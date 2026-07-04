// Admin: bulk-generate license keys in one request.
// POST body: {
//   count: number,                          // 1–50 keys to generate
//   plan: "monthly" | "yearly" | "lifetime",
//   email?: string,                         // shared email on all keys; defaults to "bulk@admin"
//   note?: string,                          // optional note applied to every generated key
//   expiresAt?: string | null,              // override expiry; omit to use plan default
// }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.

import { NextRequest, NextResponse } from 'next/server';
import { insertLicense, setNote, insertAuditLog } from '@/lib/store';
import { generateLicenseKey, planExpiry } from '@/lib/license';
import { adminGuard } from '@/lib/admin';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const VALID_PLANS = new Set(['monthly', 'yearly', 'lifetime']);
const MAX_BULK = 50;

export async function POST(req: NextRequest) {
  const denied = adminGuard(req, 'bulk-issue');
  if (denied) return denied;

  const body = await req.json().catch(() => null);
  if (!body || typeof body !== 'object') {
    return NextResponse.json({ error: 'invalid JSON body' }, { status: 400 });
  }

  const rawCount = body.count;
  const rawPlan = body.plan;
  const rawEmail = body.email;

  if (rawCount === undefined || rawCount === null) {
    return NextResponse.json({ error: 'missing count in body' }, { status: 400 });
  }
  if (typeof rawCount !== 'number' || !Number.isInteger(rawCount) || rawCount < 1) {
    return NextResponse.json({ error: 'count must be a positive integer ≥ 1' }, { status: 400 });
  }
  if (rawCount > MAX_BULK) {
    return NextResponse.json({ error: `count must be ≤ ${MAX_BULK}` }, { status: 400 });
  }
  if (!rawPlan || !VALID_PLANS.has(rawPlan)) {
    return NextResponse.json(
      { error: 'missing or invalid plan — must be monthly, yearly, or lifetime' },
      { status: 400 },
    );
  }

  // expiresAt: explicitly provided → validate and use; omitted → derive from plan.
  let expiresAt: string | null;
  if (Object.prototype.hasOwnProperty.call(body, 'expiresAt')) {
    if (body.expiresAt === null) {
      expiresAt = null;
    } else if (typeof body.expiresAt === 'string') {
      const d = new Date(body.expiresAt);
      if (isNaN(d.getTime())) {
        return NextResponse.json(
          { error: 'invalid expiresAt — must be an ISO date string or null' },
          { status: 400 },
        );
      }
      expiresAt = d.toISOString();
    } else {
      return NextResponse.json(
        { error: 'invalid expiresAt — must be a string or null' },
        { status: 400 },
      );
    }
  } else {
    expiresAt = planExpiry(rawPlan as 'monthly' | 'yearly' | 'lifetime');
  }

  const plan = rawPlan as 'monthly' | 'yearly' | 'lifetime';
  const email = rawEmail && typeof rawEmail === 'string' ? rawEmail.trim().toLowerCase() : 'bulk@admin';
  const noteText = body.note ? String(body.note).trim() || null : null;
  const issuedAt = new Date().toISOString();

  const keys: string[] = [];
  for (let i = 0; i < rawCount; i++) {
    const key = generateLicenseKey();
    keys.push(key);
    await insertLicense({ key, email, plan, expiresAt });
    if (noteText) await setNote(key, noteText);
    await insertAuditLog({
      licenseKey: key,
      action: 'issued_bulk',
      detail: { email, plan, expiresAt, note: noteText, batchSize: rawCount },
    });
  }

  return NextResponse.json({ ok: true, keys, count: keys.length, email, plan, issuedAt, expiresAt, note: noteText });
}
