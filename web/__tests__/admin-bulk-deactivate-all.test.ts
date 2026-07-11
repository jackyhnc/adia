// Tests for POST /api/admin/bulk-deactivate-all
// Body: { keys: string[] }

import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import os from 'node:os';
import path from 'node:path';
import fs from 'node:fs';
import { NextRequest } from 'next/server';
import { resetDbForTesting, insertLicense, recordActivation, countActivations, listAuditLog } from '@/lib/db';
import { _resetForTesting as resetRateLimit } from '@/lib/ratelimit';

let dbPath: string;

beforeEach(() => {
  resetRateLimit();
  dbPath = path.join(
    os.tmpdir(),
    `adia-bulk-deact-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
  );
  resetDbForTesting(dbPath);
  process.env.ADMIN_TOKEN = 'test-admin-token';
});

afterEach(() => {
  resetDbForTesting();
  delete process.env.ADMIN_TOKEN;
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

async function callBulkDeactivateAll(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/bulk-deactivate-all/route');
  const req = new NextRequest('http://localhost/api/admin/bulk-deactivate-all', {
    method: 'POST',
    body: JSON.stringify(body),
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${token}`,
    },
  });
  return POST(req);
}

function seedLicense(key: string, email = 'owner@example.com') {
  insertLicense({ key, email, plan: 'lifetime', expiresAt: null });
}

function addActivation(key: string, machineHash: string) {
  recordActivation(key, machineHash);
}

// ─── Auth ─────────────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-deactivate-all — auth', () => {
  it('returns 401 with no token', async () => {
    const { POST } = await import('@/app/api/admin/bulk-deactivate-all/route');
    const req = new NextRequest('http://localhost/api/admin/bulk-deactivate-all', {
      method: 'POST',
      body: JSON.stringify({ keys: ['ADIA-BDAC-AUTH-0001'] }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callBulkDeactivateAll({ keys: ['ADIA-BDAC-AUTH-0002'] }, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query param', async () => {
    seedLicense('ADIA-BDAC-AUTH-0003');
    addActivation('ADIA-BDAC-AUTH-0003', 'machine-auth-003');
    const { POST } = await import('@/app/api/admin/bulk-deactivate-all/route');
    const req = new NextRequest(
      'http://localhost/api/admin/bulk-deactivate-all?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ keys: ['ADIA-BDAC-AUTH-0003'] }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-deactivate-all — validation', () => {
  it('returns 400 when keys is missing', async () => {
    const res = await callBulkDeactivateAll({});
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/keys/);
  });

  it('returns 400 when keys is empty', async () => {
    const res = await callBulkDeactivateAll({ keys: [] });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/keys/);
  });

  it('returns 400 when keys exceeds 100', async () => {
    const keys = Array.from({ length: 101 }, (_, i) => `ADIA-BDAC-VAL-${String(i).padStart(4, '0')}`);
    const res = await callBulkDeactivateAll({ keys });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/100/);
  });
});

// ─── Core behavior ────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-deactivate-all — core behavior', () => {
  it('removes all activations for a single key', async () => {
    seedLicense('ADIA-BDAC-CORE-0001');
    addActivation('ADIA-BDAC-CORE-0001', 'machine-core-001a');
    addActivation('ADIA-BDAC-CORE-0001', 'machine-core-001b');
    expect(countActivations('ADIA-BDAC-CORE-0001')).toBe(2);

    const res = await callBulkDeactivateAll({ keys: ['ADIA-BDAC-CORE-0001'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BDAC-CORE-0001');
    expect(body.changed[0].removedCount).toBe(2);
    expect(countActivations('ADIA-BDAC-CORE-0001')).toBe(0);
  });

  it('removes activations for multiple keys in one request', async () => {
    for (const key of ['ADIA-BDAC-CORE-0002', 'ADIA-BDAC-CORE-0003']) {
      seedLicense(key);
      addActivation(key, `machine-core-${key.slice(-4)}`);
    }
    const res = await callBulkDeactivateAll({
      keys: ['ADIA-BDAC-CORE-0002', 'ADIA-BDAC-CORE-0003'],
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(2);
    expect(countActivations('ADIA-BDAC-CORE-0002')).toBe(0);
    expect(countActivations('ADIA-BDAC-CORE-0003')).toBe(0);
  });

  it('normalizes keys to uppercase', async () => {
    seedLicense('ADIA-BDAC-CORE-0004');
    addActivation('ADIA-BDAC-CORE-0004', 'machine-core-004');
    const res = await callBulkDeactivateAll({ keys: ['adia-bdac-core-0004'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed[0].key).toBe('ADIA-BDAC-CORE-0004');
    expect(countActivations('ADIA-BDAC-CORE-0004')).toBe(0);
  });

  it('returns correct removedCount when one machine activated', async () => {
    seedLicense('ADIA-BDAC-CORE-0005');
    addActivation('ADIA-BDAC-CORE-0005', 'machine-core-005');
    const res = await callBulkDeactivateAll({ keys: ['ADIA-BDAC-CORE-0005'] });
    const body = await res.json();
    expect(body.changed[0].removedCount).toBe(1);
  });

  it('returns correct removedCount when three machines activated', async () => {
    seedLicense('ADIA-BDAC-CORE-0006');
    addActivation('ADIA-BDAC-CORE-0006', 'machine-core-006a');
    addActivation('ADIA-BDAC-CORE-0006', 'machine-core-006b');
    addActivation('ADIA-BDAC-CORE-0006', 'machine-core-006c');
    const res = await callBulkDeactivateAll({ keys: ['ADIA-BDAC-CORE-0006'] });
    const body = await res.json();
    expect(body.changed[0].removedCount).toBe(3);
  });
});

// ─── Skip behavior ────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-deactivate-all — skip behavior', () => {
  it('skips unknown keys with reason=not_found', async () => {
    const res = await callBulkDeactivateAll({ keys: ['ADIA-BDAC-SKIP-0001'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].key).toBe('ADIA-BDAC-SKIP-0001');
    expect(body.skipped[0].reason).toBe('not_found');
  });

  it('skips keys with no activations with reason=already_clear', async () => {
    seedLicense('ADIA-BDAC-SKIP-0002');
    // no addActivation call — zero seats used
    const res = await callBulkDeactivateAll({ keys: ['ADIA-BDAC-SKIP-0002'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].key).toBe('ADIA-BDAC-SKIP-0002');
    expect(body.skipped[0].reason).toBe('already_clear');
  });

  it('handles mixed changed + not_found + already_clear in one request', async () => {
    seedLicense('ADIA-BDAC-SKIP-0003');
    addActivation('ADIA-BDAC-SKIP-0003', 'machine-skip-003');
    seedLicense('ADIA-BDAC-SKIP-0004');
    // ADIA-BDAC-SKIP-0004 has no activations → already_clear
    // ADIA-BDAC-SKIP-0005 does not exist → not_found

    const res = await callBulkDeactivateAll({
      keys: ['ADIA-BDAC-SKIP-0003', 'ADIA-BDAC-SKIP-0004', 'ADIA-BDAC-SKIP-0005'],
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BDAC-SKIP-0003');
    expect(body.skipped).toHaveLength(2);
    const reasons = body.skipped.map((s: { reason: string }) => s.reason);
    expect(reasons).toContain('not_found');
    expect(reasons).toContain('already_clear');
  });

  it('does not mutate a skipped (already_clear) key', async () => {
    seedLicense('ADIA-BDAC-SKIP-0006');
    await callBulkDeactivateAll({ keys: ['ADIA-BDAC-SKIP-0006'] });
    expect(countActivations('ADIA-BDAC-SKIP-0006')).toBe(0);
  });
});

// ─── Audit log ────────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-deactivate-all — audit log', () => {
  it('writes one audit log entry per changed key', async () => {
    seedLicense('ADIA-BDAC-AUDT-0001');
    seedLicense('ADIA-BDAC-AUDT-0002');
    addActivation('ADIA-BDAC-AUDT-0001', 'machine-audt-001');
    addActivation('ADIA-BDAC-AUDT-0002', 'machine-audt-002');

    await callBulkDeactivateAll({ keys: ['ADIA-BDAC-AUDT-0001', 'ADIA-BDAC-AUDT-0002'] });

    for (const key of ['ADIA-BDAC-AUDT-0001', 'ADIA-BDAC-AUDT-0002']) {
      const logs = listAuditLog({ licenseKey: key });
      expect(logs).toHaveLength(1);
      expect(logs[0].action).toBe('deactivate_all');
    }
  });

  it('audit log detail contains removedCount and bulk=true', async () => {
    seedLicense('ADIA-BDAC-AUDT-0003');
    addActivation('ADIA-BDAC-AUDT-0003', 'machine-audt-003a');
    addActivation('ADIA-BDAC-AUDT-0003', 'machine-audt-003b');

    await callBulkDeactivateAll({ keys: ['ADIA-BDAC-AUDT-0003'] });

    const logs = listAuditLog({ licenseKey: 'ADIA-BDAC-AUDT-0003' });
    const detail =
      typeof logs[0].detail === 'string' ? JSON.parse(logs[0].detail) : logs[0].detail;
    expect(detail).toMatchObject({ removedCount: 2, bulk: true });
  });

  it('writes no audit log entry for skipped keys', async () => {
    seedLicense('ADIA-BDAC-AUDT-0004');
    // no activations → already_clear skip
    await callBulkDeactivateAll({ keys: ['ADIA-BDAC-AUDT-0004', 'ADIA-BDAC-AUDT-NOT-FOUND'] });

    expect(listAuditLog({ licenseKey: 'ADIA-BDAC-AUDT-0004' })).toHaveLength(0);
    expect(listAuditLog({ licenseKey: 'ADIA-BDAC-AUDT-NOT-FOUND' })).toHaveLength(0);
  });
});

// ─── Rate limit ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-deactivate-all — rate limit', () => {
  it('returns 429 after 20 requests from the same IP', async () => {
    const { POST } = await import('@/app/api/admin/bulk-deactivate-all/route');
    const ip = '10.98.3.1';
    let lastStatus = 0;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-deactivate-all', {
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
    const { POST } = await import('@/app/api/admin/bulk-deactivate-all/route');
    const ip = '10.98.3.2';
    let lastRes: Response | null = null;
    for (let i = 0; i < 21; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-deactivate-all', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
        body: JSON.stringify({}),
      });
      lastRes = await POST(req);
    }
    expect(lastRes?.headers.get('Retry-After')).toBeTruthy();
  });

  it('rate limit fires before auth check — wrong token still gets 429 when bucket exhausted', async () => {
    const { POST } = await import('@/app/api/admin/bulk-deactivate-all/route');
    const ip = '10.98.3.3';
    for (let i = 0; i < 20; i++) {
      const req = new NextRequest('http://localhost/api/admin/bulk-deactivate-all', {
        method: 'POST',
        headers: { Authorization: 'Bearer test-admin-token', 'x-forwarded-for': ip },
        body: JSON.stringify({}),
      });
      await POST(req);
    }
    const req = new NextRequest('http://localhost/api/admin/bulk-deactivate-all', {
      method: 'POST',
      headers: { Authorization: 'Bearer wrong-token', 'x-forwarded-for': ip },
      body: JSON.stringify({}),
    });
    const res = await POST(req);
    expect(res.status).toBe(429);
  });
});
