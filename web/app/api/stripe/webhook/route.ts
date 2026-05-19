import { NextRequest, NextResponse } from 'next/server';
import { stripe, isStripeConfigured } from '@/lib/stripe';
import { insertLicense, setStatus } from '@/lib/db';
import { generateLicenseKey, planExpiry } from '@/lib/license';
import { sendLicenseEmail } from '@/lib/email';

export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export async function POST(req: NextRequest) {
  if (!isStripeConfigured || !stripe) {
    return NextResponse.json({ error: 'Stripe not configured' }, { status: 503 });
  }
  const sig = req.headers.get('stripe-signature');
  const secret = process.env.STRIPE_WEBHOOK_SECRET;
  if (!sig || !secret) {
    return NextResponse.json({ error: 'missing signature' }, { status: 400 });
  }
  const raw = await req.text();

  let event;
  try {
    event = stripe.webhooks.constructEvent(raw, sig, secret);
  } catch (err: any) {
    return NextResponse.json({ error: `bad signature: ${err.message}` }, { status: 400 });
  }

  if (event.type === 'checkout.session.completed') {
    const session: any = event.data.object;
    const email = session.customer_details?.email ?? session.customer_email;
    const plan = (session.metadata?.plan ?? 'monthly') as 'monthly' | 'yearly' | 'lifetime';
    if (!email) return NextResponse.json({ ok: true });

    const key = generateLicenseKey();
    const writtenKey = insertLicense({
      key,
      email,
      plan,
      stripeSession: session.id,
      stripeSub: session.subscription ?? undefined,
      expiresAt: planExpiry(plan),
    });
    // Only send the email on first issuance, not on webhook re-delivery.
    if (writtenKey === key) {
      await sendLicenseEmail(email, key, plan);
    }
  }

  if (event.type === 'customer.subscription.deleted') {
    const sub: any = event.data.object;
    // mark license expired — assumes 1 sub per license
    setStatus(sub.id, 'canceled');
  }

  return NextResponse.json({ ok: true });
}
