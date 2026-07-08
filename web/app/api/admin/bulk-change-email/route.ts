// Admin: change the email address on a batch of license keys, each to its own new email.
// POST body: { changes: [{ key: string, newEmail: string }] }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
//
// Unlike /api/admin/bulk-transfer (many keys → one destination email), this endpoint
// accepts per-key email assignments, useful for corporate seat reassignments where
// each seat belongs to a different employee.
//
// Max 100 changes per request.
// Unknown keys → skipped with reason="not_found".
// Keys already owned by the given newEmail → skipped with reason="already_set".
// Invalid email format in any entry → 400 immediately before processing.
// Each successfully changed key gets its own audit log entry.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, transferLicense, insertAuditLog } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const MAX_CHANGES = 100;
const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

type ChangeEntry = { key: string; newEmail: string };
type ChangedResult = { key: string; oldEmail: string; newEmail: string };
type SkipResult = { key: string; reason: 'not_found' | 'already_set' };

export async function POST(req: NextRequest) {
  const denied = adminGuard(req, 'bulk-change-email');
  if (denied) return denied;

  const body = await req.json().catch(() => null);

  const rawChanges = body?.changes;
  if (!Array.isArray(rawChanges) || rawChanges.length === 0) {
    return NextResponse.json({ error: 'missing or empty changes array in body' }, { status: 400 });
  }
  if (rawChanges.length > MAX_CHANGES) {
    return NextResponse.json(
      { error: `too many changes — max ${MAX_CHANGES} per request` },
      { status: 400 },
    );
  }

  // Normalise and validate all entries up-front so invalid emails are caught before
  // any mutations are made.
  const entries: ChangeEntry[] = [];
  for (let i = 0; i < rawChanges.length; i++) {
    const entry = rawChanges[i];
    if (!entry || typeof entry !== 'object') {
      return NextResponse.json(
        { error: `changes[${i}] must be an object with key and newEmail` },
        { status: 400 },
      );
    }
    const rawKey = entry.key ? String(entry.key).trim().toUpperCase() : '';
    const rawEmail = entry.newEmail ? String(entry.newEmail).trim().toLowerCase() : '';
    if (!rawKey) {
      return NextResponse.json({ error: `changes[${i}].key is missing or empty` }, { status: 400 });
    }
    if (!rawEmail) {
      return NextResponse.json(
        { error: `changes[${i}].newEmail is missing or empty` },
        { status: 400 },
      );
    }
    if (!EMAIL_RE.test(rawEmail)) {
      return NextResponse.json(
        { error: `changes[${i}].newEmail "${rawEmail}" is not a valid email address` },
        { status: 400 },
      );
    }
    entries.push({ key: rawKey, newEmail: rawEmail });
  }

  const changed: ChangedResult[] = [];
  const skipped: SkipResult[] = [];

  await Promise.all(
    entries.map(async ({ key, newEmail }) => {
      const license = await findLicense(key);
      if (!license) {
        skipped.push({ key, reason: 'not_found' });
        return;
      }
      if (license.email === newEmail) {
        skipped.push({ key, reason: 'already_set' });
        return;
      }
      const oldEmail = license.email;
      await transferLicense(key, newEmail);
      await insertAuditLog({
        licenseKey: key,
        action: 'bulk_change_email',
        detail: { oldEmail, newEmail, bulk: true },
      });
      changed.push({ key, oldEmail, newEmail });
    }),
  );

  return NextResponse.json({ ok: true, changed, skipped });
}
