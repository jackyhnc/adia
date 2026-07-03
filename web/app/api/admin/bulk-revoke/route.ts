// Admin: revoke (cancel) multiple license keys in one batch.
// POST body: { keys: string[] }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
//
// Use cases:
//   - Disable a cohort of fraudulent keys from a stolen credit card
//   - Revoke licenses issued to an invalid email domain en masse
//   - Clean up keys created during testing/staging that leaked to production
//
// Max 100 keys per request. Keys already canceled are silently skipped
// (returned in `skipped` array with reason="already_revoked"). Unknown keys are
// also skipped with reason="not_found". Each successfully revoked key gets its
// own audit log entry.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, setStatus, insertAuditLog } from '@/lib/store';

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

type RevokeResult = { key: string; previousStatus: string };
type SkipResult = { key: string; reason: 'not_found' | 'already_revoked' };

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

  const keys = rawKeys.map((k: unknown) => String(k).trim().toUpperCase());

  const changed: RevokeResult[] = [];
  const skipped: SkipResult[] = [];

  await Promise.all(
    keys.map(async (key) => {
      const license = await findLicense(key);
      if (!license) {
        skipped.push({ key, reason: 'not_found' });
        return;
      }
      if (license.status === 'canceled') {
        skipped.push({ key, reason: 'already_revoked' });
        return;
      }
      const previousStatus = license.status;
      await setStatus(key, 'canceled');
      await insertAuditLog({
        licenseKey: key,
        action: 'revoke',
        detail: { previousStatus, newStatus: 'canceled', bulk: true },
      });
      changed.push({ key, previousStatus });
    }),
  );

  return NextResponse.json({ ok: true, changed, skipped });
}
