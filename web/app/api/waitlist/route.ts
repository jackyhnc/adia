import { NextRequest, NextResponse } from 'next/server';
import { joinWaitlist } from '@/lib/db';

export const runtime = 'nodejs';

export async function POST(req: NextRequest) {
  const form = await req.formData();
  const email = String(form.get('email') ?? '').trim();
  if (!email || !/^[^@]+@[^@]+\.[^@]+$/.test(email)) {
    return NextResponse.redirect(new URL('/download?waitlist=invalid', req.url));
  }
  joinWaitlist(email);
  return NextResponse.redirect(new URL('/download?waitlist=ok', req.url));
}
