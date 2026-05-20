// Token bucket rate limiter, in-memory.
// In production on Vercel the function instance may not persist between
// invocations — use Upstash Redis or Vercel KV for a real distributed limit.
// This in-memory version is good enough to slow brute-force scans of license
// keys; the API is sized for low volume.

type Bucket = { tokens: number; last: number };
const buckets = new Map<string, Bucket>();

export type RateLimitResult = {
  ok: boolean;
  remaining: number;
  retryAfterSec: number;
};

/// Allow `capacity` requests per `windowSec` per key. Returns ok=false when
/// the bucket is empty. `retryAfterSec` is a hint for the 429 Retry-After header.
export function rateLimit(key: string, capacity = 30, windowSec = 60): RateLimitResult {
  const refillPerMs = capacity / (windowSec * 1000);
  const now = Date.now();
  let bucket = buckets.get(key);
  if (!bucket) {
    bucket = { tokens: capacity, last: now };
    buckets.set(key, bucket);
  } else {
    bucket.tokens = Math.min(capacity, bucket.tokens + (now - bucket.last) * refillPerMs);
    bucket.last = now;
  }
  if (bucket.tokens < 1) {
    const retryAfterMs = Math.ceil((1 - bucket.tokens) / refillPerMs);
    return { ok: false, remaining: 0, retryAfterSec: Math.max(1, Math.ceil(retryAfterMs / 1000)) };
  }
  bucket.tokens -= 1;
  return { ok: true, remaining: Math.floor(bucket.tokens), retryAfterSec: 0 };
}

export function clientIp(req: { headers: Headers }): string {
  // x-forwarded-for from the first proxy hop wins on Vercel.
  const fwd = req.headers.get('x-forwarded-for');
  if (fwd) return fwd.split(',')[0]!.trim();
  return req.headers.get('x-real-ip') ?? 'unknown';
}

/// Test-only: clear all buckets so tests don't pollute each other.
export function _resetForTesting() {
  buckets.clear();
}
