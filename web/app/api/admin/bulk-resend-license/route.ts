// Admin: re-send the license welcome email for multiple keys at once.
// POST body: { keys: string[], dryRun?: boolean }
//   keys: required — array of license keys, max 50.
//   dryRun: optional — if true, validates and resolves keys without sending email or writing audit log.
// Skips: not_found (unknown key), no_email (key has no email address on record).
// Writes a resend_license audit log entry for each successfully sent key.
// Auth: ADMIN_TOKEN bearer header or ?token= query param.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, insertAuditLog } from '@/lib/store';
import { sendLicenseEmail } from '@/lib/email';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const MAX_KEYS = 50;

export async function POST(req: NextRequest) {
  const denied = adminGuard(req, 'bulk-resend-license');
  if (denied) return denied;

  const body = await req.json().catch(() => null);
  const rawKeys: unknown = body?.keys;

  if (!Array.isArray(rawKeys) || rawKeys.length === 0) {
    return NextResponse.json({ error: 'missing or empty keys array' }, { status: 400 });
  }
  if (rawKeys.length > MAX_KEYS) {
    return NextResponse.json({ error: `too many keys — max ${MAX_KEYS} per request` }, { status: 400 });
  }

  const dryRun = body?.dryRun === true;
  const keys = rawKeys.map((k) => String(k).trim().toUpperCase());

  const sent: { key: string; email: string; plan: string }[] = [];
  const skipped: { key: string; reason: string }[] = [];

  for (const key of keys) {
    const license = await findLicense(key);
    if (!license) {
      skipped.push({ key, reason: 'not_found' });
      continue;
    }
    if (!license.email) {
      skipped.push({ key, reason: 'no_email' });
      continue;
    }
    if (!dryRun) {
      await sendLicenseEmail(license.email, license.key, license.plan);
      await insertAuditLog({
        licenseKey: license.key,
        action: 'resend_license',
        detail: { to: license.email, bulk: true },
      });
    }
    sent.push({ key: license.key, email: license.email, plan: license.plan });
  }

  return NextResponse.json({ ok: true, dryRun, sent, skipped });
}
