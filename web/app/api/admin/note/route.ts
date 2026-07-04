// Admin endpoint: store or retrieve a freeform note on a license.
// GET  ?key=ADIA-... → { key, note: string | null }
// POST { key, note } → { ok, key, note: string | null }
//   Pass note="" or omit note to clear. note is trimmed; empty string stored as null.
// Auth: ADMIN_TOKEN bearer header or ?token= query param.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, getNote, setNote, insertAuditLog } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function GET(req: NextRequest) {
  const denied = adminGuard(req, 'note');
  if (denied) return denied;
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
  const denied = adminGuard(req, 'note');
  if (denied) return denied;
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
  await insertAuditLog({ licenseKey: key, action: 'set_note', detail: { note } });
  return NextResponse.json({ ok: true, key, note });
}
