// Admin: set an absolute expiresAt on multiple license keys in one batch.
// POST body: { keys: string[], expiresAt: string | null }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
//
// Use cases:
//   - Set a cohort to expire on a specific renewal date
//   - Convert a set of time-based licenses to lifetime (expiresAt: null)
//   - Immediately expire a group of licenses (expiresAt: past date)
//
// expiresAt must be a valid ISO-8601 date string or null (lifetime).
// Unknown keys are skipped with reason="not_found".
// Keys whose current expiresAt already matches are skipped with reason="already_set".
// Max 100 keys per request. Each changed key gets its own audit log entry.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, setExpiry, insertAuditLog } from '@/lib/store';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const MAX_KEYS = 100;

function authorized(req: NextRequest): boolean {
  const token = process.env.ADMIN_TOKEN;
  if (!token) return false;
  const hdr = req.headers.get('authorization') ?? '';
  if (hdr.startsWith('Bearer ')) return hdr.slice(7) === token;
  return req.nextUrl.searchParams.get('token') === token;
}

function isValidIsoDate(s: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}(T[\d:.Z+-]+)?$/.test(s)) return false;
  const d = new Date(s);
  return !isNaN(d.getTime());
}

type ChangedResult = {
  key: string;
  previousExpiresAt: string | null;
  newExpiresAt: string | null;
};
type SkipResult = { key: string; reason: 'not_found' | 'already_set' };

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

  // expiresAt must be explicitly present (null is valid for lifetime)
  if (!Object.prototype.hasOwnProperty.call(body, 'expiresAt')) {
    return NextResponse.json(
      { error: 'missing expiresAt in body (pass null for lifetime)' },
      { status: 400 },
    );
  }
  const rawExpiry = body.expiresAt;
  let newExpiresAt: string | null;
  if (rawExpiry === null) {
    newExpiresAt = null;
  } else if (typeof rawExpiry === 'string') {
    if (!isValidIsoDate(rawExpiry)) {
      return NextResponse.json(
        { error: 'expiresAt must be a valid ISO-8601 date string (e.g. "2025-12-31") or null' },
        { status: 400 },
      );
    }
    newExpiresAt = new Date(rawExpiry).toISOString();
  } else {
    return NextResponse.json(
      { error: 'expiresAt must be an ISO-8601 date string or null' },
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

      // Skip no-ops: normalise both sides to ISO string for comparison
      const prevNorm = previousExpiresAt ? new Date(previousExpiresAt).toISOString() : null;
      if (prevNorm === newExpiresAt) {
        skipped.push({ key, reason: 'already_set' });
        return;
      }

      await setExpiry(key, newExpiresAt);
      await insertAuditLog({
        licenseKey: key,
        action: 'bulk_set_expiry',
        detail: { previousExpiresAt, newExpiresAt, bulk: true },
      });
      changed.push({ key, previousExpiresAt, newExpiresAt });
    }),
  );

  return NextResponse.json({ ok: true, changed, skipped });
}
