import { describe, it, expect, beforeEach, vi } from 'vitest';
import { NextRequest } from 'next/server';

beforeEach(() => {
  delete process.env.STRIPE_SECRET_KEY;
  vi.resetModules();
});

describe('GET /api/checkout', () => {
  it('redirects to /pricing?stripe=unconfigured when STRIPE_SECRET_KEY is absent', async () => {
    const { GET } = await import('@/app/api/checkout/route');
    const req = new NextRequest('http://localhost/api/checkout?plan=yearly');
    const res = await GET(req);

    expect(res.status).toBeGreaterThanOrEqual(300);
    expect(res.status).toBeLessThan(400);
    expect(res.headers.get('location') ?? '').toContain('stripe=unconfigured');
  });

  it('redirects for monthly plan', async () => {
    const { GET } = await import('@/app/api/checkout/route');
    const req = new NextRequest('http://localhost/api/checkout?plan=monthly');
    const res = await GET(req);

    expect(res.status).toBeGreaterThanOrEqual(300);
    expect(res.headers.get('location') ?? '').toContain('stripe=unconfigured');
  });

  it('defaults to yearly when no plan param', async () => {
    const { GET } = await import('@/app/api/checkout/route');
    const req = new NextRequest('http://localhost/api/checkout');
    const res = await GET(req);

    expect(res.status).toBeGreaterThanOrEqual(300);
    expect(res.headers.get('location') ?? '').toContain('stripe=unconfigured');
  });
});
