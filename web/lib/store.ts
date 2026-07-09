// Storage facade. Picks SQLite (dev/test) or Postgres (production) based on
// DATABASE_URL. Always returns Promises so callers can `await` regardless of
// backend.
//
//   DATABASE_URL=postgres://...  → @vercel/postgres
//   DATABASE_URL=postgresql://... → @vercel/postgres
//   anything else                 → better-sqlite3 (lib/db.ts)

import * as sqlite from './db';
import type { License, Activation, LicenseStats, AuditEntry } from './db';

const usePg = (() => {
  const url = process.env.DATABASE_URL ?? '';
  return /^postgres(ql)?:\/\//.test(url);
})();

export type { License, Activation, LicenseStats, AuditEntry };

export async function insertLicense(row: {
  key: string;
  email: string;
  plan: License['plan'];
  stripeSession?: string;
  stripeSub?: string;
  expiresAt: string | null;
}): Promise<string> {
  if (usePg) {
    const { insertLicensePg } = await import('./db-pg');
    return insertLicensePg(row);
  }
  return sqlite.insertLicense(row);
}

export async function findLicense(key: string, email?: string): Promise<License | null> {
  if (usePg) {
    const { findLicensePg } = await import('./db-pg');
    return findLicensePg(key, email);
  }
  return sqlite.findLicense(key, email);
}

export async function recordActivation(key: string, machineHash: string): Promise<number> {
  if (usePg) {
    const { recordActivationPg } = await import('./db-pg');
    return recordActivationPg(key, machineHash);
  }
  return sqlite.recordActivation(key, machineHash);
}

export async function hasActivation(key: string, machineHash: string): Promise<boolean> {
  if (usePg) {
    const { hasActivationPg } = await import('./db-pg');
    return hasActivationPg(key, machineHash);
  }
  return sqlite.hasActivation(key, machineHash);
}

export async function countActivations(key: string): Promise<number> {
  if (usePg) {
    const { countActivationsPg } = await import('./db-pg');
    return countActivationsPg(key);
  }
  return sqlite.countActivations(key);
}

export async function countLicensesByEmail(email: string, since?: string, status?: string, plan?: string): Promise<number> {
  if (usePg) {
    const { countLicensesByEmailPg } = await import('./db-pg');
    return countLicensesByEmailPg(email, since, status, plan);
  }
  return sqlite.countLicensesByEmail(email, since, status, plan);
}

export async function findLicensesByEmail(email: string, limit?: number, offset?: number, since?: string, status?: string, plan?: string): Promise<License[]> {
  if (usePg) {
    const { findLicensesByEmailPg } = await import('./db-pg');
    return findLicensesByEmailPg(email, limit, offset, since, status, plan);
  }
  return sqlite.findLicensesByEmail(email, limit, offset, since, status, plan);
}

export async function setStatus(key: string, status: License['status']): Promise<void> {
  if (usePg) {
    const { setStatusPg } = await import('./db-pg');
    return setStatusPg(key, status);
  }
  sqlite.setStatus(key, status);
}

export async function setPlan(key: string, plan: License['plan']): Promise<void> {
  if (usePg) {
    const { setPlanPg } = await import('./db-pg');
    return setPlanPg(key, plan);
  }
  sqlite.setPlan(key, plan);
}

export async function findLicenseBySub(stripeSub: string): Promise<License | null> {
  if (usePg) {
    const { findLicenseBySubPg } = await import('./db-pg');
    return findLicenseBySubPg(stripeSub);
  }
  return sqlite.findLicenseBySub(stripeSub);
}

export async function setStatusBySub(stripeSub: string, status: License['status']): Promise<void> {
  if (usePg) {
    const { setStatusBySubPg } = await import('./db-pg');
    return setStatusBySubPg(stripeSub, status);
  }
  sqlite.setStatusBySub(stripeSub, status);
}

export async function setExpiryBySub(stripeSub: string, expiresAt: string | null): Promise<void> {
  if (usePg) {
    const { setExpiryBySubPg } = await import('./db-pg');
    return setExpiryBySubPg(stripeSub, expiresAt);
  }
  sqlite.setExpiryBySub(stripeSub, expiresAt);
}

export async function setExpiry(key: string, expiresAt: string | null): Promise<void> {
  if (usePg) {
    const { setExpiryPg } = await import('./db-pg');
    return setExpiryPg(key, expiresAt);
  }
  sqlite.setExpiry(key, expiresAt);
}

export async function listActivations(key: string): Promise<Activation[]> {
  if (usePg) {
    const { listActivationsPg } = await import('./db-pg');
    return listActivationsPg(key);
  }
  return sqlite.listActivations(key);
}

export async function removeAllActivations(key: string): Promise<number> {
  if (usePg) {
    const { removeAllActivationsPg } = await import('./db-pg');
    return removeAllActivationsPg(key);
  }
  return sqlite.removeAllActivations(key);
}

export async function removeActivation(key: string, machineHash: string): Promise<void> {
  if (usePg) {
    const { removeActivationPg } = await import('./db-pg');
    return removeActivationPg(key, machineHash);
  }
  sqlite.removeActivation(key, machineHash);
}

export async function transferLicense(key: string, newEmail: string): Promise<void> {
  if (usePg) {
    const { transferLicensePg } = await import('./db-pg');
    return transferLicensePg(key, newEmail);
  }
  sqlite.transferLicense(key, newEmail);
}

export async function joinWaitlist(email: string): Promise<void> {
  if (usePg) {
    const { joinWaitlistPg } = await import('./db-pg');
    return joinWaitlistPg(email);
  }
  sqlite.joinWaitlist(email);
}

export async function setNote(key: string, note: string | null): Promise<void> {
  if (usePg) {
    const { setNotePg } = await import('./db-pg');
    return setNotePg(key, note);
  }
  sqlite.setNote(key, note);
}

export async function getNote(key: string): Promise<string | null> {
  if (usePg) {
    const { getNotePg } = await import('./db-pg');
    return getNotePg(key);
  }
  return sqlite.getNote(key);
}

export async function getStats(): Promise<LicenseStats> {
  if (usePg) {
    const { getStatsPg } = await import('./db-pg');
    return getStatsPg();
  }
  return sqlite.getStats();
}

export async function insertAuditLog(entry: {
  licenseKey: string | null;
  action: string;
  detail?: Record<string, unknown>;
}): Promise<void> {
  if (usePg) {
    const { insertAuditLogPg } = await import('./db-pg');
    return insertAuditLogPg(entry);
  }
  sqlite.insertAuditLog(entry);
}

export async function searchLicenses(query: string, limit?: number, offset?: number, since?: string, status?: string, plan?: string): Promise<License[]> {
  if (usePg) {
    const { searchLicensesPg } = await import('./db-pg');
    return searchLicensesPg(query, limit, offset, since, status, plan);
  }
  return sqlite.searchLicenses(query, limit, offset, since, status, plan);
}

export async function countSearchLicenses(query: string, since?: string, status?: string, plan?: string): Promise<number> {
  if (usePg) {
    const { countSearchLicensesPg } = await import('./db-pg');
    return countSearchLicensesPg(query, since, status, plan);
  }
  return sqlite.countSearchLicenses(query, since, status, plan);
}

export async function searchLicensesAll(query: string, since?: string, status?: string, plan?: string): Promise<License[]> {
  if (usePg) {
    const { searchLicensesAllPg } = await import('./db-pg');
    return searchLicensesAllPg(query, since, status, plan);
  }
  return sqlite.searchLicensesAll(query, since, status, plan);
}

export async function listExpiringLicenses(days: number, plan?: string): Promise<License[]> {
  if (usePg) {
    const { listExpiringLicensesPg } = await import('./db-pg');
    return listExpiringLicensesPg(days, plan);
  }
  return sqlite.listExpiringLicenses(days, plan);
}

export async function listNeverActivatedLicenses(plan?: string, since?: string, status?: string): Promise<License[]> {
  if (usePg) {
    const { listNeverActivatedLicensesPg } = await import('./db-pg');
    return listNeverActivatedLicensesPg(plan, since, status);
  }
  return sqlite.listNeverActivatedLicenses(plan, since, status);
}

export async function listDormantLicenses(days: number, plan?: string, status?: string): Promise<License[]> {
  if (usePg) {
    const { listDormantLicensesPg } = await import('./db-pg');
    return listDormantLicensesPg(days, plan, status);
  }
  return sqlite.listDormantLicenses(days, plan, status);
}

export type HeatmapBucket = { hour: number; count: number };

export async function activationHeatmap(days: number, plan?: string): Promise<HeatmapBucket[]> {
  if (usePg) {
    const { activationHeatmapPg } = await import('./db-pg');
    return activationHeatmapPg(days, plan);
  }
  return sqlite.activationHeatmap(days, plan);
}

export async function listAllLicenses(since?: string, status?: string, plan?: string): Promise<License[]> {
  if (usePg) {
    const { listAllLicensesPg } = await import('./db-pg');
    return listAllLicensesPg(since, status, plan);
  }
  return sqlite.listAllLicenses(since, status, plan);
}

export async function countAuditLog(opts?: {
  licenseKey?: string;
  action?: string;
  since?: string;
}): Promise<number> {
  if (usePg) {
    const { countAuditLogPg } = await import('./db-pg');
    return countAuditLogPg(opts);
  }
  return sqlite.countAuditLog(opts);
}

export async function listAuditLog(opts?: {
  licenseKey?: string;
  limit?: number;
  offset?: number;
  action?: string;
  since?: string;
}): Promise<AuditEntry[]> {
  if (usePg) {
    const { listAuditLogPg } = await import('./db-pg');
    return listAuditLogPg(opts);
  }
  return sqlite.listAuditLog(opts);
}

export async function listAllAuditLog(since?: string, action?: string, licenseKey?: string): Promise<AuditEntry[]> {
  if (usePg) {
    const { listAllAuditLogPg } = await import('./db-pg');
    return listAllAuditLogPg(since, action, licenseKey);
  }
  return sqlite.listAllAuditLog(since, action, licenseKey);
}

export type { RevenueMetrics } from './db';

export async function revenueMetrics(): Promise<import('./db').RevenueMetrics> {
  if (usePg) {
    const { revenueMetricsPg } = await import('./db-pg');
    return revenueMetricsPg();
  }
  return sqlite.revenueMetrics();
}

export type { TimelineDay } from './db';

export async function activationTimeline(days: number, plan?: string): Promise<import('./db').TimelineDay[]> {
  if (usePg) {
    const { activationTimelinePg } = await import('./db-pg');
    return activationTimelinePg(days, plan);
  }
  return sqlite.activationTimeline(days, plan);
}

export async function countNotifyHistory(email: string): Promise<number> {
  if (usePg) {
    const { countNotifyHistoryPg } = await import('./db-pg');
    return countNotifyHistoryPg(email);
  }
  return sqlite.countNotifyHistory(email);
}

export async function listNotifyHistory(email: string, limit?: number, offset?: number): Promise<AuditEntry[]> {
  if (usePg) {
    const { listNotifyHistoryPg } = await import('./db-pg');
    return listNotifyHistoryPg(email, limit, offset);
  }
  return sqlite.listNotifyHistory(email, limit, offset);
}
