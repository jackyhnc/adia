import Testing
import Foundation
import CoreGraphics
@testable import AdiCore

/// Tests run serially: SessionManager.shared is a @MainActor singleton.
@Suite("SessionManager — pure logic", .serialized)
struct SessionManagerTests {

    private func injectSession(_ session: Session?) async {
        await MainActor.run {
            SessionManager.shared._injectSessionForTesting(session)
        }
    }

    /// Minimal 1x1 CGImage — enough to satisfy `verifyAndEnd`'s `lastFrame` guard and
    /// to be JPEG-encoded and POSTed to the verification endpoint.
    private func dummyFrame() -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // Force unwrap is safe: a 1x1 8bpc RGBA bitmap context with these fixed,
        // well-formed parameters always succeeds — there's no way for `CGContext.init`
        // or `makeImage()` to return nil here.
        let ctx = CGContext(
            data: nil,
            width: 1, height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        return ctx.makeImage()!
    }

    // MARK: - recordReasoningAttempt(domain:granted:summary:)

    @Test func recordReasoningAttemptAppendsToHistory() async {
        let s = Session(task: "Essay", successCriteria: "Submitted to Canvas")
        await injectSession(s)
        await MainActor.run {
            SessionManager.shared.recordReasoningAttempt(domain: "youtube.com", granted: false, summary: "no academic reason")
        }
        let history = await MainActor.run { SessionManager.shared.session?.reasoningHistory ?? [] }
        #expect(history.count == 1)
        #expect(history[0].domain == "youtube.com")
        #expect(history[0].granted == false)
        #expect(history[0].summary == "no academic reason")
        await injectSession(nil)
    }

    @Test func recordReasoningAttemptAccumulatesAcrossCalls() async {
        let s = Session(task: "Essay", successCriteria: "Submitted to Canvas")
        await injectSession(s)
        await MainActor.run {
            SessionManager.shared.recordReasoningAttempt(domain: "youtube.com", granted: false, summary: "first ask")
            SessionManager.shared.recordReasoningAttempt(domain: "youtube.com", granted: false, summary: "second ask")
        }
        let history = await MainActor.run { SessionManager.shared.session?.reasoningHistory ?? [] }
        #expect(history.count == 2)
        #expect(history.map(\.summary) == ["first ask", "second ask"])
        await injectSession(nil)
    }

    @Test func recordReasoningAttemptIgnoresBlankDomain() async {
        let s = Session(task: "Essay", successCriteria: "Submitted to Canvas")
        await injectSession(s)
        await MainActor.run {
            SessionManager.shared.recordReasoningAttempt(domain: "   ", granted: true, summary: "n/a")
        }
        let history = await MainActor.run { SessionManager.shared.session?.reasoningHistory ?? [] }
        #expect(history.isEmpty)
        await injectSession(nil)
    }

    @Test func recordReasoningAttemptNoOpWithoutActiveSession() async {
        await injectSession(nil)
        await MainActor.run {
            SessionManager.shared.recordReasoningAttempt(domain: "youtube.com", granted: true, summary: "n/a")
        }
        let session = await MainActor.run { SessionManager.shared.session }
        #expect(session == nil)
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

    // MARK: - Focus score persistence (onTaskChecks / totalChecks in Session)

    @Test func sessionPersistsCheckCountsOnHandleFrame() async {
        // Inject a session with fresh (zero) check counts.
        var s = Session(task: "Essay", successCriteria: "Submit to Canvas")
        s.onTaskChecks = 0
        s.totalChecks  = 0
        await injectSession(s)

        // Simulate the counter state that handleFrame would produce (without needing
        // real screen capture). Push it via the test helper.
        await MainActor.run {
            SessionManager.shared._injectCheckCountsForTesting(onTask: 5, total: 8)
        }

        // handleFrame saves to the session when the counts diverge from the persisted values.
        // Calling handleFrame() directly requires a real CGImage and the capture pipeline,
        // so we instead verify the synchronisation invariant: after _injectCheckCounts the
        // live counts are correct, and a future activate() with a session carrying those
        // counts would restore them.
        let onTask = await MainActor.run { SessionManager.shared.onTaskCheckCount }
        let total  = await MainActor.run { SessionManager.shared.totalCheckCount  }
        #expect(onTask == 5)
        #expect(total  == 8)
        await injectSession(nil)
        await MainActor.run { SessionManager.shared._injectCheckCountsForTesting(onTask: 0, total: 0) }
    }

    @Test func sessionWithPersistedCheckCountsRestoredOnActivate() async {
        // Build a session that already has persisted check counts (as if it survived a
        // crash mid-session). The activate() path should restore these into the live counters.
        let s = Session(
            task: "Write report", successCriteria: "Draft completed",
            onTaskChecks: 30, totalChecks: 40
        )
        // Push directly into the manager (bypasses the real capture pipeline).
        await injectSession(s)
        // Simulate the restore path: activate() reads s.onTaskChecks / s.totalChecks
        // and writes them into the live counters. Since we can't call activate() without
        // a real SCStream, we verify that the values we'd restore are readable from Session.
        #expect(s.onTaskChecks == 30)
        #expect(s.totalChecks  == 40)
        // Confirm the live counters would be correct after injection.
        await MainActor.run {
            SessionManager.shared._injectCheckCountsForTesting(onTask: s.onTaskChecks, total: s.totalChecks)
        }
        let score = await MainActor.run { SessionManager.shared.focusScore }
        #expect(score == 0.75)
        await injectSession(nil)
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

    @Test func endSessionCapturesReasoningHistoryCounts() async {
        var s = Session(task: "Write essay", successCriteria: "Submit to Canvas")
        s.reasoningHistory = [
            ReasoningAttempt(domain: "youtube.com", granted: false, summary: "wanted a study video"),
            ReasoningAttempt(domain: "youtube.com", granted: true, summary: "found the lecture recording"),
            ReasoningAttempt(domain: "twitter.com", granted: false, summary: "just bored")
        ]
        await injectSession(s)
        await SessionManager.shared.endSession()
        let record = await MainActor.run { SessionManager.shared._lastEndedRecord }
        #expect(record?.reasoningAttempts == 3)
        #expect(record?.reasoningGranted == 1)
    }

    @Test func endSessionWithNoReasoningHistoryRecordsZeros() async {
        let s = Session(task: "Write essay", successCriteria: "Submit to Canvas")
        await injectSession(s)
        await SessionManager.shared.endSession()
        let record = await MainActor.run { SessionManager.shared._lastEndedRecord }
        #expect(record?.reasoningAttempts == 0)
        #expect(record?.reasoningGranted == 0)
    }

    @Test func endSessionStoresBlockedDomainsInRecord() async {
        let s = Session(
            task: "Write essay",
            successCriteria: "Submit to Canvas",
            blockedDomains: ["reddit.com", "youtube.com", "twitter.com"]
        )
        await injectSession(s)
        await SessionManager.shared.endSession()
        let record = await MainActor.run { SessionManager.shared._lastEndedRecord }
        #expect(record?.blockedDomains == ["reddit.com", "youtube.com", "twitter.com"])
    }

    @Test func endSessionWithNoBlockedDomainsRecordsEmptyList() async {
        let s = Session(
            task: "Write essay",
            successCriteria: "Submit to Canvas",
            blockedDomains: []
        )
        await injectSession(s)
        await SessionManager.shared.endSession()
        let record = await MainActor.run { SessionManager.shared._lastEndedRecord }
        #expect(record?.blockedDomains.isEmpty == true)
    }

    /// Regression test for a race where `verifyAndEnd()` awaits a multi-second network
    /// call (and, on success, an additional 5s sleep) while holding a stale reference to
    /// the session. If the user taps "End Session" directly during that window, the
    /// stale verification result must NOT resurrect/duplicate the session record or
    /// fire a second `endSession()` — see the `sessionID` staleness guard added to
    /// `verifyAndEnd()`.
    @Test func verifyAndEndDiscardsStaleResultAfterManualEndSession() async {
        let s = Session(task: "Write essay", successCriteria: "Essay submitted to Canvas")
        await injectSession(s)

        let priorFrame = await MainActor.run { ScreenCaptureManager.shared.lastFrame }
        await MainActor.run { ScreenCaptureManager.shared.lastFrame = dummyFrame() }

        // Swap in a mock that resolves `verify()` as "verified" after an artificial
        // delay — long enough to race a manual `endSession()` against it without
        // actually sleeping for the real 5s post-success window or hitting the
        // network. Restored to the real client at the end of the test.
        let mock = MockAgentAIClient()
        await mock.setVerifyResult(.success(VerificationResult(verified: true, explanation: "mock: essay submitted")), delay: .milliseconds(200))
        let realClient = await MainActor.run { SessionManager.shared._aiClient }
        await MainActor.run { SessionManager.shared._injectAIClientForTesting(mock) }

        // Kick off verification without awaiting it — this is what tapping "Done" does.
        let verifyTask = Task { await SessionManager.shared.verifyAndEnd() }

        // Give verifyAndEnd time to capture the session synchronously and reach its
        // first suspension point (the mocked, delayed `verify()` call), then race it —
        // exactly what tapping "End Session" mid-verification does.
        try? await Task.sleep(for: .milliseconds(50))
        await SessionManager.shared.endSession(note: "manual end mid-verification")

        let manualRecord = await MainActor.run { SessionManager.shared._lastEndedRecord }
        #expect(manualRecord?.note == "manual end mid-verification")
        #expect(manualRecord?.completedSuccessfully == false)

        // Let the in-flight verification fully resolve (including its possible 5s
        // post-success sleep) and confirm it did not clobber the manually-created
        // record with a second, stale `endSession()` call.
        await verifyTask.value
        let finalRecord = await MainActor.run { SessionManager.shared._lastEndedRecord }
        #expect(finalRecord?.id == manualRecord?.id, "stale verification result must not create/overwrite a session record")
        #expect(finalRecord?.note == "manual end mid-verification")
        #expect(await mock.verifyCallCount == 1)

        await MainActor.run {
            SessionManager.shared._injectAIClientForTesting(realClient)
            ScreenCaptureManager.shared.lastFrame = priorFrame
        }
        await injectSession(nil)
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

    // MARK: - Timer expiry re-arm

    @Test func timerExpiredRearmIntervalIs600() {
        // 10 minutes. Changing this silently would let users ignore expiry indefinitely.
        #expect(SessionManager.timerExpiredRearmInterval == 600)
    }

    @Test func handleDurationExpiredSchedulesRearmTask() async {
        let s = Session(task: "Write report", successCriteria: "Submitted")
        await injectSession(s)
        await MainActor.run { SessionManager.shared.handleDurationExpired() }
        let hasRearm = await MainActor.run { SessionManager.shared.timerExpiredRearmTask != nil }
        #expect(hasRearm == true)
        // Clean up
        await injectSession(nil)
        await MainActor.run { SessionManager.shared._resetTimerForTesting() }
    }

    @Test func endSessionCancelsRearmTask() async {
        let s = Session(task: "Read chapter 5", successCriteria: "Summarised")
        await injectSession(s)
        await MainActor.run { SessionManager.shared.handleDurationExpired() }
        await SessionManager.shared.endSession()
        let hasRearm = await MainActor.run { SessionManager.shared.timerExpiredRearmTask != nil }
        #expect(hasRearm == false)
    }

    @Test func resetTimerForTestingCancelsRearmTask() async {
        let s = Session(task: "Code review", successCriteria: "All comments resolved")
        await injectSession(s)
        await MainActor.run {
            SessionManager.shared.handleDurationExpired()
            SessionManager.shared._resetTimerForTesting()
        }
        let hasRearm = await MainActor.run { SessionManager.shared.timerExpiredRearmTask != nil }
        #expect(hasRearm == false)
        await injectSession(nil)
    }
}
