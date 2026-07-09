// Tests for GET /api/admin/revenue
// Returns MRR, ARR, lifetime revenue, past-due MRR, new MRR (30d), and per-plan breakdowns.
// Prices: monthly $7/mo · yearly $59/yr ($4.9167/mo) · lifetime $149 one-time.

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import Database from 'better-sqlite3';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

function openDb(p: string) { return new Database(p); }

function backdate(db: Database.Database, key: string, daysAgo: number) {
  const d = new Date(Date.now() - daysAgo * 24 * 60 * 60 * 1000).toISOString();
  db.prepare('UPDATE licenses SET issued_at = ? WHERE key = ?').run(d, key);
}

function setStatus(db: Database.Database, key: string, status: string) {
  db.prepare('UPDATE licenses SET status = ? WHERE key = ?').run(status, key);
}

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-revenue-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
  );
  resetDbForTesting(dbPath);
  process.env.ADMIN_TOKEN = 'test-admin-token';
});

afterEach(() => {
  resetDbForTesting();
  delete process.env.ADMIN_TOKEN;
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

function authHeader(token = 'test-admin-token') {
  return { Authorization: `Bearer ${token}` };
}

async function callGet(token = 'test-admin-token') {
  const { GET } = await import('@/app/api/admin/revenue/route');
  const req = new NextRequest('http://localhost/api/admin/revenue', {
    method: 'GET',
    headers: authHeader(token),
  });
  return GET(req);
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('GET /api/admin/revenue — auth', () => {
  it('returns 401 with no authorization header', async () => {
    const { GET } = await import('@/app/api/admin/revenue/route');
    const req = new NextRequest('http://localhost/api/admin/revenue');
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callGet('wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query-param auth', async () => {
    const { GET } = await import('@/app/api/admin/revenue/route');
    const req = new NextRequest('http://localhost/api/admin/revenue?token=test-admin-token');
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});

// ─── Empty DB ─────────────────────────────────────────────────────────────────

describe('GET /api/admin/revenue — empty DB', () => {
  it('returns zeros on empty database', async () => {
    const res = await callGet();
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.mrr).toBe(0);
    expect(body.arr).toBe(0);
    expect(body.lifetimeRevenue).toBe(0);
    expect(body.pastDueMrr).toBe(0);
    expect(body.newMrr30d).toBe(0);
  });

  it('byPlan rows are all zero on empty database', async () => {
    const res = await callGet();
    const body = await res.json();
    expect(body.byPlan.monthly.active).toBe(0);
    expect(body.byPlan.monthly.pastDue).toBe(0);
    expect(body.byPlan.monthly.new30d).toBe(0);
    expect(body.byPlan.monthly.mrr).toBe(0);
    expect(body.byPlan.yearly.active).toBe(0);
    expect(body.byPlan.yearly.pastDue).toBe(0);
    expect(body.byPlan.yearly.mrr).toBe(0);
    expect(body.byPlan.lifetime.active).toBe(0);
    expect(body.byPlan.lifetime.revenue).toBe(0);
  });
});

// ─── Monthly MRR ─────────────────────────────────────────────────────────────

describe('GET /api/admin/revenue — monthly plan', () => {
  it('1 active monthly license → mrr=$7, arr=$84', async () => {
    insertLicense({ key: 'M-1', email: 'a@x.com', plan: 'monthly', stripeSession: 'ss1' });
    const res = await callGet();
    const body = await res.json();
    expect(body.mrr).toBe(7.00);
    expect(body.arr).toBe(84.00);
    expect(body.byPlan.monthly.active).toBe(1);
    expect(body.byPlan.monthly.mrr).toBe(7.00);
  });

  it('3 active monthly licenses → mrr=$21', async () => {
    insertLicense({ key: 'M-1', email: 'a@x.com', plan: 'monthly', stripeSession: 'ss1' });
    insertLicense({ key: 'M-2', email: 'b@x.com', plan: 'monthly', stripeSession: 'ss2' });
    insertLicense({ key: 'M-3', email: 'c@x.com', plan: 'monthly', stripeSession: 'ss3' });
    const res = await callGet();
    const body = await res.json();
    expect(body.mrr).toBe(21.00);
    expect(body.byPlan.monthly.active).toBe(3);
    expect(body.byPlan.monthly.mrr).toBe(21.00);
  });
});

// ─── Yearly MRR ───────────────────────────────────────────────────────────────

describe('GET /api/admin/revenue — yearly plan', () => {
  it('1 active yearly license → mrr=$4.92', async () => {
    insertLicense({ key: 'Y-1', email: 'a@x.com', plan: 'yearly', stripeSession: 'ss1' });
    const res = await callGet();
    const body = await res.json();
    // 59/12 = 4.9167 rounds to 4.92
    expect(body.mrr).toBe(4.92);
    expect(body.byPlan.yearly.active).toBe(1);
    expect(body.byPlan.yearly.mrr).toBe(4.92);
  });

  it('12 active yearly licenses → mrr=$59.00', async () => {
    for (let i = 0; i < 12; i++) {
      insertLicense({ key: `Y-${i}`, email: `u${i}@x.com`, plan: 'yearly', stripeSession: `ss${i}` });
    }
    const res = await callGet();
    const body = await res.json();
    // 12 * (59/12) = 59.00
    expect(body.mrr).toBe(59.00);
    expect(body.byPlan.yearly.active).toBe(12);
  });
});

// ─── Lifetime revenue ─────────────────────────────────────────────────────────

describe('GET /api/admin/revenue — lifetime plan', () => {
  it('1 active lifetime license → lifetimeRevenue=$149', async () => {
    insertLicense({ key: 'L-1', email: 'a@x.com', plan: 'lifetime', stripeSession: 'ss1' });
    const res = await callGet();
    const body = await res.json();
    expect(body.lifetimeRevenue).toBe(149.00);
    expect(body.byPlan.lifetime.active).toBe(1);
    expect(body.byPlan.lifetime.revenue).toBe(149.00);
  });

  it('lifetime does not count toward mrr', async () => {
    insertLicense({ key: 'L-1', email: 'a@x.com', plan: 'lifetime', stripeSession: 'ss1' });
    const res = await callGet();
    const body = await res.json();
    expect(body.mrr).toBe(0);
    expect(body.arr).toBe(0);
  });
});

// ─── Mixed plans ──────────────────────────────────────────────────────────────

describe('GET /api/admin/revenue — mixed plans', () => {
  it('monthly + yearly + lifetime combined', async () => {
    insertLicense({ key: 'M-1', email: 'a@x.com', plan: 'monthly',  stripeSession: 'ss1' });
    insertLicense({ key: 'Y-1', email: 'b@x.com', plan: 'yearly',   stripeSession: 'ss2' });
    insertLicense({ key: 'L-1', email: 'c@x.com', plan: 'lifetime', stripeSession: 'ss3' });
    const res = await callGet();
    const body = await res.json();
    // mrr = 7.00 + 4.92 = 11.92
    expect(body.mrr).toBe(11.92);
    expect(body.arr).toBe(Math.round(11.92 * 12 * 100) / 100);
    expect(body.lifetimeRevenue).toBe(149.00);
  });
});

// ─── Past-due MRR ─────────────────────────────────────────────────────────────

describe('GET /api/admin/revenue — past_due licenses', () => {
  it('past_due monthly license contributes to pastDueMrr but not mrr', async () => {
    const rawDb = openDb(dbPath);
    insertLicense({ key: 'M-1', email: 'a@x.com', plan: 'monthly', stripeSession: 'ss1' });
    setStatus(rawDb, 'M-1', 'past_due');
    rawDb.close();
    const res = await callGet();
    const body = await res.json();
    expect(body.mrr).toBe(0);
    expect(body.pastDueMrr).toBe(7.00);
    expect(body.byPlan.monthly.active).toBe(0);
    expect(body.byPlan.monthly.pastDue).toBe(1);
  });

  it('past_due yearly license contributes to pastDueMrr', async () => {
    const rawDb = openDb(dbPath);
    insertLicense({ key: 'Y-1', email: 'a@x.com', plan: 'yearly', stripeSession: 'ss1' });
    setStatus(rawDb, 'Y-1', 'past_due');
    rawDb.close();
    const res = await callGet();
    const body = await res.json();
    expect(body.pastDueMrr).toBe(4.92);
  });
});

// ─── New MRR (30 days) ────────────────────────────────────────────────────────

describe('GET /api/admin/revenue — newMrr30d', () => {
  it('license issued 10 days ago counts in newMrr30d', async () => {
    const rawDb = openDb(dbPath);
    insertLicense({ key: 'M-1', email: 'a@x.com', plan: 'monthly', stripeSession: 'ss1' });
    backdate(rawDb, 'M-1', 10);
    rawDb.close();
    const res = await callGet();
    const body = await res.json();
    expect(body.newMrr30d).toBe(7.00);
  });

  it('license issued 45 days ago does NOT count in newMrr30d', async () => {
    const rawDb = openDb(dbPath);
    insertLicense({ key: 'M-1', email: 'a@x.com', plan: 'monthly', stripeSession: 'ss1' });
    backdate(rawDb, 'M-1', 45);
    rawDb.close();
    const res = await callGet();
    const body = await res.json();
    expect(body.newMrr30d).toBe(0);
  });

  it('canceled license issued 10 days ago does NOT count in newMrr30d', async () => {
    const rawDb = openDb(dbPath);
    insertLicense({ key: 'M-1', email: 'a@x.com', plan: 'monthly', stripeSession: 'ss1' });
    backdate(rawDb, 'M-1', 10);
    setStatus(rawDb, 'M-1', 'canceled');
    rawDb.close();
    const res = await callGet();
    const body = await res.json();
    expect(body.newMrr30d).toBe(0);
  });

  it('yearly license issued recently counts proportional new MRR', async () => {
    const rawDb = openDb(dbPath);
    insertLicense({ key: 'Y-1', email: 'a@x.com', plan: 'yearly', stripeSession: 'ss1' });
    backdate(rawDb, 'Y-1', 5);
    rawDb.close();
    const res = await callGet();
    const body = await res.json();
    expect(body.newMrr30d).toBe(4.92);
    expect(body.byPlan.yearly.new30d).toBe(1);
  });
});

// ─── Canceled licenses excluded ───────────────────────────────────────────────

describe('GET /api/admin/revenue — canceled/expired licenses', () => {
  it('canceled license does not appear in mrr or pastDueMrr', async () => {
    const rawDb = openDb(dbPath);
    insertLicense({ key: 'M-1', email: 'a@x.com', plan: 'monthly', stripeSession: 'ss1' });
    setStatus(rawDb, 'M-1', 'canceled');
    rawDb.close();
    const res = await callGet();
    const body = await res.json();
    expect(body.mrr).toBe(0);
    expect(body.pastDueMrr).toBe(0);
    expect(body.byPlan.monthly.active).toBe(0);
    expect(body.byPlan.monthly.pastDue).toBe(0);
  });

  it('expired license does not appear in mrr', async () => {
    const rawDb = openDb(dbPath);
    insertLicense({ key: 'Y-1', email: 'a@x.com', plan: 'yearly', stripeSession: 'ss1' });
    setStatus(rawDb, 'Y-1', 'expired');
    rawDb.close();
    const res = await callGet();
    const body = await res.json();
    expect(body.mrr).toBe(0);
    expect(body.byPlan.yearly.active).toBe(0);
  });
});

// ─── Response shape ───────────────────────────────────────────────────────────

describe('GET /api/admin/revenue — response shape', () => {
  it('response contains all expected top-level keys', async () => {
    const res = await callGet();
    const body = await res.json();
    expect(body).toHaveProperty('mrr');
    expect(body).toHaveProperty('arr');
    expect(body).toHaveProperty('lifetimeRevenue');
    expect(body).toHaveProperty('pastDueMrr');
    expect(body).toHaveProperty('newMrr30d');
    expect(body).toHaveProperty('byPlan');
  });

  it('byPlan contains monthly, yearly, lifetime keys', async () => {
    const res = await callGet();
    const body = await res.json();
    expect(body.byPlan).toHaveProperty('monthly');
    expect(body.byPlan).toHaveProperty('yearly');
    expect(body.byPlan).toHaveProperty('lifetime');
  });

  it('monthly byPlan row has active, pastDue, new30d, mrr fields', async () => {
    const res = await callGet();
    const body = await res.json();
    expect(body.byPlan.monthly).toHaveProperty('active');
    expect(body.byPlan.monthly).toHaveProperty('pastDue');
    expect(body.byPlan.monthly).toHaveProperty('new30d');
    expect(body.byPlan.monthly).toHaveProperty('mrr');
  });

  it('lifetime byPlan row has revenue field (not mrr)', async () => {
    const res = await callGet();
    const body = await res.json();
    expect(body.byPlan.lifetime).toHaveProperty('revenue');
    expect(body.byPlan.lifetime).not.toHaveProperty('mrr');
  });

  it('arr equals mrr * 12 (rounded to cent)', async () => {
    insertLicense({ key: 'M-1', email: 'a@x.com', plan: 'monthly', stripeSession: 'ss1' });
    insertLicense({ key: 'Y-1', email: 'b@x.com', plan: 'yearly',  stripeSession: 'ss2' });
    const res = await callGet();
    const body = await res.json();
    const expectedArr = Math.round(body.mrr * 12 * 100) / 100;
    expect(body.arr).toBe(expectedArr);
  });
});
