import { describe, it, expect, beforeEach } from 'vitest';
import { rateLimit, clientIp, _resetForTesting } from '@/lib/ratelimit';

beforeEach(() => _resetForTesting());

describe('rateLimit', () => {
  it('allows requests under capacity', () => {
    for (let i = 0; i < 5; i++) {
      const r = rateLimit('ip-a', 5, 60);
      expect(r.ok).toBe(true);
    }
  });

  it('blocks when capacity exhausted', () => {
    for (let i = 0; i < 3; i++) rateLimit('ip-b', 3, 60);
    const r = rateLimit('ip-b', 3, 60);
    expect(r.ok).toBe(false);
    expect(r.retryAfterSec).toBeGreaterThan(0);
  });

  it('isolates buckets per key', () => {
    for (let i = 0; i < 2; i++) rateLimit('ip-c', 2, 60);
    expect(rateLimit('ip-c', 2, 60).ok).toBe(false);
    expect(rateLimit('ip-d', 2, 60).ok).toBe(true);
  });

  it('refills tokens over time', async () => {
    // capacity 2, window 1 second → 2 tokens per second refill
    for (let i = 0; i < 2; i++) rateLimit('ip-e', 2, 1);
    expect(rateLimit('ip-e', 2, 1).ok).toBe(false);
    await new Promise((r) => setTimeout(r, 600));
    expect(rateLimit('ip-e', 2, 1).ok).toBe(true);
  });
});

describe('clientIp', () => {
  it('uses x-forwarded-for first hop', () => {
    const headers = new Headers({ 'x-forwarded-for': '1.2.3.4, 5.6.7.8' });
    expect(clientIp({ headers })).toBe('1.2.3.4');
  });

  it('falls back to x-real-ip', () => {
    const headers = new Headers({ 'x-real-ip': '9.9.9.9' });
    expect(clientIp({ headers })).toBe('9.9.9.9');
  });

  it('returns unknown when no headers', () => {
    expect(clientIp({ headers: new Headers() })).toBe('unknown');
  });
});
