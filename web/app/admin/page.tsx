'use client';

import { useState } from 'react';

export default function Admin() {
  const [token, setToken] = useState('');
  const [key, setKey] = useState('');
  const [email, setEmail] = useState('');
  const [result, setResult] = useState<string>('');
  const [loading, setLoading] = useState(false);

  async function lookup(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setResult('');
    try {
      const params = new URLSearchParams({ key, token });
      if (email) params.set('email', email);
      const res = await fetch(`/api/admin/lookup?${params.toString()}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const text = await res.text();
      setResult(`HTTP ${res.status}\n\n${text}`);
    } catch (err: any) {
      setResult(`Error: ${err.message}`);
    } finally {
      setLoading(false);
    }
  }

  return (
    <section className="pt-12 pb-20 max-w-xl">
      <h1 className="text-3xl font-semibold tracking-tight">Admin · license lookup</h1>
      <p className="mt-2 text-sm text-ink/60">
        Requires <code className="font-mono">ADMIN_TOKEN</code> env var on the server. This page
        is unindexed and can be removed entirely if you'd rather hit the API with curl.
      </p>

      <form onSubmit={lookup} className="card mt-8 space-y-3">
        <Field label="Admin token">
          <input
            type="password"
            value={token}
            onChange={(e) => setToken(e.target.value)}
            className="input"
            required
          />
        </Field>
        <Field label="License key">
          <input
            value={key}
            onChange={(e) => setKey(e.target.value)}
            placeholder="ADIA-XXXX-XXXX-XXXX"
            className="input font-mono"
            required
          />
        </Field>
        <Field label="Email (optional)">
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

      {result && (
        <pre className="card mt-4 font-mono text-xs whitespace-pre-wrap">{result}</pre>
      )}
    </section>
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
