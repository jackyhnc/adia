'use client';

import { useState, useEffect, useRef, Fragment } from 'react';

export default function Admin() {
  const [token, setToken] = useState('');
  const [autoLookupKey, setAutoLookupKey] = useState('');

  return (
    <section className="pt-12 pb-20 max-w-xl space-y-10">
      <div>
        <h1 className="text-3xl font-semibold tracking-tight">Admin dashboard</h1>
        <p className="mt-2 text-sm text-ink/60">
          Requires <code className="font-mono">ADMIN_TOKEN</code> env var on the server.
        </p>
      </div>

      <div className="card space-y-2">
        <label className="block text-xs uppercase tracking-wide text-ink/60">Admin token</label>
        <input
          type="password"
          value={token}
          onChange={(e) => setToken(e.target.value)}
          placeholder="paste token here — shared across all forms below"
          className="input w-full"
        />
      </div>

      <StatsPanel token={token} />
      <IssuePanel token={token} />
      <ResendLicensePanel token={token} />
      <ChangeEmailPanel token={token} />
      <LicensesByEmailPanel token={token} onSelectKey={setAutoLookupKey} />
      <SearchLicensesPanel token={token} onSelectKey={setAutoLookupKey} />
      <LookupPanel token={token} autoKey={autoLookupKey} onAutoKeyConsumed={() => setAutoLookupKey('')} />
      <NotePanel token={token} />
      <AuditPanel token={token} />
      <ActivationsPanel token={token} />
      <DeactivateAllPanel token={token} />
      <TransferPanel />
      <ResendPaymentFailedPanel token={token} />
      <RevokePanel token={token} />
      <ReactivatePanel token={token} />
      <ExtendPanel token={token} />
      <ChangePlanPanel token={token} />
      <BulkChangePlanPanel token={token} />
      <SetExpiryPanel token={token} />
    </section>
  );
}

// ─── Stats overview ───────────────────────────────────────────────────────────

type Stats = {
  total: number;
  byStatus: Record<string, number>;
  byPlan: Record<string, number>;
  newLast7Days: number;
  newLast30Days: number;
  activatedMachines: number;
};

function StatsPanel({ token }: { token: string }) {
  const [stats, setStats] = useState<Stats | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function load() {
    if (!token) { setError('Paste admin token above first.'); return; }
    setLoading(true);
    setError('');
    setStats(null);
    try {
      const res = await fetch('/api/admin/stats', {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setStats(await res.json());
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <div className="flex items-center justify-between mb-3">
        <h2 className="text-lg font-semibold">License overview</h2>
        <button onClick={load} disabled={loading} className="btn-primary text-xs px-3 py-1">
          {loading ? 'Loading…' : 'Refresh'}
        </button>
      </div>
      {error && <p className="text-sm text-red-500 mb-2">{error}</p>}
      {stats && (
        <div className="card space-y-4">
          <div className="grid grid-cols-3 gap-3">
            <Stat label="Total licenses" value={stats.total} />
            <Stat label="New (7d)" value={stats.newLast7Days} />
            <Stat label="New (30d)" value={stats.newLast30Days} />
          </div>
          <div className="grid grid-cols-3 gap-3">
            <Stat label="Active machines" value={stats.activatedMachines} />
            {Object.entries(stats.byStatus).map(([s, c]) => (
              <Stat key={s} label={`Status: ${s}`} value={c}
                accent={s === 'active' ? 'green' : s === 'canceled' ? 'red' : 'yellow'} />
            ))}
          </div>
          {Object.keys(stats.byPlan).length > 0 && (
            <div className="grid grid-cols-3 gap-3">
              {Object.entries(stats.byPlan).map(([p, c]) => (
                <Stat key={p} label={`Plan: ${p}`} value={c} />
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function Stat({
  label,
  value,
  accent,
}: {
  label: string;
  value: number;
  accent?: 'green' | 'red' | 'yellow';
}) {
  const color =
    accent === 'green'
      ? 'text-green-600'
      : accent === 'red'
        ? 'text-red-500'
        : accent === 'yellow'
          ? 'text-yellow-600'
          : 'text-ink';
  return (
    <div className="rounded-lg border border-ink/10 bg-ink/5 p-3">
      <p className="text-xs uppercase tracking-wide text-ink/50 mb-1">{label}</p>
      <p className={`text-2xl font-semibold tabular-nums ${color}`}>{value}</p>
    </div>
  );
}

// ─── Issue comp / free license ────────────────────────────────────────────────

function IssuePanel({ token }: { token: string }) {
  const [email, setEmail] = useState('');
  const [plan, setPlan] = useState<'monthly' | 'yearly' | 'lifetime'>('lifetime');
  const [note, setNote] = useState('');
  const [result, setResult] = useState<{ key: string; email: string; plan: string; expiresAt: string | null } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function issue(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch('/api/admin/issue', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, plan, note: note || undefined }),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(await res.json());
        setEmail('');
        setNote('');
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Issue comp license</h2>
      <p className="text-sm text-ink/60 mb-3">
        Manually generate a license key for a user — no Stripe required. Use for speaker comps,
        beta testers, team members, or support resolutions.
      </p>
      <form onSubmit={issue} className="card space-y-3">
        <Field label="Email">
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="user@example.com"
            className="input"
            required
          />
        </Field>
        <Field label="Plan">
          <select
            value={plan}
            onChange={(e) => setPlan(e.target.value as typeof plan)}
            className="input"
          >
            <option value="lifetime">Lifetime</option>
            <option value="yearly">Yearly</option>
            <option value="monthly">Monthly</option>
          </select>
        </Field>
        <Field label="Note (optional — stored on the license, visible in Admin note panel)">
          <input
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder="speaker comp, beta tester, …"
            className="input"
          />
        </Field>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Issuing…' : 'Issue license'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="card mt-3 space-y-2 border border-green-500/30 bg-green-50/5">
          <p className="text-sm font-semibold text-green-600">License issued ✓</p>
          <p className="text-xs text-ink/60">Send this key to the recipient:</p>
          <p className="font-mono text-base font-bold tracking-widest select-all">{result.key}</p>
          <p className="text-xs text-ink/50">
            {result.email} · {result.plan}
            {result.expiresAt ? ` · expires ${result.expiresAt.slice(0, 10)}` : ' · no expiry'}
          </p>
        </div>
      )}
    </div>
  );
}

// ─── Resend license email ─────────────────────────────────────────────────────

function ResendLicensePanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [email, setEmail] = useState('');
  const [result, setResult] = useState<{ ok: true; to: string; key: string; plan: string } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function resend(e: React.FormEvent) {
    e.preventDefault();
    if (!key && !email) {
      setError('Enter a license key or an email address.');
      return;
    }
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const body: Record<string, string> = {};
      if (key) body.key = key.trim().toUpperCase();
      if (email) body.email = email.trim();
      const res = await fetch('/api/admin/resend-license', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      if (!res.ok) {
        const b = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${b.error ?? 'unknown error'}`);
      } else {
        setResult(await res.json());
        setKey('');
        setEmail('');
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Resend license email</h2>
      <p className="text-sm text-ink/60 mb-3">
        Re-send the license welcome email to a customer who lost their key. Provide a key{' '}
        <em>or</em> an email address. If only an email is given, the most recently issued active
        license for that address is used.
      </p>
      <form onSubmit={resend} className="card space-y-3">
        <Field label="License key (takes precedence if both are filled)">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX  (optional if email is set)"
            className="input font-mono"
          />
        </Field>
        <Field label="Customer email (used if no key is given)">
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="user@example.com  (optional if key is set)"
            className="input"
          />
        </Field>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Sending…' : 'Resend license email'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="card mt-3 border border-green-500/30 bg-green-50/5">
          <p className="text-sm font-semibold text-green-600">Email sent ✓</p>
          <p className="text-xs text-ink/60 mt-1">
            Sent to <strong>{result.to}</strong> — key{' '}
            <span className="font-mono select-all">{result.key}</span> ({result.plan})
          </p>
        </div>
      )}
    </div>
  );
}

// ─── Admin email change ───────────────────────────────────────────────────────

function ChangeEmailPanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [newEmail, setNewEmail] = useState('');
  const [result, setResult] = useState<{ ok: true; key: string; oldEmail: string; newEmail: string; plan: string } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function changeEmail(e: React.FormEvent) {
    e.preventDefault();
    const k = key.trim().toUpperCase();
    if (!confirm(`Change email on ${k} to ${newEmail.trim()}? This takes effect immediately.`)) return;
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch('/api/admin/change-email', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ key: k, newEmail: newEmail.trim() }),
      });
      if (!res.ok) {
        const b = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${b.error ?? 'unknown error'}`);
      } else {
        setResult(await res.json());
        setKey('');
        setNewEmail('');
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Change license email (admin)</h2>
      <p className="text-sm text-ink/60 mb-3">
        Update the email address on a license without requiring the customer&apos;s old email for
        auth. Use when a customer changed their primary email and can no longer use the self-service
        transfer flow. Verify identity out-of-band before using.
      </p>
      <form onSubmit={changeEmail} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <Field label="New email address">
          <input
            type="email"
            value={newEmail}
            onChange={(e) => setNewEmail(e.target.value)}
            placeholder="new@example.com"
            className="input"
            required
          />
        </Field>
        <button
          type="submit"
          className="px-4 py-2 rounded-lg bg-orange-600 text-white text-sm font-medium hover:bg-orange-700 disabled:opacity-40"
          disabled={loading}
        >
          {loading ? 'Updating…' : 'Change email'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="card mt-3 border border-green-500/30 bg-green-50/5">
          <p className="text-sm font-semibold text-green-600">Email updated ✓</p>
          <p className="text-xs text-ink/60 mt-1">
            <span className="font-mono">{result.key}</span> ({result.plan}){' '}
            <span className="line-through text-ink/40">{result.oldEmail}</span>
            {' → '}
            <strong>{result.newEmail}</strong>
          </p>
        </div>
      )}
    </div>
  );
}

// ─── Shared types ────────────────────────────────────────────────────────────

type License = {
  key: string;
  email: string;
  plan: string;
  status: string;
  issuedAt: string | null;
  expiresAt: string | null;
  note?: string | null;
  machineCount?: number;
};

// ─── License search ───────────────────────────────────────────────────────────

function SearchLicensesPanel({ token, onSelectKey }: { token: string; onSelectKey: (key: string) => void }) {
  const [q, setQ] = useState('');
  const [sinceFilter, setSinceFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [planFilter, setPlanFilter] = useState('');
  const [results, setResults] = useState<License[] | null>(null);
  const [total, setTotal] = useState(0);
  const [hasMore, setHasMore] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const searchAbortRef = useRef<AbortController | null>(null);
  const PAGE_SIZE = 20;

  function buildParams(query: string, extra: Record<string, string> = {}): URLSearchParams {
    const params = new URLSearchParams({ q: query, ...extra });
    if (sinceFilter) params.set('since', sinceFilter);
    if (statusFilter) params.set('status', statusFilter);
    if (planFilter) params.set('plan', planFilter);
    return params;
  }

  async function runSearch(query: string) {
    searchAbortRef.current?.abort();
    searchAbortRef.current = new AbortController();
    const { signal } = searchAbortRef.current;
    setLoading(true);
    setError('');
    setResults(null);
    setHasMore(false);
    setTotal(0);
    try {
      const params = buildParams(query, { limit: String(PAGE_SIZE), offset: '0' });
      const res = await fetch(`/api/admin/search-licenses?${params}`, {
        headers: { Authorization: `Bearer ${token}` },
        signal,
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        throw new Error(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      }
      const body = await res.json();
      setTotal(body.total);
      setHasMore(body.hasMore);
      setResults(body.results);
    } catch (err: any) {
      if (err.name !== 'AbortError') setError(err.message);
    } finally {
      if (!signal.aborted) setLoading(false);
    }
  }

  useEffect(() => {
    const trimmed = q.trim();
    if (!trimmed) {
      setResults(null);
      setTotal(0);
      setHasMore(false);
      setError('');
      searchAbortRef.current?.abort();
      return;
    }
    if (!token) return;
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => { runSearch(trimmed); }, 300);
    return () => { if (debounceRef.current) clearTimeout(debounceRef.current); };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q, sinceFilter, statusFilter, planFilter, token]);

  function exportCsv() {
    const safeQ = q.trim().replace(/[^a-zA-Z0-9@._-]/g, '_').slice(0, 40);
    const date = new Date().toISOString().slice(0, 10);
    const params = buildParams(q.trim(), { format: 'csv' });
    const url = `/api/admin/search-licenses?${params}&token=${encodeURIComponent(token)}`;
    const a = document.createElement('a');
    a.href = url;
    a.download = `search-${safeQ}-${date}.csv`;
    a.click();
  }

  async function loadMore() {
    if (!results) return;
    setLoadingMore(true);
    try {
      const params = buildParams(q.trim(), { limit: String(PAGE_SIZE), offset: String(results.length) });
      const res = await fetch(`/api/admin/search-licenses?${params}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        throw new Error(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      }
      const body = await res.json();
      setTotal(body.total);
      setHasMore(body.hasMore);
      setResults(prev => prev ? [...prev, ...body.results] : body.results);
    } catch (err: any) {
      setError(err.message);
    } finally {
      setLoadingMore(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Search licenses</h2>
      <p className="text-sm text-ink/60 mb-3">
        Full-text search across license key, email, and note — results appear as you type. Click a key to auto-fill the lookup panel below.
      </p>
      <div className="card space-y-3">
        <Field label="Search query (key, email, or note fragment)">
          <div className="relative">
            <input
              value={q}
              onChange={(e) => setQ(e.target.value)}
              placeholder="jane@example.com or ADIA-1234 or enterprise"
              className="input pr-8"
            />
            {loading && (
              <span className="absolute right-2 top-1/2 -translate-y-1/2 text-xs text-ink/40 select-none">…</span>
            )}
          </div>
        </Field>
        <div className="flex gap-3">
          <Field label="Issued since">
            <input
              type="date"
              value={sinceFilter}
              onChange={(e) => setSinceFilter(e.target.value)}
              className="input"
            />
          </Field>
          <Field label="Status">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="input"
            >
              {STATUS_OPTIONS.map(s => (
                <option key={s} value={s}>{s === '' ? 'Any' : s}</option>
              ))}
            </select>
          </Field>
          <Field label="Plan">
            <select
              value={planFilter}
              onChange={(e) => setPlanFilter(e.target.value)}
              className="input"
            >
              {PLAN_OPTIONS.map(p => (
                <option key={p} value={p}>{p === '' ? 'Any' : p}</option>
              ))}
            </select>
          </Field>
        </div>
      </div>
      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}
      {results !== null && (
        <div className="card mt-3">
          {results.length === 0 ? (
            <p className="text-sm text-ink/50">No licenses matched &quot;{q}&quot;.</p>
          ) : (
            <>
              <div className="flex items-center justify-between mb-2">
                <p className="text-xs text-ink/50">
                  Showing {results.length} of {total} result{total !== 1 ? 's' : ''} — click a key for full detail
                </p>
                <button
                  onClick={exportCsv}
                  className="text-xs text-sky-600 hover:underline"
                >
                  Export CSV
                </button>
              </div>
              <div className="overflow-x-auto">
                <table className="w-full text-xs">
                  <thead>
                    <tr className="text-left text-ink/50 border-b border-ink/10">
                      <th className="pb-1 pr-3">Key</th>
                      <th className="pb-1 pr-3">Email</th>
                      <th className="pb-1 pr-3">Plan</th>
                      <th className="pb-1 pr-3">Status</th>
                      <th className="pb-1 pr-3">Seats</th>
                      <th className="pb-1 pr-3">Issued</th>
                      <th className="pb-1">Note</th>
                    </tr>
                  </thead>
                  <tbody>
                    {results.map((lic) => (
                      <tr key={lic.key} className="border-t border-ink/5 hover:bg-ink/5 cursor-pointer" onClick={() => onSelectKey(lic.key)}>
                        <td className="py-1 pr-3 font-mono text-sky-600 hover:underline">{lic.key}</td>
                        <td className="py-1 pr-3">{lic.email}</td>
                        <td className="py-1 pr-3">{lic.plan}</td>
                        <td className="py-1 pr-3">
                          <span className={lic.status === 'active' ? 'text-green-600' : lic.status === 'past_due' ? 'text-yellow-600' : 'text-red-500'}>
                            {lic.status}
                          </span>
                        </td>
                        <td className="py-1 pr-3 tabular-nums text-ink/60">{lic.machineCount ?? 0}/3</td>
                        <td className="py-1 pr-3 text-ink/50">{lic.issuedAt?.slice(0, 10) ?? '—'}</td>
                        <td className="py-1 text-ink/60 italic">{lic.note ?? '—'}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              {hasMore && (
                <button
                  onClick={loadMore}
                  disabled={loadingMore}
                  className="mt-3 text-xs text-sky-600 hover:underline disabled:opacity-50"
                >
                  {loadingMore ? 'Loading…' : `Load more (${total - results.length} remaining)`}
                </button>
              )}
            </>
          )}
        </div>
      )}
    </div>
  );
}

// ─── License lookup ────────────────────────────────────────────────────────────

type LookupResult = {
  license: License;
  recentAudit: AuditEntry[];
};

function LookupPanel({
  token,
  autoKey,
  onAutoKeyConsumed,
}: {
  token: string;
  autoKey?: string;
  onAutoKeyConsumed?: () => void;
}) {
  const [key, setKey] = useState('');
  const [email, setEmail] = useState('');
  const [result, setResult] = useState<LookupResult | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const panelRef = useRef<HTMLDivElement>(null);

  async function doLookup(lookupKey: string, lookupEmail?: string) {
    if (!token) { setError('Paste admin token above first.'); return; }
    setLoading(true);
    setError('');
    setResult(null);
    try {
      const params = new URLSearchParams({ key: lookupKey });
      if (lookupEmail) params.set('email', lookupEmail);
      const res = await fetch(`/api/admin/lookup?${params}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(await res.json());
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    if (!autoKey) return;
    setKey(autoKey);
    setEmail('');
    void doLookup(autoKey);
    onAutoKeyConsumed?.();
    // Scroll the panel into view after a brief tick so the result renders first
    setTimeout(() => panelRef.current?.scrollIntoView({ behavior: 'smooth', block: 'start' }), 100);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [autoKey]);

  async function lookup(e: React.FormEvent) {
    e.preventDefault();
    await doLookup(key, email || undefined);
  }

  return (
    <div ref={panelRef}>
      <h2 className="text-lg font-semibold mb-3">License lookup</h2>
      <form onSubmit={lookup} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <Field label="Email (optional — narrows the match)">
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="user@example.com"
            className="input"
          />
        </Field>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Looking up…' : 'Look up'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}
      {result && (
        <div className="card mt-3 space-y-4">
          <LicenseCard lic={result.license} />
          {result.recentAudit.length > 0 && (
            <div>
              <p className="text-xs font-semibold text-ink/50 uppercase tracking-wide mb-2">Recent actions</p>
              <div className="space-y-1">
                {result.recentAudit.map((entry) => (
                  <div key={entry.id} className="flex items-start gap-2 text-xs">
                    <span className={`font-medium ${auditActionColor(entry.action)}`}>{entry.action}</span>
                    <span className="text-ink/40">{entry.createdAt?.slice(0, 19).replace('T', ' ')}</span>
                    {entry.detail && (
                      <span className="text-ink/50 truncate max-w-xs">{renderDetailInline(entry.detail)}</span>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

function LicenseCard({ lic }: { lic: License }) {
  const statusColor = lic.status === 'active'
    ? 'text-green-600'
    : lic.status === 'past_due'
    ? 'text-yellow-600'
    : 'text-red-500';
  return (
    <div className="space-y-2">
      <div className="flex items-center gap-3">
        <span className="font-mono text-sm font-semibold">{lic.key}</span>
        <span className={`text-xs font-medium ${statusColor}`}>{lic.status}</span>
        <span className="text-xs text-ink/50">{lic.plan}</span>
      </div>
      <div className="grid grid-cols-2 gap-x-4 gap-y-1 text-xs text-ink/70">
        <span><span className="text-ink/40">Email</span> {lic.email}</span>
        <span><span className="text-ink/40">Issued</span> {lic.issuedAt?.slice(0, 10) ?? '—'}</span>
        <span><span className="text-ink/40">Expires</span> {lic.expiresAt?.slice(0, 10) ?? 'never'}</span>
        <span><span className="text-ink/40">Note</span> <em>{lic.note ?? 'none'}</em></span>
      </div>
    </div>
  );
}

function auditActionColor(action: string): string {
  if (action === 'issue') return 'text-green-600';
  if (action === 'revoke') return 'text-red-500';
  if (action === 'reactivate') return 'text-green-700';
  if (action === 'change_plan') return 'text-violet-600';
  if (action === 'extend') return 'text-blue-600';
  if (action === 'set_note') return 'text-teal-600';
  if (action === 'change_email') return 'text-orange-600';
  if (action === 'resend_license') return 'text-sky-600';
  if (action === 'deactivate_all') return 'text-rose-600';
  if (action === 'resend_payment_failed') return 'text-amber-600';
  return 'text-ink/70';
}

function renderDetailInline(detail: string | null): string {
  if (!detail) return '';
  try {
    const obj = JSON.parse(detail);
    return Object.entries(obj).map(([k, v]) => `${k}: ${v}`).join(' · ');
  } catch {
    return detail;
  }
}

// ─── Admin note ──────────────────────────────────────────────────────────────

function NotePanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [note, setNote] = useState('');
  const [fetched, setFetched] = useState<string | null | undefined>(undefined);
  const [result, setResult] = useState<{ ok: true; key: string; note: string | null } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function fetchNote(e: React.FormEvent) {
    e.preventDefault();
    if (!token) { setError('Paste admin token above first.'); return; }
    setLoading(true);
    setError('');
    setFetched(undefined);
    setResult(null);
    try {
      const res = await fetch(
        `/api/admin/note?key=${encodeURIComponent(key.trim().toUpperCase())}`,
        { headers: { Authorization: `Bearer ${token}` } },
      );
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        const body = await res.json();
        setFetched(body.note);
        setNote(body.note ?? '');
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  async function saveNote(e: React.FormEvent) {
    e.preventDefault();
    if (!token) { setError('Paste admin token above first.'); return; }
    setLoading(true);
    setError('');
    setResult(null);
    try {
      const res = await fetch('/api/admin/note', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ key: key.trim().toUpperCase(), note: note || null }),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        const body = await res.json();
        setResult(body);
        setFetched(body.note);
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Admin note</h2>
      <p className="text-sm text-ink/60 mb-3">
        Attach a freeform note to any license — speaker comp reason, support resolution context, etc.
        Notes are visible only to admins. Clear by saving an empty field.
      </p>

      <form onSubmit={fetchNote} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Loading…' : 'Fetch note'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {fetched !== undefined && (
        <form onSubmit={saveNote} className="card mt-3 space-y-3">
          <Field label={`Current note for ${key.trim().toUpperCase()}`}>
            <textarea
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder="Leave blank to clear…"
              rows={3}
              className="input w-full resize-y"
            />
          </Field>
          <button
            type="submit"
            className="px-4 py-2 rounded-lg bg-teal-600 text-white text-sm font-medium hover:bg-teal-700 disabled:opacity-40"
            disabled={loading}
          >
            {loading ? 'Saving…' : note ? 'Save note' : 'Clear note'}
          </button>
        </form>
      )}

      {result && (
        <div className="card mt-3 border border-green-500/30 bg-green-50/5">
          <p className="text-sm font-semibold text-green-600">Note saved ✓</p>
          <p className="text-xs text-ink/60 mt-1">
            {result.note
              ? <>Note on <span className="font-mono">{result.key}</span>: <em>{result.note}</em></>
              : <>Note cleared for <span className="font-mono">{result.key}</span>.</>}
          </p>
        </div>
      )}
    </div>
  );
}

// ─── Admin audit log ─────────────────────────────────────────────────────────

type AuditEntry = {
  id: number;
  licenseKey: string | null;
  action: string;
  detail: string | null;
  createdAt: string;
};

function AuditPanel({ token }: { token: string }) {
  const [keyFilter, setKeyFilter] = useState('');
  const [entries, setEntries] = useState<AuditEntry[] | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function load(e: React.FormEvent) {
    e.preventDefault();
    if (!token) { setError('Paste admin token above first.'); return; }
    setLoading(true);
    setError('');
    setEntries(null);
    try {
      const params = new URLSearchParams({ limit: '100' });
      if (keyFilter.trim()) params.set('key', keyFilter.trim().toUpperCase());
      const res = await fetch(`/api/admin/audit-log?${params}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        const body = await res.json();
        setEntries(body.entries);
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  const actionColor = auditActionColor;

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Admin audit log</h2>
      <p className="text-sm text-ink/60 mb-3">
        All admin actions on licenses — issue, revoke, change_plan, extend, reactivate, set_note,
        change_email, resend_license, deactivate_all, resend_payment_failed. Most recent first. Filter by license key to
        see history for one license.
      </p>
      <form onSubmit={load} className="card space-y-3">
        <Field label="License key (optional — leave blank for all recent actions)">
          <input
            value={keyFilter}
            onChange={(e) => setKeyFilter(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX or blank"
            className="input font-mono"
          />
        </Field>
        <div className="flex gap-2">
          <button type="submit" className="btn-primary" disabled={loading}>
            {loading ? 'Loading…' : 'Load audit log'}
          </button>
          <button
            type="button"
            className="btn-secondary text-xs px-3 py-1"
            onClick={() => {
              if (!token) return;
              const params = new URLSearchParams({ limit: '500', format: 'csv' });
              if (keyFilter.trim()) params.set('key', keyFilter.trim().toUpperCase());
              const url = `/api/admin/audit-log?${params}&token=${encodeURIComponent(token)}`;
              const a = document.createElement('a');
              a.href = url;
              a.download = 'audit-log.csv';
              a.click();
            }}
          >
            Export CSV
          </button>
        </div>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {entries !== null && (
        <div className="card mt-3 space-y-2">
          {entries.length === 0 ? (
            <p className="text-sm text-ink/50">No audit log entries found.</p>
          ) : (
            <table className="w-full text-xs">
              <thead>
                <tr className="text-left text-ink/50 border-b border-ink/10">
                  <th className="pb-1 pr-3">When</th>
                  <th className="pb-1 pr-3">Action</th>
                  <th className="pb-1 pr-3">License key</th>
                  <th className="pb-1">Detail</th>
                </tr>
              </thead>
              <tbody>
                {entries.map((e) => {
                  let detailObj: Record<string, unknown> | null = null;
                  try { detailObj = e.detail ? JSON.parse(e.detail) : null; } catch {}
                  return (
                    <tr key={e.id} className="border-t border-ink/5">
                      <td className="py-1 pr-3 font-mono text-ink/40 whitespace-nowrap">
                        {e.createdAt.slice(0, 16).replace('T', ' ')}
                      </td>
                      <td className={`py-1 pr-3 font-semibold ${actionColor(e.action)}`}>
                        {e.action}
                      </td>
                      <td className="py-1 pr-3 font-mono text-ink/60">
                        {e.licenseKey ?? <span className="italic text-ink/30">—</span>}
                      </td>
                      <td className="py-1 font-mono text-ink/50 break-all">
                        {detailObj
                          ? Object.entries(detailObj)
                              .map(([k, v]) => `${k}: ${v ?? 'null'}`)
                              .join(' · ')
                          : (e.detail ?? '—')}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
          <p className="text-xs text-ink/30 pt-1">Showing {entries.length} entries (max 100).</p>
        </div>
      )}
    </div>
  );
}

// ─── Activation management ────────────────────────────────────────────────────

type Activation = { machineHash: string; firstSeen: string; lastSeen: string };

function ActivationsPanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [data, setData] = useState<{
    key: string; email: string; plan: string; status: string;
    seatCount: number; activations: Activation[];
  } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [removing, setRemoving] = useState<string | null>(null);

  async function fetchActivations(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');
    setData(null);
    try {
      const res = await fetch(`/api/admin/activations?key=${encodeURIComponent(key)}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setData(await res.json());
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  async function deactivate(machineHash: string) {
    setRemoving(machineHash);
    try {
      const params = new URLSearchParams({ key, machine: machineHash });
      const res = await fetch(`/api/admin/activations?${params}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        alert(`Failed: ${body.error ?? res.status}`);
      } else {
        // Refresh the list
        const refreshRes = await fetch(`/api/admin/activations?key=${encodeURIComponent(key)}`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (refreshRes.ok) setData(await refreshRes.json());
      }
    } finally {
      setRemoving(null);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Machine activations</h2>
      <p className="text-sm text-ink/60 mb-3">
        List activated machines for a license, and free seats by deactivating old machines.
      </p>
      <form onSubmit={fetchActivations} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Loading…' : 'List activations'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {data && (
        <div className="card mt-3 space-y-3">
          <div className="text-sm">
            <span className="font-mono font-semibold">{data.key}</span>
            {' · '}
            {data.email}
            {' · '}
            {data.plan}
            {' · '}
            <span className={data.status === 'active' ? 'text-green-600' : 'text-red-500'}>
              {data.status}
            </span>
            {' · '}
            {data.seatCount}/3 seats used
          </div>

          {data.activations.length === 0 ? (
            <p className="text-sm text-ink/50">No activations on record.</p>
          ) : (
            <table className="w-full text-xs font-mono">
              <thead>
                <tr className="text-left text-ink/50">
                  <th className="pb-1 pr-3">Machine hash</th>
                  <th className="pb-1 pr-3">First seen</th>
                  <th className="pb-1 pr-3">Last seen</th>
                  <th className="pb-1" />
                </tr>
              </thead>
              <tbody>
                {data.activations.map((a) => (
                  <tr key={a.machineHash} className="border-t border-ink/10">
                    <td className="py-1 pr-3 text-ink/70">{a.machineHash.slice(0, 16)}…</td>
                    <td className="py-1 pr-3 text-ink/50">{a.firstSeen.slice(0, 10)}</td>
                    <td className="py-1 pr-3 text-ink/50">{a.lastSeen.slice(0, 10)}</td>
                    <td className="py-1">
                      <button
                        onClick={() => deactivate(a.machineHash)}
                        disabled={removing === a.machineHash}
                        className="text-red-500 hover:underline disabled:opacity-40 text-xs"
                      >
                        {removing === a.machineHash ? 'Removing…' : 'Remove'}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      )}
    </div>
  );
}

// ─── License revoke ────────────────────────────────────────────────────────────

function RevokePanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [result, setResult] = useState('');
  const [loading, setLoading] = useState(false);

  async function revoke(e: React.FormEvent) {
    e.preventDefault();
    if (!confirm(`Revoke license ${key}? This cannot be undone from this UI.`)) return;
    setLoading(true);
    setResult('');
    try {
      const res = await fetch('/api/admin/revoke', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ key }),
      });
      setResult(`HTTP ${res.status}\n\n${await res.text()}`);
    } catch (err: any) {
      setResult(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Revoke license</h2>
      <p className="text-sm text-ink/60 mb-3">
        Sets license status to <code className="font-mono">canceled</code>. The next time the app
        validates, it will be rejected. Use for refunds or abuse cases.
      </p>
      <form onSubmit={revoke} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <button
          type="submit"
          className="px-4 py-2 rounded-lg bg-red-600 text-white text-sm font-medium hover:bg-red-700 disabled:opacity-40"
          disabled={loading}
        >
          {loading ? 'Revoking…' : 'Revoke license'}
        </button>
      </form>
      {result && <pre className="card mt-3 font-mono text-xs whitespace-pre-wrap">{result}</pre>}
    </div>
  );
}

// ─── Reactivate license ───────────────────────────────────────────────────────

function ReactivatePanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [result, setResult] = useState<{ ok: boolean; key: string; previousStatus: string; newStatus: string } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function reactivate(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch('/api/admin/reactivate', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ key }),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(body);
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Reactivate license</h2>
      <p className="text-sm text-ink/60 mb-3">
        Sets a canceled, expired, or past-due license back to{' '}
        <code className="font-mono">active</code>. Use for wrongly revoked licenses or
        manually resolved billing failures.
      </p>
      <form onSubmit={reactivate} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <button
          type="submit"
          className="px-4 py-2 rounded-lg bg-green-600 text-white text-sm font-medium hover:bg-green-700 disabled:opacity-40"
          disabled={loading}
        >
          {loading ? 'Reactivating…' : 'Reactivate license'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      {result && (
        <div className="card mt-3 text-sm space-y-1">
          <p className="font-medium text-green-700">License reactivated</p>
          <p>
            Key: <code className="font-mono">{result.key}</code>
          </p>
          <p>
            Status:{' '}
            <span className="line-through text-ink/40">{result.previousStatus}</span>
            {' → '}
            <span className="font-semibold text-green-700">{result.newStatus}</span>
          </p>
        </div>
      )}
    </div>
  );
}

// ─── Extend license expiry ───────────────────────────────────────────────────

function ExtendPanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [days, setDays] = useState('30');
  const [result, setResult] = useState<{
    ok: boolean;
    key: string;
    previousExpiresAt: string | null;
    newExpiresAt: string;
    days: number;
  } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function extend(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch('/api/admin/extend', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ key, days: Number(days) }),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(body);
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Extend license expiry</h2>
      <p className="text-sm text-ink/60 mb-3">
        Adds N days to a license's <code className="font-mono">expiresAt</code>. If the license has
        no expiry (lifetime) or is already expired, extends from today. Max 3650 days (10 years).
      </p>
      <form onSubmit={extend} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <Field label="Days to add">
          <input
            type="number"
            min={1}
            max={3650}
            value={days}
            onChange={(e) => setDays(e.target.value)}
            className="input"
            required
          />
        </Field>
        <button
          type="submit"
          className="px-4 py-2 rounded-lg bg-blue-600 text-white text-sm font-medium hover:bg-blue-700 disabled:opacity-40"
          disabled={loading}
        >
          {loading ? 'Extending…' : 'Extend expiry'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      {result && (
        <div className="card mt-3 text-sm space-y-1">
          <p className="font-medium text-blue-700">Expiry extended by {result.days} days</p>
          <p>
            Key: <code className="font-mono">{result.key}</code>
          </p>
          <p>
            Previous:{' '}
            <span className="line-through text-ink/40">
              {result.previousExpiresAt ?? 'none (lifetime)'}
            </span>
          </p>
          <p>
            New expiry:{' '}
            <span className="font-semibold text-blue-700">{result.newExpiresAt}</span>
          </p>
        </div>
      )}
    </div>
  );
}

// ─── Change license plan ─────────────────────────────────────────────────────

function ChangePlanPanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [plan, setPlan] = useState<'monthly' | 'yearly' | 'lifetime'>('lifetime');
  const [result, setResult] = useState<{
    ok: boolean;
    key: string;
    previousPlan: string;
    newPlan: string;
  } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function changePlan(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch('/api/admin/change-plan', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ key, plan }),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(body);
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Change license plan</h2>
      <p className="text-sm text-ink/60 mb-3">
        Switch a license between <code className="font-mono">monthly</code>,{' '}
        <code className="font-mono">yearly</code>, and{' '}
        <code className="font-mono">lifetime</code>. Use for manual upgrades, support
        resolutions, or correcting an incorrect plan at issue time.
      </p>
      <form onSubmit={changePlan} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <Field label="New plan">
          <select
            value={plan}
            onChange={(e) => setPlan(e.target.value as typeof plan)}
            className="input"
          >
            <option value="lifetime">Lifetime</option>
            <option value="yearly">Yearly</option>
            <option value="monthly">Monthly</option>
          </select>
        </Field>
        <button
          type="submit"
          className="px-4 py-2 rounded-lg bg-violet-600 text-white text-sm font-medium hover:bg-violet-700 disabled:opacity-40"
          disabled={loading}
        >
          {loading ? 'Changing…' : 'Change plan'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      {result && (
        <div className="card mt-3 text-sm space-y-1">
          <p className="font-medium text-violet-700">Plan changed</p>
          <p>
            Key: <code className="font-mono">{result.key}</code>
          </p>
          <p>
            Plan:{' '}
            <span className="line-through text-ink/40">{result.previousPlan}</span>
            {' → '}
            <span className="font-semibold text-violet-700">{result.newPlan}</span>
          </p>
        </div>
      )}
    </div>
  );
}

// ─── Bulk change plan ─────────────────────────────────────────────────────────

type BulkChangedEntry = { key: string; previousPlan: string };
type BulkSkippedEntry = { key: string; reason: string };

function BulkChangePlanPanel({ token }: { token: string }) {
  const [keysText, setKeysText] = useState('');
  const [plan, setPlanValue] = useState<'monthly' | 'yearly' | 'lifetime'>('lifetime');
  const [result, setResult] = useState<{
    ok: boolean;
    plan: string;
    changed: BulkChangedEntry[];
    skipped: BulkSkippedEntry[];
  } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function bulkChange(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setResult(null);
    setError('');
    const keys = keysText
      .split(/[\n,]+/)
      .map((k) => k.trim().toUpperCase())
      .filter(Boolean);
    if (keys.length === 0) {
      setError('Enter at least one key.');
      setLoading(false);
      return;
    }
    try {
      const res = await fetch('/api/admin/bulk-change-plan', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ keys, plan }),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(body);
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Bulk change plan</h2>
      <p className="text-sm text-ink/60 mb-3">
        Change the plan for multiple license keys in one operation — for example, upgrading a cohort
        of users as compensation after a service outage. Paste keys one per line or comma-separated.
        Keys already on the target plan or not found are silently skipped and listed in the result.
      </p>
      <form onSubmit={bulkChange} className="card space-y-3">
        <Field label="License keys (one per line or comma-separated)">
          <textarea
            value={keysText}
            onChange={(e) => setKeysText(e.target.value)}
            placeholder={'ADIA-XXXX-XXXX-XXXX\nADIA-YYYY-YYYY-YYYY'}
            className="input font-mono h-28 resize-y"
            required
          />
        </Field>
        <Field label="New plan">
          <select
            value={plan}
            onChange={(e) => setPlanValue(e.target.value as typeof plan)}
            className="input"
          >
            <option value="lifetime">Lifetime</option>
            <option value="yearly">Yearly</option>
            <option value="monthly">Monthly</option>
          </select>
        </Field>
        <button
          type="submit"
          className="px-4 py-2 rounded-lg bg-violet-600 text-white text-sm font-medium hover:bg-violet-700 disabled:opacity-40"
          disabled={loading}
        >
          {loading ? 'Changing…' : 'Bulk change plan'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      {result && (
        <div className="card mt-3 text-sm space-y-2">
          <p className="font-medium text-violet-700">
            {result.changed.length} changed, {result.skipped.length} skipped →{' '}
            <span className="font-semibold">{result.plan}</span>
          </p>
          {result.changed.length > 0 && (
            <div>
              <p className="font-medium mb-1">Changed:</p>
              <ul className="space-y-0.5">
                {result.changed.map((c) => (
                  <li key={c.key} className="font-mono text-xs">
                    {c.key}{' '}
                    <span className="text-ink/40 line-through">{c.previousPlan}</span>
                    {' → '}
                    <span className="text-violet-700">{result.plan}</span>
                  </li>
                ))}
              </ul>
            </div>
          )}
          {result.skipped.length > 0 && (
            <div>
              <p className="font-medium mb-1">Skipped:</p>
              <ul className="space-y-0.5">
                {result.skipped.map((s) => (
                  <li key={s.key} className="font-mono text-xs text-ink/60">
                    {s.key} — {s.reason.replace(/_/g, ' ')}
                  </li>
                ))}
              </ul>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

// ─── Set absolute expiry date ─────────────────────────────────────────────────

function SetExpiryPanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [expiresAt, setExpiresAt] = useState('');
  const [lifetime, setLifetime] = useState(false);
  const [result, setResult] = useState<{
    ok: boolean;
    key: string;
    previousExpiresAt: string | null;
    newExpiresAt: string | null;
  } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function setExpiry(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setResult(null);
    setError('');
    const newExpiry = lifetime ? null : expiresAt || null;
    try {
      const res = await fetch('/api/admin/set-expiry', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ key: key.trim().toUpperCase(), expiresAt: newExpiry }),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(body);
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Set expiry date</h2>
      <p className="text-sm text-ink/60 mb-3">
        Set an absolute <code className="font-mono">expiresAt</code> on a license. Complements
        &ldquo;Extend&rdquo; (relative days): use this when you need a specific renewal date, want
        to immediately expire a license, or convert it to lifetime (null).
      </p>
      <form onSubmit={setExpiry} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <label className="flex items-center gap-2 text-sm">
          <input
            type="checkbox"
            checked={lifetime}
            onChange={(e) => setLifetime(e.target.checked)}
            className="rounded"
          />
          Set to lifetime (no expiry)
        </label>
        {!lifetime && (
          <Field label="New expiry date (ISO, e.g. 2025-12-31)">
            <input
              type="date"
              value={expiresAt}
              onChange={(e) => setExpiresAt(e.target.value)}
              className="input"
              required={!lifetime}
            />
          </Field>
        )}
        <button
          type="submit"
          className="px-4 py-2 rounded-lg bg-teal-600 text-white text-sm font-medium hover:bg-teal-700 disabled:opacity-40"
          disabled={loading}
        >
          {loading ? 'Setting…' : 'Set expiry'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      {result && (
        <div className="card mt-3 text-sm space-y-1">
          <p className="font-medium text-teal-700">Expiry updated</p>
          <p>
            Key: <code className="font-mono">{result.key}</code>
          </p>
          <p>
            Previous:{' '}
            <span className="line-through text-ink/40">
              {result.previousExpiresAt ?? 'none (lifetime)'}
            </span>
          </p>
          <p>
            New expiry:{' '}
            <span className="font-semibold text-teal-700">
              {result.newExpiresAt ?? 'lifetime (no expiry)'}
            </span>
          </p>
        </div>
      )}
    </div>
  );
}

// ─── Licenses by email ────────────────────────────────────────────────────────

type LicenseRow = {
  key: string;
  email: string;
  plan: string;
  status: string;
  issuedAt: string;
  expiresAt: string | null;
  machineCount: number;
  note?: string | null;
  lastAction?: string | null;
  lastActionAt?: string | null;
};

const EMAIL_PAGE_SIZE = 20;

const STATUS_OPTIONS = ['', 'active', 'canceled', 'expired', 'past_due'] as const;
const PLAN_OPTIONS = ['', 'monthly', 'yearly', 'lifetime'] as const;

function LicensesByEmailPanel({ token, onSelectKey }: { token: string; onSelectKey: (key: string) => void }) {
  const [email, setEmail] = useState('');
  const [since, setSince] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [planFilter, setPlanFilter] = useState('');
  const [result, setResult] = useState<{
    email: string;
    count: number;
    licenses: LicenseRow[];
    hasMore: boolean;
    offset: number;
  } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const [expandedKey, setExpandedKey] = useState<string | null>(null);
  const [auditMap, setAuditMap] = useState<Record<string, AuditEntry[]>>({});
  const [auditLoading, setAuditLoading] = useState<Record<string, boolean>>({});

  async function lookup(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setResult(null);
    setError('');
    setExpandedKey(null);
    setAuditMap({});
    try {
      const params = new URLSearchParams({ email, limit: String(EMAIL_PAGE_SIZE), offset: '0' });
      if (since) params.set('since', since);
      if (statusFilter) params.set('status', statusFilter);
      if (planFilter) params.set('plan', planFilter);
      const res = await fetch(`/api/admin/licenses-by-email?${params}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(await res.json());
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  async function loadMore() {
    if (!result || loadingMore) return;
    const nextOffset = result.offset + result.licenses.length;
    setLoadingMore(true);
    try {
      const params = new URLSearchParams({
        email: result.email,
        limit: String(EMAIL_PAGE_SIZE),
        offset: String(nextOffset),
      });
      if (since) params.set('since', since);
      if (statusFilter) params.set('status', statusFilter);
      if (planFilter) params.set('plan', planFilter);
      const res = await fetch(`/api/admin/licenses-by-email?${params}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        const body = await res.json();
        setResult(prev => prev
          ? {
              ...prev,
              licenses: [...prev.licenses, ...body.licenses],
              hasMore: body.hasMore,
              offset: body.offset,
            }
          : body,
        );
      }
    } catch {
      // ignore — button stays available for retry
    } finally {
      setLoadingMore(false);
    }
  }

  async function toggleExpand(key: string) {
    if (expandedKey === key) {
      setExpandedKey(null);
      return;
    }
    setExpandedKey(key);
    if (auditMap[key] !== undefined) return;
    setAuditLoading(prev => ({ ...prev, [key]: true }));
    try {
      const res = await fetch(`/api/admin/lookup?key=${encodeURIComponent(key)}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        const body = await res.json();
        setAuditMap(prev => ({ ...prev, [key]: (body.recentAudit ?? []).slice(0, 3) }));
      } else {
        setAuditMap(prev => ({ ...prev, [key]: [] }));
      }
    } catch {
      setAuditMap(prev => ({ ...prev, [key]: [] }));
    } finally {
      setAuditLoading(prev => ({ ...prev, [key]: false }));
    }
  }

  function exportCsv() {
    if (!result) return;
    const params = new URLSearchParams({ email: result.email, format: 'csv' });
    if (since) params.set('since', since);
    if (statusFilter) params.set('status', statusFilter);
    if (planFilter) params.set('plan', planFilter);
    const url = `/api/admin/licenses-by-email?${params}&token=${encodeURIComponent(token)}`;
    const a = document.createElement('a');
    a.href = url;
    a.download = `licenses-${result.email}-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Licenses by email</h2>
      <p className="text-sm text-ink/60 mb-3">
        Find all license keys associated with an email address. Click a row to see recent audit entries inline;
        click a key to open the full lookup panel.
      </p>
      <form onSubmit={lookup} className="card space-y-3">
        <Field label="Customer email">
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="user@example.com"
            className="input"
            required
          />
        </Field>
        <div className="flex gap-3">
          <Field label="Issued since">
            <input
              type="date"
              value={since}
              onChange={(e) => setSince(e.target.value)}
              className="input"
            />
          </Field>
          <Field label="Status">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="input"
            >
              {STATUS_OPTIONS.map(s => (
                <option key={s} value={s}>{s === '' ? 'Any' : s}</option>
              ))}
            </select>
          </Field>
          <Field label="Plan">
            <select
              value={planFilter}
              onChange={(e) => setPlanFilter(e.target.value)}
              className="input"
            >
              {PLAN_OPTIONS.map(p => (
                <option key={p} value={p}>{p === '' ? 'Any' : p}</option>
              ))}
            </select>
          </Field>
        </div>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Searching…' : 'Find licenses'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="card mt-3 space-y-3">
          <div className="flex items-center justify-between">
            <p className="text-sm text-ink/60">
              {result.count === 0
                ? `No licenses found for ${result.email}.`
                : `Showing ${result.licenses.length} of ${result.count} license${result.count === 1 ? '' : 's'} for ${result.email}`}
            </p>
            {result.count > 0 && (
              <button
                onClick={exportCsv}
                className="text-xs text-sky-600 hover:underline"
              >
                Export CSV
              </button>
            )}
          </div>
          {result.licenses.length > 0 && (
            <table className="w-full text-xs font-mono">
              <thead>
                <tr className="text-left text-ink/50">
                  <th className="pb-1 pr-3">Key</th>
                  <th className="pb-1 pr-3">Plan</th>
                  <th className="pb-1 pr-3">Status</th>
                  <th className="pb-1 pr-3">Seats</th>
                  <th className="pb-1 pr-3">Issued</th>
                  <th className="pb-1 pr-3">Expires</th>
                  <th className="pb-1 pr-3">Last action</th>
                  <th className="pb-1">Note</th>
                </tr>
              </thead>
              <tbody>
                {result.licenses.map((lic) => (
                  <Fragment key={lic.key}>
                    <tr
                      className="border-t border-ink/10 cursor-pointer hover:bg-ink/5"
                      onClick={() => toggleExpand(lic.key)}
                    >
                      <td className="py-1 pr-3">
                        <button
                          className="text-sky-600 hover:underline text-left"
                          onClick={(e) => { e.stopPropagation(); onSelectKey(lic.key); }}
                        >
                          {lic.key}
                        </button>
                        <span className="ml-1 text-ink/25 select-none">
                          {expandedKey === lic.key ? '▲' : '▼'}
                        </span>
                      </td>
                      <td className="py-1 pr-3 text-ink/70">{lic.plan}</td>
                      <td className={`py-1 pr-3 ${lic.status === 'active' ? 'text-green-600' : 'text-red-500'}`}>
                        {lic.status}
                      </td>
                      <td className="py-1 pr-3 tabular-nums text-ink/60">{lic.machineCount ?? 0}/3</td>
                      <td className="py-1 pr-3 text-ink/50">{lic.issuedAt.slice(0, 10)}</td>
                      <td className="py-1 pr-3 text-ink/50">{lic.expiresAt ? lic.expiresAt.slice(0, 10) : '—'}</td>
                      <td className="py-1 pr-3 text-ink/50 truncate max-w-[10rem]" title={lic.lastAction ?? undefined}>
                        {lic.lastAction
                          ? <><span>{lic.lastAction}</span>{lic.lastActionAt && <span className="ml-1 text-ink/30">({lic.lastActionAt.slice(0, 10)})</span>}</>
                          : '—'}
                      </td>
                      <td className="py-1 text-ink/50 italic">{lic.note ?? '—'}</td>
                    </tr>
                    {expandedKey === lic.key && (
                      <tr className="bg-ink/[0.02]">
                        <td colSpan={8} className="pt-1 pb-3 px-3">
                          {auditLoading[lic.key] ? (
                            <p className="text-xs text-ink/40">Loading audit…</p>
                          ) : (auditMap[lic.key]?.length ?? 0) === 0 ? (
                            <p className="text-xs text-ink/40">No audit entries.</p>
                          ) : (
                            <div className="space-y-1 mb-2">
                              {auditMap[lic.key].map(entry => (
                                <div key={entry.id} className="text-xs text-ink/60 flex gap-3">
                                  <span className="text-ink/30 shrink-0">
                                    {entry.createdAt.slice(0, 16).replace('T', ' ')}
                                  </span>
                                  <span className="text-ink/80">{entry.action}</span>
                                  {entry.detail && (
                                    <span className="text-ink/40 truncate">{entry.detail}</span>
                                  )}
                                </div>
                              ))}
                            </div>
                          )}
                          <button
                            className="text-xs text-sky-600 hover:underline mt-1"
                            onClick={(e) => { e.stopPropagation(); onSelectKey(lic.key); }}
                          >
                            → Open in lookup panel
                          </button>
                        </td>
                      </tr>
                    )}
                  </Fragment>
                ))}
              </tbody>
            </table>
          )}
          {result.hasMore && (
            <div className="flex justify-center pt-1">
              <button
                className="text-xs text-sky-600 hover:underline disabled:opacity-40"
                onClick={loadMore}
                disabled={loadingMore}
              >
                {loadingMore ? 'Loading…' : 'Load more'}
              </button>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

// ─── Resend payment-failed email ──────────────────────────────────────────────

function ResendPaymentFailedPanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [force, setForce] = useState(false);
  const [result, setResult] = useState<{ ok: true; to: string; key: string; plan: string } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function resend(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch('/api/admin/resend-payment-failed', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ key: key.trim().toUpperCase(), force }),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(await res.json());
        setKey('');
        setForce(false);
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Resend payment-failed email</h2>
      <p className="text-sm text-ink/60 mb-3">
        Manually trigger the payment-failed email for a license key. By default only sends if the
        license is <code className="font-mono">past_due</code>; check <em>force</em> to override
        (useful for testing the email template).
      </p>
      <form onSubmit={resend} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <label className="flex items-center gap-2 text-sm cursor-pointer select-none">
          <input
            type="checkbox"
            checked={force}
            onChange={(e) => setForce(e.target.checked)}
            className="rounded"
          />
          Force — send even if license is not <span className="font-mono ml-1">past_due</span>
        </label>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Sending…' : 'Resend email'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="card mt-3 border border-green-500/30 bg-green-50/5">
          <p className="text-sm font-semibold text-green-600">Email sent ✓</p>
          <p className="text-xs text-ink/60 mt-1">
            Sent to <strong>{result.to}</strong> for key{' '}
            <span className="font-mono">{result.key}</span> ({result.plan})
          </p>
        </div>
      )}
    </div>
  );
}

// ─── Deactivate all machines ──────────────────────────────────────────────────

function DeactivateAllPanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [result, setResult] = useState<{ ok: true; key: string; removedCount: number } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function deactivateAll(e: React.FormEvent) {
    e.preventDefault();
    const k = key.trim().toUpperCase();
    if (!confirm(`Remove ALL activations for ${k}? The user will need to re-activate on each machine.`)) return;
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch('/api/admin/deactivate-all', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ key: k }),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(await res.json());
        setKey('');
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Deactivate all machines</h2>
      <p className="text-sm text-ink/60 mb-3">
        Wipes every machine activation for a license in one shot. Use when a customer has lost
        access to all their machines and can&apos;t deactivate them individually.
      </p>
      <form onSubmit={deactivateAll} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <button
          type="submit"
          className="px-4 py-2 rounded-lg bg-orange-600 text-white text-sm font-medium hover:bg-orange-700 disabled:opacity-40"
          disabled={loading}
        >
          {loading ? 'Deactivating…' : 'Deactivate all'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="card mt-3 border border-green-500/30 bg-green-50/5">
          <p className="text-sm font-semibold text-green-600">Done ✓</p>
          <p className="text-xs text-ink/60 mt-1">
            Removed <strong>{result.removedCount}</strong> activation
            {result.removedCount === 1 ? '' : 's'} for{' '}
            <span className="font-mono">{result.key}</span>
          </p>
        </div>
      )}
    </div>
  );
}

// ─── License transfer (support) ───────────────────────────────────────────────

function TransferPanel() {
  const [key, setKey] = useState('');
  const [email, setEmail] = useState('');
  const [newEmail, setNewEmail] = useState('');
  const [result, setResult] = useState<{ ok: true; key: string; email: string; plan: string } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function transfer(e: React.FormEvent) {
    e.preventDefault();
    if (!confirm(`Transfer ${key} from ${email} → ${newEmail}?`)) return;
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch('/api/license/transfer', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ key: key.trim().toUpperCase(), email: email.trim(), newEmail: newEmail.trim() }),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(await res.json());
        setKey('');
        setEmail('');
        setNewEmail('');
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <h2 className="text-lg font-semibold mb-3">Transfer license</h2>
      <p className="text-sm text-ink/60 mb-3">
        Move a license to a different email address. Requires the current key + email for auth
        (collect from the customer). Use for email changes or account consolidation.
      </p>
      <form onSubmit={transfer} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <Field label="Current email (for verification)">
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="current@example.com"
            className="input"
            required
          />
        </Field>
        <Field label="New email">
          <input
            type="email"
            value={newEmail}
            onChange={(e) => setNewEmail(e.target.value)}
            placeholder="new@example.com"
            className="input"
            required
          />
        </Field>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Transferring…' : 'Transfer license'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="card mt-3 border border-green-500/30 bg-green-50/5">
          <p className="text-sm font-semibold text-green-600">Transferred ✓</p>
          <p className="text-xs text-ink/60 mt-1">
            <span className="font-mono">{result.key}</span> ({result.plan}) is now registered to{' '}
            <strong>{result.email}</strong>
          </p>
        </div>
      )}
    </div>
  );
}

// ─── Shared ────────────────────────────────────────────────────────────────────

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="text-xs uppercase tracking-wide text-ink/60">{label}</span>
      <div className="mt-1">{children}</div>
    </label>
  );
}
