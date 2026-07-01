// Admin: list all licenses issued to an email address.
// Auth: ADMIN_TOKEN bearer header. Never expose without it.

import { NextRequest, NextResponse } from 'next/server';
import { findLicensesByEmail } from '@/lib/store';

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
  const email = req.nextUrl.searchParams.get('email');
  if (!email) return NextResponse.json({ error: 'missing ?email=' }, { status: 400 });
  const licenses = await findLicensesByEmail(email);
  return NextResponse.json({ email: email.trim().toLowerCase(), count: licenses.length, licenses });
}
