// Admin: reactivate multiple license keys in one batch.
// POST body: { keys: string[] }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
//
// Use cases:
//   - Wrongly revoked licenses (admin error affecting multiple accounts)
//   - Customer cohort whose payment failures were resolved manually outside Stripe
//   - Goodwill reinstatement after a service outage
//
// Max 100 keys per request. Keys already active are silently skipped
// (returned in `skipped` array with reason="already_active"). Unknown keys are
// also skipped with reason="not_found". Each successfully reactivated key gets
// its own audit log entry.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, setStatus, insertAuditLog } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const MAX_KEYS = 100;

type ReactivateResult = { key: string; previousStatus: string };
type SkipResult = { key: string; reason: 'not_found' | 'already_active' };

export async function POST(req: NextRequest) {
  const denied = adminGuard(req, 'bulk-reactivate');
  if (denied) return denied;

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

  const changed: ReactivateResult[] = [];
  const skipped: SkipResult[] = [];

  await Promise.all(
    keys.map(async (key) => {
      const license = await findLicense(key);
      if (!license) {
        skipped.push({ key, reason: 'not_found' });
        return;
      }
      if (license.status === 'active') {
        skipped.push({ key, reason: 'already_active' });
        return;
      }
      const previousStatus = license.status;
      await setStatus(key, 'active');
      await insertAuditLog({
        licenseKey: key,
        action: 'reactivate',
        detail: { previousStatus, newStatus: 'active', bulk: true },
      });
      changed.push({ key, previousStatus });
    }),
  );

  return NextResponse.json({ ok: true, changed, skipped });
}
