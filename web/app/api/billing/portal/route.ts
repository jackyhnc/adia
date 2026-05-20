import { NextRequest, NextResponse } from 'next/server';
import { stripe, isStripeConfigured } from '@/lib/stripe';
import { rateLimit, clientIp } from '@/lib/ratelimit';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  const rl = rateLimit(`portal:${clientIp(req)}`, 10, 60);
  if (!rl.ok) {
    return NextResponse.json(
      { error: 'too many requests' },
      { status: 429, headers: { 'Retry-After': String(rl.retryAfterSec) } },
    );
  }
  if (!isStripeConfigured || !stripe) {
    return NextResponse.json({ error: 'Billing portal not available yet.' }, { status: 503 });
  }
  const body = await req.json().catch(() => null);
  const email = String(body?.email ?? '').trim().toLowerCase();
  if (!/^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$/.test(email)) {
    return NextResponse.json({ error: 'Invalid email.' }, { status: 400 });
  }
  const customers = await stripe.customers.list({ email, limit: 1 });
  const customer = customers.data[0];
  if (!customer) {
    return NextResponse.json(
      { error: 'No subscription found for that email.' },
      { status: 404 },
    );
  }
  const portal = await stripe.billingPortal.sessions.create({
    customer: customer.id,
    return_url: `${req.nextUrl.origin}/billing?from=portal`,
  });
  return NextResponse.json({ url: portal.url });
}
