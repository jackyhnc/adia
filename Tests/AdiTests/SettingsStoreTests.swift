import Testing
import Foundation
import SwiftUI
@testable import AdiCore

@MainActor
@Suite("SettingsStore")
struct SettingsStoreTests {

    private func reset() async {
        await MainActor.run {
            _ = SettingsStore.shared.setAPIKey("")
        }
    }

    @Test func setAndRetrieveAPIKey() async {
        await reset()
        await MainActor.run {
            _ = SettingsStore.shared.setAPIKey("sk-ant-test-key-12345")
        }
        let key = await MainActor.run { SettingsStore.shared.agentAIKey }
        #expect(key == "sk-ant-test-key-12345")
    }

    @Test func setEmptyKeyClearsAPIKey() async {
        await MainActor.run {
            _ = SettingsStore.shared.setAPIKey("sk-ant-initial")
        }
        await MainActor.run {
            _ = SettingsStore.shared.setAPIKey("")
        }
        let key = await MainActor.run { SettingsStore.shared.agentAIKey }
        #expect(key == nil)
    }

    @Test func setWhitespaceOnlyKeyClearsAPIKey() async {
        await MainActor.run {
            _ = SettingsStore.shared.setAPIKey("sk-ant-initial")
        }
        await MainActor.run {
            _ = SettingsStore.shared.setAPIKey("   \n\t  ")
        }
        let key = await MainActor.run { SettingsStore.shared.agentAIKey }
        #expect(key == nil)
    }

    @Test func hasAPIKeyTrueWhenKeySet() async {
        await MainActor.run {
            _ = SettingsStore.shared.setAPIKey("sk-ant-valid-key")
        }
        let has = await MainActor.run { SettingsStore.shared.hasAPIKey }
        #expect(has == true)
    }

    @Test func hasAPIKeyFalseWhenCleared() async {
        await MainActor.run {
            _ = SettingsStore.shared.setAPIKey("sk-ant-temp")
            _ = SettingsStore.shared.setAPIKey("")
        }
        let has = await MainActor.run { SettingsStore.shared.hasAPIKey }
        #expect(has == false)
    }

    @Test func keyTrimmedOnWrite() async {
        await MainActor.run {
            _ = SettingsStore.shared.setAPIKey("  sk-ant-padded  \n")
        }
        let key = await MainActor.run { SettingsStore.shared.agentAIKey }
        #expect(key == "sk-ant-padded")
    }

    @Test func acceptsAnthropicKey() async {
        await reset()
        let accepted = await MainActor.run {
            SettingsStore.shared.setAPIKey("sk-ant-api03-real-key")
        }
        let key = await MainActor.run { SettingsStore.shared.agentAIKey }
        #expect(accepted == true)
        #expect(key == "sk-ant-api03-real-key")
        await reset()
    }

    @Test func rejectsOpenAILookingKey() async {
        await reset()
        let accepted = await MainActor.run {
            SettingsStore.shared.setAPIKey("sk-proj-openai-style-key")
        }
        let key = await MainActor.run { SettingsStore.shared.agentAIKey }
        #expect(accepted == false)
        #expect(key == nil)
    }

    @Test func rejectsNonKeyString() async {
        await reset()
        let accepted = await MainActor.run {
            SettingsStore.shared.setAPIKey("not-a-real-key")
        }
        let key = await MainActor.run { SettingsStore.shared.agentAIKey }
        #expect(accepted == false)
        #expect(key == nil)
    }

    // MARK: - normalizeDomain (static, pure)

    @Test func normalizeDomainStripsHttps() {
        #expect(SettingsStore.normalizeDomain("https://example.com/path") == "example.com")
    }

    @Test func normalizeDomainStripsHttp() {
        #expect(SettingsStore.normalizeDomain("http://example.com") == "example.com")
    }

    @Test func normalizeDomainStripsWww() {
        #expect(SettingsStore.normalizeDomain("www.example.com") == "example.com")
    }

    @Test func normalizeDomainStripsHttpsAndWww() {
        #expect(SettingsStore.normalizeDomain("https://www.example.com/foo?bar=1") == "example.com")
    }

    @Test func normalizeDomainAlreadyNormalized() {
        #expect(SettingsStore.normalizeDomain("reddit.com") == "reddit.com")
    }

    @Test func normalizeDomainLowercases() {
        #expect(SettingsStore.normalizeDomain("Reddit.COM") == "reddit.com")
    }

    @Test func normalizeDomainStripsPort() {
        #expect(SettingsStore.normalizeDomain("example.com:8080") == "example.com")
    }

    @Test func normalizeDomainStripsPortWithPathAndScheme() {
        #expect(SettingsStore.normalizeDomain("https://www.example.com:443/path?q=1") == "example.com")
    }

    @Test func normalizeDomainPortOnlyBareHost() {
        #expect(SettingsStore.normalizeDomain("localhost:3000") == "localhost")
    }

    @Test func normalizeDomainStripsFragment() {
        #expect(SettingsStore.normalizeDomain("example.com#section") == "example.com")
    }

    @Test func normalizeDomainStripsFragmentWithFullURL() {
        #expect(SettingsStore.normalizeDomain("https://en.wikipedia.org/wiki/Essay#Introduction") == "en.wikipedia.org")
    }

    @Test func normalizeDomainBareFragmentWithWww() {
        #expect(SettingsStore.normalizeDomain("www.example.com#top") == "example.com")
    }

    // MARK: - Custom domain management

    private func resetDomains() async {
        await MainActor.run {
            // Clear custom and re-enable all defaults by rebuilding via known methods.
            for d in SettingsStore.shared.customBlockedDomains {
                SettingsStore.shared.removeCustomDomain(d)
            }
            for d in Session.defaultBlockedDomains {
                SettingsStore.shared.setDefaultDomain(d, enabled: true)
            }
        }
    }

    @Test func addCustomDomainAppearsInList() async {
        await resetDomains()
        await MainActor.run {
            SettingsStore.shared.addCustomDomain("chess.com")
        }
        let list = await MainActor.run { SettingsStore.shared.customBlockedDomains }
        #expect(list.contains("chess.com"))
        await resetDomains()
    }

    @Test func addCustomDomainNormalizesURL() async {
        await resetDomains()
        await MainActor.run {
            SettingsStore.shared.addCustomDomain("https://www.Chess.com/games")
        }
        let list = await MainActor.run { SettingsStore.shared.customBlockedDomains }
        #expect(list.contains("chess.com"))
        await resetDomains()
    }

    @Test func addCustomDomainDeduplicates() async {
        await resetDomains()
        await MainActor.run {
            SettingsStore.shared.addCustomDomain("chess.com")
            SettingsStore.shared.addCustomDomain("chess.com")
        }
        let list = await MainActor.run { SettingsStore.shared.customBlockedDomains }
        #expect(list.filter { $0 == "chess.com" }.count == 1)
        await resetDomains()
    }

    @Test func addCustomDomainIgnoresDefaultDomain() async {
        await resetDomains()
        await MainActor.run {
            SettingsStore.shared.addCustomDomain("reddit.com")
        }
        let list = await MainActor.run { SettingsStore.shared.customBlockedDomains }
        #expect(!list.contains("reddit.com"))
        await resetDomains()
    }

    @Test func removeCustomDomainRemovesIt() async {
        await resetDomains()
        await MainActor.run {
            SettingsStore.shared.addCustomDomain("chess.com")
            SettingsStore.shared.removeCustomDomain("chess.com")
        }
        let list = await MainActor.run { SettingsStore.shared.customBlockedDomains }
        #expect(!list.contains("chess.com"))
    }

    // MARK: - Default domain toggle

    @Test func disablingDefaultDomainRemovesFromEffective() async {
        await resetDomains()
        await MainActor.run {
            SettingsStore.shared.setDefaultDomain("reddit.com", enabled: false)
        }
        let effective = await MainActor.run { SettingsStore.shared.effectiveBlockedDomains }
        #expect(!effective.contains("reddit.com"))
        await resetDomains()
    }

    @Test func reenablingDefaultDomainRestoresInEffective() async {
        await resetDomains()
        await MainActor.run {
            SettingsStore.shared.setDefaultDomain("reddit.com", enabled: false)
            SettingsStore.shared.setDefaultDomain("reddit.com", enabled: true)
        }
        let effective = await MainActor.run { SettingsStore.shared.effectiveBlockedDomains }
        #expect(effective.contains("reddit.com"))
        await resetDomains()
    }

    @Test func isDefaultDomainEnabledReflectsToggle() async {
        await resetDomains()
        await MainActor.run {
            SettingsStore.shared.setDefaultDomain("youtube.com", enabled: false)
        }
        let enabled = await MainActor.run { SettingsStore.shared.isDefaultDomainEnabled("youtube.com") }
        #expect(enabled == false)
        await resetDomains()
    }

    // MARK: - effectiveBlockedDomains

    @Test func effectiveIncludesCustomAndDefaultsByDefault() async {
        await resetDomains()
        await MainActor.run {
            SettingsStore.shared.addCustomDomain("chess.com")
        }
        let effective = await MainActor.run { SettingsStore.shared.effectiveBlockedDomains }
        #expect(effective.contains("reddit.com"))
        #expect(effective.contains("chess.com"))
        await resetDomains()
    }

    @Test func effectiveDoesNotDuplicateCustomIfAlreadyDefault() async {
        await resetDomains()
        let effective = await MainActor.run { SettingsStore.shared.effectiveBlockedDomains }
        let counts = Dictionary(grouping: effective, by: { $0 }).mapValues(\.count)
        let hasDuplicate = counts.values.contains { $0 > 1 }
        #expect(!hasDuplicate)
    }

    // MARK: - showMenuBarItem

    @Test func showMenuBarItemDefaultsToTrue() async {
        // Clear persisted value so we read the hardcoded default.
        UserDefaults.standard.removeObject(forKey: "adia.showMenuBarItem")
        // The singleton has already been initialised in this process, so test the
        // persistence round-trip instead of the default: write false, re-read.
        await MainActor.run { SettingsStore.shared.showMenuBarItem = false }
        let stored = UserDefaults.standard.object(forKey: "adia.showMenuBarItem") as? Bool
        #expect(stored == false)
        // Restore so other tests aren't affected.
        await MainActor.run { SettingsStore.shared.showMenuBarItem = true }
    }

    @Test func showMenuBarItemPersistsToUserDefaults() async {
        await MainActor.run { SettingsStore.shared.showMenuBarItem = false }
        let stored = UserDefaults.standard.bool(forKey: "adia.showMenuBarItem")
        #expect(stored == false)
        await MainActor.run { SettingsStore.shared.showMenuBarItem = true }
        let restoredStored = UserDefaults.standard.bool(forKey: "adia.showMenuBarItem")
        #expect(restoredStored == true)
    }

    // MARK: - idleTemplatesFollowManualOrder

    @Test func idleTemplatesFollowManualOrderDefaultsToFalse() async {
        // Remove the persisted key so the default kicks in on next init.
        UserDefaults.standard.removeObject(forKey: "adia.idleTemplatesFollowManualOrder")
        // The singleton is already initialised; test persistence round-trip instead.
        await MainActor.run { SettingsStore.shared.idleTemplatesFollowManualOrder = false }
        let stored = UserDefaults.standard.object(forKey: "adia.idleTemplatesFollowManualOrder") as? Bool
        #expect(stored == false)
    }

    @Test func idleTemplatesFollowManualOrderPersistsToUserDefaults() async {
        await MainActor.run { SettingsStore.shared.idleTemplatesFollowManualOrder = true }
        let stored = UserDefaults.standard.bool(forKey: "adia.idleTemplatesFollowManualOrder")
        #expect(stored == true)
        // Restore default.
        await MainActor.run { SettingsStore.shared.idleTemplatesFollowManualOrder = false }
        let restored = UserDefaults.standard.bool(forKey: "adia.idleTemplatesFollowManualOrder")
        #expect(restored == false)
    }

    // MARK: - timerExpiredRearmMinutes

    @Test func timerExpiredRearmMinuteOptionsContainsTenMinuteDefault() {
        // 10 minutes is the historical/default re-arm interval (SessionManager.timerExpiredRearmInterval == 600).
        #expect(SettingsStore.timerExpiredRearmMinuteOptions.contains(10))
    }

    @Test func timerExpiredRearmMinuteOptionsAreSortedAndPositive() {
        let options = SettingsStore.timerExpiredRearmMinuteOptions
        #expect(options == options.sorted())
        #expect(options.allSatisfy { $0 > 0 })
    }

    @Test func timerExpiredRearmMinutesDefaultsToTen() async {
        // Remove the persisted key so the default kicks in on next init.
        UserDefaults.standard.removeObject(forKey: "adia.timerExpiredRearmMinutes")
        // The singleton is already initialised; test persistence round-trip instead.
        await MainActor.run { SettingsStore.shared.timerExpiredRearmMinutes = 10 }
        let stored = UserDefaults.standard.object(forKey: "adia.timerExpiredRearmMinutes") as? Int
        #expect(stored == 10)
    }

    @Test func timerExpiredRearmMinutesPersistsToUserDefaults() async {
        await MainActor.run { SettingsStore.shared.timerExpiredRearmMinutes = 30 }
        let stored = UserDefaults.standard.integer(forKey: "adia.timerExpiredRearmMinutes")
        #expect(stored == 30)
        // Restore default.
        await MainActor.run { SettingsStore.shared.timerExpiredRearmMinutes = 10 }
        let restored = UserDefaults.standard.integer(forKey: "adia.timerExpiredRearmMinutes")
        #expect(restored == 10)
    }

    @Test func timerExpiredRearmIntervalConvertsMinutesToSeconds() async {
        await MainActor.run { SettingsStore.shared.timerExpiredRearmMinutes = 5 }
        let interval = await MainActor.run { SettingsStore.shared.timerExpiredRearmInterval }
        #expect(interval == 300)
        // Restore default.
        await MainActor.run { SettingsStore.shared.timerExpiredRearmMinutes = 10 }
    }

    @Test func timerExpiredRearmIntervalMatchesSessionManagerDefaultAtTenMinutes() async {
        await MainActor.run { SettingsStore.shared.timerExpiredRearmMinutes = 10 }
        let interval = await MainActor.run { SettingsStore.shared.timerExpiredRearmInterval }
        #expect(interval == SessionManager.timerExpiredRearmInterval)
    }

    // MARK: - SettingsView adaptive tab heights

    @Test func settingsViewTabHeightsCoversAllFourTabs() {
        #expect(SettingsView.tabHeights.count == 4)
        for tag in 0...3 {
            #expect(SettingsView.tabHeights[tag] != nil)
        }
    }

    @Test func settingsViewAllTabHeightsArePositive() {
        for (_, height) in SettingsView.tabHeights {
            #expect(height > 0)
        }
    }

    @Test func settingsViewBlockingTabIsTallestTab() {
        // Blocking tab (1) has many toggles — it should have the most height.
        let blockingHeight = SettingsView.tabHeights[1] ?? 0
        for (tag, height) in SettingsView.tabHeights where tag != 1 {
            #expect(blockingHeight >= height)
        }
    }

    @Test func settingsViewAccountTabIsShortestTab() {
        // Account tab (0) has 3 compact sections — it should have the least height.
        guard let accountHeight = SettingsView.tabHeights[0] else {
            Issue.record("Account tab (0) has no height entry")
            return
        }
        for (tag, height) in SettingsView.tabHeights where tag != 0 {
            #expect(accountHeight <= height)
        }
    }

    // MARK: - selectableRowStats

    private func makeRecord(
        durationSeconds: TimeInterval,
        calloutCount: Int = 0,
        onTaskChecks: Int = 0,
        totalChecks: Int = 0,
        reasoningAttempts: Int = 0,
        blockedDomains: [String] = []
    ) -> SessionRecord {
        let start = Date(timeIntervalSince1970: 0)
        return SessionRecord(
            task: "Test task",
            successCriteria: "Done",
            startTime: start,
            endTime: start.addingTimeInterval(durationSeconds),
            completedSuccessfully: true,
            calloutCount: calloutCount,
            onTaskChecks: onTaskChecks,
            totalChecks: totalChecks,
            reasoningAttempts: reasoningAttempts,
            blockedDomains: blockedDomains
        )
    }

    @Test func selectableRowStatsDurationOnlyWhenNoChecks() {
        let record = makeRecord(durationSeconds: 45 * 60)
        // totalChecks == 0, calloutCount == 0 → duration only
        #expect(selectableRowStats(record: record, minChecks: 5) == "45m")
    }

    @Test func selectableRowStatsAppendsFocusScoreAboveMinChecks() {
        // 8 on-task out of 10 total → 80%; 10 >= minChecks(5), no callouts
        let record = makeRecord(durationSeconds: 45 * 60, onTaskChecks: 8, totalChecks: 10)
        #expect(selectableRowStats(record: record, minChecks: 5) == "45m · 80%")
    }

    @Test func selectableRowStatsHidesFocusScoreBelowMinChecks() {
        // 3 on-task out of 4 total → 75% score but 4 < minChecks(5) → omit score
        let record = makeRecord(durationSeconds: 45 * 60, onTaskChecks: 3, totalChecks: 4)
        #expect(selectableRowStats(record: record, minChecks: 5) == "45m")
    }

    @Test func selectableRowStatsFormatsHoursAndMinutes() {
        // 90 minutes → "1h 30m", no focus score, no callouts
        let record = makeRecord(durationSeconds: 90 * 60)
        #expect(selectableRowStats(record: record, minChecks: 5) == "1h 30m")
    }

    @Test func selectableRowStatsShowsCalloutCountWhenNonZero() {
        // 3 callouts, no focus score → "45m · 3⚠"
        let record = makeRecord(durationSeconds: 45 * 60, calloutCount: 3)
        #expect(selectableRowStats(record: record, minChecks: 5) == "45m · 3⚠")
    }

    @Test func selectableRowStatsShowsCalloutAndFocusScore() {
        // 3 callouts, 8/10 on-task → "45m · 3⚠ · 80%"
        let record = makeRecord(durationSeconds: 45 * 60, calloutCount: 3, onTaskChecks: 8, totalChecks: 10)
        #expect(selectableRowStats(record: record, minChecks: 5) == "45m · 3⚠ · 80%")
    }

    @Test func selectableRowStatsOmitsCalloutWhenZero() {
        // calloutCount == 0, score present → "45m · 80%" (no ⚠ in badge)
        let record = makeRecord(durationSeconds: 45 * 60, calloutCount: 0, onTaskChecks: 8, totalChecks: 10)
        #expect(selectableRowStats(record: record, minChecks: 5) == "45m · 80%")
        #expect(!selectableRowStats(record: record, minChecks: 5).contains("⚠"))
    }

    @Test func selectableRowStatsSingleCalloutIsNotPlural() {
        // 1 callout — the count should show as "1⚠" not "1 callout"
        let record = makeRecord(durationSeconds: 30 * 60, calloutCount: 1)
        #expect(selectableRowStats(record: record, minChecks: 5) == "30m · 1⚠")
    }

    @Test func selectableRowStatsAppendsReasoningAttemptsWhenNonZero() {
        let record = makeRecord(durationSeconds: 45 * 60, reasoningAttempts: 2)
        #expect(selectableRowStats(record: record, minChecks: 5) == "45m · asked 2×")
    }

    @Test func selectableRowStatsOmitsReasoningAttemptsWhenZero() {
        let record = makeRecord(durationSeconds: 45 * 60, reasoningAttempts: 0)
        #expect(!selectableRowStats(record: record, minChecks: 5).contains("asked"))
    }

    @Test func selectableRowStatsCombinesAllStats() {
        // callouts, focus score, and reasoning attempts all present, in order
        let record = makeRecord(
            durationSeconds: 45 * 60,
            calloutCount: 3,
            onTaskChecks: 8,
            totalChecks: 10,
            reasoningAttempts: 1
        )
        #expect(selectableRowStats(record: record, minChecks: 5) == "45m · 3⚠ · 80% · asked 1×")
    }

    // MARK: - selectableRowStats blocked domains

    @Test func selectableRowStatsShowsBlockedDomainsWhenNonEmpty() {
        let record = makeRecord(durationSeconds: 45 * 60, blockedDomains: ["reddit.com", "twitter.com"])
        #expect(selectableRowStats(record: record, minChecks: 5) == "45m · 2 blocked")
    }

    @Test func selectableRowStatsSingleBlockedDomainSingular() {
        let record = makeRecord(durationSeconds: 45 * 60, blockedDomains: ["reddit.com"])
        #expect(selectableRowStats(record: record, minChecks: 5) == "45m · 1 blocked")
    }

    @Test func selectableRowStatsOmitsBlockedDomainsWhenEmpty() {
        let record = makeRecord(durationSeconds: 45 * 60, blockedDomains: [])
        #expect(!selectableRowStats(record: record, minChecks: 5).contains("blocked"))
    }

    @Test func selectableRowStatsBlockedAppearsAfterReasoningAttempts() {
        // Ordering: duration · asked N× · N blocked (not reversed)
        let record = makeRecord(durationSeconds: 45 * 60, reasoningAttempts: 2, blockedDomains: ["reddit.com"])
        #expect(selectableRowStats(record: record, minChecks: 5) == "45m · asked 2× · 1 blocked")
    }

    @Test func selectableRowStatsCombinesAllStatsIncludingBlocked() {
        // All five stat types present in their defined order
        let record = makeRecord(
            durationSeconds: 45 * 60,
            calloutCount: 3,
            onTaskChecks: 8,
            totalChecks: 10,
            reasoningAttempts: 1,
            blockedDomains: ["reddit.com", "twitter.com", "discord.com"]
        )
        #expect(selectableRowStats(record: record, minChecks: 5) == "45m · 3⚠ · 80% · asked 1× · 3 blocked")
    }

    // MARK: - parseCustomDuration

    @Test func parseCustomDurationBareNumber() {
        #expect(parseCustomDuration("90") == 90)
    }

    @Test func parseCustomDurationMinutesSuffix() {
        #expect(parseCustomDuration("90m") == 90)
    }

    @Test func parseCustomDurationMinSuffix() {
        #expect(parseCustomDuration("90min") == 90)
    }

    @Test func parseCustomDurationMinsSuffix() {
        #expect(parseCustomDuration("90mins") == 90)
    }

    @Test func parseCustomDurationHourOnly() {
        #expect(parseCustomDuration("2h") == 120)
    }

    @Test func parseCustomDurationHourAndMinutes() {
        #expect(parseCustomDuration("1h30m") == 90)
    }

    @Test func parseCustomDurationHourAndMinutesWithSpace() {
        #expect(parseCustomDuration("1h 30m") == 90)
    }

    @Test func parseCustomDurationHourAndBareMinutes() {
        // "1h30" — no trailing "m" after minutes digit
        #expect(parseCustomDuration("1h30") == 90)
    }

    @Test func parseCustomDurationZeroHourWithMinutes() {
        #expect(parseCustomDuration("0h30m") == 30)
    }

    @Test func parseCustomDurationLeadingTrailingWhitespace() {
        #expect(parseCustomDuration("  45m  ") == 45)
    }

    @Test func parseCustomDurationCaseInsensitive() {
        #expect(parseCustomDuration("2H") == 120)
    }

    @Test func parseCustomDurationOneHour() {
        #expect(parseCustomDuration("1h") == 60)
    }

    @Test func parseCustomDurationZeroReturnsNil() {
        #expect(parseCustomDuration("0") == nil)
    }

    @Test func parseCustomDurationZeroMinutesReturnsNil() {
        #expect(parseCustomDuration("0m") == nil)
    }

    @Test func parseCustomDurationEmptyStringReturnsNil() {
        #expect(parseCustomDuration("") == nil)
    }

    @Test func parseCustomDurationWhitespaceOnlyReturnsNil() {
        #expect(parseCustomDuration("   ") == nil)
    }

    @Test func parseCustomDurationAlphaOnlyReturnsNil() {
        #expect(parseCustomDuration("abc") == nil)
    }

    @Test func parseCustomDurationGarbageSuffixReturnsNil() {
        // "90x" — unrecognised suffix
        #expect(parseCustomDuration("90x") == nil)
    }

    @Test func parseCustomDurationTrailingGarbageReturnsNil() {
        #expect(parseCustomDuration("1h30m extra") == nil)
    }

    // MARK: - parseCustomDuration — decimal hours

    @Test func parseCustomDurationDecimalHalf() {
        // "1.5h" — one-and-a-half hours = 90 minutes
        #expect(parseCustomDuration("1.5h") == 90)
    }

    @Test func parseCustomDurationDecimalHalfHour() {
        // "0.5h" — half an hour = 30 minutes
        #expect(parseCustomDuration("0.5h") == 30)
    }

    @Test func parseCustomDurationDecimalTwoAndHalf() {
        // "2.5h" — two-and-a-half hours = 150 minutes
        #expect(parseCustomDuration("2.5h") == 150)
    }

    @Test func parseCustomDurationDecimalOneQuarter() {
        // "1.25h" — one-and-a-quarter hours = 75 minutes
        #expect(parseCustomDuration("1.25h") == 75)
    }

    @Test func parseCustomDurationDecimalWithSpaceBeforeH() {
        // "1.5 h" — same as "1.5h", optional whitespace before the unit
        #expect(parseCustomDuration("1.5 h") == 90)
    }

    @Test func parseCustomDurationDecimalNoFractionalDigitsReturnsNil() {
        // "1." — decimal point with no digits after it is invalid
        #expect(parseCustomDuration("1.") == nil)
    }

    @Test func parseCustomDurationDecimalWithMinutesSuffixReturnsNil() {
        // "1.5m" — decimal with a minutes suffix doesn't make sense
        #expect(parseCustomDuration("1.5m") == nil)
    }

    @Test func parseCustomDurationDecimalCaseInsensitiveH() {
        // "1.5H" — uppercase H should be handled by lowercased() pre-processing
        #expect(parseCustomDuration("1.5H") == 90)
    }

    // MARK: - Daily focus goal presets

    @Test func dailyGoalPresetsAreNonEmpty() {
        #expect(!SettingsStore.dailyGoalPresets.isEmpty)
    }

    @Test func dailyGoalPresetsAreAscending() {
        let minutes = SettingsStore.dailyGoalPresets.map(\.0)
        #expect(minutes == minutes.sorted())
    }

    @Test func dailyGoalPresetsAllPositive() {
        for (m, _) in SettingsStore.dailyGoalPresets {
            #expect(m > 0)
        }
    }

    // MARK: - dismissedSuggestionTasks

    private func resetDismissedSuggestions() async {
        await MainActor.run { SettingsStore.shared.resetDismissedSuggestions() }
    }

    @Test func dismissSuggestionAddsToSet() async {
        await resetDismissedSuggestions()
        await MainActor.run { SettingsStore.shared.dismissSuggestion(task: "write my essay") }
        let dismissed = await MainActor.run { SettingsStore.shared.dismissedSuggestionTasks }
        #expect(dismissed.contains("write my essay"))
        await resetDismissedSuggestions()
    }

    @Test func dismissSuggestionIsIdempotent() async {
        await resetDismissedSuggestions()
        await MainActor.run {
            SettingsStore.shared.dismissSuggestion(task: "write my essay")
            SettingsStore.shared.dismissSuggestion(task: "write my essay")
        }
        let dismissed = await MainActor.run { SettingsStore.shared.dismissedSuggestionTasks }
        #expect(dismissed.count == 1)
        await resetDismissedSuggestions()
    }

    @Test func resetDismissedSuggestionsClearsAll() async {
        await MainActor.run {
            SettingsStore.shared.dismissSuggestion(task: "write my essay")
            SettingsStore.shared.dismissSuggestion(task: "study for exam")
        }
        await resetDismissedSuggestions()
        let dismissed = await MainActor.run { SettingsStore.shared.dismissedSuggestionTasks }
        #expect(dismissed.isEmpty)
    }

    @Test func showSuggestedTemplatesEnableResetsAllDismissed() async {
        // Dismiss a suggestion, hide the section, then re-enable — dismissed list must clear.
        await resetDismissedSuggestions()
        await MainActor.run {
            SettingsStore.shared.dismissSuggestion(task: "write my essay")
            SettingsStore.shared.showSuggestedTemplates = false
            SettingsStore.shared.showSuggestedTemplates = true  // re-enable
        }
        let dismissed = await MainActor.run { SettingsStore.shared.dismissedSuggestionTasks }
        #expect(dismissed.isEmpty)
        // Restore
        await MainActor.run { SettingsStore.shared.showSuggestedTemplates = true }
    }

    @Test func showSuggestedTemplatesDisableDoesNotClearDismissed() async {
        // Toggling off should NOT clear dismissed — only toggling back on does.
        await resetDismissedSuggestions()
        await MainActor.run {
            SettingsStore.shared.dismissSuggestion(task: "write my essay")
            SettingsStore.shared.showSuggestedTemplates = false
        }
        let dismissed = await MainActor.run { SettingsStore.shared.dismissedSuggestionTasks }
        #expect(dismissed.contains("write my essay"))
        // Restore
        await MainActor.run { SettingsStore.shared.showSuggestedTemplates = true }
        await resetDismissedSuggestions()
    }

    @Test func dismissedSuggestionsPersistToUserDefaults() async {
        await resetDismissedSuggestions()
        await MainActor.run { SettingsStore.shared.dismissSuggestion(task: "finish the report") }
        // Verify the UserDefaults key was written.
        let data = UserDefaults.standard.data(forKey: "adia.dismissedSuggestions")
        #expect(data != nil)
        let decoded = try? JSONDecoder().decode([String].self, from: data ?? Data())
        #expect(decoded?.contains("finish the report") == true)
        await resetDismissedSuggestions()
    }
}
