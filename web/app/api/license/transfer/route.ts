import { NextRequest, NextResponse } from 'next/server';
import { findLicense, transferLicense } from '@/lib/store';
import { rateLimit, clientIp } from '@/lib/ratelimit';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  const rl = rateLimit(`transfer:${clientIp(req)}`, 5, 60);
  if (!rl.ok) {
    return NextResponse.json(
      { error: 'too many requests' },
      { status: 429, headers: { 'Retry-After': String(rl.retryAfterSec) } },
    );
  }
  const body = await req.json().catch(() => null);
  if (!body?.key || !body?.email || !body?.newEmail) {
    return NextResponse.json({ error: 'missing key, email, or newEmail' }, { status: 400 });
  }
  const normalizedNewEmail = String(body.newEmail).trim().toLowerCase();
  const license = await findLicense(body.key, body.email);
  if (!license) {
    return NextResponse.json({ error: 'License key not found for that email.' }, { status: 404 });
  }
  if (license.email === normalizedNewEmail) {
    return NextResponse.json({ error: 'newEmail is the same as current email.' }, { status: 422 });
  }
  await transferLicense(body.key, normalizedNewEmail);
  return NextResponse.json({
    ok: true,
    key: license.key,
    email: normalizedNewEmail,
    plan: license.plan,
  });
}
