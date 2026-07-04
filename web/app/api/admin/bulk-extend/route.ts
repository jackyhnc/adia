// Admin: extend expiry on multiple license keys in one batch.
// POST body: { keys: string[], days: number }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
//
// Use cases:
//   - Goodwill extension for a cohort after downtime or billing hiccup
//   - Trial extension for a batch of test accounts
//   - Compensation extension without going through Stripe one-by-one
//
// days must be a positive integer; max 3650 (10 years) to prevent typos.
// For each key: extends from max(now, currentExpiresAt). Null expiresAt
// (lifetime licenses) are treated as extending from now.
// Unknown keys are skipped with reason="not_found".
// Max 100 keys per request. Each changed key gets its own audit log entry.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, setExpiry, insertAuditLog } from '@/lib/store';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const MAX_KEYS = 100;
const MAX_DAYS = 3650;

function authorized(req: NextRequest): boolean {
  const token = process.env.ADMIN_TOKEN;
  if (!token) return false;
  const hdr = req.headers.get('authorization') ?? '';
  if (hdr.startsWith('Bearer ')) return hdr.slice(7) === token;
  return req.nextUrl.searchParams.get('token') === token;
}

type ChangedResult = {
  key: string;
  previousExpiresAt: string | null;
  newExpiresAt: string;
  days: number;
};
type SkipResult = { key: string; reason: 'not_found' };

export async function POST(req: NextRequest) {
  if (!authorized(req)) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const body = await req.json().catch(() => null);

  const rawKeys = body?.keys;
  if (!Array.isArray(rawKeys) || rawKeys.length === 0) {
    return NextResponse.json({ error: 'missing or empty keys array in body' }, { status: 400 });
  }
  if (rawKeys.length > MAX_KEYS) {
    return NextResponse.json(
      { error: `too many keys — max ${MAX_KEYS} per request` },
      { status: 400 },
    );
  }

  const rawDays = body?.days;
  if (rawDays === undefined || rawDays === null) {
    return NextResponse.json({ error: 'missing days in body' }, { status: 400 });
  }
  const days = Number(rawDays);
  if (!Number.isInteger(days) || days < 1) {
    return NextResponse.json({ error: 'days must be a positive integer' }, { status: 400 });
  }
  if (days > MAX_DAYS) {
    return NextResponse.json(
      { error: `days must be ≤ ${MAX_DAYS} (10 years)` },
      { status: 400 },
    );
  }

  const keys = rawKeys.map((k: unknown) => String(k).trim().toUpperCase());

  const changed: ChangedResult[] = [];
  const skipped: SkipResult[] = [];

  await Promise.all(
    keys.map(async (key) => {
      const license = await findLicense(key);
      if (!license) {
        skipped.push({ key, reason: 'not_found' });
        return;
      }

      const previousExpiresAt = license.expiresAt ?? null;

      // Extend from the later of "now" or the current expiresAt, so a past
      // expiry doesn't produce a new date that's still in the past.
      const now = new Date();
      const baseDate =
        previousExpiresAt && new Date(previousExpiresAt) > now
          ? new Date(previousExpiresAt)
          : now;
      baseDate.setDate(baseDate.getDate() + days);
      const newExpiresAt = baseDate.toISOString();

      await setExpiry(key, newExpiresAt);
      await insertAuditLog({
        licenseKey: key,
        action: 'bulk_extend',
        detail: { previousExpiresAt, newExpiresAt, days, bulk: true },
      });
      changed.push({ key, previousExpiresAt, newExpiresAt, days });
    }),
  );

  return NextResponse.json({ ok: true, changed, skipped });
}
