import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Changelog — Adia',
  description: 'What shipped, when.',
};

type Entry = {
  version: string;
  date: string;
  bullets: string[];
};

const entries: Entry[] = [
  {
    version: '0.1.0',
    date: '2026-05',
    bullets: [
      'First public build.',
      'Notch UI with collapsed pill + expanded session card.',
      'On-task detection via Claude Haiku vision (1–2 s, cheap) + Claude Sonnet for verification.',
      'Friend-tone callouts when off-task.',
      '/etc/hosts blocking + local "blocked by Adia" page.',
      'Reasoning conversation for site access.',
      'Task verification — checks screen against your success criteria before unblocking.',
      'Bring-your-own Anthropic API key (stored in Keychain).',
      '7-day free trial, then $7/mo, $59/yr, or $149 lifetime.',
    ],
  },
];

export default function Changelog() {
  return (
    <section className="pt-12 pb-20 max-w-2xl">
      <h1 className="text-4xl font-semibold tracking-tight">Changelog</h1>
      <p className="mt-3 text-ink/70">
        Subscribe to the <a href="https://github.com/jackyhnc/adia/releases.atom">releases feed</a> for updates.
      </p>

      <div className="mt-10 space-y-10">
        {entries.map((e) => (
          <article key={e.version}>
            <header className="flex items-baseline gap-3">
              <h2 className="text-2xl font-semibold">v{e.version}</h2>
              <span className="text-sm text-ink/50">{e.date}</span>
            </header>
            <ul className="mt-3 space-y-1 text-sm text-ink/80 list-disc pl-5">
              {e.bullets.map((b, i) => <li key={i}>{b}</li>)}
            </ul>
          </article>
        ))}
      </div>
    </section>
  );
}
