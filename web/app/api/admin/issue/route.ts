// Admin: manually issue a comp / free license outside of Stripe.
// POST body: { email: string, plan: "monthly" | "yearly" | "lifetime", note?: string }
// Auth: ADMIN_TOKEN bearer header or ?token= query param.

import { NextRequest, NextResponse } from 'next/server';
import { insertLicense, setNote } from '@/lib/store';
import { generateLicenseKey, planExpiry } from '@/lib/license';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

const VALID_PLANS = new Set(['monthly', 'yearly', 'lifetime']);

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
  const rawEmail = body?.email;
  const rawPlan = body?.plan;

  if (!rawEmail || typeof rawEmail !== 'string') {
    return NextResponse.json({ error: 'missing or invalid email in body' }, { status: 400 });
  }
  if (!rawPlan || !VALID_PLANS.has(rawPlan)) {
    return NextResponse.json(
      { error: 'missing or invalid plan — must be monthly, yearly, or lifetime' },
      { status: 400 },
    );
  }

  const email = rawEmail.trim().toLowerCase();
  const plan = rawPlan as 'monthly' | 'yearly' | 'lifetime';
  const key = generateLicenseKey();
  const expiresAt = planExpiry(plan);
  const issuedAt = new Date().toISOString();

  await insertLicense({ key, email, plan, expiresAt });

  const noteText = body?.note ? String(body.note).trim() || null : null;
  if (noteText) await setNote(key, noteText);

  return NextResponse.json({
    ok: true,
    key,
    email,
    plan,
    issuedAt,
    expiresAt,
    note: noteText,
  });
}
