import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting } from '@/lib/db';

let dbPath: string;

beforeEach(() => {
  dbPath = path.join(os.tmpdir(), `adia-webhook-${Date.now()}.db`);
  resetDbForTesting(dbPath);
  vi.resetModules();
});

afterEach(() => {
  resetDbForTesting();
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

describe('POST /api/stripe/webhook', () => {
  it('returns 503 when Stripe is not configured', async () => {
    delete process.env.STRIPE_SECRET_KEY;
    delete process.env.STRIPE_WEBHOOK_SECRET;

    const { POST } = await import('@/app/api/stripe/webhook/route');
    const req = new NextRequest('http://localhost/api/stripe/webhook', {
      method: 'POST',
      body: '{}',
    });
    const res = await POST(req);
    expect(res.status).toBe(503);
  });

  it('returns 400 when signature header is missing', async () => {
    process.env.STRIPE_SECRET_KEY = 'sk_test_fake_key_for_testing';
    process.env.STRIPE_WEBHOOK_SECRET = 'whsec_fake_secret_for_testing';

    const { POST } = await import('@/app/api/stripe/webhook/route');
    const req = new NextRequest('http://localhost/api/stripe/webhook', {
      method: 'POST',
      body: JSON.stringify({ type: 'checkout.session.completed' }),
    });
    const res = await POST(req);
    expect(res.status).toBe(400);

    delete process.env.STRIPE_SECRET_KEY;
    delete process.env.STRIPE_WEBHOOK_SECRET;
  });

  // TODO(jacky): Full happy-path test requires constructing a valid Stripe
  // signature (HMAC-SHA256 of timestamp + payload). Wire up once test-mode
  // Stripe keys are available in CI secrets.
});
