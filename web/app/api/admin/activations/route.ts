// Admin: list or remove machine activations for a license key.
// GET    ?key=ADIA-...          → list all activated machines
// DELETE ?key=ADIA-...&machine= → deactivate one machine (frees a seat)
// Auth: ADMIN_TOKEN bearer header or ?token= query param.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, listActivations, removeActivation } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  const denied = adminGuard(req, 'activations');
  if (denied) return denied;
  const rawKey = req.nextUrl.searchParams.get('key');
  if (!rawKey) return NextResponse.json({ error: 'missing ?key=' }, { status: 400 });
  const key = rawKey.trim().toUpperCase();
  const license = await findLicense(key);
  if (!license) return NextResponse.json({ error: 'unknown key' }, { status: 404 });
  const activations = await listActivations(key);
  return NextResponse.json({
    key,
    email: license.email,
    plan: license.plan,
    status: license.status,
    seatCount: activations.length,
    activations,
  });
}

export async function DELETE(req: NextRequest) {
  const denied = adminGuard(req, 'activations');
  if (denied) return denied;
  const rawKey = req.nextUrl.searchParams.get('key');
  const machine = req.nextUrl.searchParams.get('machine');
  if (!rawKey || !machine) {
    return NextResponse.json({ error: 'missing ?key= or ?machine=' }, { status: 400 });
  }
  const key = rawKey.trim().toUpperCase();
  const license = await findLicense(key);
  if (!license) return NextResponse.json({ error: 'unknown key' }, { status: 404 });
  await removeActivation(key, machine);
  const remaining = await listActivations(key);
  return NextResponse.json({ ok: true, key, seatsNow: remaining.length });
}
