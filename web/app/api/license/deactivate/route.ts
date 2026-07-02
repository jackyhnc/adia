import { NextRequest, NextResponse } from 'next/server';
import { findLicense, hasActivation, removeActivation, countActivations } from '@/lib/store';
import { rateLimit, clientIp } from '@/lib/ratelimit';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  const rl = rateLimit(`deactivate:${clientIp(req)}`, 10, 60);
  if (!rl.ok) {
    return NextResponse.json(
      { error: 'too many requests' },
      { status: 429, headers: { 'Retry-After': String(rl.retryAfterSec) } },
    );
  }
  const body = await req.json().catch(() => null);
  if (!body?.key || !body?.email || !body?.machine) {
    return NextResponse.json({ error: 'missing key, email, or machine' }, { status: 400 });
  }
  const license = await findLicense(body.key, body.email);
  if (!license) {
    return NextResponse.json({ error: 'License key not found for that email.' }, { status: 404 });
  }
  const known = await hasActivation(body.key, body.machine);
  if (!known) {
    return NextResponse.json({ error: 'Machine not found in activations.' }, { status: 404 });
  }
  await removeActivation(body.key, body.machine);
  const seatsNow = await countActivations(body.key);
  return NextResponse.json({ ok: true, key: license.key, seatsNow });
}
