// Admin endpoint: store or retrieve a freeform note on a license.
// GET  ?key=ADIA-... → { key, note: string | null }
// POST { key, note } → { ok, key, note: string | null }
//   Pass note="" or omit note to clear. note is trimmed; empty string stored as null.
// Auth: ADMIN_TOKEN bearer header or ?token= query param.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, getNote, setNote } from '@/lib/store';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

function authorized(req: NextRequest): boolean {
  const token = process.env.ADMIN_TOKEN;
  if (!token) return false;
  const hdr = req.headers.get('authorization') ?? '';
  if (hdr.startsWith('Bearer ')) return hdr.slice(7) === token;
  return req.nextUrl.searchParams.get('token') === token;
}

export async function GET(req: NextRequest) {
  if (!authorized(req)) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }
  const rawKey = req.nextUrl.searchParams.get('key');
  if (!rawKey) {
    return NextResponse.json({ error: 'missing key' }, { status: 400 });
  }
  const key = rawKey.trim().toUpperCase();
  const license = await findLicense(key);
  if (!license) {
    return NextResponse.json({ error: 'unknown key' }, { status: 404 });
  }
  const note = await getNote(key);
  return NextResponse.json({ key, note });
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
  // Coerce: missing note → null, empty string → null, otherwise trimmed string.
  const rawNote = body.note != null ? String(body.note).trim() : null;
  const note = rawNote || null;
  await setNote(key, note);
  return NextResponse.json({ ok: true, key, note });
}
