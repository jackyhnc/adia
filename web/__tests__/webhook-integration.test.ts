// Integration tests for /api/stripe/webhook.
// Stripe SDK and email sending are mocked so tests run without real credentials.
// Rate limiter and SQLite DB are reset per test.
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, findLicense, insertLicense } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

// vi.mock() calls are hoisted before imports, so the mocked versions are in
// place when @/app/api/stripe/webhook/route is imported below.
vi.mock('@/lib/stripe', () => ({
  isStripeConfigured: true,
  stripe: {
    webhooks: { constructEvent: vi.fn() },
  },
}));

vi.mock('@/lib/email', () => ({
  sendLicenseEmail: vi.fn().mockResolvedValue(undefined),
}));

// Static imports must come AFTER vi.mock() blocks (the hoisting order is:
// vi.mock → static imports → module body).
import { stripe } from '@/lib/stripe';
import { sendLicenseEmail } from '@/lib/email';
import { POST } from '@/app/api/stripe/webhook/route';

const mockConstructEvent = vi.mocked(stripe!.webhooks.constructEvent);
const mockSendLicenseEmail = vi.mocked(sendLicenseEmail);

let dbPath: string;

beforeEach(() => {
  dbPath = path.join(os.tmpdir(), `adia-wint-${Date.now()}.db`);
  resetDbForTesting(dbPath);
  resetRateLimit();
  mockConstructEvent.mockReset();
  mockSendLicenseEmail.mockReset();
  mockSendLicenseEmail.mockResolvedValue(undefined);
  process.env.STRIPE_WEBHOOK_SECRET = 'whsec_test_secret';
});

afterEach(() => {
  resetDbForTesting();
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
  delete process.env.STRIPE_WEBHOOK_SECRET;
});

async function callPost(body = 'fake-payload') {
  const req = new NextRequest('http://localhost/api/stripe/webhook', {
    method: 'POST',
    body,
    headers: { 'stripe-signature': 'fake-sig' },
  });
  return POST(req);
}

describe('POST /api/stripe/webhook — integration (mocked Stripe)', () => {
  it('checkout.session.completed issues a license and sends an email', async () => {
    mockConstructEvent.mockReturnValue({
      type: 'checkout.session.completed',
      data: {
        object: {
          id: 'cs_test_001',
          customer_details: { email: 'buyer@example.com' },
          metadata: { plan: 'yearly' },
          subscription: 'sub_test_001',
        },
      },
    });

    const res = await callPost();
    expect(res.status).toBe(200);

    expect(mockSendLicenseEmail).toHaveBeenCalledOnce();
    const [toEmail, issuedKey, plan] = mockSendLicenseEmail.mock.calls[0] as [string, string, string];
    expect(toEmail).toBe('buyer@example.com');
    expect(issuedKey).toMatch(/^ADIA-/);
    expect(plan).toBe('yearly');

    const license = findLicense(issuedKey);
    expect(license).not.toBeNull();
    expect(license!.email).toBe('buyer@example.com');
    expect(license!.plan).toBe('yearly');
  });

  it('checkout.session.completed is idempotent on webhook re-delivery', async () => {
    mockConstructEvent.mockReturnValue({
      type: 'checkout.session.completed',
      data: {
        object: {
          id: 'cs_test_idem_002',
          customer_details: { email: 'idem@example.com' },
          metadata: { plan: 'monthly' },
          subscription: null,
        },
      },
    });

    await callPost();
    await callPost(); // re-delivery — same session ID

    // Email is sent only on first issuance; re-delivery must not double-send.
    expect(mockSendLicenseEmail).toHaveBeenCalledOnce();
  });

  it('checkout.session.completed with no email is a no-op', async () => {
    mockConstructEvent.mockReturnValue({
      type: 'checkout.session.completed',
      data: {
        object: {
          id: 'cs_test_noemail_003',
          customer_details: null,
          customer_email: null,
          metadata: { plan: 'monthly' },
          subscription: null,
        },
      },
    });

    const res = await callPost();
    expect(res.status).toBe(200);
    expect(mockSendLicenseEmail).not.toHaveBeenCalled();
  });

  it('customer.subscription.deleted cancels the license', async () => {
    insertLicense({
      key: 'ADIA-CNCL-WBHK-001A',
      email: 'sub@example.com',
      plan: 'monthly',
      stripeSub: 'sub_cancel_001',
      expiresAt: new Date(Date.now() + 86400000).toISOString(),
    });

    mockConstructEvent.mockReturnValue({
      type: 'customer.subscription.deleted',
      data: { object: { id: 'sub_cancel_001' } },
    });

    const res = await callPost();
    expect(res.status).toBe(200);

    const license = findLicense('ADIA-CNCL-WBHK-001A');
    expect(license!.status).toBe('canceled');
  });

  it('customer.subscription.updated extends license expiry when subscription is active', async () => {
    const oldExpiry = new Date(Date.now() + 30 * 86400000).toISOString();
    insertLicense({
      key: 'ADIA-UPDT-WBHK-001A',
      email: 'renew@example.com',
      plan: 'monthly',
      stripeSub: 'sub_renew_001',
      expiresAt: oldExpiry,
    });

    // Stripe sends current_period_end as Unix seconds
    const newPeriodEnd = Math.floor((Date.now() + 60 * 86400000) / 1000);
    mockConstructEvent.mockReturnValue({
      type: 'customer.subscription.updated',
      data: {
        object: {
          id: 'sub_renew_001',
          status: 'active',
          current_period_end: newPeriodEnd,
        },
      },
    });

    const res = await callPost();
    expect(res.status).toBe(200);

    const license = findLicense('ADIA-UPDT-WBHK-001A');
    const expectedExpiry = new Date(newPeriodEnd * 1000).toISOString();
    expect(license!.expiresAt).toBe(expectedExpiry);
    expect(license!.expiresAt).not.toBe(oldExpiry);
  });

  it('customer.subscription.updated does not extend expiry for past_due subscription', async () => {
    const originalExpiry = new Date(Date.now() + 30 * 86400000).toISOString();
    insertLicense({
      key: 'ADIA-PDUD-WBHK-001A',
      email: 'pastdue@example.com',
      plan: 'monthly',
      stripeSub: 'sub_pastdue_001',
      expiresAt: originalExpiry,
    });

    mockConstructEvent.mockReturnValue({
      type: 'customer.subscription.updated',
      data: {
        object: {
          id: 'sub_pastdue_001',
          status: 'past_due',
          current_period_end: Math.floor(Date.now() / 1000) + 60 * 86400,
        },
      },
    });

    const res = await callPost();
    expect(res.status).toBe(200);

    // past_due subs must NOT get an extended expiry — wait for payment to recover.
    const license = findLicense('ADIA-PDUD-WBHK-001A');
    expect(license!.expiresAt).toBe(originalExpiry);
  });

  it('unrecognized event types return 200 without side effects', async () => {
    mockConstructEvent.mockReturnValue({
      type: 'customer.created',
      data: { object: { id: 'cus_001' } },
    });

    const res = await callPost();
    expect(res.status).toBe(200);
    expect(mockSendLicenseEmail).not.toHaveBeenCalled();
  });

  it('returns 400 when Stripe signature verification throws', async () => {
    mockConstructEvent.mockImplementation(() => {
      throw new Error('No signatures found matching the expected signature for payload');
    });

    const res = await callPost();
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/bad signature/i);
  });
});
