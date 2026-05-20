// Dynamic OG image for adia.app. Next.js auto-wires this to /opengraph-image.
import { ImageResponse } from 'next/og';

export const runtime = 'edge';
export const alt = 'Adia — the friend in your notch who keeps you on task';
export const size = { width: 1200, height: 630 };
export const contentType = 'image/png';

export default async function Image() {
  return new ImageResponse(
    (
      <div
        style={{
          width: '100%',
          height: '100%',
          background: '#fafaf7',
          color: '#0a0a0a',
          display: 'flex',
          flexDirection: 'column',
          justifyContent: 'space-between',
          padding: 72,
          fontFamily: 'ui-sans-serif, system-ui, -apple-system, "Segoe UI", sans-serif',
        }}
      >
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <div style={{ width: 56, height: 22, borderRadius: 12, background: '#0a0a0a' }} />
          <div style={{ fontSize: 28, fontWeight: 600 }}>adia</div>
        </div>

        <div>
          <div style={{ fontSize: 80, fontWeight: 600, lineHeight: 1.05, letterSpacing: -2 }}>
            the friend in your notch
            <br />
            who keeps you on task.
          </div>
          <div style={{ marginTop: 24, fontSize: 28, color: 'rgba(10,10,10,0.55)' }}>
            macOS · 7-day free trial · adia.app
          </div>
        </div>

        <div
          style={{
            display: 'flex',
            justifyContent: 'space-between',
            alignItems: 'center',
            fontSize: 18,
            color: 'rgba(10,10,10,0.4)',
          }}
        >
          <span>watches your screen. blocks distractions. verifies you finished.</span>
          <span style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <span style={{ width: 6, height: 6, borderRadius: 3, background: '#ff5a36' }} />
            now in early access
          </span>
        </div>
      </div>
    ),
    { ...size },
  );
}
