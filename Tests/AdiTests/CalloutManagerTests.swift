import Testing
@testable import AdiCore

/// Tests run serially: CalloutManager.shared and NotchState.shared are @MainActor singletons.
/// Concurrent tests could interleave between MainActor.run calls and race on shared state.
@Suite("CalloutManager", .serialized)
struct CalloutManagerTests {

    @Test func onTaskNoCallout() async {
        await MainActor.run {
            NotchState.shared.clearCallout()
            CalloutManager.shared.evaluate(.onTask)
            #expect(NotchState.shared.calloutMessage == nil)
        }
    }

    @Test func ambiguousNoCrash() async {
        await MainActor.run {
            NotchState.shared.clearCallout()
            CalloutManager.shared.evaluate(.ambiguous)
            #expect(NotchState.shared.calloutMessage == nil)
        }
    }

    @Test func onTaskClearsCallout() async {
        await MainActor.run {
            NotchState.shared.showCallout("stop.")
            #expect(NotchState.shared.calloutMessage != nil)
            CalloutManager.shared.evaluate(.onTask)
            #expect(NotchState.shared.calloutMessage == nil)
        }
    }

    // Threshold is 2 consecutive offTask frames before callout fires.
    @Test func doesNotFireBeforeThreshold() async {
        await MainActor.run {
            CalloutManager.shared.evaluate(.onTask) // reset streak
            NotchState.shared.clearCallout()
            CalloutManager.shared.evaluate(.offTask) // count = 1
            #expect(NotchState.shared.calloutMessage == nil)
        }
    }

    @Test func firesCalloutAtThreshold() async {
        await MainActor.run {
            CalloutManager.shared.evaluate(.onTask) // reset streak
            NotchState.shared.clearCallout()
            CalloutManager.shared.evaluate(.offTask) // count = 1
            CalloutManager.shared.evaluate(.offTask) // count = 2, threshold hit
            #expect(NotchState.shared.calloutMessage != nil)
        }
    }

    @Test func doesNotRefireWithinSameStreak() async {
        await MainActor.run {
            CalloutManager.shared.evaluate(.onTask) // reset streak
            NotchState.shared.clearCallout()
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask) // fires
            let firstMessage = NotchState.shared.calloutMessage
            #expect(firstMessage != nil)
            // Subsequent offTask frames within the same streak must not re-fire.
            NotchState.shared.clearCallout()
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask)
            // clearCallout doesn't reset hasFiredForStreak — message stays nil
            #expect(NotchState.shared.calloutMessage == nil)
        }
    }

    @Test func refiresAfterRecovery() async {
        await MainActor.run {
            CalloutManager.shared.evaluate(.onTask) // reset streak
            NotchState.shared.clearCallout()
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask) // first callout fires
            CalloutManager.shared.evaluate(.onTask)  // back on task → resets streak
            #expect(NotchState.shared.calloutMessage == nil)
            // New off-task streak should fire again.
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask)
            #expect(NotchState.shared.calloutMessage != nil)
        }
    }

    /// Verify callout shows a non-empty message string from the callouts pool.
    @Test func calloutMessageIsNonEmpty() async {
        await MainActor.run {
            CalloutManager.shared.evaluate(.onTask) // reset streak
            NotchState.shared.clearCallout()
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask)
            let msg = NotchState.shared.calloutMessage
            #expect(msg != nil)
            #expect(!(msg ?? "").isEmpty)
        }
    }

    /// Verifies that firing a second streak after reset() uses a fresh auto-dismiss task.
    /// This guards the race condition where two streaks share independent tasks:
    /// the first task's 8s timer must not clear the second streak's callout.
    @Test func resetCancelsAutoDismissBeforeNewStreak() async {
        await MainActor.run {
            CalloutManager.shared.evaluate(.onTask)  // reset streak
            NotchState.shared.clearCallout()
            // First streak fires
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask)
            let firstMessage = NotchState.shared.calloutMessage
            #expect(firstMessage != nil)
            // reset() cancels the first auto-dismiss task
            CalloutManager.shared.reset()
            #expect(NotchState.shared.calloutMessage == nil)
            // Second streak fires with its own independent task
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask)
            #expect(NotchState.shared.calloutMessage != nil)
        }
    }

    /// Verifies that public reset() clears streak state so a fresh session can
    /// immediately trigger a callout without inheriting the prior session's streak.
    @Test func publicResetAllowsNewStreakToFire() async {
        await MainActor.run {
            // Build up a fired streak (hasFiredForStreak = true)
            CalloutManager.shared.evaluate(.onTask)
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask) // fires
            #expect(NotchState.shared.calloutMessage != nil)

            // Simulate session end → new session start
            CalloutManager.shared.reset()
            // reset() calls clearCallout() internally
            #expect(NotchState.shared.calloutMessage == nil)

            // A brand-new off-task streak must fire despite hasFiredForStreak
            // having been true in the previous session.
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask)
            #expect(NotchState.shared.calloutMessage != nil)
        }
    }

    /// Verifies that consecutive independent streaks never show the same callout message.
    /// With 10 callouts and last-message filtering, back-to-back identical messages are
    /// impossible as long as the pool has ≥ 2 entries.
    @Test func consecutiveStreaksDoNotRepeatCallout() async {
        await MainActor.run {
            // Fire first streak
            CalloutManager.shared.reset()
            NotchState.shared.clearCallout()
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask)
            let first = NotchState.shared.calloutMessage
            #expect(first != nil)

            // Reset (simulates session end / on-task recovery) and fire second streak
            CalloutManager.shared.reset()
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask)
            let second = NotchState.shared.calloutMessage
            #expect(second != nil)

            // Deduplication guarantees consecutive callouts are never identical.
            #expect(first != second)
        }
    }

    // MARK: - calloutCount

    @Test func calloutCountStartsAtZero() async {
        await MainActor.run {
            CalloutManager.shared.reset()
            #expect(CalloutManager.shared.calloutCount == 0)
        }
    }

    @Test func calloutCountIncrementOnFire() async {
        await MainActor.run {
            CalloutManager.shared.reset()
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask) // threshold hit → fires
            #expect(CalloutManager.shared.calloutCount == 1)
        }
    }

    @Test func calloutCountIncrementPerStreak() async {
        await MainActor.run {
            CalloutManager.shared.reset()
            // First streak
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask)
            // Recovery
            CalloutManager.shared.evaluate(.onTask)
            // Second streak
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask)
            #expect(CalloutManager.shared.calloutCount == 2)
        }
    }

    @Test func calloutCountResetsOnReset() async {
        await MainActor.run {
            CalloutManager.shared.reset()
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask)
            #expect(CalloutManager.shared.calloutCount == 1)
            CalloutManager.shared.reset()
            #expect(CalloutManager.shared.calloutCount == 0)
        }
    }

    // MARK: - On-task recovery preserves calloutCount

    /// Verifies that returning on-task does NOT reset calloutCount, so tier escalation
    /// correctly accumulates across multiple off-task streaks within a session.
    @Test func onTaskRecoveryPreservesCalloutCount() async {
        await MainActor.run {
            CalloutManager.shared.reset()
            // First streak
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask) // fires, count = 1
            // Recovery
            CalloutManager.shared.evaluate(.onTask)  // resetStreak only — count must stay 1
            #expect(CalloutManager.shared.calloutCount == 1)
            // Second streak
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask) // fires, count = 2
            #expect(CalloutManager.shared.calloutCount == 2)
        }
    }

    // MARK: - Tier escalation

    /// First callout uses tier-1 pool (calloutCount == 0 before fire).
    @Test func tier1OnFirstCallout() async {
        await MainActor.run {
            CalloutManager.shared.reset()
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask) // fires — tier 1
            #expect(NotchState.shared.calloutTier == 1)
        }
    }

    /// After two callouts (count == 2 before third fire), tier escalates to 2.
    @Test func tier2OnThirdCallout() async {
        await MainActor.run {
            CalloutManager.shared.reset()
            // Fire first two callouts with on-task recovery between each
            for _ in 0..<2 {
                CalloutManager.shared.evaluate(.offTask)
                CalloutManager.shared.evaluate(.offTask)
                CalloutManager.shared.evaluate(.onTask) // streak reset; calloutCount preserved
            }
            // Third callout
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask)
            #expect(NotchState.shared.calloutTier == 2)
        }
    }

    /// After four callouts (count == 4 before fifth fire), tier escalates to 3.
    @Test func tier3OnFifthCallout() async {
        await MainActor.run {
            CalloutManager.shared.reset()
            // Fire first four callouts with on-task recovery between each
            for _ in 0..<4 {
                CalloutManager.shared.evaluate(.offTask)
                CalloutManager.shared.evaluate(.offTask)
                CalloutManager.shared.evaluate(.onTask) // streak reset; calloutCount preserved
            }
            // Fifth callout
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask)
            #expect(NotchState.shared.calloutTier == 3)
        }
    }

    /// Verifies currentTier() boundaries: 0–1 → tier 1, 2–3 → tier 2, 4+ → tier 3.
    @Test func currentTierBoundaries() async {
        await MainActor.run {
            CalloutManager.shared.reset()
            #expect(CalloutManager.shared.currentTier() == 1) // count = 0
            // Manually fire to increment count without full reset between checks
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask) // count = 1
            CalloutManager.shared.evaluate(.onTask)  // streak reset, count stays 1
            #expect(CalloutManager.shared.currentTier() == 1) // count = 1
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask) // count = 2
            CalloutManager.shared.evaluate(.onTask)
            #expect(CalloutManager.shared.currentTier() == 2) // count = 2
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask) // count = 3
            CalloutManager.shared.evaluate(.onTask)
            #expect(CalloutManager.shared.currentTier() == 2) // count = 3
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask) // count = 4
            CalloutManager.shared.evaluate(.onTask)
            #expect(CalloutManager.shared.currentTier() == 3) // count = 4
        }
    }

    /// Dismiss delay increases with tier so higher-tier callouts are harder to ignore.
    @Test func dismissDelayEscalatesWithTier() async {
        #expect(CalloutManager.dismissDelay(for: 1) == .seconds(8))
        #expect(CalloutManager.dismissDelay(for: 2) == .seconds(12))
        #expect(CalloutManager.dismissDelay(for: 3) == .seconds(20))
    }

    // MARK: - Restore (session resume after crash/relaunch)

    /// restore(count:) sets calloutCount so a relaunched session resumes at the right tier.
    @Test func restoreCountSetsCalloutCount() async {
        await MainActor.run {
            CalloutManager.shared.reset()
            #expect(CalloutManager.shared.calloutCount == 0)
            CalloutManager.shared.restore(count: 4)
            #expect(CalloutManager.shared.calloutCount == 4)
        }
    }

    /// After restore(count: 4), the next callout fires at tier 3 (≥4 means tier 3).
    @Test func restoreCountAffectsTierOnNextFire() async {
        await MainActor.run {
            CalloutManager.shared.reset()
            CalloutManager.shared.restore(count: 4) // simulate 4 prior callouts
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask) // fires — should be tier 3
            #expect(NotchState.shared.calloutTier == 3)
        }
    }

    /// reset() after restore() zeroes the count again (clean-slate for a brand-new session).
    @Test func resetAfterRestoreZeroesCount() async {
        await MainActor.run {
            CalloutManager.shared.reset()
            CalloutManager.shared.restore(count: 3)
            #expect(CalloutManager.shared.calloutCount == 3)
            CalloutManager.shared.reset()
            #expect(CalloutManager.shared.calloutCount == 0)
        }
    }

    // MARK: - Task context keyword extraction

    @Test func extractTaskKeywordFromEssayInput() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my history essay") == "essay")
        #expect(CalloutManager.extractTaskKeyword(from: "ENGL 101 paper") == "essay")
        #expect(CalloutManager.extractTaskKeyword(from: "finish my thesis") == "essay")
    }

    @Test func extractTaskKeywordFromCodeInput() {
        #expect(CalloutManager.extractTaskKeyword(from: "fix the login bug") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "finish coding the API") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "implement the new feature") == "code")
    }

    @Test func extractTaskKeywordFromPresentationInput() {
        #expect(CalloutManager.extractTaskKeyword(from: "make a presentation") == "presentation")
        #expect(CalloutManager.extractTaskKeyword(from: "finish my slides") == "presentation")
        #expect(CalloutManager.extractTaskKeyword(from: "build the pitch deck") == "presentation")
    }

    @Test func extractTaskKeywordFromStudyInput() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for biology exam") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "study for the quiz") == "studying")
    }

    @Test func extractTaskKeywordFromHomeworkInput() {
        #expect(CalloutManager.extractTaskKeyword(from: "do my homework") == "homework")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the assignment") == "homework")
    }

    @Test func extractTaskKeywordFromResearchInput() {
        #expect(CalloutManager.extractTaskKeyword(from: "research on tariffs") == "research")
    }

    @Test func extractTaskKeywordReturnsNilForGenericInput() {
        #expect(CalloutManager.extractTaskKeyword(from: "get things done") == nil)
        #expect(CalloutManager.extractTaskKeyword(from: "work") == nil)
        #expect(CalloutManager.extractTaskKeyword(from: "") == nil)
    }

    @Test func setTaskStoresExtractedKeyword() async {
        await MainActor.run {
            CalloutManager.shared.reset()
            CalloutManager.shared.setTask("write my ENGL 101 essay")
            #expect(CalloutManager.shared.currentTaskKeyword == "essay")
        }
    }

    @Test func setTaskWithUnknownTaskStoresNil() async {
        await MainActor.run {
            CalloutManager.shared.reset()
            CalloutManager.shared.setTask("get things done")
            #expect(CalloutManager.shared.currentTaskKeyword == nil)
        }
    }

    @Test func resetClearsTaskKeyword() async {
        await MainActor.run {
            CalloutManager.shared.setTask("write my essay")
            #expect(CalloutManager.shared.currentTaskKeyword == "essay")
            CalloutManager.shared.reset()
            #expect(CalloutManager.shared.currentTaskKeyword == nil)
        }
    }

    @Test func taskAwareCalloutsContainKeyword() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier1 = manager.taskAwareCallouts(keyword: "essay", tier: 1)
            let tier2 = manager.taskAwareCallouts(keyword: "essay", tier: 2)
            let tier3 = manager.taskAwareCallouts(keyword: "essay", tier: 3)
            #expect(!tier1.isEmpty)
            #expect(!tier2.isEmpty)
            #expect(!tier3.isEmpty)
            #expect(tier1.allSatisfy { $0.contains("essay") })
            #expect(tier2.allSatisfy { $0.contains("essay") })
            #expect(tier3.allSatisfy { $0.contains("essay") })
        }
    }

    @Test func taskAwareCalloutsSubstituteKeywordPerTier() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            let keywords = ["code", "presentation", "homework", "research"]
            for kw in keywords {
                for tier in 1...3 {
                    let msgs = manager.taskAwareCallouts(keyword: kw, tier: tier)
                    #expect(msgs.allSatisfy { $0.contains(kw) },
                            "tier \(tier) messages for '\(kw)' must all contain the keyword")
                }
            }
        }
    }

    // "studying" uses natural gerund phrasing — "your studying" sounds awkward.
    @Test func taskAwareCalloutsStudyingUsesNaturalPhrasing() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "studying", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) studying messages must not be empty")
                // Must contain a study-root word; must NOT contain "your studying"
                #expect(msgs.allSatisfy { $0.contains("study") || $0.contains("Study") },
                        "tier \(tier) studying messages must reference studying")
                #expect(msgs.allSatisfy { !$0.contains("your studying") },
                        "tier \(tier) studying messages must not use 'your studying'")
            }
        }
    }

    // "reading" uses natural gerund phrasing — "your reading" sounds awkward as a direct object.
    @Test func taskAwareCalloutsReadingUsesNaturalPhrasing() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "reading", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) reading messages must not be empty")
                #expect(msgs.allSatisfy { $0.contains("read") || $0.contains("Read") },
                        "tier \(tier) reading messages must reference reading")
                // Tier 2 says "your reading" intentionally for natural phrasing — only tier 1 and 3 drop it.
                let noYourReadingTiers = [1, 3]
                if noYourReadingTiers.contains(tier) {
                    #expect(msgs.allSatisfy { !$0.contains("your reading") },
                            "tier \(tier) reading messages must not use 'your reading'")
                }
            }
        }
    }

    // MARK: - Word-boundary extraction (false-positive prevention)

    @Test func extractTaskKeywordIgnoresReadingInsideThreading() {
        // "threading" contains "reading" as a substring — must NOT match
        #expect(CalloutManager.extractTaskKeyword(from: "I am threading the model") == nil)
        #expect(CalloutManager.extractTaskKeyword(from: "multi-threading performance") == nil)
    }

    @Test func extractTaskKeywordIgnoresTestInsideContest() {
        // "contest", "latest", "protest" contain "test" as a substring — must NOT match "studying"
        #expect(CalloutManager.extractTaskKeyword(from: "enter the coding contest") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "latest news") == nil)
        #expect(CalloutManager.extractTaskKeyword(from: "protest march") == nil)
    }

    @Test func extractTaskKeywordIgnoresBookInsideFacebook() {
        // "facebook" contains "book" as a substring — must NOT match "reading"
        #expect(CalloutManager.extractTaskKeyword(from: "check facebook") == nil)
    }

    @Test func extractTaskKeywordStillMatchesStandaloneWords() {
        // Whole-word matches must still work
        #expect(CalloutManager.extractTaskKeyword(from: "finish reading the book") == "reading")
        #expect(CalloutManager.extractTaskKeyword(from: "study for the test") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "read the article") == "reading")
    }

    // MARK: - Student-centric keyword additions

    @Test func extractTaskKeywordFromMidterm() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for my midterm") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "midterm tomorrow") == "studying")
    }

    @Test func extractTaskKeywordFromFinals() {
        #expect(CalloutManager.extractTaskKeyword(from: "finals week prep") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "reviewing for finals") == "studying")
    }

    @Test func extractTaskKeywordFromNotes() {
        #expect(CalloutManager.extractTaskKeyword(from: "take notes on the lecture") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "review my notes") == "studying")
    }

    @Test func extractTaskKeywordFromFlashcards() {
        #expect(CalloutManager.extractTaskKeyword(from: "make flashcards for bio") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "go through flashcard deck") == "studying")
    }

    @Test func extractTaskKeywordFromPset() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish pset 3") == "homework")
        #expect(CalloutManager.extractTaskKeyword(from: "math pset due tonight") == "homework")
    }

    @Test func extractTaskKeywordFromLab() {
        #expect(CalloutManager.extractTaskKeyword(from: "write up the chemistry lab") == "research")
        #expect(CalloutManager.extractTaskKeyword(from: "bio lab report") == "research")
    }

    @Test func extractTaskKeywordFromLecture() {
        // lectures are study-mode activities — map to "studying"
        // ("review the lecture slides" maps to "presentation" because "slides" fires first)
        #expect(CalloutManager.extractTaskKeyword(from: "watch lecture 4") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "re-watch lecture recording") == "studying")
    }

    @Test func extractTaskKeywordLabDoesNotMatchElaboration() {
        // "elaboration" contains "lab" — must NOT match "research"
        #expect(CalloutManager.extractTaskKeyword(from: "write an elaboration on the topic") == nil)
    }

    @Test func extractTaskKeywordPsetDoesNotMatchUpset() {
        // "upset" does not contain "pset" as a word boundary match
        #expect(CalloutManager.extractTaskKeyword(from: "feeling upset about grades") == nil)
    }
}
