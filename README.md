# Adia

A macOS focus app that lives in your MacBook's notch.

You tell it what you're working on and how you'll know you're done. While the session is active, Adia watches your screen, blocks distracting sites, and calls you out — like a friend sitting next to you — when you wander off-task. When you tap **Done**, Adia verifies you actually finished by looking at your screen.

## Requirements

- macOS 14 (Sonoma) or later, MacBook with a notch recommended
- Swift 6.0+ toolchain
- An Anthropic API key
- Xcode 26+ (only required if you want to run `xcodebuild test`)

## Build & run

```bash
git clone https://github.com/jackyhnc/adia.git
cd adia
export ANTHROPIC_API_KEY=sk-ant-...
swift build -c release
sudo .build/release/Adia    # sudo lets /etc/hosts blocking work
```

`sudo` is only needed if you want the hosts-file blocking to apply. Without it, the local blocked-page server still runs on port 8080, but system-wide DNS blocking is skipped.

On first launch, macOS will prompt for:
- **Screen Recording** (required) — System Settings → Privacy & Security → Screen Recording
- **Accessibility** (optional, for app-name detection)

## How it works

1. **Tell it the task.** Click the notch to expand the panel. Enter the task (`"Write ENGL 101 essay"`) and the success criteria (`"Submit to Canvas"`). Hit Go.
2. **Adia watches.** A `ScreenCaptureKit` stream sends a screenshot to `claude-haiku-4-5` every ~1.5s for on/off-task classification.
3. **Off-task? Adia calls you out.** After 2 consecutive off-task frames, the notch shows a short, direct message (`"yo, what are you doing?"`).
4. **Distracting sites are blocked.** Default blocklist (Twitter, YouTube, Reddit, etc.) goes into `/etc/hosts`. A local server serves a "blocked by Adia" page when you hit one.
5. **Need a site unblocked?** Click "Chat" and argue your case. `claude-sonnet-4-6` decides — if it grants access, the domain is whitelisted for the rest of the session.
6. **Trying to bail?** Click "Exit" and the AI tries to talk you into one more push. You can always override.
7. **Done? Adia verifies.** Click "Done" and the last screenshot goes to `claude-sonnet-4-6` along with your success criteria. If verified, everything unblocks and the session ends. If not, you see why.

## Architecture

```
Sources/AdiApp/         — NSApplication entry point, status item
Sources/AdiCore/
  AI/ClaudeClient.swift     — Anthropic API (vision + chat)
  Blocking/                 — HostsFileManager, LocalBlockServer
  Callout/                  — off-task callout state machine
  Capture/                  — ScreenCaptureKit pipeline
  Conversation/             — reasoning + early-exit chat
  Models/                   — Session, ChatMessage, etc.
  Persistence/              — UserDefaults session storage
  Views/                    — SwiftUI views (notch, conversation)
  NotchView, NotchState, NotchWindowController, SessionManager
Tests/AdiTests/         — Swift Testing suites
```

`SessionManager` is the central coordinator; everything else is a single-purpose component reachable via `.shared`.

## Tests

```bash
swift test                            # CLI runner
xcodebuild test -scheme Adia          # Xcode runner (recommended)
```

The CLI runner requires Swift Testing framework paths that are already wired in `Package.swift`.

## Configuration

| Env var | Required | Default |
|---|---|---|
| `ANTHROPIC_API_KEY` | yes | — |

Default blocked domains live in `Sources/AdiCore/Models/SessionState.swift` (`Session.defaultBlockedDomains`). Sessions persist for 24h in `UserDefaults` so a crash mid-session doesn't lose your context.

## Ship it

```bash
VERSION=0.1.0 scripts/release.sh           # build → sign → notarize → DMG
```

That produces `dist/Adia-0.1.0.dmg`. With Apple Developer credentials set as env vars it's signed + notarized; without them it falls back to an ad-hoc-signed DMG (works locally; Gatekeeper will warn).

Full deployment guide (Stripe, Resend, Vercel, GitHub Actions): see [DEPLOY.md](DEPLOY.md).

## Repo layout

```
Sources/            Swift app + library
Tests/              Swift test suites
scripts/            build-app, sign, notarize, build-dmg, release
Resources/          entitlements, Info.plist template, app icon
web/                Next.js — adia.app marketing site + license/billing API
.github/workflows/  CI + release-on-tag pipeline
BRAND.md            positioning, pricing
DEPLOY.md           how to actually ship
PRIVACY.md          privacy policy
TERMS.md            EULA
```

## Status

v0.1, ready to ship pending: domain + Apple Developer + Stripe accounts. See [DEPLOY.md](DEPLOY.md) for the launch checklist and `USER_TODO.md` for the manual items.
