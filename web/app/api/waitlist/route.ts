import { NextRequest, NextResponse } from 'next/server';
import { joinWaitlist } from '@/lib/store';
import { rateLimit, clientIp } from '@/lib/ratelimit';

export const runtime = 'nodejs';

export async function POST(req: NextRequest) {
  const rl = rateLimit(`waitlist:${clientIp(req)}`, 5, 60);
  if (!rl.ok) {
    return NextResponse.redirect(new URL('/download?waitlist=ratelimit', req.url));
  }
  const form = await req.formData();
  const email = String(form.get('email') ?? '').trim().toLowerCase();
  // Conservative: local + @ + domain + . + tld, no spaces, <=254 chars
  const valid = email.length <= 254
    && /^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/.test(email);
  if (!valid) {
    return NextResponse.redirect(new URL('/download?waitlist=invalid', req.url));
  }
  await joinWaitlist(email);
  return NextResponse.redirect(new URL('/download?waitlist=ok', req.url));
}
