// Admin: move a list of license keys to a new email address in one batch.
// POST body: { keys: string[], newEmail: string }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
//
// Use cases:
//   - Company re-org: all licenses under old corporate email → new email
//   - Account merging: consolidate multiple purchase emails into one
//   - Customer changed email and has many keys
//
// Unlike /api/admin/change-email (single-key, targeted), this operates on up to
// 100 keys at once and requires no confirmation of the old email.
//
// Max 100 keys per request.
// Unknown keys → skipped with reason="not_found".
// Keys already owned by newEmail → skipped with reason="already_set".
// Each successfully transferred key gets its own audit log entry.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, transferLicense, insertAuditLog } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const MAX_KEYS = 100;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

type ChangedResult = { key: string; oldEmail: string };
type SkipResult = { key: string; reason: 'not_found' | 'already_set' };

export async function POST(req: NextRequest) {
  const denied = adminGuard(req, 'bulk-transfer');
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

  const rawEmail = body?.newEmail ? String(body.newEmail).trim().toLowerCase() : null;
  if (!rawEmail) {
    return NextResponse.json({ error: 'missing newEmail in body' }, { status: 400 });
  }
  if (!EMAIL_RE.test(rawEmail)) {
    return NextResponse.json({ error: 'newEmail is not a valid email address' }, { status: 400 });
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
      if (license.email === rawEmail) {
        skipped.push({ key, reason: 'already_set' });
        return;
      }
      const oldEmail = license.email;
      await transferLicense(key, rawEmail);
      await insertAuditLog({
        licenseKey: key,
        action: 'bulk_transfer',
        detail: { oldEmail, newEmail: rawEmail, bulk: true },
      });
      changed.push({ key, oldEmail });
    }),
  );

  return NextResponse.json({ ok: true, newEmail: rawEmail, changed, skipped });
}
