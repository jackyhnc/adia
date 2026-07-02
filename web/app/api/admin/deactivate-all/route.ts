// Admin endpoint: remove ALL machine activations for a license key in one call.
// Useful for lost/stolen machine scenarios where the user can't identify individual machines.
// POST { key } → { ok, key, removedCount }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, removeAllActivations } from '@/lib/store';

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
  if (!body?.key) {
    return NextResponse.json({ error: 'missing key' }, { status: 400 });
  }
  const key = String(body.key).trim().toUpperCase();
  const license = await findLicense(key);
  if (!license) {
    return NextResponse.json({ error: 'unknown key' }, { status: 404 });
  }
  const removedCount = await removeAllActivations(key);
  return NextResponse.json({ ok: true, key, removedCount });
}
