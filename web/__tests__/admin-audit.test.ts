// Tests for:
//   lib/db  — logAdminAction, listAdminAuditLog
//   GET /api/admin/audit-log — auth, filtering, limit

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import {
  resetDbForTesting,
  insertLicense,
  logAdminAction,
  listAdminAuditLog,
} from '@/lib/db';

let dbPath: string;

beforeEach(() => {
  dbPath = path.join(
    os.tmpdir(),
    `adia-audit-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
  );
  resetDbForTesting(dbPath);
  process.env.ADMIN_TOKEN = 'test-admin-token';
});

afterEach(() => {
  resetDbForTesting();
  delete process.env.ADMIN_TOKEN;
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

// ─── DB-layer tests ───────────────────────────────────────────────────────────

describe('logAdminAction / listAdminAuditLog', () => {
  it('records an entry and reads it back', () => {
    logAdminAction('revoke', 'ADIA-TEST-0001', { previousStatus: 'active', newStatus: 'canceled' });
    const entries = listAdminAuditLog();
    expect(entries).toHaveLength(1);
    expect(entries[0].action).toBe('revoke');
    expect(entries[0].licenseKey).toBe('ADIA-TEST-0001');
    expect(entries[0].details).toEqual({ previousStatus: 'active', newStatus: 'canceled' });
    expect(entries[0].performedAt).toBeTruthy();
    expect(typeof entries[0].id).toBe('number');
  });

  it('returns entries newest-first', () => {
    logAdminAction('issue', 'ADIA-A', { plan: 'monthly' });
    logAdminAction('revoke', 'ADIA-B', {});
    const entries = listAdminAuditLog();
    expect(entries[0].action).toBe('revoke');
    expect(entries[1].action).toBe('issue');
  });

  it('filters by license key (case-insensitive normalisation)', () => {
    logAdminAction('extend', 'ADIA-ALPHA', { days: 30 });
    logAdminAction('revoke', 'ADIA-BETA', {});
    const entries = listAdminAuditLog({ key: 'ADIA-ALPHA' });
    expect(entries).toHaveLength(1);
    expect(entries[0].licenseKey).toBe('ADIA-ALPHA');
  });

  it('respects the limit parameter', () => {
    for (let i = 0; i < 10; i++) {
      logAdminAction('extend', `ADIA-${i.toString().padStart(4, '0')}`, { days: i });
    }
    const entries = listAdminAuditLog({ limit: 3 });
    expect(entries).toHaveLength(3);
  });

  it('defaults to empty details when not provided', () => {
    logAdminAction('reactivate', 'ADIA-EMPTY', {});
    const [entry] = listAdminAuditLog();
    expect(entry.details).toEqual({});
  });
});

// ─── Endpoint tests ───────────────────────────────────────────────────────────

function authHeader(token = 'test-admin-token') {
  return { Authorization: `Bearer ${token}` };
}

async function callAuditLog(
  params: Record<string, string> = {},
  token = 'test-admin-token',
) {
  const { GET } = await import('@/app/api/admin/audit-log/route');
  const qs = new URLSearchParams(params).toString();
  const url = `http://localhost/api/admin/audit-log${qs ? '?' + qs : ''}`;
  const req = new NextRequest(url, { method: 'GET', headers: authHeader(token) });
  return GET(req);
}

describe('GET /api/admin/audit-log', () => {
  it('returns 401 without token', async () => {
    const { GET } = await import('@/app/api/admin/audit-log/route');
    const req = new NextRequest('http://localhost/api/admin/audit-log', { method: 'GET' });
    const res = await GET(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callAuditLog({}, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('returns empty entries when log is empty', async () => {
    const res = await callAuditLog();
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.entries).toEqual([]);
    expect(body.count).toBe(0);
  });

  it('returns 400 for out-of-range limit', async () => {
    const res = await callAuditLog({ limit: '0' });
    expect(res.status).toBe(400);
  });

  it('returns 400 for limit > 500', async () => {
    const res = await callAuditLog({ limit: '501' });
    expect(res.status).toBe(400);
  });

  it('returns all entries with correct shape', async () => {
    logAdminAction('revoke', 'ADIA-ENDPT', { previousStatus: 'active' });
    const res = await callAuditLog();
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    const entry = body.entries[0];
    expect(entry.action).toBe('revoke');
    expect(entry.licenseKey).toBe('ADIA-ENDPT');
    expect(entry.details).toEqual({ previousStatus: 'active' });
    expect(entry.performedAt).toBeTruthy();
  });

  it('filters by key param', async () => {
    logAdminAction('extend', 'ADIA-FILTER', { days: 7 });
    logAdminAction('issue', 'ADIA-OTHER', { plan: 'monthly' });
    const res = await callAuditLog({ key: 'ADIA-FILTER' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(1);
    expect(body.entries[0].licenseKey).toBe('ADIA-FILTER');
  });

  it('respects limit param', async () => {
    for (let i = 0; i < 5; i++) {
      logAdminAction('extend', `ADIA-LIM${i}`, { days: i });
    }
    const res = await callAuditLog({ limit: '2' });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.count).toBe(2);
    expect(body.entries).toHaveLength(2);
  });

  it('entries are returned newest-first', async () => {
    logAdminAction('issue', 'ADIA-FIRST', {});
    logAdminAction('revoke', 'ADIA-SECOND', {});
    const res = await callAuditLog();
    const body = await res.json();
    expect(body.entries[0].licenseKey).toBe('ADIA-SECOND');
    expect(body.entries[1].licenseKey).toBe('ADIA-FIRST');
  });

  it('token query-param fallback is accepted', async () => {
    const { GET } = await import('@/app/api/admin/audit-log/route');
    const req = new NextRequest(
      'http://localhost/api/admin/audit-log?token=test-admin-token',
      { method: 'GET' },
    );
    const res = await GET(req);
    expect(res.status).toBe(200);
  });
});
