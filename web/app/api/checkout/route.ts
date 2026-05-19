import { NextRequest, NextResponse } from 'next/server';
import { stripe, isStripeConfigured, PRICE_IDS, type Plan } from '@/lib/stripe';

export async function GET(req: NextRequest) {
  const plan = (req.nextUrl.searchParams.get('plan') ?? 'yearly') as Plan;
  const priceId = PRICE_IDS[plan];
  const origin = req.nextUrl.origin;

  if (!isStripeConfigured || !priceId || !stripe) {
    // Graceful fallback so the page is usable before Stripe is wired up.
    return NextResponse.redirect(`${origin}/pricing?stripe=unconfigured&plan=${plan}`);
  }

  const session = await stripe.checkout.sessions.create({
    mode: plan === 'lifetime' ? 'payment' : 'subscription',
    line_items: [{ price: priceId, quantity: 1 }],
    success_url: `${origin}/success?session_id={CHECKOUT_SESSION_ID}`,
    cancel_url: `${origin}/pricing?canceled=1`,
    customer_creation: plan === 'lifetime' ? 'always' : undefined,
    allow_promotion_codes: true,
    automatic_tax: { enabled: true },
    billing_address_collection: 'auto',
    metadata: { plan },
  });

  return NextResponse.redirect(session.url!, { status: 303 });
}
