import { NextRequest, NextResponse } from 'next/server';
import { stripe, isStripeConfigured } from '@/lib/stripe';
import { insertLicense, setStatusBySub, setExpiryBySub, findLicenseBySub } from '@/lib/store';
import { generateLicenseKey, planExpiry } from '@/lib/license';
import { sendLicenseEmail, sendPaymentFailedEmail } from '@/lib/email';

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
    const writtenKey = await insertLicense({
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
    // Look up the license by stripe_sub, not by its own primary key.
    await setStatusBySub(sub.id, 'canceled');
  }

  if (event.type === 'customer.subscription.updated') {
    const sub: any = event.data.object;
    // Extend license expiry when subscription renews or its period changes.
    // Only update for active subscriptions — past_due/unpaid subs keep their
    // current expiry until either the payment recovers or the sub is deleted.
    if (sub.status === 'active' && sub.current_period_end) {
      const expiresAt = new Date(sub.current_period_end * 1000).toISOString();
      await setExpiryBySub(sub.id, expiresAt);
    }
  }

  if (event.type === 'invoice.payment_failed') {
    const inv: any = event.data.object;
    // Subscription invoices only — ignore one-time charges.
    if (inv.subscription) {
      const license = await findLicenseBySub(inv.subscription);
      await setStatusBySub(inv.subscription, 'past_due');
      if (license) {
        await sendPaymentFailedEmail(license.email, license.key, license.plan);
      }
    }
  }

  if (event.type === 'invoice.payment_succeeded') {
    const inv: any = event.data.object;
    // Reactivate the license if payment recovers after a past_due period.
    // For initial checkouts this is a harmless no-op (status already 'active').
    if (inv.subscription) {
      await setStatusBySub(inv.subscription, 'active');
    }
  }

  return NextResponse.json({ ok: true });
}
