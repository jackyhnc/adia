import { NextRequest, NextResponse } from 'next/server';
import { joinWaitlist } from '@/lib/db';

export const runtime = 'nodejs';

export async function POST(req: NextRequest) {
  const form = await req.formData();
  const email = String(form.get('email') ?? '').trim().toLowerCase();
  // Conservative: local + @ + domain + . + tld, no spaces, <=254 chars
  const valid = email.length <= 254
    && /^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/.test(email);
  if (!valid) {
    return NextResponse.redirect(new URL('/download?waitlist=invalid', req.url));
  }
  joinWaitlist(email);
  return NextResponse.redirect(new URL('/download?waitlist=ok', req.url));
}
