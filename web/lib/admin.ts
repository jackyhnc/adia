// Shared guard for admin API routes: rate-limit then authenticate.
// Returns a NextResponse (429 or 401) when the request must be rejected,
// or null when the caller may proceed.
//
// Rate limit: 20 requests / 60 s per IP, keyed by route name so one
// hammered endpoint cannot starve others.
// Auth: ADMIN_TOKEN bearer header or ?token= query param.

import { NextRequest, NextResponse } from 'next/server';
import { rateLimit, clientIp } from './ratelimit';

export function adminGuard(req: NextRequest, routeName: string): NextResponse | null {
  const rl = rateLimit(`admin-${routeName}:${clientIp(req)}`, 20, 60);
  if (!rl.ok) {
    return NextResponse.json(
      { error: 'too many requests' },
      { status: 429, headers: { 'Retry-After': String(rl.retryAfterSec) } },
    );
  }

  const token = process.env.ADMIN_TOKEN;
  if (!token) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });
  const hdr = req.headers.get('authorization') ?? '';
  const ok = hdr.startsWith('Bearer ')
    ? hdr.slice(7) === token
    : req.nextUrl.searchParams.get('token') === token;
  if (!ok) return NextResponse.json({ error: 'unauthorized' }, { status: 401 });

  return null;
}
