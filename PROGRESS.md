# Adia — Build Progress

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
