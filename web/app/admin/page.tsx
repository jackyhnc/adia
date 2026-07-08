'use client';

import { useState, useEffect, useRef, Fragment, createContext, useContext } from 'react';

const SectionFilterContext = createContext('');

export default function Admin() {
  const [token, setToken] = useState('');
  const [autoLookupKey, setAutoLookupKey] = useState('');
  const [sectionFilter, setSectionFilter] = useState('');
  const filterInputRef = useRef<HTMLInputElement>(null);

  // Pre-fill token from ?token= and section filter from ?section= URL params on mount.
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const t = params.get('token');
    if (t) setToken(t);
    const s = params.get('section');
    if (s) setSectionFilter(s);
  }, []);

  // Keep ?token= in sync so refreshing the page preserves the session.
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    if (token) {
      params.set('token', token);
    } else {
      params.delete('token');
    }
    const qs = params.toString();
    const next = qs ? `${window.location.pathname}?${qs}` : window.location.pathname;
    window.history.replaceState(null, '', next);
  }, [token]);

  // Keep ?section= in sync with the filter input so filtered views are bookmarkable.
  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    if (sectionFilter) {
      params.set('section', sectionFilter);
    } else {
      params.delete('section');
    }
    const qs = params.toString();
    const next = qs ? `${window.location.pathname}?${qs}` : window.location.pathname;
    window.history.replaceState(null, '', next);
  }, [sectionFilter]);

  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === '/' && document.activeElement?.tagName !== 'INPUT' && document.activeElement?.tagName !== 'TEXTAREA') {
        e.preventDefault();
        filterInputRef.current?.focus();
      }
      if (e.key === 'Escape') {
        setSectionFilter('');
        filterInputRef.current?.blur();
      }
    }
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, []);

  return (
    <SectionFilterContext.Provider value={sectionFilter}>
    <section className="pt-12 pb-20 max-w-xl space-y-4">
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
        <p className="text-xs text-ink/40">Tip: bookmark <code className="font-mono">/admin?token=YOUR_TOKEN</code> to skip pasting.</p>
      </div>

      <div className="sticky top-3 z-10">
        <div className="relative">
          <svg className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-ink/40 pointer-events-none" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <circle cx="11" cy="11" r="8" /><line x1="21" y1="21" x2="16.65" y2="16.65" />
          </svg>
          <input
            ref={filterInputRef}
            type="text"
            value={sectionFilter}
            onChange={(e) => setSectionFilter(e.target.value)}
            placeholder="Jump to section… (press / to focus)"
            className="input w-full pl-9 pr-8 bg-canvas shadow-sm"
          />
          {sectionFilter && (
            <button
              type="button"
              onClick={() => setSectionFilter('')}
              className="absolute right-2.5 top-1/2 -translate-y-1/2 text-ink/40 hover:text-ink/70"
              aria-label="Clear filter"
            >
              ✕
            </button>
          )}
        </div>
      </div>

      <CollapsibleSection title="License overview" defaultOpen>
        <StatsPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Expiring soon">
        <ExpiringSoonPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Never activated">
        <NeverActivatedPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Dormant licenses">
        <DormantPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Issue comp license">
        <IssuePanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Bulk issue licenses">
        <BulkIssuePanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Resend license email">
        <ResendLicensePanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Bulk resend license email">
        <BulkResendLicensePanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Change license email">
        <ChangeEmailPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Bulk transfer">
        <BulkTransferPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Bulk change email">
        <BulkChangeEmailPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Licenses by email">
        <LicensesByEmailPanel token={token} onSelectKey={setAutoLookupKey} />
      </CollapsibleSection>
      <CollapsibleSection title="Search licenses">
        <SearchLicensesPanel token={token} onSelectKey={setAutoLookupKey} />
      </CollapsibleSection>
      <CollapsibleSection title="License lookup">
        <LookupPanel token={token} autoKey={autoLookupKey} onAutoKeyConsumed={() => setAutoLookupKey('')} />
      </CollapsibleSection>
      <CollapsibleSection title="Admin note">
        <NotePanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Admin audit log">
        <AuditPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Machine activations">
        <ActivationsPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Deactivate all machines">
        <DeactivateAllPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Bulk deactivate all machines">
        <BulkDeactivateAllPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Transfer license">
        <TransferPanel />
      </CollapsibleSection>
      <CollapsibleSection title="Resend payment-failed email">
        <ResendPaymentFailedPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Send custom email to license holder">
        <NotifyPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Outreach history by email">
        <NotifyHistoryPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Revoke license">
        <RevokePanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Reactivate license">
        <ReactivatePanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Extend license expiry">
        <ExtendPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Change license plan">
        <ChangePlanPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Bulk change plan">
        <BulkChangePlanPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Bulk revoke">
        <BulkRevokePanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Bulk reactivate">
        <BulkReactivatePanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Bulk set status">
        <BulkSetStatusPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Bulk note">
        <BulkNotePanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Bulk extend">
        <BulkExtendPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Bulk set expiry date">
        <BulkSetExpiryPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Set expiry date">
        <SetExpiryPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Export licenses">
        <ExportLicensesPanel token={token} />
      </CollapsibleSection>
      <CollapsibleSection title="Export audit log">
        <AuditLogExportPanel token={token} />
      </CollapsibleSection>
    </section>
    </SectionFilterContext.Provider>
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
  expiringIn30Days: number;
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
      <div className="flex justify-end mb-3">
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
            <Stat label="Expiring (30d)" value={stats.expiringIn30Days}
              accent={stats.expiringIn30Days > 0 ? (stats.expiringIn30Days >= 10 ? 'red' : 'yellow') : undefined} />
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

// ─── Bulk issue licenses ──────────────────────────────────────────────────────

function BulkIssuePanel({ token }: { token: string }) {
  const [count, setCount] = useState('5');
  const [plan, setPlan] = useState<'monthly' | 'yearly' | 'lifetime'>('lifetime');
  const [email, setEmail] = useState('');
  const [note, setNote] = useState('');
  const [result, setResult] = useState<{
    ok: boolean;
    keys: string[];
    count: number;
    email: string;
    plan: string;
    expiresAt: string | null;
    note: string | null;
  } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [copied, setCopied] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    const n = parseInt(count, 10);
    if (!n || n < 1 || n > 50) {
      setError('Count must be between 1 and 50.');
      return;
    }
    setLoading(true);
    setResult(null);
    setError('');
    setCopied(false);
    try {
      const body: Record<string, unknown> = { count: n, plan };
      if (email.trim()) body.email = email.trim();
      if (note.trim()) body.note = note.trim();
      const res = await fetch('/api/admin/bulk-issue', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(`HTTP ${res.status}: ${data.error ?? 'unknown error'}`);
      } else {
        setResult(data);
      }
    } catch (err: unknown) {
      setError(`Error: ${err instanceof Error ? err.message : String(err)}`);
    } finally {
      setLoading(false);
    }
  }

  function copyAll() {
    if (!result) return;
    navigator.clipboard.writeText(result.keys.join('\n')).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  }

  return (
    <div>
      <p className="text-sm text-ink/60 mb-3">
        Generate multiple license keys at once — useful for conference giveaways, batch promo
        codes, or seeding a cohort. All keys share the same plan, email, and note.
      </p>
      <form onSubmit={submit} className="card space-y-3">
        <Field label="Number of keys (1–50)">
          <input
            type="number"
            value={count}
            onChange={(e) => setCount(e.target.value)}
            min={1}
            max={50}
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
        <Field label="Email (optional — defaults to bulk@admin)">
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="promo@example.com"
            className="input"
          />
        </Field>
        <Field label="Note (optional — applied to every key)">
          <input
            value={note}
            onChange={(e) => setNote(e.target.value)}
            placeholder="conference giveaway, beta cohort, …"
            className="input"
          />
        </Field>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Generating…' : `Generate ${count || '?'} keys`}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="card mt-3 space-y-3 border border-green-500/30 bg-green-50/5">
          <div className="flex items-center justify-between">
            <p className="text-sm font-semibold text-green-600">
              {result.count} keys generated ✓
            </p>
            <button
              type="button"
              onClick={copyAll}
              className="text-xs px-2 py-1 rounded border border-ink/20 hover:bg-ink/5"
            >
              {copied ? 'Copied!' : 'Copy all'}
            </button>
          </div>
          <p className="text-xs text-ink/50">
            {result.email} · {result.plan}
            {result.expiresAt ? ` · expires ${result.expiresAt.slice(0, 10)}` : ' · no expiry'}
            {result.note ? ` · note: ${result.note}` : ''}
          </p>
          <ul className="space-y-1">
            {result.keys.map((k) => (
              <li key={k} className="font-mono text-sm tracking-wide select-all text-green-800">
                {k}
              </li>
            ))}
          </ul>
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

// ─── Admin bulk resend license email ─────────────────────────────────────────

function BulkResendLicensePanel({ token }: { token: string }) {
  const [keysRaw, setKeysRaw] = useState('');
  const [dryRun, setDryRun] = useState(false);
  const [result, setResult] = useState<{
    ok: boolean;
    dryRun: boolean;
    sent: { key: string; email: string; plan: string }[];
    skipped: { key: string; reason: string }[];
  } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    const keys = keysRaw
      .split(/[\n,]+/)
      .map((k) => k.trim().toUpperCase())
      .filter(Boolean);
    if (keys.length === 0) {
      setError('Enter at least one license key.');
      return;
    }
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch('/api/admin/bulk-resend-license', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ keys, dryRun }),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(body);
        if (!dryRun && body.sent?.length > 0) setKeysRaw('');
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <p className="text-sm text-ink/60 mb-3">
        Re-send the license welcome email to multiple customers at once (max 50 keys).
        Keys that are not found or have no email address are silently skipped.
        Use <strong>dry run</strong> to preview which keys would be resolved without sending.
      </p>
      <form onSubmit={submit} className="card space-y-3">
        <Field label="License keys (one per line or comma-separated, max 50)">
          <textarea
            value={keysRaw}
            onChange={(e) => setKeysRaw(e.target.value)}
            rows={5}
            placeholder={'ADIA-XXXX-XXXX-XXXX\nADIA-YYYY-YYYY-YYYY'}
            className="input font-mono"
          />
        </Field>
        <label className="flex items-center gap-2 text-sm text-ink/70 select-none">
          <input
            type="checkbox"
            checked={dryRun}
            onChange={(e) => setDryRun(e.target.checked)}
            className="rounded"
          />
          Dry run (preview only — no emails sent, no audit log written)
        </label>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Sending…' : dryRun ? 'Preview' : 'Resend license emails'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="mt-3 space-y-3">
          <div className={`card border ${result.dryRun ? 'border-yellow-400/40 bg-yellow-50/5' : 'border-green-500/30 bg-green-50/5'}`}>
            <p className="text-sm font-semibold">
              {result.dryRun ? '🔍 Dry run — ' : ''}
              {result.sent.length} email{result.sent.length !== 1 ? 's' : ''} {result.dryRun ? 'would be sent' : 'sent'},&nbsp;
              {result.skipped.length} skipped
            </p>
          </div>
          {result.sent.length > 0 && (
            <div className="card space-y-1">
              <p className="text-xs font-semibold text-ink/60 uppercase tracking-wide mb-2">
                {result.dryRun ? 'Would send' : 'Sent'}
              </p>
              {result.sent.map((s) => (
                <div key={s.key} className="flex items-center gap-2 text-xs font-mono">
                  <span className="text-green-500">✓</span>
                  <span className="select-all">{s.key}</span>
                  <span className="text-ink/50">→</span>
                  <span className="text-ink/70">{s.email}</span>
                  <span className="text-ink/40">({s.plan})</span>
                </div>
              ))}
            </div>
          )}
          {result.skipped.length > 0 && (
            <div className="card space-y-1">
              <p className="text-xs font-semibold text-ink/60 uppercase tracking-wide mb-2">Skipped</p>
              {result.skipped.map((s) => (
                <div key={s.key} className="flex items-center gap-2 text-xs font-mono">
                  <span className="text-yellow-500">–</span>
                  <span className="select-all">{s.key}</span>
                  <span className="text-ink/40 italic">{s.reason}</span>
                </div>
              ))}
            </div>
          )}
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

const AUDIT_PAGE_SIZE = 50;

function AuditPanel({ token }: { token: string }) {
  const [keyFilter, setKeyFilter] = useState('');
  const [actionFilter, setActionFilter] = useState('');
  const [sinceFilter, setSinceFilter] = useState('');
  const [entries, setEntries] = useState<AuditEntry[] | null>(null);
  const [total, setTotal] = useState(0);
  const [hasMore, setHasMore] = useState(false);
  const [currentOffset, setCurrentOffset] = useState(0);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [loadingMore, setLoadingMore] = useState(false);
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  async function fetchPage(offset: number, append: boolean, overrides?: { key?: string; action?: string; since?: string }) {
    if (!token) { setError('Paste admin token above first.'); return; }
    if (append) setLoadingMore(true); else setLoading(true);
    setError('');
    try {
      const key = overrides?.key ?? keyFilter;
      const action = overrides?.action ?? actionFilter;
      const since = overrides?.since ?? sinceFilter;
      const params = new URLSearchParams({ limit: String(AUDIT_PAGE_SIZE), offset: String(offset) });
      if (key.trim()) params.set('key', key.trim().toUpperCase());
      if (action.trim()) params.set('action', action.trim());
      if (since.trim()) params.set('since', since.trim());
      const res = await fetch(`/api/admin/audit-log?${params}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        const body = await res.json();
        setEntries(prev => append && prev ? [...prev, ...body.entries] : body.entries);
        setTotal(body.total ?? body.count ?? 0);
        setHasMore(body.hasMore ?? false);
        setCurrentOffset(offset + body.entries.length);
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      if (append) setLoadingMore(false); else setLoading(false);
    }
  }

  function load(e: React.FormEvent) {
    e.preventDefault();
    setEntries(null);
    setCurrentOffset(0);
    fetchPage(0, false);
  }

  function scheduleDebounce(key: string, action: string, since: string) {
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => {
      setEntries(null);
      setCurrentOffset(0);
      fetchPage(0, false, { key, action, since });
    }, 300);
  }

  const actionColor = auditActionColor;

  return (
    <div>
      <p className="text-sm text-ink/60 mb-3">
        All admin actions on licenses — issue, revoke, change_plan, extend, reactivate, set_note,
        change_email, resend_license, deactivate_all, resend_payment_failed. Most recent first.
        Filter by license key, action name, or date.
      </p>
      <form onSubmit={load} className="card space-y-3">
        <div className="flex gap-3 flex-wrap">
          <Field label="License key (optional)">
            <input
              value={keyFilter}
              onChange={(e) => { setKeyFilter(e.target.value); scheduleDebounce(e.target.value, actionFilter, sinceFilter); }}
              placeholder="ADIA-XXXX-XXXX-XXXX or blank"
              className="input font-mono"
            />
          </Field>
          <Field label="Action (optional)">
            <input
              value={actionFilter}
              onChange={(e) => { setActionFilter(e.target.value); scheduleDebounce(keyFilter, e.target.value, sinceFilter); }}
              placeholder="e.g. revoke, issue, extend"
              className="input"
            />
          </Field>
          <Field label="Since (optional)">
            <input
              type="date"
              value={sinceFilter}
              onChange={(e) => { setSinceFilter(e.target.value); scheduleDebounce(keyFilter, actionFilter, e.target.value); }}
              className="input"
            />
          </Field>
        </div>
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
              if (actionFilter.trim()) params.set('action', actionFilter.trim());
              if (sinceFilter.trim()) params.set('since', sinceFilter.trim());
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
            <>
              <p className="text-xs text-ink/40">Showing {entries.length} of {total} entries</p>
              <div className="overflow-x-auto">
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
              </div>
              {hasMore && (
                <button
                  type="button"
                  className="btn-secondary text-xs w-full mt-1"
                  disabled={loadingMore}
                  onClick={() => fetchPage(currentOffset, true)}
                >
                  {loadingMore ? 'Loading…' : `Load more (${total - currentOffset} remaining)`}
                </button>
              )}
            </>
          )}
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

// ─── Bulk revoke licenses ────────────────────────────────────────────────────

type BulkRevokeRevokedEntry = { key: string; previousStatus: string };
type BulkRevokeSkippedEntry = { key: string; reason: string };

function BulkRevokePanel({ token }: { token: string }) {
  const [keysText, setKeysText] = useState('');
  const [result, setResult] = useState<{
    ok: boolean;
    changed: BulkRevokeRevokedEntry[];
    skipped: BulkRevokeSkippedEntry[];
  } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function bulkRevoke(e: React.FormEvent) {
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
      const res = await fetch('/api/admin/bulk-revoke', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ keys }),
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

      <p className="text-sm text-ink/60 mb-3">
        Cancel multiple license keys in one operation — for example, disabling a cohort of keys
        from a stolen credit card or cleaning up fraudulent accounts. Paste keys one per line or
        comma-separated. Keys already canceled or not found are silently skipped and listed in the
        result.
      </p>
      <form onSubmit={bulkRevoke} className="card space-y-3">
        <Field label="License keys (one per line or comma-separated)">
          <textarea
            value={keysText}
            onChange={(e) => setKeysText(e.target.value)}
            placeholder={'ADIA-XXXX-XXXX-XXXX\nADIA-YYYY-YYYY-YYYY'}
            className="input font-mono h-28 resize-y"
            required
          />
        </Field>
        <button
          type="submit"
          className="px-4 py-2 rounded-lg bg-red-600 text-white text-sm font-medium hover:bg-red-700 disabled:opacity-40"
          disabled={loading}
        >
          {loading ? 'Revoking…' : 'Bulk revoke'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      {result && (
        <div className="card mt-3 text-sm space-y-2">
          <p className="font-medium text-red-700">
            {result.changed.length} revoked, {result.skipped.length} skipped
          </p>
          {result.changed.length > 0 && (
            <div>
              <p className="font-medium mb-1">Revoked:</p>
              <ul className="space-y-0.5">
                {result.changed.map((c) => (
                  <li key={c.key} className="font-mono text-xs">
                    {c.key}{' '}
                    <span className="text-ink/40 line-through">{c.previousStatus}</span>
                    {' → '}
                    <span className="text-red-700">canceled</span>
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

// ─── Bulk reactivate ──────────────────────────────────────────────────────────

type BulkReactivateReactivatedEntry = { key: string; previousStatus: string };
type BulkReactivateSkippedEntry = { key: string; reason: string };

function BulkReactivatePanel({ token }: { token: string }) {
  const [keysText, setKeysText] = useState('');
  const [result, setResult] = useState<{
    ok: boolean;
    changed: BulkReactivateReactivatedEntry[];
    skipped: BulkReactivateSkippedEntry[];
  } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function bulkReactivate(e: React.FormEvent) {
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
      const res = await fetch('/api/admin/bulk-reactivate', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ keys }),
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

      <p className="text-sm text-ink/60 mb-3">
        Restore multiple license keys to active in one operation — for example, fixing a batch of
        wrongly revoked accounts or reinstating a cohort whose payment issues were resolved manually.
        Paste keys one per line or comma-separated. Keys already active or not found are silently
        skipped and listed in the result.
      </p>
      <form onSubmit={bulkReactivate} className="card space-y-3">
        <Field label="License keys (one per line or comma-separated)">
          <textarea
            value={keysText}
            onChange={(e) => setKeysText(e.target.value)}
            placeholder={'ADIA-XXXX-XXXX-XXXX\nADIA-YYYY-YYYY-YYYY'}
            className="input font-mono h-28 resize-y"
            required
          />
        </Field>
        <button
          type="submit"
          className="px-4 py-2 rounded-lg bg-green-600 text-white text-sm font-medium hover:bg-green-700 disabled:opacity-40"
          disabled={loading}
        >
          {loading ? 'Reactivating…' : 'Bulk reactivate'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-600">{error}</p>}
      {result && (
        <div className="card mt-3 text-sm space-y-2">
          <p className="font-medium text-green-700">
            {result.changed.length} reactivated, {result.skipped.length} skipped
          </p>
          {result.changed.length > 0 && (
            <div>
              <p className="font-medium mb-1">Reactivated:</p>
              <ul className="space-y-0.5">
                {result.changed.map((c) => (
                  <li key={c.key} className="font-mono text-xs">
                    {c.key}{' '}
                    <span className="text-ink/40 line-through">{c.previousStatus}</span>
                    {' → '}
                    <span className="text-green-700">active</span>
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

// ─── Custom notify ────────────────────────────────────────────────────────────

function NotifyPanel({ token }: { token: string }) {
  const [key, setKey] = useState('');
  const [subject, setSubject] = useState('');
  const [message, setMessage] = useState('');
  const [result, setResult] = useState<{ ok: true; key: string; to: string; sentAt: string } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function send(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch('/api/admin/notify', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ key: key.trim().toUpperCase(), subject: subject.trim(), message: message.trim() }),
      });
      const body = await res.json();
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
      <p className="text-sm text-ink/60 mb-3">
        Send a custom email to any license holder. Use this for billing follow-ups, policy notices,
        or personalised outreach. Rate-limited to 10 emails per minute.
      </p>
      <form onSubmit={send} className="card space-y-3">
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <Field label="Subject">
          <input
            value={subject}
            onChange={(e) => setSubject(e.target.value)}
            placeholder="e.g. A quick note about your Adia account"
            className="input"
            maxLength={200}
            required
          />
        </Field>
        <Field label="Message">
          <textarea
            value={message}
            onChange={(e) => setMessage(e.target.value)}
            placeholder="Your message here. Plain text — line breaks are preserved."
            className="input min-h-[100px]"
            maxLength={2000}
            required
          />
          <p className="text-xs text-ink/40 mt-1">{message.length}/2000 chars</p>
        </Field>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Sending…' : 'Send email'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}
      {result && (
        <div className="card mt-3">
          <p className="text-sm text-green-600 font-medium">Email sent.</p>
          <p className="text-xs text-ink/60 mt-1">
            To: <span className="font-mono">{result.to}</span> · Key: <span className="font-mono">{result.key}</span>
          </p>
          <p className="text-xs text-ink/40 mt-0.5">Sent at {result.sentAt.slice(0, 16).replace('T', ' ')} UTC</p>
        </div>
      )}
    </div>
  );
}

// ─── Outreach history by email ────────────────────────────────────────────────

type NotifyEntry = {
  id: number;
  licenseKey: string;
  action: string;
  detail: string | null;
  createdAt: string;
};

function NotifyHistoryPanel({ token }: { token: string }) {
  const [email, setEmail] = useState('');
  const [entries, setEntries] = useState<NotifyEntry[]>([]);
  const [total, setTotal] = useState(0);
  const [offset, setOffset] = useState(0);
  const [hasMore, setHasMore] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function load(nextOffset = 0) {
    if (!email.trim()) return;
    setLoading(true);
    setError('');
    try {
      const params = new URLSearchParams({ email: email.trim(), limit: '20', offset: String(nextOffset) });
      const res = await fetch(`/api/admin/notify-history?${params}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const body = await res.json();
      if (!res.ok) {
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
        return;
      }
      if (nextOffset === 0) {
        setEntries(body.entries ?? []);
      } else {
        setEntries(prev => [...prev, ...(body.entries ?? [])]);
      }
      setTotal(body.count ?? 0);
      setOffset(nextOffset);
      setHasMore(body.hasMore ?? false);
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  function parseDetail(raw: string | null): { to?: string; subject?: string } {
    if (!raw) return {};
    try { return JSON.parse(raw); } catch { return {}; }
  }

  return (
    <div>
      <p className="text-sm text-ink/60 mb-3">
        View all custom emails sent to a customer across all their license keys.
      </p>
      <form onSubmit={(e) => { e.preventDefault(); load(0); }} className="card space-y-3">
        <Field label="Customer email">
          <input
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            placeholder="user@example.com"
            className="input"
            type="email"
            required
          />
        </Field>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Loading…' : 'Fetch history'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}
      {entries.length > 0 && (
        <div className="mt-3 space-y-2">
          <p className="text-xs text-ink/50">{total} email{total !== 1 ? 's' : ''} sent to {email.trim().toLowerCase()}</p>
          {entries.map(e => {
            const d = parseDetail(e.detail);
            return (
              <div key={e.id} className="card text-sm space-y-0.5">
                <p className="font-medium truncate">{d.subject ?? '(no subject)'}</p>
                <p className="text-xs text-ink/50">
                  Key: <span className="font-mono">{e.licenseKey}</span>
                  {' · '}{e.createdAt.slice(0, 16).replace('T', ' ')} UTC
                </p>
              </div>
            );
          })}
          {hasMore && (
            <button
              type="button"
              className="btn-secondary w-full"
              disabled={loading}
              onClick={() => load(offset + 20)}
            >
              {loading ? 'Loading…' : 'Load more'}
            </button>
          )}
        </div>
      )}
      {!loading && entries.length === 0 && total === 0 && email && (
        <p className="mt-3 text-sm text-ink/50">No emails sent to this address.</p>
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

// ─── Bulk deactivate all machines ────────────────────────────────────────────

type BulkDeactivateAllResult = {
  ok: true;
  changed: { key: string; removedCount: number }[];
  skipped: { key: string; reason: string }[];
};

function BulkDeactivateAllPanel({ token }: { token: string }) {
  const [keysInput, setKeysInput] = useState('');
  const [result, setResult] = useState<BulkDeactivateAllResult | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    const keys = keysInput
      .split(/[\n,]+/)
      .map((k) => k.trim().toUpperCase())
      .filter(Boolean);
    if (keys.length === 0) { setError('Enter at least one key.'); return; }
    if (!confirm(`Remove ALL activations for ${keys.length} key${keys.length === 1 ? '' : 's'}? Users will need to re-activate on each machine.`)) return;
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch('/api/admin/bulk-deactivate-all', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ keys }),
      });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(await res.json());
        setKeysInput('');
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  const totalRemoved = result?.changed.reduce((s, r) => s + r.removedCount, 0) ?? 0;

  return (
    <div>
      <p className="text-sm text-ink/60 mb-3">
        Wipes every machine activation for a batch of license keys at once. Use when multiple
        customers have lost access to their machines and need seats cleared.
      </p>
      <form onSubmit={submit} className="card space-y-3">
        <Field label="License keys (one per line or comma-separated, max 100)">
          <textarea
            value={keysInput}
            onChange={(e) => setKeysInput(e.target.value)}
            placeholder={"ADIA-XXXX-XXXX-XXXX\nADIA-YYYY-YYYY-YYYY"}
            className="input font-mono text-xs min-h-[80px]"
            rows={4}
          />
        </Field>
        <button
          type="submit"
          className="px-4 py-2 rounded-lg bg-orange-600 text-white text-sm font-medium hover:bg-orange-700 disabled:opacity-40"
          disabled={loading}
        >
          {loading ? 'Deactivating…' : 'Deactivate all machines'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="mt-3 space-y-2">
          <div className="card border border-green-500/30 bg-green-50/5">
            <p className="text-sm font-semibold text-green-600">
              {result.changed.length} key{result.changed.length === 1 ? '' : 's'} cleared
              {totalRemoved > 0 && ` — ${totalRemoved} activation${totalRemoved === 1 ? '' : 's'} removed`}
            </p>
          </div>
          {result.changed.length > 0 && (
            <div className="card text-xs space-y-1">
              <p className="font-semibold text-ink/70 mb-1">Cleared</p>
              {result.changed.map((r) => (
                <p key={r.key}>
                  <span className="font-mono">{r.key}</span>
                  <span className="text-ink/50 ml-2">
                    {r.removedCount} activation{r.removedCount === 1 ? '' : 's'} removed
                  </span>
                </p>
              ))}
            </div>
          )}
          {result.skipped.length > 0 && (
            <div className="card text-xs space-y-1">
              <p className="font-semibold text-ink/70 mb-1">Skipped</p>
              {result.skipped.map((s) => (
                <p key={s.key}>
                  <span className="font-mono">{s.key}</span>
                  <span className="text-ink/50 ml-2 italic">{s.reason}</span>
                </p>
              ))}
            </div>
          )}
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

// ─── Bulk set status ──────────────────────────────────────────────────────────

type BulkSetStatusResult = {
  ok: boolean;
  changed: { key: string; previousStatus: string }[];
  skipped: { key: string; reason: string }[];
};

function BulkSetStatusPanel({ token }: { token: string }) {
  const [keys, setKeys] = useState('');
  const [status, setStatus] = useState<'active' | 'canceled' | 'expired' | 'past_due'>('canceled');
  const [result, setResult] = useState<BulkSetStatusResult | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    const parsedKeys = keys.split(/[\n,]+/).map((k) => k.trim()).filter(Boolean);
    if (!parsedKeys.length) { setError('Enter at least one key.'); return; }
    setLoading(true);
    setResult(null);
    setError('');
    try {
      const res = await fetch('/api/admin/bulk-set-status', {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ keys: parsedKeys, status }),
      });
      const body = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
      } else {
        setResult(body);
        setKeys('');
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <p className="text-sm text-ink/60 mb-3">
        Set any status on multiple licenses in one request. Replaces the need for separate
        bulk-revoke / bulk-reactivate when targeting other statuses.
      </p>
      <form onSubmit={submit} className="card space-y-3">
        <Field label="License keys (one per line or comma-separated)">
          <textarea
            value={keys}
            onChange={(e) => setKeys(e.target.value)}
            rows={4}
            placeholder={'ADIA-XXXX-XXXX-XXXX\nADIA-YYYY-YYYY-YYYY'}
            className="input font-mono w-full"
            required
          />
        </Field>
        <Field label="Target status">
          <select
            value={status}
            onChange={(e) => setStatus(e.target.value as typeof status)}
            className="input"
          >
            <option value="active">active</option>
            <option value="canceled">canceled</option>
            <option value="expired">expired</option>
            <option value="past_due">past_due</option>
          </select>
        </Field>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Setting…' : 'Set status'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}
      {result && (
        <div className="card mt-3 space-y-2 border border-green-500/30 bg-green-50/5">
          <p className="text-sm font-semibold text-green-600">
            {result.changed.length} set to &ldquo;{status}&rdquo;
            {result.skipped.length > 0 && `, ${result.skipped.length} skipped`}
          </p>
          {result.changed.length > 0 && (
            <ul className="text-xs space-y-1">
              {result.changed.map(({ key, previousStatus }) => (
                <li key={key} className="font-mono">
                  {key}{' '}
                  <span className="text-ink/50 line-through">{previousStatus}</span>
                  {' → '}
                  <span className="text-green-600">{status}</span>
                </li>
              ))}
            </ul>
          )}
          {result.skipped.length > 0 && (
            <ul className="text-xs space-y-1">
              {result.skipped.map(({ key, reason }) => (
                <li key={key} className="font-mono text-ink/50">
                  {key} — <span className="italic">{reason}</span>
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
    </div>
  );
}

// ─── Export licenses ─────────────────────────────────────────────────────────

function ExportLicensesPanel({ token }: { token: string }) {
  const [format, setFormat] = useState<'csv' | 'json'>('csv');
  const [status, setStatus] = useState('');
  const [plan, setPlan] = useState('');
  const [since, setSince] = useState('');
  const [error, setError] = useState('');
  const [jsonResult, setJsonResult] = useState<{ licenses: unknown[]; count: number } | null>(null);
  const [loading, setLoading] = useState(false);

  function buildUrl() {
    const params = new URLSearchParams({ token, format });
    if (status) params.set('status', status);
    if (plan) params.set('plan', plan);
    if (since) params.set('since', since);
    return `/api/admin/export-licenses?${params.toString()}`;
  }

  async function handleExport(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setJsonResult(null);
    setLoading(true);
    try {
      const res = await fetch(buildUrl(), { headers: { Authorization: `Bearer ${token}` } });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
        return;
      }
      if (format === 'json') {
        const body = await res.json();
        setJsonResult(body);
      } else {
        const blob = await res.blob();
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        const filename = `adia-licenses-${new Date().toISOString().slice(0, 10)}.csv`;
        a.href = url;
        a.download = filename;
        a.click();
        URL.revokeObjectURL(url);
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <p className="text-sm text-ink/60 mb-3">
        Download all licenses as CSV or JSON. Optional filters narrow the export.
      </p>
      <form onSubmit={handleExport} className="card space-y-3">
        <div className="grid grid-cols-2 gap-3">
          <Field label="Format">
            <select value={format} onChange={(e) => setFormat(e.target.value as 'csv' | 'json')} className="input w-full">
              <option value="csv">CSV</option>
              <option value="json">JSON</option>
            </select>
          </Field>
          <Field label="Status (optional)">
            <select value={status} onChange={(e) => setStatus(e.target.value)} className="input w-full">
              <option value="">All</option>
              <option value="active">active</option>
              <option value="canceled">canceled</option>
              <option value="expired">expired</option>
              <option value="past_due">past_due</option>
            </select>
          </Field>
          <Field label="Plan (optional)">
            <select value={plan} onChange={(e) => setPlan(e.target.value)} className="input w-full">
              <option value="">All</option>
              <option value="monthly">monthly</option>
              <option value="yearly">yearly</option>
              <option value="lifetime">lifetime</option>
            </select>
          </Field>
          <Field label="Issued since (optional)">
            <input
              type="date"
              value={since}
              onChange={(e) => setSince(e.target.value)}
              className="input w-full"
            />
          </Field>
        </div>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Exporting…' : format === 'csv' ? 'Download CSV' : 'Fetch JSON'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}
      {jsonResult && (
        <div className="card mt-3 space-y-2 border border-blue-500/30 bg-blue-50/5">
          <p className="text-sm font-semibold text-blue-600">{jsonResult.count} license{jsonResult.count !== 1 ? 's' : ''} returned</p>
          <pre className="text-xs font-mono overflow-x-auto max-h-64 whitespace-pre-wrap break-all">
            {JSON.stringify(jsonResult.licenses.slice(0, 5), null, 2)}
            {jsonResult.licenses.length > 5 && `\n… and ${jsonResult.licenses.length - 5} more`}
          </pre>
        </div>
      )}
    </div>
  );
}

// ─── Audit log export ────────────────────────────────────────────────────────

type AuditLogExportResult = { entries: unknown[]; count: number };

function AuditLogExportPanel({ token }: { token: string }) {
  const [format, setFormat] = useState<'csv' | 'json'>('csv');
  const [since, setSince] = useState('');
  const [action, setAction] = useState('');
  const [licenseKey, setLicenseKey] = useState('');
  const [error, setError] = useState('');
  const [jsonResult, setJsonResult] = useState<AuditLogExportResult | null>(null);
  const [loading, setLoading] = useState(false);

  function buildUrl() {
    const params = new URLSearchParams({ token, format });
    if (since) params.set('since', since);
    if (action.trim()) params.set('action', action.trim());
    if (licenseKey.trim()) params.set('licenseKey', licenseKey.trim());
    return `/api/admin/audit-log-export?${params.toString()}`;
  }

  async function handleExport(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setJsonResult(null);
    setLoading(true);
    try {
      const res = await fetch(buildUrl(), { headers: { Authorization: `Bearer ${token}` } });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        setError(`HTTP ${res.status}: ${body.error ?? 'unknown error'}`);
        return;
      }
      if (format === 'json') {
        const body = await res.json();
        setJsonResult(body);
      } else {
        const blob = await res.blob();
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        const filename = `adia-audit-log-${new Date().toISOString().slice(0, 10)}.csv`;
        a.href = url;
        a.download = filename;
        a.click();
        URL.revokeObjectURL(url);
      }
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <p className="text-sm text-ink/60 mb-3">
        Download the full admin audit log as CSV or JSON. Filter by date, action type, or license key.
      </p>
      <form onSubmit={handleExport} className="card space-y-3">
        <div className="grid grid-cols-2 gap-3">
          <Field label="Format">
            <select value={format} onChange={(e) => setFormat(e.target.value as 'csv' | 'json')} className="input w-full">
              <option value="csv">CSV</option>
              <option value="json">JSON</option>
            </select>
          </Field>
          <Field label="Since (optional)">
            <input
              type="date"
              value={since}
              onChange={(e) => setSince(e.target.value)}
              className="input w-full"
            />
          </Field>
          <Field label="Action (optional)">
            <input
              type="text"
              value={action}
              onChange={(e) => setAction(e.target.value)}
              placeholder="e.g. issue, revoke, set_status"
              className="input w-full font-mono text-xs"
            />
          </Field>
          <Field label="License key (optional)">
            <input
              type="text"
              value={licenseKey}
              onChange={(e) => setLicenseKey(e.target.value)}
              placeholder="ADIA-XXXX-YYYY"
              className="input w-full font-mono text-xs"
            />
          </Field>
        </div>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Exporting…' : format === 'csv' ? 'Download CSV' : 'Fetch JSON'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}
      {jsonResult && (
        <div className="card mt-3 space-y-2 border border-blue-500/30 bg-blue-50/5">
          <p className="text-sm font-semibold text-blue-600">{jsonResult.count} entr{jsonResult.count !== 1 ? 'ies' : 'y'} returned</p>
          <pre className="text-xs font-mono overflow-x-auto max-h-64 whitespace-pre-wrap break-all">
            {JSON.stringify(jsonResult.entries.slice(0, 5), null, 2)}
            {jsonResult.entries.length > 5 && `\n… and ${jsonResult.entries.length - 5} more`}
          </pre>
        </div>
      )}
    </div>
  );
}

// ─── Bulk note ───────────────────────────────────────────────────────────────

type BulkNoteResult = {
  ok: boolean;
  changed: { key: string; previousNote: string | null; newNote: string | null }[];
  skipped: { key: string; reason: string }[];
};

function BulkNotePanel({ token }: { token: string }) {
  const [rawKeys, setRawKeys] = useState('');
  const [note, setNote] = useState('');
  const [mode, setMode] = useState<'set' | 'append' | 'clear'>('set');
  const [result, setResult] = useState<BulkNoteResult | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setResult(null);
    const keys = rawKeys
      .split(/[\n,]+/)
      .map((k) => k.trim())
      .filter(Boolean);
    if (keys.length === 0) {
      setError('Enter at least one license key.');
      return;
    }
    setLoading(true);
    try {
      const body: Record<string, unknown> = { keys, mode };
      if (mode !== 'clear') body.note = note;
      const res = await fetch('/api/admin/bulk-note', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify(body),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(`HTTP ${res.status}: ${data.error ?? 'unknown error'}`);
        return;
      }
      setResult(data);
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <p className="text-sm text-ink/60 mb-3">
        Set, append to, or clear notes on multiple license keys at once. One key per line (or comma-separated).
      </p>
      <form onSubmit={submit} className="card space-y-3">
        <Field label="License keys (one per line or comma-separated)">
          <textarea
            value={rawKeys}
            onChange={(e) => setRawKeys(e.target.value)}
            rows={4}
            placeholder={'ADIA-XXXX-YYYY-ZZZZ\nADIA-AAAA-BBBB-CCCC'}
            className="input w-full font-mono text-xs resize-y"
          />
        </Field>
        <Field label="Mode">
          <select value={mode} onChange={(e) => setMode(e.target.value as typeof mode)} className="input w-full">
            <option value="set">set — overwrite note (empty clears)</option>
            <option value="append">append — add to existing note</option>
            <option value="clear">clear — remove note</option>
          </select>
        </Field>
        {mode !== 'clear' && (
          <Field label="Note">
            <input
              type="text"
              value={note}
              onChange={(e) => setNote(e.target.value)}
              placeholder={mode === 'append' ? 'Text to append…' : 'Note text (leave empty to clear)'}
              className="input w-full"
            />
          </Field>
        )}
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Saving…' : 'Apply'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}
      {result && (
        <div className="card mt-3 space-y-2 border border-green-500/30 bg-green-50/5">
          <p className="text-sm font-semibold text-green-600">
            {result.changed.length} changed, {result.skipped.length} skipped
          </p>
          {result.changed.length > 0 && (
            <ul className="text-xs space-y-1 font-mono">
              {result.changed.map((c) => (
                <li key={c.key} className="text-green-700">
                  ✓ {c.key} → {c.newNote === null ? <em>cleared</em> : <span>"{c.newNote}"</span>}
                </li>
              ))}
            </ul>
          )}
          {result.skipped.length > 0 && (
            <ul className="text-xs space-y-1 font-mono">
              {result.skipped.map((s) => (
                <li key={s.key} className="text-ink/50">
                  — {s.key} ({s.reason})
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
    </div>
  );
}

// ─── Bulk extend ─────────────────────────────────────────────────────────────

type BulkExtendResult = {
  ok: boolean;
  changed: { key: string; previousExpiresAt: string | null; newExpiresAt: string; days: number }[];
  skipped: { key: string; reason: string }[];
};

function BulkExtendPanel({ token }: { token: string }) {
  const [rawKeys, setRawKeys] = useState('');
  const [days, setDays] = useState('30');
  const [result, setResult] = useState<BulkExtendResult | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setResult(null);
    const keys = rawKeys
      .split(/[\n,]+/)
      .map((k) => k.trim())
      .filter(Boolean);
    if (keys.length === 0) {
      setError('Enter at least one license key.');
      return;
    }
    const daysNum = parseInt(days, 10);
    if (!Number.isInteger(daysNum) || daysNum < 1) {
      setError('Days must be a positive integer.');
      return;
    }
    setLoading(true);
    try {
      const res = await fetch('/api/admin/bulk-extend', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ keys, days: daysNum }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(`HTTP ${res.status}: ${data.error ?? 'unknown error'}`);
        return;
      }
      setResult(data);
    } catch (err: any) {
      setError(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <p className="text-sm text-ink/60 mb-3">
        Extend expiry on multiple license keys at once. Extends from the later of today or the
        current expiry, so expired licenses are never left still-expired. One key per line or
        comma-separated.
      </p>
      <form onSubmit={submit} className="card space-y-3">
        <Field label="License keys (one per line or comma-separated)">
          <textarea
            value={rawKeys}
            onChange={(e) => setRawKeys(e.target.value)}
            rows={4}
            placeholder={'ADIA-XXXX-YYYY-ZZZZ\nADIA-AAAA-BBBB-CCCC'}
            className="input w-full font-mono text-xs resize-y"
          />
        </Field>
        <Field label="Days to extend">
          <input
            type="number"
            value={days}
            onChange={(e) => setDays(e.target.value)}
            min={1}
            max={3650}
            step={1}
            className="input w-32"
          />
        </Field>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Extending…' : 'Extend'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}
      {result && (
        <div className="card mt-3 space-y-2 border border-green-500/30 bg-green-50/5">
          <p className="text-sm font-semibold text-green-600">
            {result.changed.length} extended, {result.skipped.length} skipped
          </p>
          {result.changed.length > 0 && (
            <ul className="text-xs space-y-1 font-mono">
              {result.changed.map((c) => (
                <li key={c.key} className="text-green-700">
                  ✓ {c.key} → {new Date(c.newExpiresAt).toLocaleDateString()}{' '}
                  <span className="text-ink/40">(+{c.days}d)</span>
                </li>
              ))}
            </ul>
          )}
          {result.skipped.length > 0 && (
            <ul className="text-xs space-y-1 font-mono">
              {result.skipped.map((s) => (
                <li key={s.key} className="text-ink/50">
                  — {s.key} ({s.reason})
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
    </div>
  );
}

// ─── BulkSetExpiry ─────────────────────────────────────────────────────────────

type BulkSetExpiryResult = {
  ok: boolean;
  changed: { key: string; previousExpiresAt: string | null; newExpiresAt: string | null }[];
  skipped: { key: string; reason: string }[];
};

function BulkSetExpiryPanel({ token }: { token: string }) {
  const [rawKeys, setRawKeys] = useState('');
  const [expiresAt, setExpiresAt] = useState('');
  const [lifetime, setLifetime] = useState(false);
  const [result, setResult] = useState<BulkSetExpiryResult | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setResult(null);
    const keys = rawKeys
      .split(/[\n,]+/)
      .map((k) => k.trim())
      .filter(Boolean);
    if (keys.length === 0) {
      setError('Enter at least one license key.');
      return;
    }
    if (!lifetime && !expiresAt) {
      setError('Enter an expiry date or check "Set as lifetime".');
      return;
    }
    setLoading(true);
    try {
      const res = await fetch('/api/admin/bulk-set-expiry', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ keys, expiresAt: lifetime ? null : expiresAt }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(`HTTP ${res.status}: ${data.error ?? 'unknown error'}`);
        return;
      }
      setResult(data);
    } catch (err: unknown) {
      setError(`Error: ${err instanceof Error ? err.message : String(err)}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <p className="text-sm text-ink/60 mb-3">
        Set an absolute expiry date on multiple license keys at once. Use this to align a cohort to
        a specific renewal date, convert licenses to lifetime, or immediately expire a group.
        One key per line or comma-separated.
      </p>
      <form onSubmit={submit} className="card space-y-3">
        <Field label="License keys (one per line or comma-separated)">
          <textarea
            value={rawKeys}
            onChange={(e) => setRawKeys(e.target.value)}
            rows={4}
            placeholder={'ADIA-XXXX-YYYY-ZZZZ\nADIA-AAAA-BBBB-CCCC'}
            className="input w-full font-mono text-xs resize-y"
          />
        </Field>
        <label className="flex items-center gap-2 text-sm cursor-pointer select-none">
          <input
            type="checkbox"
            checked={lifetime}
            onChange={(e) => setLifetime(e.target.checked)}
            className="rounded"
          />
          Set as lifetime (no expiry)
        </label>
        {!lifetime && (
          <Field label="New expiry date">
            <input
              type="date"
              value={expiresAt}
              onChange={(e) => setExpiresAt(e.target.value)}
              className="input"
            />
          </Field>
        )}
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Setting…' : 'Set expiry'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}
      {result && (
        <div className="card mt-3 space-y-2 border border-green-500/30 bg-green-50/5">
          <p className="text-sm font-semibold text-green-600">
            {result.changed.length} updated, {result.skipped.length} skipped
          </p>
          {result.changed.length > 0 && (
            <ul className="text-xs space-y-1 font-mono">
              {result.changed.map((c) => (
                <li key={c.key} className="text-green-700">
                  ✓ {c.key} →{' '}
                  {c.newExpiresAt ? new Date(c.newExpiresAt).toLocaleDateString() : 'lifetime'}
                </li>
              ))}
            </ul>
          )}
          {result.skipped.length > 0 && (
            <ul className="text-xs space-y-1 font-mono">
              {result.skipped.map((s) => (
                <li key={s.key} className="text-ink/50">
                  — {s.key} ({s.reason})
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
    </div>
  );
}

// ─── Bulk transfer ───────────────────────────────────────────────────────────

type BulkTransferChangedEntry = { key: string; oldEmail: string };
type BulkTransferSkippedEntry = { key: string; reason: string };

function BulkTransferPanel({ token }: { token: string }) {
  const [keysText, setKeysText] = useState('');
  const [newEmail, setNewEmail] = useState('');
  const [result, setResult] = useState<{
    ok: boolean;
    newEmail: string;
    changed: BulkTransferChangedEntry[];
    skipped: BulkTransferSkippedEntry[];
  } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setResult(null);
    const keys = keysText
      .split(/[\n,]+/)
      .map((k) => k.trim())
      .filter(Boolean);
    if (keys.length === 0) {
      setError('Enter at least one license key.');
      return;
    }
    if (!newEmail.trim()) {
      setError('Enter the destination email address.');
      return;
    }
    setLoading(true);
    try {
      const res = await fetch('/api/admin/bulk-transfer', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ keys, newEmail: newEmail.trim() }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(`HTTP ${res.status}: ${data.error ?? 'unknown error'}`);
        return;
      }
      setResult(data);
    } catch (err: unknown) {
      setError(`Error: ${err instanceof Error ? err.message : String(err)}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <p className="text-sm text-ink/60 mb-3">
        Move multiple license keys to a new owner email in one operation — for company re-orgs,
        account merges, or customers with many keys who changed their email. Keys already owned by
        the destination address or not found are silently skipped.
        One key per line or comma-separated.
      </p>
      <form onSubmit={submit} className="card space-y-3">
        <Field label="License keys (one per line or comma-separated)">
          <textarea
            value={keysText}
            onChange={(e) => setKeysText(e.target.value)}
            rows={4}
            placeholder={'ADIA-XXXX-YYYY-ZZZZ\nADIA-AAAA-BBBB-CCCC'}
            className="input w-full font-mono text-xs resize-y"
          />
        </Field>
        <Field label="Destination email">
          <input
            type="email"
            value={newEmail}
            onChange={(e) => setNewEmail(e.target.value)}
            placeholder="newowner@example.com"
            className="input"
          />
        </Field>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Transferring…' : 'Bulk transfer'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}
      {result && (
        <div className="card mt-3 space-y-2 border border-green-500/30 bg-green-50/5">
          <p className="text-sm font-semibold text-green-600">
            {result.changed.length} transferred to {result.newEmail},{' '}
            {result.skipped.length} skipped
          </p>
          {result.changed.length > 0 && (
            <ul className="text-xs space-y-1 font-mono">
              {result.changed.map((c) => (
                <li key={c.key} className="text-green-700">
                  ✓ {c.key}{' '}
                  <span className="text-ink/40">{c.oldEmail}</span>
                  {' → '}
                  {result.newEmail}
                </li>
              ))}
            </ul>
          )}
          {result.skipped.length > 0 && (
            <ul className="text-xs space-y-1 font-mono">
              {result.skipped.map((s) => (
                <li key={s.key} className="text-ink/50">
                  — {s.key} ({s.reason.replace(/_/g, ' ')})
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
    </div>
  );
}

// ─── Bulk change email ───────────────────────────────────────────────────────

type BulkChangeEmailChangedEntry = { key: string; oldEmail: string; newEmail: string };
type BulkChangeEmailSkippedEntry = { key: string; reason: string };

function BulkChangeEmailPanel({ token }: { token: string }) {
  const [changesText, setChangesText] = useState('');
  const [result, setResult] = useState<{
    ok: boolean;
    changed: BulkChangeEmailChangedEntry[];
    skipped: BulkChangeEmailSkippedEntry[];
  } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setResult(null);

    // Parse "KEY  email@example.com" lines (whitespace or comma separated)
    const lines = changesText
      .split('\n')
      .map((l) => l.trim())
      .filter(Boolean);
    const changes: { key: string; newEmail: string }[] = [];
    for (const line of lines) {
      const parts = line.split(/[\s,]+/);
      if (parts.length < 2) {
        setError(`Cannot parse line: "${line}" — expected "KEY  email@example.com"`);
        return;
      }
      changes.push({ key: parts[0], newEmail: parts[1] });
    }
    if (changes.length === 0) {
      setError('Enter at least one key → email mapping.');
      return;
    }

    setLoading(true);
    try {
      const res = await fetch('/api/admin/bulk-change-email', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ changes }),
      });
      const data = await res.json();
      if (!res.ok) {
        setError(`HTTP ${res.status}: ${data.error ?? 'unknown error'}`);
        return;
      }
      setResult(data);
    } catch (err: unknown) {
      setError(`Error: ${err instanceof Error ? err.message : String(err)}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <p className="text-sm text-ink/60 mb-3">
        Assign each license key to its own individual email address — useful for corporate seat
        reassignments where multiple employees each need a different key. Unlike "Bulk transfer"
        (all keys → one email), this maps each key to a distinct address.
        <br />
        Format: one entry per line, key followed by whitespace or comma, then the new email.
        Example: <code className="font-mono text-xs">ADIA-XXXX-YYYY-ZZZZ  alice@corp.com</code>
      </p>
      <form onSubmit={submit} className="card space-y-3">
        <Field label='Key → email pairs (one per line: "KEY  new@email.com")'>
          <textarea
            value={changesText}
            onChange={(e) => setChangesText(e.target.value)}
            rows={6}
            placeholder={'ADIA-XXXX-YYYY-ZZZZ  alice@corp.com\nADIA-AAAA-BBBB-CCCC  bob@corp.com'}
            className="input w-full font-mono text-xs resize-y"
          />
        </Field>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Changing emails…' : 'Bulk change email'}
        </button>
      </form>
      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}
      {result && (
        <div className="card mt-3 space-y-2 border border-green-500/30 bg-green-50/5">
          <p className="text-sm font-semibold text-green-600">
            {result.changed.length} changed, {result.skipped.length} skipped
          </p>
          {result.changed.length > 0 && (
            <ul className="text-xs space-y-1 font-mono">
              {result.changed.map((c) => (
                <li key={c.key} className="text-green-700">
                  ✓ {c.key}{' '}
                  <span className="text-ink/40">{c.oldEmail}</span>
                  {' → '}
                  {c.newEmail}
                </li>
              ))}
            </ul>
          )}
          {result.skipped.length > 0 && (
            <ul className="text-xs space-y-1 font-mono">
              {result.skipped.map((s) => (
                <li key={s.key} className="text-ink/50">
                  — {s.key} ({s.reason.replace(/_/g, ' ')})
                </li>
              ))}
            </ul>
          )}
        </div>
      )}
    </div>
  );
}

// ─── Dormant licenses ────────────────────────────────────────────────────────

type DormantRow = {
  key: string;
  email: string;
  plan: string;
  status: string;
  issuedAt: string;
  machineCount: number;
  lastSeen: string | null;
  note?: string | null;
};

function DormantPanel({ token }: { token: string }) {
  const [days, setDays] = useState('30');
  const [planFilter, setPlanFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [result, setResult] = useState<{ licenses: DormantRow[]; count: number; days: number } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function load(e: React.FormEvent) {
    e.preventDefault();
    if (!token) { setError('Paste admin token above first.'); return; }
    setLoading(true);
    setError('');
    setResult(null);
    try {
      const params = new URLSearchParams({ days });
      if (planFilter) params.set('plan', planFilter);
      if (statusFilter) params.set('status', statusFilter);
      const res = await fetch(`/api/admin/dormant?${params}`, {
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

  function exportCsv() {
    const params = new URLSearchParams({ days, format: 'csv', token });
    if (planFilter) params.set('plan', planFilter);
    if (statusFilter) params.set('status', statusFilter);
    const a = document.createElement('a');
    a.href = `/api/admin/dormant?${params}`;
    a.download = `adia-dormant-${days}d-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
  }

  return (
    <div>
      <p className="text-sm text-ink/60 mb-3">
        List licenses that have been activated but where every machine's last_seen is older
        than N days. Useful for re-engagement campaigns. Results ordered most-recently-seen first.
      </p>
      <form onSubmit={load} className="card space-y-3">
        <div className="flex gap-3 flex-wrap">
          <Field label="Dormant for at least (days)">
            <input
              type="number"
              min="1"
              max="365"
              value={days}
              onChange={(e) => setDays(e.target.value)}
              className="input w-24"
            />
          </Field>
          <Field label="Plan (optional)">
            <select
              value={planFilter}
              onChange={(e) => setPlanFilter(e.target.value)}
              className="input"
            >
              <option value="">All</option>
              <option value="monthly">Monthly</option>
              <option value="yearly">Yearly</option>
              <option value="lifetime">Lifetime</option>
            </select>
          </Field>
          <Field label="Status (optional)">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="input"
            >
              <option value="">All</option>
              <option value="active">Active</option>
              <option value="canceled">Canceled</option>
              <option value="expired">Expired</option>
              <option value="past_due">Past due</option>
            </select>
          </Field>
        </div>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Loading…' : 'Find dormant licenses'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="mt-4 space-y-3">
          <div className="flex items-center justify-between">
            <p className="text-sm font-semibold">
              {result.count === 0
                ? `No dormant licenses found (window: ${result.days} days)`
                : `${result.count} dormant license${result.count !== 1 ? 's' : ''} (inactive ${result.days}+ days)`}
            </p>
            {result.count > 0 && (
              <button onClick={exportCsv} className="btn-secondary text-xs px-3 py-1">
                Export CSV
              </button>
            )}
          </div>
          {result.licenses.length > 0 && (
            <div className="overflow-x-auto">
              <table className="w-full text-xs font-mono border-collapse">
                <thead>
                  <tr className="border-b border-ink/10 text-ink/50 uppercase text-left">
                    <th className="pr-3 pb-2 font-normal">Key</th>
                    <th className="pr-3 pb-2 font-normal">Email</th>
                    <th className="pr-3 pb-2 font-normal">Plan</th>
                    <th className="pr-3 pb-2 font-normal">Status</th>
                    <th className="pr-3 pb-2 font-normal">Machines</th>
                    <th className="pb-2 font-normal">Last seen</th>
                  </tr>
                </thead>
                <tbody>
                  {result.licenses.map((l) => (
                    <tr key={l.key} className="border-b border-ink/5 hover:bg-ink/5">
                      <td className="pr-3 py-1.5 text-blue-600">{l.key}</td>
                      <td className="pr-3 py-1.5 text-ink/80">{l.email}</td>
                      <td className="pr-3 py-1.5 text-ink/60">{l.plan}</td>
                      <td className={`pr-3 py-1.5 font-semibold ${l.status === 'active' ? 'text-green-600' : 'text-red-500'}`}>
                        {l.status}
                      </td>
                      <td className="pr-3 py-1.5 text-ink/60">{l.machineCount}</td>
                      <td className="py-1.5 text-ink/60">{l.lastSeen?.slice(0, 10) ?? '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

// ─── Never activated ─────────────────────────────────────────────────────────

type NeverActivatedRow = {
  key: string;
  email: string;
  plan: string;
  status: string;
  issuedAt: string;
  machineCount: number;
  note?: string | null;
};

function NeverActivatedPanel({ token }: { token: string }) {
  const [planFilter, setPlanFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [since, setSince] = useState('');
  const [result, setResult] = useState<{ licenses: NeverActivatedRow[]; count: number } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function load(e: React.FormEvent) {
    e.preventDefault();
    if (!token) { setError('Paste admin token above first.'); return; }
    setLoading(true);
    setError('');
    setResult(null);
    try {
      const params = new URLSearchParams();
      if (planFilter) params.set('plan', planFilter);
      if (statusFilter) params.set('status', statusFilter);
      if (since) params.set('since', since);
      const res = await fetch(`/api/admin/never-activated?${params}`, {
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

  function exportCsv() {
    const params = new URLSearchParams({ format: 'csv', token });
    if (planFilter) params.set('plan', planFilter);
    if (statusFilter) params.set('status', statusFilter);
    if (since) params.set('since', since);
    const a = document.createElement('a');
    a.href = `/api/admin/never-activated?${params}`;
    a.download = `adia-never-activated-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
  }

  return (
    <div>
      <p className="text-sm text-ink/60 mb-3">
        List licenses that have never been activated (machineCount = 0). Useful for finding
        keys that were issued but never opened. Results ordered newest-issued first.
      </p>
      <form onSubmit={load} className="card space-y-3">
        <div className="flex gap-3 flex-wrap">
          <Field label="Plan (optional)">
            <select
              value={planFilter}
              onChange={(e) => setPlanFilter(e.target.value)}
              className="input"
            >
              <option value="">All</option>
              <option value="monthly">Monthly</option>
              <option value="yearly">Yearly</option>
              <option value="lifetime">Lifetime</option>
            </select>
          </Field>
          <Field label="Status (optional)">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="input"
            >
              <option value="">All</option>
              <option value="active">Active</option>
              <option value="canceled">Canceled</option>
              <option value="expired">Expired</option>
              <option value="past_due">Past due</option>
            </select>
          </Field>
          <Field label="Issued since (optional)">
            <input
              type="date"
              value={since}
              onChange={(e) => setSince(e.target.value)}
              className="input w-40"
            />
          </Field>
        </div>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Loading…' : 'Find never-activated licenses'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="mt-4 space-y-3">
          <div className="flex items-center justify-between">
            <p className="text-sm font-semibold">
              {result.count === 0
                ? 'No never-activated licenses found'
                : `${result.count} license${result.count !== 1 ? 's' : ''} never activated`}
            </p>
            {result.count > 0 && (
              <button onClick={exportCsv} className="btn-secondary text-xs px-3 py-1">
                Export CSV
              </button>
            )}
          </div>
          {result.licenses.length > 0 && (
            <div className="overflow-x-auto">
              <table className="w-full text-xs font-mono border-collapse">
                <thead>
                  <tr className="border-b border-ink/10 text-ink/50 uppercase text-left">
                    <th className="pr-3 pb-2 font-normal">Key</th>
                    <th className="pr-3 pb-2 font-normal">Email</th>
                    <th className="pr-3 pb-2 font-normal">Plan</th>
                    <th className="pr-3 pb-2 font-normal">Status</th>
                    <th className="pb-2 font-normal">Issued at</th>
                  </tr>
                </thead>
                <tbody>
                  {result.licenses.map((l) => (
                    <tr key={l.key} className="border-b border-ink/5 hover:bg-ink/5">
                      <td className="pr-3 py-1.5 text-blue-600">{l.key}</td>
                      <td className="pr-3 py-1.5 text-ink/80">{l.email}</td>
                      <td className="pr-3 py-1.5 text-ink/60">{l.plan}</td>
                      <td className={`pr-3 py-1.5 font-semibold ${l.status === 'active' ? 'text-green-600' : 'text-red-500'}`}>
                        {l.status}
                      </td>
                      <td className="py-1.5 text-ink/60">{l.issuedAt?.slice(0, 10) ?? '—'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

// ─── Expiring soon ───────────────────────────────────────────────────────────

type ExpiringSoonRow = {
  key: string;
  email: string;
  plan: string;
  status: string;
  expiresAt: string | null;
  machineCount: number;
  note?: string | null;
};

function ExpiringSoonPanel({ token }: { token: string }) {
  const [days, setDays] = useState('30');
  const [planFilter, setPlanFilter] = useState('');
  const [result, setResult] = useState<{ licenses: ExpiringSoonRow[]; count: number; days: number } | null>(null);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function load(e: React.FormEvent) {
    e.preventDefault();
    if (!token) { setError('Paste admin token above first.'); return; }
    const daysNum = parseInt(days, 10);
    if (!Number.isFinite(daysNum) || daysNum < 1 || daysNum > 365) {
      setError('Days must be between 1 and 365.');
      return;
    }
    setLoading(true);
    setError('');
    setResult(null);
    try {
      const params = new URLSearchParams({ days: String(daysNum) });
      if (planFilter) params.set('plan', planFilter);
      const res = await fetch(`/api/admin/expiring-soon?${params}`, {
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

  function exportCsv() {
    if (!result) return;
    const params = new URLSearchParams({ days: String(result.days), format: 'csv', token });
    if (planFilter) params.set('plan', planFilter);
    const a = document.createElement('a');
    a.href = `/api/admin/expiring-soon?${params}`;
    a.download = `adia-expiring-${result.days}d-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
  }

  function daysUntil(expiresAt: string | null): string {
    if (!expiresAt) return '—';
    const diff = Math.ceil((new Date(expiresAt).getTime() - Date.now()) / (1000 * 60 * 60 * 24));
    if (diff <= 0) return 'today';
    return `${diff}d`;
  }

  return (
    <div>
      <p className="text-sm text-ink/60 mb-3">
        List active licenses expiring within a look-ahead window. Lifetime licenses (no expiry) are never returned.
        Results are ordered soonest-expiring first.
      </p>
      <form onSubmit={load} className="card space-y-3">
        <div className="flex gap-3">
          <Field label="Look-ahead (days)">
            <input
              type="number"
              value={days}
              onChange={(e) => setDays(e.target.value)}
              min={1}
              max={365}
              className="input w-28"
              required
            />
          </Field>
          <Field label="Plan (optional)">
            <select
              value={planFilter}
              onChange={(e) => setPlanFilter(e.target.value)}
              className="input"
            >
              <option value="">All</option>
              <option value="monthly">Monthly</option>
              <option value="yearly">Yearly</option>
            </select>
          </Field>
        </div>
        <button type="submit" className="btn-primary" disabled={loading}>
          {loading ? 'Loading…' : 'Find expiring licenses'}
        </button>
      </form>

      {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

      {result && (
        <div className="mt-4 space-y-3">
          <div className="flex items-center justify-between">
            <p className="text-sm font-semibold">
              {result.count === 0
                ? `No active licenses expiring in the next ${result.days} days`
                : `${result.count} license${result.count !== 1 ? 's' : ''} expiring in the next ${result.days} days`}
            </p>
            {result.count > 0 && (
              <button onClick={exportCsv} className="btn-secondary text-xs px-3 py-1">
                Export CSV
              </button>
            )}
          </div>
          {result.licenses.length > 0 && (
            <div className="overflow-x-auto">
              <table className="w-full text-xs font-mono border-collapse">
                <thead>
                  <tr className="border-b border-ink/10 text-ink/50 uppercase text-left">
                    <th className="pr-3 pb-2 font-normal">Key</th>
                    <th className="pr-3 pb-2 font-normal">Email</th>
                    <th className="pr-3 pb-2 font-normal">Plan</th>
                    <th className="pr-3 pb-2 font-normal">Expires at</th>
                    <th className="pb-2 font-normal">Time left</th>
                  </tr>
                </thead>
                <tbody>
                  {result.licenses.map((l) => {
                    const daysLeft = l.expiresAt
                      ? Math.ceil((new Date(l.expiresAt).getTime() - Date.now()) / (1000 * 60 * 60 * 24))
                      : null;
                    const urgent = daysLeft !== null && daysLeft <= 7;
                    return (
                      <tr key={l.key} className="border-b border-ink/5 hover:bg-ink/5">
                        <td className="pr-3 py-1.5 text-blue-600">{l.key}</td>
                        <td className="pr-3 py-1.5 text-ink/80">{l.email}</td>
                        <td className="pr-3 py-1.5 text-ink/60">{l.plan}</td>
                        <td className="pr-3 py-1.5 text-ink/60">{l.expiresAt?.slice(0, 10) ?? '—'}</td>
                        <td className={`py-1.5 font-semibold ${urgent ? 'text-red-500' : 'text-yellow-600'}`}>
                          {daysUntil(l.expiresAt)}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>
      )}
    </div>
  );
}

// ─── Shared ────────────────────────────────────────────────────────────────────

function CollapsibleSection({
  title,
  defaultOpen = false,
  children,
}: {
  title: string;
  defaultOpen?: boolean;
  children: React.ReactNode;
}) {
  const filter = useContext(SectionFilterContext);
  const [open, setOpen] = useState(defaultOpen);
  if (filter && !title.toLowerCase().includes(filter.toLowerCase())) return null;
  return (
    <div className="border border-ink/10 rounded-xl overflow-hidden">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className="w-full flex items-center justify-between px-5 py-4 text-left hover:bg-ink/5 transition-colors"
      >
        <span className="font-semibold text-sm">{title}</span>
        <svg
          className={`w-4 h-4 text-ink/40 transition-transform ${open ? 'rotate-180' : ''}`}
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <polyline points="6 9 12 15 18 9" />
        </svg>
      </button>
      {open && <div className="px-5 pb-5 pt-3 border-t border-ink/10">{children}</div>}
    </div>
  );
}

function Field({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <label className="block">
      <span className="text-xs uppercase tracking-wide text-ink/60">{label}</span>
      <div className="mt-1">{children}</div>
    </label>
  );
}
