import Stripe from 'stripe';

export const isStripeConfigured = !!process.env.STRIPE_SECRET_KEY;

export const stripe = isStripeConfigured
  ? new Stripe(process.env.STRIPE_SECRET_KEY!, { apiVersion: '2025-02-24.acacia' })
  : null;

export const PRICE_IDS = {
  monthly: process.env.STRIPE_PRICE_MONTHLY,
  yearly:  process.env.STRIPE_PRICE_YEARLY,
  lifetime: process.env.STRIPE_PRICE_LIFETIME,
} as const;

export type Plan = keyof typeof PRICE_IDS;
