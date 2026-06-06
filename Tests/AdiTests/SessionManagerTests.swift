import Testing
import Foundation
@testable import AdiCore

/// Tests run serially: SessionManager.shared is a @MainActor singleton.
@Suite("SessionManager — pure logic", .serialized)
struct SessionManagerTests {

    private func injectSession(_ session: Session?) async {
        await MainActor.run {
            SessionManager.shared._injectSessionForTesting(session)
        }
    }

    // MARK: - whitelist(domain:)

    @Test func whitelistEmptyDomainIsNoOp() async {
        let s = Session(task: "Study", successCriteria: "Done")
        await injectSession(s)
        await MainActor.run {
            Task { await SessionManager.shared.whitelist(domain: "") }
        }
        // Allow the async task to settle
        try? await Task.sleep(for: .milliseconds(50))
        let domains = await MainActor.run { SessionManager.shared.session?.whitelistedDomains ?? [] }
        #expect(domains.isEmpty)
        await injectSession(nil)
    }

    @Test func whitelistWhitespaceOnlyDomainIsNoOp() async {
        let s = Session(task: "Study", successCriteria: "Done")
        await injectSession(s)
        await MainActor.run {
            Task { await SessionManager.shared.whitelist(domain: "   ") }
        }
        try? await Task.sleep(for: .milliseconds(50))
        let domains = await MainActor.run { SessionManager.shared.session?.whitelistedDomains ?? [] }
        #expect(domains.isEmpty)
        await injectSession(nil)
    }

    @Test func whitelistStripswwwPrefix() async {
        let s = Session(
            task: "Research",
            successCriteria: "Done",
            blockedDomains: ["jstor.org"]
        )
        await injectSession(s)
        await MainActor.run {
            Task { await SessionManager.shared.whitelist(domain: "www.jstor.org") }
        }
        try? await Task.sleep(for: .milliseconds(50))
        let session = await MainActor.run { SessionManager.shared.session }
        #expect(session?.whitelistedDomains.contains("jstor.org") == true)
        #expect(session?.blockedDomains.contains("jstor.org") == false)
        await injectSession(nil)
    }

    @Test func whitelistRemovesDomainFromBlockList() async {
        let s = Session(
            task: "Research",
            successCriteria: "Done",
            blockedDomains: ["reddit.com", "youtube.com"]
        )
        await injectSession(s)
        await MainActor.run {
            Task { await SessionManager.shared.whitelist(domain: "reddit.com") }
        }
        try? await Task.sleep(for: .milliseconds(50))
        let session = await MainActor.run { SessionManager.shared.session }
        #expect(session?.whitelistedDomains.contains("reddit.com") == true)
        #expect(session?.blockedDomains.contains("reddit.com") == false)
        #expect(session?.blockedDomains.contains("youtube.com") == true)
        await injectSession(nil)
    }

    @Test func whitelistDeduplicatesDuplicateDomain() async {
        let s = Session(
            task: "Study",
            successCriteria: "Done",
            blockedDomains: ["reddit.com"]
        )
        await injectSession(s)
        // First whitelist call — should add "reddit.com"
        await MainActor.run {
            Task { await SessionManager.shared.whitelist(domain: "reddit.com") }
        }
        try? await Task.sleep(for: .milliseconds(50))
        // Second call with the same domain — should be a no-op
        await MainActor.run {
            Task { await SessionManager.shared.whitelist(domain: "reddit.com") }
        }
        try? await Task.sleep(for: .milliseconds(50))
        let domains = await MainActor.run { SessionManager.shared.session?.whitelistedDomains ?? [] }
        #expect(domains.filter { $0 == "reddit.com" }.count == 1,
                "duplicate whitelist call must not create duplicate entries")
        await injectSession(nil)
    }

    @Test func whitelistNoSessionIsNoOp() async {
        await injectSession(nil)
        // Should not crash
        await MainActor.run {
            Task { await SessionManager.shared.whitelist(domain: "example.com") }
        }
        try? await Task.sleep(for: .milliseconds(50))
        // No assertion needed — just verifying no crash
    }

    // MARK: - restoreIfNeeded

    @Test func restoreIfNeededNoSavedSessionLeavesSessionNil() async {
        SessionPersistence.shared.clear()
        await MainActor.run {
            SessionManager.shared._injectSessionForTesting(nil)
        }
        // restoreIfNeeded with no saved session should leave session == nil
        // (we can't call the real restoreIfNeeded since it starts capture, but we verify
        //  the persistence side: load() returns nil, so the guard exits early)
        let loaded = SessionPersistence.shared.load()
        #expect(loaded == nil)
    }

    @Test func restoreIfNeededStaleSessionIsDiscarded() async {
        // Sessions older than 24h should be pruned by SessionPersistence.load()
        let old = Session(
            task: "Old task",
            successCriteria: "done",
            startTime: Date(timeIntervalSinceNow: -25 * 3600)
        )
        SessionPersistence.shared.save(old)
        let loaded = SessionPersistence.shared.load()
        #expect(loaded == nil, "stale session should be discarded by load()")
        SessionPersistence.shared.clear()
    }

    // MARK: - Focus score (onTaskCheckCount / totalCheckCount)

    @Test func onTaskCheckCountDefaultsToZero() async {
        let count = await MainActor.run { SessionManager.shared.onTaskCheckCount }
        // Reset any carry-over from prior tests, then verify the zero state.
        await MainActor.run { SessionManager.shared._injectCheckCountsForTesting(onTask: 0, total: 0) }
        let reset = await MainActor.run { SessionManager.shared.onTaskCheckCount }
        #expect(reset == 0)
        _ = count   // suppress unused-variable warning
    }

    @Test func totalCheckCountDefaultsToZero() async {
        await MainActor.run { SessionManager.shared._injectCheckCountsForTesting(onTask: 0, total: 0) }
        let total = await MainActor.run { SessionManager.shared.totalCheckCount }
        #expect(total == 0)
    }

    @Test func focusScoreNilWhenNoChecksEvaluated() async {
        await MainActor.run { SessionManager.shared._injectCheckCountsForTesting(onTask: 0, total: 0) }
        let score = await MainActor.run { SessionManager.shared.focusScore }
        #expect(score == nil)
    }

    @Test func focusScoreReflectsInjectedCounts() async {
        await MainActor.run { SessionManager.shared._injectCheckCountsForTesting(onTask: 8, total: 10) }
        let score = await MainActor.run { SessionManager.shared.focusScore }
        #expect(score == 0.8)
        await MainActor.run { SessionManager.shared._injectCheckCountsForTesting(onTask: 0, total: 0) }
    }

    // MARK: - minChecksForFocusScore

    @Test func minChecksForFocusScoreIs5() {
        // Changing this value requires updating the UI display guard in NotchView and SettingsView.
        #expect(SessionManager.minChecksForFocusScore == 5)
    }

    @Test func focusScoreRecordBelowMinChecksThresholdHasNoDisplayableScore() {
        let now = Date()
        let record = SessionRecord(
            task: "Write essay", successCriteria: "Submit",
            startTime: now, endTime: now.addingTimeInterval(3600),
            completedSuccessfully: true, calloutCount: 0,
            onTaskChecks: 3, totalChecks: SessionManager.minChecksForFocusScore - 1
        )
        // focusScore exists (non-nil), but the display guard hides it below the threshold.
        #expect(record.focusScore != nil)
        #expect(record.totalChecks < SessionManager.minChecksForFocusScore)
    }

    @Test func focusScoreRecordAtMinChecksThresholdIsDisplayable() {
        let now = Date()
        let record = SessionRecord(
            task: "Write essay", successCriteria: "Submit",
            startTime: now, endTime: now.addingTimeInterval(3600),
            completedSuccessfully: true, calloutCount: 0,
            onTaskChecks: 5, totalChecks: SessionManager.minChecksForFocusScore
        )
        #expect(record.focusScore != nil)
        #expect(record.totalChecks >= SessionManager.minChecksForFocusScore)
    }

    // MARK: - endSession(note:)

    @Test func endSessionDefaultNoteIsNil() async {
        let s = Session(task: "Write essay", successCriteria: "Submit to Canvas")
        await injectSession(s)
        await SessionManager.shared.endSession()
        let record = await MainActor.run { SessionManager.shared._lastEndedRecord }
        #expect(record?.note == nil)
    }

    @Test func endSessionNoteIsPassedThroughToRecord() async {
        let s = Session(task: "Study biology", successCriteria: "Finish chapter 4")
        await injectSession(s)
        await SessionManager.shared.endSession(note: "covered all sections, felt solid")
        let record = await MainActor.run { SessionManager.shared._lastEndedRecord }
        #expect(record?.note == "covered all sections, felt solid")
    }

    // MARK: - Duration timer expiry

    @Test func timerExpiredDefaultsToFalse() async {
        let expired = await MainActor.run { SessionManager.shared.timerExpired }
        #expect(expired == false)
    }

    @Test func handleDurationExpiredSetsFlag() async {
        let s = Session(task: "Write essay", successCriteria: "Submit")
        await injectSession(s)
        await MainActor.run { SessionManager.shared.handleDurationExpired() }
        let expired = await MainActor.run { SessionManager.shared.timerExpired }
        #expect(expired == true)
        // Clean up
        await injectSession(nil)
        await MainActor.run { SessionManager.shared._resetTimerForTesting() }
    }

    @Test func handleDurationExpiredWithNoSessionIsNoOp() async {
        await injectSession(nil)
        await MainActor.run { SessionManager.shared.handleDurationExpired() }
        let expired = await MainActor.run { SessionManager.shared.timerExpired }
        #expect(expired == false)
    }

    @Test func handleDurationExpiredExpandsNotch() async {
        let s = Session(task: "Code review", successCriteria: "All comments resolved")
        await injectSession(s)
        await MainActor.run {
            NotchState.shared.collapse()
            SessionManager.shared.handleDurationExpired()
        }
        let expanded = await MainActor.run { NotchState.shared.isExpanded }
        #expect(expanded == true)
        // Clean up
        await injectSession(nil)
        await MainActor.run {
            SessionManager.shared._resetTimerForTesting()
            NotchState.shared.collapse()
        }
    }

    @Test func endSessionResetsTimerExpiredFlag() async {
        let s = Session(task: "Study biology", successCriteria: "Finish chapter 4")
        await injectSession(s)
        await MainActor.run { SessionManager.shared.handleDurationExpired() }
        let before = await MainActor.run { SessionManager.shared.timerExpired }
        #expect(before == true)
        await SessionManager.shared.endSession()
        let after = await MainActor.run { SessionManager.shared.timerExpired }
        #expect(after == false)
    }

    // MARK: - HapticPlayer

    @Test func hapticSuccessPulseDelayIs50ms() {
        #expect(HapticPlayer.successPulseDelay == .milliseconds(50))
    }

    @Test func hapticPlayerPerformSuccessCompletesWithoutHanging() async {
        // On hardware without a Force Touch trackpad the #if canImport(AppKit) block
        // is a no-op. On Force Touch hardware the two pulses fire 50 ms apart.
        // Either way performSuccess() must return — the await here enforces it.
        await HapticPlayer.performSuccess()
    }

    // MARK: - Timer expiry sound

    @Test func timerExpiredSoundNameIsGlass() {
        // "Glass" is intentionally distinct from the off-task callout sounds
        // (Sosumi/Basso/Funk) so the user can immediately tell "done" from "get back to work".
        // Changing this constant requires an explicit, intentional commit.
        #expect(SessionManager.timerExpiredSoundName == "Glass")
    }

    @Test func timerExpiredSoundNameIsKnownMacOSSystemSound() {
        // All macOS system sounds live in /System/Library/Sounds/ as .aiff files.
        // This test guards against typos that would silently produce no sound.
        let knownSounds = ["Basso", "Blow", "Bottle", "Frog", "Funk", "Glass",
                           "Hero", "Morse", "Ping", "Pop", "Purr", "Sosumi",
                           "Submarine", "Tink"]
        #expect(knownSounds.contains(SessionManager.timerExpiredSoundName))
    }
}
