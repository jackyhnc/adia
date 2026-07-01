// Admin: manually resend the payment-failed email for a license key.
// POST body: { key: "ADIA-...", force?: boolean }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
// By default only past_due licenses trigger an email; pass force:true to send
// regardless of status (useful for testing the email template).

import { NextRequest, NextResponse } from 'next/server';
import { findLicense } from '@/lib/store';
import { sendPaymentFailedEmail } from '@/lib/email';

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
  const rawKey = body?.key;
  if (!rawKey) return NextResponse.json({ error: 'missing key in body' }, { status: 400 });
  const key = String(rawKey).trim().toUpperCase();
  const force = Boolean(body?.force);

  const license = await findLicense(key);
  if (!license) return NextResponse.json({ error: 'unknown key' }, { status: 404 });

  if (!force && license.status !== 'past_due') {
    return NextResponse.json(
      { error: 'license is not past_due; pass force:true to send anyway', status: license.status },
      { status: 422 },
    );
  }

  await sendPaymentFailedEmail(license.email, key, license.plan);
  return NextResponse.json({ ok: true, to: license.email, key, plan: license.plan });
}
