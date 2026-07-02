// Tests for GET /api/license/seats
// Auth: key + email (query params). Lists activated machines for the license holder.

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, recordActivation } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

beforeEach(() => {
  dbPath = path.join(os.tmpdir(), `adia-seats-${Date.now()}-${Math.random().toString(36).slice(2)}.db`);
  resetDbForTesting(dbPath);
  resetRateLimit();
});

afterEach(() => {
  resetDbForTesting();
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

async function callGet(params: Record<string, string>, ip = '127.0.0.1') {
  const { GET } = await import('@/app/api/license/seats/route');
  const qs = new URLSearchParams(params).toString();
  const req = new NextRequest(`http://localhost/api/license/seats?${qs}`, {
    method: 'GET',
    headers: { 'x-forwarded-for': ip },
  });
  return GET(req);
}

describe('GET /api/license/seats', () => {
  it('returns 400 when key is missing', async () => {
    const res = await callGet({ email: 'user@example.com' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing/i);
  });

  it('returns 400 when email is missing', async () => {
    const res = await callGet({ key: 'ADIA-XXXX-XXXX-XXXX' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing/i);
  });

  it('returns 404 for unknown key/email combination', async () => {
    const res = await callGet({ key: 'ADIA-UNKN-UNKN-UNKN', email: 'ghost@example.com' });
    expect(res.status).toBe(404);
    const body = await res.json();
    expect(body.error).toMatch(/not found/i);
  });

  it('returns 404 when correct key but wrong email', async () => {
    insertLicense({ key: 'ADIA-SEAT-WRGM-AAAA', email: 'owner@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callGet({ key: 'ADIA-SEAT-WRGM-AAAA', email: 'notowner@example.com' });
    expect(res.status).toBe(404);
  });

  it('returns empty seats list for a key with no activations', async () => {
    insertLicense({ key: 'ADIA-SEAT-EMTY-AAAA', email: 'empty@example.com', plan: 'monthly', expiresAt: null });
    const res = await callGet({ key: 'ADIA-SEAT-EMTY-AAAA', email: 'empty@example.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.key).toBe('ADIA-SEAT-EMTY-AAAA');
    expect(body.seatCount).toBe(0);
    expect(body.seats).toEqual([]);
  });

  it('returns all activated machines with correct seat count', async () => {
    const key = 'ADIA-SEAT-LIST-AAAA';
    insertLicense({ key, email: 'listed@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation(key, 'machine-alpha');
    recordActivation(key, 'machine-beta');
    recordActivation(key, 'machine-gamma');

    const res = await callGet({ key, email: 'listed@example.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.seatCount).toBe(3);
    expect(body.seats).toHaveLength(3);
    const hashes = body.seats.map((s: any) => s.machineHash);
    expect(hashes).toContain('machine-alpha');
    expect(hashes).toContain('machine-beta');
    expect(hashes).toContain('machine-gamma');
  });

  it('returns license metadata alongside seats', async () => {
    const key = 'ADIA-SEAT-META-AAAA';
    insertLicense({ key, email: 'meta@example.com', plan: 'yearly', expiresAt: '2027-01-01T00:00:00.000Z' });
    const res = await callGet({ key, email: 'meta@example.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.plan).toBe('yearly');
    expect(body.status).toBe('active');
  });

  it('each seat entry has firstSeen and lastSeen timestamps', async () => {
    const key = 'ADIA-SEAT-TIME-AAAA';
    insertLicense({ key, email: 'ts@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation(key, 'machine-ts');

    const res = await callGet({ key, email: 'ts@example.com' });
    const body = await res.json();
    const seat = body.seats[0];
    expect(seat.machineHash).toBe('machine-ts');
    expect(seat.firstSeen).toBeTruthy();
    expect(seat.lastSeen).toBeTruthy();
  });

  it('key lookup is case-insensitive (normalized to uppercase)', async () => {
    const key = 'ADIA-SEAT-CASE-AAAA';
    insertLicense({ key, email: 'casetest@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation(key, 'machine-x');

    const res = await callGet({ key: 'adia-seat-case-aaaa', email: 'casetest@example.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.key).toBe('ADIA-SEAT-CASE-AAAA');
    expect(body.seatCount).toBe(1);
  });

  it('returns 429 after 20 requests from the same IP', async () => {
    for (let i = 0; i < 20; i++) {
      const r = await callGet({}, '10.2.0.1');
      expect(r.status).not.toBe(429);
    }
    const r = await callGet({}, '10.2.0.1');
    expect(r.status).toBe(429);
    const body = await r.json();
    expect(body.error).toBe('too many requests');
    expect(r.headers.get('Retry-After')).toBeTruthy();
  });

  it('rate limit is per-IP — a different IP is not blocked', async () => {
    for (let i = 0; i < 20; i++) {
      await callGet({}, '10.2.0.2');
    }
    const r = await callGet({}, '10.2.0.3');
    expect(r.status).not.toBe(429);
  });

  it('seat count reflects machine removal after deactivate', async () => {
    const key = 'ADIA-SEAT-RFRSH-AAAA';
    insertLicense({ key, email: 'refresh@example.com', plan: 'lifetime', expiresAt: null });
    recordActivation(key, 'machine-a');
    recordActivation(key, 'machine-b');

    // Confirm initial state: 2 seats.
    const r1 = await callGet({ key, email: 'refresh@example.com' });
    expect(r1.status).toBe(200);
    const b1 = await r1.json();
    expect(b1.seatCount).toBe(2);

    // Remove one machine via /deactivate.
    const { POST: deactivatePost } = await import('@/app/api/license/deactivate/route');
    const deacReq = new NextRequest('http://localhost/api/license/deactivate', {
      method: 'POST',
      body: JSON.stringify({ key, email: 'refresh@example.com', machine: 'machine-a' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const deacRes = await deactivatePost(deacReq);
    expect(deacRes.status).toBe(200);

    // Seat list now reflects the removal.
    const r2 = await callGet({ key, email: 'refresh@example.com' });
    expect(r2.status).toBe(200);
    const b2 = await r2.json();
    expect(b2.seatCount).toBe(1);
    expect(b2.seats).toHaveLength(1);
    expect(b2.seats[0].machineHash).toBe('machine-b');
  });
});
