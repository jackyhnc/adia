// Admin: set, append, or clear a note on multiple license keys in one batch.
// POST body: { keys: string[], note?: string | null, mode?: 'set' | 'append' | 'clear' }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
//
// Modes:
//   set    (default) — overwrite the note; empty string or omitted note clears it.
//   append           — append note to existing value separated by " | ".
//                      If existing note is null, behaves like "set".
//   clear            — set note to null for all keys, ignoring the note field.
//
// Max 100 keys per request. Unknown keys are skipped (reason="not_found").
// Keys whose note would not change are skipped (reason="already_set").
// Each changed key gets its own audit log entry.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, getNote, setNote, insertAuditLog } from '@/lib/store';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const MAX_KEYS = 100;
const MODES = ['set', 'append', 'clear'] as const;
type Mode = (typeof MODES)[number];

function authorized(req: NextRequest): boolean {
  const token = process.env.ADMIN_TOKEN;
  if (!token) return false;
  const hdr = req.headers.get('authorization') ?? '';
  if (hdr.startsWith('Bearer ')) return hdr.slice(7) === token;
  return req.nextUrl.searchParams.get('token') === token;
}

type ChangedResult = { key: string; previousNote: string | null; newNote: string | null };
type SkipResult = { key: string; reason: 'not_found' | 'already_set' };

export async function POST(req: NextRequest) {
  if (!authorized(req)) {
    return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  }

  const body = await req.json().catch(() => null);

  const rawKeys = body?.keys;
  if (!Array.isArray(rawKeys) || rawKeys.length === 0) {
    return NextResponse.json({ error: 'missing or empty keys array in body' }, { status: 400 });
  }
  if (rawKeys.length > MAX_KEYS) {
    return NextResponse.json(
      { error: `too many keys — max ${MAX_KEYS} per request` },
      { status: 400 },
    );
  }

  const rawMode: unknown = body?.mode ?? 'set';
  if (!MODES.includes(rawMode as Mode)) {
    return NextResponse.json(
      { error: `invalid mode — must be one of: ${MODES.join(', ')}` },
      { status: 400 },
    );
  }
  const mode = rawMode as Mode;

  // Resolve the target note text from body (ignored for mode="clear").
  const noteText: string | null =
    mode === 'clear'
      ? null
      : body?.note != null
        ? String(body.note).trim() || null
        : null;

  const keys = rawKeys.map((k: unknown) => String(k).trim().toUpperCase());

  const changed: ChangedResult[] = [];
  const skipped: SkipResult[] = [];

  await Promise.all(
    keys.map(async (key) => {
      const license = await findLicense(key);
      if (!license) {
        skipped.push({ key, reason: 'not_found' });
        return;
      }

      const previousNote = await getNote(key);
      let newNote: string | null;

      if (mode === 'clear') {
        newNote = null;
      } else if (mode === 'append') {
        if (previousNote && noteText) {
          newNote = `${previousNote} | ${noteText}`;
        } else {
          newNote = noteText ?? previousNote;
        }
      } else {
        newNote = noteText;
      }

      if (newNote === previousNote) {
        skipped.push({ key, reason: 'already_set' });
        return;
      }

      await setNote(key, newNote);
      await insertAuditLog({
        licenseKey: key,
        action: 'bulk_note',
        detail: { mode, previousNote, newNote, bulk: true },
      });
      changed.push({ key, previousNote, newNote });
    }),
  );

  return NextResponse.json({ ok: true, changed, skipped });
}
