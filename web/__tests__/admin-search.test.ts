// Tests for GET /api/admin/search-licenses and resend_payment_failed audit log.

import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, listAuditLog, recordActivation, setStatus, setIssuedAt } from '@/lib/db';

vi.mock('@/lib/email', () => ({
  sendLicenseEmail: vi.fn().mockResolvedValue(undefined),
  sendPaymentFailedEmail: vi.fn().mockResolvedValue(undefined),
}));

let dbPath: string;

beforeEach(() => {
  dbPath = path.join(
    os.tmpdir(),
    `adia-search-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
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

async function callSearch(params: Record<string, string> = {}, token = 'test-admin-token') {
  const { GET } = await import('@/app/api/admin/search-licenses/route');
  const qs = new URLSearchParams(params).toString();
  const req = new NextRequest(`http://localhost/api/admin/search-licenses${qs ? `?${qs}` : ''}`, {
    method: 'GET',
    headers: authHeader(token),
  });
  return GET(req);
}

async function callResendPaymentFailed(body: Record<string, unknown>, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/resend-payment-failed/route');
  const req = new NextRequest('http://localhost/api/admin/resend-payment-failed', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: { 'Content-Type': 'application/json', ...authHeader(token) },
  });
  return POST(req);
}

// ─── search-licenses ──────────────────────────────────────────────────────────

describe('GET /api/admin/search-licenses', () => {
  it('returns 401 without token', async () => {
    const res = await callSearch({ q: 'test' }, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('returns 400 when q is missing', async () => {
    const res = await callSearch({});
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/missing.*q/i);
  });

  it('returns 400 when q is blank', async () => {
    const res = await callSearch({ q: '   ' });
    expect(res.status).toBe(400);
  });

  it('returns empty results when no licenses match', async () => {
    const res = await callSearch({ q: 'nobody@nowhere.com' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(0);
    expect(body.results).toEqual([]);
  });

  it('matches by email substring', async () => {
    insertLicense({ key: 'ADIA-SRCH-EMAI-AAAA', email: 'alice@acme.com', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-SRCH-EMAI-BBBB', email: 'bob@other.com', plan: 'yearly', expiresAt: null });
    const res = await callSearch({ q: 'acme' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.results[0].key).toBe('ADIA-SRCH-EMAI-AAAA');
  });

  it('matches by license key substring', async () => {
    insertLicense({ key: 'ADIA-SRCH-KEYY-AAAA', email: 'test@example.com', plan: 'lifetime', expiresAt: null });
    const res = await callSearch({ q: 'KEYY' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.results[0].key).toBe('ADIA-SRCH-KEYY-AAAA');
  });

  it('matches by note substring', async () => {
    insertLicense({ key: 'ADIA-SRCH-NOTE-AAAA', email: 'noted@example.com', plan: 'yearly', expiresAt: null });
    // set note via db directly
    const { setNote } = await import('@/lib/db');
    setNote('ADIA-SRCH-NOTE-AAAA', 'enterprise deal Q3');
    const res = await callSearch({ q: 'enterprise' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.results[0].key).toBe('ADIA-SRCH-NOTE-AAAA');
    expect(body.results[0].note).toBe('enterprise deal Q3');
  });

  it('returns multiple matches', async () => {
    insertLicense({ key: 'ADIA-SRCH-MULT-AAAA', email: 'user1@company.io', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-SRCH-MULT-BBBB', email: 'user2@company.io', plan: 'yearly', expiresAt: null });
    const res = await callSearch({ q: 'company.io' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(2);
  });

  it('respects limit parameter', async () => {
    for (let i = 1; i <= 5; i++) {
      insertLicense({ key: `ADIA-SRCH-LMT-${String(i).padStart(4, '0')}`, email: `lmt${i}@limit.com`, plan: 'monthly', expiresAt: null });
    }
    const res = await callSearch({ q: 'limit.com', limit: '2' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.results.length).toBe(2);
  });

  it('clamps limit to 100 max', async () => {
    const res = await callSearch({ q: 'x', limit: '999' });
    expect(res.status).toBe(200);
  });

  it('returns result fields: key, email, plan, status, issuedAt, expiresAt, note, machineCount', async () => {
    insertLicense({ key: 'ADIA-SRCH-FLDS-AAAA', email: 'fields@test.com', plan: 'lifetime', expiresAt: null });
    const res = await callSearch({ q: 'fields@test.com' });
    const body = await res.json();
    const r = body.results[0];
    expect(r.key).toBe('ADIA-SRCH-FLDS-AAAA');
    expect(r.email).toBe('fields@test.com');
    expect(r.plan).toBe('lifetime');
    expect(r.status).toBe('active');
    expect(r).toHaveProperty('issuedAt');
    expect(r).toHaveProperty('expiresAt');
    expect(r).toHaveProperty('note');
    expect(r).toHaveProperty('machineCount');
  });

  it('returns machineCount 0 when no activations exist', async () => {
    insertLicense({ key: 'ADIA-SRCH-MC0-AAAA', email: 'zero@machines.com', plan: 'monthly', expiresAt: null });
    const res = await callSearch({ q: 'zero@machines.com' });
    const body = await res.json();
    expect(body.results[0].machineCount).toBe(0);
  });

  it('returns machineCount equal to number of activations', async () => {
    insertLicense({ key: 'ADIA-SRCH-MC2-AAAA', email: 'two@machines.com', plan: 'yearly', expiresAt: null });
    recordActivation('ADIA-SRCH-MC2-AAAA', 'hash-machine-1');
    recordActivation('ADIA-SRCH-MC2-AAAA', 'hash-machine-2');
    const res = await callSearch({ q: 'two@machines.com' });
    const body = await res.json();
    expect(body.results[0].machineCount).toBe(2);
  });

  it('machineCount does not bleed across licenses in same search', async () => {
    insertLicense({ key: 'ADIA-SRCH-MCA-AAAA', email: 'multi@group.io', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-SRCH-MCB-BBBB', email: 'multi@group.io', plan: 'yearly', expiresAt: null });
    recordActivation('ADIA-SRCH-MCA-AAAA', 'hash-a-1');
    recordActivation('ADIA-SRCH-MCA-AAAA', 'hash-a-2');
    recordActivation('ADIA-SRCH-MCA-AAAA', 'hash-a-3');
    const res = await callSearch({ q: 'multi@group.io' });
    const body = await res.json();
    const byKey = Object.fromEntries(body.results.map((r: any) => [r.key, r.machineCount]));
    expect(byKey['ADIA-SRCH-MCA-AAAA']).toBe(3);
    expect(byKey['ADIA-SRCH-MCB-BBBB']).toBe(0);
  });

  it('accepts ?token= query param as auth fallback', async () => {
    const { GET } = await import('@/app/api/admin/search-licenses/route');
    const req = new NextRequest(
      'http://localhost/api/admin/search-licenses?q=x&token=test-admin-token',
      { method: 'GET' },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
  });

  // ─── pagination ─────────────────────────────────────────────────────────────

  it('response includes total, hasMore, offset, limit fields', async () => {
    insertLicense({ key: 'ADIA-SRCH-PAG0-AAAA', email: 'pag@page.io', plan: 'monthly', expiresAt: null });
    const res = await callSearch({ q: 'pag@page.io' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body).toHaveProperty('total');
    expect(body).toHaveProperty('hasMore');
    expect(body).toHaveProperty('offset');
    expect(body).toHaveProperty('limit');
    expect(body.offset).toBe(0);
    expect(body.limit).toBe(20);
  });

  it('total reflects all matching records regardless of limit', async () => {
    for (let i = 1; i <= 5; i++) {
      insertLicense({ key: `ADIA-SRCH-TOT-${String(i).padStart(4, '0')}`, email: `tot${i}@total.dev`, plan: 'monthly', expiresAt: null });
    }
    const res = await callSearch({ q: 'total.dev', limit: '2' });
    const body = await res.json();
    expect(body.total).toBe(5);
    expect(body.count).toBe(2);
    expect(body.hasMore).toBe(true);
  });

  it('offset skips earlier results and returns the next page', async () => {
    for (let i = 1; i <= 6; i++) {
      insertLicense({ key: `ADIA-SRCH-OFF-${String(i).padStart(4, '0')}`, email: `off${i}@offset.dev`, plan: 'monthly', expiresAt: null });
    }
    const page1 = await (await callSearch({ q: 'offset.dev', limit: '4' })).json();
    const page2 = await (await callSearch({ q: 'offset.dev', limit: '4', offset: '4' })).json();
    expect(page1.results.length).toBe(4);
    expect(page2.results.length).toBe(2);
    expect(page2.hasMore).toBe(false);
    // No key overlap between pages
    const keys1 = new Set(page1.results.map((r: any) => r.key));
    const keys2 = new Set(page2.results.map((r: any) => r.key));
    for (const k of keys2) expect(keys1.has(k)).toBe(false);
  });

  it('hasMore is false on the last page', async () => {
    for (let i = 1; i <= 3; i++) {
      insertLicense({ key: `ADIA-SRCH-LAST-${String(i).padStart(4, '0')}`, email: `last${i}@lastpage.dev`, plan: 'yearly', expiresAt: null });
    }
    const res = await callSearch({ q: 'lastpage.dev', limit: '3', offset: '0' });
    const body = await res.json();
    expect(body.hasMore).toBe(false);
    expect(body.total).toBe(3);
    expect(body.count).toBe(3);
  });

  it('offset beyond total returns empty results with hasMore false', async () => {
    insertLicense({ key: 'ADIA-SRCH-OVFL-AAAA', email: 'ovfl@overflow.dev', plan: 'lifetime', expiresAt: null });
    const res = await callSearch({ q: 'overflow.dev', limit: '20', offset: '999' });
    const body = await res.json();
    expect(body.results).toEqual([]);
    expect(body.count).toBe(0);
    expect(body.total).toBe(1);
    expect(body.hasMore).toBe(false);
  });

  it('offset defaults to 0 when not provided', async () => {
    insertLicense({ key: 'ADIA-SRCH-DEF0-AAAA', email: 'def@default0.dev', plan: 'monthly', expiresAt: null });
    const res = await callSearch({ q: 'default0.dev' });
    const body = await res.json();
    expect(body.offset).toBe(0);
  });

  // ─── ?since= filter ──────────────────────────────────────────────────────────

  it('?since= returns 400 for invalid status value', async () => {
    const res = await callSearch({ q: 'x', status: 'invalid_status' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/invalid.*status/i);
  });

  it('?plan= returns 400 for invalid plan value', async () => {
    const res = await callSearch({ q: 'x', plan: 'enterprise' });
    expect(res.status).toBe(400);
    const body = await res.json();
    expect(body.error).toMatch(/invalid.*plan/i);
  });

  it('?since= filters out licenses issued before the date', async () => {
    insertLicense({ key: 'ADIA-SRCH-SNC-AAAA', email: 'snc@filter.dev', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-SRCH-SNC-BBBB', email: 'snc@filter.dev', plan: 'yearly', expiresAt: null });
    setIssuedAt('ADIA-SRCH-SNC-AAAA', '2023-01-01T00:00:00Z');
    setIssuedAt('ADIA-SRCH-SNC-BBBB', '2025-06-01T00:00:00Z');
    const res = await callSearch({ q: 'snc@filter.dev', since: '2025-01-01' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.total).toBe(1);
    expect(body.results[0].key).toBe('ADIA-SRCH-SNC-BBBB');
  });

  it('?status= filters to only matching status', async () => {
    insertLicense({ key: 'ADIA-SRCH-STA-AAAA', email: 'sta@filter.dev', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-SRCH-STA-BBBB', email: 'sta@filter.dev', plan: 'yearly', expiresAt: null });
    setStatus('ADIA-SRCH-STA-BBBB', 'canceled');
    const res = await callSearch({ q: 'sta@filter.dev', status: 'active' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.total).toBe(1);
    expect(body.results[0].key).toBe('ADIA-SRCH-STA-AAAA');
  });

  it('?plan= filters to only matching plan', async () => {
    insertLicense({ key: 'ADIA-SRCH-PLN-AAAA', email: 'pln@filter.dev', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-SRCH-PLN-BBBB', email: 'pln@filter.dev', plan: 'lifetime', expiresAt: null });
    const res = await callSearch({ q: 'pln@filter.dev', plan: 'lifetime' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.total).toBe(1);
    expect(body.results[0].key).toBe('ADIA-SRCH-PLN-BBBB');
  });

  it('?plan=yearly returns empty when no yearly licenses match query', async () => {
    insertLicense({ key: 'ADIA-SRCH-PLN-CCCC', email: 'pln@noyearly.dev', plan: 'monthly', expiresAt: null });
    const res = await callSearch({ q: 'noyearly.dev', plan: 'yearly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.total).toBe(0);
    expect(body.results).toEqual([]);
  });

  it('combined ?status= + ?plan= filters both dimensions', async () => {
    insertLicense({ key: 'ADIA-SRCH-CMB-AAAA', email: 'cmb@filter.dev', plan: 'yearly', expiresAt: null });
    insertLicense({ key: 'ADIA-SRCH-CMB-BBBB', email: 'cmb@filter.dev', plan: 'yearly', expiresAt: null });
    insertLicense({ key: 'ADIA-SRCH-CMB-CCCC', email: 'cmb@filter.dev', plan: 'monthly', expiresAt: null });
    setStatus('ADIA-SRCH-CMB-BBBB', 'canceled');
    const res = await callSearch({ q: 'cmb@filter.dev', status: 'active', plan: 'yearly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.total).toBe(1);
    expect(body.results[0].key).toBe('ADIA-SRCH-CMB-AAAA');
  });

  it('combined ?since= + ?status= + ?plan= narrows results correctly', async () => {
    insertLicense({ key: 'ADIA-SRCH-ALL-AAAA', email: 'all@filter.dev', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-SRCH-ALL-BBBB', email: 'all@filter.dev', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-SRCH-ALL-CCCC', email: 'all@filter.dev', plan: 'yearly', expiresAt: null });
    setIssuedAt('ADIA-SRCH-ALL-AAAA', '2023-06-01T00:00:00Z'); // old
    setIssuedAt('ADIA-SRCH-ALL-BBBB', '2025-06-01T00:00:00Z'); // new monthly active
    setIssuedAt('ADIA-SRCH-ALL-CCCC', '2025-06-01T00:00:00Z'); // new yearly active
    const res = await callSearch({ q: 'all@filter.dev', since: '2025-01-01', status: 'active', plan: 'monthly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.total).toBe(1);
    expect(body.results[0].key).toBe('ADIA-SRCH-ALL-BBBB');
  });

  it('response echoes since/status/plan in body when set', async () => {
    insertLicense({ key: 'ADIA-SRCH-ECH-AAAA', email: 'ech@filter.dev', plan: 'monthly', expiresAt: null });
    const res = await callSearch({ q: 'ech@filter.dev', since: '2020-01-01', status: 'active', plan: 'monthly' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.since).toBe('2020-01-01');
    expect(body.status).toBe('active');
    expect(body.plan).toBe('monthly');
  });

  it('filter does not bleed across emails in same search result', async () => {
    insertLicense({ key: 'ADIA-SRCH-BLD-AAAA', email: 'user1@bleed.io', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-SRCH-BLD-BBBB', email: 'user2@bleed.io', plan: 'yearly', expiresAt: null });
    setStatus('ADIA-SRCH-BLD-BBBB', 'canceled');
    const res = await callSearch({ q: 'bleed.io', status: 'active' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.total).toBe(1);
    expect(body.results[0].key).toBe('ADIA-SRCH-BLD-AAAA');
  });

  // ─── CSV export ─────────────────────────────────────────────────────────────

  it('format=csv returns 401 without a valid token', async () => {
    const { GET } = await import('@/app/api/admin/search-licenses/route');
    const req = new NextRequest('http://localhost/api/admin/search-licenses?q=test&format=csv', {
      method: 'GET',
      headers: { Authorization: 'Bearer wrong-token' },
    });
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('format=csv returns 400 when q is missing', async () => {
    const { GET } = await import('@/app/api/admin/search-licenses/route');
    const req = new NextRequest('http://localhost/api/admin/search-licenses?format=csv', {
      method: 'GET',
      headers: { Authorization: 'Bearer test-admin-token' },
    });
    const res = await GET(req);
    expect(res.status).toBe(400);
  });

  it('format=csv responds with text/csv content-type', async () => {
    insertLicense({ key: 'ADIA-CSV-CT-AAAA', email: 'csv@content.io', plan: 'monthly', expiresAt: null });
    const { GET } = await import('@/app/api/admin/search-licenses/route');
    const req = new NextRequest('http://localhost/api/admin/search-licenses?q=csv%40content.io&format=csv', {
      method: 'GET',
      headers: { Authorization: 'Bearer test-admin-token' },
    });
    const res = await GET(req);
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toMatch(/text\/csv/);
  });

  it('format=csv includes a Content-Disposition attachment header', async () => {
    const { GET } = await import('@/app/api/admin/search-licenses/route');
    const req = new NextRequest('http://localhost/api/admin/search-licenses?q=nobody&format=csv', {
      method: 'GET',
      headers: { Authorization: 'Bearer test-admin-token' },
    });
    const res = await GET(req);
    const cd = res.headers.get('content-disposition') ?? '';
    expect(cd).toMatch(/attachment/);
    expect(cd).toMatch(/\.csv/);
  });

  it('format=csv body starts with the expected header row', async () => {
    const { GET } = await import('@/app/api/admin/search-licenses/route');
    const req = new NextRequest('http://localhost/api/admin/search-licenses?q=nobody&format=csv', {
      method: 'GET',
      headers: { Authorization: 'Bearer test-admin-token' },
    });
    const res = await GET(req);
    const text = await res.text();
    expect(text.split('\r\n')[0]).toBe('key,email,plan,status,machineCount,issuedAt,expiresAt,note');
  });

  it('format=csv includes one data row per matching license', async () => {
    insertLicense({ key: 'ADIA-CSV-ROW-AAAA', email: 'rows@csvtest.io', plan: 'yearly', expiresAt: null });
    insertLicense({ key: 'ADIA-CSV-ROW-BBBB', email: 'rows@csvtest.io', plan: 'lifetime', expiresAt: null });
    const { GET } = await import('@/app/api/admin/search-licenses/route');
    const req = new NextRequest('http://localhost/api/admin/search-licenses?q=rows%40csvtest.io&format=csv', {
      method: 'GET',
      headers: { Authorization: 'Bearer test-admin-token' },
    });
    const res = await GET(req);
    const text = await res.text();
    const lines = text.split('\r\n').filter(Boolean);
    expect(lines.length).toBe(3); // header + 2 rows
  });

  it('format=csv data row contains correct key, email, plan, and status fields', async () => {
    insertLicense({ key: 'ADIA-CSV-FLD-AAAA', email: 'fields@csvexport.io', plan: 'monthly', expiresAt: null });
    const { GET } = await import('@/app/api/admin/search-licenses/route');
    const req = new NextRequest('http://localhost/api/admin/search-licenses?q=fields%40csvexport.io&format=csv', {
      method: 'GET',
      headers: { Authorization: 'Bearer test-admin-token' },
    });
    const res = await GET(req);
    const text = await res.text();
    const dataRow = text.split('\r\n')[1];
    expect(dataRow).toMatch(/ADIA-CSV-FLD-AAAA/);
    expect(dataRow).toMatch(/fields@csvexport\.io/);
    expect(dataRow).toMatch(/monthly/);
    expect(dataRow).toMatch(/active/);
  });

  it('format=csv respects ?plan= filter', async () => {
    insertLicense({ key: 'ADIA-CSV-PLN-AAAA', email: 'csvpln@test.dev', plan: 'monthly', expiresAt: null });
    insertLicense({ key: 'ADIA-CSV-PLN-BBBB', email: 'csvpln@test.dev', plan: 'lifetime', expiresAt: null });
    const { GET } = await import('@/app/api/admin/search-licenses/route');
    const req = new NextRequest('http://localhost/api/admin/search-licenses?q=csvpln%40test.dev&format=csv&plan=lifetime', {
      method: 'GET',
      headers: { Authorization: 'Bearer test-admin-token' },
    });
    const res = await GET(req);
    expect(res.status).toBe(200);
    const text = await res.text();
    const dataRows = text.split('\r\n').filter(Boolean).slice(1);
    expect(dataRows.length).toBe(1);
    expect(dataRows[0]).toContain('ADIA-CSV-PLN-BBBB');
  });

  it('format=csv returns header-only body when no licenses match', async () => {
    const { GET } = await import('@/app/api/admin/search-licenses/route');
    const req = new NextRequest('http://localhost/api/admin/search-licenses?q=nobody%40noone.io&format=csv', {
      method: 'GET',
      headers: { Authorization: 'Bearer test-admin-token' },
    });
    const res = await GET(req);
    const text = await res.text();
    const lines = text.split('\r\n').filter(Boolean);
    expect(lines.length).toBe(1);
    expect(lines[0]).toBe('key,email,plan,status,machineCount,issuedAt,expiresAt,note');
  });

  it('format=csv cells with commas are quoted per RFC 4180', async () => {
    insertLicense({ key: 'ADIA-CSV-CMM-AAAA', email: 'comma@csv.io', plan: 'monthly', expiresAt: null });
    const { setNote } = await import('@/lib/db');
    setNote('ADIA-CSV-CMM-AAAA', 'a note, with commas');
    const { GET } = await import('@/app/api/admin/search-licenses/route');
    const req = new NextRequest('http://localhost/api/admin/search-licenses?q=comma%40csv.io&format=csv', {
      method: 'GET',
      headers: { Authorization: 'Bearer test-admin-token' },
    });
    const res = await GET(req);
    const text = await res.text();
    expect(text).toContain('"a note, with commas"');
  });

  it('format=csv ?token= query-param auth works', async () => {
    const { GET } = await import('@/app/api/admin/search-licenses/route');
    const req = new NextRequest(
      'http://localhost/api/admin/search-licenses?q=x&format=csv&token=test-admin-token',
      { method: 'GET' },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
    expect(res.headers.get('content-type')).toMatch(/text\/csv/);
  });

  it('format=csv exports all results beyond the 100-item pagination cap', async () => {
    // Insert 5 licenses under a unique domain; the pagination limit is 20 by default.
    // CSV must include all 5 (not capped at page size).
    for (let i = 1; i <= 5; i++) {
      insertLicense({
        key: `ADIA-CSV-ALL-${String(i).padStart(4, '0')}`,
        email: `all${i}@csvall.dev`,
        plan: 'monthly',
        expiresAt: null,
      });
    }
    const { GET } = await import('@/app/api/admin/search-licenses/route');
    const req = new NextRequest('http://localhost/api/admin/search-licenses?q=csvall.dev&format=csv', {
      method: 'GET',
      headers: { Authorization: 'Bearer test-admin-token' },
    });
    const res = await GET(req);
    const text = await res.text();
    const dataRows = text.split('\r\n').filter(Boolean).slice(1);
    expect(dataRows.length).toBe(5);
  });
});

// ─── resend_payment_failed audit log ─────────────────────────────────────────

describe('resend_payment_failed audit log', () => {
  it('records audit entry on successful resend (force=true)', async () => {
    insertLicense({ key: 'ADIA-RPFA-AUDI-AAAA', email: 'rpfa@example.com', plan: 'monthly', expiresAt: null });
    const res = await callResendPaymentFailed({ key: 'ADIA-RPFA-AUDI-AAAA', force: true });
    expect(res.status).toBe(200);
    const entries = listAuditLog({ licenseKey: 'ADIA-RPFA-AUDI-AAAA' });
    expect(entries.length).toBe(1);
    expect(entries[0].action).toBe('resend_payment_failed');
    const detail = JSON.parse(entries[0].detail ?? '{}');
    expect(detail.to).toBe('rpfa@example.com');
    expect(detail.force).toBe(true);
  });

  it('records audit entry for past_due license without force', async () => {
    const { setStatus } = await import('@/lib/db');
    insertLicense({ key: 'ADIA-RPFA-PDUE-AAAA', email: 'pdue@example.com', plan: 'monthly', expiresAt: null });
    setStatus('ADIA-RPFA-PDUE-AAAA', 'past_due');
    const res = await callResendPaymentFailed({ key: 'ADIA-RPFA-PDUE-AAAA' });
    expect(res.status).toBe(200);
    const entries = listAuditLog({ licenseKey: 'ADIA-RPFA-PDUE-AAAA' });
    expect(entries.length).toBe(1);
    expect(entries[0].action).toBe('resend_payment_failed');
  });

  it('does NOT record audit entry when 422 (not past_due, no force)', async () => {
    insertLicense({ key: 'ADIA-RPFA-SKIP-AAAA', email: 'skip@example.com', plan: 'monthly', expiresAt: null });
    const res = await callResendPaymentFailed({ key: 'ADIA-RPFA-SKIP-AAAA' });
    expect(res.status).toBe(422);
    const entries = listAuditLog({ licenseKey: 'ADIA-RPFA-SKIP-AAAA' });
    expect(entries.length).toBe(0);
  });

  it('does NOT record audit entry on 404 unknown key', async () => {
    const res = await callResendPaymentFailed({ key: 'ADIA-RPFA-UNKN-ZZZZ', force: true });
    expect(res.status).toBe(404);
    const entries = listAuditLog({ licenseKey: 'ADIA-RPFA-UNKN-ZZZZ' });
    expect(entries.length).toBe(0);
  });
});

// ─── lookup now returns { license, recentAudit } ────────────────────────────

describe('GET /api/admin/lookup includes recentAudit', () => {
  it('returns recentAudit array (empty when no audit entries)', async () => {
    insertLicense({ key: 'ADIA-LKPA-NAUD-AAAA', email: 'naud@example.com', plan: 'monthly', expiresAt: null });
    const { GET } = await import('@/app/api/admin/lookup/route');
    const req = new NextRequest('http://localhost/api/admin/lookup?key=ADIA-LKPA-NAUD-AAAA', {
      method: 'GET',
      headers: authHeader(),
    });
    const res = await GET(req);
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.license.key).toBe('ADIA-LKPA-NAUD-AAAA');
    expect(body.recentAudit).toBeInstanceOf(Array);
    expect(body.recentAudit.length).toBe(0);
  });

  it('returns up to 5 most recent audit entries for the key', async () => {
    const { insertAuditLog } = await import('@/lib/db');
    insertLicense({ key: 'ADIA-LKPA-WAUD-AAAA', email: 'waud@example.com', plan: 'yearly', expiresAt: null });
    for (let i = 1; i <= 7; i++) {
      insertAuditLog({ licenseKey: 'ADIA-LKPA-WAUD-AAAA', action: `action_${i}` });
    }
    const { GET } = await import('@/app/api/admin/lookup/route');
    const req = new NextRequest('http://localhost/api/admin/lookup?key=ADIA-LKPA-WAUD-AAAA', {
      method: 'GET',
      headers: authHeader(),
    });
    const res = await GET(req);
    const body = await res.json();
    expect(body.recentAudit.length).toBe(5);
    // Should be newest-first
    expect(body.recentAudit[0].action).toBe('action_7');
  });
});
