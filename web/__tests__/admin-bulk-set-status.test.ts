import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, findLicense, insertLicense, listAuditLog, setStatus } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-bulk-set-status-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
  );
  resetDbForTesting(dbPath);
  process.env.ADMIN_TOKEN = 'test-admin-token';
});

afterEach(() => {
  resetDbForTesting();
  delete process.env.ADMIN_TOKEN;
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

async function callBulkSetStatus(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/bulk-set-status/route');
  const req = new NextRequest('http://localhost/api/admin/bulk-set-status', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });
  return POST(req);
}

function seedLicense(
  key: string,
  email = 'owner@example.com',
  plan: 'lifetime' | 'monthly' | 'yearly' = 'lifetime',
) {
  insertLicense({ key, email, plan, expiresAt: null });
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-set-status — auth', () => {
  it('returns 401 with no token', async () => {
    const { POST } = await import('@/app/api/admin/bulk-set-status/route');
    const req = new NextRequest('http://localhost/api/admin/bulk-set-status', {
      method: 'POST',
      body: JSON.stringify({ keys: ['ADIA-BSS-AUTH-0001'], status: 'canceled' }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callBulkSetStatus(
      { keys: ['ADIA-BSS-AUTH-0002'], status: 'canceled' },
      'wrong-token',
    );
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query param', async () => {
    seedLicense('ADIA-BSS-AUTH-0003');
    const { POST } = await import('@/app/api/admin/bulk-set-status/route');
    const req = new NextRequest(
      'http://localhost/api/admin/bulk-set-status?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ keys: ['ADIA-BSS-AUTH-0003'], status: 'canceled' }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-set-status — validation', () => {
  it('returns 400 when keys is missing', async () => {
    const res = await callBulkSetStatus({ status: 'canceled' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/keys/);
  });

  it('returns 400 when keys is empty', async () => {
    const res = await callBulkSetStatus({ keys: [], status: 'canceled' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/keys/);
  });

  it('returns 400 when keys exceeds 100', async () => {
    const keys = Array.from(
      { length: 101 },
      (_, i) => `ADIA-BSS-VAL-${String(i).padStart(4, '0')}`,
    );
    const res = await callBulkSetStatus({ keys, status: 'canceled' });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/100/);
  });

  it('returns 400 when status is missing', async () => {
    const res = await callBulkSetStatus({ keys: ['ADIA-BSS-VAL-STAT-0001'] });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/status/);
  });

  it('returns 400 when status is invalid', async () => {
    const res = await callBulkSetStatus({
      keys: ['ADIA-BSS-VAL-STAT-0002'],
      status: 'suspended',
    });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/status/);
  });
});

// ─── Core behavior ────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-set-status — core behavior', () => {
  it('sets a single active key to canceled', async () => {
    seedLicense('ADIA-BSS-CORE-0001');
    const res = await callBulkSetStatus({
      keys: ['ADIA-BSS-CORE-0001'],
      status: 'canceled',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BSS-CORE-0001');
    expect(body.skipped).toHaveLength(0);
    expect(findLicense('ADIA-BSS-CORE-0001')?.status).toBe('canceled');
  });

  it('sets multiple keys to expired in one request', async () => {
    seedLicense('ADIA-BSS-CORE-0002');
    seedLicense('ADIA-BSS-CORE-0003');
    seedLicense('ADIA-BSS-CORE-0004');
    const res = await callBulkSetStatus({
      keys: ['ADIA-BSS-CORE-0002', 'ADIA-BSS-CORE-0003', 'ADIA-BSS-CORE-0004'],
      status: 'expired',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(3);
    for (const key of ['ADIA-BSS-CORE-0002', 'ADIA-BSS-CORE-0003', 'ADIA-BSS-CORE-0004']) {
      expect(findLicense(key)?.status).toBe('expired');
    }
  });

  it('normalizes keys to uppercase', async () => {
    seedLicense('ADIA-BSS-CORE-0005');
    const res = await callBulkSetStatus({
      keys: ['adia-bss-core-0005'],
      status: 'expired',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed[0].key).toBe('ADIA-BSS-CORE-0005');
    expect(findLicense('ADIA-BSS-CORE-0005')?.status).toBe('expired');
  });

  it('returns previousStatus in each changed entry', async () => {
    seedLicense('ADIA-BSS-CORE-0006');
    const res = await callBulkSetStatus({
      keys: ['ADIA-BSS-CORE-0006'],
      status: 'expired',
    });
    const body = await res.json();
    expect(body.changed[0].previousStatus).toBe('active');
  });

  it('sets active → past_due', async () => {
    seedLicense('ADIA-BSS-CORE-0007');
    const res = await callBulkSetStatus({
      keys: ['ADIA-BSS-CORE-0007'],
      status: 'past_due',
    });
    expect((await res.json()).changed[0].previousStatus).toBe('active');
    expect(findLicense('ADIA-BSS-CORE-0007')?.status).toBe('past_due');
  });

  it('sets canceled → active (re-activation)', async () => {
    seedLicense('ADIA-BSS-CORE-0008');
    setStatus('ADIA-BSS-CORE-0008', 'canceled');
    const res = await callBulkSetStatus({
      keys: ['ADIA-BSS-CORE-0008'],
      status: 'active',
    });
    expect(res.status).toBe(200);
    expect((await res.json()).changed[0].previousStatus).toBe('canceled');
    expect(findLicense('ADIA-BSS-CORE-0008')?.status).toBe('active');
  });

  it('sets expired → active', async () => {
    seedLicense('ADIA-BSS-CORE-0009');
    setStatus('ADIA-BSS-CORE-0009', 'expired');
    const res = await callBulkSetStatus({
      keys: ['ADIA-BSS-CORE-0009'],
      status: 'active',
    });
    expect(res.status).toBe(200);
    expect((await res.json()).changed[0].previousStatus).toBe('expired');
    expect(findLicense('ADIA-BSS-CORE-0009')?.status).toBe('active');
  });

  it('sets past_due → canceled', async () => {
    seedLicense('ADIA-BSS-CORE-0010');
    setStatus('ADIA-BSS-CORE-0010', 'past_due');
    const res = await callBulkSetStatus({
      keys: ['ADIA-BSS-CORE-0010'],
      status: 'canceled',
    });
    expect(res.status).toBe(200);
    expect((await res.json()).changed[0].previousStatus).toBe('past_due');
    expect(findLicense('ADIA-BSS-CORE-0010')?.status).toBe('canceled');
  });

  it('accepts all four valid target statuses', async () => {
    const validStatuses = ['active', 'canceled', 'expired', 'past_due'] as const;
    for (const [i, status] of validStatuses.entries()) {
      const key = `ADIA-BSS-CORE-${String(11 + i).padStart(4, '0')}`;
      seedLicense(key);
      const res = await callBulkSetStatus({ keys: [key], status });
      expect(res.status).toBe(200);
    }
  });
});

// ─── Skip behavior ────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-set-status — skip behavior', () => {
  it('skips unknown keys with reason=not_found', async () => {
    const res = await callBulkSetStatus({
      keys: ['ADIA-BSS-SKIP-0001'],
      status: 'canceled',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].key).toBe('ADIA-BSS-SKIP-0001');
    expect(body.skipped[0].reason).toBe('not_found');
  });

  it('skips keys already at the target status with reason=already_set', async () => {
    seedLicense('ADIA-BSS-SKIP-0002');
    setStatus('ADIA-BSS-SKIP-0002', 'canceled');
    const res = await callBulkSetStatus({
      keys: ['ADIA-BSS-SKIP-0002'],
      status: 'canceled',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].key).toBe('ADIA-BSS-SKIP-0002');
    expect(body.skipped[0].reason).toBe('already_set');
  });

  it('handles mixed changed + skipped in one request', async () => {
    seedLicense('ADIA-BSS-SKIP-0003'); // will change: active → expired
    seedLicense('ADIA-BSS-SKIP-0004');
    setStatus('ADIA-BSS-SKIP-0004', 'expired'); // will skip: already_set
    // ADIA-BSS-SKIP-0005 does not exist → not_found
    const res = await callBulkSetStatus({
      keys: ['ADIA-BSS-SKIP-0003', 'ADIA-BSS-SKIP-0004', 'ADIA-BSS-SKIP-0005'],
      status: 'expired',
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BSS-SKIP-0003');
    expect(body.skipped).toHaveLength(2);
    const reasons = body.skipped.map((s: { reason: string }) => s.reason);
    expect(reasons).toContain('already_set');
    expect(reasons).toContain('not_found');
  });

  it('does not mutate a skipped key', async () => {
    seedLicense('ADIA-BSS-SKIP-0006');
    setStatus('ADIA-BSS-SKIP-0006', 'expired');
    await callBulkSetStatus({ keys: ['ADIA-BSS-SKIP-0006'], status: 'expired' });
    expect(findLicense('ADIA-BSS-SKIP-0006')?.status).toBe('expired');
  });
});

// ─── Audit log ────────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-set-status — audit log', () => {
  it('writes one set_status audit entry per changed key', async () => {
    seedLicense('ADIA-BSS-AUDT-0001');
    seedLicense('ADIA-BSS-AUDT-0002');
    await callBulkSetStatus({
      keys: ['ADIA-BSS-AUDT-0001', 'ADIA-BSS-AUDT-0002'],
      status: 'expired',
    });
    for (const key of ['ADIA-BSS-AUDT-0001', 'ADIA-BSS-AUDT-0002']) {
      const logs = listAuditLog({ licenseKey: key });
      expect(logs).toHaveLength(1);
      expect(logs[0].action).toBe('set_status');
    }
  });

  it('audit detail contains previousStatus, newStatus, bulk=true', async () => {
    seedLicense('ADIA-BSS-AUDT-0003');
    await callBulkSetStatus({ keys: ['ADIA-BSS-AUDT-0003'], status: 'past_due' });
    const logs = listAuditLog({ licenseKey: 'ADIA-BSS-AUDT-0003' });
    const detail =
      typeof logs[0].detail === 'string' ? JSON.parse(logs[0].detail) : logs[0].detail;
    expect(detail).toMatchObject({
      previousStatus: 'active',
      newStatus: 'past_due',
      bulk: true,
    });
  });

  it('does not write audit log for not_found keys', async () => {
    await callBulkSetStatus({ keys: ['ADIA-BSS-AUDT-NONE'], status: 'canceled' });
    const logs = listAuditLog({ licenseKey: 'ADIA-BSS-AUDT-NONE' });
    expect(logs).toHaveLength(0);
  });

  it('does not write audit log for already_set keys', async () => {
    seedLicense('ADIA-BSS-AUDT-0004');
    setStatus('ADIA-BSS-AUDT-0004', 'canceled');
    await callBulkSetStatus({ keys: ['ADIA-BSS-AUDT-0004'], status: 'canceled' });
    const logs = listAuditLog({ licenseKey: 'ADIA-BSS-AUDT-0004' });
    expect(logs).toHaveLength(0);
  });
});

// ─── Rate limit ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-set-status — rate limit', () => {
  it('returns 429 after 20 requests from the same IP', async () => {
    const { POST } = await import('@/app/api/admin/bulk-set-status/route');
    const ip = '10.98.11.1';
    let lastStatus = 0;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-set-status', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
        body: JSON.stringify({}),
      });
      const res = await POST(req);
      lastStatus = res.status;
    }
    expect(lastStatus).toBe(429);
  });

  it('429 response includes Retry-After header', async () => {
    const { POST } = await import('@/app/api/admin/bulk-set-status/route');
    const ip = '10.98.11.2';
    let lastRes: Response | null = null;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-set-status', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
        body: JSON.stringify({}),
      });
      lastRes = await POST(req);
    }
    expect(lastRes?.headers.get('Retry-After')).toBeTruthy();
  });

  it('rate limit fires before auth check — wrong token still gets 429 when bucket exhausted', async () => {
    const { POST } = await import('@/app/api/admin/bulk-set-status/route');
    const ip = '10.98.11.3';
    for (let i = 0; i < 20; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-set-status', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
        body: JSON.stringify({}),
      });
      await POST(req);
    }
    const req = new NextRequest('http://localhost/api/admin/bulk-set-status', {
      method: 'POST',
      headers: { Authorization: 'Bearer wrong-token', 'x-forwarded-for': ip },
      body: JSON.stringify({}),
    });
    const res = await POST(req);
    expect(res.status).toBe(429);
  });
});
