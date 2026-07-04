// Admin: set a license's expiresAt to an absolute date (or null for lifetime).
// POST body: { key: "ADIA-...", expiresAt: string | null }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.
//
// Complements /api/admin/extend (which adds relative days) — use this when
// you need to set a specific renewal date, immediately expire a license, or
// convert a time-based license to lifetime (expiresAt: null).
//
// expiresAt must be a valid ISO-8601 date string, or null.
// No status gate — admin can change expiry regardless of license status.

import { NextRequest, NextResponse } from 'next/server';
import { findLicense, setExpiry, insertAuditLog } from '@/lib/store';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

function isValidIsoDate(s: string): boolean {
  if (!/^\d{4}-\d{2}-\d{2}(T[\d:.Z+-]+)?$/.test(s)) return false;
  const d = new Date(s);
  return !isNaN(d.getTime());
}

export async function POST(req: NextRequest) {
  const denied = adminGuard(req, 'set-expiry');
  if (denied) return denied;

  const body = await req.json().catch(() => null);
  const rawKey = body?.key;
  if (!rawKey) return NextResponse.json({ error: 'missing key in body' }, { status: 400 });
  const key = String(rawKey).trim().toUpperCase();

  // expiresAt must be present in the body (null is explicit lifetime, undefined means not provided)
  if (!Object.prototype.hasOwnProperty.call(body, 'expiresAt')) {
    return NextResponse.json({ error: 'missing expiresAt in body (pass null for lifetime)' }, { status: 400 });
  }
  const rawExpiry = body.expiresAt;
  let newExpiresAt: string | null;
  if (rawExpiry === null) {
    newExpiresAt = null;
  } else if (typeof rawExpiry === 'string') {
    if (!isValidIsoDate(rawExpiry)) {
      return NextResponse.json(
        { error: 'expiresAt must be a valid ISO-8601 date string (e.g. "2025-12-31") or null' },
        { status: 400 },
      );
    }
    // Normalise to full ISO string
    newExpiresAt = new Date(rawExpiry).toISOString();
  } else {
    return NextResponse.json(
      { error: 'expiresAt must be an ISO-8601 date string or null' },
      { status: 400 },
    );
  }

  const license = await findLicense(key);
  if (!license) return NextResponse.json({ error: 'unknown key' }, { status: 404 });

  const previousExpiresAt = license.expiresAt ?? null;

  // Guard against no-op to prevent accidental double-sets
  const prevNorm = previousExpiresAt ? new Date(previousExpiresAt).toISOString() : null;
  if (prevNorm === newExpiresAt) {
    return NextResponse.json(
      { error: 'expiresAt is already set to this value', key, expiresAt: newExpiresAt },
      { status: 422 },
    );
  }

  await setExpiry(key, newExpiresAt);
  await insertAuditLog({
    licenseKey: key,
    action: 'set_expiry',
    detail: { previousExpiresAt, newExpiresAt },
  });

  return NextResponse.json({ ok: true, key, previousExpiresAt, newExpiresAt });
}
