// Tests for POST /api/billing/portal
// Stripe SDK is mocked — no real credentials needed.
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { NextRequest } from 'next/server';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

vi.mock('@/lib/stripe', () => ({
  isStripeConfigured: true,
  stripe: {
    customers: {
      list: vi.fn(),
    },
    billingPortal: {
      sessions: {
        create: vi.fn(),
      },
    },
  },
}));

import { stripe } from '@/lib/stripe';

const mockCustomersList = vi.mocked(stripe!.customers.list);
const mockPortalCreate = vi.mocked(stripe!.billingPortal.sessions.create);

beforeEach(() => {
  resetRateLimit();
  mockCustomersList.mockReset();
  mockPortalCreate.mockReset();
});

async function callPost(body: unknown, ip = '1.2.3.4') {
  const { POST } = await import('@/app/api/billing/portal/route');
  const req = new NextRequest('http://localhost/api/billing/portal', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', 'x-forwarded-for': ip },
  });
  return POST(req);
}

describe('POST /api/billing/portal', () => {
  it('returns 503 when Stripe is not configured', async () => {
    const mod = await import('@/lib/stripe');
    const original = (mod as any).isStripeConfigured;
    (mod as any).isStripeConfigured = false;

    const res = await callPost({ email: 'user@example.com' });
    expect(res.status).toBe(503);
    const body = await res.json();
    expect(body.error).toMatch(/not available/i);

    (mod as any).isStripeConfigured = original;
  });

  it('returns 400 for missing email', async () => {
    const res = await callPost({});
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/invalid email/i);
  });

  it('returns 400 for invalid email format', async () => {
    const res = await callPost({ email: 'not-an-email' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/invalid email/i);
  });

  it('returns 404 when no Stripe customer found', async () => {
    mockCustomersList.mockResolvedValue({ data: [] } as any);

    const res = await callPost({ email: 'nobody@example.com' });
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body.error).toMatch(/no subscription/i);
  });

  it('returns 200 with portal URL on success', async () => {
    mockCustomersList.mockResolvedValue({
      data: [{ id: 'cus_abc123', email: 'user@example.com' }],
    } as any);
    mockPortalCreate.mockResolvedValue({
      url: 'https://billing.stripe.com/session/test_abc',
    } as any);

    const res = await callPost({ email: 'user@example.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.url).toBe('https://billing.stripe.com/session/test_abc');

    expect(mockCustomersList).toHaveBeenCalledWith({ email: 'user@example.com', limit: 1 });
    expect(mockPortalCreate).toHaveBeenCalledWith(
      expect.objectContaining({ customer: 'cus_abc123' }),
    );
  });

  it('normalises email to lowercase before lookup', async () => {
    mockCustomersList.mockResolvedValue({ data: [] } as any);

    await callPost({ email: 'User@Example.COM' });
    expect(mockCustomersList).toHaveBeenCalledWith({ email: 'user@example.com', limit: 1 });
  });

  it('returns 429 after 10 requests from the same IP', async () => {
    mockCustomersList.mockResolvedValue({ data: [] } as any);

    const ip = '9.9.9.9';
    for (let i = 0; i < 10; i++) {
      await callPost({ email: 'x@example.com' }, ip);
    }
    const res = await callPost({ email: 'x@example.com' }, ip);
    expect(res.status).toBe(429);
    const body = await res.json();
    expect(body.error).toMatch(/too many/i);
  });

  it('rate limit is per-IP — a different IP is not blocked', async () => {
    mockCustomersList.mockResolvedValue({ data: [] } as any);

    const ip = '8.8.8.8';
    for (let i = 0; i < 10; i++) {
      await callPost({ email: 'x@example.com' }, ip);
    }
    const res = await callPost({ email: 'x@example.com' }, '8.8.4.4');
    expect(res.status).not.toBe(429);
  });
});
