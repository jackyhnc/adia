# Adia — Build Progress

## Run 81 — 2026-06-07

### Shipped
- **fix: unblock failing CI** — found the `main` branch had been red since at least
  Run 80's push (CI run 128, head `8aeebd2`): both `swift-test` and `pipeline-smoke`
  jobs were failing. Note: this session's repo started in a detached-HEAD state at
  `8aeebd2` while local `main` pointed at the much older `9819c9b` (run 51) — re-fetched
  origin and reset `main` to track `origin/main` before starting.
  - **`swift-test` (compile error)** — `Tests/AdiTests/SessionManagerTests.swift:468`
    `resetTimerForTestingCancelsRearmTask` had three back-to-back
    `await MainActor.run { ... }` closures (two `Void`-returning, one `Bool`-returning).
    That shape trips a Swift Testing `@Test` macro-expansion bug: the compiler emits
    `error: generic parameter 'T' could not be inferred` pointing at the function's
    closing brace, inside the synthesized `__requiringTry`/`__requiringAwait` calls —
    not at the actual offending line. Fix: merged the two `Void`-returning
    `MainActor.run` blocks (`handleDurationExpired()` + `_resetTimerForTesting()`) into
    one closure, dropping back to two consecutive `MainActor.run` calls — the same
    shape as the adjacent (passing) `handleDurationExpiredSchedulesRearmTask` and
    `endSessionCancelsRearmTask` tests. Behaviorally identical (both still run on
    `MainActor`, in order).
  - **`pipeline-smoke` (signing error)** — `scripts/test-pipeline.sh` calls
    `scripts/sign.sh`, which `exit 1`s unless either `DEVELOPER_ID_APPLICATION` (gated
    on the Apple Developer account — see `USER_TODO.md`) or `ADIA_ALLOW_UNSIGNED_RELEASE=1`
    is set. The smoke test only verifies pipeline *mechanics* (build → sign → notarize
    skip → dmg → checksum → verify), not a shippable artifact, so it should always be
    able to ad-hoc sign. Added `export ADIA_ALLOW_UNSIGNED_RELEASE="${ADIA_ALLOW_UNSIGNED_RELEASE:-1}"`
    near the top of the script (defaulted, so a real release run can still override it).

### Verification
- **No Swift toolchain in this container** (Linux, no `swift`/`swiftc` on PATH) — could
  not run `swift build`/`swift test` locally. Verified brace/paren balance on the
  changed Swift file (`111`/`111`, `256`/`256`) and `bash -n` on the shell script.
  Pushed to `main`; CI (`macos-15` runners) will confirm both jobs go green on the
  next run.

### Blocked
- None.

### Next agent
- **Confirm CI is green** on the `main` branch after this push (run after `c20f9cc`).
  If `swift-test` still fails with the same macro-expansion error elsewhere, the
  pattern to search for is "3+ consecutive `await MainActor.run { }` closures inside
  one `@Test func`" — merge same-return-type-adjacent ones together.
- All 14 GOAL.md items remain complete (per `BUILD_COMPLETE`). Focus areas: integration
  smoke testing on a real macOS machine with a notch, or any new features the user
  requests.

---

## Run 80 — 2026-06-07

### Shipped
- **feat: surface reasoning-conversation stats in session history** — Run 79 added
  `Session.reasoningHistory: [ReasoningAttempt]` (the AI's memory of site-access asks
  within a session) but nothing displayed it after the session ended. This run wires
  it through to `SessionRecord` and every place `calloutCount`/`focusScore` are shown,
  per Run 79's "Next agent" suggestion (b).
  - **`SessionRecord`** (`Sources/AdiCore/Models/SessionRecord.swift`) — two new stored
    `Int` fields, `reasoningAttempts` and `reasoningGranted`, following the exact
    `onTaskChecks`/`totalChecks` pattern: default `0` in the initializer, `CodingKeys`
    entry, `decodeIfPresent ... ?? 0` for legacy-record safety, and explicit `encode`.
  - **`SessionManager.endSession()`** (`Sources/AdiCore/SessionManager.swift:122-123`)
    — populates the new fields from `s.reasoningHistory.count` and
    `s.reasoningHistory.filter(\.granted).count` at record-creation time.
  - **`NotchView.swift`** completion-card stats row — appends
    `"asked N×, M granted"` (with a `bubble.left.and.text.bubble.right.fill` icon)
    when `reasoningHistory` is non-empty, mirroring the existing callout/focus-score
    `Label`s.
  - **`SettingsView.swift`** — four spots mirrored: `selectableRowStats` (compact
    `"asked N×"` suffix), the collapsed history row `Label`, the expanded detail panel
    (`detailField("Site access asks", "N asked, M granted")`), and the CSV export
    (two new columns, `Site Access Asks,Site Access Granted`).
  - **Tests** (+9): `SessionHistoryTests` gained `reasoningStatsRoundTripThroughJSON`
    and `legacyJSONWithoutReasoningStatsDecodesWithZero` (mirroring the
    `focusScoreRoundTripsThroughJSON`/legacy pair). `SessionManagerTests` gained
    `endSessionCapturesReasoningHistoryCounts` (3 attempts, 1 granted → record reflects
    both) and `endSessionWithNoReasoningHistoryRecordsZeros`. `SettingsStoreTests`
    gained `selectableRowStatsAppendsReasoningAttemptsWhenNonZero`,
    `selectableRowStatsOmitsReasoningAttemptsWhenZero`, and
    `selectableRowStatsCombinesAllStats` (verifies ordering: duration → callouts →
    focus score → reasoning asks), plus extended the `makeRecord` helper with a
    `reasoningAttempts` parameter.

### Branch hygiene
- Local `HEAD` was detached at `244286a` again on session start (same recurring issue
  Run 79 flagged as item (c)). `git fetch origin main` confirmed `origin/main` was
  already at `244286a` (45 commits ahead of the stale local `main` ref at `9819c9b`).
  `git checkout main && git merge --ff-only 244286a` fast-forwarded cleanly — no lost
  work, just a stale local branch pointer.

### Blocked
- **No Swift toolchain in this container** (Linux, no `swift`/`swiftc` on PATH) —
  could not run `swift build`/`swift test` locally. Verified brace/paren balance
  across all 7 touched files (delta is 0/0 each — e.g. `SessionRecord.swift` 9/9
  braces, 37/37 parens) and that every new symbol follows an existing,
  proven-to-compile sibling pattern (`onTaskChecks`/`totalChecks`/`focusScore` for
  the model+Codable bits, `calloutCount`/`focusScore` `Label`s for the UI bits).
  CI (`macos-15` runner) will build and test on push.

### Next agent
- All 14 GOAL.md items remain checked off; `BUILD_COMPLETE` still accurate. Possible
  next improvements:
  - (a) Carried from Run 79: a broader "house style" memory signal across *different*
    domains (e.g. "asked for access to 3 different sites and been denied each time")
    — needs careful prompt-tuning so it doesn't make the AI suspicious of legitimate
    first-time asks.
  - (b) Carried from Run 78: `AgentAIClient` DI seam refactor for deterministic tests
    (still unstarted — moderately large, scope carefully).
  - (c) Branch hygiene keeps recurring (3rd+ time) — if it happens again, consider
    whether the session-start hook should `git checkout main` proactively.
  - (d) The History stats surfaces are getting crowded (duration, callouts, focus
    score, reasoning asks). If more stats get added later, consider a compact
    "session stats" popover instead of an ever-growing `HStack`/CSV column list.

---

## Run 79 — 2026-06-07

### Shipped
- **feat: reasoning-conversation memory across attempts within a session**
  - The PRD explicitly calls for the access-reasoning AI to "carry context across
    attempts within a session," and GOAL.md item 13 says the same — but
    `ConversationManager.start(mode:)` unconditionally reset `messages = []`, so a
    user who got denied access to a domain and came back ten minutes later with the
    same (or a slightly different) excuse got a completely fresh conversation. The AI
    had no way to know it had already heard — and rejected — that argument.
  - **`ReasoningAttempt`** (`Sources/AdiCore/Models/SessionState.swift`) — new
    `Codable, Sendable` struct: `timestamp`, `domain`, `granted: Bool`, `summary: String`
    (a truncated capture of the AI's final reasoning). Added `Session.reasoningHistory:
    [ReasoningAttempt]` with the same graceful-decode-missing-key pattern as
    `verificationHistory`/`targetDuration` (old persisted sessions decode to `[]`).
  - **`SessionManager.recordReasoningAttempt(domain:granted:summary:)`** — mirrors
    `whitelist(domain:)`: trims/validates the domain, no-ops without an active session,
    appends to `reasoningHistory`, persists. Synchronous (`@MainActor`, no I/O beyond
    `persistence.save`).
  - **`ConversationManager`**:
    - `recordOutcome(domain:granted:)` — calls `summarize(messages:)` (the last
      assistant message, decision tags stripped, truncated to 160 chars with an
      ellipsis) and forwards to `SessionManager.shared.recordReasoningAttempt`. Wired
      into all three decision paths: `grantAccess` (manual chip), `denyAccess` (manual
      chip, only when `mode` is `.reasoning`), and `parseAccessDecision(from:)` (AI
      decides in-band via `[ACCESS GRANTED]`/`[ACCESS DENIED]`).
    - `memoryFragment(for:history:)` — pure static helper that filters
      `reasoningHistory` to the domain being asked about (case-insensitive), and
      renders a numbered "Earlier this session, the user already asked about X
      N times: 1. DENIED — <reason> …" block instructing the AI to "call out repeat
      asks, and don't let them re-litigate a denial with the same weak reason."
      Returns `""` when there's no relevant history — the common first-ask case stays
      byte-identical to the old prompt.
    - `systemPrompt(for:)` now appends `memoryFragment(...)` to the `.reasoning` system
      prompt, reading `session?.reasoningHistory` fresh on every `send()` so
      newly-recorded attempts are visible on the very next message — including a second
      ask about the *same* domain within the *same* conversation (e.g. user gets denied,
      argues a new angle — the system prompt for that follow-up message already includes
      the just-recorded denial).
  - **Tests** (+19): `ConversationManagerTests` gained `summarize*` (5: tag-stripping,
    truncation, last-assistant-only, empty, user-only) and `memoryFragment*` (7: empty
    history, unrelated domain, blank domain, verdict+reason rendering, case-insensitive
    domain match, multi-attempt counting, missing-summary fallback). `SessionManagerTests`
    gained `recordReasoningAttempt*` (4: appends, accumulates, ignores blank domain,
    no-ops without a session). `SessionStateTests` gained `reasoningHistory*` (3: empty
    default, Codable round-trip, legacy-decode-as-empty).

### Housekeeping
- **Branch hygiene**: found local `HEAD` detached again at `5580e0e` (45 commits ahead
  of the locally-cached `main` at `9819c9b`). `git fetch origin main` showed
  `origin/main` was already at `5580e0e` (Run 78's push succeeded; only the local ref
  was stale). `git checkout main && git merge --ff-only 5580e0e` fast-forwarded
  cleanly. This is the third time — see Run 78's note (c); the cause looks like the
  container restoring a detached checkout rather than a branch on session start.

### Blocked
- Nothing. **No Swift toolchain in this container** (Linux, no `swift`/`swiftc` on
  PATH) — could not run `swift build`/`swift test` locally. Verified brace/paren
  balance across all 6 touched files (delta is 0/0 each), and that every new symbol
  (`ReasoningAttempt`, `recordReasoningAttempt`, `recordOutcome`, `summarize`,
  `memoryFragment`) follows an existing, proven-to-compile sibling pattern
  (`VerificationAttempt`/`whitelist`/`parseAccessDecision`). CI (`macos-15` runner)
  will build and test on push.

### Next agent
- All 14 GOAL.md items remain checked off; `BUILD_COMPLETE` still accurate. This run's
  feature closes a real gap between the PRD/GOAL.md text ("context memory") and the
  prior implementation (full reset on every `start`). Possible next improvements:
  - (a) `memoryFragment` currently only fires for the *exact* domain being asked about.
    A broader "house style" memory (e.g. "the user has asked for access to 3 different
    sites and been denied each time — they may be testing your limits") could be a
    nice escalation signal, but would need careful prompt-tuning to avoid making the AI
    overly suspicious of legitimate first-time asks for unrelated sites.
  - (b) Consider surfacing `reasoningHistory` in the session completion card / History
    view (mirroring how `calloutCount` and `focusScore` are shown) — could be a useful
    "you asked for access N times, were granted M" stat for self-reflection.
  - (c) Branch hygiene — keep checking `HEAD` vs `main` at the start of each run; this
    is the third recovery. If it keeps recurring, consider whether the session-start
    hook should `git checkout main` proactively before any work begins.
  - (d) Carried from Run 78: `AgentAIClient` DI seam refactor for deterministic tests
    (still unstarted — moderately large, scope carefully).

---

## Run 78 — 2026-06-07

### Shipped
- **fix: race condition in `SessionManager.verifyAndEnd()` could act on a stale session**
  - `verifyAndEnd()` captures `session` into a local `s`, then `await`s a multi-second
    network call to `AgentAIClient.shared.verify(...)` and (on a verified result) an
    additional 5s `Task.sleep`. Nothing prevented the user from tapping "End Session"
    directly during that window — `endSession()` runs to completion (clears `session`,
    resets `sessionEndedSuccessfully`, persists a `SessionRecord` reflecting the manual
    exit, tears down all subsystems). When the in-flight `verify()` later resolved with
    `verified == true`, the old code would still: set `sessionEndedSuccessfully = true`
    (a stale flag now mutating freshly-cleared/new-session state), fire a "session
    complete" notification + success haptic for a session the user had already manually
    ended, and leave `sessionEndedSuccessfully` dangling `true` — capable of tainting
    the *next* session's `SessionRecord.completedSuccessfully` if that next session
    ended before the flag was otherwise reset.
  - **Fix**: `verifyAndEnd()` now snapshots `let sessionID = s.id` before the first
    `await`, and re-checks `session?.id == sessionID` (a) immediately after `verify()`
    resolves — discarding the result entirely (logged as `verification.discarded_stale`)
    if the session was ended/replaced — and (b) again after the 5s post-success sleep,
    before calling `endSession()`. This makes the whole verification flow a no-op once
    the session it was verifying no longer exists, regardless of how `verify()` resolves.
  - **Test** (`Tests/AdiTests/SessionManagerTests.swift`):
    `verifyAndEndDiscardsStaleResultAfterManualEndSession` — injects a session, sets a
    dummy `lastFrame`, kicks off `verifyAndEnd()` as a background task, races it with a
    direct `endSession(note:)` ~300ms later (mirroring a user tapping "End Session"
    mid-verification), then awaits the verification task to fully resolve and asserts
    `_lastEndedRecord` still reflects the manual end (same `id`, same `note`) — i.e. the
    stale result did not create/overwrite a second record. This test makes a real network
    call to `claude-sonnet-4-6` (no DI seam exists for `AgentAIClient` without a larger
    refactor), so — like `ClaudeAPIIntegrationTests` — it's gated behind
    `.enabled(if: sessionManagerHasAnthropicKey)` and skips automatically when
    `ANTHROPIC_API_KEY` isn't set.

### Housekeeping
- **Branch hygiene**: found local `HEAD` detached again at `63f4b82` (44 commits ahead
  of the locally-cached `main`/`origin/main` at `9819c9b`). Fetched `origin/main`
  (which already had all 44 commits — pushes during prior runs succeeded, only the
  local ref was stale), confirmed `git checkout main && git merge --ff-only origin/main`
  fast-forwarded cleanly with zero conflicts, and verified `git status` now shows
  "On branch main … up to date with 'origin/main'". Future commits will land on `main`.

### Blocked
- Nothing. All 14 GOAL.md items remain checked off; `BUILD_COMPLETE` still accurate.
- **No Swift toolchain in this container** (Linux, no `swift`/`swiftc` on PATH) — could
  not run `swift build`/`swift test` locally. Verified brace/paren balance on both
  touched files; the fix is a small, mechanical guard-clause addition mirroring the
  existing `if session != nil { await endSession() }` check it replaces, and the new
  test follows the exact `ClaudeAPIIntegrationTests` gating pattern already proven to
  compile in CI. CI (`macos-15` runner) will build and test on push.

### Next agent
- All goals complete. Possible next improvements (carried over from Run 77, still open):
  - (a) `AppMonitor.reHideIntervalMilliseconds` (200ms) / `hiddenNotificationMinInterval`
    (3s) remain hardcoded constants — Run 77 judged exposing them as `SettingsStore`
    preferences to be UI clutter for low-value technical knobs; still seems right to leave
    as-is unless a concrete user complaint surfaces.
  - (b) Onboarding Screen Recording permission UX — Run 70 concluded the `.app` bundle
    IS the correct Finder drag target; worth a final runtime check on a real Mac.
  - (c) **Branch hygiene**: keep running `git status` / checking `HEAD` vs `main` at the
    start of each run — this is the second time `HEAD` has drifted detached. If it's
    detached again next run, repeat the `git checkout main && git merge --ff-only
    origin/main` recovery (safe: it only fast-forwards, never rewrites history).
  - (d) Consider whether `AgentAIClient` is worth refactoring behind a protocol/DI seam
    — several integration tests (this run's included) are gated on a real network call
    purely because there's no way to inject a fake response. A `VerifyingClient` protocol
    with `AgentAIClient: VerifyingClient` and a test double would let races, error paths,
    and parsing be tested deterministically without `ANTHROPIC_API_KEY`. This would be a
    moderately large refactor (touches `OnTaskDetector`, `SessionManager`,
    `ConversationManager`, and several test files) — worth scoping carefully before
    starting.

---

## Run 77 — 2026-06-07

### Shipped
- **chore: comment every force-unwrap per the "no force unwraps unless commented" quality bar**
  - Audited the codebase for `!` force-unwraps (`as!`, `try!`, `.first!`, `URL(string:)!`)
    and found 11 across 10 files that lacked an inline justification comment, despite
    each being provably safe:
    - `FocusBlockerWindowController.blockerPanel` / `NotchWindowController.notchPanel`
      — `window as! NSPanel` / `as! NotchPanel`: safe because each controller's `init()`
      always constructs `window` as that exact subclass before `super.init(window:)`.
    - `SessionTemplate.init()` / `SessionHistory.init()` — `.first!` on
      `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)`:
      safe because `.userDomainMask` always resolves to exactly one directory on macOS.
    - `SessionManager.openScreenRecordingSettings()`, `OnboardingView` (System Settings
      deep link + Anthropic console link), `AgentAIClient.baseURL`,
      `LicenseManager.serverBaseURL`, `SettingsView` (×2 pricing links),
      `PaywallView` (×2 checkout links) — all `URL(string: "<constant>")!`: safe because
      every string is a constant, well-formed URL literal with no user input or
      percent-encoding concerns, so `URL(string:)` cannot return `nil`.
  - No behavior changes — purely additive doc comments explaining *why* each unwrap
    can never crash, satisfying the "type-safe Swift — no force unwraps unless
    commented why" quality bar called out in the build brief. Every unwrap in
    `Sources/` now carries a one-to-three-line comment explaining the invariant that
    makes it safe.

### Blocked
- Nothing. All 14 GOAL.md items remain checked off; `BUILD_COMPLETE` still accurate.
- **No Swift toolchain in this container** (Linux, no `swift`/`swiftc` on PATH) — could
  not run `swift build`/`swift test` locally. Changes are comment-only (zero code/logic
  changes); verified brace/paren balance stayed identical across all 10 touched files
  before and after editing. CI (`macos-15` runner) will build and test on push.

### Next agent
- All goals complete; codebase is in good shape. Possible next improvements (carried
  over from Run 76, still open):
  - (a) Consider exposing `AppMonitor.reHideIntervalMilliseconds` (200ms) and
    `AppMonitor.hiddenNotificationMinInterval` (3s) as `SettingsStore` preferences,
    mirroring the `timerExpiredRearmMinutes` treatment from Run 76 — though these are
    lower-stakes/more technical than user-facing reminder cadence, so weigh whether
    they're worth the Settings UI clutter vs. just leaving them as tuned constants.
  - (b) Onboarding Screen Recording permission UX: `requestPermission()` reveals
    `Bundle.main.bundleURL` — Run 70 concluded the `.app` bundle IS the correct Finder
    drag target for Privacy settings, so likely no change needed; worth a final
    runtime check on a real Mac.
  - (c) Branch hygiene: continue running `git status` / `git rev-parse --abbrev-ref HEAD`
    at the start of each run (per Run 76's recovery note) — `main` is correctly attached
    now, just keep verifying it stays that way.

---
## Run 76 — 2026-06-07

### Shipped
- **feat: make timer-expiry re-arm interval user-configurable**
  - Implements follow-up (a) from Run 75's notes: `SessionManager.timerExpiredRearmInterval`
    was hardcoded at 600s (10 min) — now user-tunable from Settings.
  - `SettingsStore.timerExpiredRearmMinutes: Int` — new `@Published` preference,
    persisted to `UserDefaults` under `adia.timerExpiredRearmMinutes`. Loaded in
    `init()` and clamped to `Self.timerExpiredRearmMinuteOptions` (falls back to 10
    if the stored value is missing or corrupted/out-of-range — guards against a
    stray `0` silently disabling the reminder loop).
  - `SettingsStore.timerExpiredRearmMinuteOptions: [Int] = [5, 10, 15, 30]` — new
    `public static let`, drives the Settings picker.
  - `SettingsStore.timerExpiredRearmInterval: TimeInterval` — new computed property,
    `timerExpiredRearmMinutes * 60`. This is what `SessionManager` now reads.
  - `SessionManager.handleDurationExpired()` — the re-arm loop now reads
    `SettingsStore.shared.timerExpiredRearmInterval` fresh on each iteration (instead
    of the old `Self.timerExpiredRearmInterval` constant), so a mid-session preference
    change takes effect on the very next re-arm without restarting the session.
    `SessionManager.timerExpiredRearmInterval` stays as a documented default-value
    constant (existing test `timerExpiredRearmIntervalIs600` still guards it).
  - **Settings UI**: new "Reminders" section in `AccountSettingsTab` with a
    `Picker("Remind me every", …)` bound to `settings.timerExpiredRearmMinutes`,
    offering 5/10/15/30 min, with a footer explaining the re-arm behavior.
  - **Tests (+6)** in `SettingsStoreTests`: `timerExpiredRearmMinuteOptionsContainsTenMinuteDefault`,
    `timerExpiredRearmMinuteOptionsAreSortedAndPositive`, `timerExpiredRearmMinutesDefaultsToTen`,
    `timerExpiredRearmMinutesPersistsToUserDefaults`, `timerExpiredRearmIntervalConvertsMinutesToSeconds`,
    `timerExpiredRearmIntervalMatchesSessionManagerDefaultAtTenMinutes` (cross-checks the
    new computed property against the existing `SessionManager` constant at the 10-min default).

### Housekeeping
- **Recovered 42 unreferenced commits (Runs 52–73)** — the local `main` ref had drifted
  to Run 51 while the working tree's `HEAD` was detached 42 commits ahead (Runs 52–73
  had been committed without ever updating a branch pointer locally). Verified
  `origin/main` already had all 42 commits (the pushes during those runs succeeded —
  only the local branch ref was stale/detached), confirmed a clean fast-forward
  (`git merge-base --is-ancestor` ⇒ true), and fast-forwarded local `main` to match.
  No data was lost; this just re-attaches the working tree to a branch so future
  commits land on `main` instead of going detached again.

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.
- **No Swift toolchain in this container** (Linux, no `swift`/`swiftc` on PATH) — could
  not run `swift build`/`swift test` locally. Verified brace/paren balance across all
  four touched files and reviewed each diff against the existing `idleTemplatesFollowManualOrder`
  / `showMenuBarItem` preference patterns it mirrors; CI (`macos-15` runner) will build
  and test on push.

### Next agent
- All goals complete. Possible next improvements (carried over / refined):
  - (a) Apply the same "expose as `SettingsStore` preference" treatment to the two
    remaining hardcoded tuning constants from Run 75's notes:
    `AppMonitor.reHideIntervalMilliseconds` (200ms) and
    `AppMonitor.hiddenNotificationMinInterval` (3s). These are lower-stakes/more
    technical than the re-arm interval (which is the one most likely to annoy users
    if wrong), so they were intentionally left for a follow-up run rather than
    bundled into one large diff.
  - (b) Onboarding Screen Recording permission UX: `requestPermission()` reveals
    `Bundle.main.bundleURL` — Run 70 concluded the `.app` bundle IS the correct Finder
    drag target for Privacy settings, so likely no change needed; worth a final
    runtime check on a real Mac.
  - (c) **IMPORTANT — branch hygiene**: always run `git status` / `git rev-parse
    --abbrev-ref HEAD` at the start of a run. If `HEAD` is detached, `git checkout main`
    and fast-forward before starting work, otherwise your commit will silently land
    outside any branch (as happened for Runs 52–73 — recovered in this run, but it's
    fragile: if `origin/main` had been behind, a `git push` from a detached HEAD would
    have failed or required force-pushing).

---

## Run 75 — 2026-06-07

### Shipped
- **fix: rate-limit "closed <app>" notification to prevent banner spam**
  - Implements follow-up (c) from Run 74's notes: rapid Cmd-Tabbing into/out of the
    same blocked app was firing `SessionNotifier.sendBlockedAppHidden()` on every
    `didActivateApplicationNotification`, scheduling a fresh notification request
    each time even though the stable notification ID prevented visual stacking.
  - `AppMonitor.shouldSendHiddenNotification(forBundleID:lastBundleID:lastNotifiedAt:now:minInterval:)`
    — new `static` **pure** decision function: returns `true` immediately for a
    different app than last time, or once `minInterval` has elapsed since the last
    notification for the *same* app. Mirrors `OnTaskDetector`'s rate-limiting guard
    pattern (`lastEvaluatedAt` + `minInterval`), but kept `static` and side-effect-free
    so it's directly testable with controlled `Date` values — no `NSWorkspace`
    activation choreography required in tests.
  - `AppMonitor.lastHiddenNotificationBundleID` / `lastHiddenNotificationAt` —
    new `internal private(set)` state, recorded in `handle()` immediately before
    calling `SessionNotifier.shared.sendBlockedAppHidden`. Reset to `nil` in `stop()`
    alongside `currentTask` so stale guard state never leaks into the next session.
  - `AppMonitor.hiddenNotificationMinInterval: TimeInterval = 3.0` — new `static let`.
    3 seconds absorbs a rapid Cmd-Tab flurry into the same blocked app while staying
    short enough that re-hiding the same app after a real gap still explains itself
    promptly.
  - `handle()` — now gates the `sendBlockedAppHidden` call behind
    `shouldSendHiddenNotification(forBundleID:)` (a private instance wrapper around
    the pure static function using the monitor's own guard state + `Date()`).
  - **Tests (+8)**: `allowsFirstNotificationWithNoPriorState`,
    `allowsImmediateNotificationForDifferentApp`,
    `suppressesRapidRefireForSameAppWithinInterval`,
    `allowsRefireForSameAppAfterIntervalElapses`,
    `allowsRefireExactlyAtIntervalBoundary`, `hiddenNotificationMinIntervalIsPositive`,
    `hiddenNotificationMinIntervalIsReasonable`, `startResetsHiddenNotificationGuardState`.
    All exercise the pure static decision function with controlled `Date` offsets —
    no flakiness from real-time sleeps or `NSWorkspace` notification plumbing.

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.
- **No Swift toolchain in this container** (Linux, no `swift`/`swiftc` on PATH) —
  could not run `swift build`/`swift test` locally. Verified brace/paren balance and
  reviewed the diff carefully against the existing `OnTaskDetector` rate-limiting
  pattern it mirrors; CI (`macos-15` runner) will build and test on push.

### Next agent
- All goals complete. Possible next improvements (carried over / refined):
  - (a) Re-hide interval / re-arm interval / hidden-notification-interval configurability:
    `AppMonitor.reHideIntervalMilliseconds` (200ms), `SessionManager.timerExpiredRearmInterval`
    (600s), and the new `AppMonitor.hiddenNotificationMinInterval` (3s) are all hardcoded.
    Could expose as `SettingsStore` preferences if users want to tune enforcement aggressiveness.
  - (b) Onboarding Screen Recording permission UX: `requestPermission()` reveals
    `Bundle.main.bundleURL` — Run 70 concluded the `.app` bundle IS the correct Finder
    drag target for Privacy settings, so likely no change needed; worth a final runtime
    check on a real Mac.
  - (c) Consider applying the same `static` pure-decision-function refactor to other
    rate-limiting guards (e.g. `OnTaskDetector`'s `minInterval` check) for consistency
    and easier unit testing without actor-isolation friction.

---

## Run 74 — 2026-06-07

### Shipped
- **feat: "closed <app>" explanation banner when a blocked app is force-hidden**
  - Implements follow-up (c) from Run 73's notes: "when a blocked app is force-hidden, the user sees whatever was frontmost before — could show a brief Adia overlay or notification explaining why the app was hidden."
  - `SessionNotifier.sendBlockedAppHidden(appName:task:)` — new method. Posts a system notification titled `"closed <appName>"` with a friend-toned body that names the actual task (`"that's not \"write essay\". get back to it."`) or falls back to a generic line when no task is set. Uses the stable identifier `adia.session.blocked_app_hidden` so rapid re-activations of the same app replace the previous banner instead of stacking up.
  - `SessionNotifier.blockedAppHiddenBody(task:)` — new `static` pure copy-builder, extracted so tests can verify the message text without a real `UNNotificationContent`.
  - `AppMonitor.currentTask: String` — new `internal private(set)` property holding the active session's task description. Set by `start(blockedBundleIDs:task:)` (new `task` parameter, defaults to `""`), cleared by `stop()`.
  - `AppMonitor.handle()` — after force-hiding a blocked app, now calls `SessionNotifier.shared.sendBlockedAppHidden(appName:task:)` so the user understands *why* the app vanished instead of it looking like a crash or glitch. Only fires from the activation-triggered `handle()` path, not the 200ms re-hide poll loop, so it can't spam.
  - `SessionManager.activate()` — updated the `AppMonitor.shared.start(...)` call site to pass `task: s.task`.
  - **Tests (+7)**: `AppMonitorTests`: `startStoresTaskForExplanationBanner`, `startWithoutTaskDefaultsToEmptyString`, `stopClearsCurrentTask`, `restartReplacesStaleTaskFromPriorSession`. `SessionNotifierTests`: `blockedAppHiddenBodyMentionsTaskWhenPresent`, `blockedAppHiddenBodyFallsBackWhenTaskIsEmpty`, `blockedAppHiddenBodyIsNotEmpty`.

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.
- **No Swift toolchain in this container** (Linux, no `swift`/`swiftc` on PATH) — could not run `swift build`/`swift test` locally. Changes were reviewed carefully for type correctness against the existing `SessionNotifier`/`AppMonitor` patterns (mirrors `sendTimerExpired` exactly); CI (`macos-15` runner) will build and test on push.

### Next agent
- All goals complete. Possible next improvements:
  - (a) Re-hide interval / re-arm interval configurability: both `AppMonitor.reHideIntervalMilliseconds` (200ms) and `SessionManager.timerExpiredRearmInterval` (600s) are hardcoded. Could expose as `SettingsStore` preferences.
  - (b) Onboarding Screen Recording permission UX: `requestPermission()` reveals `Bundle.main.bundleURL` — Run 70 concluded the `.app` bundle IS the correct Finder drag target for Privacy settings, so likely no change needed; worth a final runtime check on a real Mac.
  - (c) Rate-limit `sendBlockedAppHidden`: currently it fires on every `didActivateApplicationNotification` for a blocked app. If a user rapidly Cmd-Tabs into/out of a blocked app, the stable notification ID prevents banner pile-up, but each call still schedules a request. Could add a `lastNotifiedBundleID`/timestamp guard mirroring `OnTaskDetector`'s rate-limiting if this proves noisy in practice.

---

## Run 73 — 2026-06-07

### Shipped
- **feat: re-hide loop in AppMonitor — re-hides blocked apps every 200 ms**
  - `AppMonitor.reHideIntervalMilliseconds: Int = 200` — new `static let`. 200 ms is fast enough to close the Command-Tab re-activation window within one human-perceptible frame while keeping CPU cost negligible.
  - `AppMonitor.reHideTask: Task<Void, Never>?` — `internal private(set)`. Created by `startReHideLoop()`, cancelled and nilled in `stop()`.
  - `startReHideLoop()` — private; called from `start()` after the empty-IDs guard. Cancels any prior task then creates a new one that loops: call `reHideIfNeeded()`, sleep 200 ms, repeat until `Task.isCancelled`.
  - `reHideIfNeeded()` — private; checks `NSWorkspace.shared.frontmostApplication`, if its `bundleIdentifier` is in `blockedBundleIDs` and `forceHidesBlockedApps == true`, calls `frontmost.hide()`. `#if canImport(AppKit)` guarded. No-op on Linux CI.
  - `stop()` — added `reHideTask?.cancel(); reHideTask = nil` before clearing `blockedBundleIDs`.
  - **Tests (+5)**: `reHideIntervalIsAtMost200ms` (constant guard), `reHideIntervalIsPositive`, `startWithBlockedAppsStartsReHideTask` (non-nil after start), `stopCancelsReHideTask` (nil after stop), `startWithEmptyBundleIDsDoesNotStartReHideTask` (early-return path leaves task nil).

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) Onboarding Screen Recording permission UX: `requestPermission()` reveals `Bundle.main.bundleURL` — could change to `Bundle.main.executableURL` so Finder reveals the binary inside `Contents/MacOS/`, which is the correct drag target for the Privacy settings list.
  - (b) App-level block page: when a blocked app is force-hidden, the user sees whatever was frontmost before. Could show a brief Adia overlay or notification explaining why the app was hidden.
  - (c) Re-arm interval configurability: `timerExpiredRearmInterval` is currently fixed at 600s. Could expose it as a `SettingsStore` preference ("remind me every: 5m / 10m / 15m").
  - (d) Re-hide interval configurability: `AppMonitor.reHideIntervalMilliseconds` is now 200 ms. Could expose as a debug preference or test helper if users report excessive CPU from the polling loop.

---

## Run 72 — 2026-06-06

### Shipped
- **feat: timer-expiry re-arm — re-opens notch every 10 min until user verifies**
  - `SessionManager.timerExpiredRearmInterval: TimeInterval = 600` — new `internal static let`. 10-minute re-arm interval, guarded by a test so any accidental weakening produces a CI failure.
  - `SessionManager.timerExpiredRearmTask: Task<Void, Never>?` — `internal private(set)`. Started inside `handleDurationExpired()` after the initial banner fires. The task loops: sleeps 10 minutes, then if `timerExpired` is still true and the session is still active, re-expands the notch, re-sends the "Time's up" notification, and replays the Glass chime. Loops until the task is cancelled.
  - `handleDurationExpired()` — cancels any in-flight rearm before creating a new one (idempotent). The `Task { while !Task.isCancelled { ... } }` body runs on `@MainActor` (inherits actor context), so `timerExpired` and `session` accesses are race-free.
  - `endSession()` — adds `timerExpiredRearmTask?.cancel() / = nil` before `timerExpired = false`, so the loop terminates synchronously on the next `isCancelled` check.
  - `_resetTimerForTesting()` — same cancellation/nil treatment so test cleanup is clean.
  - **Tests (+4)**: `timerExpiredRearmIntervalIs600` (constant guard), `handleDurationExpiredSchedulesRearmTask` (task is non-nil after expiry), `endSessionCancelsRearmTask` (task is nil after endSession), `resetTimerForTestingCancelsRearmTask` (task is nil after test reset).

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) App force-hide refinement: `NSRunningApplication.hide()` (Run 71) hides windows but Command-Tab brings the app back. Could add a `NSWorkspace.shared.frontmostApplication` observation loop that re-hides a blocked app within ~200ms of re-activation — more aggressive but closer to "no soft blocks".
  - (b) Onboarding Screen Recording permission UX: `requestPermission()` reveals `Bundle.main.bundleURL` — could change to `Bundle.main.executableURL` so Finder reveals the binary inside `Contents/MacOS/`, which is the correct drag target for the Privacy settings list.
  - (c) App-level block page: when a blocked app is force-hidden, the user sees whatever was frontmost before. Could show a brief Adia overlay or notification explaining why the app was hidden.
  - (d) Re-arm interval configurability: `timerExpiredRearmInterval` is currently fixed at 600s. Could expose it as a `SettingsStore` preference ("remind me every: 5m / 10m / 15m") for users who want more or less aggressive reminders.

---

## Run 71 — 2026-06-06

### Shipped
- **feat: force-hide blocked apps on activation + Glass sound on timer expiry**
  - `AppMonitor.handle()` — after firing the callout, now calls `NSRunningApplication.hide()` on the blocked app immediately. Enforces the "no soft blocks" design principle: the user cannot continue using a blocked app by ignoring or dismissing the callout banner. `#if canImport(AppKit)` guarded. The hide path is gated on `Self.forceHidesBlockedApps` (a `public static let` = `true`) so the behavior is documented as explicit policy and easily tested.
  - `AppMonitor.forceHidesBlockedApps: Bool = true` — new `public static let`. Acts as a machine-readable policy statement and allows a test to assert the constant is `true` (preventing silent weakening of enforcement).
  - `SessionManager.timerExpiredSoundName: String = "Glass"` — new `internal static let`. "Glass" is audibly distinct from the off-task callout sounds (Sosumi tier-1, Basso tier-2, Funk tier-3) so the user can immediately tell "time's up" from "get back to work" without looking at the screen.
  - `SessionManager.handleDurationExpired()` — added `NSSound(named: Self.timerExpiredSoundName)?.play()` inside `#if canImport(AppKit)` guard. Plays on every timer expiry; silently no-ops if the sound file is missing (optional chaining).
  - **Tests (+3)**: `forceHidesBlockedAppsIsTrue` (guards against softening enforcement), `timerExpiredSoundNameIsGlass` (prevents silent rename), `timerExpiredSoundNameIsKnownMacOSSystemSound` (validates against the 14 known macOS system sound names — catches typos that would produce silence).

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) Callout escalation for timerExpired: when the timer banner is dismissed (user collapses notch) without verifying, auto-reopen the notch after e.g. 10 minutes. `handleDurationExpired()` currently fires once; a looping `Task.sleep` + `expand()` would implement the re-arm.
  - (b) App force-hide: `NSRunningApplication.hide()` hides the window but doesn't prevent the user from Command-Tabbing back. Adding `NSWorkspace.shared.runningApplications.first(where: ...).activate(options: [])` after a short delay would keep bringing Adia back to front, but that may be too aggressive. As shipped, force-hide is a good balance.
  - (c) Onboarding Screen Recording permission UX: `requestPermission()` reveals `Bundle.main.bundleURL` — could change to `Bundle.main.executableURL` so Finder reveals the binary inside `Contents/MacOS/`, which is the correct drag target for the Privacy settings list.
  - (d) App-level block page: when a blocked app is force-hidden, the user sees whatever was frontmost before (usually Adia or the desktop). Could show a brief overlay or notification explaining why the app was hidden, similar to the blocked site reasoning page.

---

## Run 70 — 2026-06-06

### Shipped
- **feat: auto-expand notch + timer-expired banner when session duration goal elapses**
  - `SessionManager.timerExpired: Bool` — new `@Published` flag, flips true when the duration countdown reaches zero, reset by `endSession()`.
  - `SessionManager.durationTimerTask: Task<Void, Never>?` — private unstructured task started in `activate()` immediately after `captureManager.start()` succeeds. Sleeps for `max(0, targetDuration - session.elapsed)` so crash-recovered sessions resume with the correct remaining time. Cancelled and nilled in `endSession()` and if `activate()` throws.
  - `SessionManager.handleDurationExpired()` — `internal` (not private) so unit tests can invoke it without sleeping real time. Sets `timerExpired = true`, calls `NotchState.shared.expand()`, and fires `SessionNotifier.shared.sendTimerExpired(task:)`.
  - `SessionNotifier.sendTimerExpired(task:)` — new notification method. Title "Time's up ⏰", body "Open Adia to verify: <task>". ID `adia.session.timer_expired` (stable so a second expiry in the same session replaces the first banner).
  - `TimerExpiredBanner` (new private struct in `NotchView.swift`) — amber background `(0.60, 0.42, 0.0)`, `timer` SF Symbol, "time's up — how'd it go?" heavy text, and a "verify now →" button that calls `verifyAndEnd()`. Uses `.transition(.move(edge: .top).combined(with: .opacity))`.
  - `activeBody` in `NotchView` — shows `TimerExpiredBanner` in the same slot as `CalloutBanner` when `session.timerExpired && state.calloutMessage == nil`. Off-task callout takes visual priority; timer banner shows between sessions. Task text dims and top padding tightens (8pt → same as callout) when banner is visible.
  - `NotchWindowController` — subscribes to `SessionManager.shared.$timerExpired`; `targetFrame` routes to `calloutExpandedHeight (302pt)` when `timerExpired` is true and no callout is showing.
  - **Tests (+5)** in `SessionManagerTests`: `timerExpiredDefaultsToFalse`, `handleDurationExpiredSetsFlag` (flag becomes true), `handleDurationExpiredWithNoSessionIsNoOp` (no session → flag stays false), `handleDurationExpiredExpandsNotch` (notch auto-opens), `endSessionResetsTimerExpiredFlag` (endSession zeroes the flag).

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) Onboarding Screen Recording permission: `requestPermission()` uses `Bundle.main.bundleURL` for Finder reveal — the correct drag target for Screen Recording IS the `.app` bundle, so this is actually correct and can be left alone.
  - (b) App force-hide on blocked app detection: `AppMonitor.handle()` calls out when a blocked app activates but doesn't actually hide it. Adding `NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == bundleID })?.hide()` would enforce "no soft blocks" at the app level.
  - (c) Callout escalation for timerExpired state: when the timer banner is dismissed (user collapses notch), if they don't verify within e.g. 10 minutes, auto-reopen. Currently the banner only fires once.
  - (d) Timer expiry sound: `NSSound(named: "Glass")?.play()` in `handleDurationExpired()` would give a satisfying "done" chime distinct from the off-task Sosumi/Basso/Funk sounds.

---

## Run 69 — 2026-06-06

### Shipped
- **feat: callout count in History multi-select row badge**
  - `selectableRowStats(record:minChecks:)` — updated to produce `"45m · 3⚠ · 80%"` when `calloutCount > 0` and focus score is available. When calloutCount is 0 the badge is unchanged (`"45m · 80%"` or `"45m"`). Uses a `parts` array joined by `" · "` to cleanly assemble duration + optional callout badge + optional focus score. The `⚠` (U+26A0) text character is compact at 11pt monospaced without being emoji-heavy.
  - `makeRecord` test helper in `SettingsStoreTests` — added `calloutCount: Int = 0` parameter (default keeps all existing tests passing).
  - **Tests (+4)**: `selectableRowStatsShowsCalloutCountWhenNonZero` (3 callouts, no score → "45m · 3⚠"), `selectableRowStatsShowsCalloutAndFocusScore` (3 callouts + 80% → "45m · 3⚠ · 80%"), `selectableRowStatsOmitsCalloutWhenZero` (0 callouts + score → "45m · 80%", no ⚠), `selectableRowStatsSingleCalloutIsNotPlural` (1 callout → "30m · 1⚠").

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) Onboarding Screen Recording permission UX: `requestPermission()` reveals `Bundle.main.bundleURL` — could change to `Bundle.main.executableURL` so Finder reveals the binary inside `Contents/MacOS/`, which is more useful for dragging into Privacy settings.
  - (b) `selectableRowStats` separator: the `" · "` (U+00B7 middle dot) is fine at 11pt but at very small sizes may be faint. Could switch to `" / "` or `" - "` if hardware testing shows it fades.
  - (c) Export CSV vs badge parity: CSV already exports `calloutCount` as a column. The selectable row badge now surfaces the same data inline — the two views are in sync.
  - (d) Onboarding: the Screen Recording permission step currently shows `Bundle.main.bundleURL` to `NSWorkspace.shared.activateFileViewerSelecting`. `Bundle.main.executableURL` would reveal the actual binary at `Contents/MacOS/Adia`, which is the drag target for the Privacy settings list.

---

## Run 68 — 2026-06-06

### Shipped
- **feat: duration + focus score badge in History multi-select row**
  - `selectableRowStats(record:minChecks:)` — new `internal` pure function in `SettingsView.swift`. Takes a `SessionRecord` and a `minChecks` threshold; returns a compact stat string: `"<1m"`, `"45m"`, `"1h 30m"`, or `"45m · 80%"` when a valid focus score exists (`totalChecks >= minChecks`). The explicit `minChecks` parameter makes the function directly testable without touching the singleton.
  - `SelectableRecordRow` — adds a trailing `Text(selectableRowStats(...))` view (11pt monospaced, `.tertiary` color) so the History tab's multi-select mode shows per-session stats at a glance. Previously the selectable rows showed only task name, outcome icon, and date; now duration and focus score are visible without expanding the row or leaving select mode.
  - **Tests (+4)** in `SettingsStoreTests`: `selectableRowStatsDurationOnlyWhenNoChecks` (no checks → duration only), `selectableRowStatsAppendsFocusScoreAboveMinChecks` (8/10 on-task, ≥5 checks → "45m · 80%"), `selectableRowStatsHidesFocusScoreBelowMinChecks` (4 checks < 5 threshold → score omitted), `selectableRowStatsFormatsHoursAndMinutes` (90 min → "1h 30m").

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) Onboarding Screen Recording permission UX: `requestPermission()` reveals `Bundle.main.bundleURL` — could change to `Bundle.main.executableURL` so Finder reveals the binary inside `Contents/MacOS/`, which is more useful for dragging into Privacy settings.
  - (b) SettingsView History tab — selectable rows could also show `calloutCount` in the trailing badge (e.g. "45m · 3⚠ · 80%") for even richer bulk comparison, though this may be too crowded at 11pt.
  - (c) `selectableRowStats` format: the "·" separator is a Unicode middle dot (U+00B7). Could switch to "/" or "-" if the font renders it too faintly at small sizes.
  - (d) Export CSV already includes focus score; select-mode row now mirrors that — the two data views are now in sync.

---

## Run 67 — 2026-06-06

### Shipped
- **refactor: extract `minChecksForFocusScore` constant + idle card duration badge**
  - `SessionManager.minChecksForFocusScore: Int = 5` — new `public static let`. The `>= 5` hardcode that guards focus-score display was scattered across 3 sites; all three now reference this single constant so changing the threshold only requires one edit.
  - `NotchView.swift:405` — `session.totalCheckCount >= 5` → `session.totalCheckCount >= SessionManager.minChecksForFocusScore`.
  - `SettingsView.swift` — both `record.totalChecks >= 5` occurrences (row caption + detail panel) updated to `>= SessionManager.minChecksForFocusScore`.
  - **Idle card duration badge**: the "repeat last session" button in `IdleBody` now shows a compact elapsed-time badge on the trailing edge when `record.duration >= 60`. Restructured the label from a single `Label(task, systemImage:)` to an explicit `HStack` with `Image` + `Text` + `Spacer(minLength: 0)` + optional duration badge (`sessionElapsedLabel(seconds:)`, 9pt monospaced). Visual parity with template buttons that already show their `preferredDuration`.
  - **Tests (+3)** in `SessionManagerTests`: `minChecksForFocusScoreIs5` (asserts constant == 5, prevents silent changes), `focusScoreRecordBelowMinChecksThresholdHasNoDisplayableScore` (4 checks → `totalChecks < minChecks`, score non-nil but below display gate), `focusScoreRecordAtMinChecksThresholdIsDisplayable` (exactly 5 checks → `totalChecks >= minChecks`, score displayable).

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) Onboarding Screen Recording permission UX: `requestPermission()` reveals `Bundle.main.bundleURL` — could change to `Bundle.main.executableURL` so Finder reveals the binary inside `Contents/MacOS/`, which is more useful for dragging into Privacy settings.
  - (b) SettingsView History tab: add a "Focus score" column to the bulk list view (multi-select/export view) for at-a-glance comparison across sessions without opening the detail panel.
  - (c) Idle card "last session" link: DONE in this run — duration badge now shows next to the task name.
  - (d) `minChecksForFocusScore` constant: DONE in this run.

---

## Run 66 — 2026-06-06

### Shipped
- **feat: surface last session note in idle notch card**
  - `NotchState.idleHasNote: Bool` — new `@Published internal(set)` flag. Set by `IdleBody.task` alongside `idleTemplateCount` when the idle panel loads its template+record data. Reads `lastRecord?.note != nil`.
  - `IdleBody.idleContent` — the `if let record = lastRecord` block now wraps the repeat-button and an optional note in a `VStack(alignment: .leading, spacing: 3)`. When `record.note != nil`, a `Text(note).font(.system(size: 10).italic())` label appears below the button at 28% white opacity, 2-line max, indented 17pt to align with the label text after the SF Symbol.
  - `NotchWindowController` — new `idleNoteHeight: CGFloat = 28` constant. Idle panel height formula gains `+ (state.idleHasNote ? Self.idleNoteHeight : 0)` so the panel auto-grows when a note row is shown. Added `$idleHasNote` Combine sink in `observeState` so the panel repositions immediately when `IdleBody` sets the flag.
  - **Tests (+3)** in `NotchStateTests`: `idleHasNoteDefaultsToFalse`, `settingIdleHasNoteTrueRaisesFlag`, `collapseDoesNotClearIdleHasNote` (verifies the flag persists across `collapse()` — it reflects DB state, not transient UI state, and is only refreshed when IdleBody reloads).

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) Onboarding Screen Recording permission UX: `requestPermission()` reveals `Bundle.main.bundleURL` — could change to `Bundle.main.executableURL` so Finder reveals the binary inside `Contents/MacOS/`, which is more useful for dragging into Privacy settings.
  - (b) SettingsView History tab: add a "Focus score" column to the bulk list view (multi-select/export view) for at-a-glance comparison across sessions without opening the detail panel.
  - (c) Focus score threshold: `>= 5` total checks required to show is a constant inside `SessionManager`. Could expose it as `internal static let minChecksForFocusScore: Int = 5` so it's easy to tune via tests.
  - (d) Idle card "last session" link: when no note is set, the repeat-button label shows just the task. Could show a compact duration badge (similar to template buttons) if `lastRecord.duration > 0`.

---

## Run 65 — 2026-06-06

### Shipped
- **feat: session note field in completion card**
  - `SessionManager.endSession(note: String? = nil)` — new optional parameter threads the user's annotation directly into `SessionRecord(note:)` at the moment the record is created (instead of requiring a separate `updateNote` call via History tab). Empty/nil note stores `nil`; the existing `updateNote` path in Settings still works for later edits. `_lastEndedRecord: SessionRecord?` test helper captures the most-recently-created record for assertions.
  - `ExpandedView` (NotchView.swift): `@State private var completionNote: String = ""` + `@FocusState private var noteFieldFocused: Bool`. When `result.verified`, a **SESSION NOTE** field appears between the stats row and the End Session button. Dark-themed: `Color.white.opacity(0.06)` background, 11pt white text, placeholder "Add a note…" (22% opacity), focus-sensitive border ring. Pressing Return commits the note and ends the session identically to clicking the button.
  - End Session button updated to pass `completionNote.trimmingCharacters(in: .whitespaces)` as note (nil when blank). `completionNote` is reset to `""` in the button action and via `.onChange(of: state.verificationResult?.verified)` so stale text never leaks between sessions.
  - `NotchWindowController.verifiedCardHeight`: 210 → 265 (adds 55pt for the note label + field).
  - **Tests (+2)** in `SessionManagerTests`: `endSessionDefaultNoteIsNil` (no note arg → `_lastEndedRecord?.note == nil`), `endSessionNoteIsPassedThroughToRecord` (note arg → note stored in record).

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) Onboarding Screen Recording permission UX: `requestPermission()` reveals `Bundle.main.bundleURL` (the .app bundle). Could change to `Bundle.main.executableURL` so Finder reveals the binary inside `Contents/MacOS/` — more useful when users need to drag it into Privacy settings.
  - (b) SettingsView History tab: add a "Focus score" column to the compact session list rows for at-a-glance comparison across sessions without opening the detail panel.
  - (c) Session note in idle card: when the notch is idle and shows the last session's stats, surface the note if one was set — a quick reminder of what the user wrote while the session was fresh.
  - (d) Focus score threshold: `>= 5` total checks required to show is a constant inside `SessionManager`. Could expose it as `internal static let minChecksForFocusScore: Int = 5` so it's easy to adjust via tests.

---

## Run 64 — 2026-06-06

### Shipped
- **feat: focus score tracking — on-task % per session, surfaced in completion card + history**
  - `SessionManager`: `@Published onTaskCheckCount: Int` and `@Published totalCheckCount: Int` — incremented in `handleFrame()` on every AI classification result; `focusScore: Double?` computed property (nil when totalCheckCount == 0). Both counters reset to 0 in `activate()` (new session / restore) and again in `endSession()` (clean state for next session). `_injectCheckCountsForTesting(onTask:total:)` test helper added alongside the existing session-inject helper.
  - `SessionRecord`: new `onTaskChecks: Int` and `totalChecks: Int` fields. Manual `Codable` extension with `decodeIfPresent ?? 0` backward compat so all existing history records decode cleanly. `focusScore: Double?` computed property (nil when `totalChecks == 0`). CSV export gains a "Focus Score (%)" column (empty string for pre-feature records, integer percentage for new ones).
  - `NotchView` — completion stats row: when `session.focusScore != nil && session.totalCheckCount >= 5`, appends `· 87% focused` with an SF Symbol `target` icon next to the elapsed time and callout count. The `>= 5` guard filters out sessions too short to have statistically meaningful sample sizes.
  - `SettingsView` — `SessionRecordRow` summary caption: same `>= 5` guard + `"87% focused"` label after callouts. `SessionRecordRow` detail panel: new `"Focus score"` field shows `"87%"` in the `HStack` alongside Duration and Callouts.
  - **Tests (+10)**: `SessionManagerTests` — `onTaskCheckCountDefaultsToZero`, `totalCheckCountDefaultsToZero`, `focusScoreNilWhenNoChecksEvaluated`, `focusScoreReflectsInjectedCounts`; `SessionHistoryTests` — `focusScoreNilWhenTotalChecksIsZero`, `focusScoreWhenAllOnTask`, `focusScoreWhenPartiallyOnTask`, `focusScoreWhenNoneOnTask`, `focusScoreRoundTripsThroughJSON`, `legacyJSONWithoutCheckCountsDecodesWithZeroAndNilFocusScore`.

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) Onboarding Screen Recording permission: the "reveal in Finder" UX could be improved — change `Bundle.main.bundleURL` to `Bundle.main.executableURL` in `requestPermission()` so Finder reveals the binary inside `Contents/MacOS/` rather than the app bundle, matching macOS's expectations when dragging into Screen Recording privacy list.
  - (b) Focus score threshold tuning — currently `>= 5` total checks required to show. Could expose this as a constant in `SessionManager` so it's easy to adjust via tests.
  - (c) SettingsView History tab: could add a "Focus score" column to the bulk-select/export view for at-a-glance comparison across sessions.
  - (d) Session note field in completion card: currently only editable in the History settings tab. Could add a quick note field on the completion stats card so users can annotate sessions immediately after finishing.

---

## Run 63 — 2026-06-06

### Shipped
- **feat: SettingsView adaptive height per tab**
  - `SettingsView.tabHeights: [Int: CGFloat]` — new `static let` dictionary mapping each of the 4 tab indices to a hand-tuned height: Account (0) → 400pt, Blocking (1) → 560pt, Templates (2) → 460pt, History (3) → 540pt. Reasoning: Account has 3 compact sections and wasted whitespace at 500pt; Blocking has 18 domain toggles + 8 app toggles and benefits from extra viewport; Templates and History are comfortably mid-range.
  - `SettingsView.currentHeight: CGFloat` — computed property reads `tabHeights[selectedTab] ?? 500` (fallback for future tabs).
  - `@AppStorage("settingsSelectedTab") private var selectedTab: Int = 0` — persists the last-used tab across window re-opens so the user lands where they left off.
  - `TabView` now uses `TabView(selection: $selectedTab)` to wire the selection binding.
  - `.animation(.easeOut(duration: 0.18), value: selectedTab)` — softens the window height transition when switching tabs; SwiftUI propagates the new intrinsic size to the `Settings` scene window automatically.
  - **Tests (+4)** in `SettingsStoreTests.swift`: `settingsViewTabHeightsCoversAllFourTabs` (all 4 tags 0–3 have entries), `settingsViewAllTabHeightsArePositive` (no zero/negative heights), `settingsViewBlockingTabIsTallestTab` (tab 1 ≥ all others), `settingsViewAccountTabIsShortestTab` (tab 0 ≤ all others).

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) Onboarding Screen Recording permission: the "reveal in Finder" UX could be improved — on M1/Intel the Adia binary may need to be dragged from within the bundle's `Contents/MacOS` folder. Could improve discoverability with a direct "Reveal binary" button.
  - (b) `HapticPlayer.performSuccess` second-pulse timing — current 50 ms is a constant. Could expose a `secondPulseDelay` in `SettingsStore` for experimentation, but probably overkill.
  - (c) `SleepBlocker` assertion name localisation — "Adia focus session" is hardcoded as a `CFString` literal. Could derive it from `Bundle.main.bundleIdentifier` or `kCFBundleNameKey`.
  - (d) SettingsView width adaptive — currently fixed at 480pt. Could be widened for the History tab to show more session data per row.

---

## Run 62 — 2026-06-06

### Shipped
- **feat: double haptic "tada" at session completion + IOPMCopyAssertionsByProcess integration tests**
  - `HapticPlayer` (new `@MainActor enum` in `SessionManager.swift`): centralises Force Touch feedback. `successPulseDelay: Duration = .milliseconds(50)` is a `nonisolated static let` so tests can access it without a main-actor hop. `performSuccess() async` fires two `.levelChange` pulses 50 ms apart via `NSHapticFeedbackManager.defaultPerformer` — the trackpad registers them as two distinct events, producing a "tada" double-beat instead of the previous single pulse. `#if canImport(AppKit)` guard means the call is a no-op on non-macOS and on Macs without Force Touch hardware.
  - `SessionManager.verifyAndEnd()` — replaced the inline `#if canImport(AppKit) NSHapticFeedbackManager … #endif` block with `await HapticPlayer.performSuccess()`. Cleaner, testable, and the 50 ms await still comfortably precedes the 5-second stats-card display window.
  - **Tests (+2)** in `SessionManagerTests`: `hapticSuccessPulseDelayIs50ms` (asserts the constant is exactly 50 ms — change requires an intentional commit); `hapticPlayerPerformSuccessCompletesWithoutHanging` (awaits the function directly from the test — if it deadlocked the test runner would time out; passing proves the async path terminates cleanly).
  - **`SleepBlockerTests`** — `import IOKit.pwr_mgt` added under `#if canImport(IOKit)`. Two new integration tests that query the real OS assertion table:
    - `startRegistersAssertionWithOS`: calls `SleepBlocker.shared.start()`, then `IOPMCopyAssertionsByProcess`, looks for an assertion named `"Adia focus session"` under the test process's PID. Skips gracefully (early return) when `IOPMCopyAssertionsByProcess` returns non-success (sandboxed CI). Uses `Issue.record` rather than `#expect(false)` so the failure is diagnostic when the PID entry is missing.
    - `stopRemovesAssertionFromOS`: starts then immediately stops, queries again, asserts the assertion is absent — verifying `IOPMAssertionRelease` actually de-registers it from the OS table, not just clearing our internal flag.

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) `SettingsView` window height adaptive — currently fixed at `500`. Could use a per-tab height map driven by `@AppStorage("settingsSelectedTab")` or a `PreferenceKey`.
  - (b) Onboarding permission step: the "reveal in Finder" UX — on M1/Intel the Adia binary may need to be dragged from within the bundle's `Contents/MacOS` folder to grant Screen Recording permission. Could improve discoverability.
  - (c) `HapticPlayer.performSuccess` second-pulse timing — current 50 ms is a constant. Could expose a `secondPulseDelay` in `SettingsStore` for A/B testing on hardware, but probably overkill.
  - (d) `SleepBlocker` assertion name localisation — "Adia focus session" is hardcoded as a CFString literal. Could derive it from `Bundle.main.bundleIdentifier` or `kCFBundleNameKey` so it updates automatically if the app name changes.

---

## Run 61 — 2026-06-06

### Shipped
- **feat: haptic feedback on task completion + fix verified card panel height**
  - `SessionManager.verifyAndEnd()` — fires `NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, ...)` when Claude marks the session verified. Gives a satisfying physical confirmation on MacBooks with Force Touch trackpad at the exact moment of success. `#if canImport(AppKit)` guarded.
  - `NotchWindowController.targetFrame` — new `verifiedCardHeight = 210` constant. When `verificationResult?.verified == true` the panel uses this compact height instead of the shared `verificationHistoryHeight = 350`. Verified cards never show the scrollable previous-attempts section, so 350pt left ~140pt of empty space below the "End Session" button on third-attempt success runs.
  - `NotchWindowController.observeState` — added `$calloutTier` Combine sink. Previous code only subscribed to `$calloutMessage`; if the same message string fired at a higher tier, the panel would not resize from `calloutExpandedHeight` (302) to `tier3CalloutExpandedHeight` (322). Now tier escalation always triggers a reposition even if the message text is identical.
  - **Tests (+2)** in `NotchStateTests`: `verifiedResultSignalsVerifiedFlagRegardlessOfHistoryCount` (3-attempt session ending in verified → `verificationResult.verified==true` even with `history.count==3`, confirming the compact-height branch fires); `notVerifiedWithHistorySignalsHistoryHeight` (2 failed attempts → `verified==false` and `count>1`, confirming the history-height branch fires).

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) `SettingsView` window height adaptive — currently fixed at `500`. Could use a custom tab switcher so each tab reports its natural height.
  - (b) Integration test for `SleepBlocker.start()` — verify assertion is registered with `IOPMCopyAssertionsByProcess`.
  - (c) Onboarding permission step: the "reveal in Finder" UX — on M1/Intel the Adia binary may need to be dragged from within the bundle's Contents/MacOS folder to grant permission. Could improve discoverability.
  - (d) Second haptic "tada" pattern: two rapid `.levelChange` pulses (50ms apart via `Task.sleep`) instead of a single pulse for a more celebratory feel. Would need careful testing on hardware to verify it doesn't feel jarring.
  - (e) `calloutTier` sink newly added — could verify with an integration test that tier-3 fires a `Funk` NSSound (currently only verifiable on hardware).

---

## Run 60 — 2026-06-06

### Shipped
- **feat: session completion card — stats + explicit End Session button**
  - `verificationResultBody` — when `result.verified == true`, the notch now shows a stats row (elapsed time + callout count, e.g. "42m · 3 callouts") plus an explicit **End Session** button instead of auto-dismissing after 1.2 seconds. The stats row reads from the still-active `session.session` while it's alive; once the user clicks End Session (or the 5-second auto-end fires), `endSession()` clears it and the notch collapses.
  - `SessionManager.verifyAndEnd()` — extended auto-end sleep from 1.2 s to 5 s, giving the user time to read their stats. Added `if session != nil` guard before the fallback `endSession()` call so tapping the button first doesn't trigger a redundant second call.
  - `sessionElapsedLabel(seconds:)` — new `internal` helper in `NotchView.swift` that formats a second count as a compact label: `"<1m"`, `"45m"`, `"1h"`, `"1h 30m"`. Follows same convention as `heatmapFormatMinutes`.
  - **Tests (+11)**: `SessionElapsedLabelTests` suite in `SessionHistoryTests.swift` — zero, sub-minute (30s, 59s), negative clamp, exact 1m, 45m, 59m, 1h, 1h 30m, 2h, 2h 2m.

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) `SettingsView` window height adaptive — currently fixed at `500`. Could use a custom tab switcher so each tab reports its natural height.
  - (b) Integration test for `SleepBlocker.start()` — verify assertion is registered with `IOPMCopyAssertionsByProcess`.
  - (c) Onboarding permission step: currently opens System Settings correctly (already uses `x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture`). Could improve the "reveal in Finder" UX — currently reveals the bundle, but on M1/Intel the Adia binary may need to be dragged from within the bundle's Contents/MacOS folder.
  - (d) Session completion card: could add a confetti or haptic burst (`NSHapticFeedbackManager`) on verified=true for celebration.
  - (e) `NotchWindowController` panel sizing: the panel height for the verified card is shared with the non-verified card. If the session had many callouts AND a whitelisted domain hint, the verified card could overflow. Could compute required height for verified vs non-verified states.

---

## Run 59 — 2026-06-06

### Shipped
- **fix: natural phrasing for "studying" and "reading" callout keywords**
  - `CalloutManager.taskAwareCallouts(keyword:tier:)` — added two early-return branches before the generic `switch tier` block, one for `"studying"` and one for `"reading"`.
  - `"studying"` tier 1: "get back to studying." / "you're not studying right now." / "studying won't do itself." — drops the awkward "your studying" possessive.
  - `"studying"` tier 2: "stop putting off studying." / "you need to be studying, not doing this."
  - `"studying"` tier 3: "CLOSE THIS. Start studying." / "your study session is ticking away."
  - `"reading"` tier 1/3 similarly avoid "your reading" as a direct object; tier 2 keeps "stop putting off your reading." which is natural English.
  - **Tests (+2)**: `taskAwareCalloutsStudyingUsesNaturalPhrasing` (all 3 tiers: non-empty, contain "study"/"Study", none contain "your studying"), `taskAwareCalloutsReadingUsesNaturalPhrasing` (all 3 tiers: non-empty, contain "read"/"Read"; tiers 1+3 don't use "your reading" as a verb phrase).

- **feat: custom duration hint in EditTemplateSheet**
  - `EditTemplateSheet` — new `let customDurationHint: String?` property. Computed in `init` by checking whether `template.preferredDuration` (converted to minutes) matches any preset chip (25/45/60/90). Non-matching values are formatted via `heatmapFormatMinutes` (reuses existing helper: "30m", "2h", "1h 15m"). Preset durations → nil (chip pre-selected as before).
  - Duration Goal section footer: when no chip is selected AND `customDurationHint` is non-nil, an amber text line appears above the standard footer: "Saved: 30m — select a preset to keep a time limit, or save as-is to clear it." This closes the UX gap where a template's non-standard duration was silently treated as nil with no visible indication.

- **feat: ⌃⌥A shortcut row in onboarding welcome screen**
  - `OnboardingView.welcome` — added a 4th `featureRow` after "Verifies you're done": `("keyboard.fill", "⌃⌥A from anywhere", "Expand Adia from any app without switching windows.")`. New users now learn about the global hotkey during first launch rather than discovering it by accident or reading Settings.

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) `SettingsView` window height adaptive — currently fixed at `500`. Make height computed from tab content.
  - (b) Integration test for `SleepBlocker.start()` — verify assertion is registered with `IOPMCopyAssertionsByProcess`.
  - (c) `EditTemplateSheet` clear-custom-duration button — currently if user saves without selecting a chip, the non-preset duration is cleared. Could add a "Clear" link next to the orange hint so users can explicitly clear it, and change save path to preserve custom durations when no chip is active and the hint is showing.
  - (d) Callout tone for `"report"` keyword: "get back to your report." is slightly better but "your doc" / "your document" work well. No change needed unless testing shows awkwardness.
  - (e) Onboarding: the permission step (Screen Recording) could link directly to the specific Privacy pane section rather than opening System Settings generally.

---

## Run 58 — 2026-06-06

### Shipped
- **feat: student-centric keyword expansion in `extractTaskKeyword`**
  - Added 7 new trigger words mapped to existing keyword categories:
    - `midterm` / `midterms` / `finals` / `notes` / `flashcard` / `flashcards` / `lecture` → `"studying"`
    - `pset` → `"homework"` (shorthand for "problem set", common in CS/STEM courses)
    - `lab` → `"research"` (chemistry lab, bio lab report, etc.)
  - All new terms use the same `\b` word-boundary regex guard as existing terms, preventing false positives: "elaboration" does not match "lab"; "upset" does not match "pset".
  - `lecture` intentionally maps to `"studying"` (not `"reading"`) since watching/reviewing lecture recordings is a study activity. Note: `"review the lecture slides"` still maps to `"presentation"` because `slides` fires earlier in the chain.
  - **Tests (+9)**: `extractTaskKeywordFromMidterm`, `extractTaskKeywordFromFinals`, `extractTaskKeywordFromNotes`, `extractTaskKeywordFromFlashcards`, `extractTaskKeywordFromPset`, `extractTaskKeywordFromLab`, `extractTaskKeywordFromLecture`, `extractTaskKeywordLabDoesNotMatchElaboration`, `extractTaskKeywordPsetDoesNotMatchUpset`.

- **feat: whitelisted domain hint in "not verified" result card**
  - When task verification returns not-verified, `verificationResultBody` now checks `session.session?.whitelistedDomains.last`. If the user has whitelisted any site during the session (e.g., canvas.edu to submit an essay), a compact hint row appears above the action buttons: `🔗 canvas.edu is whitelisted — go finish there`. Styled at 11pt, 38% white opacity — informative without distracting from the "Try again" / "Keep going" buttons. This closes the UX gap where a user has the right site whitelisted but forgets they can go there to complete the task.

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) `SettingsView` window height adaptive — currently fixed at `500`. Make height computed from tab content.
  - (b) Integration test for `SleepBlocker.start()` — verify assertion is registered with `IOPMCopyAssertionsByProcess`.
  - (c) Non-preset duration in `EditTemplateSheet` — if a template has a stored duration that doesn't match any chip (e.g. 30 min saved programmatically), show a "Custom: 30m" text hint alongside the presets instead of silently treating it as nil.
  - (d) `SettingsView` keyboard shortcut to open: expose the `⌃⌥A` shortcut in the onboarding walkthrough so new users know how to open Adia from anywhere.
  - (e) Callout tone for `"studying"` keyword: current messages are generic ("get back to your studying." sounds slightly awkward — "get back to studying." flows better). Could add a special-cased message format for the `studying` keyword that drops the possessive "your".

---

## Run 57 — 2026-06-05

### Shipped
- **fix + feat: preserve and edit preferredDuration in EditTemplateSheet**
  - **Bug fixed**: `EditTemplateSheet` was calling `SessionTemplateStore.update(id:task:successCriteria:)` without the `preferredDuration` parameter, which defaulted to `nil` and silently wiped the stored duration on every save. Now the save handler captures `let dur: TimeInterval? = selectedMinutes.map { TimeInterval($0 * 60) }` and passes it explicitly.
  - **Duration chip row added** to `EditTemplateSheet`: same four presets (25m / 45m / 1h / 90m) as the session creation form, styled with `Color.accentColor` fill for the selected chip. A clear button (`xmark.circle.fill`) appears when a chip is active.
  - **Snap-to-preset on open**: `init` converts `template.preferredDuration` (seconds) to integer minutes, checks membership in `{25, 45, 60, 90}`, and pre-selects the matching chip. Non-preset values (e.g., a 30-minute duration set programmatically) get no chip pre-selected (treated as nil) without data loss at the store level.
  - **Sheet height** bumped 280 → 360 to accommodate the new Duration Goal section.
  - **Tests (+3)** in `SessionTemplateTests.swift`: `updateWithNilPreferredDurationClearsStoredValue` (regression guard: passing nil to update overwrites an existing value), `updatePersistsAllThreeFieldsTogether` (task + criteria + duration all committed in one update call), `updatePreservesDurationWhenPassedThrough` (simulates the fixed EditTemplateSheet path: read template.preferredDuration, pass it back unchanged, verify it survives).

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) `SettingsView` window height adaptive — currently fixed at `500`. Make height computed from tab content.
  - (b) Integration test for `SleepBlocker.start()` — verify assertion is registered with `IOPMCopyAssertionsByProcess`.
  - (c) Keyword extraction: could add "lab" → "research", "pset" → "homework", "midterm" → "studying" for more student-centric inputs.
  - (d) Auto-suggest recently whitelisted domain on "not verified": surface `session.whitelistedDomains.last` in the verification result view.
  - (e) Non-preset duration in EditTemplateSheet: if a template has a stored duration that doesn't match any chip (e.g. 30 min saved programmatically), the current init snaps to nil. Could add a custom time picker or show a text hint like "Custom: 30m (no chip)" alongside the presets.

---

## Run 56 — 2026-06-05

### Shipped
- **fix + feat: word-boundary keyword extraction + template duration memory**
  - `extractTaskKeyword` — replaced all `lower.contains(keyword)` checks with a `word(_ w: String) -> Bool` helper using `String.range(of: "\\b\(w)\\b", options: .regularExpression)`. Fixes false positives: "threading" → no longer matches "reading"; "contest"/"latest"/"protest" → no longer match "test" → "studying"; "facebook" → no longer matches "book" → "reading". All existing keyword tests continue to pass (whole-word inputs like "study", "reading", "test", "book" still match correctly).
  - `SessionTemplate.preferredDuration: TimeInterval?` — new optional field (default `nil`). Moved struct to manual `Codable` conformance (extension) with `decodeIfPresent` / `encodeIfPresent` for full backward compat: old JSON without the key decodes to `nil`, `nil` is not written to JSON.
  - `SessionTemplateStore.add(task:successCriteria:preferredDuration:)` — new optional `preferredDuration` param (default `nil`). Both the "new template" and "deduplication update" paths now persist the duration. So re-pinning a task with a different chip selection updates the stored duration.
  - `SessionTemplateStore.update(id:task:successCriteria:preferredDuration:)` — same, accepts and stores `preferredDuration`.
  - **`launchTemplate`** in `NotchView` — passes `t.preferredDuration` as `targetDuration` to `SessionManager.shared.start`. Template launches now automatically restore the progress arc and countdown from Run 55 without the user having to re-select a chip.
  - **Template pin in creation form** — the `shouldPin` path now passes `durationSeconds` as `preferredDuration: durationSeconds` to `SessionTemplateStore.shared.add`, so the chip selection at creation time is remembered in the template.
  - **`templateButton`** — shows a small monospaced duration badge (e.g. "25m", "1h", "1h30m") to the right of the task name when `preferredDuration != nil`. Uses `templateDurationLabel(_ seconds:)` private helper that formats minutes < 60 as "Nm", exact hours as "Nh", and mixed as "NhMm".
  - **Tests (+13)**: `extractTaskKeywordIgnoresReadingInsideThreading` (2 inputs), `extractTaskKeywordIgnoresTestInsideContest` (contest/latest/protest × 3 inputs), `extractTaskKeywordIgnoresBookInsideFacebook`, `extractTaskKeywordStillMatchesStandaloneWords` (reading/studying/article × 3); template duration: `addWithPreferredDurationStoresIt`, `addWithoutPreferredDurationDefaultsToNil`, `addDuplicateTaskUpdatesPreferredDuration`, `addDuplicateTaskClearsPreferredDurationWhenNil`, `updateWithPreferredDurationStoresIt`, `preferredDurationSurvivesCodecRoundTrip`, `legacyJSONWithoutPreferredDurationDecodesAsNil`.

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) `SettingsView` window height adaptive — currently fixed at `500`. Make height computed from tab content.
  - (b) Integration test for `SleepBlocker.start()` — verify assertion is registered with `IOPMCopyAssertionsByProcess`.
  - (c) Keyword extraction: could add "lab" → "research", "pset" → "homework", "midterm" → "studying" for more student-centric inputs.
  - (d) Auto-suggest recently whitelisted domain on "not verified": surface `session.whitelistedDomains.last` in the verification result view.
  - (e) Template edit UI in SettingsView — currently templates can only be reordered/deleted; no way to edit task text or success criteria in-place without re-creating.

---

## Run 55 — 2026-06-05

### Shipped
- **feat: session duration goal with progress arc and countdown**
  - `Session.targetDuration: TimeInterval?` — new optional field (default `nil`). `decodeIfPresent` for backward compat (old sessions decode to nil). `encodeIfPresent` so nil omits the key from JSON.
  - `SessionManager.start(targetDuration:)` — new optional parameter (default `nil`), threads the chosen duration into the `Session` init.
  - **Session creation form** — DURATION chip row: `25m / 45m / 60m / 90m` compact chips between the text field and the clarifying question. Tapping a selected chip deselects it (nil = no limit). White fill + black text for selected state, 10pt semibold text.
  - **`ProgressDot`** (new private struct in `NotchView.swift`): when `progress` is `nil` renders the original 7×7 colored dot; when set (0…1) renders a 13×13 arc ring (1.5pt stroke) with a 5pt center dot. `CollapsedView` uses a `TimelineView(.periodic(by: 1.0))` to update the arc every second — only when a duration goal is active (no-goal sessions continue using the cheap static `Circle()`).
  - **`ProgressBar`** (new private struct): full-width 3pt-tall progress bar using `GeometryReader` so the fill accurately scales to available width. Shown in the expanded active-session card below the elapsed timer row, inside a 1s `TimelineView`.
  - **Remaining time label** in the expanded active-session elapsed row: when target is set, a small secondary label appears alongside the monospaced elapsed timer ("45m left" / "1h 20m left" / "< 1m left" / "done").
  - `NotchWindowController.creationExpandedHeight` bumped 310 → 348 to accommodate the new chip row.
  - **Tests (+9)**: `SessionDurationTests` (6 cases — `targetDurationDefaultsToNil`, `targetDurationStoredInInit`, codable round-trip with value, codable round-trip with nil, legacy JSON backward compat decodes as nil, nil not encoded as key); `SessionPersistenceTests` (3 new cases — `saveLoadRoundTripPreservesTargetDuration` (5400s), `targetDurationDefaultsToNilForLegacySession` (key stripped from JSON), `nilTargetDurationRoundTrips`).

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) `SettingsView` window height adaptive — currently fixed at `500`. Make height computed from tab content.
  - (b) Integration test for `SleepBlocker.start()` — verify assertion is registered with `IOPMCopyAssertionsByProcess`.
  - (c) Keyword extraction edge case: "threading" contains "reading" → returns `"reading"` keyword. Fix with word-boundary regex in `extractTaskKeyword`.
  - (d) Auto-suggest recently whitelisted domain on "not verified": surface `session.whitelistedDomains.last` in the verification result view.
  - (e) Template duration memory: when launching a session from a pinned template, let the template optionally store a preferred duration so the user doesn't have to re-select chips.

---

## Run 54 — 2026-06-05

### Shipped
- **feat: task-context-aware callout messages**
  - `CalloutManager.extractTaskKeyword(from:)` — new `public static` pure function. Maps a free-text task description to one of 8 subject keywords: `"essay"` (essay/paper/thesis), `"presentation"` (slides/deck/powerpoint/keynote), `"code"` (coding/bug/feature/function), `"report"` (report/document/doc), `"studying"` (study/exam/quiz/test), `"reading"` (reading/book/chapter/article), `"homework"` (homework/assignment), `"research"`. Returns `nil` for generic inputs like "work" or "get things done".
  - `CalloutManager.setTask(_:)` — new `public` method that calls `extractTaskKeyword` and stores the result. Called by `SessionManager.activate()` after `reset()` + `restore(count:)` so every new and crash-restored session gets correct context immediately.
  - `CalloutManager.taskAwareCallouts(keyword:tier:)` — new `internal` method returning 2–3 task-specific callout strings per tier. Tier 1: "get back to your essay.", "this isn't your essay.", "your essay isn't going to finish itself." Tier 2: "stop putting off your essay.", "you need to work on your essay, not this." Tier 3: "CLOSE THIS. open your essay.", "your essay deadline isn't moving." 
  - `fire()` updated: blends `taskAwareCallouts` into the generic tier pool when `taskKeyword != nil`. Generic pool remains dominant in size so generic messages still fire proportionally. Task-aware messages appear ~(k / n+k) of the time.
  - `reset()` now clears `taskKeyword = nil` so session cleanup is complete.
  - Removed hardcoded `"this isn't your essay."` from `tier1Callouts` static pool — replaced by the dynamic "this isn't your [keyword]." template that adapts to the actual task.
  - `currentTaskKeyword: String?` exposed as `internal var` for unit test inspection.
  - `SessionManager.activate()` — added `callout.setTask(s.task)` after `callout.restore(count:)`.
  - **Tests (+12)** in `CalloutManagerTests.swift`: `extractTaskKeywordFromEssayInput` (essay/paper/thesis inputs), `extractTaskKeywordFromCodeInput` (bug/coding/feature), `extractTaskKeywordFromPresentationInput` (presentation/slides/deck), `extractTaskKeywordFromStudyInput` (study/quiz), `extractTaskKeywordFromHomeworkInput` (homework/assignment), `extractTaskKeywordFromResearchInput`, `extractTaskKeywordReturnsNilForGenericInput` (work/""/generic phrases), `setTaskStoresExtractedKeyword`, `setTaskWithUnknownTaskStoresNil`, `resetClearsTaskKeyword`, `taskAwareCalloutsContainKeyword` (all tier-1/2/3 messages for "essay" contain "essay"), `taskAwareCalloutsSubstituteKeywordPerTier` (verified for 4 keywords × 3 tiers).

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) `SettingsView` window height adaptive — currently fixed at `500`. If future tabs grow taller, make height computed from tab content.
  - (b) Integration test for `SleepBlocker.start()` — could verify the assertion is registered with `IOPMCopyAssertionsByProcess`.
  - (c) Session duration goal: let the user optionally set a target work duration (e.g. 90 min) and show a countdown or progress arc in the collapsed notch. Adds `targetDuration: TimeInterval?` to `Session`.
  - (d) Keyword extraction edge case: "threading" contains "reading" → returns "reading" instead of nil. Low impact for target users (students), but could be addressed with word-boundary logic if needed.
  - (e) Auto-suggest recently whitelisted domain on "not verified": surface `session.whitelistedDomains.last` in the verification result view so the user knows what site they can visit to finish the task.

---

## Run 53 — 2026-06-05

### Shipped
- **feat: expand notch when user taps notification banner**
  - `SessionNotifier.expandNotch()` (internal): testable helper that calls `NotchState.shared.expand()`. Kept `internal` (not `private`) so unit tests can invoke it directly without needing a real `UNNotificationResponse`.
  - `userNotificationCenter(_:didReceive:withCompletionHandler:)` added to the `UNUserNotificationCenterDelegate` extension. `nonisolated` per the delegate protocol; dispatches `expandNotch()` + `NSApp.activate(ignoringOtherApps: true)` to the `@MainActor` via `Task { @MainActor in ... }`; calls `completionHandler()` immediately (no need to await the UI hop, per Apple docs).
  - `#if canImport(AppKit) import AppKit #endif` added at the top of `SessionNotifier.swift` to expose `NSApp`.
  - **Tests (+3)** in `SessionNotifierTests.swift`: `notificationTapExpandsNotchFromCollapsed` (collapses notch, calls `expandNotch()`, checks `isExpanded == true`), `notificationTapIsIdempotentWhenAlreadyExpanded` (expands first, calls again, stays expanded), `delegateImplementsDidReceiveSelector` (`responds(to: NSSelectorFromString("userNotificationCenter:didReceive:withCompletionHandler:"))` is true).

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) `SettingsView` window height adaptive — currently fixed at `500`. If future tabs grow taller, bump to `520` or make height computed from tab content.
  - (b) Integration test for `SleepBlocker.start()` — currently exercised by unit tests that call `IOPMAssertionCreateWithName` on macOS; could add a test that verifies the assertion is actually registered with `IOPMCopyAssertionsByProcess`.
  - (c) `userNotificationCenter(_:didReceive:withCompletionHandler:)` — DONE in this run.
  - (d) Make `SettingsView` window height adaptive to content — currently hardcoded to `500` in `AppDelegate`. Tabs could compute their intrinsic height via `GeometryReader` or a `PreferenceKey` and update the window on tab switch.
  - (e) When session verification shows "not verified", auto-suggest the most-recently-visited blocked site as a potential relevant resource — pull from `HostsFileManager` whitelist and surface it in the callout or notch.

---

## Run 52 — 2026-06-05

### Shipped
- **feat: UNUserNotificationCenterDelegate — notifications fire while app is frontmost**
  - `SessionNotifier` now extends `NSObject` and conforms to `UNUserNotificationCenterDelegate`.
  - `init()` sets `UNUserNotificationCenter.current().delegate = self` so macOS invokes `willPresent(_:withCompletionHandler:)` instead of silently suppressing banners when Adia is the active application.
  - `willPresent` returns `[.banner, .sound]` via `foregroundPresentationOptions` (a `nonisolated static let` constant so the `nonisolated` delegate method can read it without an actor hop, Swift 6-clean).
  - `foregroundPresentationOptions` is public so tests can verify the value without needing a real `UNNotification` instance.
  - **Tests (+3)** in `SessionNotifierTests.swift`: `sharedIsRegisteredAsNotificationDelegate` (checks `UNUserNotificationCenter.current().delegate === SessionNotifier.shared`), `conformsToUNUserNotificationCenterDelegate` (protocol conformance check), `foregroundPresentationOptionsIncludeBannerAndSound` (verifies `.banner` and `.sound` are both present).

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) `SettingsView` window height adaptive — currently fixed at `500`. If future tabs grow taller, bump to `520` or make height computed from tab content.
  - (b) Integration test for `SleepBlocker.start()` — currently exercised by unit tests that call `IOPMAssertionCreateWithName` on macOS; could add a test that verifies the assertion is actually registered with `IOPMCopyAssertionsByProcess`.
  - (c) `userNotificationCenter(_:didReceive:withCompletionHandler:)` — handle user tapping the notification banner to bring the Adia notch into focus (expand the notch panel). Currently the delegate doesn't implement this method so tapping the banner does nothing.

---

## Run 51 — 2026-06-05

### Shipped
- **feat: prevent display sleep during focus sessions**
  - `SleepBlocker` (`Sources/AdiCore/SleepBlocker.swift`): new `@MainActor public final class`. Wraps `IOPMAssertionCreateWithName(kIOPMAssertPreventUserIdleDisplaySleep, ...)` / `IOPMAssertionRelease`. `start()` is idempotent; `stop()` is a safe no-op if not active. `isActive: Bool` for inspection.
  - `#if canImport(IOKit)` guards throughout — non-macOS builds get a state-tracking stub that compiles cleanly.
  - `SessionManager.activate()` — calls `SleepBlocker.shared.start()` at the top of every session (new and restored).
  - `SessionManager.endSession()` — calls `SleepBlocker.shared.stop()`.
  - `SessionManager.start()` error-rollback path — also calls `SleepBlocker.shared.stop()` so a failed activate doesn't leave the assertion dangling.
  - **Tests (+6)** in `SleepBlockerTests.swift`: `inactiveByDefault`, `startActivatesBlocker`, `stopDeactivatesBlocker`, `doubleStartIsIdempotent`, `stopWithoutStartIsNoOp`, `restartAfterStopWorks`.
- **feat: system notifications for session complete and session restore**
  - `SessionNotifier` (`Sources/AdiCore/SessionNotifier.swift`): new `@MainActor public final class`. `requestPermission()` requests `UNUserNotificationCenter` `.alert + .sound` permission once. `sendSessionComplete(task:)` fires "Session complete ✓" banner when Claude verifies the task done — surfaces the success even if the notch collapses before the user looks up. `sendSessionRestored(task:)` fires "Session restored" banner on crash-recovery relaunch.
  - `@preconcurrency import UserNotifications` + `#if canImport(UserNotifications)` guards for Swift 6 compatibility and non-macOS builds.
  - `AppDelegate.showNotch()` — calls `SessionNotifier.shared.requestPermission()` once at startup (after the notch window is up, before `restoreIfNeeded`).
  - `SessionManager.verifyAndEnd()` — calls `sendSessionComplete(task: s.task)` immediately after `sessionEndedSuccessfully = true`, before the 1.2s display pause.
  - `SessionManager.restoreIfNeeded()` — calls `sendSessionRestored(task: s.task)` after fully restoring capture + history.
  - Added clarifying comment in `verifyAndEnd()` not-verified path explaining why `session` is re-read rather than using the stale `s` (preserves any whitelist changes made during the verification await).

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) `UNUserNotificationCenterDelegate.userNotificationCenter(_:willPresent:withCompletionHandler:)` — macOS by default suppresses banners when the app is frontmost. If Adia is in a non-interactive fullscreen state where the notch is visible but the window counts as "active", users might not see the completion notification. Adding the delegate with `completionHandler([.banner, .sound])` ensures banners fire regardless of foreground state.
  - (b) `SettingsView` window height adaptive — currently fixed at `500`. If future tabs grow taller, bump to `520` or make height computed.
  - (c) Integration test for `SleepBlocker.start()` — currently exercised by unit tests that call `IOPMAssertionCreateWithName` on macOS; could add a test that verifies the assertion is actually registered with `IOPMCopyAssertionsByProcess`.

---

## Run 50 — 2026-06-04

### Shipped
- **feat: persist verification history across crash/relaunch**
  - `VerificationAttempt`: added `Codable` conformance (all fields — `timestamp: Date`, `result: VerificationResult`, `attemptNumber: Int` — are already codable types; no manual implementation needed).
  - `Session`: new field `verificationHistory: [VerificationAttempt]` (default `[]`, init parameter added with default). Manual `Codable` updated: `CodingKeys` gains `.verificationHistory`; `init(from:)` uses `decodeIfPresent` with `?? []` so sessions persisted before this change decode cleanly; `encode(to:)` encodes the array.
  - `NotchState.restoreVerificationHistory(_:)` — new public `@MainActor` method that sets `verificationHistory` directly. Does not expand the notch or modify other state. Called only by `SessionManager.restoreIfNeeded()` after crash recovery.
  - `SessionManager.verifyAndEnd()` — after `setVerificationResult(result)` for a **not-verified** result (session continues), reads `NotchState.shared.verificationHistory` back into a copy of `session` and writes it to `SessionPersistence`. This is the sync point: when the user crashes between "not verified" and their next attempt, the persisted attempt count is correct.
  - `SessionManager.restoreIfNeeded()` — after `activate(s)`, if `s.verificationHistory` is non-empty, calls `NotchState.shared.restoreVerificationHistory(s.verificationHistory)` so the attempt counter resumes correctly without expanding or otherwise disrupting the restored active-session UX.
  - **Tests (+7)**: `saveLoadRoundTripPreservesVerificationHistory` (2-attempt history survives JSONEncoder→UserDefaults→JSONDecoder round-trip, both attempt numbers and explanations verified), `verificationHistoryDefaultsToEmptyForLegacySession` (key stripped from JSON → decoded as `[]`) — in `SessionPersistenceTests`; `restoreVerificationHistoryPopulatesHistory` (2-entry restore, checks count and field values), `afterRestoreNextResultIsAttemptThree` (restore 2 entries, then call `setVerificationResult` → `attemptNumber == 3`), `restoreVerificationHistoryDoesNotExpandNotch` (history restored, `isExpanded` stays `false`) — in `NotchStateTests`.

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) `SettingsView` window height adaptive: currently fixed at `500`. If future tabs grow taller, consider making it adaptive or bumping to `520`.
  - (b) Verify-and-end `session` capture races: in `verifyAndEnd()`, the `guard let s = session` and the later `if var updated = session` both capture `session`. In theory `session` could go nil between them (e.g. `endSession()` called concurrently), though the UI prevents this. Could be made more robust with a single `guard let` at the top and passing `s` through.
  - (c) Verification history UI: the `VerificationAttemptRow` in `NotchView.swift` already shows history when `count > 1`. After a crash restore with 2 prior attempts, the user sees "attempt 3" immediately on the next verification — the counter is correct, but the prior-attempt rows are not shown until a new result comes in (because the row section only renders when `state.verificationHistory.count > 1`). Already working correctly because `restoreVerificationHistory` populates the array before the next `setVerificationResult` appends.

---

## Run 49 — 2026-06-04

### Shipped
- **fix: idle notch live refresh when `idleTemplatesFollowManualOrder` is toggled**
  - `IdleTaskID` (new private `Hashable` struct in `NotchView.swift`): combines `sessionID: UUID?` and `followManualOrder: Bool` into a single composite key.
  - `IdleBody`: added `@ObservedObject private var settings = SettingsStore.shared`. Changed `.task(id: session.session?.id)` to `.task(id: IdleTaskID(sessionID: session.session?.id, followManualOrder: settings.idleTemplatesFollowManualOrder))`. Now the async task re-fires immediately when the user toggles the sort-order setting while idle — previously the template list only refreshed after a session ended.
  - Removed the redundant `let followManual = SettingsStore.shared.idleTemplatesFollowManualOrder` local inside the task body; replaced with `settings.idleTemplatesFollowManualOrder` which is already observed.
- **fix: "Notch: use reorder" toggle visible in empty Templates settings state**
  - `TemplatesSettingsTab.body` refactored from `Group { if empty { ... } else { VStack { List + footer } } }` to `VStack { if empty { ... } else { List } + footer }`. The footer `HStack` (text label + `Toggle`) is now unconditionally rendered at the bottom.
  - Footer label adapts: `"No templates yet"` when empty, `"N templates · drag to reorder"` otherwise.
  - Users can now configure the notch sort-order preference before saving any templates.

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) Verification history persistence: `verificationHistory` lives only in `NotchState` (in-memory). If the app is relaunched mid-session-verification, history is lost. Could persist it alongside `SessionPersistence` keyed by session ID.
  - (b) Idle notch panel height when settings toggle fires: `NotchWindowController` currently resizes on `$idleTemplateCount` changes. Toggling `idleTemplatesFollowManualOrder` may change the template count (e.g. load() vs sorted() can return different numbers); height will auto-adjust because `idleTemplateCount` is updated inside the same task. No fix needed.
  - (c) `SettingsView` window height: currently fixed at `500`. If future tabs grow taller, consider making the window height adaptive or bumping to `520`.

---

## Run 48 — 2026-06-04

### Shipped
- **feat: empty-day heatmap opacity — dimmer track for days with 0 sessions**
  - `WeekHeatmapView.columnView` in `SettingsView.swift`: track `RoundedRectangle` fill changed from a flat `secondary.opacity(0.1)` to `secondary.opacity(day.minutes > 0 ? 0.1 : 0.05)`. Days that had sessions keep the existing 10% opacity track; days with zero sessions drop to 5%. The fill bar is still absent for empty days, so active days now read as more distinct in two ways: brighter track + visible fill bar.
- **feat: idle notch template order toggle — show pinned templates by drag order or recency**
  - `SettingsStore.idleTemplatesFollowManualOrder: Bool` — new `@Published` property persisted to UserDefaults (`adia.idleTemplatesFollowManualOrder`), default `false` (recency order, unchanged from before).
  - `IdleBody.body.task` in `NotchView.swift`: reads `SettingsStore.shared.idleTemplatesFollowManualOrder` and branches:
    - `false` (default): `SessionTemplateStore.shared.sorted()` — top-2 by most recently used (existing behaviour).
    - `true`: `SessionTemplateStore.shared.load()` — file order (the drag-to-reorder order from the Templates settings tab).
  - `TemplatesSettingsTab` in `SettingsView.swift`: added `@ObservedObject private var settings = SettingsStore.shared`. Footer bar now includes a compact `Toggle("Notch: use reorder", ...)` switch (`controlSize: .mini`, `.toggleStyle(.switch)`, `.help(...)` tooltip) on the trailing edge alongside the existing count label.
  - **Tests (+2)** in `SettingsStoreTests.swift`: `idleTemplatesFollowManualOrderDefaultsToFalse` (write `false`, read back from UserDefaults → `false`), `idleTemplatesFollowManualOrderPersistsToUserDefaults` (write `true` → stored `true`, write `false` → stored `false`).

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) Verification history persistence: `verificationHistory` lives only in `NotchState` (in-memory). If the app is relaunched mid-session-verification, history is lost. Could persist it alongside `SessionPersistence` keyed by session ID.
  - (b) `TemplatesSettingsTab` "Notch: use reorder" toggle visibility: currently only shown when templates exist (non-empty state). Consider showing the setting even in the empty state so users can configure it before adding templates.
  - (c) Idle notch live refresh on `idleTemplatesFollowManualOrder` change: currently `IdleBody` re-queries templates only when `session.session?.id` changes. If the user toggles the setting while idle, the order doesn't update until the next session end. Could add `$idleTemplatesFollowManualOrder` to the `.task(id:)` dependency.

---

## Run 47 — 2026-06-04

### Shipped
- **feat: verification attempt history within a session**
  - `VerificationAttempt` (new `Sendable` struct in `SessionState.swift`): `timestamp: Date`, `result: VerificationResult`, `attemptNumber: Int` (1-based). Simple value type, no persistence needed.
  - `NotchState.verificationHistory: [VerificationAttempt]` — new `@Published public private(set)` array. `setVerificationResult(_:)` appends a new `VerificationAttempt` on every non-nil result call. `setVerificationResult(nil)` does not append (nil = "Keep going" / clear, not an attempt). `collapse()` clears the array so each session starts fresh.
  - `verificationResultBody` in `NotchView.swift`: when `state.verificationHistory.count > 1` (there's at least one prior attempt besides the current one), the header shows an `"attempt N"` capsule. Below the action buttons a `"PREVIOUS ATTEMPTS"` section renders a 100pt-max `ScrollView` of `VerificationAttemptRow` entries in reverse order (most recent prior attempt first) so the user sees the most recent context at the top.
  - `VerificationAttemptRow` (new private struct): icon (✓/✗) + `"Attempt N"` label + relative timestamp (`"just now"` / `"Nm ago"`) + 2-line truncated explanation. Styled recessed with `Color.white.opacity(0.04)` background so it reads as secondary to the current result.
  - `NotchWindowController`: new `verificationHistoryHeight = 350` constant. `targetFrame` selects it when `state.verificationHistory.count > 1` (vs `verificationHeight = 250` for first attempt). Added `$verificationHistory` Combine sink so the panel resizes automatically on the first retry without waiting for another published change.
  - **Tests (+6)** in `NotchStateTests`: `setVerificationResultAppendsToHistory`, `multipleResultsAccumulateInHistory` (3 sequential results → history.count==3, attemptNumbers 1/2/3), `historyPreservesExplanations`, `setVerificationResultNilDoesNotAppendToHistory` (nil call doesn't grow count), `collapseClearsVerificationHistory`, `historyIsEmptyOnFreshState`. Updated `collapseResetsAllUIFlags` to also assert `verificationHistory.isEmpty`.

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) Empty-day heatmap opacity: give days with 0 sessions a subtly different track color (e.g. `secondary.opacity(0.05)`) to make active/inactive days more distinct from never-used days.
  - (b) Idle notch template order toggle: `SettingsStore.idleNotchTemplatesFollowManualOrder: Bool` — lets users choose whether the notch shows top-2 by recency (current) or manual reorder order.
  - (c) Verification history persistence: currently `verificationHistory` lives only in `NotchState` (in-memory). If the app is relaunched mid-session-verification, history is lost. Could persist it alongside `SessionPersistence` keyed by session ID.

---

## Run 46 — 2026-06-04

### Shipped
- **feat: "Try again" button in verification result — re-verify without ending session**
  - `verificationResultBody` in `NotchView.swift`: when the verification result is not-verified, the button row is now an `HStack` with two `AdiButton`s side by side.
  - **"Try again"** (`.secondary` style): calls `Task { await SessionManager.shared.verifyAndEnd() }`. This immediately invokes `setVerifying(true)` (clearing the stale not-verified result), shows the spinner, re-captures `captureManager.lastFrame` (the latest screen state), and sends it to claude-sonnet-4-6 for re-verification. Session stays active the whole time.
  - **"Keep going"** (`.primary` style): unchanged — clears the result and collapses the notch, resuming the session silently.
  - No changes to `SessionManager.verifyAndEnd()` or `NotchState` were needed — the state machine already supports this path: `setVerifying(true)` clears `verificationResult`, causing the content switcher to show `verifyingBody` (spinner) instead of the stale result card.
  - **Tests (+2)** in `NotchStateTests.swift`:
    - `retryAfterNotVerifiedClearsResult` — seeds a not-verified result, calls `setVerifying(true)` (the action "Try again" triggers), asserts `verificationResult == nil`, `isVerifying == true`, `isExpanded == true`.
    - `retryKeepGoingCollapsesClearsResult` — seeds a not-verified result, simulates "Keep going" sequence (`setVerificationResult(nil)` + `collapse()`), asserts `verificationResult == nil`, `isExpanded == false`, `isVerifying == false`.

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) Empty-day heatmap opacity: give days with 0 sessions a subtly different track color (e.g. `secondary.opacity(0.05)`) to make active/inactive days more distinct.
  - (b) Idle notch template order toggle: `SettingsStore.idleNotchTemplatesFollowManualOrder: Bool` — lets users choose whether the notch shows top-2 by recency (current) or manual reorder order.
  - (c) Verification history: show past verification attempts within a session (how many times the user tried, what Claude said each time) in the expanded notch card, so the user can adapt their approach.

---

## Run 45 — 2026-06-04

### Shipped
- **feat: callout escalation persistence across session restarts**
  - `Session.calloutCount: Int` (default 0) — new field on the Session model. Persisted via the manual Codable implementation using `decodeIfPresent` so old sessions without the key decode cleanly to 0 (backward-compat). Encoded in `encode(to:)`.
  - `CalloutManager.restore(count:)` — new public method sets `calloutCount` directly. Designed to be called after `reset()` so streak state is cleared but the session-level tier counter is preserved. For new sessions with `calloutCount = 0` this is a no-op.
  - `SessionManager.activate()` — now calls `callout.restore(count: s.calloutCount)` immediately after `callout.reset()`. This is the only call site: new sessions pass 0 (no-op), restored sessions pass the saved count so they resume at the correct tier (1/2/3).
  - `SessionManager.handleFrame()` — after `callout.evaluate(status)`, checks if `callout.calloutCount != session.calloutCount`. If so (a callout just fired), syncs the new count back into `session` and calls `persistence.save(s)`. This is an O(1) int comparison on every ~1fps frame; actual UserDefaults writes happen only when a callout fires.
  - **Tests (+5)**: `restoreCountSetsCalloutCount`, `restoreCountAffectsTierOnNextFire` (verifies tier 3 fires after restoring count=4), `resetAfterRestoreZeroesCount` — in `CalloutManagerTests`; `saveLoadRoundTripPreservesCalloutCount`, `calloutCountDefaultsToZeroForLegacySession` (strips key from encoded JSON, verifies 0 fallback) — in `SessionPersistenceTests`.

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) Empty-day heatmap opacity: give days with 0 sessions a subtly different track color (e.g. `secondary.opacity(0.05)`) to make active/inactive days more distinct.
  - (b) Idle notch template order toggle: `SettingsStore.idleNotchTemplatesFollowManualOrder: Bool` toggle so users can choose whether the notch shows top-2 by recency (current) or manual reorder order.
  - (c) Session verification retry: after a "not verified" result, show a "Try again" button that re-captures and re-verifies without ending the session, so the user doesn't need to wait for a new screen state.

---

## Run 44 — 2026-06-04

### Shipped
- **feat: template drag-to-reorder in Settings Templates tab**
  - `SessionTemplateStore.reorder(fromOffsets:toOffset:)` — new public actor method. Loads the template array, calls `Array.move(fromOffsets:toOffset:)` (same semantics as SwiftUI `.onMove`), saves atomically. No intermediate sort.
  - `SessionTemplateStore.add()` — changed `append` → `insert(at: 0)` so the newest template surfaces at the top of the user-visible list. When trimming over the 10-template cap, the existing `lastUsedAt`-sort is still used to keep the most-valuable entries.
  - `TemplatesSettingsTab.reloadTemplates()` — now calls `load()` (file order = display order) instead of `sorted()`. The idle notch still uses `sorted()` (lastUsedAt order) so the 2 most-recently-used templates continue to appear there regardless of manual reorder.
  - `ForEach.onMove` wired in the Settings List: updates local `@State` immediately (optimistic), then persists via `Task { await store.reorder(...) }`.
  - Footer text: "sorted by recent use" → "drag to reorder".
  - **Tests (+5)**: `addPrependsNewTemplateAtFront`, `reorderMovesItemToFront`, `reorderIsPersisted`, `reorderOnSingleItemIsNoOp`, `reorderPreservesTemplateFields`.

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) Callout escalation persistence: `calloutCount` resets on session restore. Persist it in `SessionPersistence` / `SessionRecord` and restore in `CalloutManager.reset()`.
  - (b) Empty-day heatmap opacity: give days with 0 sessions a subtly different track color (e.g. `secondary.opacity(0.05)`) to make active/inactive days more distinct.
  - (c) Idle notch template order: the idle notch currently shows top 2 by `lastUsedAt`. Could add a `SettingsStore.idleNotchTemplatesFollowManualOrder: Bool` toggle so users can choose whether the notch respects manual reorder or recency.

---

## Run 43 — 2026-06-03

### Shipped
- **test: Claude API integration smoke test** (`Tests/AdiTests/ClaudeAPIIntegrationTests.swift`)
  - New `@Suite("Claude API Integration", .enabled(if: hasAnthropicKey, ...))` — entire suite is auto-skipped when `ANTHROPIC_API_KEY` is absent, so CI never fails.
  - `hasAnthropicKey` (private module-scope constant): evaluates once at test startup; requires `sk-ant-` prefix and non-empty value.
  - **`parseGoalAcceptsAcademicTask`** — calls `parseGoal("write my history essay")`, asserts `ok == true`, non-empty `task` and `successCriteria`, `question == nil`.
  - **`parseGoalAcceptsHomework`** — same shape for `"homework"`.
  - **`parseGoalAcceptsPresentation`** — same shape for `"make a presentation"`.
  - **`parseGoalRejectsEmptyViaLocalGuard`** / **`parseGoalRejectsLeisureViaLocalGuard`** — verifies the fast `localGoalRejectionReason(_:)` path fires before any network hop for empty/leisure input.
  - **`parseGoalReturnsQuestionForVagueInput`** — confirms local guard catches `"stuff"`.
  - **`chatReturnsNonEmptyResponse`** — sends one-word instruction, asserts non-empty response.
  - **`chatFollowsSystemPromptTone`** — asks `2+2`, system says "single number only", asserts `"4"` in response.
  - **`chatMultiTurnCarriesContext`** — three-turn conversation establishing "favourite colour is blue", asserts follow-up contains `"blue"`.
  - **`parseGoalResponseIsWellFormed`** — round-trip check on `"study for my biology exam"`: whichever branch fires (ok/reject), the output is structurally valid.
  - Run with: `ANTHROPIC_API_KEY=sk-ant-... swift test`

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) Callout escalation persistence: `calloutCount` resets on session restore. Persist it in `SessionPersistence` / `SessionRecord` and restore in `CalloutManager.reset()`.
  - (b) Empty-day heatmap opacity: give days with 0 sessions a subtly different track color to make the active/inactive gap more pronounced.
  - (c) Template reorder: drag-to-reorder in the Templates tab (add `displayOrder: Int` to `SessionTemplate`, `reorder(fromOffsets:toOffset:)` to `SessionTemplateStore`).

---

## Run 42 — 2026-06-03

### Shipped
- **feat: menu bar status item — NSStatusItem with left-click toggle and right-click context menu**
  - `MenuBarManager` (`Sources/AdiCore/MenuBarManager.swift`): new `@MainActor public final class`. Creates an `NSStatusItem` (square length) in the system menu bar when `SettingsStore.shared.showMenuBarItem` is `true`. Left-click fires the same open/close logic as `GlobalHotkeyManager` (`startCreating` when idle, `toggle` when session active). Right-click pops a context menu showing current session state, Start/End Session, Settings…, and Quit Adia.
  - Icon: `"a.circle"` (idle) / `"a.circle.fill"` (session active), both `.isTemplate = true` so they adapt to dark/light menu bar automatically.
  - Subscribes to `SessionManager.$session` via Combine to keep the icon in sync with session state without polling.
  - `SettingsStore.showMenuBarItem: Bool` — new `@Published` property persisted to UserDefaults (`adia.showMenuBarItem`), defaults `true`. Controls whether `MenuBarManager.start()` actually creates the status item.
  - `AppDelegate.showNotch()` — calls `MenuBarManager.shared.start()` after `GlobalHotkeyManager` so both controls are active from launch.
  - `SettingsView` Account tab — adds a "Show in menu bar" toggle in the Keyboard Shortcuts section. Toggling off calls `MenuBarManager.stop()` (removes the item immediately); toggling on calls `start()`. Footer text updated to mention the menu bar as a notch fallback for non-notch Macs.
  - **Tests** (`SettingsStoreTests` +2): `showMenuBarItemDefaultsToTrue` (verifies persistence round-trip to UserDefaults), `showMenuBarItemPersistsToUserDefaults` (write `false` → stored `false`, write `true` → stored `true`).

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals complete. Possible next improvements:
  - (a) Callout escalation persistence: `calloutCount` resets on session restore. Persist it in `SessionPersistence` / `SessionRecord` and restore in `CalloutManager.reset()`.
  - (b) Empty-day heatmap opacity: give days with 0 sessions a subtly different track color to make the active/inactive gap more pronounced.
  - (c) Template reorder: drag-to-reorder in the Templates tab (add `displayOrder: Int` to `SessionTemplate`, `reorder(fromOffsets:toOffset:)` to `SessionTemplateStore`).
  - (d) Integration smoke test: hit the real Claude API with the `ANTHROPIC_API_KEY` in env; parse and log classification + verification responses.

## Run 41 — 2026-06-03

### Shipped
- **refactor: make response parsers static, eliminate test duplication**
  - `AgentAIClient.swift`: `parseClassification`, `parseVerification`, `parseGoalResponse`, `stripMarkdownFences` promoted from instance methods to `static`. They carried no actor state; making them static makes their pure nature explicit and lets tests call the real implementations without async/await.
  - `AgentAIClientTests.swift`: removed ~40 lines of duplicated parsing helpers (`parseClassification`, `parseVerification`, `strip`). Tests now call `AgentAIClient.parseClassification(...)` and `AgentAIClient.parseVerification(...)` directly. Added 8 new test cases (ambiguous status, unknown status, missing confidence default, markdown-strip-verified-true, local rejection for empty/whitespace/stuff/youtube/tiktok).
  - `USER_TODO.md`: corrected stale `OPENAI_API_KEY` → `ANTHROPIC_API_KEY` reference left over from the OpenAI-era docs.

### Blocked
- Nothing. All 14 GOAL.md items remain checked off.

### Next agent
- All goals are complete. Consider: integration smoke test hitting the real Claude API (key is in env), UI polish pass, or adding a "focus streak" feature to history tracking.

## Run 40 — 2026-06-02

### Shipped
- **refactor: migrate AI client from OpenAI to Claude (Anthropic) API**
  - `AgentAIClient.swift` — full HTTP layer rewrite:
    - Base URL changed from `https://api.openai.com/v1/responses` → `https://api.anthropic.com/v1/messages`
    - Auth header changed from `Authorization: Bearer <key>` → `x-api-key: <key>` with `anthropic-version: 2023-06-01`
    - Fast model: `claude-haiku-4-5-20251001` (from `ADIA_CLAUDE_FAST_MODEL` env or default). Used for classify, parseGoal, chat.
    - Strong model: `claude-sonnet-4-6` (from `ADIA_CLAUDE_STRONG_MODEL` env or default). Used for verify.
    - Request body format: `{model, max_tokens, system, messages}` (Anthropic Messages API) — replaces OpenAI Responses API `{model, instructions, input, max_output_tokens}`.
    - Image content block: `{type:"image", source:{type:"base64", media_type:"image/jpeg", data:...}}` — replaces OpenAI `{type:"input_image", image_url:..., detail:...}`.
    - Text content blocks: `{type:"text", text:...}` — was `{type:"input_text", text:...}`.
    - Multi-turn chat messages now serialize as `{role, content: String}` (text-only, Anthropic shorthand).
    - `extractOutputText()` now reads from Anthropic response's `content[{type:text, text:...}]` array instead of OpenAI's `output[content[text|output_text]]` nesting.
    - `looksLikeAnthropicKey()` (private): accepts `sk-ant-*` prefix; was `looksLikeOpenAIKey` which accepted `sk-*` but rejected `sk-ant-*`.
    - `currentKey()` reads env vars `ANTHROPIC_API_KEY`, `ADIA_AGENT_AI_KEY` in that order.
  - `SettingsStore.swift`:
    - `openAICompatibleKey` and `isOpenAICompatibleKey` (public) renamed to `anthropicCompatibleKey` / `isAnthropicCompatibleKey`. No callers outside this file, so no ABI break.
    - Key validation inverted: now requires `sk-ant-` prefix (was requiring `sk-` but excluding `sk-ant-`).
    - Env var resolution order in `init`: `ANTHROPIC_API_KEY` first, then `ADIA_AGENT_AI_KEY`.
    - Home-file fallback: `anthropic_key` now checked first (was last).
  - `SettingsView.swift`: "OpenAI API Key" → "Claude API Key"; placeholder `sk-proj-...` → `sk-ant-...`; error copy updated.
  - `OnboardingView.swift`: "Connect OpenAI" → "Connect Claude"; all user-facing OpenAI mentions updated. API key link now points to `console.anthropic.com/settings/keys`.
  - `NotchView.swift`: "Add an OpenAI key" error message → "Add a Claude API key in Settings".
  - `SettingsStoreTests.swift`: all `sk-proj-*` test keys updated to `sk-ant-*`; `rejectsAnthropicLookingKey` test flipped and renamed to `rejectsOpenAILookingKey` + added `acceptsAnthropicKey` test.
  - `GOAL.md`: updated checklist items to reflect Claude/Anthropic terminology.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. The app is now wired to Claude API (claude-haiku-4-5-20251001 for fast inference, claude-sonnet-4-6 for verification). The `ANTHROPIC_API_KEY` env var is the primary key source.
- Possible next improvements:
  - (a) Callout escalation persistence: `calloutCount` resets on session restore; persist it in `SessionPersistence`/`SessionRecord`.
  - (b) Empty-day heatmap opacity: give days with 0 sessions a subtly different track color.
  - (c) Template reorder: drag-to-reorder in Templates tab (add `displayOrder: Int` to `SessionTemplate`).
  - (d) Menu bar item: `NSStatusItem` as an alternative to the hotkey, useful on non-notch Macs.

---

## Run 39 — 2026-06-02

### Shipped
- **feat: global keyboard shortcut ⌃⌥A — expand Adia notch from any app**
  - `GlobalHotkeyManager` (`Sources/AdiCore/GlobalHotkeyManager.swift`): new `@MainActor public final class`. Registers both a local monitor (consumes event when Adia is key, prevents double-handling) and a global monitor (observes from any foreground app). Hotkey: `⌃⌥A` (Control+Option+A) — low-conflict combination not used by common apps.
  - `start()` / `stop()` lifecycle methods. `#if canImport(AppKit)` guards throughout for Linux build compatibility.
  - `fire()`: when no session is active → calls `NotchState.shared.startCreating()` (expands notch, opens session form); when session is active → calls `NotchState.shared.toggle()` (expand/collapse).
  - Key code `0x00` is the virtual key for the 'A' position on QWERTY layouts (position-based, layout-independent).
  - `AppDelegate.showNotch()` — added `GlobalHotkeyManager.shared.start()` call after the notch window and blocker window are created.
  - `SettingsView` Account tab — added "Keyboard Shortcuts" section showing `⌃⌥A → Open / close Adia` with a "Works globally" footer hint.
  - No new tests: pure logic (`fire()`) delegates to `NotchState`/`SessionManager` which are already tested; monitor registration is AppKit I/O not suited for unit tests.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Possible next improvements:
  - (a) Callout escalation persistence across session restore: `calloutCount` resets on every `activate()`, so a restored session starts at tier 1. Could persist `calloutCount` in `SessionPersistence` / `SessionRecord` and restore it in `CalloutManager.reset()`.
  - (b) Empty-day heatmap opacity variation: give days with 0 sessions a subtly different track color to make active/inactive gap more pronounced.
  - (c) Template reorder: drag-to-reorder in the Templates tab — requires adding `displayOrder: Int` to `SessionTemplate` and a `reorder(fromOffsets:toOffset:)` method to `SessionTemplateStore`.
  - (d) Menu bar presence: add a `NSStatusItem` with a simple icon so users can click the menu bar icon as an alternative to the hotkey (useful on non-notch Macs).

---

## Run 38 — 2026-06-02

### Shipped
- **feat: Templates tab in Settings — view, edit, and delete saved templates**
  - `SessionTemplateStore.update(id:task:successCriteria:)` — new actor method for direct ID-based edit. Finds the entry by UUID, mutates both fields, writes atomically. No-op for unknown IDs. Preserves `useCount`, `lastUsedAt`, `createdAt`.
  - **`TemplatesSettingsTab`** (private struct in `SettingsView.swift`): fourth tab (tag 2, `pin.fill` icon), History tab moved to tag 3. Loads from `SessionTemplateStore.shared.sorted()` in `.task`. Empty state shows `pin.slash` icon + instructions. Non-empty state shows a `List` with an inset style and a footer "N templates · sorted by recent use".
  - **`TemplateRow`** (private struct): `pin.fill` icon, task text (2-line), criteria (1-line secondary), use count + relative timestamp in caption; pencil (edit) and trash (delete) action buttons with `.help` tooltips. Delete path awaits `SessionTemplateStore.shared.delete` then reloads.
  - **`EditTemplateSheet`** (private struct): 380×280 modal sheet. Two `TextField(axis:.vertical)` fields pre-populated from the template. Save (⏎) / Cancel (⎋) keyboard shortcuts. Save button disabled if either field is blank. On save: calls `SessionTemplateStore.shared.update`, invokes `onSave` callback (triggers list reload), dismisses.
  - **Tests** (`SessionTemplateTests` +4): `updateChangesBothFields`, `updatePreservesOtherFields` (id/useCount/lastUsedAt survive an edit), `updateUnknownIdIsNoOp`, `updateDoesNotAffectOtherTemplates`.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Possible next improvements:
  - (a) Callout escalation persistence across session restore: `calloutCount` resets on every `activate()`, so a restored session starts at tier 1. Could persist `calloutCount` in `SessionPersistence` / `SessionRecord` and restore it in `CalloutManager.reset()`.
  - (b) Empty-day heatmap opacity variation: give days with 0 sessions a subtly different track color (e.g. even lighter or slightly different hue) to make the gap between active/inactive days more pronounced.
  - (c) Keyboard shortcut to start/stop session: global hotkey (e.g. `⌘Return` or `⌘⇧F`) to open the session creation form from anywhere, expanding the notch if collapsed.
  - (d) Template reorder: drag-to-reorder in the new Templates tab — requires adding an explicit `displayOrder: Int` field to `SessionTemplate` and a `reorder(fromOffsets:toOffset:)` method to `SessionTemplateStore`.

---

## Run 37 — 2026-06-01

### Shipped
- **feat: tier-3 callout shake animation — horizontal shake on first banner appearance**
  - Extracted the inline callout banner VStack from `ExpandedView.activeBody(_:)` into a new `private struct CalloutBanner: View` in `NotchView.swift`.
  - `CalloutBanner` takes `message: String`, `tier: Int`, and `onChat: () -> Void`. All styling previously on the inline block (escalating icon, font size, vertical padding, background color) is preserved identically.
  - `@State private var shakeTrigger: Bool = false` — toggled each time a tier-3 callout fires. SwiftUI's `keyframeAnimator(initialValue:trigger:)` plays the shake sequence whenever `shakeTrigger` changes.
  - Keyframe sequence: `0 → -9 → 9 → -7 → 7 → -4 → 4 → 0` px horizontal offset over ~280ms (8 `LinearKeyframe` steps). Amplitude damps from 9px to 0 giving a natural error-shake feel.
  - `.onChange(of: message, initial: true)` with `initial: true` triggers the shake both on first appearance (via `initial: true`) and if a new tier-3 message replaces the current one while the banner is still visible. Tier 1 and 2 banners are unaffected (condition: `tier >= 3`).
  - `bannerBackground` private computed property consolidates the tier→color switch that was previously `ExpandedView.calloutBackground(tier:)`.
  - No new tests — the shake is purely visual; tier escalation and `calloutTier` state transitions are already covered by `CalloutManagerTests` and `NotchStateTests`.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Possible next improvements:
  - (a) Template management in Settings: a "Templates" tab where users can view, reorder, rename, and delete pinned templates (currently only deletable via the store, no dedicated management UI).
  - (b) Callout escalation persistence across session restore: currently `calloutCount` resets on every `activate()`, so a restored session starts at tier 1. Could persist `calloutCount` in `SessionPersistence` if desired.
  - (c) Empty-day heatmap opacity variation: give days with 0 sessions a subtly different track color (e.g. even lighter or slightly different hue) to make the gap between active and inactive days more pronounced.
  - (d) Keyboard shortcut to start/stop session: e.g. ⌘Return to open the session creation form from the idle notch.

---

## Run 36 — 2026-06-01

### Shipped
- **feat: heatmap column hover tooltip — show sessions and duration on mouseover**
  - Each of the 7 day columns in `WeekHeatmapView` now responds to `.onHover`: when the cursor enters a column, a compact floating label appears 26pt above the bar showing "N sessions · Xh Ym" (e.g. "3 sessions · 1h 30m") or "no sessions" for empty days.
  - Tooltip uses `.regularMaterial` background (`RoundedRectangle` at 4pt radius), 9pt medium font — matches the heatmap's compact aesthetic.
  - Smooth fade via `.transition(.opacity)` + `.animation(.easeInOut(duration: 0.12), value: hoveredIndex)` on the containing HStack.
  - `.zIndex(hoveredIndex == i ? 1 : 0)` on each column ensures the active tooltip floats above neighboring columns without clipping.
  - Extracted `heatmapFormatMinutes(_:)` and `heatmapTooltipText(for:)` as `internal` free functions in `SettingsView.swift` so the pure formatting logic is testable without a view context.
  - **Tests** (`HeatmapTooltipTests`, 11 cases): `formatMinutesZero`, `formatMinutesUnderAnHour`, `formatMinutesExactHour`, `formatMinutesExactTwoHours`, `formatMinutesHoursAndMinutes`, `formatMinutesLargeValue`, `tooltipNoSessions`, `tooltipOneSingular`, `tooltipManyPlural`, `tooltipExactHour`, `tooltipOneSessionExactHour`.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Possible next improvements:
  - (a) Template management in Settings: a "Templates" tab where users can view, reorder, rename, and delete pinned templates (currently only deletable via the store, no dedicated management UI).
  - (b) Tier-3 shake animation: add a brief horizontal shake (keyframe animation) to the tier-3 callout banner on first appearance to make it even harder to ignore.
  - (c) Callout escalation persistence across session restore: currently `calloutCount` resets on every `activate()`, so a restored session starts at tier 1. Could persist `calloutCount` in `SessionPersistence` if desired.
  - (d) Empty-day heatmap opacity variation: give days with 0 sessions a subtly different track color (e.g. even lighter or slightly different hue) to make the gap between active and inactive days more pronounced.

---

## Run 35 — 2026-05-31

### Shipped
- **feat: focus heatmap — 7-column weekly bar chart in History tab**
  - **`DayActivity`** (public, `Sendable`): `date` (start of calendar day), `sessionCount`, `minutes`. Lives in `SessionHistory.swift`.
  - **`weeklyHeatmapData(_:calendar:today:)`** (internal free function): pure computation over `[SessionRecord]`; returns exactly 7 `DayActivity` values for the calendar days `[today-6 … today]`, oldest first. Filters each day by `calendar.isDate(_:inSameDayAs:)`, sums durations. Directly testable without an actor hop.
  - **`SessionHistory.weeklyHeatmap()`**: thin public actor wrapper that calls `weeklyHeatmapData(_load())`.
  - **`WeekHeatmapView`** (private SwiftUI struct in `SettingsView.swift`): 7-column `HStack(alignment: .bottom)`. Each column has a 40pt gray track (`secondary.opacity(0.1)`) with a bottom-aligned `RoundedRectangle` fill proportional to `minutes / maxMinutes`; today's column uses full `accentColor`, past days 45% opacity. Minimum fill of 4pt ensures any day with sessions has a visible bar. 9pt day-abbreviation label (bold for today) sits below each column.
  - **`HistoryTab` integration**: `weeklySection(_:)` replaces `weeklySummaryHeader(_:)`. Shows the existing text summary + streak pill when `weekCount > 0`, then always renders `WeekHeatmapView`. Shown whenever `heatmapDays.count == 7` (populated in `.task`). Heatmap is reloaded alongside `stats` after single-delete, bulk-delete, and clear-all.
  - **Window height**: `SettingsView.frame` bumped `440 → 500` to give the session list adequate room alongside the new ~62pt heatmap section.
  - **Tests** (`WeeklyHeatmapDataTests`, 10 cases): `emptyHistoryReturnsSevenZeroDays`, `alwaysReturnsSeven`, `todaySessionShowsInLastSlot`, `yesterdaySessionShowsInSecondToLastSlot`, `sessionSixDaysAgoShowsInFirstSlot`, `sessionSevenDaysAgoNotIncluded`, `multipleSessionsSameDayAccumulate`, `resultIsOrderedOldestFirst`, `datesAreCalendarDayBoundaries`, `lastSlotIsToday`, `firstSlotIsSixDaysAgo`.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Possible next improvements:
  - (a) Template management in Settings: a "Templates" tab where users can view, reorder, rename, and delete pinned templates (currently only deletable via the store, no dedicated management UI).
  - (b) Tier-3 shake animation: add a brief horizontal shake (keyframe animation) to the tier-3 callout banner on first appearance to make it even harder to ignore.
  - (c) Callout escalation persistence across session restore: currently `calloutCount` resets on every `activate()`, so a restored session starts at tier 1. Could persist `calloutCount` in `SessionPersistence` if desired.
  - (d) Heatmap tooltip: show a small popover with "N sessions · Xh Ym" when hovering over a heatmap column (`.onHover` + `popover`).

---

## Run 34 — 2026-05-31

### Shipped
- **feat: callout escalation — 3 tiers of intensity across a session**
  - **Tier 1** (callouts 1–2): friendly/direct pool ("yo, what are you doing?", "stop.", etc.), 8s auto-dismiss, Sosumi sound — unchanged from before.
  - **Tier 2** (callouts 3–4): stronger language ("this is the third time.", "get back to work. now.", "what are you doing to yourself."), 12s auto-dismiss, Basso sound, deeper red `#B3070E` background.
  - **Tier 3** (callout 5+): harshest messages ("STOP.", "every minute here hurts you.", "I am not letting this slide."), 20s auto-dismiss, Funk sound, near-black red `#800000` background, 19pt heavy font, `exclamationmark.3` icon, 16pt vertical padding — visually unmissable.
  - **`CalloutManager`**: replaced single `callouts: [String]` pool with `tier1Callouts`, `tier2Callouts`, `tier3Callouts` arrays. `currentTier() -> Int` (internal) maps session `calloutCount` → tier (< 2 → 1, < 4 → 2, else 3). `static dismissDelay(for:) -> Duration` (internal) returns escalating durations. `fire()` selects pool by tier; `display(_:tier:)` passes tier to `NotchState.showCallout(_:tier:)` and plays tier-aware `NSSound`.
  - **Bug fix (pre-existing)**: `evaluate(.onTask)` was calling public `reset()` which zeroed `calloutCount`, breaking session-level escalation and causing `calloutCountIncrementPerStreak` to silently produce wrong results. Fixed by extracting private `resetStreak()` (resets `consecutiveOffTask`, `hasFiredForStreak`, cancels auto-dismiss, clears callout) and making `evaluate(.onTask)` call `resetStreak()` instead. Session-level `calloutCount` now survives on-task recovery and only zeroes on explicit `reset()` (called by `SessionManager.activate()`).
  - **`NotchState`**: added `@Published public private(set) var calloutTier: Int = 1`. `showCallout(_:tier:)` takes `tier: Int = 1` (backward-compatible with all existing callers). `clearCallout()` and `collapse()` both reset `calloutTier = 1`.
  - **`NotchWindowController`**: `tier3CalloutExpandedHeight = 280` (vs `calloutExpandedHeight = 260`). `targetFrame` selects it when `state.calloutTier >= 3` so the larger tier-3 banner never clips.
  - **`NotchView`**: `calloutBackground(tier:)` helper on `ExpandedView` returns `Color` darkening by tier. `activeBody(_:)` uses `let tier = state.calloutTier` to conditionally apply bigger icon, font size, and padding for tier 3.
  - **Tests** (`CalloutManagerTests` +6, `NotchStateTests` +4): `onTaskRecoveryPreservesCalloutCount`, `tier1OnFirstCallout`, `tier2OnThirdCallout`, `tier3OnFifthCallout`, `currentTierBoundaries`, `dismissDelayEscalatesWithTier`, `showCalloutDefaultsTierToOne`, `showCalloutWithTierSetsCalloutTier`, `clearCalloutResetsTierToOne`, `collapseResetsTierToOne`.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Possible next improvements:
  - (a) Template management in Settings: a "Templates" tab where users can view, reorder, rename, and delete pinned templates (currently only deletable via the store, no dedicated management UI).
  - (b) Focus heatmap: weekly chart (7 columns, 1 per day) in the History tab showing session count/minutes per day at a glance.
  - (c) Tier-3 shake animation: add a brief horizontal shake (keyframe animation) to the tier-3 callout banner on first appearance to make it even harder to ignore.
  - (d) Callout escalation persistence across session restore: currently `calloutCount` resets on every `activate()`, so a restored session starts at tier 1. Could persist `calloutCount` in `SessionPersistence` if desired.

---

## Run 33 — 2026-05-31

### Shipped
- **feat: running-apps picker in Blocking Settings — add apps without knowing bundle IDs**
  - `RunningAppInfo` (private struct in `SettingsView.swift`): `id` (bundle identifier), `name`, `icon: NSImage?`. Used as the list model for the picker.
  - `RunningAppsPickerView` (private struct in `SettingsView.swift`): SwiftUI popover content. On `.task`, loads `NSWorkspace.shared.runningApplications`, filters out Apple system apps (`com.apple.*` prefix), apps already in `Session.defaultBlockedAppBundleIDs`, and deduplicates by bundle ID. Results sorted alphabetically by name. Displays each app's icon (28×28 from `NSRunningApplication.icon`), display name (bold), and bundle ID (caption monospaced). Live search field (name or bundle ID substring match). Apps already in `effectiveBlockedApps` are shown with a greyed "Blocked" capsule and their button is disabled so they can't be double-added. Tapping a non-blocked row calls `SettingsStore.shared.addCustomApp(_:)` and dismisses the popover.
  - `BlockingSettingsTab`: added `@State private var showingAppPicker = false`. A "Pick from running apps…" button row (with `apps.iphone.badge.plus` icon) sits above the manual bundle-ID text field. The `.popover(isPresented: $showingAppPicker, arrowEdge: .bottom)` modifier attaches `RunningAppsPickerView` to the button. Footer text updated to reflect both input paths.
  - No tests added — `loadApps()` delegates entirely to `NSWorkspace.shared.runningApplications` which is environment-dependent and not unit-testable in isolation; the pure filter logic (search matching, duplicate guard) is trivial.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Possible next improvements:
  - (a) Callout escalation: after N callouts in a session, escalate message intensity (louder sound, longer display, stronger language).
  - (b) Template management in Settings: a "Templates" tab where users can view, reorder, rename, and delete pinned templates (currently only deletable via the store, no dedicated management UI).
  - (c) Focus heatmap: weekly chart (7 columns, 1 per day) in the History tab showing session count/minutes per day at a glance.
  - (d) Callout sound: play a short system sound (`NSSound.beep()` or a named sound) when a callout fires, reinforcing the visual alert.

---

## Run 32 — 2026-05-30

### Shipped
- **feat: app blocking via NSWorkspace — immediate callout when a blocked app becomes frontmost**
  - `BlockedApp` (new model, `Sources/AdiCore/Models/BlockedApp.swift`): `id` (bundle identifier) + `name` (display name). `Codable`, `Sendable`, `Identifiable`.
  - `Session.defaultBlockedApps: [BlockedApp]` — 8 apps: Discord, Steam, Twitch, WhatsApp, Telegram, Apple TV, Instagram, Facebook.
  - `Session.defaultBlockedAppBundleIDs: [String]` — derived from `defaultBlockedApps`.
  - `Session.blockedApps: [String]` — bundle IDs stored per-session. Manual `Codable` conformance (`init(from:)` + `encode(to:)`) handles the missing key gracefully for sessions persisted before this field was introduced (falls back to `defaultBlockedAppBundleIDs`).
  - `AppMonitor` (new actor, `Sources/AdiCore/Blocking/AppMonitor.swift`): `@MainActor public final class`. Observes `NSWorkspace.didActivateApplicationNotification` on the main queue. `start(blockedBundleIDs:)` registers the observer; `stop()` removes it. `handle(bundleID:appName:)` checks membership and calls `CalloutManager.shared.fireAppCallout(_:)`. `static func callout(for:) -> String` mixes `%@`-format callouts (embedding the app name) with generic fallbacks — always returns a non-`%@` string.
  - `CalloutManager.fireAppCallout(_:)` — new public method that bypasses the consecutive-frame threshold and fires immediately. Shares the same `display(_:)` helper as the screen-monitor path, so callout count, auto-dismiss, and deduplication all work the same way.
  - `SettingsStore`: added `customBlockedApps: [String]`, `disabledDefaultApps: Set<String>`, `effectiveBlockedApps: [String]`, and CRUD methods `addCustomApp(_:)`, `removeCustomApp(_:)`, `setDefaultApp(_:enabled:)`, `isDefaultAppEnabled(_:)`. Persisted to UserDefaults alongside domain settings.
  - `SessionManager.start(task:successCriteria:)`: passes `SettingsStore.shared.effectiveBlockedApps` to the `Session` init.
  - `SessionManager.activate(_:)`: calls `AppMonitor.shared.start(blockedBundleIDs: Set(s.blockedApps))` after `callout.reset()`.
  - `SessionManager.endSession()` and the failure-rollback path in `start()`: both call `AppMonitor.shared.stop()`.
  - `BlockingSettingsTab` in `SettingsView`: added "Blocked Apps" section (default list with per-app toggles) and "Custom Apps" section (monospaced bundle-ID text field + Add button + delete per row).
  - **Tests** (`AppMonitorTests.swift`, 9 tests): `calloutIsNonEmpty`, `calloutHasNoFormatSpecifier` (30 runs, never leaves `%@`), `calloutWithAppNameEitherContainsNameOrIsGeneric` (30 runs, always from known pool), `calloutPoolCoversNamedAndGenericEntries`, `calloutEmptyAppNameDoesNotCrash`, `calloutSpecialCharAppNameDoesNotCrash`, `defaultBlockedAppsHaveNonEmptyIDs`, `defaultBlockedAppBundleIDsMatchDefaultApps`, `defaultBlockedAppsAreUnique`, `sessionRoundTripPreservesBlockedApps`, `sessionDecodesLegacyJsonWithoutBlockedApps`.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Possible next improvements:
  - (a) Callout escalation: after N callouts in a session, escalate message intensity (louder sound, longer display, stronger language).
  - (b) Template management in Settings: a "Templates" tab or section where users can view, reorder, rename, and delete pinned templates.
  - (c) Focus heatmap: weekly chart (7 columns, 1 per day) in the History tab showing session count/minutes per day at a glance.
  - (d) Running-apps picker in Settings: populate the custom apps list from `NSWorkspace.shared.runningApplications` so users don't need to know bundle IDs.

---

## Run 31 — 2026-05-30

### Shipped
- **feat: session templates — pin and 1-tap launch recurring sessions**
  - `SessionTemplate` (new model): `id`, `task`, `successCriteria`, `useCount`, `lastUsedAt`, `createdAt` — all `Codable`/`Sendable`.
  - `SessionTemplateStore` (new actor): persists to `~/Library/Application Support/Adia/templates.json`. Methods: `add(task:successCriteria:)` (deduplicates on normalized task text, trims to max 10), `delete(id:)`, `recordUse(id:)` (increments count + sets date), `sorted()` (most recently used first).
  - `IdleBody`: loads top-2 sorted templates in `.task(id:)`. Renders a "PINNED" section with compact quick-launch buttons (pin icon + task name + play icon). Tapping a template calls `SessionManager.shared.start(task:successCriteria:)` directly, records the use, and collapses the notch — no form required. Errors shown inline with `templateError` state.
  - `NotchWindowController`: `idleExpandedHeight` now grows by 34pt per pinned template (capped at 2), driven by `NotchState.idleTemplateCount`. Subscribes to `$idleTemplateCount` so the panel resizes automatically when templates load.
  - `NotchState`: `@Published public internal(set) var idleTemplateCount: Int = 0` — set by `IdleBody` after template load, read by controller for height calculation.
  - `SessionCreationFormView`: pin icon toggle button (visible when task field is non-empty). When enabled and Go is tapped, the AI-parsed `task` + `successCriteria` are saved as a template after the session starts.
  - **Tests** (`SessionTemplateTests.swift`): 14 tests — empty load, add/load, delete, dedup on task text, dedup case-insensitive, recordUse increments+sets date, recordUse multiple times, recordUse unknown id, sorted newest-first, sorted puts used before unused, max templates trim, Codable round-trip.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Possible next improvements:
  - (a) Callout escalation: after N callouts in a session, escalate message intensity (louder sound, longer display, stronger language).
  - (b) Template management in Settings: a "Templates" tab or section where users can view, reorder, rename, and delete pinned templates (currently only deletable via the store, no UI for management).
  - (c) App blocking via NSWorkspace: detect when a distracting app (e.g. Discord, Instagram for Mac) becomes frontmost during a session and immediately fire a callout. STACK already lists "NSWorkspace observation for app monitoring" as planned.
  - (d) Focus heatmap: weekly chart (7 columns, 1 per day) in the History tab showing session count/minutes per day at a glance.

---

## Run 30 — 2026-05-30

### Shipped
- **feat: repeat-last-task button in idle notch**
  - `NotchState.startCreating(prefill: String? = nil)` — new parameter stores the task text in a new `@Published sessionCreationPrefill: String?` property. `stopCreating()` and `collapse()` both clear it so stale text never leaks.
  - `SessionCreationFormView.onAppear` reads `state.sessionCreationPrefill` and sets `inputText` if non-empty, pre-filling the creation form.
  - `IdleBody` loads `SessionHistory.shared.load().first` alongside stats in the `.task(id:)` handler. When a prior record exists, renders a subtle "↺ <last task>" button below "Start Session". Tapping it calls `startCreating(prefill: record.task)` so repeat sessions take one tap.
- **feat: persistent CompletionFilter in HistoryTab**
  - Changed `@State private var completionFilter: CompletionFilter = .all` to `@AppStorage("historyCompletionFilter")`. The "All"/"Done"/"Exited" picker now survives Settings-tab reopens.
- **feat: ⌘A keyboard shortcut for Select All in HistoryTab**
  - Added `.keyboardShortcut("a", modifiers: .command)` to the "Select All"/"Deselect All" footer button. Fires only while `isSelectMode == true` (when the button is in the view hierarchy).
- **tests**: 2 new `NotchStateTests` — `startCreatingWithPrefillStoresPrefill`, `stopCreatingClearsIsCreatingAndPrefill`. Updated `collapseResetsAllUIFlags` and `startCreatingSetsIsCreatingAndExpands` to also assert `sessionCreationPrefill == nil`.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Possible next improvements:
  - (a) Session templating: let users save/name common sessions (e.g. "Morning deep work") and pick from a list in the idle notch.
  - (b) `NotchWindowController` idle height: verify `idleExpandedHeight = 220` still gives enough room now that the repeat-last-task button is shown (adds ~26pt; total estimated ~183pt, still under 220).
  - (c) Callout escalation: after N callouts in a session, escalate message intensity or play a louder sound.
  - (d) Integration smoke test on real macOS hardware with `ANTHROPIC_API_KEY`.

---

## Run 29 — 2026-05-29

### Shipped
- **feat: date grouping + Select All in HistoryTab**
  - `DayGroup` (internal, `Identifiable`) — section bucket with `label: String` and `var records: [SessionRecord]`.
  - `dayLabel(for:calendar:now:)` (internal) — returns "Today", "Yesterday", or a locale-aware month+day string. Appends the calendar year only for dates in a prior year (e.g. "January 1, 2024" vs "May 24").
  - `groupedByDay(_:calendar:now:)` (internal) — groups a newest-first record slice into `[DayGroup]` without reordering. Pure function, directly testable.
  - `HistoryTab.List` now uses `ForEach(groupedByDay(filteredRecords))` with a `Section` per group so rows appear under "Today", "Yesterday", "May 24" etc. headers. Applies in both normal and select mode.
  - `allFilteredSelected: Bool` + `toggleSelectAll()` added to `HistoryTab`.
  - "Select All" / "Deselect All" button in select-mode footer (between delete button and "Done") selects/deselects all currently visible (filtered) records.
  - 8 new `@Test` cases in `GroupedByDayTests`: empty, single-today, multi-today collapse, order preserved within group, today+yesterday two sections, past-year label contains year, current-year label omits year, three-day three-section structure.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Possible next improvements:
  - (a) `NotchWindowController` idle height: verify `idleExpandedHeight = 220` is sufficient when both stats line and streak pill are visible simultaneously.
  - (b) Integration smoke test on real macOS hardware with `ANTHROPIC_API_KEY`.
  - (c) Keyboard shortcut (⌘A) to trigger "Select All" in HistoryTab select mode.
  - (d) Persistent filter state: remember the selected `CompletionFilter` across Settings tab re-opens (currently resets to "All" each time).

---

## Run 28 — 2026-05-29

### Shipped
- **feat: multi-select + bulk delete in HistoryTab**
  - `SessionHistory.deleteMultiple(ids: Set<UUID>)` — removes all records in the id set atomically; no-op for empty set or unknown ids.
  - `HistoryTab`: added `isSelectMode: Bool` and `selectedIDs: Set<UUID>` state. A "Select" button appears in the footer (right of "Export CSV…") to enter selection mode.
  - In select mode, each row renders as `SelectableRecordRow` — a compact row with a checkmark-circle (filled when selected, empty when not) + task text + date. Tapping toggles selection via `toggleSelection(_:)`.
  - "Delete N selected" button (red, invisible when nothing is selected) bulk-deletes via `deleteMultiple`, animates rows out, refreshes stats, then auto-exits select mode when the list becomes empty.
  - "Done" button exits select mode and clears `selectedIDs`. "Clear All" confirmation also resets both.
  - `toggleSelection(_:)` and `deleteSelected()` extracted as private helpers.
- **fix: search × also resets completion filter** — tapping the clear (×) button in the search field now resets the "All / Done / Exited" picker back to "All" in addition to clearing `searchText`.
- **tests**: 3 new `@Test` cases — `deleteMultipleRemovesAllSpecified` (2-of-3 deleted, 1 remains), `deleteMultipleNoOpForUnknownIDs` (unknown ids leave records untouched), `deleteMultipleEmptySetIsNoOp` (empty set is a no-op).

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Possible next improvements:
  - (a) Select-all shortcut in HistoryTab select mode (a "Select All" button that adds all `filteredRecords` ids to `selectedIDs`).
  - (b) `NotchWindowController` idle height: verify `idleExpandedHeight = 220` is sufficient when both stats line and streak pill are visible simultaneously.
  - (c) Integration smoke test on real macOS hardware with `ANTHROPIC_API_KEY`.
  - (d) Session date grouping in HistoryTab (group rows by day: "Today", "Yesterday", "May 27", etc.).

---

## Run 27 — 2026-05-29

### Shipped
- **feat: search + completion filter in HistoryTab**
  - `filterRecords(_:query:completed:)` — pure `internal` free function at module scope (directly testable). Case-insensitive substring match across `task`, `successCriteria`, and `note` fields. Optional `Bool?` completion filter is applied first; `nil` means no filter.
  - `HistoryTab.CompletionFilter` — nested enum (`.all` / `.completed` / `.exitedEarly`) with `boolValue: Bool?` that feeds directly into `filterRecords`.
  - `HistoryTab.filteredRecords` — computed property wiring state into the filter; all list render/delete handlers correctly use `filteredRecords` for display while `records` stays as the canonical backing array.
  - `searchFilterBar` — compact `HStack` above the session list: a rounded search field with a live clear (×) button + a `.segmented` Picker showing "All" / "Done" / "Exited". Only shown when there are records.
  - "No matching sessions" empty state (magnifying glass icon + label) renders inside the list area when `filteredRecords` is empty but `records` is not, distinct from the pre-history "No sessions yet" state.
  - 11 new `@Test` cases in a new `FilterRecordsTests` suite: empty query returns all, whitespace-only query returns all, task match case-insensitive, criteria match, note match, no-match → empty, completed filter, exited-early filter, nil filter returns all, combined query+completion filter, empty input → empty.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Possible next improvements:
  - (a) HistoryTab multi-select + bulk delete (shift-click to select a range, then "Delete selected N").
  - (b) `NotchWindowController` idle height: verify `idleExpandedHeight = 220` is sufficient when both stats line and streak pill are visible simultaneously.
  - (c) Integration smoke test on real macOS hardware with `ANTHROPIC_API_KEY`.
  - (d) "Reset search" also resets the completion filter (currently search clear button only clears `searchText`; user must manually click "All" in the picker).

---

## Run 26 — 2026-05-28

### Shipped
- **feat: per-row delete button in HistoryTab expanded detail panel**
  - `SessionRecordRow`: added `onDelete: (() -> Void)? = nil` callback. When `onDelete` is set, a right-aligned "Delete session" trash button appears at the bottom of each expanded detail panel (below the note editor field).
  - `HistoryTab`: wires `onDelete:` for every row — calls `await SessionHistory.shared.delete(id:)`, animates the row out of `records`, collapses `expandedRecordID` if it was that row, then refreshes `stats` from the actor so the weekly summary header stays accurate.
  - 2 new `SessionHistoryTests`: `deleteUpdatesStats` (confirms `todayCount`/`weekCount` drop after deleting one of two today-sessions) and `deleteLastRecordYieldsZeroStats` (confirms zeros and empty list after removing the only record).

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Possible next improvements:
  - (a) HistoryTab multi-select + bulk delete (shift-click range, then "Delete selected").
  - (b) `NotchWindowController` idle height: verify `idleExpandedHeight = 220` is sufficient when both stats line and streak pill are visible simultaneously.
  - (c) Integration smoke test on real macOS hardware with `ANTHROPIC_API_KEY`.
  - (d) Search/filter in HistoryTab (filter by task text or date range).

---

## Run 25 — 2026-05-28

### Shipped
- **feat: per-session notes — annotate completed sessions from History tab**
  - `SessionRecord`: added `note: String?` (var, optional, defaults `nil`). Backward-compatible: synthesised `Codable` uses `decodeIfPresent` for optional fields, so existing `history.json` records decode cleanly with `note == nil`.
  - `SessionHistory`: added `updateNote(id:note:)` — trims whitespace, writes `nil` for empty/whitespace-only input; also added `delete(id:)` for single-record removal.
  - `SettingsView / SessionRecordRow`: inline note editor appears at the bottom of each expanded detail panel. Shows `"Add a note…"` placeholder when empty. Commits on Return (`onSubmit`) or focus loss (`onChange(of: noteFocused)`). `HistoryTab` wires `onNoteChange:` to both persist via `SessionHistory.shared` and immediately update the local `records` array.
  - CSV export updated to include a Note column.
  - 10 new `SessionHistoryTests` covering: set note, trim whitespace, clear by empty string, no-op on unknown id, multi-record isolation, `delete(id:)`, and Codable note round-trip (nil and non-nil).

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Possible next improvements:
  - (a) Per-row delete in HistoryTab (swipe-to-delete or trash button in expanded detail), wired to the new `SessionHistory.delete(id:)`.
  - (b) HistoryTab multi-select + bulk delete (shift-click range, then "Delete selected").
  - (c) `NotchWindowController` idle height: verify `idleExpandedHeight = 220` is sufficient when both stats line and streak pill are visible simultaneously.
  - (d) Integration smoke test on real macOS hardware with `ANTHROPIC_API_KEY`.

---

## Run 24 — 2026-05-27

### Shipped
- **feat: Expandable session detail rows in HistoryTab**
  - `SessionRecordRow` — added `isExpanded: Bool` and `onTap: () -> Void` params. Summary row now shows a `chevron.up/down` affordance next to the date. Tapping anywhere on the summary row toggles an inline detail panel below it.
  - Detail panel shows: full task text (no line limit), success criteria, start/end times (`.abbreviated` date + `.shortened` time), duration, callout count. All fields use a `detailField` helper with a small uppercase label + readable value text.
  - `HistoryTab` — added `@State private var expandedRecordID: UUID?`; accordion behaviour (one row open at a time); `expandedRecordID` is also reset to `nil` on "Clear All" so a cleared list starts fresh.
  - Animation: `.easeOut(0.18s)` + `.opacity.combined(with: .move(edge: .top))` transition for smooth open/close.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Possible next improvements:
  - (a) Integration smoke test on real macOS hardware with `ANTHROPIC_API_KEY`.
  - (b) `NotchWindowController` idle height: `idleExpandedHeight = 220` — verify it's sufficient when both stats line and streak pill are visible simultaneously.
  - (c) HistoryTab multi-select + bulk delete (shift-click range, then "Delete selected").
  - (d) Per-session notes field: let the user annotate a completed session with a short note stored in `SessionRecord`.

---

## Run 23 — 2026-05-27

### Shipped
- **feat: Clear history button + week-framing in idle notch stats**
  - `SettingsView.HistoryTab` — added "Clear All" button in the footer bar (left of "Export CSV…"). Tapping it shows a native `.alert` confirmation with a destructive "Clear" action and a count ("delete all 7 session records"). On confirm: calls `SessionHistory.shared.clear()` and resets local `records`/`stats` state so the tab immediately shows the empty state. Button action wrapped in `Task { @MainActor in ... }` for Swift 6 safety.
  - `IdleBody` (`NotchView.swift`) — changed stats visibility guard from `s.todayCount > 0` to `s.todayCount > 0 || s.weekCount > 0`. On days with no sessions yet, the idle notch now shows "X sessions this week · Xh Ym" framing (e.g. "3 sessions this week · 2h 30m") so users see meaningful momentum even before starting their first session of the day.
  - `idleStatsSummary(_:)` — extracted as a module-level `internal` free function (was a private method on `IdleBody`) so it is directly testable. Today framing: "N session(s) · Xh Ym". Week framing when `todayCount == 0`: "N session(s) this week · Xh Ym".
  - Tests: `IdleStatsSummaryTests` (+9 cases in `SessionHistoryTests.swift`) — covers today singular/plural, today with minutes/hours/exact-hour, week fallback singular/plural, week fallback with time, all-zeros edge case (no crash).

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Possible next improvements:
  - (a) Integration smoke test on real macOS hardware with `ANTHROPIC_API_KEY`.
  - (b) `NotchWindowController` idle height: `idleExpandedHeight = 220` — verify it's sufficient when both stats line and streak pill are visible simultaneously (rare layout where streak > 1 wraps).
  - (c) Session detail view in HistoryTab: tap a row to expand it showing full task, success criteria, callout transcript summary.

---

## Run 22 — 2026-05-26

### Shipped
- **feat: Weekly stats, idle streak badge, stats reload fix**
  - `SessionStats` — added `weekCount` (sessions started in the current calendar week) and `weekMinutes` (focused minutes this week), computed via `Calendar.isDate(_:equalTo:toGranularity:.weekOfYear)` so locale-aware week start is respected. All three `SessionStats` return points in `stats()` updated.
  - `CollapsedView` (`NotchView.swift`) — when `session.session == nil` and `idleStreak > 1`, the collapsed notch pill now shows a `"🔥 Nd"` badge next to the status dot (motivational streak indicator). Loaded via `.task(id: session.session?.id)` so it refreshes each time a session ends, even if the pill was already visible.
  - `IdleBody` (`NotchView.swift`) — bug fix: changed bare `.task { ... }` to `.task(id: session.session?.id) { ... }` so stats (today count, minutes, streak) re-load after a session ends while the notch panel is already expanded. Previously stats could be stale until the panel was collapsed and reopened.
  - `SettingsView.HistoryTab` — added a compact weekly summary header above the session list. Displays `"N sessions this week · Xh Ym"` plus an optional `"🔥 Nd streak"` pill. Only shown when `weekCount > 0`. Stats loaded alongside records in the existing `.task`.
  - Tests: `statsWeekCountAndMinutes` — inserts a today session + a 2-day-old session, uses `cal.isDate(_:equalTo:toGranularity:.weekOfYear)` to determine expected weekCount (1 or 2 depending on week boundary), asserts `weekMinutes >= 60`. `statsWeekIgnoresSessionsFromLastWeek` — 10-day-old session yields `weekCount == 0` and `weekMinutes == 0`.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Possible next improvements:
  - (a) `weekCount`/`weekMinutes` in the idle notch stats line (currently shows today-only); could switch to "this week" framing if `todayCount == 0` but `weekCount > 0`.
  - (b) HistoryTab: "Clear history" button with confirmation (currently only export is available; no way to wipe).
  - (c) `NotchWindowController` idle height might need bumping if the streak pill in `IdleBody` ever wraps (current `idleExpandedHeight = 220`).
  - (d) Integration smoke test on real macOS hardware with `ANTHROPIC_API_KEY`.

---

## Run 21 — 2026-05-26

### Shipped
- **feat: Idle notch stats, CSV export, session streak**
  - `SessionStats` (public, Sendable) — snapshot of `todayCount`, `todayMinutes`, `streak` (consecutive calendar days with ≥1 session ending at the most recent active day, including yesterday if today has none).
  - `SessionHistory.stats()` — computes the snapshot synchronously inside the actor from the on-disk record list; streak walks backward from today (or yesterday) using a `Set<Date>` of calendar-day starts.
  - `IdleBody` (new private SwiftUI struct in `NotchView.swift`) — replaces the inline `idleBody` computed property in `ExpandedView`; loads stats async via `.task`; when `todayCount > 0` shows a compact `"N sessions · Xh Ym"` line with optional `"🔥 Nd streak"` pill above the Start Session button.
  - `NotchWindowController` — `idleExpandedHeight = 220` (vs `expandedHeight = 190` for active session); `targetFrame` now checks `SessionManager.shared.session == nil` to select the idle height; new `SessionManager.shared.$session` Combine sink triggers reposition on session start/end so the panel resizes correctly when transitioning between idle and active states.
  - `SettingsView.HistoryTab` — "Export CSV…" button (only when history is non-empty) opens `NSSavePanel` and writes a UTF-8 CSV with columns `Date,Task,Success Criteria,Duration (min),Completed,Callouts`.
  - Tests: 6 new cases in `SessionHistoryTests` for `stats()` — empty→zeros, todayCount+minutes, old sessions ignored, streak single day, streak two consecutive days, streak broken by 1-day gap.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Remaining gap is hardware-only: (1) integration smoke test on a real macOS machine with `ANTHROPIC_API_KEY`; (2) UX test of notch panel on a MacBook with a physical notch.
- Possible next improvements: (a) `NotchState.$isShowingStats` publish so `IdleBody` stats reload after a session ends even if the panel was already expanded; (b) streak badges on the collapsed pill for motivation; (c) weekly summary in the History tab header.

---

## Run 20 — 2026-05-26

### Shipped
- **feat: Session history tracking** — All 14 GOAL.md items were already complete; added the first post-checklist feature: every session (verified or early-exit) is now recorded to `~/Library/Application Support/Adia/history.json`.
  - `SessionRecord` — Codable, Sendable model: task, successCriteria, startTime, endTime, completedSuccessfully, calloutCount.
  - `SessionHistory` actor — prepends records newest-first, caps at 50, uses `.atomic` writes; internal `init(fileURL:)` constructor enables test isolation.
  - `CalloutManager.calloutCount` — public property incremented in `fire()`, zeroed in `reset()`.
  - `SessionManager.endSession()` — reads `callout.calloutCount` and builds a `SessionRecord` before teardown; `sessionEndedSuccessfully` flag is set in `verifyAndEnd()` when Claude confirms task completion.
  - `SettingsView` — new "History" tab (`SessionRecordRow`: ✓/↩ icon, task text, formatted duration, callout count badge, date). Window height bumped 400→440.
  - Tests: `SessionHistoryTests` (10 cases: round-trip, ordering, field preservation, cap-at-50, cap-keeps-newest, clear, duration, accumulation) + 4 new `CalloutManagerTests` for `calloutCount` increment/reset behaviour.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. History feature shipped as bonus.
- Remaining gap is hardware-only: (1) integration smoke test on a real macOS machine with `ANTHROPIC_API_KEY`; (2) UX test of notch panel on a MacBook with a physical notch.
- Possible next improvements: (a) session stats summary card on the main notch idle screen; (b) streak counter ("3 sessions today"); (c) export history as CSV from Settings.

---

## Run 19 — 2026-05-25

### Shipped
- **Fix: `SessionManager.start()` partial-state rollback** — When `activate()` throws (only possible path: `captureManager.start()` raising `CaptureError.permissionDenied` or `.noDisplayFound`), the prior code left `session` set and the session saved to `SessionPersistence`. On next launch `restoreIfNeeded()` would then try to restore a session that never fully started. Fix: wrapped `activate()` in a do/catch that rolls back all side effects — clears `session`, `persistence`, `captureManager.onFrame`, detaches `detector`, stops `LocalBlockServer`, and calls `hosts.unblockAll()` (since `hosts.block()` may have succeeded before `captureManager.start()` threw).
- **Fix: `SessionCreationFormView` silent failure** — When `start()` threw, `isStarting` reset and the form re-enabled, but nothing told the user what went wrong. Added `@State private var startError: String?`; specific catch for `CaptureError.permissionDenied` shows "Screen Recording permission required. Grant it in System Settings → Privacy."; generic catch shows "Couldn't start session. Try again." Error appears inline below the button row with an animated `.opacity` transition. `startError` is cleared on each new attempt.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Remaining gaps are hardware-only: (1) integration smoke test on a real macOS machine with `ANTHROPIC_API_KEY`; (2) UX test of the notch panel on a MacBook with a physical notch.

---

## Run 18 — 2026-05-25

### Shipped
- **Fix: `LocalBlockServer` data race** — `taskDescription` was a `var` set on `@MainActor` (in `start()`) but read on `serverQueue` (in `handle()` → `blockedHTML()`). With `@unchecked Sendable`, the compiler doesn't catch this. Fixed by capturing `taskDescription` as a local `let` constant (`capturedTask`) in `start()` before the `newConnectionHandler` closure, then threading it through `handle(_:taskDescription:)` and `blockedHTML(domain:taskDescription:)` as explicit parameters. `self.taskDescription` is kept for potential future reads on the main actor but is no longer accessed from `serverQueue`.
- **Fix: `CalloutManager` callout deduplication** — `fire()` previously called `randomElement()` on the full 10-item callout pool, giving a 10% chance of repeating the same message in consecutive independent off-task streaks (e.g. user goes off-task, comes back, immediately goes off again). Added `private var lastFiredMessage: String?`: `fire()` now filters `lastFiredMessage` from the candidate pool before `randomElement()`, making back-to-back identical callouts impossible. `reset()` clears `lastFiredMessage` so sessions start with a fresh pool.
- **Fix: `MessageBubble.cleanedContent` empty bubble** — When Claude responded with exactly `[ACCESS GRANTED]` or `[ACCESS DENIED]` and no surrounding text (valid per the system prompt but rare), stripping the token produced `""`, rendering a visible but blank message bubble. Added a contextual fallback: content containing `[ACCESS GRANTED]` → `"ok, you're in."`; `[ACCESS DENIED]` → `"no."`. Normal responses where the token is appended to explanation text are unaffected.
- **Test: `consecutiveStreaksDoNotRepeatCallout`** — New `@Test` in `CalloutManagerTests` fires two independent off-task streaks (with `reset()` between them) and asserts the two callout messages are different, providing a deterministic regression guard for the deduplication logic.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Remaining gaps are hardware-only: (1) integration smoke test on a real macOS machine with `ANTHROPIC_API_KEY`; (2) UX test of the notch panel on a MacBook with a physical notch.

---

## Run 17 — 2026-05-24

### Shipped
- **Fix: `SessionManager.whitelist(domain:)` deduplication** — Calling `whitelist(domain:)` twice with the same domain previously appended the domain twice to `whitelistedDomains`. A second call with `"reddit.com"` would produce `["reddit.com", "reddit.com"]`, meaning `HostsFileManager` would attempt to write duplicate `/etc/hosts` entries on the second unblock and the whitelist UI could show duplicate chips. Fixed by adding `guard !s.whitelistedDomains.contains(base) else { return }` before the `append`. The `blockedDomains.removeAll` after it was already idempotent, so no change needed there.
- **Fix: Force-unwrap comment on `ClaudeClient.baseURL`** — Quality rule: no force unwraps without an explaining comment. `URL(string: "https://...")!` is safe for a hardcoded string literal but violated the rule. Added `// hardcoded constant — URL(_:) always succeeds`.
- **Tests: `whitelistDeduplicatesDuplicateDomain`** — New test in `SessionManagerTests` verifies that calling `whitelist(domain:)` twice with `"reddit.com"` results in exactly one entry in `whitelistedDomains`, not two.
- **Tests: `elapsedReflectsStartTime`** — New test in `SessionModelTests` creates a `Session` with `startTime = Date(timeIntervalSinceNow: -60)` and asserts `elapsed ∈ [58, 62]`. The previous `elapsedNonNegative` test only verified the property returned a non-negative value — it could not catch a broken implementation that always returned `0`.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Remaining gaps are hardware-only: (1) integration smoke test on a real macOS machine with `ANTHROPIC_API_KEY`; (2) UX test of the notch panel on a MacBook with a physical notch.

---

## Run 16 — 2026-05-24

### Shipped
- **UX: Auto-focus in `SessionCreationFormView`** — The form previously appeared without focus, forcing the user to click the "WORKING ON" field before typing. Added `@FocusState private var focused: FormField?` and a `FormField` enum (`task`, `criteria`). On `onAppear`, a 300ms Task sleep (letting the slide-up animation settle) requests focus on the task field. Return in the task field moves focus to the criteria field; Return in the criteria field submits the form if `canStart`. Refactored `fieldGroup` from `(label:placeholder:text:multiline:)` to `(label:content:)` using a `@ViewBuilder` closure — the new signature lets `@FocusState` bindings be applied directly on the `TextField`s inside the closure, which the old generic-parameter design made impossible to thread through. Extracted the placeholder `Text` into a `fieldPlaceholder` helper to avoid repetition.
- **Fix: `ScreenCaptureManager.stop()` clears `lastFrame`** — Previously `stop()` set `stream = nil` but left `_lastFrame` pointing at the last captured frame from the ended session. If a new session started and the user immediately tapped "Done" before any new frame arrived, `verifyAndEnd()` would send the stale frame from the *previous* session to Claude for verification. Added `lastFrame = nil` in `stop()` (after `stream = nil`) so each session starts with a clean slate. The `lastFrame` setter is already lock-protected (`NSLock`), so this is safe from the stream queue.
- **Fix: `normalizeDomain` strips URL fragment identifiers** — `example.com#section` was not stripped by the existing path-split (`"/"`) or query-split (`"?"`) logic; it passed through verbatim, producing the syntactically invalid `/etc/hosts` entry `127.0.0.1 example.com#section`. Added `s = s.components(separatedBy: "#").first ?? s` before the port-strip step (fragments cannot appear in domain names, so splitting on `#` is always safe). Three new `@Test` cases in `SettingsStoreTests`: bare fragment, full URL with path+fragment, www+fragment.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. Remaining gaps are hardware-only: (1) integration smoke test on a real macOS machine with `ANTHROPIC_API_KEY`; (2) UX test of the notch panel on a MacBook with a physical notch.

---

## Run 15 — 2026-05-23

### Shipped
- **Refactor: `NotchWindowController` — remove mixed parameter/singleton access** — `targetFrame` previously took boolean parameters (`expanded`, `creating`, `conversation`, `verifying`) for most state but read `NotchState.shared.verificationResult` and `NotchState.shared.calloutMessage` directly, creating an inconsistency where the function's output depended on both its parameters and hidden global state. Refactored: `positionPanel(animate:)` and `targetFrame(screen:)` now take no state parameters and read all sizing state from `NotchState.shared` directly (safe because both are exclusively called from `@MainActor`). The six separate Combine sinks in `observeState()` collapsed into a single shared `reposition` closure, eliminating the pattern where each sink had to re-read the same state it was already receiving.
- **Fix: add `.serialized` to 4 test suites that share mutable `@MainActor` singletons** — `CalloutManagerTests`, `ConversationManagerTests`, `OnTaskDetectorTests`, and `SessionManagerTests` all access their respective singletons across multiple `await MainActor.run` calls within a single test. Without `.serialized`, Swift Testing's default concurrent execution allows two tests to interleave between those calls and race on shared mutable state. `NotchStateTests` already had `.serialized`; applied the same fix to the four remaining suites.

### Blocked
- None.

### Next agent
- All 14 GOAL.md items remain complete. No outstanding code tasks. Remaining gaps are hardware-only: (1) integration smoke test on a real macOS machine with `ANTHROPIC_API_KEY`; (2) UX test of the notch panel on a MacBook with a physical notch.

---

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
