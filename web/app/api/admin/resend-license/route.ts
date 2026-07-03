// Admin: re-send the license welcome email for a key or email address.
// POST body: { key?: "ADIA-...", email?: "user@example.com" }
//   - If key is supplied, look up that specific license and re-send.
//   - If only email is supplied, pick the most-recently-issued active license
//     for that address and re-send. Useful for customers who lost their key.
//   - If both are supplied, key takes precedence (email is ignored).
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
// Always sends regardless of license status (unlike resend-payment-failed which
// gates on past_due). Admins know what they're doing.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, findLicensesByEmail, insertAuditLog } from '@/lib/store';
import { sendLicenseEmail } from '@/lib/email';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

function authorized(req: NextRequest): boolean {
  const token = process.env.ADMIN_TOKEN;
  if (!token) return false;
  const hdr = req.headers.get('authorization') ?? '';
  if (hdr.startsWith('Bearer ')) return hdr.slice(7) === token;
  return req.nextUrl.searchParams.get('token') === token;
}

export async function POST(req: NextRequest) {
  if (!authorized(req)) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const body = await req.json().catch(() => null);
  const rawKey = body?.key ? String(body.key).trim().toUpperCase() : null;
  const rawEmail = body?.email ? String(body.email).trim().toLowerCase() : null;

  if (!rawKey && !rawEmail) {
    return NextResponse.json({ error: 'missing key or email in body' }, { status: 400 });
  }

  let license = null;

  if (rawKey) {
    license = await findLicense(rawKey);
    if (!license) {
      return NextResponse.json({ error: 'unknown license key' }, { status: 404 });
    }
  } else {
    // Find the most recently issued active license for this email.
    // Fall back to the most recent license of any status if none are active.
    const licenses = await findLicensesByEmail(rawEmail!);
    if (licenses.length === 0) {
      return NextResponse.json({ error: 'no licenses found for that email' }, { status: 404 });
    }
    // Prefer active licenses over non-active ones. Take the first element —
    // findLicensesByEmail returns newest-first (issuedAt DESC), so index 0 = newest.
    const active = licenses.filter((l) => l.status === 'active');
    license = active.length > 0 ? active[0] : licenses[0];
  }

  await sendLicenseEmail(license.email, license.key, license.plan);
  await insertAuditLog({
    licenseKey: license.key,
    action: 'resend_license',
    detail: { to: license.email, resolvedBy: rawKey ? 'key' : 'email' },
  });
  return NextResponse.json({ ok: true, to: license.email, key: license.key, plan: license.plan });
}
