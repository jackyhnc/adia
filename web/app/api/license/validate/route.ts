import { NextRequest, NextResponse } from 'next/server';
import { findLicense, recordActivation } from '@/lib/store';
import { rateLimit, clientIp } from '@/lib/ratelimit';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  const rl = rateLimit(`validate:${clientIp(req)}`, 60, 60);
  if (!rl.ok) {
    return NextResponse.json(
      { error: 'too many requests' },
      { status: 429, headers: { 'Retry-After': String(rl.retryAfterSec) } },
    );
  }
  const body = await req.json().catch(() => null);
  if (!body?.key || !body?.machine) {
    return NextResponse.json({ error: 'missing key or machine' }, { status: 400 });
  }
  const license = await findLicense(body.key);
  if (!license) return NextResponse.json({ error: 'unknown key' }, { status: 404 });
  if (license.status !== 'active') {
    return NextResponse.json({ error: `License is ${license.status}.` }, { status: 403 });
  }
  if (license.expiresAt && new Date(license.expiresAt) < new Date()) {
    return NextResponse.json({ error: 'License expired.' }, { status: 403 });
  }
  await recordActivation(body.key, body.machine);
  return NextResponse.json({
    key: license.key,
    email: license.email,
    plan: license.plan,
    issuedAt: license.issuedAt,
    expiresAt: license.expiresAt,
    lastValidatedAt: new Date().toISOString(),
  });
}
