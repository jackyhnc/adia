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
    `adia-bulk-reactivate-${Date.now()}-${Math.random().toString(36).slice(2)}.db`,
  );
  resetDbForTesting(dbPath);
  process.env.ADMIN_TOKEN = 'test-admin-token';
});

afterEach(() => {
  resetDbForTesting();
  delete process.env.ADMIN_TOKEN;
  if (fs.existsSync(dbPath)) fs.unlinkSync(dbPath);
});

async function callBulkReactivate(body: unknown, token = 'test-admin-token') {
  const { POST } = await import('@/app/api/admin/bulk-reactivate/route');
  const req = new NextRequest('http://localhost/api/admin/bulk-reactivate', {
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

describe('POST /api/admin/bulk-reactivate — auth', () => {
  it('returns 401 with no token', async () => {
    const { POST } = await import('@/app/api/admin/bulk-reactivate/route');
    const req = new NextRequest('http://localhost/api/admin/bulk-reactivate', {
      method: 'POST',
      body: JSON.stringify({ keys: ['ADIA-BRA-AUTH-0001'] }),
      headers: { 'Content-Type': 'application/json' },
    });
    const res = await POST(req);
    expect(res.status).toBe(401);
  });

  it('returns 401 with wrong token', async () => {
    const res = await callBulkReactivate({ keys: ['ADIA-BRA-AUTH-0002'] }, 'wrong-token');
    expect(res.status).toBe(401);
  });

  it('accepts ?token= query param', async () => {
    seedLicense('ADIA-BRA-AUTH-0003');
    setStatus('ADIA-BRA-AUTH-0003', 'canceled');
    const { POST } = await import('@/app/api/admin/bulk-reactivate/route');
    const req = new NextRequest(
      'http://localhost/api/admin/bulk-reactivate?token=test-admin-token',
      {
        method: 'POST',
        body: JSON.stringify({ keys: ['ADIA-BRA-AUTH-0003'] }),
        headers: { 'Content-Type': 'application/json' },
      },
    );
    const res = await POST(req);
    expect(res.status).toBe(200);
  });
});

// ─── Validation ───────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-reactivate — validation', () => {
  it('returns 400 when keys is missing', async () => {
    const res = await callBulkReactivate({});
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/keys/);
  });

  it('returns 400 when keys is empty', async () => {
    const res = await callBulkReactivate({ keys: [] });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/keys/);
  });

  it('returns 400 when keys exceeds 100', async () => {
    const keys = Array.from({ length: 101 }, (_, i) => `ADIA-BRA-VAL-${String(i).padStart(4, '0')}`);
    const res = await callBulkReactivate({ keys });
    expect(res.status).toBe(400);
    expect((await res.json()).error).toMatch(/100/);
  });
});

// ─── Core behavior ────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-reactivate — core behavior', () => {
  it('reactivates a single canceled key', async () => {
    seedLicense('ADIA-BRA-CORE-0001');
    setStatus('ADIA-BRA-CORE-0001', 'canceled');
    const res = await callBulkReactivate({ keys: ['ADIA-BRA-CORE-0001'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.ok).toBe(true);
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BRA-CORE-0001');
    expect(body.skipped).toHaveLength(0);
    expect(findLicense('ADIA-BRA-CORE-0001')?.status).toBe('active');
  });

  it('reactivates multiple keys in one request', async () => {
    seedLicense('ADIA-BRA-CORE-0002');
    seedLicense('ADIA-BRA-CORE-0003');
    seedLicense('ADIA-BRA-CORE-0004');
    for (const k of ['ADIA-BRA-CORE-0002', 'ADIA-BRA-CORE-0003', 'ADIA-BRA-CORE-0004']) {
      setStatus(k, 'canceled');
    }
    const res = await callBulkReactivate({
      keys: ['ADIA-BRA-CORE-0002', 'ADIA-BRA-CORE-0003', 'ADIA-BRA-CORE-0004'],
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(3);
    for (const key of ['ADIA-BRA-CORE-0002', 'ADIA-BRA-CORE-0003', 'ADIA-BRA-CORE-0004']) {
      expect(findLicense(key)?.status).toBe('active');
    }
  });

  it('normalizes keys to uppercase', async () => {
    seedLicense('ADIA-BRA-CORE-0005');
    setStatus('ADIA-BRA-CORE-0005', 'expired');
    const res = await callBulkReactivate({ keys: ['adia-bra-core-0005'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed[0].key).toBe('ADIA-BRA-CORE-0005');
    expect(findLicense('ADIA-BRA-CORE-0005')?.status).toBe('active');
  });

  it('returns previousStatus=canceled in changed entry', async () => {
    seedLicense('ADIA-BRA-CORE-0006');
    setStatus('ADIA-BRA-CORE-0006', 'canceled');
    const res = await callBulkReactivate({ keys: ['ADIA-BRA-CORE-0006'] });
    const body = await res.json();
    expect(body.changed[0].previousStatus).toBe('canceled');
  });

  it('reactivates an expired license — previousStatus=expired', async () => {
    seedLicense('ADIA-BRA-CORE-0007');
    setStatus('ADIA-BRA-CORE-0007', 'expired');
    const res = await callBulkReactivate({ keys: ['ADIA-BRA-CORE-0007'] });
    const body = await res.json();
    expect(body.changed[0].previousStatus).toBe('expired');
    expect(findLicense('ADIA-BRA-CORE-0007')?.status).toBe('active');
  });

  it('reactivates a past_due license — previousStatus=past_due', async () => {
    seedLicense('ADIA-BRA-CORE-0008');
    setStatus('ADIA-BRA-CORE-0008', 'past_due');
    const res = await callBulkReactivate({ keys: ['ADIA-BRA-CORE-0008'] });
    const body = await res.json();
    expect(body.changed[0].previousStatus).toBe('past_due');
    expect(findLicense('ADIA-BRA-CORE-0008')?.status).toBe('active');
  });
});

// ─── Skip behavior ────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-reactivate — skip behavior', () => {
  it('skips unknown keys with reason=not_found', async () => {
    const res = await callBulkReactivate({ keys: ['ADIA-BRA-SKIP-0001'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].key).toBe('ADIA-BRA-SKIP-0001');
    expect(body.skipped[0].reason).toBe('not_found');
  });

  it('skips already-active keys with reason=already_active', async () => {
    seedLicense('ADIA-BRA-SKIP-0002');
    // insertLicense seeds with status=active by default
    const res = await callBulkReactivate({ keys: ['ADIA-BRA-SKIP-0002'] });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(0);
    expect(body.skipped).toHaveLength(1);
    expect(body.skipped[0].key).toBe('ADIA-BRA-SKIP-0002');
    expect(body.skipped[0].reason).toBe('already_active');
  });

  it('handles mixed changed + skipped in one request', async () => {
    seedLicense('ADIA-BRA-SKIP-0003');
    setStatus('ADIA-BRA-SKIP-0003', 'canceled');
    seedLicense('ADIA-BRA-SKIP-0004');
    // ADIA-BRA-SKIP-0004 stays active → already_active
    // ADIA-BRA-SKIP-0005 does not exist → not_found
    const res = await callBulkReactivate({
      keys: ['ADIA-BRA-SKIP-0003', 'ADIA-BRA-SKIP-0004', 'ADIA-BRA-SKIP-0005'],
    });
    expect(res.status).toBe(200);
    const body = await res.json();
    expect(body.changed).toHaveLength(1);
    expect(body.changed[0].key).toBe('ADIA-BRA-SKIP-0003');
    expect(body.skipped).toHaveLength(2);
    const reasons = body.skipped.map((s: { reason: string }) => s.reason);
    expect(reasons).toContain('already_active');
    expect(reasons).toContain('not_found');
  });

  it('does not mutate a skipped (already_active) key', async () => {
    seedLicense('ADIA-BRA-SKIP-0006');
    await callBulkReactivate({ keys: ['ADIA-BRA-SKIP-0006'] });
    expect(findLicense('ADIA-BRA-SKIP-0006')?.status).toBe('active');
  });
});

// ─── Audit log ────────────────────────────────────────────────────────────────

describe('POST /api/admin/bulk-reactivate — audit log', () => {
  it('writes one audit log entry per reactivated key', async () => {
    seedLicense('ADIA-BRA-AUDT-0001');
    seedLicense('ADIA-BRA-AUDT-0002');
    setStatus('ADIA-BRA-AUDT-0001', 'canceled');
    setStatus('ADIA-BRA-AUDT-0002', 'expired');
    await callBulkReactivate({ keys: ['ADIA-BRA-AUDT-0001', 'ADIA-BRA-AUDT-0002'] });
    for (const key of ['ADIA-BRA-AUDT-0001', 'ADIA-BRA-AUDT-0002']) {
      const logs = listAuditLog({ licenseKey: key });
      expect(logs).toHaveLength(1);
      expect(logs[0].action).toBe('reactivate');
    }
  });

  it('audit log detail contains previousStatus, newStatus=active, bulk=true', async () => {
    seedLicense('ADIA-BRA-AUDT-0003');
    setStatus('ADIA-BRA-AUDT-0003', 'canceled');
    await callBulkReactivate({ keys: ['ADIA-BRA-AUDT-0003'] });
    const logs = listAuditLog({ licenseKey: 'ADIA-BRA-AUDT-0003' });
    const detail =
      typeof logs[0].detail === 'string' ? JSON.parse(logs[0].detail) : logs[0].detail;
    expect(detail).toMatchObject({
      previousStatus: 'canceled',
      newStatus: 'active',
      bulk: true,
    });
  });

  it('does not write audit log for not_found keys', async () => {
    await callBulkReactivate({ keys: ['ADIA-BRA-AUDT-NONE'] });
    const logs = listAuditLog({ licenseKey: 'ADIA-BRA-AUDT-NONE' });
    expect(logs).toHaveLength(0);
  });

  it('does not write audit log for already_active keys', async () => {
    seedLicense('ADIA-BRA-AUDT-0004');
    // status is 'active' by default after insert
    await callBulkReactivate({ keys: ['ADIA-BRA-AUDT-0004'] });
    const logs = listAuditLog({ licenseKey: 'ADIA-BRA-AUDT-0004' });
    expect(logs).toHaveLength(0);
  });
});
