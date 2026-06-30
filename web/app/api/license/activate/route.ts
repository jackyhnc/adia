import { NextRequest, NextResponse } from 'next/server';
import { findLicense, hasActivation, countActivations, recordActivation } from '@/lib/store';
import { rateLimit, clientIp } from '@/lib/ratelimit';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const MAX_SEATS = 3;

export async function POST(req: NextRequest) {
  const rl = rateLimit(`activate:${clientIp(req)}`, 20, 60);
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
  if (license.status !== 'active') {
    return NextResponse.json({ error: `License is ${license.status}.` }, { status: 403 });
  }
  if (license.expiresAt && new Date(license.expiresAt) < new Date()) {
    return NextResponse.json({ error: 'License expired.' }, { status: 403 });
  }
  // Check seat limit BEFORE writing. Known machines (re-activation) bypass the
  // count check — the upsert will only update last_seen, not add a seat.
  // Unknown machines must not be persisted if the limit is already reached;
  // the old code wrote first and checked after, leaving phantom DB rows.
  const knownMachine = await hasActivation(body.key, body.machine);
  if (!knownMachine) {
    const seatsUsed = await countActivations(body.key);
    if (seatsUsed >= MAX_SEATS) {
      return NextResponse.json(
        { error: `Already activated on ${MAX_SEATS} machines.` },
        { status: 403 },
      );
    }
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
