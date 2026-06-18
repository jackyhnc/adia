import Testing
import Foundation
@testable import AdiCore

/// Tests run serially because NotchState.shared is a @MainActor singleton —
/// concurrent access from parallel tests would race on the same published properties.
@Suite("NotchState", .serialized)
struct NotchStateTests {

    private func reset() async {
        await MainActor.run { NotchState.shared.collapse() }
    }

    // MARK: - Expand / collapse / toggle

    @Test func collapseDefaultsToNotExpanded() async {
        await reset()
        let expanded = await MainActor.run { NotchState.shared.isExpanded }
        #expect(expanded == false)
    }

    @Test func expandSetsIsExpanded() async {
        await reset()
        await MainActor.run { NotchState.shared.expand() }
        let expanded = await MainActor.run { NotchState.shared.isExpanded }
        #expect(expanded == true)
    }

    @Test func toggleFlipsExpanded() async {
        await reset()
        await MainActor.run { NotchState.shared.toggle() }
        #expect(await MainActor.run { NotchState.shared.isExpanded } == true)
        await MainActor.run { NotchState.shared.toggle() }
        #expect(await MainActor.run { NotchState.shared.isExpanded } == false)
    }

    @Test func collapseResetsAllUIFlags() async {
        await MainActor.run {
            NotchState.shared.expand()
            NotchState.shared.startCreating(prefill: "my task")
            NotchState.shared.showCallout("yo!")
            NotchState.shared.setVerifying(true)
            NotchState.shared.setVerificationResult(VerificationResult(verified: false, explanation: "not yet"))
        }
        await MainActor.run { NotchState.shared.collapse() }
        await MainActor.run {
            #expect(NotchState.shared.isExpanded == false)
            #expect(NotchState.shared.isCreating == false)
            #expect(NotchState.shared.sessionCreationPrefill == nil)
            #expect(NotchState.shared.calloutMessage == nil)
            #expect(NotchState.shared.isVerifying == false)
            #expect(NotchState.shared.verificationResult == nil)
            #expect(NotchState.shared.showingConversation == false)
            #expect(NotchState.shared.verificationHistory.isEmpty)
        }
    }

    // MARK: - Session creation

    @Test func startCreatingSetsIsCreatingAndExpands() async {
        await reset()
        await MainActor.run { NotchState.shared.startCreating() }
        await MainActor.run {
            #expect(NotchState.shared.isCreating == true)
            #expect(NotchState.shared.isExpanded == true)
            #expect(NotchState.shared.sessionCreationPrefill == nil)
        }
    }

    @Test func startCreatingWithPrefillStoresPrefill() async {
        await reset()
        await MainActor.run { NotchState.shared.startCreating(prefill: "finish my essay") }
        await MainActor.run {
            #expect(NotchState.shared.isCreating == true)
            #expect(NotchState.shared.isExpanded == true)
            #expect(NotchState.shared.sessionCreationPrefill == "finish my essay")
        }
    }

    @Test func stopCreatingClearsIsCreatingAndPrefill() async {
        await reset()
        await MainActor.run {
            NotchState.shared.startCreating(prefill: "finish my essay")
            NotchState.shared.stopCreating()
        }
        await MainActor.run {
            #expect(NotchState.shared.isCreating == false)
            #expect(NotchState.shared.sessionCreationPrefill == nil)
        }
    }

    // MARK: - Callout

    @Test func showCalloutSetsMessageAndExpands() async {
        await reset()
        await MainActor.run { NotchState.shared.showCallout("focus.") }
        await MainActor.run {
            #expect(NotchState.shared.calloutMessage == "focus.")
            #expect(NotchState.shared.isExpanded == true)
        }
    }

    @Test func clearCalloutRemovesMessage() async {
        await MainActor.run {
            NotchState.shared.showCallout("stop.")
            NotchState.shared.clearCallout()
        }
        let msg = await MainActor.run { NotchState.shared.calloutMessage }
        #expect(msg == nil)
    }

    // MARK: - Callout tier

    @Test func showCalloutDefaultsTierToOne() async {
        await reset()
        await MainActor.run { NotchState.shared.showCallout("focus.") }
        let tier = await MainActor.run { NotchState.shared.calloutTier }
        #expect(tier == 1)
    }

    @Test func showCalloutWithTierSetsCalloutTier() async {
        await reset()
        await MainActor.run { NotchState.shared.showCallout("STOP.", tier: 3) }
        await MainActor.run {
            #expect(NotchState.shared.calloutTier == 3)
            #expect(NotchState.shared.calloutMessage == "STOP.")
        }
    }

    @Test func clearCalloutResetsTierToOne() async {
        await reset()
        await MainActor.run {
            NotchState.shared.showCallout("STOP.", tier: 3)
            NotchState.shared.clearCallout()
        }
        let tier = await MainActor.run { NotchState.shared.calloutTier }
        #expect(tier == 1)
    }

    @Test func collapseResetsTierToOne() async {
        await MainActor.run {
            NotchState.shared.showCallout("STOP.", tier: 3)
            NotchState.shared.collapse()
        }
        let tier = await MainActor.run { NotchState.shared.calloutTier }
        #expect(tier == 1)
    }

    // MARK: - Verification

    @Test func setVerifyingTrueExpandsAndClearsResult() async {
        await reset()
        await MainActor.run {
            // Pre-seed a result to confirm it gets cleared when verifying starts.
            NotchState.shared.setVerificationResult(VerificationResult(verified: true, explanation: "done"))
            NotchState.shared.setVerifying(true)
        }
        await MainActor.run {
            #expect(NotchState.shared.isVerifying == true)
            #expect(NotchState.shared.isExpanded == true)
            #expect(NotchState.shared.verificationResult == nil)
        }
    }

    @Test func setVerifyingFalseDoesNotExpand() async {
        await reset()
        await MainActor.run { NotchState.shared.setVerifying(false) }
        #expect(await MainActor.run { NotchState.shared.isExpanded } == false)
    }

    @Test func setVerificationResultClearsVerifying() async {
        await reset()
        await MainActor.run {
            NotchState.shared.setVerifying(true)
            NotchState.shared.setVerificationResult(VerificationResult(verified: false, explanation: "not yet"))
        }
        await MainActor.run {
            #expect(NotchState.shared.isVerifying == false)
            #expect(NotchState.shared.verificationResult?.verified == false)
            #expect(NotchState.shared.verificationResult?.explanation == "not yet")
        }
    }

    @Test func setVerificationResultNilClearsResult() async {
        await reset()
        await MainActor.run {
            NotchState.shared.setVerificationResult(VerificationResult(verified: true, explanation: "good"))
            NotchState.shared.setVerificationResult(nil)
        }
        let result = await MainActor.run { NotchState.shared.verificationResult }
        #expect(result == nil)
    }

    // MARK: - Conversation

    @Test func exitConversationClearsShowingConversation() async {
        await reset()
        await MainActor.run {
            // startConversation also calls ConversationManager — just verify the flag.
            NotchState.shared.startConversation(.earlyExit)
        }
        await MainActor.run {
            #expect(NotchState.shared.showingConversation == true)
            #expect(NotchState.shared.isExpanded == true)
        }
        await MainActor.run { NotchState.shared.exitConversation() }
        let showing = await MainActor.run { NotchState.shared.showingConversation }
        #expect(showing == false)
    }

    @Test func startConversationClearsVerificationResult() async {
        await reset()
        await MainActor.run {
            NotchState.shared.setVerificationResult(VerificationResult(verified: true, explanation: "done"))
            NotchState.shared.startConversation(.reasoning(domain: nil))
        }
        let result = await MainActor.run { NotchState.shared.verificationResult }
        #expect(result == nil)
    }

    // Regression: tapping "Try again" after a not-verified result calls setVerifying(true),
    // which must clear the old result so the spinner appears (not a stale "not done yet" card).
    @Test func retryAfterNotVerifiedClearsResult() async {
        await reset()
        await MainActor.run {
            // Simulate the not-verified result state.
            NotchState.shared.setVerificationResult(VerificationResult(verified: false, explanation: "didn't see the submission"))
        }
        await MainActor.run {
            #expect(NotchState.shared.verificationResult != nil)
            #expect(NotchState.shared.isVerifying == false)
        }
        // Simulate what verifyAndEnd() does on retry: setVerifying(true).
        await MainActor.run {
            NotchState.shared.setVerifying(true)
        }
        await MainActor.run {
            #expect(NotchState.shared.isVerifying == true)
            #expect(NotchState.shared.verificationResult == nil)
            #expect(NotchState.shared.isExpanded == true)
        }
    }

    @Test func retryKeepGoingCollapsesClearsResult() async {
        await reset()
        await MainActor.run {
            NotchState.shared.setVerificationResult(VerificationResult(verified: false, explanation: "not yet"))
            // Simulate "Keep going" button action.
            NotchState.shared.setVerificationResult(nil)
            NotchState.shared.collapse()
        }
        await MainActor.run {
            #expect(NotchState.shared.verificationResult == nil)
            #expect(NotchState.shared.isExpanded == false)
            #expect(NotchState.shared.isVerifying == false)
        }
    }

    // MARK: - Verification history

    @Test func setVerificationResultAppendsToHistory() async {
        await reset()
        await MainActor.run {
            NotchState.shared.setVerificationResult(VerificationResult(verified: false, explanation: "not yet"))
        }
        let count = await MainActor.run { NotchState.shared.verificationHistory.count }
        #expect(count == 1)
    }

    @Test func multipleResultsAccumulateInHistory() async {
        await reset()
        await MainActor.run {
            NotchState.shared.setVerificationResult(VerificationResult(verified: false, explanation: "first try"))
            NotchState.shared.setVerifying(true)
            NotchState.shared.setVerificationResult(VerificationResult(verified: false, explanation: "second try"))
            NotchState.shared.setVerifying(true)
            NotchState.shared.setVerificationResult(VerificationResult(verified: true, explanation: "done"))
        }
        await MainActor.run {
            #expect(NotchState.shared.verificationHistory.count == 3)
            #expect(NotchState.shared.verificationHistory[0].attemptNumber == 1)
            #expect(NotchState.shared.verificationHistory[2].attemptNumber == 3)
        }
    }

    @Test func historyPreservesExplanations() async {
        await reset()
        await MainActor.run {
            NotchState.shared.setVerificationResult(VerificationResult(verified: false, explanation: "didn't see submission"))
            NotchState.shared.setVerifying(true)
            NotchState.shared.setVerificationResult(VerificationResult(verified: false, explanation: "canvas still loading"))
        }
        await MainActor.run {
            #expect(NotchState.shared.verificationHistory[0].result.explanation == "didn't see submission")
            #expect(NotchState.shared.verificationHistory[1].result.explanation == "canvas still loading")
        }
    }

    @Test func setVerificationResultNilDoesNotAppendToHistory() async {
        await reset()
        await MainActor.run {
            NotchState.shared.setVerificationResult(VerificationResult(verified: false, explanation: "not yet"))
            NotchState.shared.setVerificationResult(nil)
        }
        // nil clears current result but doesn't add a blank entry to history.
        let count = await MainActor.run { NotchState.shared.verificationHistory.count }
        #expect(count == 1)
    }

    @Test func collapseClearsVerificationHistory() async {
        await reset()
        await MainActor.run {
            NotchState.shared.setVerificationResult(VerificationResult(verified: false, explanation: "first"))
            NotchState.shared.setVerifying(true)
            NotchState.shared.setVerificationResult(VerificationResult(verified: false, explanation: "second"))
            NotchState.shared.collapse()
        }
        let count = await MainActor.run { NotchState.shared.verificationHistory.count }
        #expect(count == 0)
    }

    @Test func historyIsEmptyOnFreshState() async {
        await reset()
        let count = await MainActor.run { NotchState.shared.verificationHistory.count }
        #expect(count == 0)
    }

    // MARK: - Restore verification history

    @Test func restoreVerificationHistoryPopulatesHistory() async {
        await reset()
        let attempts = [
            VerificationAttempt(
                result: VerificationResult(verified: false, explanation: "essay not submitted"),
                attemptNumber: 1
            ),
            VerificationAttempt(
                result: VerificationResult(verified: false, explanation: "canvas still loading"),
                attemptNumber: 2
            ),
        ]
        await MainActor.run { NotchState.shared.restoreVerificationHistory(attempts) }
        await MainActor.run {
            #expect(NotchState.shared.verificationHistory.count == 2)
            #expect(NotchState.shared.verificationHistory[0].attemptNumber == 1)
            #expect(NotchState.shared.verificationHistory[1].result.explanation == "canvas still loading")
        }
    }

    @Test func afterRestoreNextResultIsAttemptThree() async {
        await reset()
        let prior = [
            VerificationAttempt(result: VerificationResult(verified: false, explanation: "a"), attemptNumber: 1),
            VerificationAttempt(result: VerificationResult(verified: false, explanation: "b"), attemptNumber: 2),
        ]
        await MainActor.run {
            NotchState.shared.restoreVerificationHistory(prior)
            // Simulate the user retrying verification after a restore.
            NotchState.shared.setVerificationResult(VerificationResult(verified: true, explanation: "done"))
        }
        await MainActor.run {
            #expect(NotchState.shared.verificationHistory.count == 3)
            #expect(NotchState.shared.verificationHistory[2].attemptNumber == 3)
        }
    }

    @Test func restoreVerificationHistoryDoesNotExpandNotch() async {
        await reset()
        await MainActor.run {
            NotchState.shared.restoreVerificationHistory([
                VerificationAttempt(result: VerificationResult(verified: false, explanation: "x"), attemptNumber: 1)
            ])
        }
        let expanded = await MainActor.run { NotchState.shared.isExpanded }
        #expect(expanded == false)
    }

    // MARK: - Panel height selection signals
    // NotchWindowController.targetFrame() branches on verificationResult?.verified to
    // pick verifiedCardHeight (210) instead of verificationHistoryHeight (350). These
    // tests confirm the state properties that drive those branches are set correctly.

    @Test func verifiedResultSignalsVerifiedFlagRegardlessOfHistoryCount() async {
        // After two not-verified attempts followed by a verified one, history.count == 3
        // but verificationResult?.verified == true → panel should use compact verified height.
        await reset()
        await MainActor.run {
            NotchState.shared.setVerificationResult(VerificationResult(verified: false, explanation: "first"))
            NotchState.shared.setVerifying(true)
            NotchState.shared.setVerificationResult(VerificationResult(verified: false, explanation: "second"))
            NotchState.shared.setVerifying(true)
            NotchState.shared.setVerificationResult(VerificationResult(verified: true, explanation: "done!"))
        }
        await MainActor.run {
            #expect(NotchState.shared.verificationResult?.verified == true)
            #expect(NotchState.shared.verificationHistory.count == 3)
            // history.count > 1 but verified==true → compact card, not history panel
        }
    }

    @Test func notVerifiedWithHistorySignalsHistoryHeight() async {
        // After two not-verified attempts, history.count > 1 and verified==false →
        // panel should use the taller history height to show previous attempts.
        await reset()
        await MainActor.run {
            NotchState.shared.setVerificationResult(VerificationResult(verified: false, explanation: "first"))
            NotchState.shared.setVerifying(true)
            NotchState.shared.setVerificationResult(VerificationResult(verified: false, explanation: "second"))
        }
        await MainActor.run {
            #expect(NotchState.shared.verificationResult?.verified == false)
            #expect(NotchState.shared.verificationHistory.count == 2)
            // verified==false and count > 1 → history panel height applies
        }
    }

    // MARK: - idleHasNote

    @Test func idleHasNoteDefaultsToFalse() async {
        await reset()
        let v = await MainActor.run { NotchState.shared.idleHasNote }
        #expect(v == false)
    }

    @Test func settingIdleHasNoteTrueRaisesFlag() async {
        await reset()
        await MainActor.run { NotchState.shared.idleHasNote = true }
        let v = await MainActor.run { NotchState.shared.idleHasNote }
        #expect(v == true)
    }

    @Test func collapseDoesNotClearIdleHasNote() async {
        // idleHasNote persists across collapse — it reflects lastRecord state,
        // not transient UI state, and is only updated when IdleBody reloads.
        await reset()
        await MainActor.run { NotchState.shared.idleHasNote = true }
        await MainActor.run { NotchState.shared.collapse() }
        let v = await MainActor.run { NotchState.shared.idleHasNote }
        #expect(v == true)
    }

    // MARK: - focusScoreColor

    @Test func focusScoreColorGreenAtHighScore() {
        // SwiftUI Color doesn't expose RGB directly; verify via boundary conditions.
        #expect(focusScoreColor(0.80) == focusScoreColor(0.99),
                "scores at or above 0.80 must share the same green color")
    }

    @Test func focusScoreColorAmberAtMidScore() {
        #expect(focusScoreColor(0.60) == focusScoreColor(0.79),
                "scores in [0.60, 0.80) must share the same amber color")
    }

    @Test func focusScoreColorRedBelowSixty() {
        #expect(focusScoreColor(0.59) == focusScoreColor(0.00),
                "scores below 0.60 must share the same red color")
    }

    @Test func focusScoreColorBoundaryAtEighty() {
        // Exactly 0.80 is green; 0.799... is amber.
        let green = focusScoreColor(0.80)
        let amber = focusScoreColor(0.79)
        #expect(green != amber, "0.80 must be green while 0.79 must be amber")
    }

    @Test func focusScoreColorBoundaryAtSixty() {
        let amber = focusScoreColor(0.60)
        let red   = focusScoreColor(0.59)
        #expect(amber != red, "0.60 must be amber while 0.59 must be red")
    }

    // MARK: - whitelistedDomainsLabel

    @Test func whitelistedDomainsLabelEmptyReturnsEmpty() {
        #expect(whitelistedDomainsLabel([]) == "")
    }

    @Test func whitelistedDomainsLabelSingleDomain() {
        #expect(whitelistedDomainsLabel(["canvas.com"]) == "canvas.com")
    }

    @Test func whitelistedDomainsLabelTwoDomains() {
        #expect(whitelistedDomainsLabel(["canvas.com", "google.com"]) == "canvas.com, google.com")
    }

    @Test func whitelistedDomainsLabelThreeDomainsAtMax() {
        let result = whitelistedDomainsLabel(["a.com", "b.com", "c.com"])
        #expect(result == "a.com, b.com, c.com")
    }

    @Test func whitelistedDomainsLabelFourDomainsShowsPlusMore() {
        let result = whitelistedDomainsLabel(["a.com", "b.com", "c.com", "d.com"])
        #expect(result == "a.com, b.com, c.com +1 more")
    }

    @Test func whitelistedDomainsLabelManyDomainsShowsPlusMore() {
        let result = whitelistedDomainsLabel(["a.com", "b.com", "c.com", "d.com", "e.com", "f.com"])
        #expect(result == "a.com, b.com, c.com +3 more")
    }

    @Test func whitelistedDomainsLabelCustomMaxVisible() {
        let result = whitelistedDomainsLabel(["a.com", "b.com", "c.com"], maxVisible: 1)
        #expect(result == "a.com +2 more")
    }

    // MARK: - idleHasHeatmap

    @Test func idleHasHeatmapDefaultsToFalse() async {
        await reset()
        let v = await MainActor.run { NotchState.shared.idleHasHeatmap }
        #expect(v == false)
    }

    @Test func settingIdleHasHeatmapTrueRaisesFlag() async {
        await reset()
        await MainActor.run { NotchState.shared.idleHasHeatmap = true }
        let v = await MainActor.run { NotchState.shared.idleHasHeatmap }
        #expect(v == true)
    }

    @Test func collapseDoesNotClearIdleHasHeatmap() async {
        await reset()
        await MainActor.run { NotchState.shared.idleHasHeatmap = true }
        await MainActor.run { NotchState.shared.collapse() }
        let v = await MainActor.run { NotchState.shared.idleHasHeatmap }
        #expect(v == true)
    }

    // MARK: - notchHeatmapTooltip

    @Test func notchHeatmapTooltipNoSessions() {
        let day = DayActivity(date: Date(), sessionCount: 0, minutes: 0)
        #expect(notchHeatmapTooltip(day) == "no sessions")
    }

    @Test func notchHeatmapTooltipOneSession() {
        let day = DayActivity(date: Date(), sessionCount: 1, minutes: 45)
        #expect(notchHeatmapTooltip(day) == "1 session · 45m")
    }

    @Test func notchHeatmapTooltipMultipleSessions() {
        let day = DayActivity(date: Date(), sessionCount: 3, minutes: 90)
        #expect(notchHeatmapTooltip(day) == "3 sessions · 1h 30m")
    }

    @Test func notchHeatmapTooltipHoursOnly() {
        let day = DayActivity(date: Date(), sessionCount: 2, minutes: 120)
        #expect(notchHeatmapTooltip(day) == "2 sessions · 2h")
    }

    @Test func notchHeatmapTooltipSubMinute() {
        let day = DayActivity(date: Date(), sessionCount: 1, minutes: 0)
        #expect(notchHeatmapTooltip(day) == "1 session · <1m")
    }

    // MARK: - notchHeatmapDayAbbrev

    @Test func notchHeatmapDayAbbrevSunday() {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1
        let sunday = cal.date(from: DateComponents(year: 2026, month: 6, day: 14))!
        #expect(notchHeatmapDayAbbrev(sunday) == "Su")
    }

    @Test func notchHeatmapDayAbbrevThursday() {
        var cal = Calendar(identifier: .gregorian)
        cal.firstWeekday = 1
        let thursday = cal.date(from: DateComponents(year: 2026, month: 6, day: 18))!
        #expect(notchHeatmapDayAbbrev(thursday) == "Th")
    }

    // MARK: - idleHasDailyGoal

    @Test func idleHasDailyGoalDefaultsFalse() async {
        await reset()
        let has = await MainActor.run { NotchState.shared.idleHasDailyGoal }
        #expect(has == false)
    }

    @Test func idleHasDailyGoalCanBeSet() async {
        await reset()
        await MainActor.run { NotchState.shared.idleHasDailyGoal = true }
        let has = await MainActor.run { NotchState.shared.idleHasDailyGoal }
        #expect(has == true)
    }

    // MARK: - dailyGoalProgressLabel

    @Test func dailyGoalProgressLabelZeroProgress() {
        #expect(dailyGoalProgressLabel(todayMinutes: 0, goalMinutes: 120) == "0m of 2h daily goal")
    }

    @Test func dailyGoalProgressLabelPartialProgress() {
        #expect(dailyGoalProgressLabel(todayMinutes: 45, goalMinutes: 120) == "45m of 2h daily goal")
    }

    @Test func dailyGoalProgressLabelHoursAndMinutes() {
        #expect(dailyGoalProgressLabel(todayMinutes: 90, goalMinutes: 180) == "1h 30m of 3h daily goal")
    }

    @Test func dailyGoalProgressLabelGoalReached() {
        #expect(dailyGoalProgressLabel(todayMinutes: 120, goalMinutes: 120) == "2h daily goal reached!")
    }

    @Test func dailyGoalProgressLabelGoalExceeded() {
        #expect(dailyGoalProgressLabel(todayMinutes: 150, goalMinutes: 120) == "2h daily goal reached!")
    }

    @Test func dailyGoalProgressLabelZeroGoal() {
        #expect(dailyGoalProgressLabel(todayMinutes: 30, goalMinutes: 0) == "")
    }

    // MARK: - dailyGoalCollapsedLabel

    @Test func dailyGoalCollapsedLabelZeroProgress() {
        #expect(dailyGoalCollapsedLabel(todayMinutes: 0, goalMinutes: 120) == "0m / 2h")
    }

    @Test func dailyGoalCollapsedLabelPartialProgress() {
        #expect(dailyGoalCollapsedLabel(todayMinutes: 45, goalMinutes: 120) == "45m / 2h")
    }

    @Test func dailyGoalCollapsedLabelGoalReached() {
        #expect(dailyGoalCollapsedLabel(todayMinutes: 120, goalMinutes: 120) == "2h / 2h ✓")
    }

    @Test func dailyGoalCollapsedLabelGoalExceeded() {
        #expect(dailyGoalCollapsedLabel(todayMinutes: 150, goalMinutes: 120) == "2h 30m / 2h ✓")
    }

    @Test func dailyGoalCollapsedLabelZeroGoal() {
        #expect(dailyGoalCollapsedLabel(todayMinutes: 30, goalMinutes: 0) == "")
    }
}
