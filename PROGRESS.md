# Adia — Build Progress

## Run 14 — 2026-05-23

### Shipped
- **Fix: `ExpandedView` transparent panel bottom** — The expanded notch VStack used `frame(maxWidth: .infinity)` but no `maxHeight`, so its dark rounded-rect background only covered the content area (~250–300pt). The lower portion of the fixed-size NSPanel (e.g. 390pt in conversation mode) was transparent — the panel's clear `backgroundColor` showed through to the screen below. Fixed with `frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)`. The `.topLeading` alignment pins header at the top; the dark RoundedRectangle background now fills the full panel height.
- **Fix: `ConversationView` message list capped at 180pt** — Previously the `ScrollViewReader` had `.frame(maxHeight: 180)`, leaving ~110pt of dark background visible below the action buttons instead of giving it to the scroll view. Changed to `.frame(maxHeight: .infinity)` now that `ExpandedView` fills the panel. The scroll view now uses all available height above the input row and action chips.
- **Fix: `SettingsStore.readKey` mutable-but-never-mutated `query`** — `var query: [String: Any]` was never mutated; changed to `let`, removing the Swift compiler warning.
- **Fix: `LocalBlockServer.blockedHTML` capitalised task mid-sentence** — Blocked page displayed `"you said you'd Write my essay."` (capital W) for tasks starting with a verb. Now lowercases the first character before interpolation: `"you said you'd write my essay."`.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Remaining runtime gaps are hardware-only: (1) integration smoke test on a real macOS machine with `ANTHROPIC_API_KEY`; (2) UX test of the notch panel on a MacBook with a physical notch.

---

## Run 13 — 2026-05-22

### Shipped
- **Fix: `CalloutManager` auto-dismiss race condition** — Two consecutive off-task streaks created two independent `Task` values. The first task's 8-second timer could fire mid-second-streak and clear a callout it didn't own. Fixed by storing `autoDismissTask: Task<Void, Never>?` on the class. `fire()` cancels the old task before starting a new one; `reset()` also cancels the pending task. The new task uses `try await Task.sleep(for: .seconds(8))` with a `catch` block so cancellation is silent. Removed the now-redundant `[weak self]`/`hasFiredForStreak` guard from the task body.
- **Fix: `SettingsStore.normalizeDomain` port stripping** — A domain entered as `"example.com:8080"` was stored verbatim, producing the malformed `/etc/hosts` entry `127.0.0.1 example.com:8080` (hosts files do not support ports). Added `s = s.components(separatedBy: ":").first ?? s` after path and query stripping. Updated the docstring. Three new test cases: bare port, port with full URL, `localhost:3000`.
- **Fix: `OnTaskDetector.evaluate()` rate-limit ordering** — `isConfigured()` (which hops to `@MainActor` to read `SettingsStore.shared.anthropicAPIKey`) was called on every frame, even when the rate-limit guard was about to return the cached status anyway. Moved the rate-limit check before `isConfigured()` so the MainActor hop happens only when an API call is actually needed (~1× per second vs. every delivered frame). `lastEvaluatedAt = now` is set after `isConfigured()` succeeds so a missing key doesn't consume the time-window slot.
- **Tests: `NotchStateTests.swift` (+14 cases)** — First test coverage for `NotchState`, the core UI state machine. Tests cover: collapse defaults, expand/toggle, collapse resets all flags, startCreating/stopCreating, showCallout/clearCallout, setVerifying (expand + clear result), setVerifying(false) no expand, setVerificationResult clears isVerifying, setVerificationResult(nil), exitConversation clears showingConversation, startConversation clears verificationResult. Suite runs `.serialized` to avoid races on the shared singleton.
- **Tests: `CalloutManagerTests.swift` (+1 case)** — `resetCancelsAutoDismissBeforeNewStreak` guards the specific race condition fixed above: two streaks with reset in between should produce independent callouts.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. The remaining runtime gaps are hardware-only: (1) integration smoke test on a real macOS machine with `ANTHROPIC_API_KEY`; (2) UX test of the notch panel on a MacBook with a physical notch.

---

## Run 12 — 2026-05-22

### Shipped
- **Fix: `ScreenCaptureManager` Linux stub missing `lastFrame`** — The `#else` stub (non-ScreenCaptureKit platforms / Linux CI) was missing `lastFrame: CGImage?`. `SessionManager.verifyAndEnd()` accesses `captureManager.lastFrame` unconditionally, so this was a guaranteed compile error on Linux. Added `public var lastFrame: CGImage? { nil }` to the stub.
- **Fix: `ConversationManager` GCD/actor mixing** — Both `grantAccess(domain:)` and `parseAccessDecision(from:)` used `DispatchQueue.main.asyncAfter` for delayed navigation. On a `@MainActor` class in Swift 6, mixing GCD dispatch with structured concurrency is fragile and potentially unsafe. Replaced both with `Task { @MainActor in try? await Task.sleep(for: ...) }`.
- **Fix: HTML injection in `LocalBlockServer.blockedHTML`** — The `domain` (extracted from HTTP `Host:` header) and `taskDescription` (user input) were interpolated directly into the HTML response without sanitization. A task like `"write <ENGL 101> essay & \"cover page\""` would break the blocked page's HTML structure. Added `htmlEscape(_:)` (internal static, testable) that replaces `&`, `<`, `>`, `"` with safe entities; applied to both injected values.
- **UX: Elapsed time in collapsed notch pill** — The collapsed notch previously showed a static "Focus" label when a session was active. Now shows live elapsed time via `TimelineView(.periodic(..., by: 60))`: "3m", "1h 23m", etc. Returns "Focus" only for the first sub-minute of a session. Updates every minute without triggering extra API calls.
- **Tests: +6 cases** in `LocalBlockServerTests` covering `htmlEscape`: plain passthrough, `&`, `<>`, `"`, combined realistic task description, empty string.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Remaining known gaps: (1) integration smoke test on a real macOS machine with `ANTHROPIC_API_KEY` set; (2) runtime UX testing on a MacBook with a notch.

---

## Run 11 — 2026-05-22

### Shipped
- **Fix: Chat-without-domain opening message** — `ConversationManager.openingMessage(for:)` previously returned "why do you need that site right now?" even when domain was nil/empty (user tapped Chat while on-task, no blocked site). Now returns "what's up?" for nil/empty domain, preserving the "why do you need X right now?" phrasing only when a specific domain is present.
- **Fix: Chat-without-domain missing close button** — `ConversationView.reasoningActions(domain:)` previously showed nothing when `domain.isEmpty` and no access decision had been made. The only escape was the header back chevron (not obvious). Added an `else` branch that shows a "Close" action chip in this case.
- **Fix: Callout auto-dismiss after 8 seconds** — `CalloutManager.fire()` now schedules a detached `Task` that waits 8 seconds and clears the callout if `hasFiredForStreak` is still true (i.e. user hasn't returned to on-task). Prevents the callout banner from sticking permanently when ignored.
- **Tests: +4 cases** — `ConversationManagerTests`: nil domain opens "what's up?", empty domain opens "what's up?", real domain mentions domain in opening. `CalloutManagerTests`: callout message string is non-empty.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Remaining known gaps: (1) integration smoke test on a real macOS machine with `ANTHROPIC_API_KEY` set; (2) runtime UX testing on a MacBook with a notch.

---

## Run 10 — 2026-05-21

### Shipped
- **Bug fix: `SessionManager.restoreIfNeeded()` actually restores** — the previous implementation set `session` but never restarted capture or blocking. The UI showed active buttons (Done/Chat/Exit) while nothing ran underneath; tapping "Done" silently skipped verification. Extracted a shared `activate(_ session: Session) async throws` helper used by both `start()` and `restoreIfNeeded()`. The restore path catches capture errors and logs them rather than propagating.
- **Bug fix: `whitelist(domain:)` empty-domain guard** — when `Chat` was opened with `.reasoning(domain: nil)`, clicking "Grant Access" called `whitelist(domain: "")`, appending `""` to `whitelistedDomains`. Added `guard !trimmed.isEmpty` at the top of `whitelist(domain:)`.
- **Bug fix: `ConversationView.reasoningActions` hides chips for no-domain case** — the Grant Access / Keep Blocked action chips were shown even when `domain` was `""` (user opened Chat from the notch without a blocked site involved). Changed to `else if !domain.isEmpty` so the chips only appear when there's a specific site to grant/deny.
- **New test file: `SessionManagerTests.swift`** — 7 tests covering: empty/whitespace domain is a no-op, www-stripped domain is whitelisted and removed from blockedDomains, no-session whitelist is a no-op, no saved session leaves `session` nil, stale sessions (>24h) are discarded by `SessionPersistence.load()`.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Known gaps if re-invoked: (1) integration smoke test on a real macOS machine with `ANTHROPIC_API_KEY` set; (2) runtime UX testing on a MacBook with a notch; (3) the "Chat" button without a blocked domain shows a conversation but no domain-specific action chips — consider whether to add a generic "all good" close button for this flow.

---

## Run 9 — 2026-05-21

### Shipped
- **Revert OpenAI backend → Anthropic Claude API** — a prior agent run (Run 8 followup commits) switched `ClaudeClient.swift` to hit `api.openai.com` with `gpt-5.4-mini` (a hallucinated model name) and relabelled all UI strings to "OpenAI/GPT". This run restores the spec-correct implementation:
  - `ClaudeClient.swift`: base URL → `https://api.anthropic.com/v1/messages`; auth headers → `x-api-key` + `anthropic-version: 2023-06-01`; request format → Anthropic Messages API (`system` top-level, image blocks via `source.type=base64`); response parsing → `content[0].text`; removed OpenAI-specific `max_completion_tokens` fallback retry; split models — `claude-haiku-4-5-20251001` for classify/chat, `claude-sonnet-4-6` for verify.
  - `OnboardingView.swift`: "OpenAI API key" → "Anthropic API key"; description → mentions Claude; placeholder → `sk-ant-...`; link → `console.anthropic.com/settings/api-keys`.
  - `SettingsView.swift`: section header and placeholder corrected to Anthropic.
  - `SettingsStore.swift`: removed `OPENAI_API_KEY` env fallback; home-file lookup now tries `anthropic_key` first (dropped `openai_key`); updated comments.
  - `AppDelegate.swift`: minor comment updated.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. App is spec-correct: Anthropic Claude API throughout. If re-invoked: (1) integration smoke test on macOS with `ANTHROPIC_API_KEY` set; (2) UX testing of notch panel on hardware with a notch.

---

## Run 8 — 2026-05-20

### Shipped
- **Settings window lifecycle fix** (`AppDelegate.swift`) — after the user opened Settings via the gear icon in the notch, `NSApp.setActivationPolicy(.regular)` was called but never restored to `.accessory` when the window closed, leaving the dock icon lingering. Added a `NSWindow.willCloseNotification` observer in `applicationDidFinishLaunching` that fires a `Task { @MainActor in }` on every window close; if no non-panel, visible windows remain, it restores `.accessory` policy. The Task hop ensures the closing window is fully gone before `NSApp.windows` is consulted. No interaction with the existing onboarding flow (which already calls `.accessory` explicitly in `finishOnboarding`).
- **Callout height fix** (`NotchWindowController.swift`) — the active-session panel used a fixed `expandedHeight = 190` regardless of whether the callout banner was visible. A callout text block at 15pt bold + 12/4pt padding adds ~35pt, pushing a 2-line task description + buttons past the 190pt frame, clipping the bottom row. Added `calloutExpandedHeight = 235` and a new `NotchState.shared.$calloutMessage` Combine sink that calls `positionPanel` whenever the callout appears or disappears. The `targetFrame` branch order now checks `calloutMessage != nil` before falling through to the base `expandedHeight`.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Known quality issues resolved: Settings lifecycle bug (Run 8), callout clipping (Run 8), blocking engine cross-session state (Run 6), HostsFileManager test coverage (Run 6). If re-invoked: (1) integration smoke test with a real API key on a macOS machine; (2) runtime UX testing of the notch panel on an actual MacBook with notch hardware.

---

## Run 7 — 2026-05-20

### Shipped
- **Settings panel (⌘,)** — replaced the empty `Settings { EmptyView() }` scene with a real two-tab settings window (`SettingsView.swift`).
  - **Account tab**: shows masked API key (`sk-ant-…XXXXXX`), inline Update/Add flow with `SecureField`, license status (trial countdown, activated email+plan, or inline activate form for expired/unknown state).
  - **Blocking tab**: toggleable list of all 18 default blocked domains, plus add/remove custom domains (input is normalized via `normalizeDomain`: strips `https://`, `www.`, paths, and query strings).
- **SettingsStore domain management** — six new public methods: `addCustomDomain`, `removeCustomDomain`, `setDefaultDomain(enabled:)`, `isDefaultDomainEnabled`, plus `effectiveBlockedDomains` (computed: enabled defaults + custom), `normalizeDomain` (static). Custom and disabled domains persist via UserDefaults as JSON.
- **SessionManager.start** uses `SettingsStore.shared.effectiveBlockedDomains` instead of the static default list, so user customisations take effect from session start.
- **Notch gear button** — small gear icon appears in the expanded notch header when no session is active; tapping it opens Settings via `NSApp.sendAction(showSettingsWindow:)`.
- **Tests: +20 cases** in `SettingsStoreTests.swift` covering `normalizeDomain` (6 cases: https/http/www/combined/passthrough/lowercase), custom domain CRUD (5 cases: add, normalize-on-add, deduplicate, reject-default, remove), default domain toggle (3 cases: disable/re-enable/isEnabled), `effectiveBlockedDomains` (2 cases: includes custom + no duplicates).

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Potential follow-ups:
  1. **Integration smoke test** on a real macOS machine with `ANTHROPIC_API_KEY` set.
  2. **Settings window lifecycle**: after opening Settings, `NSApp.setActivationPolicy(.regular)` is called but never reset to `.accessory` when the window closes — the dock icon lingers. Fix: observe the Settings `NSWindow` close notification and call `NSApp.setActivationPolicy(.accessory)`.
  3. **Notch height for active session with callout**: the panel uses `expandedHeight = 190`. If `calloutMessage` is long, the content may clip. A `calloutHeight` constant could be added to `NotchWindowController` and CombineLatest-subscribed.

---

## Run 6 — 2026-05-20

### Shipped
- **Bug fix: CalloutManager cross-session state leak** — `reset()` was `private`; stale `hasFiredForStreak=true` and `consecutiveOffTask` survived into the next session, silently suppressing the first off-task callout. Made `reset()` public and called it from `SessionManager.start()` before `detector.attach()`. New test: `publicResetAllowsNewStreakToFire`.
- **HostsFileManager test coverage** — the three pure string helpers (`stripped`, `buildBlock`, `parseBlocked`) were entirely untested. Promoted them from `private` instance methods to `nonisolated static internal`, allowing synchronous test calls with no actor hop. Added a malformed-content guard in `parseBlocked` (`begin.upperBound <= end.lowerBound`). Test file grew from 18 lines / 2 trivial checks to 120 lines / 15 tests covering stripped (4), buildBlock (4), parseBlocked (3), round-trip (2), defaults sanity (2).
- **Expanded blocked-domain list** — added `pinterest.com`, `snapchat.com`, `threads.net`, `tumblr.com`, `9gag.com` to `Session.defaultBlockedDomains`.
- **Minor**: annotated force-unwrap in `SettingsStore.writeKey` per the no-force-unwrap quality rule.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. All known bugs are fixed. Focus areas if re-invoked: (1) integration smoke test with a real Anthropic API key on a macOS machine; (2) runtime UX testing of the notch UI on an actual MacBook with a notch; (3) consider adding a `Settings` panel (hotkey to open Adia, manage API key after onboarding, toggle blocked domains list).

---

## Run 5 — 2026-05-19

### Shipped
- **OnTaskDetector rate-limiting guard** — added `lastEvaluatedAt: Date?` and `lastStatus` cache to `OnTaskDetector`. Frames arriving faster than `minInterval` (1.0s) return the cached last result instead of firing a redundant API call. `attach()` resets both fields so each new session starts clean.
- **Callout threshold tests** — added 4 new `@Test` cases to `CalloutManagerTests.swift`: `doesNotFireBeforeThreshold`, `firesCalloutAtThreshold`, `doesNotRefireWithinSameStreak`, `refiresAfterRecovery`. These cover the full streak state machine (threshold=2, single-fire per streak, reset on onTask).
- **BUILD_COMPLETE** — all 14 goals verified complete; wrote `BUILD_COMPLETE` file summarizing shipped features.

### Blocked
- None.

### Next agent
- No outstanding code tasks. All 14 GOAL.md items are complete. If re-invoked, focus on: (1) integration smoke test with a real API key once in a macOS env, (2) any regression fixes from actual runtime testing.

---

## Run 4 — 2026-05-18

### Shipped
- **Tasks 5 & 6 complete: Screen capture pipeline + Claude API client**

**ScreenCaptureManager** (`Sources/AdiCore/Capture/ScreenCaptureManager.swift`):
- `StreamOutputBridge: NSObject, SCStreamOutput` — receives `CMSampleBuffer` from SCStream on a background DispatchQueue, converts via `CVPixelBuffer → CGContext → CGImage` (32BGRA, premultiplied first), fires `onFrame` callback in a detached `Task`.
- `ScreenCaptureManager` — `@unchecked Sendable` final class (safe: start/stop always called from `@MainActor` SessionManager). `start()` gates on `CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess()`, fetches `SCShareableContent.current`, creates `SCStreamConfiguration` at 1 FPS / half display resolution / 32BGRA, creates `SCContentFilter` (full display, no exclusions), calls `s.startCapture()`. `stop()` calls `stopCapture(completionHandler:)`.
- `#else` stub for non-ScreenCaptureKit platforms (Linux CI) so `swift build` succeeds.

**ClaudeClient** (`Sources/AdiCore/AI/ClaudeClient.swift`):
- `classify(image:taskDescription:successCriteria:)` — vision call to `claude-haiku-4-5-20251001`, system prompt instructs strict JSON response `{"status":"onTask"|"offTask"|"ambiguous","confidence":N,"reason":"..."}`. Returns `OnTaskClassification`.
- `verify(image:taskDescription:successCriteria:)` — vision call to `claude-sonnet-4-6`, strict verification with instructions to look for confirmation pages, submission receipts, timestamps. Returns `VerificationResult`.
- `chat(messages:systemPrompt:)` — text-only call to `claude-haiku-4-5-20251001` for conversation flows (reasoning, early exit).
- Image encoding: `NSImage → tiffRepresentation → NSBitmapImageRep → JPEG @ 0.72 quality → base64`. Wrapped in `#if canImport(AppKit)`.
- `post(key:body:)` — URLSession async/await, sets `x-api-key`, `anthropic-version: 2023-06-01`, `content-type: application/json`. Parses `content[0].text` from response.
- Response parsers strip markdown fences, fall back gracefully on bad JSON.
- `ClaudeError` replaces old stub error cases with: `.missingAPIKey`, `.httpError(Int, String)`, `.decodingError(String)`.

**SessionManager** (`Sources/AdiCore/SessionManager.swift`):
- Added `captureManager.onFrame = { [weak self] frame in await self?.handleFrame(frame) }` in `start()` to wire the capture pipeline into the on-task detector.

**Tests** (`Tests/AdiTests/ClaudeClientTests.swift`):
- 8 unit tests covering `parseClassification` (onTask, offTask, ambiguous fallback, markdown stripping) and `parseVerification` (verified=true, verified=false, bad JSON fallback, markdown stripping).

### Blocked
- None.

### Next agent should pick up
- **Task 7: On-task detection** — `OnTaskDetector` in `Sources/AdiCore/AI/OnTaskDetector.swift` is already wired: it calls `client.classify(image:taskDescription:successCriteria:)` and returns the `OnTaskStatus`. The implementation is complete. Verify there are no remaining stubs and that `OnTaskDetector` handles rate-limiting (don't send frames more than once per second even if capture delivers faster). Add a `lastEvaluatedAt: Date?` guard.
- **Task 8: Callout system** — `NotchState` needs an `isShowingCallout: Bool` flag. When `SessionManager.onTaskStatus` changes to `.offTask`, the notch should auto-expand and show a callout overlay with a friend-like direct message (e.g. "yo, what are you doing?"). Use a small pool of callout strings. Wire `SessionManager.$onTaskStatus` into `NotchWindowController` via Combine, call `state.expand()` on offTask.

---

## Run 3 — 2026-05-18

### Shipped
- **Task 4 complete: Session creation view**
- `NotchState.swift` — added `@Published isCreating: Bool`, `startCreating()`, `stopCreating()`. `collapse()` now also resets `isCreating`. Guard in `startCreating()` prevents double-firing `CombineLatest` when already expanded.
- `NotchWindowController.swift` — `observeState()` now uses `Publishers.CombineLatest($isExpanded, $isCreating)` so the panel resizes correctly when the form opens. Added `creationExpandedHeight = 268`. `positionPanel` and `targetFrame` accept `creating: Bool` parameter and select the appropriate height.
- `SessionManager.swift` — `hosts.block()` is now non-fatal (do-catch with log); session starts even without root. The blocking engine task (task 9) will add the privileged XPC helper.
- `NotchView.swift` — `idleBody` is now `@ViewBuilder private var idleBody: some View` with if/else on `state.isCreating`:
  - Idle (default): "No active session" + "Start Session" button that calls `state.startCreating()` with spring animation.
  - Creating: `SessionCreationFormView` with slide-up insertion transition.
- New `SessionCreationFormView` (private struct in `NotchView.swift`):
  - "WORKING ON" field — `TextField(axis: .vertical)` limited to 2 lines, dark background, white text, placeholder overlay.
  - "DONE WHEN" field — single-line `TextField`, same styling.
  - "Go" button — calls `SessionManager.start(task:successCriteria:)` via `Task { @MainActor in }`, then `state.stopCreating()`. Visually dimmed + non-interactive while `taskText` is empty or starting is in progress.
  - "Cancel" link — calls `state.stopCreating()` with fade animation.
  - `isStarting` local state prevents double-taps and shows "Starting…" label while async call is in flight.

### Blocked
- None.

### Next agent should pick up
- **Task 5: Screen capture pipeline** — Implement `ScreenCaptureManager` in `Sources/AdiCore/Capture/ScreenCaptureManager.swift`. Use `ScreenCaptureKit` (`SCShareableContent`, `SCStreamConfiguration`, `SCStream`, `SCStreamOutput` delegate). Set up a stream for the main display at ~1 FPS. Emit `CGImage` frames via `onFrame: (@Sendable (CGImage) async -> Void)?`. Start/stop wired to `SessionManager`. Requires Screen Recording permission — request it on start. Must compile even when `ScreenCaptureKit` is unavailable via the existing `#if canImport` guard.

---

## Run 1 — 2026-05-18

### Shipped
- **Task 1 complete: Xcode project scaffold**
- `Package.swift` — Swift 6 tools version, macOS 14+, three targets: `AdiApp` (executable), `AdiCore` (library), `AdiTests` (test)
- Full folder structure: `Sources/AdiApp/`, `Sources/AdiCore/{Models,AI,Blocking,Capture}/`, `Tests/AdiTests/`
- `AdiApp/AdiApp.swift` — `@main App` entry point, no dock icon via `.accessory` policy
- `AdiApp/AppDelegate.swift` — `NSApplicationDelegate` on `@MainActor`
- `AdiCore/Models/SessionState.swift` — `Session`, `SessionPhase`, `OnTaskStatus`, `VerificationResult` (all `Codable`, `Sendable`)
- `AdiCore/Models/ChatMessage.swift` — `ChatMessage` with role enum
- `AdiCore/AI/ClaudeClient.swift` — actor skeleton; reads `ANTHROPIC_API_KEY` from `ProcessInfo`
- `AdiCore/AI/OnTaskDetector.swift` — actor skeleton wired to `ClaudeClient`
- `AdiCore/Blocking/HostsFileManager.swift` — full parsing/stripping logic for `/etc/hosts` markers; write path needs root
- `AdiCore/Capture/ScreenCaptureManager.swift` — placeholder for `SCStream` wrapper
- `AdiCore/NotchWindowController.swift` — placeholder `NSWindowController`
- `AdiCore/SessionManager.swift` — `@MainActor ObservableObject` session lifecycle coordinator
- `Tests/AdiTests/SessionStateTests.swift` — Swift Testing `@Suite` covering `Session`, `ChatMessage`, `VerificationResult` Codable round-trips
- `Tests/AdiTests/HostsFileManagerTests.swift` — pure logic tests (no I/O) for blocked domain list

### Blocked
- None.

### Next agent should pick up
- **Task 2: Notch UI** — see Run 2.

---

## Run 2 — 2026-05-18

### Shipped
- **Task 2 complete: Notch UI**
- **Task 3 checked off: Session model** — was fully implemented in Run 1; checkbox was missed.
- `AdiCore/NotchState.swift` — `@MainActor ObservableObject` (`NotchState`) with `isExpanded`, `expand()`, `collapse()`, `toggle()`. Observed by controller via Combine; observed by SwiftUI views via `@ObservedObject`.
- `AdiCore/NotchWindowController.swift` — full rewrite. Private `NotchPanel: NSPanel` (borderless, `nonactivatingPanel`, `statusBar+1` level, `canJoinAllSpaces`, clear background, no shadow in collapsed state). `NotchWindowController` positions the panel using `NSScreen.main?.auxiliaryTopLeftArea/Right` + `safeAreaInsets.top` on notch-equipped displays; falls back to top-center 200×32 pill on non-notch Macs. Animates expand/collapse (0.28s ease-in-out) via `NSAnimationContext`. Subscribes to `NotchState.$isExpanded` via Combine and resizes the panel on changes.
- `AdiCore/NotchView.swift` — full SwiftUI hierarchy:
  - `NotchRootView` — root, switches between collapsed/expanded with spring animation
  - `CollapsedView` — dark capsule pill with colored status dot (green/orange/red) + "Focus" label; expand on tap or hover
  - `ExpandedView` — dark card dropping from notch: header (ADIA label + close ×), task name (2-line), live elapsed timer via `TimelineView(.periodic)`, `StatusBadge` (on-task/off-task/check-in capsule), action buttons (Done, Chat, Exit), idle state (no session)
  - `StatusBadge` — colored dot + label capsule
  - `AdiButton` — primary (white bg/black text), secondary (ghost), destructive (red tint)

### Architecture notes
- Panel geometry: collapsed rect = notch slot (or 200×32 fallback). Expanded rect grows downward from `base.maxY` to a fixed 190pt height, 340pt wide (centered on screen).
- SwiftUI singletons (`NotchState.shared`, `SessionManager.shared`) are injected at the `@MainActor` controller init site rather than accessed as defaults in struct inits — avoids Swift 6 actor-isolation compile errors.
- Force cast `window as! NotchPanel` is safe and commented — the controller creates the panel in its own `init()`.

### Blocked
- None.

### Next agent should pick up
- **Task 4: Session creation view** — SwiftUI form (task description + success criteria text fields, Go button). On tap: calls `SessionManager.shared.start(task:successCriteria:)`. Should appear inside the expanded notch view when no session is active (the idle state's "Start Session" button already exists; wire it to a sheet or inline form). The expanded idle body already has a "Start Session" button stub at `NotchView.swift:ExpandedView.idleBody`.
