// Admin: set any status on multiple license keys in one batch.
// POST body: { keys: string[], status: 'active' | 'canceled' | 'expired' | 'past_due' }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
//
// Use cases:
//   - Forcibly expire a batch of trial licenses
//   - Mark a cohort as past_due after a billing processor migration
//   - Reset a test-environment batch back to active
//
// Max 100 keys per request. Keys already at the target status are silently
// skipped (reason="already_set"). Unknown keys are skipped with reason="not_found".
// Each successfully changed key gets its own audit log entry.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, setStatus, insertAuditLog } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const MAX_KEYS = 100;
const VALID_STATUSES = ['active', 'canceled', 'expired', 'past_due'] as const;
type ValidStatus = (typeof VALID_STATUSES)[number];

type ChangedResult = { key: string; previousStatus: string };
type SkipResult = { key: string; reason: 'not_found' | 'already_set' };

export async function POST(req: NextRequest) {
  const denied = adminGuard(req, 'bulk-set-status');
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

  const targetStatus: unknown = body?.status;
  if (!VALID_STATUSES.includes(targetStatus as ValidStatus)) {
    return NextResponse.json(
      { error: `invalid status — must be one of: ${VALID_STATUSES.join(', ')}` },
      { status: 400 },
    );
  }
  const status = targetStatus as ValidStatus;

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
      if (license.status === status) {
        skipped.push({ key, reason: 'already_set' });
        return;
      }
      const previousStatus = license.status;
      await setStatus(key, status);
      await insertAuditLog({
        licenseKey: key,
        action: 'set_status',
        detail: { previousStatus, newStatus: status, bulk: true },
      });
      changed.push({ key, previousStatus });
    }),
  );

  return NextResponse.json({ ok: true, changed, skipped });
}
