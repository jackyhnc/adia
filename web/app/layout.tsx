import type { Metadata } from 'next';
import './globals.css';
import Link from 'next/link';

export const metadata: Metadata = {
  metadataBase: new URL('https://adia.app'),
  title: 'Adia — the friend in your notch who keeps you on task',
  description:
    'Tell Adia what you\'re working on. It watches your screen, blocks distracting sites, and calls you out when you wander. Verifies you actually finished.',
  openGraph: {
    title: 'Adia',
    description: 'The friend in your notch who keeps you on task.',
    url: 'https://adia.app',
    siteName: 'Adia',
    type: 'website',
  },
  twitter: { card: 'summary_large_image', title: 'Adia', description: 'The friend in your notch who keeps you on task.' },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>
        <header className="px-6 py-5 flex items-center justify-between max-w-6xl mx-auto">
          <Link href="/" className="no-underline flex items-center gap-2 text-lg font-semibold">
            <span className="inline-block w-5 h-2 rounded-full bg-ink" />
            adia
          </Link>
          <nav className="flex gap-6 text-sm">
            <Link href="/pricing" className="no-underline hover:opacity-70">Pricing</Link>
            <Link href="/download" className="no-underline hover:opacity-70">Download</Link>
            <Link href="/changelog" className="no-underline hover:opacity-70">Changelog</Link>
            <a href="https://github.com/jackyhnc/adia" className="no-underline hover:opacity-70">GitHub</a>
          </nav>
        </header>
        <main className="max-w-6xl mx-auto px-6 pb-16">{children}</main>
        <footer className="border-t border-ink/10 px-6 py-8 mt-12">
          <div className="max-w-6xl mx-auto flex flex-col md:flex-row gap-4 justify-between text-sm text-ink/60">
            <div>© 2026 Adia</div>
            <div className="flex gap-5">
              <Link href="/billing" className="no-underline hover:opacity-70">Billing</Link>
              <Link href="/privacy" className="no-underline hover:opacity-70">Privacy</Link>
              <Link href="/terms" className="no-underline hover:opacity-70">Terms</Link>
              <a href="mailto:support@adia.app" className="no-underline hover:opacity-70">Support</a>
            </div>
          </div>
        </footer>
      </body>
    </html>
  );
}
