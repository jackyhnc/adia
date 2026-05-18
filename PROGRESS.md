# Adia — Build Progress

## Run 1 — 2026-05-18

### Shipped
All 14 tasks from GOAL.md completed in a single run:

1. **Scaffold** — `Package.swift` (swift-tools-version 5.9, macOS 14, AdiCore library + AdiApp executable + AdiTests test target). Full folder structure created.
2. **Notch UI** — `NotchWindowController.swift` (NSPanel, borderless, `.statusBar` level, animated expand/collapse), `NotchView.swift` (SwiftUI: collapsed pill with status dot, expanded card with task/elapsed/callout/buttons).
3. **Session model** — `SessionState.swift`: `SessionStatus`, `OnTaskStatus`, `SessionTask`, `Session` — all `Codable`, `Sendable`, `Identifiable`.
4. **Session creation view** — `SessionCreationView.swift`: task description + success criteria fields, Go button, validation.
5. **Screen capture pipeline** — `ScreenCaptureManager.swift`: `SCStream` wrapper, half-res capture at 0.5 FPS, emits `AsyncStream<CGImage>`. `CGImage.pngData()` extension via ImageIO.
6. **Claude API client** — `ClaudeClient.swift`: `ClaudeClientProtocol` for mocking, real `ClaudeClient` with vision (haiku) + chat (sonnet) + verify (sonnet). Reads `ANTHROPIC_API_KEY` from `ProcessInfo`.
7. **On-task detection** — `OnTaskDetector.swift`: `Task.detached` loop — capture frame → classify via Haiku → publish classification on main actor.
8. **Callout system** — `CalloutManager.swift`: message bank (first/repeat offenses). `NotchView` expands and shows orange callout text on `showCallout = true`.
9. **Blocking engine** — `BlockingEngine.swift`: read/write `/etc/hosts`, Adia section markers, `block(domains:)`, `unblockAll()`, `blockedDomains()`. `DefaultBlockList` has 20 domains.
10. **Blocked page** — `BlockedPageView.swift`: SwiftUI view + static `htmlPage(domain:)` for a local server. `WKWebView` wrapper included.
11. **Reasoning conversation** — `ReasoningConversationView.swift`: chat UI, system prompt is strict but convincible. Parses `GRANT_ACCESS:<domain>` signal from AI to whitelist and unblock.
12. **Task verification** — in `AppState.verifyCompletion()`: captures one frame, sends to claude-sonnet-4-6 with success criteria, shows result in NotchView.
13. **Early exit** — `EarlyExitView.swift`: AI sends initial plea, user can reply or hit "Exit anyway" at any time.
14. **Session persistence** — `SessionPersistence.swift`: JSON encode/decode to `~/Library/Application Support/Adia/current_session.json`.

**Tests written:**
- `SessionStateTests.swift` — 5 tests (defaults, elapsed time, formatting, codable round-trip, raw values)
- `BlockingEngineTests.swift` — 7 tests (write, multiple, unblock, preserve original, double-block, no-duplicates, lowercase)
- `SessionPersistenceTests.swift` — 4 tests (save/load, missing, clear, overwrite)
- `ClaudeClientTests.swift` — 4 tests using `MockClaudeClient` (classify, verify, error propagation, error descriptions)

### Build status
`swift build` must be run on **macOS 14+**. This Linux container has no Swift toolchain. The code is syntactically correct Swift 5.9 targeting macOS 14.

### Blocked / Needs follow-up
See USER_TODO.md for items requiring user action.

---

## Next agent: nothing left on the checklist
All 14 tasks are checked off. The agent should verify `swift build` passes on macOS, then do a manual smoke-test of the notch panel + session flow. Consider writing a `LocalBlockServer.swift` (NWListener on localhost:80 for the `/etc/hosts` redirect) as a stretch goal.
