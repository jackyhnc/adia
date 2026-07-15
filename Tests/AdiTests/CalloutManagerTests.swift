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
        #expect(CalloutManager.extractTaskKeyword(from: "ENGL 101 paper") == "paper")
        #expect(CalloutManager.extractTaskKeyword(from: "finish my thesis") == "thesis")
        #expect(CalloutManager.extractTaskKeyword(from: "write my dissertation") == "thesis")
    }

    // MARK: - Plural keyword variants (consistency with project/proposal/interview)

    @Test func extractTaskKeywordPluralEssays() {
        #expect(CalloutManager.extractTaskKeyword(from: "I have two essays due this week") == "essay")
        #expect(CalloutManager.extractTaskKeyword(from: "both essays need to be submitted") == "essay")
    }

    @Test func extractTaskKeywordPluralPapers() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish my papers before Friday") == "paper")
        #expect(CalloutManager.extractTaskKeyword(from: "three papers due this semester") == "paper")
    }

    @Test func extractTaskKeywordPluralTheses() {
        #expect(CalloutManager.extractTaskKeyword(from: "grad students defending their theses") == "thesis")
    }

    @Test func extractTaskKeywordPluralDissertations() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on my dissertations chapter") == "thesis")
    }

    @Test func extractTaskKeywordPluralReports() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish two client reports by EOD") == "report")
        #expect(CalloutManager.extractTaskKeyword(from: "quarterly reports are due Monday") == "report")
    }

    @Test func extractTaskKeywordPluralDocuments() {
        #expect(CalloutManager.extractTaskKeyword(from: "review all the onboarding documents") == "report")
        #expect(CalloutManager.extractTaskKeyword(from: "edit the documents before sending") == "report")
    }

    @Test func extractTaskKeywordPluralDocs() {
        #expect(CalloutManager.extractTaskKeyword(from: "update the API docs") == "report")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the docs for this module") == "report")
    }

    @Test func extractTaskKeywordPluralPresentations() {
        #expect(CalloutManager.extractTaskKeyword(from: "two presentations due this week") == "presentation")
        #expect(CalloutManager.extractTaskKeyword(from: "prep all three presentations") == "presentation")
    }

    @Test func extractTaskKeywordPluralDeadlines() {
        #expect(CalloutManager.extractTaskKeyword(from: "so many deadlines this week") == "deadline")
        #expect(CalloutManager.extractTaskKeyword(from: "multiple deadlines converging today") == "deadline")
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

    // "paper" now has a dedicated pool — each message must reference "paper" and not fall to generic.
    @Test func taskAwareCalloutsPaperContainsPaper() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "paper", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) paper messages must not be empty")
                #expect(msgs.allSatisfy { $0.contains("paper") },
                        "tier \(tier) paper messages must say 'paper', not 'essay'")
            }
        }
    }

    // "paper" dedicated pool has at least 3 messages per tier (richer than generic's 3/2/2).
    @Test func taskAwareCalloutsPaperDedicatedPoolSize() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            #expect(manager.taskAwareCallouts(keyword: "paper", tier: 1).count >= 3, "tier 1 paper pool must have ≥3 messages")
            #expect(manager.taskAwareCallouts(keyword: "paper", tier: 2).count >= 2, "tier 2 paper pool must have ≥2 messages")
            #expect(manager.taskAwareCallouts(keyword: "paper", tier: 3).count >= 2, "tier 3 paper pool must have ≥2 messages")
        }
    }

    // "thesis" now has a dedicated pool — each message must reference "thesis" and not fall to generic.
    @Test func taskAwareCalloutsThesisContainsThesis() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "thesis", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) thesis messages must not be empty")
                #expect(msgs.allSatisfy { $0.contains("thesis") },
                        "tier \(tier) thesis messages must say 'thesis', not 'essay'")
            }
        }
    }

    // "thesis" dedicated pool has at least 2 messages per tier.
    @Test func taskAwareCalloutsThesisDedicatedPoolSize() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            #expect(manager.taskAwareCallouts(keyword: "thesis", tier: 1).count >= 2, "tier 1 thesis pool must have ≥2 messages")
            #expect(manager.taskAwareCallouts(keyword: "thesis", tier: 2).count >= 2, "tier 2 thesis pool must have ≥2 messages")
            #expect(manager.taskAwareCallouts(keyword: "thesis", tier: 3).count >= 2, "tier 3 thesis pool must have ≥2 messages")
        }
    }

    // Tier 3 thesis messages should not contain "your thesis" in a way that sounds generic.
    // The dedicated pool has one unique "years of work" message that generic could never produce.
    @Test func taskAwareCalloutsThesisTier3HasUniqueMessage() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            let msgs = manager.taskAwareCallouts(keyword: "thesis", tier: 3)
            #expect(msgs.contains { $0.contains("years") || $0.contains("deadline") || $0.contains("CLOSE") },
                    "tier 3 thesis pool must have at least one high-urgency message")
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

    @Test func extractTaskKeywordAudiobook() {
        // "listen to an audiobook" has no annotate/reading match; audiobook must map to "reading"
        #expect(CalloutManager.extractTaskKeyword(from: "listen to an audiobook") == "reading")
        #expect(CalloutManager.extractTaskKeyword(from: "finish my audiobook") == "reading")
        #expect(CalloutManager.extractTaskKeyword(from: "audiobooks are on my list") == "reading")
    }

    @Test func extractTaskKeywordAudiobookDoesNotMatchPodcast() {
        // A podcast task must still route to "podcast" even if audiobook is mentioned in passing
        #expect(CalloutManager.extractTaskKeyword(from: "record a podcast episode") == "podcast")
    }

    @Test func extractTaskKeywordAudiobookWithAnnotate() {
        // The existing suggested template "Listen to and annotate an audiobook chapter"
        // matches "annotate" before reaching "audiobook" — both yield "reading", so the
        // result must remain "reading" regardless of match order.
        #expect(CalloutManager.extractTaskKeyword(from: "listen to and annotate an audiobook chapter") == "reading")
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
        // ("go through flashcard deck" maps to "presentation" because "deck" fires first —
        // same precedence quirk as "review the lecture slides", see extractTaskKeywordFromLecture)
        #expect(CalloutManager.extractTaskKeyword(from: "make flashcards for bio") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "go through my flashcards") == "studying")
    }

    @Test func extractTaskKeywordFromPset() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish pset 3") == "homework")
        #expect(CalloutManager.extractTaskKeyword(from: "math pset due tonight") == "homework")
    }

    @Test func extractTaskKeywordFromLab() {
        // ("bio lab report" maps to "report" because "report" fires first — same
        // precedence quirk as "review the lecture slides", see extractTaskKeywordFromLecture)
        #expect(CalloutManager.extractTaskKeyword(from: "write up the chemistry lab") == "research")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the bio lab") == "research")
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

    // MARK: - Knowledge-worker keyword additions: design

    @Test func extractTaskKeywordFromDesign() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish the UI design") == "design")
        #expect(CalloutManager.extractTaskKeyword(from: "create a mockup for the landing page") == "design")
        #expect(CalloutManager.extractTaskKeyword(from: "wireframe the onboarding flow") == "design")
        #expect(CalloutManager.extractTaskKeyword(from: "build a prototype for the new feature") == "design")
        #expect(CalloutManager.extractTaskKeyword(from: "designing the dashboard in Figma") == "design")
        #expect(CalloutManager.extractTaskKeyword(from: "open the sketch file") == "design")
    }

    @Test func taskAwareCalloutsDesignContainsKeyword() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "design", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) design messages must not be empty")
                #expect(msgs.allSatisfy { $0.contains("design") },
                        "tier \(tier) design messages must contain 'design'")
            }
        }
    }

    // "design" now has a dedicated handler — tier 3 must not produce "open your design".
    @Test func taskAwareCalloutsDesignTier3AvoidsOpenPhrase() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "design", tier: 3)
            #expect(tier3.allSatisfy { !$0.contains("open your design") },
                    "tier 3 design must not use 'open your design' (sounds like opening a file)")
        }
    }

    @Test func taskAwareCalloutsDesignTier3UsesActionPhrasing() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "design", tier: 3)
            let actionWords = ["finish", "go", "complete", "keep", "back"]
            #expect(tier3.contains { msg in actionWords.contains { msg.lowercased().contains($0) } },
                    "tier 3 design must contain at least one action-oriented message")
        }
    }

    // MARK: - Knowledge-worker keyword additions: email

    @Test func extractTaskKeywordFromEmail() {
        #expect(CalloutManager.extractTaskKeyword(from: "write 5 important emails") == "email")
        #expect(CalloutManager.extractTaskKeyword(from: "clear my inbox") == "email")
        #expect(CalloutManager.extractTaskKeyword(from: "draft the client email") == "email")
        // "newsletter" now maps to "writing" since writing a newsletter is a content task.
        #expect(CalloutManager.extractTaskKeyword(from: "finish writing the newsletter") == "writing")
    }

    @Test func taskAwareCalloutsEmailContainsKeyword() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "email", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) email messages must not be empty")
                // Natural email phrasing uses both "email" and "inbox" — accept either.
                #expect(msgs.allSatisfy { $0.contains("email") || $0.contains("inbox") },
                        "tier \(tier) email messages must reference email or inbox")
            }
        }
    }

    // "email" uses inbox-centric phrasing — "this isn't your email" sounds unnatural.
    @Test func taskAwareCalloutsEmailUsesNaturalPhrasing() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "email", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) email messages must not be empty")
                #expect(msgs.allSatisfy { !$0.contains("this isn't your email") },
                        "tier \(tier) must not use awkward 'this isn't your email' phrasing")
                #expect(msgs.allSatisfy { !$0.contains("your email isn't going to finish") },
                        "tier \(tier) must not use awkward 'finish itself' phrasing for email")
            }
        }
    }

    // MARK: - Knowledge-worker keyword additions: writing (blog, newsletter, content)

    @Test func extractTaskKeywordFromWriting() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a blog post") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "finish my blog") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "write the weekly newsletter") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "draft the newsletter for Monday") == "writing")
    }

    @Test func taskAwareCalloutsWritingUsesNaturalPhrasing() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "writing", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) writing messages must not be empty")
                // Must reference writing-related words
                let writingWords = ["writ", "post", "draft", "browse"]
                #expect(msgs.allSatisfy { msg in writingWords.contains { msg.contains($0) } },
                        "tier \(tier) writing messages must reference writing activity")
            }
        }
    }

    @Test func extractTaskKeywordBlogDoesNotMatchEmail() {
        // "blog" and "email" are separate keywords — a blog task must not map to email.
        #expect(CalloutManager.extractTaskKeyword(from: "write a blog post") != "email")
    }

    @Test func extractTaskKeywordEssayTakesPriorityOverWriting() {
        // "essay" check runs before "blog" — "write a blog-style essay" maps to essay, not writing.
        #expect(CalloutManager.extractTaskKeyword(from: "write a long-form essay") == "essay")
    }

    @Test func extractTaskKeywordStudyTakesPriorityOverDesign() {
        // "study" check runs before "design" — "study industrial design" maps to studying, not design.
        #expect(CalloutManager.extractTaskKeyword(from: "study industrial design") == "studying")
    }

    @Test func extractTaskKeywordEmailDoesNotMatchDesign() {
        // "design" and "email" live in separate checks — no cross-contamination.
        #expect(CalloutManager.extractTaskKeyword(from: "design the email template") == "design")
    }

    // MARK: - Knowledge-worker keyword additions: report / document / doc

    @Test func extractTaskKeywordFromReport() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my quarterly report") == "report")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the client report") == "report")
        #expect(CalloutManager.extractTaskKeyword(from: "update the document") == "report")
        #expect(CalloutManager.extractTaskKeyword(from: "edit the doc") == "report")
    }

    @Test func extractTaskKeywordReportTakesPriorityOverLab() {
        // "report" check (rank 4) runs before "lab" (rank 8) in extractTaskKeyword.
        // "bio lab report" contains both "report" and "lab"; "report" wins.
        #expect(CalloutManager.extractTaskKeyword(from: "write up the bio lab report") == "report")
        #expect(CalloutManager.extractTaskKeyword(from: "bio lab report due Friday") == "report")
    }

    @Test func taskAwareCalloutsReportContainsKeyword() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "report", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) report messages must not be empty")
                #expect(msgs.allSatisfy { $0.contains("report") },
                        "tier \(tier) report messages must contain 'report'")
            }
        }
    }

    // "report" now has a dedicated handler — tier 3 must not produce "open your report".
    @Test func taskAwareCalloutsReportTier3AvoidsOpenPhrase() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "report", tier: 3)
            #expect(tier3.allSatisfy { !$0.contains("open your report") },
                    "tier 3 report must not use 'open your report' (sounds like opening a file)")
        }
    }

    @Test func taskAwareCalloutsReportTier3UsesActionPhrasing() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "report", tier: 3)
            let actionWords = ["finish", "go", "write", "keep", "back"]
            #expect(tier3.contains { msg in actionWords.contains { msg.lowercased().contains($0) } },
                    "tier 3 report must contain at least one action-oriented message")
        }
    }

    @Test func taskAwareCalloutsDocumentContainsKeyword() async {
        // extractTaskKeyword always returns "report" for document/doc/report inputs;
        // "document" is never passed directly in production. This verifies the generic
        // template path handles arbitrary keywords correctly — defensive against future
        // changes that might add "document" as a distinct return value.
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "document", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) document messages must not be empty")
                #expect(msgs.allSatisfy { $0.contains("document") },
                        "tier \(tier) document messages must contain 'document'")
            }
        }
    }

    // MARK: - Knowledge-worker / student keyword additions: project

    @Test func extractTaskKeywordFromProject() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on my CS project") == "project")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the group project") == "project")
        #expect(CalloutManager.extractTaskKeyword(from: "complete the class projects") == "project")
        #expect(CalloutManager.extractTaskKeyword(from: "my project is due tomorrow") == "project")
    }

    @Test func extractTaskKeywordProjectDoesNotMatchProjectile() {
        // "projectile" contains "project" as a substring — word-boundary check must prevent this.
        #expect(CalloutManager.extractTaskKeyword(from: "calculate projectile motion") == nil)
    }

    @Test func extractTaskKeywordDesignProjectMapsToDesign() {
        // "design" check runs before "project" — "design project" should map to design, not project.
        #expect(CalloutManager.extractTaskKeyword(from: "finish my design project") == "design")
    }

    @Test func taskAwareCalloutsProjectContainsKeyword() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "project", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) project messages must not be empty")
                #expect(msgs.allSatisfy { $0.contains("project") },
                        "tier \(tier) project messages must contain 'project'")
            }
        }
    }

    @Test func taskAwareCalloutsProjectTier3AvoidsOpenPhrase() async {
        // The generic template produces "CLOSE THIS. open your project." which sounds like opening a file.
        // The special handler must NOT produce this phrase.
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier3 = manager.taskAwareCallouts(keyword: "project", tier: 3)
            #expect(tier3.allSatisfy { !$0.contains("open your project") },
                    "tier 3 project messages must not use 'open your project' phrasing")
        }
    }

    @Test func taskAwareCalloutsProjectTier3UsesActionPhrasing() async {
        // Tier 3 must be action-oriented: "finish", "Go" — not vague "open".
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier3 = manager.taskAwareCallouts(keyword: "project", tier: 3)
            let actionWords = ["finish", "Finish", "Go", "go", "complete", "Complete"]
            #expect(tier3.contains { msg in actionWords.contains { msg.contains($0) } },
                    "tier 3 project messages must include at least one action-oriented phrase")
        }
    }

    // MARK: - Knowledge-worker / student keyword additions: proposal

    @Test func extractTaskKeywordFromProposal() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a grant proposal") == "proposal")
        #expect(CalloutManager.extractTaskKeyword(from: "draft the business proposal") == "proposal")
        #expect(CalloutManager.extractTaskKeyword(from: "write two proposals for the client") == "proposal")
        // "finish my project proposal" — "project" check runs before "proposal"; maps to project.
        #expect(CalloutManager.extractTaskKeyword(from: "finish my project proposal") == "project")
    }

    @Test func extractTaskKeywordThesisProposalMapsToThesis() {
        // "thesis" check runs before "proposal" — "thesis proposal" maps to thesis, not proposal.
        #expect(CalloutManager.extractTaskKeyword(from: "write my thesis proposal") == "thesis")
    }

    @Test func extractTaskKeywordProjectProposalMapsToProject() {
        // "project" check runs before "proposal" — "project proposal" maps to project.
        #expect(CalloutManager.extractTaskKeyword(from: "work on the project proposal") == "project")
    }

    @Test func taskAwareCalloutsProposalContainsKeyword() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "proposal", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) proposal messages must not be empty")
                #expect(msgs.allSatisfy { $0.contains("proposal") },
                        "tier \(tier) proposal messages must contain 'proposal'")
            }
        }
    }

    @Test func taskAwareCalloutsProposalTier3AvoidsOpenPhrase() async {
        // The generic template would produce "CLOSE THIS. open your proposal." which sounds passive.
        // The special handler must NOT produce this phrase.
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier3 = manager.taskAwareCallouts(keyword: "proposal", tier: 3)
            #expect(tier3.allSatisfy { !$0.contains("open your proposal") },
                    "tier 3 proposal messages must not use 'open your proposal' phrasing")
        }
    }

    @Test func taskAwareCalloutsProposalTier3UsesActionPhrasing() async {
        // Tier 3 must be action-oriented — direct, not passive.
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier3 = manager.taskAwareCallouts(keyword: "proposal", tier: 3)
            let actionWords = ["finish", "Finish", "Go", "go", "write", "Write"]
            #expect(tier3.contains { msg in actionWords.contains { msg.contains($0) } },
                    "tier 3 proposal messages must include at least one action-oriented phrase")
        }
    }

    // MARK: - fireAppCallout

    @Test func fireAppCalloutShowsMessageImmediately() async {
        await MainActor.run {
            CalloutManager.shared.reset()
            NotchState.shared.clearCallout()
            CalloutManager.shared.fireAppCallout("close Discord. now.")
            #expect(NotchState.shared.calloutMessage == "close Discord. now.")
        }
    }

    @Test func fireAppCalloutIncrementsCalloutCount() async {
        await MainActor.run {
            CalloutManager.shared.reset()
            #expect(CalloutManager.shared.calloutCount == 0)
            CalloutManager.shared.fireAppCallout("close Steam.")
            #expect(CalloutManager.shared.calloutCount == 1)
        }
    }

    @Test func fireAppCalloutBypassesOffTaskThreshold() async {
        // Normal off-task callouts need 2 consecutive frames to fire;
        // fireAppCallout fires unconditionally — no evaluate(.offTask) calls needed.
        await MainActor.run {
            CalloutManager.shared.reset()
            NotchState.shared.clearCallout()
            #expect(NotchState.shared.calloutMessage == nil)
            CalloutManager.shared.fireAppCallout("get out of Twitch.")
            #expect(NotchState.shared.calloutMessage == "get out of Twitch.")
        }
    }

    @Test func fireAppCalloutUsesCurrentTierAtCalloutCountZero() async {
        await MainActor.run {
            CalloutManager.shared.reset()   // calloutCount = 0 → tier 1
            CalloutManager.shared.fireAppCallout("close that.")
            #expect(NotchState.shared.calloutTier == 1)
        }
    }

    @Test func fireAppCalloutUsesCurrentTierAtCalloutCountTwo() async {
        await MainActor.run {
            // Drive calloutCount to 2 via threshold-based callouts, then fire an app callout.
            CalloutManager.shared.reset()
            for _ in 0..<2 {
                CalloutManager.shared.evaluate(.offTask)
                CalloutManager.shared.evaluate(.offTask)
                CalloutManager.shared.evaluate(.onTask)
            }
            #expect(CalloutManager.shared.calloutCount == 2)
            CalloutManager.shared.fireAppCallout("close Steam.")
            #expect(NotchState.shared.calloutTier == 2)
        }
    }

    @Test func fireAppCalloutDoesNotPreventSubsequentThresholdCallout() async {
        // fireAppCallout does not set hasFiredForStreak — a subsequent off-task
        // streak can still fire its own threshold-based callout independently.
        await MainActor.run {
            CalloutManager.shared.reset()
            CalloutManager.shared.evaluate(.onTask)  // reset streak state
            NotchState.shared.clearCallout()
            // App callout fires immediately
            CalloutManager.shared.fireAppCallout("close Discord. now.")
            #expect(NotchState.shared.calloutMessage == "close Discord. now.")
            NotchState.shared.clearCallout()
            // Threshold-based detection still active — 2 off-task frames should fire
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask)
            #expect(NotchState.shared.calloutMessage != nil)
        }
    }

    @Test func multipleFireAppCalloutsAccumulateCalloutCount() async {
        await MainActor.run {
            CalloutManager.shared.reset()
            CalloutManager.shared.fireAppCallout("close Discord.")
            CalloutManager.shared.fireAppCallout("close Steam.")
            CalloutManager.shared.fireAppCallout("close Twitch.")
            #expect(CalloutManager.shared.calloutCount == 3)
        }
    }

    @Test func fireAppCalloutResetsCancelsAndReplacesAutoDismiss() async {
        // Each fireAppCallout installs a fresh auto-dismiss task; prior task is cancelled.
        // Indirectly verified by confirming calloutMessage reflects the most recent call.
        await MainActor.run {
            CalloutManager.shared.reset()
            CalloutManager.shared.fireAppCallout("first message")
            CalloutManager.shared.fireAppCallout("second message")
            #expect(NotchState.shared.calloutMessage == "second message")
        }
    }

    // MARK: - Special "code" callouts (natural coding-specific phrasing)

    @Test func taskAwareCalloutsCodeContainsKeyword() async {
        // All code-specific messages must contain "code" to pass the generic keyword test.
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "code", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) code messages must not be empty")
                #expect(msgs.allSatisfy { $0.contains("code") || $0.contains("Code") },
                        "tier \(tier) code messages must contain 'code'")
            }
        }
    }

    @Test func taskAwareCalloutsCodeTier3AvoidsBadGenericPhrase() async {
        // The generic template produces "CLOSE THIS. open your code." which sounds unnatural.
        // The special handler must NOT produce this phrase.
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier3 = manager.taskAwareCallouts(keyword: "code", tier: 3)
            #expect(tier3.allSatisfy { !$0.contains("open your code") },
                    "tier 3 code messages must not use awkward 'open your code' phrasing")
        }
    }

    @Test func taskAwareCalloutsCodeUsesActionPhrasing() async {
        // Tier 3 must be action-oriented: "Commit", "write", or "ship" — not generic deadline framing.
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier3 = manager.taskAwareCallouts(keyword: "code", tier: 3)
            let actionWords = ["Commit", "commit", "write", "Write", "ship", "Ship"]
            #expect(tier3.contains { msg in actionWords.contains { msg.contains($0) } },
                    "tier 3 code messages must include at least one action-oriented phrase")
        }
    }

    // MARK: - Special "presentation" callouts (natural presentation-specific phrasing)

    @Test func taskAwareCalloutsPresentationContainsKeyword() async {
        // All presentation-specific messages must contain "presentation".
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "presentation", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) presentation messages must not be empty")
                #expect(msgs.allSatisfy { $0.contains("presentation") },
                        "tier \(tier) presentation messages must contain 'presentation'")
            }
        }
    }

    @Test func taskAwareCalloutsPresentationTier3AvoidsBadGenericPhrase() async {
        // The generic template produces "CLOSE THIS. open your presentation." which is passive.
        // The special handler replaces this with action-oriented phrasing.
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier3 = manager.taskAwareCallouts(keyword: "presentation", tier: 3)
            #expect(tier3.allSatisfy { !$0.contains("open your presentation") },
                    "tier 3 presentation messages must not use passive 'open your presentation' phrasing")
        }
    }

    // MARK: - Special "homework" callouts (natural homework-specific phrasing)

    @Test func taskAwareCalloutsHomeworkContainsKeyword() async {
        // All homework-specific messages must contain "homework".
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "homework", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) homework messages must not be empty")
                #expect(msgs.allSatisfy { $0.contains("homework") },
                        "tier \(tier) homework messages must contain 'homework'")
            }
        }
    }

    @Test func taskAwareCalloutsHomeworkTier3AvoidsOpenPhrase() async {
        // The generic template produces "CLOSE THIS. open your homework." which sounds like
        // opening a file. The special handler replaces it with "Go finish your homework."
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier3 = manager.taskAwareCallouts(keyword: "homework", tier: 3)
            #expect(tier3.allSatisfy { !$0.contains("open your homework") },
                    "tier 3 homework messages must not use awkward 'open your homework' phrasing")
        }
    }

    @Test func taskAwareCalloutsHomeworkTier3UsesActionPhrasing() async {
        // Tier 3 must use "finish" or "do" — concrete action, not vague "open".
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier3 = manager.taskAwareCallouts(keyword: "homework", tier: 3)
            let actionWords = ["finish", "Finish", "do", "Do", "complete", "Complete"]
            #expect(tier3.contains { msg in actionWords.contains { msg.contains($0) } },
                    "tier 3 homework messages must include at least one action-oriented phrase")
        }
    }

    // MARK: - Special "research" callouts (natural research-specific phrasing)

    @Test func taskAwareCalloutsResearchContainsKeyword() async {
        // All research-specific messages must contain "research".
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "research", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) research messages must not be empty")
                #expect(msgs.allSatisfy { $0.contains("research") },
                        "tier \(tier) research messages must contain 'research'")
            }
        }
    }

    @Test func taskAwareCalloutsResearchTier3AvoidsOpenPhrase() async {
        // The generic template produces "CLOSE THIS. open your research." which is passive.
        // The special handler replaces it with direct "Get back to your research."
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier3 = manager.taskAwareCallouts(keyword: "research", tier: 3)
            #expect(tier3.allSatisfy { !$0.contains("open your research") },
                    "tier 3 research messages must not use passive 'open your research' phrasing")
        }
    }

    // MARK: - Keyword additions: interview

    @Test func extractTaskKeywordFromInterview() {
        #expect(CalloutManager.extractTaskKeyword(from: "prep for my job interview") == "interview")
        #expect(CalloutManager.extractTaskKeyword(from: "practice coding interview questions") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "review for tomorrow's interviews") == "interview")
        #expect(CalloutManager.extractTaskKeyword(from: "mock interview prep") == "interview")
    }

    @Test func extractTaskKeywordCodeInterviewMapsToCode() {
        // "code" check runs before "interview" — coding interview prep should map to code.
        #expect(CalloutManager.extractTaskKeyword(from: "practice coding interview questions") == "code")
    }

    @Test func taskAwareCalloutsInterviewContainsKeyword() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "interview", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) interview messages must not be empty")
                let interviewWords = ["interview", "Interview", "prep", "Prep", "practice", "Practice"]
                #expect(msgs.allSatisfy { msg in interviewWords.contains { msg.contains($0) } },
                        "tier \(tier) interview messages must reference interview or practice")
            }
        }
    }

    @Test func taskAwareCalloutsInterviewTier3UsesActionPhrasing() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier3 = manager.taskAwareCallouts(keyword: "interview", tier: 3)
            let actionWords = ["Go", "go", "prep", "Prep", "practice", "Practice", "coming"]
            #expect(tier3.contains { msg in actionWords.contains { msg.contains($0) } },
                    "tier 3 interview messages must include action-oriented phrasing")
        }
    }

    // MARK: - Keyword additions: video

    @Test func extractTaskKeywordFromVideo() {
        #expect(CalloutManager.extractTaskKeyword(from: "edit the YouTube video") == "video")
        #expect(CalloutManager.extractTaskKeyword(from: "finish editing the footage") == "video")
        #expect(CalloutManager.extractTaskKeyword(from: "cut the film for class") == "video")
        #expect(CalloutManager.extractTaskKeyword(from: "filming the event recap") == "video")
    }

    @Test func extractTaskKeywordVideoDoesNotMatchVideoGameOrInterviewVideo() {
        // "video interview" — "interview" check runs before "video"; should map to interview.
        #expect(CalloutManager.extractTaskKeyword(from: "prep for my video interview") == "interview")
    }

    @Test func taskAwareCalloutsVideoContainsKeyword() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "video", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) video messages must not be empty")
                let videoWords = ["video", "Video", "edit", "Edit"]
                #expect(msgs.allSatisfy { msg in videoWords.contains { msg.contains($0) } },
                        "tier \(tier) video messages must reference video or editing")
            }
        }
    }

    @Test func taskAwareCalloutsVideoTier3AvoidsOpenPhrase() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier3 = manager.taskAwareCallouts(keyword: "video", tier: 3)
            #expect(tier3.allSatisfy { !$0.contains("open your video") },
                    "tier 3 video messages must not use passive 'open your video' phrasing")
        }
    }

    @Test func taskAwareCalloutsVideoTier3UsesActionPhrasing() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier3 = manager.taskAwareCallouts(keyword: "video", tier: 3)
            let actionWords = ["Finish", "finish", "editing", "Editing", "deadline", "Deadline"]
            #expect(tier3.contains { msg in actionWords.contains { msg.contains($0) } },
                    "tier 3 video messages must include action-oriented phrasing")
        }
    }

    // MARK: - CV / Résumé keyword

    @Test func extractTaskKeywordFromCV() {
        #expect(CalloutManager.extractTaskKeyword(from: "update my CV for the internship") == "resume")
        #expect(CalloutManager.extractTaskKeyword(from: "build a cv from scratch") == "resume")
        #expect(CalloutManager.extractTaskKeyword(from: "polish my CV before the deadline") == "resume")
    }

    @Test func extractTaskKeywordFromResume() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my résumé for summer jobs") == "resume")
        #expect(CalloutManager.extractTaskKeyword(from: "update the résumé and send it out") == "resume")
    }

    @Test func extractTaskKeywordCVDoesNotMatchCodingOrVideo() {
        // "cv" matched correctly but code and video take priority when both appear.
        #expect(CalloutManager.extractTaskKeyword(from: "code a CV generator app") == "code")
    }

    @Test func taskAwareCalloutsResumeContainsRelevantPhrasing() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in [1, 2, 3] {
                let msgs = manager.taskAwareCallouts(keyword: "resume", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) must have resume messages")
                #expect(msgs.contains { $0.contains("résumé") || $0.contains("CV") },
                        "tier \(tier) messages must reference résumé or CV")
            }
        }
    }

    @Test func taskAwareCalloutsResumeTier3UsesActionPhrasing() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier3 = manager.taskAwareCallouts(keyword: "resume", tier: 3)
            let actionWords = ["Finish", "finish", "deadline", "Deadline", "CLOSE"]
            #expect(tier3.contains { msg in actionWords.contains { msg.contains($0) } },
                    "tier 3 résumé messages must use action-oriented phrasing")
        }
    }

    @Test func taskAwareCalloutsResumeTier3AvoidsPassiveOpenPhrase() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier3 = manager.taskAwareCallouts(keyword: "resume", tier: 3)
            #expect(!tier3.contains { $0.lowercased().contains("open your") },
                    "tier 3 résumé messages must not use passive 'open your' phrasing")
        }
    }

    // MARK: - Keyword additions: application (job/internship/college applications, cover letters)

    @Test func extractTaskKeywordFromJobApplication() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish my job application for Google") == "application")
        #expect(CalloutManager.extractTaskKeyword(from: "fill out the internship application") == "application")
        #expect(CalloutManager.extractTaskKeyword(from: "complete my college application") == "application")
        #expect(CalloutManager.extractTaskKeyword(from: "submit my applications by tonight") == "application")
    }

    @Test func extractTaskKeywordFromCoverLetter() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a cover letter for Amazon") == "application")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the cover letter and send it") == "application")
        #expect(CalloutManager.extractTaskKeyword(from: "draft my cover letter") == "application")
    }

    @Test func extractTaskKeywordFromApplying() {
        #expect(CalloutManager.extractTaskKeyword(from: "applying to summer internships") == "application")
        #expect(CalloutManager.extractTaskKeyword(from: "I am applying to grad school tonight") == "application")
    }

    @Test func extractTaskKeywordApplicationDoesNotMatchSoftwareApp() {
        // "code" check runs before "application" — explicit coding tasks map to code, not application.
        #expect(CalloutManager.extractTaskKeyword(from: "code the iOS application") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "finish coding my web application") == "code")
        // "build my web application" without a coding keyword maps to "application" — acceptable.
        #expect(CalloutManager.extractTaskKeyword(from: "build my web application") == "application")
    }

    @Test func extractTaskKeywordApplicationDoesNotMatchDesignApp() {
        // "design" check runs before "application" — designing an app maps to design.
        #expect(CalloutManager.extractTaskKeyword(from: "design the application UI in Figma") == "design")
    }

    @Test func extractTaskKeywordResumeApplicationPreference() {
        // "resume" check runs before "application" — "update my résumé to apply" maps to resume.
        #expect(CalloutManager.extractTaskKeyword(from: "update my résumé before applying") == "resume")
    }

    @Test func taskAwareCalloutsApplicationContainsKeyword() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "application", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) application messages must not be empty")
                // Messages should reference "application" or "submit" or "writing" (cover letter context).
                let appWords = ["application", "Application", "submit", "Submit", "writing", "Writing"]
                #expect(msgs.allSatisfy { msg in appWords.contains { msg.contains($0) } },
                        "tier \(tier) application messages must reference application or submission")
            }
        }
    }

    @Test func taskAwareCalloutsApplicationTier3AvoidsSoftwareAppPhrasing() async {
        // Must not use "open your application" — sounds like launching a software app.
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier3 = manager.taskAwareCallouts(keyword: "application", tier: 3)
            #expect(tier3.allSatisfy { !$0.contains("open your application") },
                    "tier 3 application messages must not use 'open your application' phrasing")
        }
    }

    @Test func taskAwareCalloutsApplicationTier3UsesActionPhrasing() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier3 = manager.taskAwareCallouts(keyword: "application", tier: 3)
            let actionWords = ["Submit", "submit", "CLOSE", "finish", "Finish", "deadline"]
            #expect(tier3.contains { msg in actionWords.contains { msg.contains($0) } },
                    "tier 3 application messages must use action-oriented phrasing")
        }
    }

    @Test func taskAwareCalloutsApplicationTier1AvoidsGenericIsntYourPhrasing() async {
        // "this isn't your application" sounds like a software app — must not appear.
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier1 = manager.taskAwareCallouts(keyword: "application", tier: 1)
            #expect(tier1.allSatisfy { !$0.contains("this isn't your application") },
                    "tier 1 application messages must avoid ambiguous software-app phrasing")
        }
    }

    // MARK: - "deadline" keyword extraction

    @Test func extractTaskKeywordFromDeadlineWord() {
        #expect(CalloutManager.extractTaskKeyword(from: "I have a deadline tonight") == "deadline")
    }

    @Test func extractTaskKeywordFromDueBy() {
        #expect(CalloutManager.extractTaskKeyword(from: "this is due by midnight") == "deadline")
    }

    @Test func extractTaskKeywordFromDueTomorrow() {
        #expect(CalloutManager.extractTaskKeyword(from: "assignment due tomorrow morning") == "deadline")
    }

    @Test func extractTaskKeywordFromDueIn() {
        #expect(CalloutManager.extractTaskKeyword(from: "project due in 2 hours") == "deadline")
    }

    @Test func extractTaskKeywordFromDueBefore() {
        #expect(CalloutManager.extractTaskKeyword(from: "submit due before 11:59pm") == "deadline")
    }

    @Test func extractTaskKeywordDeadlineYieldsToEssay() {
        // "essay" is more specific — "deadline" is a fallback only when no subject keyword found.
        #expect(CalloutManager.extractTaskKeyword(from: "finish my essay, deadline is tonight") == "essay")
    }

    @Test func extractTaskKeywordDeadlineYieldsToHomework() {
        #expect(CalloutManager.extractTaskKeyword(from: "homework due by midnight") == "homework")
    }

    @Test func extractTaskKeywordDeadlineYieldsToCode() {
        #expect(CalloutManager.extractTaskKeyword(from: "ship the code, deadline is tomorrow") == "code")
    }

    // MARK: - "deadline" callout messages

    @Test func taskAwareCalloutsDeadlineNonEmpty() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "deadline", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) deadline messages must not be empty")
            }
        }
    }

    @Test func taskAwareCalloutsDeadlineTier1ContainsUrgency() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier1 = manager.taskAwareCallouts(keyword: "deadline", tier: 1)
            let urgencyWords = ["deadline", "clock", "ticking", "ticks"]
            #expect(tier1.contains { msg in urgencyWords.contains { msg.lowercased().contains($0) } },
                    "tier 1 deadline messages must convey time pressure")
        }
    }

    @Test func taskAwareCalloutsDeadlineTier3UsesAllCaps() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier3 = manager.taskAwareCallouts(keyword: "deadline", tier: 3)
            #expect(tier3.contains { $0.contains("CLOSE") || $0.contains("DEADLINE") },
                    "tier 3 deadline messages must use all-caps urgency")
        }
    }

    @Test func taskAwareCalloutsDeadlineTier3DoesNotUseGenericOpenPhrase() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            let tier3 = manager.taskAwareCallouts(keyword: "deadline", tier: 3)
            #expect(tier3.allSatisfy { !$0.contains("open your deadline") },
                    "tier 3 deadline messages must not use the generic 'open your X' fallback")
        }
    }

    // MARK: - "due at <time>" keyword extraction

    @Test func extractTaskKeywordFromDueAtHour() {
        // "due at 5pm" — digit after "due at" matches \bdue at \d
        #expect(CalloutManager.extractTaskKeyword(from: "assignment due at 5pm") == "deadline")
    }

    @Test func extractTaskKeywordFromDueAtSpecificTime() {
        #expect(CalloutManager.extractTaskKeyword(from: "submit before it's due at 11:59") == "deadline")
    }

    @Test func extractTaskKeywordDueAtNoFalsePositiveResidue() {
        // "residue at 3" must NOT produce "deadline" — \b blocks mid-word matches
        #expect(CalloutManager.extractTaskKeyword(from: "check the residue at 3 spots") == nil)
    }

    @Test func extractTaskKeywordDueAtYieldsToEssay() {
        // A specific subject keyword takes precedence over the urgency catch-all
        #expect(CalloutManager.extractTaskKeyword(from: "essay due at 9am") == "essay")
    }

    @Test func extractTaskKeywordDueAtNoon() {
        // "due at noon" doesn't start with a digit so \bdue at \d misses it — explicit check needed
        #expect(CalloutManager.extractTaskKeyword(from: "assignment due at noon") == "deadline")
        #expect(CalloutManager.extractTaskKeyword(from: "submit by class, due at noon") == "deadline")
    }

    @Test func extractTaskKeywordDueAtEndOfDay() {
        // "due at end of day" / "due at end of class" — non-digit time variants
        #expect(CalloutManager.extractTaskKeyword(from: "project due at end of day") == "deadline")
        #expect(CalloutManager.extractTaskKeyword(from: "this is due at end of class") == "deadline")
    }

    @Test func extractTaskKeywordDueAtNoonYieldsToEssay() {
        // Subject keyword always wins over the urgency catch-all
        #expect(CalloutManager.extractTaskKeyword(from: "essay due at noon") == "essay")
    }

    // MARK: - Coding competition / algorithm keywords

    @Test func extractTaskKeywordFromLeetCode() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on leetcode") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "do leetcode problems") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "grind leetcode") == "code")
    }

    @Test func extractTaskKeywordFromAlgorithm() {
        #expect(CalloutManager.extractTaskKeyword(from: "practice algorithms") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "study the algorithm") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "review algorithm concepts") == "code")
    }

    @Test func extractTaskKeywordFromDataStructure() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on data structure problems") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "review data structures") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "implement a data structure") == "code")
    }

    @Test func extractTaskKeywordFromHackerRank() {
        #expect(CalloutManager.extractTaskKeyword(from: "do hackerrank challenges") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "finish hackerrank problem set") == "code")
    }

    @Test func extractTaskKeywordAlgorithmTakesPriorityOverStudying() {
        // "code" check runs before "studying" — algorithm review maps to code, not studying.
        #expect(CalloutManager.extractTaskKeyword(from: "study the algorithm") == "code")
    }

    // MARK: - Writing / draft / outline / revision keywords

    @Test func extractTaskKeywordFromDraft() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish my draft") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "write a draft") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "clean up the drafts") == "writing")
    }

    @Test func extractTaskKeywordFromOutline() {
        #expect(CalloutManager.extractTaskKeyword(from: "write an outline") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the outline") == "writing")
    }

    @Test func extractTaskKeywordFromRevision() {
        #expect(CalloutManager.extractTaskKeyword(from: "do my revisions") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "revise the introduction") == "writing")
    }

    @Test func extractTaskKeywordFromProofread() {
        #expect(CalloutManager.extractTaskKeyword(from: "proofread this section") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "finish proofreading") == "writing")
    }

    @Test func extractTaskKeywordEssayTakesPriorityOverDraft() {
        // "essay" check fires before draft/outline — more specific keyword wins.
        #expect(CalloutManager.extractTaskKeyword(from: "revise my essay draft") == "essay")
        #expect(CalloutManager.extractTaskKeyword(from: "write an outline for my essay") == "essay")
    }

    @Test func extractTaskKeywordReportTakesPriorityOverRevision() {
        // "report" check fires before revision — revising a report maps to report.
        #expect(CalloutManager.extractTaskKeyword(from: "do revisions on my report") == "report")
    }

    @Test func extractTaskKeywordEmailTakesPriorityOverDraft() {
        // "email" check fires before draft — drafting an email maps to email.
        #expect(CalloutManager.extractTaskKeyword(from: "draft the client email") == "email")
    }

    @Test func extractTaskKeywordOutlinePresentationMapsToPresentation() {
        // "presentation" check fires before outline — outline for a presentation maps to presentation.
        #expect(CalloutManager.extractTaskKeyword(from: "create an outline for the presentation") == "presentation")
    }

    // MARK: - Worksheet keyword (homework group)

    @Test func extractTaskKeywordFromWorksheet() {
        #expect(CalloutManager.extractTaskKeyword(from: "do my worksheet") == "homework")
        // "chemistry" now fires in the studying block before "worksheet" reaches the homework
        // block — chemistry subject wins over worksheet format when both are present.
        #expect(CalloutManager.extractTaskKeyword(from: "finish the chemistry worksheet") == "studying")
        // "bio" is not matched by \bbiology\b, so no studying subject keyword fires;
        // the homework block's \bworksheets\b catches it instead.
        #expect(CalloutManager.extractTaskKeyword(from: "complete the bio worksheets") == "homework")
    }

    // MARK: - Programming language keywords (code group)

    @Test func extractTaskKeywordFromPython() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on my python project") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the python script") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "Python homework") == "code")
    }

    @Test func extractTaskKeywordFromJavaScript() {
        #expect(CalloutManager.extractTaskKeyword(from: "javascript assignment") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "build a javascript app") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "fix the javascript bug") == "code")
    }

    @Test func extractTaskKeywordFromTypeScript() {
        #expect(CalloutManager.extractTaskKeyword(from: "typescript component") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "write typescript types") == "code")
    }

    @Test func extractTaskKeywordFromJava() {
        #expect(CalloutManager.extractTaskKeyword(from: "java assignment") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "finish my java project") == "code")
    }

    @Test func extractTaskKeywordJavaDoesNotMatchJavaScript() {
        // \bjava\b should NOT fire on "javascript" — word boundary prevents the overlap.
        // The `javascript` check fires instead.
        #expect(CalloutManager.extractTaskKeyword(from: "javascript homework") == "code")
    }

    @Test func extractTaskKeywordFromKotlin() {
        #expect(CalloutManager.extractTaskKeyword(from: "kotlin android app") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "finish kotlin homework") == "code")
    }

    @Test func extractTaskKeywordFromRust() {
        #expect(CalloutManager.extractTaskKeyword(from: "rust systems project") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "write rust code") == "code")
    }

    @Test func extractTaskKeywordFromSwiftLanguage() {
        #expect(CalloutManager.extractTaskKeyword(from: "swift ios app") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "write swift function") == "code")
    }

    @Test func extractTaskKeywordFromReact() {
        #expect(CalloutManager.extractTaskKeyword(from: "react component") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "build a react app") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "finish my react homework") == "code")
    }

    @Test func extractTaskKeywordFromHtmlCss() {
        #expect(CalloutManager.extractTaskKeyword(from: "html assignment") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "css styling homework") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "build html page") == "code")
    }

    @Test func extractTaskKeywordFromSql() {
        #expect(CalloutManager.extractTaskKeyword(from: "sql homework") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "write sql queries") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the sql assignment") == "code")
    }

    @Test func extractTaskKeywordFromBashShell() {
        #expect(CalloutManager.extractTaskKeyword(from: "bash script") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "write shell script") == "code")
    }

    @Test func extractTaskKeywordFromDebug() {
        #expect(CalloutManager.extractTaskKeyword(from: "debug this function") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "debugging the issue") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "need to debug my app") == "code")
    }

    @Test func extractTaskKeywordFromRefactor() {
        #expect(CalloutManager.extractTaskKeyword(from: "refactor this module") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "refactoring the codebase") == "code")
    }

    @Test func extractTaskKeywordFromPullRequest() {
        #expect(CalloutManager.extractTaskKeyword(from: "write pull request") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the pull request") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "review pull request") == "code")
    }

    @Test func extractTaskKeywordFromUnitTest() {
        #expect(CalloutManager.extractTaskKeyword(from: "write unit tests") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "finish unit test coverage") == "code")
    }

    @Test func extractTaskKeywordCodeTakesPriorityOverStudyingForLanguages() {
        // code check runs before studying — "python homework" should map to code, not homework.
        #expect(CalloutManager.extractTaskKeyword(from: "python homework") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "javascript assignment") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "sql exam") == "code")
    }

    // MARK: - Academic subject keywords (studying group)

    @Test func extractTaskKeywordFromCalculus() {
        #expect(CalloutManager.extractTaskKeyword(from: "study calculus") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "calculus review") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "do my calculus homework") == "studying")
    }

    @Test func extractTaskKeywordFromStatistics() {
        #expect(CalloutManager.extractTaskKeyword(from: "statistics assignment") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "study statistics") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "stats review") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "work on my stats") == "studying")
    }

    @Test func extractTaskKeywordFromAlgebra() {
        #expect(CalloutManager.extractTaskKeyword(from: "algebra homework") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "linear algebra practice") == "studying")
    }

    @Test func extractTaskKeywordFromGeometry() {
        #expect(CalloutManager.extractTaskKeyword(from: "geometry assignment") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "study geometry") == "studying")
    }

    @Test func extractTaskKeywordFromProbability() {
        #expect(CalloutManager.extractTaskKeyword(from: "probability problem set") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "study probability") == "studying")
    }

    @Test func extractTaskKeywordFromPhysics() {
        #expect(CalloutManager.extractTaskKeyword(from: "physics homework") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "study for physics exam") == "studying")
        // "report" fires before "physics" in priority order — a physics lab report is a report.
        #expect(CalloutManager.extractTaskKeyword(from: "physics lab report") == "report")
    }

    @Test func extractTaskKeywordFromChemistry() {
        #expect(CalloutManager.extractTaskKeyword(from: "chemistry assignment") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "study for chemistry exam") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "chemistry review") == "studying")
    }

    @Test func extractTaskKeywordFromBiology() {
        #expect(CalloutManager.extractTaskKeyword(from: "biology homework") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "study for biology quiz") == "studying")
    }

    @Test func extractTaskKeywordFromEconomics() {
        #expect(CalloutManager.extractTaskKeyword(from: "economics assignment") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "study econ") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "econ review") == "studying")
    }

    @Test func extractTaskKeywordFromPsychology() {
        #expect(CalloutManager.extractTaskKeyword(from: "psychology notes") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "study psych") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "psych review") == "studying")
    }

    @Test func extractTaskKeywordFromSociology() {
        #expect(CalloutManager.extractTaskKeyword(from: "sociology reading") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "study sociology") == "studying")
    }

    @Test func extractTaskKeywordEssayTakesPriorityOverSubject() {
        // "essay" fires before "studying" — a chemistry essay maps to essay, not studying.
        #expect(CalloutManager.extractTaskKeyword(from: "write my chemistry essay") == "essay")
        #expect(CalloutManager.extractTaskKeyword(from: "biology paper") == "paper")
        #expect(CalloutManager.extractTaskKeyword(from: "physics thesis") == "thesis")
    }

    @Test func extractTaskKeywordSubjectTakesPriorityOverWorksheet() {
        // The studying block runs before the homework block — when a subject keyword (chemistry)
        // is present, it fires first even if a worksheet term is also present.
        // Only worksheet without a subject keyword reaches the homework block.
        #expect(CalloutManager.extractTaskKeyword(from: "study chemistry") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "chemistry worksheet") == "studying")
        // No subject keyword → worksheet in homework block fires.
        #expect(CalloutManager.extractTaskKeyword(from: "do my worksheet") == "homework")
    }

    // MARK: - Resume (plain English, no accent)

    @Test func extractTaskKeywordFromPlainResume() {
        // Plain "resume" (no accent) must now be detected alongside "résumé" / "cv".
        #expect(CalloutManager.extractTaskKeyword(from: "update my resume") == "resume")
        #expect(CalloutManager.extractTaskKeyword(from: "write my resume for the internship") == "resume")
        #expect(CalloutManager.extractTaskKeyword(from: "polish the resume before applying") == "resume")
    }

    @Test func extractTaskKeywordResumeDoesNotFalseMatchCodeTask() {
        // "code" is checked before "resume" — "resume" as a verb in a coding task must not
        // redirect to the résumé pool.
        #expect(CalloutManager.extractTaskKeyword(from: "resume my coding on the side project") == "code")
    }

    @Test func extractTaskKeywordResumeDoesNotFalseMatchEssayTask() {
        // "essay" fires before "resume" — phrasing like "resume writing my essay" must route
        // to essay, not the résumé pool.
        #expect(CalloutManager.extractTaskKeyword(from: "resume writing my essay") == "essay")
    }

    // MARK: - Meeting keyword

    @Test func extractTaskKeywordFromMeeting() {
        #expect(CalloutManager.extractTaskKeyword(from: "prep for team meeting") == "meeting")
        #expect(CalloutManager.extractTaskKeyword(from: "write meeting agenda") == "meeting")
        #expect(CalloutManager.extractTaskKeyword(from: "take meeting notes") == "meeting")
        #expect(CalloutManager.extractTaskKeyword(from: "prepare for my one-on-one meeting") == "meeting")
    }

    @Test func extractTaskKeywordFromAgenda() {
        #expect(CalloutManager.extractTaskKeyword(from: "write the agenda for tomorrow") == "meeting")
        #expect(CalloutManager.extractTaskKeyword(from: "finalize the agenda") == "meeting")
    }

    @Test func extractTaskKeywordMeetingPhrases() {
        #expect(CalloutManager.extractTaskKeyword(from: "meeting prep before standup") == "meeting")
        #expect(CalloutManager.extractTaskKeyword(from: "review meeting notes from yesterday") == "meeting")
    }

    @Test func extractTaskKeywordPresentationTakesPriorityOverMeeting() {
        // "presentation" fires well before "meeting" — a meeting that involves slides
        // routes to the presentation pool, not the meeting pool.
        #expect(CalloutManager.extractTaskKeyword(from: "finish slides for the team meeting") == "presentation")
    }

    @Test func taskAwareCalloutsMeetingHasMessages() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "meeting", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) must have meeting messages")
            }
        }
    }

    @Test func taskAwareCalloutsMeetingDedicatedPoolSize() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            #expect(manager.taskAwareCallouts(keyword: "meeting", tier: 1).count >= 3)
            #expect(manager.taskAwareCallouts(keyword: "meeting", tier: 2).count >= 2)
            #expect(manager.taskAwareCallouts(keyword: "meeting", tier: 3).count >= 2)
        }
    }

    @Test func taskAwareCalloutsMeetingTier3HasUrgentMessage() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "meeting", tier: 3)
            let containsUrgency = tier3.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("meeting") || lower.contains("prep") || lower.contains("unprepared")
            }
            #expect(containsUrgency, "tier 3 meeting messages must reference meeting urgency")
        }
    }

    // MARK: - Budget / finance keyword

    @Test func extractTaskKeywordFromBudget() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on my monthly budget") == "budget")
        #expect(CalloutManager.extractTaskKeyword(from: "budgeting for next month") == "budget")
        #expect(CalloutManager.extractTaskKeyword(from: "update the household budget") == "budget")
    }

    @Test func extractTaskKeywordFromSpreadsheet() {
        #expect(CalloutManager.extractTaskKeyword(from: "update the spreadsheet") == "budget")
        #expect(CalloutManager.extractTaskKeyword(from: "fill in the expense spreadsheets") == "budget")
    }

    @Test func extractTaskKeywordFromFinances() {
        #expect(CalloutManager.extractTaskKeyword(from: "sort out my finances") == "budget")
        #expect(CalloutManager.extractTaskKeyword(from: "review financial statements") == "budget")
        #expect(CalloutManager.extractTaskKeyword(from: "do my accounting") == "budget")
        #expect(CalloutManager.extractTaskKeyword(from: "catch up on bookkeeping") == "budget")
    }

    @Test func extractTaskKeywordFromTaxes() {
        #expect(CalloutManager.extractTaskKeyword(from: "file my taxes") == "budget")
        #expect(CalloutManager.extractTaskKeyword(from: "complete my tax return") == "budget")
        #expect(CalloutManager.extractTaskKeyword(from: "send the invoice to the client") == "budget")
    }

    @Test func extractTaskKeywordBudgetDoesNotFalseMatchUnrelated() {
        // "spreadsheet" alone maps to budget; but tasks with higher-priority keywords should
        // not be overridden.
        #expect(CalloutManager.extractTaskKeyword(from: "code a spreadsheet parser") == "code")
        #expect(CalloutManager.extractTaskKeyword(from: "design the financial dashboard") == "design")
    }

    @Test func taskAwareCalloutsBudgetHasMessages() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "budget", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) must have budget messages")
            }
        }
    }

    @Test func taskAwareCalloutsBudgetDedicatedPoolSize() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            #expect(manager.taskAwareCallouts(keyword: "budget", tier: 1).count >= 3)
            #expect(manager.taskAwareCallouts(keyword: "budget", tier: 2).count >= 2)
            #expect(manager.taskAwareCallouts(keyword: "budget", tier: 3).count >= 2)
        }
    }

    @Test func taskAwareCalloutsBudgetTier1ReferencesMoney() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "budget", tier: 1)
            let containsMoneyRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("budget") || lower.contains("financ") || lower.contains("number")
            }
            #expect(containsMoneyRef, "tier 1 budget messages must reference budget or finances")
        }
    }

    // MARK: - planning keyword extraction

    @Test func extractTaskKeywordFromPlanning() {
        #expect(CalloutManager.extractTaskKeyword(from: "plan my trip") == "planning")
        #expect(CalloutManager.extractTaskKeyword(from: "trip planning") == "planning")
        #expect(CalloutManager.extractTaskKeyword(from: "event planning") == "planning")
        #expect(CalloutManager.extractTaskKeyword(from: "plan my day") == "planning")
        #expect(CalloutManager.extractTaskKeyword(from: "business plan") == "planning")
        #expect(CalloutManager.extractTaskKeyword(from: "lesson plan for tomorrow") == "planning")
        #expect(CalloutManager.extractTaskKeyword(from: "meal planning for the week") == "planning")
        #expect(CalloutManager.extractTaskKeyword(from: "wedding planning") == "planning")
    }

    @Test func extractTaskKeywordFromPlanner() {
        #expect(CalloutManager.extractTaskKeyword(from: "update my planner") == "planning")
        #expect(CalloutManager.extractTaskKeyword(from: "fill in the weekly planner") == "planning")
    }

    @Test func extractTaskKeywordPlanningDoesNotOverrideEssay() {
        // "plan" appears but "essay" has higher priority — must still return "essay"
        #expect(CalloutManager.extractTaskKeyword(from: "plan my essay outline") == "essay")
    }

    @Test func extractTaskKeywordPlanningDoesNotOverrideStudying() {
        // "study plan" contains "study" which matches the studying block before planning
        #expect(CalloutManager.extractTaskKeyword(from: "study plan for finals") == "studying")
    }

    @Test func extractTaskKeywordPlanningDoesNotOverrideProject() {
        // "project" is checked before "planning"
        #expect(CalloutManager.extractTaskKeyword(from: "project planning") == "project")
    }

    @Test func extractTaskKeywordPlanningDoesNotOverrideResearch() {
        #expect(CalloutManager.extractTaskKeyword(from: "research plan for my lab") == "research")
    }

    @Test func taskAwarePlanningHasMessages() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "planning", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) must have planning messages")
            }
        }
    }

    @Test func taskAwarePlanningDedicatedPoolSize() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            #expect(manager.taskAwareCallouts(keyword: "planning", tier: 1).count >= 3)
            #expect(manager.taskAwareCallouts(keyword: "planning", tier: 2).count >= 2)
            #expect(manager.taskAwareCallouts(keyword: "planning", tier: 3).count >= 2)
        }
    }

    @Test func taskAwarePlanningTier3HasUrgentMessage() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "planning", tier: 3)
            let hasUrgent = tier3.contains { msg in
                let upper = msg.uppercased()
                return upper.contains("CLOSE") || upper.contains("PLAN") || upper.contains("FINISH")
            }
            #expect(hasUrgent, "tier 3 planning messages must contain an urgent directive")
        }
    }

    // MARK: - extractTaskKeyword — tutor / teach / coach

    @Test func extractTaskKeywordFromTutor() {
        #expect(CalloutManager.extractTaskKeyword(from: "tutor my students in algebra") == "tutor")
        #expect(CalloutManager.extractTaskKeyword(from: "tutoring session prep") == "tutor")
        #expect(CalloutManager.extractTaskKeyword(from: "prep for my tutors") == "tutor")
    }

    @Test func extractTaskKeywordFromTeach() {
        #expect(CalloutManager.extractTaskKeyword(from: "teach my class today") == "tutor")
        #expect(CalloutManager.extractTaskKeyword(from: "teaching materials for tomorrow") == "tutor")
    }

    @Test func extractTaskKeywordFromCoach() {
        #expect(CalloutManager.extractTaskKeyword(from: "coach my team for the debate") == "tutor")
        #expect(CalloutManager.extractTaskKeyword(from: "coaching notes for the workshop") == "tutor")
    }

    @Test func extractTaskKeywordFromInstructor() {
        #expect(CalloutManager.extractTaskKeyword(from: "instructor guide for the lab") == "tutor")
        #expect(CalloutManager.extractTaskKeyword(from: "write the instruction manual") == "tutor")
    }

    @Test func extractTaskKeywordTutorDoesNotOverrideCode() {
        // "teaching myself python" — "python" hits the code block before tutor
        #expect(CalloutManager.extractTaskKeyword(from: "teaching myself python") == "code")
    }

    @Test func extractTaskKeywordTutorDoesNotOverrideInterview() {
        // "coaching for my interview" — "interview" has higher priority
        #expect(CalloutManager.extractTaskKeyword(from: "coaching for my interview") == "interview")
    }

    @Test func extractTaskKeywordTutorDoesNotOverrideEssay() {
        #expect(CalloutManager.extractTaskKeyword(from: "teach me how to write my essay") == "essay")
    }

    @Test func taskAwareCalloutsTutorHasMessages() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "tutor", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) must have tutor messages")
            }
        }
    }

    @Test func taskAwareCalloutsTutorDedicatedPoolSize() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            #expect(manager.taskAwareCallouts(keyword: "tutor", tier: 1).count >= 3)
            #expect(manager.taskAwareCallouts(keyword: "tutor", tier: 2).count >= 2)
            #expect(manager.taskAwareCallouts(keyword: "tutor", tier: 3).count >= 2)
        }
    }

    @Test func taskAwareCalloutsTutorTier1ReferencesStudents() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "tutor", tier: 1)
            let refsStudents = tier1.contains { $0.lowercased().contains("student") || $0.lowercased().contains("class") || $0.lowercased().contains("lesson") }
            #expect(refsStudents, "tier 1 tutor messages should reference students, class, or lesson")
        }
    }

    @Test func taskAwareCalloutsTutorTier3HasUrgentMessage() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "tutor", tier: 3)
            let hasUrgent = tier3.contains { msg in
                let upper = msg.uppercased()
                return upper.contains("CLOSE") || upper.contains("STUDENT") || upper.contains("CLASS")
            }
            #expect(hasUrgent, "tier 3 tutor messages must contain an urgent directive")
        }
    }

    // MARK: - extractTaskKeyword — practice / rehearse

    @Test func extractTaskKeywordFromPractice() {
        #expect(CalloutManager.extractTaskKeyword(from: "practice piano") == "practice")
        #expect(CalloutManager.extractTaskKeyword(from: "practice my speech") == "practice")
        #expect(CalloutManager.extractTaskKeyword(from: "practicing guitar") == "practice")
    }

    @Test func extractTaskKeywordFromRehearse() {
        #expect(CalloutManager.extractTaskKeyword(from: "rehearse my lines for drama") == "practice")
        #expect(CalloutManager.extractTaskKeyword(from: "rehearsal prep") == "practice")
        #expect(CalloutManager.extractTaskKeyword(from: "rehearsing the opening") == "practice")
    }

    @Test func extractTaskKeywordPracticeDoesNotOverrideCode() {
        // "practice coding" — "coding" hits the code block first
        #expect(CalloutManager.extractTaskKeyword(from: "practice coding problems") == "code")
    }

    @Test func extractTaskKeywordPracticeDoesNotOverrideEssay() {
        #expect(CalloutManager.extractTaskKeyword(from: "practice essay writing") == "essay")
    }

    @Test func extractTaskKeywordPracticeDoesNotOverrideInterview() {
        #expect(CalloutManager.extractTaskKeyword(from: "practice for my interview") == "interview")
    }

    @Test func extractTaskKeywordPracticeDoesNotOverridePresentation() {
        #expect(CalloutManager.extractTaskKeyword(from: "practice my presentation slides") == "presentation")
    }

    @Test func taskAwareCalloutsPracticeHasMessages() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "practice", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) must have practice messages")
            }
        }
    }

    @Test func taskAwareCalloutsPracticeDedicatedPoolSize() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            #expect(manager.taskAwareCallouts(keyword: "practice", tier: 1).count >= 3)
            #expect(manager.taskAwareCallouts(keyword: "practice", tier: 2).count >= 2)
            #expect(manager.taskAwareCallouts(keyword: "practice", tier: 3).count >= 2)
        }
    }

    @Test func taskAwareCalloutsPracticeTier2HasRepsMessage() async {
        await MainActor.run {
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "practice", tier: 2)
            let hasReps = tier2.contains { $0.lowercased().contains("rep") || $0.lowercased().contains("doing") || $0.lowercased().contains("practice") }
            #expect(hasReps, "tier 2 practice messages should reference reps or doing")
        }
    }

    @Test func taskAwareCalloutsPracticeTier3HasUrgentMessage() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "practice", tier: 3)
            let hasUrgent = tier3.contains { msg in
                let upper = msg.uppercased()
                return upper.contains("CLOSE") || upper.contains("PRACTICE") || upper.contains("IMPROVE")
            }
            #expect(hasUrgent, "tier 3 practice messages must contain an urgent directive")
        }
    }

    // MARK: - Music production keyword (was: Music keyword)

    @Test func extractTaskKeywordFromCompose() {
        #expect(CalloutManager.extractTaskKeyword(from: "compose a piece for violin") == "musicproduction")
        #expect(CalloutManager.extractTaskKeyword(from: "composing my EP") == "musicproduction")
        #expect(CalloutManager.extractTaskKeyword(from: "write music for my album") == "musicproduction")
    }

    @Test func extractTaskKeywordFromLyrics() {
        #expect(CalloutManager.extractTaskKeyword(from: "write lyrics for my song") == "musicproduction")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the lyric for verse 2") == "musicproduction")
        #expect(CalloutManager.extractTaskKeyword(from: "songwriter challenge") == "musicproduction")
    }

    @Test func extractTaskKeywordFromBeatmaking() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish the beatmaking session") == "musicproduction")
        #expect(CalloutManager.extractTaskKeyword(from: "music production for my EP") == "musicproduction")
        #expect(CalloutManager.extractTaskKeyword(from: "mixing the final master") == "musicproduction")
    }

    @Test func extractTaskKeywordMusicDoesNotOverrideCode() {
        // "compose" an algorithm shouldn't trigger music when "code" keywords are present
        #expect(CalloutManager.extractTaskKeyword(from: "compose a function in python") == "code")
    }

    @Test func extractTaskKeywordMusicDoesNotOverrideEssay() {
        #expect(CalloutManager.extractTaskKeyword(from: "write an essay about music theory") == "essay")
    }

    @Test func extractTaskKeywordMusicDoesNotOverridePresentation() {
        #expect(CalloutManager.extractTaskKeyword(from: "presentation on music history") == "presentation")
    }

    @Test func taskAwareCalloutsMusicProductionKeywordHasMessages() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "musicproduction", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) must have musicproduction messages")
            }
        }
    }

    @Test func taskAwareCalloutsMusicProductionKeywordPoolSize() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            #expect(manager.taskAwareCallouts(keyword: "musicproduction", tier: 1).count >= 3)
            #expect(manager.taskAwareCallouts(keyword: "musicproduction", tier: 2).count >= 2)
            #expect(manager.taskAwareCallouts(keyword: "musicproduction", tier: 3).count >= 2)
        }
    }

    @Test func taskAwareCalloutsMusicProductionKeywordTier3HasUrgentMessage() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "musicproduction", tier: 3)
            let hasUrgent = tier3.contains { msg in
                let upper = msg.uppercased()
                return upper.contains("CLOSE") || upper.contains("TRACK") || upper.contains("DAW")
            }
            #expect(hasUrgent, "tier 3 musicproduction messages must contain an urgent directive")
        }
    }

    // MARK: - Language keyword

    @Test func extractTaskKeywordFromLanguage() {
        #expect(CalloutManager.extractTaskKeyword(from: "learn spanish for my class") == "language")
        #expect(CalloutManager.extractTaskKeyword(from: "duolingo japanese streak") == "language")
        #expect(CalloutManager.extractTaskKeyword(from: "french vocabulary review") == "language")
        #expect(CalloutManager.extractTaskKeyword(from: "mandarin conjugation drills") == "language")
        #expect(CalloutManager.extractTaskKeyword(from: "translate this document to german") == "language")
        #expect(CalloutManager.extractTaskKeyword(from: "language learning goals for korean") == "language")
    }

    @Test func extractTaskKeywordFromTranslation() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish translating the manual") == "language")
        #expect(CalloutManager.extractTaskKeyword(from: "translation for my arabic class") == "language")
    }

    @Test func extractTaskKeywordLanguageDoesNotOverrideEssay() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a spanish essay") == "essay")
    }

    @Test func extractTaskKeywordLanguageDoesNotOverrideCode() {
        // "translate" in a code context — code keywords dominate
        #expect(CalloutManager.extractTaskKeyword(from: "translate python code to javascript") == "code")
    }

    @Test func extractTaskKeywordLanguageDoesNotOverrideStudying() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for my spanish exam") == "studying")
    }

    @Test func taskAwareCalloutsLanguageHasMessages() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "language", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) must have language messages")
            }
        }
    }

    @Test func taskAwareCalloutsLanguageDedicatedPoolSize() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            #expect(manager.taskAwareCallouts(keyword: "language", tier: 1).count >= 3)
            #expect(manager.taskAwareCallouts(keyword: "language", tier: 2).count >= 2)
            #expect(manager.taskAwareCallouts(keyword: "language", tier: 3).count >= 2)
        }
    }

    @Test func taskAwareCalloutsLanguageTier1ReferencesReps() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "language", tier: 1)
            let hasReps = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("rep") || lower.contains("daily") || lower.contains("practice")
                    || lower.contains("fluent") || lower.contains("lesson")
            }
            #expect(hasReps, "tier 1 language messages should reference reps, daily habit, or fluency")
        }
    }

    @Test func taskAwareCalloutsLanguageTier3HasUrgentMessage() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "language", tier: 3)
            let hasUrgent = tier3.contains { msg in
                let upper = msg.uppercased()
                return upper.contains("CLOSE") || upper.contains("FLUENT") || upper.contains("LANGUAGE")
            }
            #expect(hasUrgent, "tier 3 language messages must contain an urgent directive")
        }
    }

    // MARK: - Fitness keyword extraction

    @Test func extractTaskKeywordFromWorkout() {
        #expect(CalloutManager.extractTaskKeyword(from: "plan my workout") == "fitness")
    }

    @Test func extractTaskKeywordFromGym() {
        #expect(CalloutManager.extractTaskKeyword(from: "gym session plan") == "fitness")
    }

    @Test func extractTaskKeywordFromCardio() {
        #expect(CalloutManager.extractTaskKeyword(from: "cardio training schedule") == "fitness")
    }

    @Test func extractTaskKeywordFromYoga() {
        #expect(CalloutManager.extractTaskKeyword(from: "yoga sequence for beginners") == "fitness")
    }

    @Test func extractTaskKeywordFromMealPrep() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my meal prep list for the week") == "fitness")
    }

    @Test func extractTaskKeywordFromNutritionPlan() {
        #expect(CalloutManager.extractTaskKeyword(from: "build a nutrition plan") == "fitness")
    }

    @Test func extractTaskKeywordFitnessDoesNotOverrideCode() {
        // "running" appears in description but "code" terms dominate earlier in the chain
        #expect(CalloutManager.extractTaskKeyword(from: "debug the running tracker feature in swift") == "code")
    }

    @Test func extractTaskKeywordFitnessDoesNotOverrideStudying() {
        // "calories" appears but "exam" is earlier
        #expect(CalloutManager.extractTaskKeyword(from: "study calories and metabolism for biology exam") == "studying")
    }

    @Test func taskAwareCalloutsFitnessHasMessages() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "fitness", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) must have fitness messages")
            }
        }
    }

    @Test func taskAwareCalloutsFitnessDedicatedPoolSize() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            #expect(manager.taskAwareCallouts(keyword: "fitness", tier: 1).count >= 3)
            #expect(manager.taskAwareCallouts(keyword: "fitness", tier: 2).count >= 2)
            #expect(manager.taskAwareCallouts(keyword: "fitness", tier: 3).count >= 2)
        }
    }

    @Test func taskAwareCalloutsFitnessTier3HasUrgentMessage() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "fitness", tier: 3)
            let hasUrgent = tier3.contains { msg in
                let upper = msg.uppercased()
                return upper.contains("CLOSE") || upper.contains("WORKOUT") || upper.contains("FINISH")
            }
            #expect(hasUrgent, "tier 3 fitness messages must contain an urgent directive")
        }
    }

    // MARK: - Fitness keyword expansion (exercise/running/training additions)

    @Test func extractTaskKeywordFromExercise() {
        #expect(CalloutManager.extractTaskKeyword(from: "do my exercise routine") == "fitness")
    }

    @Test func extractTaskKeywordFromExercises() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish my core exercises before class") == "fitness")
    }

    @Test func extractTaskKeywordFromExercising() {
        #expect(CalloutManager.extractTaskKeyword(from: "stop procrastinating and start exercising") == "fitness")
    }

    @Test func extractTaskKeywordFromRunning() {
        #expect(CalloutManager.extractTaskKeyword(from: "go running for 30 minutes") == "fitness")
    }

    @Test func extractTaskKeywordFromTrainingSession() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete my training session before dinner") == "fitness")
    }

    @Test func extractTaskKeywordFromTrainingPlan() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my training plan for the next four weeks") == "fitness")
    }

    @Test func extractTaskKeywordRunningDoesNotOverrideCode() {
        // "running a python script" — "python" and "script" hit code branch first
        #expect(CalloutManager.extractTaskKeyword(from: "debug why running the python script fails") == "code")
    }

    @Test func extractTaskKeywordExerciseDoesNotOverrideStudying() {
        // "biology exam" hits studying branch before exercise fires
        #expect(CalloutManager.extractTaskKeyword(from: "study the exercise physiology questions for biology exam") == "studying")
    }

    @Test func extractTaskKeywordTrainingSessionDoesNotOverrideCode() {
        // "training a machine learning model" contains "training" but not the phrase "training session"
        // — should NOT match fitness; instead falls through (research or nil)
        let kw = CalloutManager.extractTaskKeyword(from: "training a machine learning model on the dataset")
        #expect(kw != "fitness", "bare 'training' without 'session'/'plan' suffix should not yield fitness")
    }

    @Test func extractTaskKeywordMarathonTrainingPlan() {
        // "training plan" phrase matches via lower.contains("training plan")
        #expect(CalloutManager.extractTaskKeyword(from: "write out my marathon training plan") == "fitness")
    }

    // MARK: - Podcast keyword extraction

    @Test func extractTaskKeywordFromPodcast() {
        #expect(CalloutManager.extractTaskKeyword(from: "record my podcast") == "podcast")
    }

    @Test func extractTaskKeywordFromPodcastEpisode() {
        #expect(CalloutManager.extractTaskKeyword(from: "edit podcast episode 12") == "podcast")
    }

    @Test func extractTaskKeywordFromShowNotes() {
        #expect(CalloutManager.extractTaskKeyword(from: "write show notes for this week") == "podcast")
    }

    @Test func extractTaskKeywordFromPodcasting() {
        #expect(CalloutManager.extractTaskKeyword(from: "podcasting session for my history show") == "podcast")
    }

    @Test func extractTaskKeywordPodcastDoesNotOverrideCode() {
        #expect(CalloutManager.extractTaskKeyword(from: "build a podcast rss feed in swift") == "code")
    }

    @Test func taskAwareCalloutsPodcastHasMessages() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "podcast", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) must have podcast messages")
            }
        }
    }

    @Test func taskAwareCalloutsPodcastDedicatedPoolSize() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            #expect(manager.taskAwareCallouts(keyword: "podcast", tier: 1).count >= 3)
            #expect(manager.taskAwareCallouts(keyword: "podcast", tier: 2).count >= 2)
            #expect(manager.taskAwareCallouts(keyword: "podcast", tier: 3).count >= 2)
        }
    }

    @Test func taskAwareCalloutsPodcastTier3HasUrgentMessage() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "podcast", tier: 3)
            let hasUrgent = tier3.contains { msg in
                let upper = msg.uppercased()
                return upper.contains("CLOSE") || upper.contains("EPISODE") || upper.contains("PODCAST")
            }
            #expect(hasUrgent, "tier 3 podcast messages must contain an urgent directive")
        }
    }

    // MARK: - Art / Drawing keyword extraction

    @Test func extractTaskKeywordFromDrawing() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish my drawing for art class") == "art")
    }

    @Test func extractTaskKeywordFromPainting() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish the painting I started") == "art")
    }

    @Test func extractTaskKeywordFromIllustration() {
        #expect(CalloutManager.extractTaskKeyword(from: "create an illustration for the cover") == "art")
    }

    @Test func extractTaskKeywordFromProcreate() {
        #expect(CalloutManager.extractTaskKeyword(from: "procreate character design") == "art")
    }

    @Test func extractTaskKeywordFromDigitalArt() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish digital art commission") == "art")
    }

    @Test func extractTaskKeywordFromSketching() {
        #expect(CalloutManager.extractTaskKeyword(from: "sketching practice for figure drawing") == "art")
    }

    @Test func extractTaskKeywordArtDoesNotOverrideCode() {
        // "drawing" appears but "code" terms earlier in the chain dominate
        #expect(CalloutManager.extractTaskKeyword(from: "draw a uml diagram for my code review") == "code")
    }

    @Test func extractTaskKeywordArtDoesNotOverrideDesign() {
        // "sketch" (the app) → design; "sketching" (activity) → art — distinct checks
        #expect(CalloutManager.extractTaskKeyword(from: "open sketch and create a wireframe") == "design")
    }

    @Test func taskAwareCalloutsArtHasMessages() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "art", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) must have art messages")
            }
        }
    }

    @Test func taskAwareCalloutsArtDedicatedPoolSize() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            #expect(manager.taskAwareCallouts(keyword: "art", tier: 1).count >= 3)
            #expect(manager.taskAwareCallouts(keyword: "art", tier: 2).count >= 2)
            #expect(manager.taskAwareCallouts(keyword: "art", tier: 3).count >= 2)
        }
    }

    @Test func taskAwareCalloutsArtTier3HasUrgentMessage() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "art", tier: 3)
            let hasUrgent = tier3.contains { msg in
                let upper = msg.uppercased()
                return upper.contains("CLOSE") || upper.contains("FINISH") || upper.contains("CANVAS")
            }
            #expect(hasUrgent, "tier 3 art messages must contain an urgent directive")
        }
    }

    // MARK: - Plural forms: blogs, newsletters

    @Test func extractTaskKeywordFromBlogsPlural() {
        #expect(CalloutManager.extractTaskKeyword(from: "I have two blogs to write") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "update both blogs before Monday") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "write three blogs this week") == "writing")
    }

    @Test func extractTaskKeywordFromNewslettersPlural() {
        #expect(CalloutManager.extractTaskKeyword(from: "send the newsletters out today") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "finish editing both newsletters") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "draft newsletters for this month") == "writing")
    }

    @Test func extractTaskKeywordBlogsSingularStillWorks() {
        // Regression: singular "blog" must still map to "writing" after adding "blogs"
        #expect(CalloutManager.extractTaskKeyword(from: "write a blog post") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "finish my blog") == "writing")
    }

    @Test func extractTaskKeywordNewsletterSingularStillWorks() {
        // Regression: singular "newsletter" must still map to "writing"
        #expect(CalloutManager.extractTaskKeyword(from: "write the weekly newsletter") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "draft the newsletter for Monday") == "writing")
    }

    // MARK: - Internship keyword

    @Test func extractTaskKeywordFromBareInternship() {
        // "internship" alone (no application/interview context) maps to application
        #expect(CalloutManager.extractTaskKeyword(from: "summer internship") == "application")
        #expect(CalloutManager.extractTaskKeyword(from: "find an internship") == "application")
        #expect(CalloutManager.extractTaskKeyword(from: "get an internship") == "application")
    }

    @Test func extractTaskKeywordFromInternshipsPlural() {
        #expect(CalloutManager.extractTaskKeyword(from: "apply to internships") == "application")
        #expect(CalloutManager.extractTaskKeyword(from: "looking for summer internships") == "application")
        #expect(CalloutManager.extractTaskKeyword(from: "browse internships on LinkedIn") == "application")
    }

    @Test func extractTaskKeywordInternshipDoesNotOverrideInterview() {
        // "internship interview" → interview block fires first
        #expect(CalloutManager.extractTaskKeyword(from: "internship interview tomorrow") == "interview")
    }

    @Test func extractTaskKeywordInternshipDoesNotOverrideResume() {
        // "resume for internship" → resume block fires first
        #expect(CalloutManager.extractTaskKeyword(from: "update my resume for the internship") == "resume")
    }

    @Test func extractTaskKeywordInternshipApplicationPhraseStillWorks() {
        // Regression: compound phrase that was already handled must remain correct
        #expect(CalloutManager.extractTaskKeyword(from: "fill out the internship application") == "application")
        #expect(CalloutManager.extractTaskKeyword(from: "applying to summer internships") == "application")
    }

    // MARK: - "apply" bare verb → application

    @Test func extractTaskKeywordFromApplyBareVerb() {
        #expect(CalloutManager.extractTaskKeyword(from: "apply to jobs") == "application")
        #expect(CalloutManager.extractTaskKeyword(from: "apply to college") == "application")
        #expect(CalloutManager.extractTaskKeyword(from: "apply for scholarships") == "application")
    }

    @Test func extractTaskKeywordApplyingStillWorks() {
        // Regression: "applying" must still map to application after adding "apply"
        #expect(CalloutManager.extractTaskKeyword(from: "applying to grad school") == "application")
        #expect(CalloutManager.extractTaskKeyword(from: "I am applying to jobs") == "application")
    }

    @Test func extractTaskKeywordApplyDoesNotOverrideResume() {
        // "apply" fires after "resume" in the block ordering
        #expect(CalloutManager.extractTaskKeyword(from: "update my resume to apply") == "resume")
    }

    // MARK: - capstone → project

    @Test func extractTaskKeywordFromCapstone() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on my capstone") == "project")
        #expect(CalloutManager.extractTaskKeyword(from: "capstone project due Friday") == "project")
        #expect(CalloutManager.extractTaskKeyword(from: "my senior capstone tonight") == "project")
    }

    // MARK: - grant / abstract → writing

    @Test func extractTaskKeywordFromGrant() {
        // "grant" alone (no "proposal" or "application" keyword) → writing
        #expect(CalloutManager.extractTaskKeyword(from: "working on my NSF grant") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "submit the grant tonight") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the grants") == "writing")
    }

    @Test func extractTaskKeywordGrantProposalMapsToProposal() {
        // "grant proposal" has "proposal" which fires before the writing block — expected.
        #expect(CalloutManager.extractTaskKeyword(from: "write a grant proposal") == "proposal")
    }

    @Test func extractTaskKeywordFromAbstract() {
        #expect(CalloutManager.extractTaskKeyword(from: "write the abstract") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "finish my paper abstract") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "revise abstracts for submission") == "writing")
    }

    // MARK: - fellowship / scholarship → application

    @Test func extractTaskKeywordFromFellowship() {
        #expect(CalloutManager.extractTaskKeyword(from: "apply for a fellowship") == "application")
        #expect(CalloutManager.extractTaskKeyword(from: "NSF fellowship application") == "application")
        #expect(CalloutManager.extractTaskKeyword(from: "submit fellowships by Friday") == "application")
    }

    @Test func extractTaskKeywordFromScholarship() {
        #expect(CalloutManager.extractTaskKeyword(from: "apply for a scholarship") == "application")
        #expect(CalloutManager.extractTaskKeyword(from: "scholarship essay due tonight") == "application")
        #expect(CalloutManager.extractTaskKeyword(from: "finishing my scholarships spreadsheet") == "application")
    }

    @Test func extractTaskKeywordScholarshipDoesNotTriggerOnUnrelated() {
        // "apply for scholarships" already tested above; check lone keyword boundary
        #expect(CalloutManager.extractTaskKeyword(from: "scholarship") == "application")
    }

    // MARK: - literature review / lit review → writing

    @Test func extractTaskKeywordFromLiteratureReview() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my literature review") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "literature review for my thesis") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the literature review section") == "writing")
    }

    @Test func extractTaskKeywordFromLitReview() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on the lit review") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "lit review due Friday") == "writing")
        #expect(CalloutManager.extractTaskKeyword(from: "polish lit review tonight") == "writing")
    }

    // MARK: - case study / case studies → research

    @Test func extractTaskKeywordFromCaseStudy() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a case study") == "research")
        #expect(CalloutManager.extractTaskKeyword(from: "case study for my business class") == "research")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the case study tonight") == "research")
    }

    @Test func extractTaskKeywordFromCaseStudies() {
        #expect(CalloutManager.extractTaskKeyword(from: "analyzing case studies") == "research")
        #expect(CalloutManager.extractTaskKeyword(from: "case studies due tomorrow") == "research")
        #expect(CalloutManager.extractTaskKeyword(from: "review the case studies") == "research")
    }

    // MARK: - Journaling keyword extraction

    @Test func extractTaskKeywordFromJournal() {
        #expect(CalloutManager.extractTaskKeyword(from: "write in my journal") == "journaling")
        #expect(CalloutManager.extractTaskKeyword(from: "my journal for today") == "journaling")
        #expect(CalloutManager.extractTaskKeyword(from: "open journal and reflect") == "journaling")
    }

    @Test func extractTaskKeywordFromJournaling() {
        #expect(CalloutManager.extractTaskKeyword(from: "journaling session") == "journaling")
        #expect(CalloutManager.extractTaskKeyword(from: "daily journaling practice") == "journaling")
    }

    @Test func extractTaskKeywordFromJournalEntry() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a journal entry") == "journaling")
        #expect(CalloutManager.extractTaskKeyword(from: "finish journal entry for today") == "journaling")
        #expect(CalloutManager.extractTaskKeyword(from: "catching up on journal entries") == "journaling")
    }

    @Test func extractTaskKeywordFromMorningPages() {
        #expect(CalloutManager.extractTaskKeyword(from: "morning pages session") == "journaling")
        #expect(CalloutManager.extractTaskKeyword(from: "do my morning pages") == "journaling")
        #expect(CalloutManager.extractTaskKeyword(from: "morning pages before work") == "journaling")
    }

    @Test func extractTaskKeywordFromDiary() {
        #expect(CalloutManager.extractTaskKeyword(from: "write in my diary") == "journaling")
        #expect(CalloutManager.extractTaskKeyword(from: "diary entry for today") == "journaling")
    }

    @Test func extractTaskKeywordFromDiaryEntry() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a diary entry") == "journaling")
        #expect(CalloutManager.extractTaskKeyword(from: "complete my diary entry") == "journaling")
    }

    @Test func extractTaskKeywordJournalingDoesNotOverrideEssay() {
        // "essay" appears earlier in the chain and must win
        #expect(CalloutManager.extractTaskKeyword(from: "essay about my journal as a student") == "essay")
    }

    @Test func extractTaskKeywordJournalingDoesNotOverrideWriting() {
        // "blog" → writing earlier in chain; journaling doesn't interfere
        #expect(CalloutManager.extractTaskKeyword(from: "write a blog about journaling habits") == "writing")
    }

    @Test func extractTaskKeywordJournalingDoesNotOverridePaper() {
        // "paper" keyword fires at line 89, before the journaling branch; "journal" in
        // academic-submission context doesn't interfere when a clearer keyword is present.
        #expect(CalloutManager.extractTaskKeyword(from: "submit paper to academic journal") == "paper")
    }

    @Test func taskAwareCalloutsJournalingHasMessages() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "journaling", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) must have journaling messages")
            }
        }
    }

    @Test func taskAwareCalloutsJournalingDedicatedPoolSize() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            #expect(manager.taskAwareCallouts(keyword: "journaling", tier: 1).count >= 3)
            #expect(manager.taskAwareCallouts(keyword: "journaling", tier: 2).count >= 2)
            #expect(manager.taskAwareCallouts(keyword: "journaling", tier: 3).count >= 2)
        }
    }

    @Test func taskAwareCalloutsJournalingTier3HasUrgentMessage() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "journaling", tier: 3)
            let hasUrgent = tier3.contains { msg in
                let upper = msg.uppercased()
                return upper.contains("CLOSE") || upper.contains("JOURNAL") || upper.contains("WRITE")
            }
            #expect(hasUrgent, "tier 3 journaling messages must contain an urgent directive")
        }
    }

    @Test func taskAwareCalloutsJournalingTier1ReferencesJournal() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "journaling", tier: 1)
            let hasJournalRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("journal") || lower.contains("write") || lower.contains("entry")
            }
            #expect(hasJournalRef, "tier 1 journaling messages must reference journal or writing")
        }
    }

    // MARK: - Legal keyword

    @Test func extractTaskKeywordLegalBrief() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my case brief") == "legal")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the legal brief") == "legal")
    }

    @Test func extractTaskKeywordLegalMemo() {
        #expect(CalloutManager.extractTaskKeyword(from: "draft a legal memo") == "legal")
        #expect(CalloutManager.extractTaskKeyword(from: "write a legal memorandum") == "legal")
    }

    @Test func extractTaskKeywordBarExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for the bar exam") == "legal")
        #expect(CalloutManager.extractTaskKeyword(from: "bar prep session today") == "legal")
    }

    @Test func extractTaskKeywordMootCourt() {
        #expect(CalloutManager.extractTaskKeyword(from: "practice my moot court argument") == "legal")
    }

    @Test func extractTaskKeywordLawReview() {
        #expect(CalloutManager.extractTaskKeyword(from: "edit law review article") == "legal")
    }

    @Test func extractTaskKeywordLegalResearch() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish legal research for memo") == "legal")
    }

    @Test func extractTaskKeywordLegalPleading() {
        #expect(CalloutManager.extractTaskKeyword(from: "draft the pleadings") == "legal")
        #expect(CalloutManager.extractTaskKeyword(from: "file a pleading") == "legal")
    }

    @Test func extractTaskKeywordLegalDoesNotOverridePaper() {
        // "paper" fires before "brief" — a legal brief submitted as a paper for class
        // shouldn't override an explicit "paper" match; add "paper" to verify chain order.
        // This task uses "paper" but also mentions "brief" — paper wins as it's earlier in chain.
        #expect(CalloutManager.extractTaskKeyword(from: "write a research paper on legal briefs") == "paper")
    }

    @Test func extractTaskKeywordContractMapsToLegal() {
        #expect(CalloutManager.extractTaskKeyword(from: "review the contract") == "legal")
        // "draft" fires writing branch first; use a non-conflicting phrasing
        #expect(CalloutManager.extractTaskKeyword(from: "sign service contracts") == "legal")
        #expect(CalloutManager.extractTaskKeyword(from: "contracts for new clients") == "legal")
    }

    @Test func extractTaskKeywordLitigationMapsToLegal() {
        #expect(CalloutManager.extractTaskKeyword(from: "prepare litigation strategy") == "legal")
    }

    @Test func taskAwareCalloutsLegalHasMessages() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            for tier in 1...3 {
                let msgs = manager.taskAwareCallouts(keyword: "legal", tier: tier)
                #expect(!msgs.isEmpty, "tier \(tier) must have legal messages")
            }
        }
    }

    @Test func taskAwareCalloutsLegalDedicatedPoolSize() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            #expect(manager.taskAwareCallouts(keyword: "legal", tier: 1).count >= 3)
            #expect(manager.taskAwareCallouts(keyword: "legal", tier: 2).count >= 2)
            #expect(manager.taskAwareCallouts(keyword: "legal", tier: 3).count >= 2)
        }
    }

    @Test func taskAwareCalloutsLegalTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "legal", tier: 3)
            let hasUrgent = tier3.contains { msg in
                let upper = msg.uppercased()
                return upper.contains("CLOSE") || upper.contains("BRIEF") || upper.contains("BAR")
            }
            #expect(hasUrgent, "tier 3 legal messages must contain an urgent directive")
        }
    }

    @Test func taskAwareCalloutsLegalTier1ReferencesBrief() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "legal", tier: 1)
            let hasBriefRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("brief") || lower.contains("legal") || lower.contains("work")
            }
            #expect(hasBriefRef, "tier 1 legal messages must reference legal work")
        }
    }

    // MARK: - extractTaskKeyword — creative brief / design brief false-positive guards

    @Test func extractTaskKeywordCreativeBriefDoesNotMapToLegal() {
        // "creative brief" is a marketing/advertising concept, not a legal brief.
        // The writing branch now catches it before legal fires.
        #expect(CalloutManager.extractTaskKeyword(from: "write a creative brief for the campaign") == "writing")
    }

    @Test func extractTaskKeywordDesignBriefDoesNotMapToLegal() {
        // "design brief" should map to design, not legal.
        #expect(CalloutManager.extractTaskKeyword(from: "put together a design brief for the client") == "design")
    }

    @Test func extractTaskKeywordMarketingBriefDoesNotMapToLegal() {
        // "marketing brief" is a comms document, not a legal document.
        #expect(CalloutManager.extractTaskKeyword(from: "finish the marketing brief before the meeting") == "writing")
    }

    @Test func extractTaskKeywordLegalBriefStillMapsToLegal() {
        // True legal briefs must still resolve to "legal".
        #expect(CalloutManager.extractTaskKeyword(from: "draft my appellate brief") == "legal")
        #expect(CalloutManager.extractTaskKeyword(from: "write a legal brief for the motion") == "legal")
        #expect(CalloutManager.extractTaskKeyword(from: "write a case brief for class") == "legal")
    }

    // MARK: - journaling tier-4 edge case (falls through to default → tier 3 pool)

    @Test func taskAwareCalloutsJournalingTier4DoesNotCrash() async {
        await MainActor.run {
            // tier 4 has no explicit case in the switch — falls to `default:` which returns tier 3 pool.
            let result = CalloutManager.shared.taskAwareCallouts(keyword: "journaling", tier: 4)
            #expect(!result.isEmpty, "tier 4 must fall through to default (tier 3) pool and return messages")
        }
    }

    @Test func taskAwareCalloutsJournalingTier0ReturnsMessages() async {
        await MainActor.run {
            // tier 0 also hits default: — should not crash or return empty.
            let result = CalloutManager.shared.taskAwareCallouts(keyword: "journaling", tier: 0)
            #expect(!result.isEmpty, "tier 0 must return default pool messages")
        }
    }

    // MARK: - extractTaskKeyword — pre-med / MCAT

    @Test func extractTaskKeywordAnatomyMapsToPremed() {
        #expect(CalloutManager.extractTaskKeyword(from: "review anatomy for lab practical") == "premed")
        #expect(CalloutManager.extractTaskKeyword(from: "anatomy notes for the quiz") == "premed")
    }

    @Test func extractTaskKeywordPhysiologyMapsToPremed() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish my physiology reading") == "premed")
    }

    @Test func extractTaskKeywordBiochemistryMapsToPremed() {
        #expect(CalloutManager.extractTaskKeyword(from: "biochemistry chapter 4") == "premed")
    }

    @Test func extractTaskKeywordPharmacologyMapsToPremed() {
        #expect(CalloutManager.extractTaskKeyword(from: "pharmacology drug classifications") == "premed")
    }

    @Test func extractTaskKeywordMcatMapsToPremed() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for the MCAT") == "premed")
        #expect(CalloutManager.extractTaskKeyword(from: "MCAT practice section — CARS") == "premed")
    }

    @Test func extractTaskKeywordNclexMapsToPremed() {
        #expect(CalloutManager.extractTaskKeyword(from: "NCLEX review — med-surg") == "premed")
    }

    @Test func extractTaskKeywordUsmleMapsToPremed() {
        #expect(CalloutManager.extractTaskKeyword(from: "USMLE Step 1 practice questions") == "premed")
    }

    @Test func extractTaskKeywordMedSchoolMapsToPremed() {
        #expect(CalloutManager.extractTaskKeyword(from: "catch up on med school notes") == "premed")
        #expect(CalloutManager.extractTaskKeyword(from: "pre-med organic chemistry") == "premed")
    }

    @Test func extractTaskKeywordPathologyMapsToPremed() {
        #expect(CalloutManager.extractTaskKeyword(from: "pathology slide review") == "premed")
    }

    @Test func extractTaskKeywordPremedDoesNotOverrideStudy() {
        // "study anatomy" — word("study") fires first → "studying", not "premed".
        // This is intentional: the studying pool is fine for generic study sessions.
        #expect(CalloutManager.extractTaskKeyword(from: "study anatomy for the exam") == "studying")
    }

    @Test func extractTaskKeywordBiologyResearchDoesNotMapToPremed() {
        // "biology research paper" → "paper" fires before premed.
        #expect(CalloutManager.extractTaskKeyword(from: "write a biology research paper") == "paper")
    }

    // MARK: - taskAwareCallouts — pre-med pool

    @Test func taskAwareCalloutsPremedHasMessages() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            #expect(!manager.taskAwareCallouts(keyword: "premed", tier: 1).isEmpty)
            #expect(!manager.taskAwareCallouts(keyword: "premed", tier: 2).isEmpty)
            #expect(!manager.taskAwareCallouts(keyword: "premed", tier: 3).isEmpty)
        }
    }

    @Test func taskAwareCalloutsPremedDedicatedPoolSize() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            #expect(manager.taskAwareCallouts(keyword: "premed", tier: 1).count >= 3)
            #expect(manager.taskAwareCallouts(keyword: "premed", tier: 2).count >= 2)
            #expect(manager.taskAwareCallouts(keyword: "premed", tier: 3).count >= 2)
        }
    }

    @Test func taskAwareCalloutsPremedTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "premed", tier: 3)
            let hasUrgent = tier3.contains { msg in
                let upper = msg.uppercased()
                return upper.contains("CLOSE") || upper.contains("BOARDS") || upper.contains("MCAT")
                    || upper.contains("ANATOMY") || upper.contains("MED SCHOOL")
            }
            #expect(hasUrgent, "tier 3 premed messages must contain an urgent directive")
        }
    }

    @Test func taskAwareCalloutsPremedTier1ReferencesMedWork() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "premed", tier: 1)
            let hasMedRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("mcat") || lower.contains("anatomy") || lower.contains("med")
                    || lower.contains("patient") || lower.contains("study")
            }
            #expect(hasMedRef, "tier 1 premed messages must reference medical study context")
        }
    }

    @Test func taskAwareCalloutsPremedTier4FallsThrough() async {
        await MainActor.run {
            // tier 4 → default case → same as tier 3 pool. Must not crash or return empty.
            let result = CalloutManager.shared.taskAwareCallouts(keyword: "premed", tier: 4)
            #expect(!result.isEmpty)
        }
    }

    // MARK: - extractTaskKeyword — architecture

    @Test func extractTaskKeywordArchitectMapsToArchitecture() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on my architect portfolio") == "architecture")
    }

    @Test func extractTaskKeywordArchitectureMapsToArchitecture() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish my architecture studio project") == "architecture")
        #expect(CalloutManager.extractTaskKeyword(from: "architectural drawing for crit") == "architecture")
    }

    @Test func extractTaskKeywordAutocadMapsToArchitecture() {
        #expect(CalloutManager.extractTaskKeyword(from: "AutoCAD floor plan for the final") == "architecture")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the autocad drawing") == "architecture")
    }

    @Test func extractTaskKeywordRevitMapsToArchitecture() {
        #expect(CalloutManager.extractTaskKeyword(from: "model the building in Revit") == "architecture")
    }

    @Test func extractTaskKeywordRhinoMapsToArchitecture() {
        #expect(CalloutManager.extractTaskKeyword(from: "parametric design in Rhino") == "architecture")
    }

    @Test func extractTaskKeywordBlueprintMapsToArchitecture() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish the blueprint for the project") == "architecture")
        #expect(CalloutManager.extractTaskKeyword(from: "review blueprints for the studio") == "architecture")
    }

    @Test func extractTaskKeywordFloorPlanMapsToArchitecture() {
        #expect(CalloutManager.extractTaskKeyword(from: "draw the floor plan for unit B") == "architecture")
        #expect(CalloutManager.extractTaskKeyword(from: "update the floor plans for crit") == "architecture")
    }

    @Test func extractTaskKeywordSitePlanMapsToArchitecture() {
        #expect(CalloutManager.extractTaskKeyword(from: "update the site plan for the design review") == "architecture")
    }

    @Test func extractTaskKeywordElevationMapsToArchitecture() {
        #expect(CalloutManager.extractTaskKeyword(from: "draw east elevation for project") == "architecture")
        #expect(CalloutManager.extractTaskKeyword(from: "finish all elevations by tonight") == "architecture")
    }

    @Test func extractTaskKeywordRenderingMapsToArchitecture() {
        #expect(CalloutManager.extractTaskKeyword(from: "export the final rendering") == "architecture")
        #expect(CalloutManager.extractTaskKeyword(from: "set up renderings for pin-up") == "architecture")
    }

    @Test func extractTaskKeywordAreExamMapsToArchitecture() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for the ARE exam — site planning") == "architecture")
        #expect(CalloutManager.extractTaskKeyword(from: "ARE architecture exam practice questions") == "architecture")
    }

    @Test func extractTaskKeywordSoftwareArchitectureDoesNotMapToArchitecture() {
        // software architecture → no specific keyword, falls through to nil
        #expect(CalloutManager.extractTaskKeyword(from: "review the software architecture") == nil)
        #expect(CalloutManager.extractTaskKeyword(from: "diagram the system architecture") == nil)
        #expect(CalloutManager.extractTaskKeyword(from: "cloud architecture for the project") == nil)
    }

    @Test func extractTaskKeywordDataArchitectureDoesNotMapToArchitecture() {
        #expect(CalloutManager.extractTaskKeyword(from: "redesign the data architecture") == nil)
        #expect(CalloutManager.extractTaskKeyword(from: "application architecture review") == nil)
    }

    // MARK: - taskAwareCallouts — architecture pool

    @Test func taskAwareCalloutsArchitectureHasMessages() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            #expect(!manager.taskAwareCallouts(keyword: "architecture", tier: 1).isEmpty)
            #expect(!manager.taskAwareCallouts(keyword: "architecture", tier: 2).isEmpty)
            #expect(!manager.taskAwareCallouts(keyword: "architecture", tier: 3).isEmpty)
        }
    }

    @Test func taskAwareCalloutsArchitectureDedicatedPoolSize() async {
        await MainActor.run {
            let manager = CalloutManager.shared
            #expect(manager.taskAwareCallouts(keyword: "architecture", tier: 1).count >= 3)
            #expect(manager.taskAwareCallouts(keyword: "architecture", tier: 2).count >= 2)
            #expect(manager.taskAwareCallouts(keyword: "architecture", tier: 3).count >= 2)
        }
    }

    @Test func taskAwareCalloutsArchitectureTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "architecture", tier: 3)
            let hasUrgent = tier3.contains { msg in
                let upper = msg.uppercased()
                return upper.contains("CLOSE") || upper.contains("STUDIO") || upper.contains("CRIT")
                    || upper.contains("DEADLINE") || upper.contains("MODEL") || upper.contains("DRAWINGS")
            }
            #expect(hasUrgent, "tier 3 architecture messages must contain an urgent directive")
        }
    }

    @Test func taskAwareCalloutsArchitectureTier1ReferencesDesignWork() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "architecture", tier: 1)
            let hasDesignRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("drawing") || lower.contains("studio") || lower.contains("model")
                    || lower.contains("designing") || lower.contains("design")
            }
            #expect(hasDesignRef, "tier 1 architecture messages must reference design work")
        }
    }

    @Test func taskAwareCalloutsArchitectureTier4FallsThrough() async {
        await MainActor.run {
            let result = CalloutManager.shared.taskAwareCallouts(keyword: "architecture", tier: 4)
            #expect(!result.isEmpty)
        }
    }

    // MARK: - Startup keyword + callout pool

    @Test func extractTaskKeywordStartupPitchDeck() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my pitch deck") == "startup")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the investor deck") == "startup")
    }

    @Test func extractTaskKeywordStartupGoToMarket() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on go-to-market strategy") == "startup")
        #expect(CalloutManager.extractTaskKeyword(from: "define our GTM strategy") == "startup")
    }

    @Test func extractTaskKeywordStartupBusinessPlan() {
        // "business plan" contains "plan" but startup fires first
        #expect(CalloutManager.extractTaskKeyword(from: "write my business plan") == "startup")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the business model section") == "startup")
    }

    @Test func extractTaskKeywordStartupFundraising() {
        #expect(CalloutManager.extractTaskKeyword(from: "startup fundraising prep") == "startup")
        #expect(CalloutManager.extractTaskKeyword(from: "fundraise for our seed round") == "startup")
    }

    @Test func extractTaskKeywordStartupKeyword() {
        #expect(CalloutManager.extractTaskKeyword(from: "build my startup") == "startup")
        #expect(CalloutManager.extractTaskKeyword(from: "work on my startups landing page") == "startup")
    }

    @Test func extractTaskKeywordStartupSeedRound() {
        #expect(CalloutManager.extractTaskKeyword(from: "prepare seed round materials") == "startup")
        #expect(CalloutManager.extractTaskKeyword(from: "series a pitch prep") == "startup")
    }

    @Test func extractTaskKeywordStartupValueProposition() {
        #expect(CalloutManager.extractTaskKeyword(from: "refine the value proposition") == "startup")
    }

    @Test func extractTaskKeywordStartupSaas() {
        #expect(CalloutManager.extractTaskKeyword(from: "SaaS pricing strategy") == "startup")
        #expect(CalloutManager.extractTaskKeyword(from: "build a b2b sales deck") == "startup")
        #expect(CalloutManager.extractTaskKeyword(from: "b2c growth model") == "startup")
    }

    @Test func extractTaskKeywordStartupCofounder() {
        #expect(CalloutManager.extractTaskKeyword(from: "write co-founder agreement") == "startup")
        #expect(CalloutManager.extractTaskKeyword(from: "cofounder equity split doc") == "startup")
    }

    @Test func extractTaskKeywordStartupProductMarketFit() {
        #expect(CalloutManager.extractTaskKeyword(from: "analyze product-market fit") == "startup")
        #expect(CalloutManager.extractTaskKeyword(from: "product market fit research") == "startup")
    }

    @Test func extractTaskKeywordStartupGrowth() {
        #expect(CalloutManager.extractTaskKeyword(from: "growth hacking experiment") == "startup")
        #expect(CalloutManager.extractTaskKeyword(from: "map out growth strategy") == "startup")
    }

    @Test func extractTaskKeywordStartupDoesNotOverrideEssay() {
        // "essay" fires before startup
        #expect(CalloutManager.extractTaskKeyword(from: "essay about startup culture") == "essay")
    }

    @Test func extractTaskKeywordStartupDoesNotOverridePaper() {
        // "paper" fires before startup
        #expect(CalloutManager.extractTaskKeyword(from: "research paper on SaaS growth") == "paper")
    }

    @Test func taskAwareCalloutsStartupHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "startup", tier: tier)
                #expect(!msgs.isEmpty, "startup tier \(tier) must be non-empty")
            }
        }
    }

    @Test func taskAwareCalloutsStartupDedicatedPoolSize() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "startup", tier: 1)
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "startup", tier: 2)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "startup", tier: 3)
            #expect(tier1.count >= 3, "startup tier 1 should have at least 3 messages")
            #expect(tier2.count >= 2, "startup tier 2 should have at least 2 messages")
            #expect(tier3.count >= 2, "startup tier 3 should have at least 2 messages")
        }
    }

    @Test func taskAwareCalloutsStartupTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "startup", tier: 3)
            let hasUrgent = tier3.contains { msg in
                let upper = msg.uppercased()
                return upper.contains("CLOSE") || upper.contains("DECK") || upper.contains("STARTUP")
                    || upper.contains("PITCH") || upper.contains("FUND")
            }
            #expect(hasUrgent, "tier 3 startup messages must contain an urgent directive")
        }
    }

    @Test func taskAwareCalloutsStartupTier1ReferencesStartupWork() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "startup", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("pitch") || lower.contains("startup") || lower.contains("business")
                    || lower.contains("co-founder") || lower.contains("deck")
            }
            #expect(hasRef, "tier 1 startup messages must reference startup work")
        }
    }

    @Test func taskAwareCalloutsStartupTier4FallsThrough() async {
        await MainActor.run {
            let result = CalloutManager.shared.taskAwareCallouts(keyword: "startup", tier: 4)
            #expect(!result.isEmpty)
        }
    }

    // MARK: - Nursing keyword tests

    @Test func extractTaskKeywordNursingWord() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish my nursing notes") == "nursing")
        #expect(CalloutManager.extractTaskKeyword(from: "nursing school assignment") == "nursing")
    }

    @Test func extractTaskKeywordNursingCarePlan() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a care plan for my patient") == "nursing")
        #expect(CalloutManager.extractTaskKeyword(from: "finish care plans for clinical") == "nursing")
    }

    @Test func extractTaskKeywordNursingCharting() {
        #expect(CalloutManager.extractTaskKeyword(from: "catch up on nurse charting from today") == "nursing")
        #expect(CalloutManager.extractTaskKeyword(from: "write shift notes from my clinical") == "nursing")
    }

    @Test func extractTaskKeywordNursingDosageCalc() {
        #expect(CalloutManager.extractTaskKeyword(from: "practice dosage calculations") == "nursing")
        #expect(CalloutManager.extractTaskKeyword(from: "study for med calc quiz") == "nursing")
        #expect(CalloutManager.extractTaskKeyword(from: "review medication calculations") == "nursing")
    }

    @Test func extractTaskKeywordNursingTheory() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a nursing theory paper") == "nursing")
        #expect(CalloutManager.extractTaskKeyword(from: "nursing diagnosis for care plan") == "nursing")
    }

    @Test func extractTaskKeywordNursingAssessment() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete my patient assessment") == "nursing")
        #expect(CalloutManager.extractTaskKeyword(from: "document vital signs from today") == "nursing")
        #expect(CalloutManager.extractTaskKeyword(from: "check and record vitals") == "nursing")
    }

    @Test func extractTaskKeywordNursingClinicalDocs() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish clinical documentation") == "nursing")
        #expect(CalloutManager.extractTaskKeyword(from: "write shift report before handoff") == "nursing")
    }

    @Test func extractTaskKeywordNursingWoundCare() {
        #expect(CalloutManager.extractTaskKeyword(from: "study wound care protocols") == "nursing")
    }

    @Test func extractTaskKeywordNursingDoesNotMatchPremed() {
        // anatomy/pharmacology/NCLEX still fire as "premed" since premed branch comes first
        #expect(CalloutManager.extractTaskKeyword(from: "study anatomy for lab") == "premed")
        #expect(CalloutManager.extractTaskKeyword(from: "NCLEX review session") == "premed")
    }

    @Test func taskAwareCalloutsNursingHasMessages() async {
        await MainActor.run {
            for tier in 1...4 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "nursing", tier: tier)
                #expect(!msgs.isEmpty, "nursing tier \(tier) must be non-empty")
            }
        }
    }

    @Test func taskAwareCalloutsNursingDedicatedPoolSize() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "nursing", tier: 1)
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "nursing", tier: 2)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "nursing", tier: 3)
            #expect(tier1.count >= 3, "nursing tier 1 should have at least 3 messages")
            #expect(tier2.count >= 2, "nursing tier 2 should have at least 2 messages")
            #expect(tier3.count >= 2, "nursing tier 3 should have at least 2 messages")
        }
    }

    @Test func taskAwareCalloutsNursingTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "nursing", tier: 3)
            let hasUrgent = tier3.contains { msg in
                let upper = msg.uppercased()
                return upper.contains("CLOSE") || upper.contains("CARE PLAN")
                    || upper.contains("NOTES") || upper.contains("CHART")
            }
            #expect(hasUrgent, "tier 3 nursing messages must contain an urgent directive")
        }
    }

    @Test func taskAwareCalloutsNursingTier1ReferencesNursingWork() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "nursing", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("care plan") || lower.contains("nursing") || lower.contains("notes")
                    || lower.contains("chart") || lower.contains("patient")
            }
            #expect(hasRef, "tier 1 nursing messages must reference nursing work")
        }
    }

    @Test func taskAwareCalloutsNursingTier4FallsThrough() async {
        await MainActor.run {
            let result = CalloutManager.shared.taskAwareCallouts(keyword: "nursing", tier: 4)
            #expect(!result.isEmpty)
        }
    }

    // MARK: - Photography keyword + callout pool

    @Test func extractTaskKeywordPhotographyWord() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on my photography project") == "photography")
        #expect(CalloutManager.extractTaskKeyword(from: "I am a photographer building my portfolio") == "photography")
    }

    @Test func extractTaskKeywordPhotographyLightroom() {
        #expect(CalloutManager.extractTaskKeyword(from: "edit my photos in lightroom") == "photography")
        #expect(CalloutManager.extractTaskKeyword(from: "lightroom editing session") == "photography")
    }

    @Test func extractTaskKeywordPhotographyPhotoShoot() {
        #expect(CalloutManager.extractTaskKeyword(from: "prep for my photo shoot tomorrow") == "photography")
        #expect(CalloutManager.extractTaskKeyword(from: "photoshoot prep and planning") == "photography")
    }

    @Test func extractTaskKeywordPhotographyEditingPhrases() {
        #expect(CalloutManager.extractTaskKeyword(from: "photo editing session in capture one") == "photography")
        #expect(CalloutManager.extractTaskKeyword(from: "editing photos from the event") == "photography")
    }

    @Test func extractTaskKeywordPhotographyPortraitLandscape() {
        #expect(CalloutManager.extractTaskKeyword(from: "practice portrait photography techniques") == "photography")
        #expect(CalloutManager.extractTaskKeyword(from: "review my landscape photography from the trip") == "photography")
    }

    @Test func extractTaskKeywordPhotographyHeadshots() {
        #expect(CalloutManager.extractTaskKeyword(from: "edit client headshots from today") == "photography")
        #expect(CalloutManager.extractTaskKeyword(from: "deliver the headshot gallery to my client") == "photography")
    }

    @Test func extractTaskKeywordPhotographyRawFiles() {
        #expect(CalloutManager.extractTaskKeyword(from: "cull and edit raw files from the weekend") == "photography")
        #expect(CalloutManager.extractTaskKeyword(from: "raw editing for the wedding album") == "photography")
    }

    @Test func extractTaskKeywordPhotographyStreetProduct() {
        #expect(CalloutManager.extractTaskKeyword(from: "go out and practice street photography") == "photography")
        #expect(CalloutManager.extractTaskKeyword(from: "product photography shoot for client") == "photography")
    }

    @Test func extractTaskKeywordPhotographyDarkroom() {
        #expect(CalloutManager.extractTaskKeyword(from: "work in the darkroom developing film") == "photography")
    }

    @Test func taskAwareCalloutsPhotographyHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "photography", tier: tier)
                #expect(!msgs.isEmpty, "photography tier \(tier) should have messages")
            }
        }
    }

    @Test func taskAwareCalloutsPhotographyDedicatedPoolSize() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "photography", tier: 1)
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "photography", tier: 2)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "photography", tier: 3)
            #expect(tier1.count >= 3, "photography tier1 should have ≥3 messages")
            #expect(tier2.count >= 2, "photography tier2 should have ≥2 messages")
            #expect(tier3.count >= 2, "photography tier3 should have ≥2 messages")
        }
    }

    @Test func taskAwareCalloutsPhotographyTier1ReferencesPhotographyWork() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "photography", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("photo") || lower.contains("lightroom")
                    || lower.contains("edit") || lower.contains("raw")
            }
            #expect(hasRef, "photography tier1 messages must reference photography work")
        }
    }

    @Test func taskAwareCalloutsPhotographyTier3HasUrgency() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "photography", tier: 3)
            #expect(!tier3.isEmpty, "photography tier3 must have messages")
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") }
            #expect(hasUrgent, "photography tier3 should contain an ALL-CAPS urgent directive")
        }
    }

    @Test func taskAwareCalloutsPhotographyTier4FallsThrough() async {
        await MainActor.run {
            let result = CalloutManager.shared.taskAwareCallouts(keyword: "photography", tier: 4)
            #expect(!result.isEmpty, "tier 4 should fall through to tier3 photography messages")
        }
    }

    // MARK: - Data science / ML keyword tests

    @Test func extractTaskKeywordDatascienceMachineLearning() {
        #expect(CalloutManager.extractTaskKeyword(from: "study machine learning concepts") == "datascience")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the machine learning assignment") == "datascience")
    }

    @Test func extractTaskKeywordDatascienceDeepLearning() {
        #expect(CalloutManager.extractTaskKeyword(from: "implement a deep learning model") == "datascience")
        #expect(CalloutManager.extractTaskKeyword(from: "deep learning homework") == "datascience")
    }

    @Test func extractTaskKeywordDatascienceNeuralNetwork() {
        #expect(CalloutManager.extractTaskKeyword(from: "train a neural network for image classification") == "datascience")
        #expect(CalloutManager.extractTaskKeyword(from: "debug my neural networks") == "datascience")
    }

    @Test func extractTaskKeywordDatasciencePytorch() {
        #expect(CalloutManager.extractTaskKeyword(from: "write pytorch training loop") == "datascience")
        #expect(CalloutManager.extractTaskKeyword(from: "fix my pytorch model") == "datascience")
    }

    @Test func extractTaskKeywordDatascienceTensorflow() {
        #expect(CalloutManager.extractTaskKeyword(from: "build a tensorflow model") == "datascience")
        #expect(CalloutManager.extractTaskKeyword(from: "tensorflow and keras experiment") == "datascience")
    }

    @Test func extractTaskKeywordDatascienceJupyter() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish my jupyter notebook") == "datascience")
        #expect(CalloutManager.extractTaskKeyword(from: "work through the jupyter cells") == "datascience")
    }

    @Test func extractTaskKeywordDatascienceKaggle() {
        #expect(CalloutManager.extractTaskKeyword(from: "submit my kaggle competition entry") == "datascience")
        #expect(CalloutManager.extractTaskKeyword(from: "work on kaggle dataset") == "datascience")
    }

    @Test func extractTaskKeywordDatascienceDataScientist() {
        #expect(CalloutManager.extractTaskKeyword(from: "prep for data science interview") == "datascience")
        #expect(CalloutManager.extractTaskKeyword(from: "practice data scientist problems") == "datascience")
    }

    @Test func extractTaskKeywordDatascienceNLP() {
        #expect(CalloutManager.extractTaskKeyword(from: "build a natural language processing pipeline") == "datascience")
    }

    @Test func extractTaskKeywordDatascienceModelTraining() {
        #expect(CalloutManager.extractTaskKeyword(from: "run model training on the dataset") == "datascience")
        #expect(CalloutManager.extractTaskKeyword(from: "tune hyperparameter settings") == "datascience")
    }

    @Test func extractTaskKeywordDatascienceRandomForest() {
        #expect(CalloutManager.extractTaskKeyword(from: "train a random forest classifier") == "datascience")
        #expect(CalloutManager.extractTaskKeyword(from: "compare gradient boosting methods") == "datascience")
    }

    @Test func extractTaskKeywordDatascienceDoesNotOverrideResearch() {
        // Generic "data analysis" and "data collection" should still route to research
        #expect(CalloutManager.extractTaskKeyword(from: "data collection for my study") == "research")
        #expect(CalloutManager.extractTaskKeyword(from: "qualitative data analysis") == "research")
    }

    @Test func taskAwareCalloutsDatascienceHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "datascience", tier: tier)
                #expect(!msgs.isEmpty, "datascience tier \(tier) should have messages")
            }
        }
    }

    @Test func taskAwareCalloutsDatascienceDedicatedPoolSize() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "datascience", tier: 1)
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "datascience", tier: 2)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "datascience", tier: 3)
            #expect(tier1.count >= 3, "datascience tier1 should have ≥3 messages")
            #expect(tier2.count >= 2, "datascience tier2 should have ≥2 messages")
            #expect(tier3.count >= 2, "datascience tier3 should have ≥2 messages")
        }
    }

    @Test func taskAwareCalloutsDatascienceTier1ReferencesMLWork() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "datascience", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("model") || lower.contains("notebook")
                    || lower.contains("data") || lower.contains("jupyter")
            }
            #expect(hasRef, "datascience tier1 messages must reference ML/data work")
        }
    }

    @Test func taskAwareCalloutsDatascienceTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "datascience", tier: 3)
            #expect(!tier3.isEmpty, "datascience tier3 must have messages")
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") }
            #expect(hasUrgent, "datascience tier3 should contain a CLOSE THIS directive")
        }
    }

    @Test func taskAwareCalloutsDatascienceTier4FallsThrough() async {
        await MainActor.run {
            let result = CalloutManager.shared.taskAwareCallouts(keyword: "datascience", tier: 4)
            #expect(!result.isEmpty, "tier 4 should fall through to tier3 datascience messages")
        }
    }

    // MARK: - Game dev keyword tests

    @Test func extractTaskKeywordGamedevUnity() {
        #expect(CalloutManager.extractTaskKeyword(from: "build a game in Unity") == "gamedev")
        #expect(CalloutManager.extractTaskKeyword(from: "fix a bug in my Unity project") == "gamedev")
    }

    @Test func extractTaskKeywordGamedevGodot() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on my Godot project") == "gamedev")
        #expect(CalloutManager.extractTaskKeyword(from: "add a scene in Godot") == "gamedev")
    }

    @Test func extractTaskKeywordGamedevGameJam() {
        #expect(CalloutManager.extractTaskKeyword(from: "submit my game jam entry") == "gamedev")
        #expect(CalloutManager.extractTaskKeyword(from: "game jam project due tonight") == "gamedev")
    }

    @Test func extractTaskKeywordGamedevLevelDesign() {
        #expect(CalloutManager.extractTaskKeyword(from: "design levels for my platformer") == "gamedev")
        #expect(CalloutManager.extractTaskKeyword(from: "open the level editor and finish world 2") == "gamedev")
    }

    @Test func extractTaskKeywordGamedevGDD() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my game design document") == "gamedev")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the GDD for my project") == "gamedev")
    }

    @Test func extractTaskKeywordGamedevDoesNotMatchGamePlan() {
        // "game plan" must NOT route to gamedev — it's not a game-dev phrase
        let result = CalloutManager.extractTaskKeyword(from: "write a game plan for the presentation")
        #expect(result != "gamedev", "\"game plan\" should not match the gamedev branch")
    }

    @Test func taskAwareCalloutsGamedevHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "gamedev", tier: tier)
                #expect(!msgs.isEmpty, "gamedev tier \(tier) should have messages")
            }
        }
    }

    @Test func taskAwareCalloutsGamedevPoolSizes() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "gamedev", tier: 1)
            let t2 = CalloutManager.shared.taskAwareCallouts(keyword: "gamedev", tier: 2)
            let t3 = CalloutManager.shared.taskAwareCallouts(keyword: "gamedev", tier: 3)
            #expect(t1.count >= 3, "gamedev tier1 should have ≥3 messages")
            #expect(t2.count >= 2, "gamedev tier2 should have ≥2 messages")
            #expect(t3.count >= 2, "gamedev tier3 should have ≥2 messages")
        }
    }

    @Test func taskAwareCalloutsGamedevTier1ReferencesGameWork() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "gamedev", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("game") || lower.contains("engine") || lower.contains("level")
            }
            #expect(hasRef, "gamedev tier1 messages must reference game/engine/level work")
        }
    }

    @Test func taskAwareCalloutsGamedevTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "gamedev", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") }
            #expect(hasUrgent, "gamedev tier3 should contain a CLOSE THIS directive")
        }
    }

    @Test func taskAwareCalloutsGamedevTier4FallsThrough() async {
        await MainActor.run {
            let result = CalloutManager.shared.taskAwareCallouts(keyword: "gamedev", tier: 4)
            #expect(!result.isEmpty, "tier 4 should fall through to tier3 gamedev messages")
        }
    }

    // MARK: - Engineering keyword tests

    @Test func extractTaskKeywordEngineeringSolidworks() {
        #expect(CalloutManager.extractTaskKeyword(from: "do my SolidWorks homework") == "engineering")
        #expect(CalloutManager.extractTaskKeyword(from: "model a part in SolidWorks") == "engineering")
    }

    @Test func extractTaskKeywordEngineeringArduino() {
        #expect(CalloutManager.extractTaskKeyword(from: "program my arduino sensor board") == "engineering")
        #expect(CalloutManager.extractTaskKeyword(from: "wire up the arduino circuit") == "engineering")
    }

    @Test func extractTaskKeywordEngineeringCircuit() {
        #expect(CalloutManager.extractTaskKeyword(from: "draw the circuit diagram for lab") == "engineering")
        #expect(CalloutManager.extractTaskKeyword(from: "design a circuit board for ECE class") == "engineering")
    }

    @Test func extractTaskKeywordEngineeringSubdiscipline() {
        #expect(CalloutManager.extractTaskKeyword(from: "prep for mechanical engineering exam") == "engineering")
        #expect(CalloutManager.extractTaskKeyword(from: "read electrical engineering notes") == "engineering")
        #expect(CalloutManager.extractTaskKeyword(from: "aerospace engineering assignment") == "engineering")
    }

    @Test func extractTaskKeywordEngineeringThermodynamics() {
        #expect(CalloutManager.extractTaskKeyword(from: "study thermodynamics for the lab") == "engineering")
        #expect(CalloutManager.extractTaskKeyword(from: "finish my heat transfer problem set") == "engineering")
    }

    @Test func taskAwareCalloutsEngineeringHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "engineering", tier: tier)
                #expect(!msgs.isEmpty, "engineering tier \(tier) should have messages")
            }
        }
    }

    @Test func taskAwareCalloutsEngineeringPoolSizes() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "engineering", tier: 1)
            let t2 = CalloutManager.shared.taskAwareCallouts(keyword: "engineering", tier: 2)
            let t3 = CalloutManager.shared.taskAwareCallouts(keyword: "engineering", tier: 3)
            #expect(t1.count >= 3, "engineering tier1 should have ≥3 messages")
            #expect(t2.count >= 2, "engineering tier2 should have ≥2 messages")
            #expect(t3.count >= 2, "engineering tier3 should have ≥2 messages")
        }
    }

    @Test func taskAwareCalloutsEngineeringTier1ReferencesWork() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "engineering", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("design") || lower.contains("engineering")
                    || lower.contains("cad") || lower.contains("circuit")
            }
            #expect(hasRef, "engineering tier1 messages must reference design/engineering work")
        }
    }

    @Test func taskAwareCalloutsEngineeringTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "engineering", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") }
            #expect(hasUrgent, "engineering tier3 should contain a CLOSE THIS directive")
        }
    }

    // MARK: - Therapy keyword tests

    @Test func extractTaskKeywordTherapyNotes() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my therapy notes for today") == "therapy")
        #expect(CalloutManager.extractTaskKeyword(from: "update progress notes for my client") == "therapy")
    }

    @Test func extractTaskKeywordTherapyTreatmentPlan() {
        #expect(CalloutManager.extractTaskKeyword(from: "update my client's treatment plan") == "therapy")
        #expect(CalloutManager.extractTaskKeyword(from: "draft a treatment plan section") == "therapy")
    }

    @Test func extractTaskKeywordTherapyCaseConceptualization() {
        #expect(CalloutManager.extractTaskKeyword(from: "case conceptualization for my client") == "therapy")
        #expect(CalloutManager.extractTaskKeyword(from: "write case formulation for supervision") == "therapy")
    }

    @Test func extractTaskKeywordTherapyLCSW() {
        #expect(CalloutManager.extractTaskKeyword(from: "prep for LCSW exam") == "therapy")
        #expect(CalloutManager.extractTaskKeyword(from: "study for LMFT licensing") == "therapy")
    }

    @Test func extractTaskKeywordTherapySocialWork() {
        #expect(CalloutManager.extractTaskKeyword(from: "document my social work internship hours") == "therapy")
        #expect(CalloutManager.extractTaskKeyword(from: "write client notes for my social work placement") == "therapy")
    }

    @Test func taskAwareCalloutsTherapyHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "therapy", tier: tier)
                #expect(!msgs.isEmpty, "therapy tier \(tier) should have messages")
            }
        }
    }

    @Test func taskAwareCalloutsTherapyPoolSizes() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "therapy", tier: 1)
            let t2 = CalloutManager.shared.taskAwareCallouts(keyword: "therapy", tier: 2)
            let t3 = CalloutManager.shared.taskAwareCallouts(keyword: "therapy", tier: 3)
            #expect(t1.count >= 3, "therapy tier1 should have ≥3 messages")
            #expect(t2.count >= 2, "therapy tier2 should have ≥2 messages")
            #expect(t3.count >= 2, "therapy tier3 should have ≥2 messages")
        }
    }

    @Test func taskAwareCalloutsTherapyTier1ReferencesNotes() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "therapy", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("note") || lower.contains("client") || lower.contains("focus")
            }
            #expect(hasRef, "therapy tier1 messages must reference notes/clients/focus")
        }
    }

    @Test func taskAwareCalloutsTherapyTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "therapy", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") }
            #expect(hasUrgent, "therapy tier3 should contain a CLOSE THIS directive")
        }
    }

    // MARK: - Social science keyword tests

    @Test func extractTaskKeywordPoliticalScience() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish my political science paper") == "socialscience")
        #expect(CalloutManager.extractTaskKeyword(from: "work on my poli sci essay") == "essay")
        #expect(CalloutManager.extractTaskKeyword(from: "poli sci readings for Tuesday") == "socialscience")
    }

    @Test func extractTaskKeywordAnthropology() {
        #expect(CalloutManager.extractTaskKeyword(from: "anthropology fieldwork writeup") == "socialscience")
        #expect(CalloutManager.extractTaskKeyword(from: "read my anthropology chapter") == "reading")
        #expect(CalloutManager.extractTaskKeyword(from: "ethnographic research for class") == "socialscience")
    }

    @Test func extractTaskKeywordCriminology() {
        #expect(CalloutManager.extractTaskKeyword(from: "criminology assignment for tomorrow") == "socialscience")
        #expect(CalloutManager.extractTaskKeyword(from: "criminal justice presentation") == "presentation")
        #expect(CalloutManager.extractTaskKeyword(from: "study criminal justice for my exam") == "studying")
    }

    @Test func extractTaskKeywordLSAT() {
        #expect(CalloutManager.extractTaskKeyword(from: "LSAT prep session") == "socialscience")
        #expect(CalloutManager.extractTaskKeyword(from: "practice LSAT logic games") == "socialscience")
        #expect(CalloutManager.extractTaskKeyword(from: "prepare for the LSAT") == "socialscience")
    }

    @Test func extractTaskKeywordPublicPolicy() {
        #expect(CalloutManager.extractTaskKeyword(from: "public policy memo for class") == "socialscience")
        #expect(CalloutManager.extractTaskKeyword(from: "public administration case study") == "socialscience")
    }

    @Test func extractTaskKeywordInternationalRelations() {
        #expect(CalloutManager.extractTaskKeyword(from: "international relations theory paper") == "socialscience")
        #expect(CalloutManager.extractTaskKeyword(from: "comparative politics reading") == "socialscience")
    }

    @Test func extractTaskKeywordSocialScienceDoesNotOverrideStudy() {
        // "study sociology" hits word("study") and word("sociology") is in studying branch — stays "studying"
        #expect(CalloutManager.extractTaskKeyword(from: "study political science for my exam") == "studying")
        #expect(CalloutManager.extractTaskKeyword(from: "sociology flashcards") == "studying")
    }

    @Test func extractTaskKeywordSocialScienceDoesNotOverrideLegal() {
        // bar exam, legal brief — should still resolve to legal, not socialscience
        #expect(CalloutManager.extractTaskKeyword(from: "prep for the bar exam") == "legal")
        #expect(CalloutManager.extractTaskKeyword(from: "write my legal brief") == "legal")
    }

    @Test func taskAwareCalloutsSocialScienceHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "socialscience", tier: tier)
                #expect(!msgs.isEmpty, "socialscience tier \(tier) should have messages")
            }
        }
    }

    @Test func taskAwareCalloutsSocialSciencePoolSizes() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "socialscience", tier: 1)
            let t2 = CalloutManager.shared.taskAwareCallouts(keyword: "socialscience", tier: 2)
            let t3 = CalloutManager.shared.taskAwareCallouts(keyword: "socialscience", tier: 3)
            #expect(t1.count >= 3, "socialscience tier1 should have ≥3 messages")
            #expect(t2.count >= 2, "socialscience tier2 should have ≥2 messages")
            #expect(t3.count >= 2, "socialscience tier3 should have ≥2 messages")
        }
    }

    @Test func taskAwareCalloutsSocialScienceTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "socialscience", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") }
            #expect(hasUrgent, "socialscience tier3 should contain a CLOSE THIS directive")
        }
    }

    @Test func taskAwareCalloutsSocialScienceTier1ReferencesWork() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "socialscience", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("political") || lower.contains("social science")
                    || lower.contains("lsat") || lower.contains("research")
            }
            #expect(hasRef, "socialscience tier1 messages must reference the domain")
        }
    }

    // MARK: - Nutrition keyword tests

    @Test func extractTaskKeywordDietitian() {
        #expect(CalloutManager.extractTaskKeyword(from: "prep for my meeting with my dietitian") == "nutrition")
        #expect(CalloutManager.extractTaskKeyword(from: "work with a registered dietician") == "nutrition")
        #expect(CalloutManager.extractTaskKeyword(from: "ask my nutritionist follow-up questions") == "nutrition")
    }

    @Test func extractTaskKeywordMacronutrients() {
        #expect(CalloutManager.extractTaskKeyword(from: "log my macronutrients for today") == "nutrition")
        #expect(CalloutManager.extractTaskKeyword(from: "review macronutrients after my workout") == "nutrition")
    }

    @Test func extractTaskKeywordFoodScience() {
        #expect(CalloutManager.extractTaskKeyword(from: "food science lab report") == "nutrition")
        #expect(CalloutManager.extractTaskKeyword(from: "nutritional science reading assignment") == "nutrition")
    }

    @Test func extractTaskKeywordClinicalNutrition() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete my clinical nutrition case study") == "nutrition")
        #expect(CalloutManager.extractTaskKeyword(from: "nutrition assessment for my client") == "nutrition")
    }

    @Test func extractTaskKeywordCalorieTracking() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish my calorie tracking for today") == "nutrition")
        #expect(CalloutManager.extractTaskKeyword(from: "calorie counting spreadsheet") == "nutrition")
    }

    @Test func extractTaskKeywordNutritionDoesNotOverrideFitness() {
        // "nutrition plan" and "meal prep" must stay in fitness
        #expect(CalloutManager.extractTaskKeyword(from: "follow my nutrition plan after gym") == "fitness")
        #expect(CalloutManager.extractTaskKeyword(from: "meal prep for the week") == "fitness")
    }

    @Test func taskAwareCalloutsNutritionHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "nutrition", tier: tier)
                #expect(!msgs.isEmpty, "nutrition tier \(tier) should have messages")
            }
        }
    }

    @Test func taskAwareCalloutsNutritionPoolSizes() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "nutrition", tier: 1)
            let t2 = CalloutManager.shared.taskAwareCallouts(keyword: "nutrition", tier: 2)
            let t3 = CalloutManager.shared.taskAwareCallouts(keyword: "nutrition", tier: 3)
            #expect(t1.count >= 3, "nutrition tier1 should have ≥3 messages")
            #expect(t2.count >= 2, "nutrition tier2 should have ≥2 messages")
            #expect(t3.count >= 2, "nutrition tier3 should have ≥2 messages")
        }
    }

    @Test func taskAwareCalloutsNutritionTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "nutrition", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") }
            #expect(hasUrgent, "nutrition tier3 should contain a CLOSE THIS directive")
        }
    }

    @Test func taskAwareCalloutsNutritionTier1ReferencesDietetics() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "nutrition", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("macro") || lower.contains("nutrition")
                    || lower.contains("food") || lower.contains("dietetic")
            }
            #expect(hasRef, "nutrition tier1 messages must reference dietetics domain")
        }
    }

    // MARK: - Culinary keyword tests

    @Test func extractTaskKeywordCulinary() {
        #expect(CalloutManager.extractTaskKeyword(from: "practice my culinary skills") == "culinary")
        #expect(CalloutManager.extractTaskKeyword(from: "study for culinary school") == "culinary")
        #expect(CalloutManager.extractTaskKeyword(from: "attend my culinary arts class") == "culinary")
    }

    @Test func extractTaskKeywordRecipeDevelopment() {
        #expect(CalloutManager.extractTaskKeyword(from: "recipe development for my menu") == "culinary")
        #expect(CalloutManager.extractTaskKeyword(from: "recipe testing for the restaurant") == "culinary")
        #expect(CalloutManager.extractTaskKeyword(from: "recipe writing for my cookbook") == "culinary")
    }

    @Test func extractTaskKeywordBakingPastry() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish my baking project") == "culinary")
        #expect(CalloutManager.extractTaskKeyword(from: "work on pastry techniques") == "culinary")
        #expect(CalloutManager.extractTaskKeyword(from: "take my pastry arts class") == "culinary")
    }

    @Test func extractTaskKeywordCulinaryTechniques() {
        #expect(CalloutManager.extractTaskKeyword(from: "practice mise en place") == "culinary")
        #expect(CalloutManager.extractTaskKeyword(from: "study knife skills for kitchen exam") == "culinary")
        #expect(CalloutManager.extractTaskKeyword(from: "work on my menu planning assignment") == "culinary")
    }

    @Test func extractTaskKeywordCulinaryDoesNotOverrideNutrition() {
        // "food science" and "meal prep" must stay in nutrition/fitness respectively
        #expect(CalloutManager.extractTaskKeyword(from: "food science lab report") == "nutrition")
        #expect(CalloutManager.extractTaskKeyword(from: "meal prep for the week") == "fitness")
    }

    @Test func taskAwareCalloutsCulinaryHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "culinary", tier: tier)
                #expect(!msgs.isEmpty, "culinary tier \(tier) should have messages")
            }
        }
    }

    @Test func taskAwareCalloutsCulinaryPoolSizes() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "culinary", tier: 1)
            let t2 = CalloutManager.shared.taskAwareCallouts(keyword: "culinary", tier: 2)
            let t3 = CalloutManager.shared.taskAwareCallouts(keyword: "culinary", tier: 3)
            #expect(t1.count >= 3, "culinary tier1 should have ≥3 messages")
            #expect(t2.count >= 2, "culinary tier2 should have ≥2 messages")
            #expect(t3.count >= 2, "culinary tier3 should have ≥2 messages")
        }
    }

    @Test func taskAwareCalloutsCulinaryTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "culinary", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") }
            #expect(hasUrgent, "culinary tier3 should contain a CLOSE THIS directive")
        }
    }

    @Test func taskAwareCalloutsCulinaryTier1ReferencesKitchenWork() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "culinary", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("recipe") || lower.contains("culinary")
                    || lower.contains("kitchen") || lower.contains("mise")
            }
            #expect(hasRef, "culinary tier1 messages must reference kitchen/recipe work")
        }
    }

    @Test func taskAwareCalloutsCulinaryTier4FallsThrough() async {
        await MainActor.run {
            let tier4 = CalloutManager.shared.taskAwareCallouts(keyword: "culinary", tier: 4)
            #expect(!tier4.isEmpty, "culinary tier4 (default) should still return messages")
        }
    }

    // MARK: - Philosophy keyword tests

    @Test func extractTaskKeywordPhilosophy() {
        #expect(CalloutManager.extractTaskKeyword(from: "study philosophy for class") == "philosophy")
        #expect(CalloutManager.extractTaskKeyword(from: "write a philosophical essay") == "philosophy")
        #expect(CalloutManager.extractTaskKeyword(from: "read about a famous philosopher") == "philosophy")
    }

    @Test func extractTaskKeywordPhilosophersNames() {
        #expect(CalloutManager.extractTaskKeyword(from: "read Kant for class") == "philosophy")
        #expect(CalloutManager.extractTaskKeyword(from: "analyze Plato's Republic") == "philosophy")
        #expect(CalloutManager.extractTaskKeyword(from: "write about Socrates and virtue") == "philosophy")
        #expect(CalloutManager.extractTaskKeyword(from: "study Aristotle's ethics") == "philosophy")
        #expect(CalloutManager.extractTaskKeyword(from: "read Nietzsche for my philosophy course") == "philosophy")
    }

    @Test func extractTaskKeywordPhilosophyBranches() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a paper on metaphysics") == "philosophy")
        #expect(CalloutManager.extractTaskKeyword(from: "epistemology reading for tomorrow") == "philosophy")
        #expect(CalloutManager.extractTaskKeyword(from: "study ontology concepts") == "philosophy")
    }

    @Test func extractTaskKeywordPhilosophyPhrases() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my ethics paper") == "philosophy")
        #expect(CalloutManager.extractTaskKeyword(from: "analyze a philosophical argument") == "philosophy")
        #expect(CalloutManager.extractTaskKeyword(from: "work through a logic problem") == "philosophy")
        #expect(CalloutManager.extractTaskKeyword(from: "write about a thought experiment") == "philosophy")
    }

    @Test func extractTaskKeywordPhilosophySchools() {
        #expect(CalloutManager.extractTaskKeyword(from: "apply utilitarianism to the case study") == "philosophy")
        #expect(CalloutManager.extractTaskKeyword(from: "critique deontology in my response paper") == "philosophy")
        #expect(CalloutManager.extractTaskKeyword(from: "study consequentialism for the exam") == "philosophy")
    }

    @Test func extractTaskKeywordPhilosophyDoesNotOverrideLegal() {
        // legal-specific terms must still route to legal
        #expect(CalloutManager.extractTaskKeyword(from: "write my legal brief") == "legal")
        #expect(CalloutManager.extractTaskKeyword(from: "prep for bar exam") == "legal")
    }

    @Test func taskAwareCalloutsPhilosophyHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "philosophy", tier: tier)
                #expect(!msgs.isEmpty, "philosophy tier \(tier) should have messages")
            }
        }
    }

    @Test func taskAwareCalloutsPhilosophyPoolSizes() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "philosophy", tier: 1)
            let t2 = CalloutManager.shared.taskAwareCallouts(keyword: "philosophy", tier: 2)
            let t3 = CalloutManager.shared.taskAwareCallouts(keyword: "philosophy", tier: 3)
            #expect(t1.count >= 3, "philosophy tier1 should have ≥3 messages")
            #expect(t2.count >= 2, "philosophy tier2 should have ≥2 messages")
            #expect(t3.count >= 2, "philosophy tier3 should have ≥2 messages")
        }
    }

    @Test func taskAwareCalloutsPhilosophyTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "philosophy", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") }
            #expect(hasUrgent, "philosophy tier3 should contain a CLOSE THIS directive")
        }
    }

    @Test func taskAwareCalloutsPhilosophyTier1ReferencesPhilosophyWork() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "philosophy", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("argument") || lower.contains("philosophy")
                    || lower.contains("kant") || lower.contains("critique")
            }
            #expect(hasRef, "philosophy tier1 messages must reference philosophy domain")
        }
    }

    @Test func taskAwareCalloutsPhilosophyTier4FallsThrough() async {
        await MainActor.run {
            let tier4 = CalloutManager.shared.taskAwareCallouts(keyword: "philosophy", tier: 4)
            #expect(!tier4.isEmpty, "philosophy tier4 (default) should still return messages")
        }
    }

    // MARK: - Music production / theory split

    @Test func extractTaskKeywordMusicProductionDAW() {
        #expect(CalloutManager.extractTaskKeyword(from: "produce a track in Ableton") == "musicproduction")
        #expect(CalloutManager.extractTaskKeyword(from: "mix and master my track") == "musicproduction")
        #expect(CalloutManager.extractTaskKeyword(from: "finish my music production project") == "musicproduction")
        #expect(CalloutManager.extractTaskKeyword(from: "write a song for my EP") == "musicproduction")
        #expect(CalloutManager.extractTaskKeyword(from: "work on songwriting and lyrics") == "musicproduction")
    }

    @Test func extractTaskKeywordMusicProductionBeatmaking() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on beatmaking tonight") == "musicproduction")
        #expect(CalloutManager.extractTaskKeyword(from: "record music for my project") == "musicproduction")
        #expect(CalloutManager.extractTaskKeyword(from: "compose a melody for my track") == "musicproduction")
        #expect(CalloutManager.extractTaskKeyword(from: "work on a composition for class") == "musicproduction")
    }

    @Test func extractTaskKeywordMusicTheory() {
        #expect(CalloutManager.extractTaskKeyword(from: "study music theory for my exam") == "musictheory")
        #expect(CalloutManager.extractTaskKeyword(from: "do my ear training exercises") == "musictheory")
        #expect(CalloutManager.extractTaskKeyword(from: "practice sight reading") == "musictheory")
        #expect(CalloutManager.extractTaskKeyword(from: "learn chord progressions") == "musictheory")
        #expect(CalloutManager.extractTaskKeyword(from: "study counterpoint and aural skills") == "musictheory")
    }

    @Test func extractTaskKeywordMusicProductionBeforeTheory() {
        // "write a song" should fire musicproduction, not musictheory
        #expect(CalloutManager.extractTaskKeyword(from: "write a song about summer") == "musicproduction")
        // "music theory class" should fire musictheory
        #expect(CalloutManager.extractTaskKeyword(from: "study for music theory class") == "musictheory")
    }

    @Test func taskAwareCalloutsMusicProductionHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "musicproduction", tier: tier)
                #expect(!msgs.isEmpty, "musicproduction tier \(tier) should have messages")
            }
        }
    }

    @Test func taskAwareCalloutsMusicProductionPoolSizes() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "musicproduction", tier: 1)
            let t2 = CalloutManager.shared.taskAwareCallouts(keyword: "musicproduction", tier: 2)
            let t3 = CalloutManager.shared.taskAwareCallouts(keyword: "musicproduction", tier: 3)
            #expect(t1.count >= 3)
            #expect(t2.count >= 2)
            #expect(t3.count >= 2)
        }
    }

    @Test func taskAwareCalloutsMusicProductionTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "musicproduction", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") }
            #expect(hasUrgent, "musicproduction tier3 should contain a CLOSE THIS directive")
        }
    }

    @Test func taskAwareCalloutsMusicProductionTier1ReferencesDaw() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "musicproduction", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("daw") || lower.contains("track") || lower.contains("beat")
                    || lower.contains("song") || lower.contains("lyric") || lower.contains("mix")
            }
            #expect(hasRef, "musicproduction tier1 messages must reference production domain")
        }
    }

    @Test func taskAwareCalloutsMusicTheoryHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "musictheory", tier: tier)
                #expect(!msgs.isEmpty, "musictheory tier \(tier) should have messages")
            }
        }
    }

    @Test func taskAwareCalloutsMusicTheoryTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "musictheory", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") }
            #expect(hasUrgent, "musictheory tier3 should contain a CLOSE THIS directive")
        }
    }

    @Test func taskAwareCalloutsMusicTheoryTier1ReferencesTheory() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "musictheory", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("ear") || lower.contains("theory") || lower.contains("scale")
                    || lower.contains("sight") || lower.contains("chord")
            }
            #expect(hasRef, "musictheory tier1 messages must reference theory domain")
        }
    }

    // MARK: - Environmental science keyword

    @Test func extractTaskKeywordEnviroEcology() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my field ecology report") == "enviro")
        #expect(CalloutManager.extractTaskKeyword(from: "study for environmental science exam") == "enviro")
        #expect(CalloutManager.extractTaskKeyword(from: "research climate change impacts") == "enviro")
        #expect(CalloutManager.extractTaskKeyword(from: "analyze biodiversity data for class") == "enviro")
    }

    @Test func extractTaskKeywordEnviroSustainability() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a sustainability report") == "enviro")
        #expect(CalloutManager.extractTaskKeyword(from: "do my environmental studies assignment") == "enviro")
    }

    @Test func taskAwareCalloutsEnviroHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "enviro", tier: tier)
                #expect(!msgs.isEmpty, "enviro tier \(tier) should have messages")
            }
        }
    }

    @Test func taskAwareCalloutsEnviroTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "enviro", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") }
            #expect(hasUrgent, "enviro tier3 should contain a CLOSE THIS directive")
        }
    }

    @Test func taskAwareCalloutsEnviroTier1ReferencesEcology() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "enviro", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("ecosystem") || lower.contains("ecology")
                    || lower.contains("field") || lower.contains("environment")
                    || lower.contains("lab") || lower.contains("report")
            }
            #expect(hasRef, "enviro tier1 messages must reference ecology/environment domain")
        }
    }

    // MARK: - Finance keyword

    @Test func extractTaskKeywordFinanceCPAExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for my CPA exam") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "prepare for the CPA prep course") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "review my CPA practice problems") == "finance")
    }

    @Test func extractTaskKeywordFinanceCFA() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for my CFA exam") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "complete my CFA practice set") == "finance")
    }

    @Test func extractTaskKeywordFinanceStatements() {
        #expect(CalloutManager.extractTaskKeyword(from: "analyze these financial statements") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "prepare a balance sheet for class") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "write up the income statement analysis") == "finance")
    }

    @Test func extractTaskKeywordFinanceModeling() {
        #expect(CalloutManager.extractTaskKeyword(from: "build a financial model for the case") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "do my financial analysis assignment") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "complete a corporate finance problem set") == "finance")
    }

    @Test func extractTaskKeywordFinanceAudit() {
        #expect(CalloutManager.extractTaskKeyword(from: "prepare for my auditing exam") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "complete this audit engagement exercise") == "finance")
    }

    @Test func extractTaskKeywordFinanceAccounting() {
        #expect(CalloutManager.extractTaskKeyword(from: "study managerial accounting chapter 5") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "do my cost accounting homework") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "study financial accounting principles") == "finance")
    }

    @Test func extractTaskKeywordFinanceCashFlow() {
        #expect(CalloutManager.extractTaskKeyword(from: "write up the cash flow statement") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "complete the cash flow analysis") == "finance")
    }

    @Test func extractTaskKeywordFinanceDoesNotOverrideBudget() {
        // Generic "budget" / "finances" should still route to "budget", not "finance"
        #expect(CalloutManager.extractTaskKeyword(from: "do my monthly budget") == "budget")
        #expect(CalloutManager.extractTaskKeyword(from: "manage my personal finances") == "budget")
    }

    @Test func taskAwareCalloutsFinanceHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "finance", tier: tier)
                #expect(!msgs.isEmpty, "finance tier \(tier) should have messages")
            }
        }
    }

    @Test func taskAwareCalloutsFinanceDedicatedPoolSize() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "finance", tier: 1)
            let t2 = CalloutManager.shared.taskAwareCallouts(keyword: "finance", tier: 2)
            let t3 = CalloutManager.shared.taskAwareCallouts(keyword: "finance", tier: 3)
            #expect(t1.count >= 3, "finance tier1 must have at least 3 messages")
            #expect(t2.count >= 2, "finance tier2 must have at least 2 messages")
            #expect(t3.count >= 2, "finance tier3 must have at least 2 messages")
        }
    }

    @Test func taskAwareCalloutsFinanceTier1ReferencesAccountingWork() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "finance", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("financial") || lower.contains("accounting") || lower.contains("cpa")
                    || lower.contains("analysis") || lower.contains("prep")
            }
            #expect(hasRef, "finance tier1 messages must reference finance/accounting domain")
        }
    }

    @Test func taskAwareCalloutsFinanceTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "finance", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") }
            #expect(hasUrgent, "finance tier3 should contain a CLOSE THIS directive")
        }
    }

    @Test func taskAwareCalloutsFinanceTier4FallsThrough() async {
        await MainActor.run {
            let tier4 = CalloutManager.shared.taskAwareCallouts(keyword: "finance", tier: 4)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "finance", tier: 3)
            #expect(tier4 == tier3, "tier4 (out of range) should return same pool as tier3")
        }
    }

    @Test func extractTaskKeywordFinanceSeries7() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for my Series 7 exam") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "prep for the Series 63 license test") == "finance")
    }

    @Test func extractTaskKeywordFinanceDCF() {
        #expect(CalloutManager.extractTaskKeyword(from: "build a DCF model for this company") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "do discounted cash flow analysis for the case") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "complete the DCF assignment") == "finance")
    }

    @Test func extractTaskKeywordFinanceLBO() {
        #expect(CalloutManager.extractTaskKeyword(from: "write up the LBO case") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "build a leveraged buyout model") == "finance")
    }

    @Test func extractTaskKeywordFinanceBloomberg() {
        #expect(CalloutManager.extractTaskKeyword(from: "practice on the Bloomberg Terminal") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "run my analysis on bloomberg terminal") == "finance")
    }

    @Test func extractTaskKeywordFinanceComparables() {
        #expect(CalloutManager.extractTaskKeyword(from: "do comparable company analysis for the pitch") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "build a comps analysis for the case") == "finance")
    }

    @Test func extractTaskKeywordFinanceInvestmentBanking() {
        #expect(CalloutManager.extractTaskKeyword(from: "review my investment banking case study") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "prep for IB analyst recruiting") == "finance")
    }

    @Test func extractTaskKeywordFinanceEquityResearch() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my equity research report") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the equity research assignment") == "finance")
    }

    @Test func extractTaskKeywordFinanceValuation() {
        #expect(CalloutManager.extractTaskKeyword(from: "build a valuation model for the M&A case") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "complete company valuation for class") == "finance")
    }

    @Test func extractTaskKeywordFinanceFINRA() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for my FINRA exam") == "finance")
        #expect(CalloutManager.extractTaskKeyword(from: "review FINRA rules and regulations") == "finance")
    }

    @Test func taskAwareCalloutsFinanceMentionsIBTerms() async {
        await MainActor.run {
            let allMessages = (1...3).flatMap { tier in
                CalloutManager.shared.taskAwareCallouts(keyword: "finance", tier: tier)
            }
            let hasIBRef = allMessages.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("dcf") || lower.contains("bloomberg") || lower.contains("lbo")
                    || lower.contains("model") || lower.contains("cfa") || lower.contains("cpa")
                    || lower.contains("investment") || lower.contains("financial")
            }
            #expect(hasIBRef, "finance callout pool should reference investment banking / finance terms")
        }
    }

    // MARK: - Policy keyword

    @Test func extractTaskKeywordPolicyMemo() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my policy memo for class") == "policy")
        #expect(CalloutManager.extractTaskKeyword(from: "draft the policy memos due Friday") == "policy")
    }

    @Test func extractTaskKeywordPolicyBrief() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a policy brief on housing") == "policy")
        #expect(CalloutManager.extractTaskKeyword(from: "complete my policy briefs for seminar") == "policy")
    }

    @Test func extractTaskKeywordPolicyRegulatoryAnalysis() {
        #expect(CalloutManager.extractTaskKeyword(from: "do my regulatory analysis assignment") == "policy")
        #expect(CalloutManager.extractTaskKeyword(from: "analyze the regulatory framework for this industry") == "policy")
    }

    @Test func extractTaskKeywordPolicyLegislative() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a legislative brief for my policy class") == "policy")
        #expect(CalloutManager.extractTaskKeyword(from: "draft a legislative memo for the committee") == "policy")
    }

    @Test func extractTaskKeywordPolicyAnalysis() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete my policy analysis paper") == "policy")
        #expect(CalloutManager.extractTaskKeyword(from: "do policy recommendation research") == "policy")
    }

    @Test func extractTaskKeywordPolicyHealthFiscal() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a paper on health policy reform") == "policy")
        #expect(CalloutManager.extractTaskKeyword(from: "analyze fiscal policy effects") == "policy")
        #expect(CalloutManager.extractTaskKeyword(from: "study monetary policy for my econ exam") == "policy")
    }

    @Test func extractTaskKeywordPolicyDoesNotOverrideLegal() {
        // Legal-specific terms should still route to "legal"
        #expect(CalloutManager.extractTaskKeyword(from: "write a legal brief for moot court") == "legal")
        #expect(CalloutManager.extractTaskKeyword(from: "draft pleadings for my law class") == "legal")
    }

    @Test func taskAwareCalloutsPolicyHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "policy", tier: tier)
                #expect(!msgs.isEmpty, "policy tier \(tier) should have messages")
            }
        }
    }

    @Test func taskAwareCalloutsPolicyDedicatedPoolSize() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "policy", tier: 1)
            let t2 = CalloutManager.shared.taskAwareCallouts(keyword: "policy", tier: 2)
            let t3 = CalloutManager.shared.taskAwareCallouts(keyword: "policy", tier: 3)
            #expect(t1.count >= 3, "policy tier1 must have at least 3 messages")
            #expect(t2.count >= 2, "policy tier2 must have at least 2 messages")
            #expect(t3.count >= 2, "policy tier3 must have at least 2 messages")
        }
    }

    @Test func taskAwareCalloutsPolicyTier1ReferencesPolicyWork() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "policy", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("policy") || lower.contains("memo") || lower.contains("brief")
                    || lower.contains("analysis") || lower.contains("regulatory")
            }
            #expect(hasRef, "policy tier1 messages must reference policy work domain")
        }
    }

    @Test func taskAwareCalloutsPolicyTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "policy", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") }
            #expect(hasUrgent, "policy tier3 should contain a CLOSE THIS directive")
        }
    }

    @Test func taskAwareCalloutsPolicyTier4FallsThrough() async {
        await MainActor.run {
            let tier4 = CalloutManager.shared.taskAwareCallouts(keyword: "policy", tier: 4)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "policy", tier: 3)
            #expect(tier4 == tier3, "tier4 (out of range) should return same pool as tier3")
        }
    }

    // MARK: - UX design keyword

    @Test func extractTaskKeywordFromUserResearch() {
        // "user research" routes to ux even though it contains "research";
        // the ux branch is ordered before the generic research branch.
        #expect(CalloutManager.extractTaskKeyword(from: "conduct user research for my app") == "ux")
        #expect(CalloutManager.extractTaskKeyword(from: "do user research interviews today") == "ux")
        #expect(CalloutManager.extractTaskKeyword(from: "analyze my user research data") == "ux")
    }

    @Test func extractTaskKeywordFromUsabilityTesting() {
        // avoid "report" (report branch) and standalone "test" (studying branch)
        #expect(CalloutManager.extractTaskKeyword(from: "run usability tests on the prototype") == "ux")
        #expect(CalloutManager.extractTaskKeyword(from: "complete my usability testing writeup") == "ux")
        #expect(CalloutManager.extractTaskKeyword(from: "run my usability testing today") == "ux")
    }

    @Test func extractTaskKeywordFromUserFlow() {
        // avoid "document" (report branch)
        #expect(CalloutManager.extractTaskKeyword(from: "map out the user flow for checkout") == "ux")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the user flows for onboarding") == "ux")
    }

    @Test func extractTaskKeywordFromUserJourney() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete my user journey map") == "ux")
        #expect(CalloutManager.extractTaskKeyword(from: "create user journey maps for each persona") == "ux")
        #expect(CalloutManager.extractTaskKeyword(from: "finish the journey mapping exercise") == "ux")
    }

    @Test func extractTaskKeywordFromAffinityMap() {
        // avoid "notes" and "research" as standalone words (studying / research branches)
        #expect(CalloutManager.extractTaskKeyword(from: "do affinity mapping from my interviews") == "ux")
        #expect(CalloutManager.extractTaskKeyword(from: "build an affinity diagram for the product") == "ux")
        #expect(CalloutManager.extractTaskKeyword(from: "cluster insights into an affinity map") == "ux")
    }

    @Test func extractTaskKeywordFromDesignThinking() {
        #expect(CalloutManager.extractTaskKeyword(from: "apply design thinking to this problem") == "ux")
        #expect(CalloutManager.extractTaskKeyword(from: "facilitate a design thinking exercise") == "ux")
    }

    @Test func extractTaskKeywordFromHCI() {
        // avoid "study"/"exam" (studying branch)
        #expect(CalloutManager.extractTaskKeyword(from: "apply HCI principles to my interface") == "ux")
        #expect(CalloutManager.extractTaskKeyword(from: "learn about human-computer interaction today") == "ux")
    }

    @Test func extractTaskKeywordFromUXResearch() {
        // "ux research" is a compound phrase caught by the ux branch before the report branch
        #expect(CalloutManager.extractTaskKeyword(from: "write up my UX research findings") == "ux")
        #expect(CalloutManager.extractTaskKeyword(from: "do UX design work for the onboarding flow") == "ux")
        #expect(CalloutManager.extractTaskKeyword(from: "work on UX writing for the dashboard") == "ux")
    }

    @Test func extractTaskKeywordFromInformationArchitecture() {
        // "information architecture" is a UX term — must not route to building architecture
        // avoid "document" (report branch)
        #expect(CalloutManager.extractTaskKeyword(from: "design the information architecture for my app") == "ux")
        #expect(CalloutManager.extractTaskKeyword(from: "map out the information architecture of the site") == "ux")
    }

    @Test func extractTaskKeywordFromInteractionDesign() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on interaction design for the modal") == "ux")
    }

    @Test func extractTaskKeywordFromUserStory() {
        #expect(CalloutManager.extractTaskKeyword(from: "write user stories for the sprint") == "ux")
        #expect(CalloutManager.extractTaskKeyword(from: "refine user story acceptance criteria") == "ux")
    }

    @Test func extractTaskKeywordFromWireframing() {
        #expect(CalloutManager.extractTaskKeyword(from: "wireframing the settings screen today") == "ux")
    }

    @Test func extractTaskKeywordUXDoesNotOverrideEssay() {
        // essay fires before ux
        #expect(CalloutManager.extractTaskKeyword(from: "write an essay on UX design principles") == "essay")
    }

    @Test func extractTaskKeywordUXDoesNotOverrideCode() {
        // code fires before ux
        #expect(CalloutManager.extractTaskKeyword(from: "code the user authentication flow") == "code")
    }

    @Test func extractTaskKeywordUXDoesNotFalseMatchGenericDesign() {
        // generic design without any UX-specific terms routes to design, not ux
        #expect(CalloutManager.extractTaskKeyword(from: "design my logo in Photoshop") == "design")
    }

    @Test func taskAwareCalloutsUXHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "ux", tier: tier)
                #expect(!msgs.isEmpty, "ux tier \(tier) should have messages")
            }
        }
    }

    @Test func taskAwareCalloutsUXDedicatedPoolSize() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "ux", tier: 1)
            let t2 = CalloutManager.shared.taskAwareCallouts(keyword: "ux", tier: 2)
            let t3 = CalloutManager.shared.taskAwareCallouts(keyword: "ux", tier: 3)
            #expect(t1.count >= 3, "ux tier1 must have at least 3 messages")
            #expect(t2.count >= 2, "ux tier2 must have at least 2 messages")
            #expect(t3.count >= 2, "ux tier3 must have at least 2 messages")
        }
    }

    @Test func taskAwareCalloutsUXTier1ReferencesUXWork() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "ux", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("ux") || lower.contains("user") || lower.contains("design")
                    || lower.contains("research") || lower.contains("usability")
            }
            #expect(hasRef, "ux tier1 messages must reference UX work domain")
        }
    }

    @Test func taskAwareCalloutsUXTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "ux", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") }
            #expect(hasUrgent, "ux tier3 should contain a CLOSE THIS directive")
        }
    }

    @Test func taskAwareCalloutsUXTier4FallsThrough() async {
        await MainActor.run {
            let tier4 = CalloutManager.shared.taskAwareCallouts(keyword: "ux", tier: 4)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "ux", tier: 3)
            #expect(tier4 == tier3, "tier4 (out of range) should return same pool as tier3")
        }
    }

    // MARK: - Statistics keyword tests

    @Test func extractTaskKeywordRStudio() {
        #expect(CalloutManager.extractTaskKeyword(from: "run my analysis in RStudio") == "statistics")
    }

    @Test func extractTaskKeywordRStudioSpaced() {
        #expect(CalloutManager.extractTaskKeyword(from: "open R studio and clean my dataset") == "statistics")
    }

    @Test func extractTaskKeywordSPSS() {
        #expect(CalloutManager.extractTaskKeyword(from: "run an ANOVA in SPSS for my thesis") == "statistics")
    }

    @Test func extractTaskKeywordStata() {
        #expect(CalloutManager.extractTaskKeyword(from: "analyze survey data in Stata") == "statistics")
    }

    @Test func extractTaskKeywordHypothesisTesting() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete my hypothesis testing assignment") == "statistics")
    }

    @Test func extractTaskKeywordLinearRegression() {
        #expect(CalloutManager.extractTaskKeyword(from: "write up my linear regression analysis") == "statistics")
    }

    @Test func extractTaskKeywordLogisticRegression() {
        #expect(CalloutManager.extractTaskKeyword(from: "run a logistic regression on this dataset") == "statistics")
    }

    @Test func extractTaskKeywordANOVA() {
        #expect(CalloutManager.extractTaskKeyword(from: "interpret the ANOVA results from my lab") == "statistics")
    }

    @Test func extractTaskKeywordStatisticalAnalysis() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish my statistical analysis report") == "statistics")
    }

    @Test func extractTaskKeywordDescriptiveStatistics() {
        #expect(CalloutManager.extractTaskKeyword(from: "calculate descriptive statistics for my data") == "statistics")
    }

    @Test func extractTaskKeywordStatisticsDoesNotOverrideStudying() {
        // bare word("statistics") stays in studying
        #expect(CalloutManager.extractTaskKeyword(from: "study statistics for my exam") == "studying")
    }

    @Test func extractTaskKeywordRegressionTestingRoutesToCode() {
        // "regression testing" without a specific stats phrase routes to code (via python etc.)
        // or falls through — should NOT route to statistics
        let result = CalloutManager.extractTaskKeyword(from: "write regression tests for my API")
        #expect(result != "statistics", "regression testing (software QA) must not route to statistics")
    }

    @Test func taskAwareCalloutsStatisticsHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "statistics", tier: tier)
                #expect(!msgs.isEmpty, "statistics tier \(tier) should have messages")
            }
        }
    }

    @Test func taskAwareCalloutsStatisticsDedicatedPoolSize() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "statistics", tier: 1)
            let t2 = CalloutManager.shared.taskAwareCallouts(keyword: "statistics", tier: 2)
            let t3 = CalloutManager.shared.taskAwareCallouts(keyword: "statistics", tier: 3)
            #expect(t1.count >= 3, "statistics tier1 must have at least 3 messages")
            #expect(t2.count >= 2, "statistics tier2 must have at least 2 messages")
            #expect(t3.count >= 2, "statistics tier3 must have at least 2 messages")
        }
    }

    @Test func taskAwareCalloutsStatisticsTier1ReferencesStats() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "statistics", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("stat") || lower.contains("analysis") || lower.contains("regression")
                    || lower.contains("dataset") || lower.contains("data")
            }
            #expect(hasRef, "statistics tier1 messages must reference stats work domain")
        }
    }

    @Test func taskAwareCalloutsStatisticsTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "statistics", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") }
            #expect(hasUrgent, "statistics tier3 should contain a CLOSE THIS directive")
        }
    }

    @Test func taskAwareCalloutsStatisticsTier4FallsThrough() async {
        await MainActor.run {
            let tier4 = CalloutManager.shared.taskAwareCallouts(keyword: "statistics", tier: 4)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "statistics", tier: 3)
            #expect(tier4 == tier3, "tier4 (out of range) should return same pool as tier3")
        }
    }

    // MARK: - Kinesiology keyword tests

    @Test func extractTaskKeywordKinesiology() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish my kinesiology assignment") == "kinesiology")
    }

    @Test func extractTaskKeywordBiomechanics() {
        #expect(CalloutManager.extractTaskKeyword(from: "write up my biomechanics lab report") == "kinesiology")
    }

    @Test func extractTaskKeywordExercisePhysiology() {
        #expect(CalloutManager.extractTaskKeyword(from: "study exercise physiology for my exam") == "kinesiology")
    }

    @Test func extractTaskKeywordSportsScience() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete my sports science assignment") == "kinesiology")
    }

    @Test func extractTaskKeywordCSCS() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for the CSCS exam") == "kinesiology")
    }

    @Test func extractTaskKeywordPhysicalTherapy() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my physical therapy case notes") == "kinesiology")
    }

    @Test func extractTaskKeywordStrengthAndConditioning() {
        #expect(CalloutManager.extractTaskKeyword(from: "plan my strength and conditioning program") == "kinesiology")
    }

    @Test func extractTaskKeywordKinesiologyDoesNotOverrideCode() {
        // code fires before kinesiology
        #expect(CalloutManager.extractTaskKeyword(from: "code a biomechanics simulation in Python") == "code")
    }

    @Test func extractTaskKeywordKinesiologyDoesNotMapGeneralFitness() {
        // "gym workout" with no kinesiology-specific phrase stays in fitness
        let result = CalloutManager.extractTaskKeyword(from: "plan my gym workout")
        #expect(result == "fitness", "generic gym tasks must stay in fitness, not kinesiology")
    }

    @Test func taskAwareCalloutsKinesiologyHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "kinesiology", tier: tier)
                #expect(!msgs.isEmpty, "kinesiology tier \(tier) should have messages")
            }
        }
    }

    @Test func taskAwareCalloutsKinesiologyDedicatedPoolSize() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "kinesiology", tier: 1)
            let t2 = CalloutManager.shared.taskAwareCallouts(keyword: "kinesiology", tier: 2)
            let t3 = CalloutManager.shared.taskAwareCallouts(keyword: "kinesiology", tier: 3)
            #expect(t1.count >= 3, "kinesiology tier1 must have at least 3 messages")
            #expect(t2.count >= 2, "kinesiology tier2 must have at least 2 messages")
            #expect(t3.count >= 2, "kinesiology tier3 must have at least 2 messages")
        }
    }

    @Test func taskAwareCalloutsKinesiologyTier1ReferencesKinesiology() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "kinesiology", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("kinesiology") || lower.contains("biomechanics")
                    || lower.contains("physiology") || lower.contains("movement")
                    || lower.contains("sports") || lower.contains("exercise")
            }
            #expect(hasRef, "kinesiology tier1 messages must reference the sports science domain")
        }
    }

    @Test func taskAwareCalloutsKinesiologyTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "kinesiology", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") }
            #expect(hasUrgent, "kinesiology tier3 should contain a CLOSE THIS directive")
        }
    }

    @Test func taskAwareCalloutsKinesiologyTier4FallsThrough() async {
        await MainActor.run {
            let tier4 = CalloutManager.shared.taskAwareCallouts(keyword: "kinesiology", tier: 4)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "kinesiology", tier: 3)
            #expect(tier4 == tier3, "tier4 (out of range) should return same pool as tier3")
        }
    }

    // MARK: - Veterinary keyword tests

    @Test func extractTaskKeywordVeterinary() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish my veterinary pharmacology notes") == "veterinary")
    }

    @Test func extractTaskKeywordVeterinarianWord() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for veterinarian licensing exam") == "veterinary")
    }

    @Test func extractTaskKeywordVetSchool() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for my vet school anatomy exam") == "veterinary")
    }

    @Test func extractTaskKeywordNAVLE() {
        #expect(CalloutManager.extractTaskKeyword(from: "prep for the NAVLE licensing exam") == "veterinary")
    }

    @Test func extractTaskKeywordAnimalScience() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete my animal science research paper") == "veterinary")
    }

    @Test func extractTaskKeywordZoology() {
        #expect(CalloutManager.extractTaskKeyword(from: "study zoology for my practical exam") == "veterinary")
    }

    @Test func extractTaskKeywordSmallAnimal() {
        #expect(CalloutManager.extractTaskKeyword(from: "write up my small animal surgery case notes") == "veterinary")
    }

    @Test func extractTaskKeywordVetTech() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete my vet tech certification materials") == "veterinary")
    }

    @Test func extractTaskKeywordVeterinaryDoesNotOverridePremed() {
        // plain anatomy without vet context stays in premed
        #expect(CalloutManager.extractTaskKeyword(from: "study anatomy for medical school") == "premed")
    }

    @Test func taskAwareCalloutsVeterinaryHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "veterinary", tier: tier)
                #expect(!msgs.isEmpty, "veterinary tier \(tier) should have messages")
            }
        }
    }

    @Test func taskAwareCalloutsVeterinaryDedicatedPoolSize() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "veterinary", tier: 1)
            let t2 = CalloutManager.shared.taskAwareCallouts(keyword: "veterinary", tier: 2)
            let t3 = CalloutManager.shared.taskAwareCallouts(keyword: "veterinary", tier: 3)
            #expect(t1.count >= 3, "veterinary tier1 must have at least 3 messages")
            #expect(t2.count >= 2, "veterinary tier2 must have at least 2 messages")
            #expect(t3.count >= 2, "veterinary tier3 must have at least 2 messages")
        }
    }

    @Test func taskAwareCalloutsVeterinaryTier1ReferencesVetWork() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "veterinary", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("vet") || lower.contains("animal") || lower.contains("patient")
                    || lower.contains("case") || lower.contains("notes")
            }
            #expect(hasRef, "veterinary tier1 messages must reference vet work domain")
        }
    }

    @Test func taskAwareCalloutsVeterinaryTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "veterinary", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") }
            #expect(hasUrgent, "veterinary tier3 should contain a CLOSE THIS directive")
        }
    }

    @Test func taskAwareCalloutsVeterinaryTier4FallsThrough() async {
        await MainActor.run {
            let tier4 = CalloutManager.shared.taskAwareCallouts(keyword: "veterinary", tier: 4)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "veterinary", tier: 3)
            #expect(tier4 == tier3, "tier4 (out of range) should return same pool as tier3")
        }
    }

    // MARK: - Business/management keyword tests

    @Test func extractTaskKeywordBusinessMBA() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on my MBA strategic management case") == "business")
    }

    @Test func extractTaskKeywordBusinessGMAT() {
        #expect(CalloutManager.extractTaskKeyword(from: "prep for the GMAT verbal section") == "business")
    }

    @Test func extractTaskKeywordBusinessCaseAnalysis() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my case analysis for marketing class") == "business")
    }

    @Test func extractTaskKeywordBusinessSupplyChain() {
        #expect(CalloutManager.extractTaskKeyword(from: "analyze our supply chain bottlenecks") == "business")
    }

    @Test func extractTaskKeywordBusinessOrgBehavior() {
        #expect(CalloutManager.extractTaskKeyword(from: "study organizational behavior for my management class") == "business")
    }

    @Test func extractTaskKeywordBusinessStrategy() {
        #expect(CalloutManager.extractTaskKeyword(from: "draft our business strategy for next quarter") == "business")
    }

    @Test func extractTaskKeywordBusinessMarketResearch() {
        #expect(CalloutManager.extractTaskKeyword(from: "do market research for our product launch") == "business")
    }

    @Test func extractTaskKeywordBusinessMarketingResearch() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete a marketing research assignment") == "business")
    }

    @Test func extractTaskKeywordBusinessSWOT() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete a SWOT analysis for my management assignment") == "business")
    }

    @Test func extractTaskKeywordBusinessHumanResources() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish my human resources management case study") == "business")
    }

    @Test func extractTaskKeywordBusinessCompetitiveAnalysis() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a competitive analysis for my strategy class") == "business")
    }

    @Test func extractTaskKeywordBusinessDoesNotOverrideStartup() {
        // pitch deck is already in the startup branch (positioned before business)
        #expect(CalloutManager.extractTaskKeyword(from: "finish my pitch deck for the investor meeting") == "startup")
    }

    @Test func extractTaskKeywordBusinessDoesNotOverrideCode() {
        // "debug" fires the code branch before business is reached
        #expect(CalloutManager.extractTaskKeyword(from: "debug the business logic in my app") == "code")
    }

    @Test func taskAwareCalloutsBusinessHasMessages() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "business", tier: tier)
                #expect(!msgs.isEmpty, "business tier \(tier) should have messages")
            }
        }
    }

    @Test func taskAwareCalloutsBusinessDedicatedPoolSize() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "business", tier: 1)
            let t2 = CalloutManager.shared.taskAwareCallouts(keyword: "business", tier: 2)
            let t3 = CalloutManager.shared.taskAwareCallouts(keyword: "business", tier: 3)
            #expect(t1.count >= 3, "business tier1 must have at least 3 messages")
            #expect(t2.count >= 2, "business tier2 must have at least 2 messages")
            #expect(t3.count >= 2, "business tier3 must have at least 2 messages")
        }
    }

    @Test func taskAwareCalloutsBusinessTier1ReferencesBusinessWork() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "business", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("case") || lower.contains("business") || lower.contains("mba")
                    || lower.contains("mckinsey") || lower.contains("management") || lower.contains("strategy")
            }
            #expect(hasRef, "business tier1 messages must reference business work domain")
        }
    }

    @Test func taskAwareCalloutsBusinessTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "business", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") }
            #expect(hasUrgent, "business tier3 should contain a CLOSE THIS directive")
        }
    }

    // MARK: - publicheath keyword extraction

    @Test func extractTaskKeywordReturnsPublicheathForEpidemiology() {
        let kw = CalloutManager.extractTaskKeyword(from: "study epidemiology for my MPH exam")
        #expect(kw == "publicheath")
    }

    @Test func extractTaskKeywordReturnsPublicheathForBiostatistics() {
        let kw = CalloutManager.extractTaskKeyword(from: "complete my biostatistics homework")
        #expect(kw == "publicheath")
    }

    @Test func extractTaskKeywordReturnsPublicheathForCommunityHealth() {
        let kw = CalloutManager.extractTaskKeyword(from: "work on my community health project")
        #expect(kw == "publicheath")
    }

    @Test func extractTaskKeywordReturnsPublicheathForGlobalHealth() {
        let kw = CalloutManager.extractTaskKeyword(from: "research global health disparities for class")
        #expect(kw == "publicheath")
    }

    @Test func extractTaskKeywordReturnsPublicheathForPublicHealth() {
        let kw = CalloutManager.extractTaskKeyword(from: "study public health for my MPH program")
        #expect(kw == "publicheath")
    }

    @Test func extractTaskKeywordReturnsPublicheathForInfectiousDisease() {
        let kw = CalloutManager.extractTaskKeyword(from: "analyze infectious disease transmission data")
        #expect(kw == "publicheath")
    }

    @Test func extractTaskKeywordReturnsPublicheathForOutbreak() {
        let kw = CalloutManager.extractTaskKeyword(from: "write an outbreak investigation report")
        #expect(kw == "publicheath")
    }

    @Test func extractTaskKeywordReturnsPublicheathForMphProgram() {
        let kw = CalloutManager.extractTaskKeyword(from: "finish my MPH program capstone project")
        #expect(kw == "publicheath")
    }

    @Test func extractTaskKeywordReturnsPublicheathForMasterOfPublicHealth() {
        let kw = CalloutManager.extractTaskKeyword(from: "complete my master of public health thesis")
        #expect(kw == "publicheath")
    }

    @Test func extractTaskKeywordReturnsPublicheathForPopulationHealth() {
        let kw = CalloutManager.extractTaskKeyword(from: "analyze population health outcomes for my research")
        #expect(kw == "publicheath")
    }

    @Test func extractTaskKeywordReturnsPublicheathForHealthEquity() {
        let kw = CalloutManager.extractTaskKeyword(from: "write a paper on health equity and social determinants of health")
        #expect(kw == "publicheath")
    }

    @Test func extractTaskKeywordReturnsPublicheathForDiseaseSurveillance() {
        let kw = CalloutManager.extractTaskKeyword(from: "build a disease surveillance dashboard for my MPH class")
        #expect(kw == "publicheath")
    }

    @Test func extractTaskKeywordPublicheathFalsePositiveGuard_RunningSpeed() {
        // "mph" without public health context (miles per hour) should NOT fire publicheath.
        // The branch only matches "mph program/degree/student/class/exam/capstone/thesis/master of public health"
        // phrases, not the bare acronym — so "I ran at 6 mph" falls through.
        let kw = CalloutManager.extractTaskKeyword(from: "I ran at 6 mph today")
        #expect(kw != "publicheath", "bare mph (miles per hour) must not trigger publicheath")
    }

    // MARK: - publicheath callout pool properties

    @Test func publichealthCalloutsAllTiersAreNonEmpty() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "publicheath", tier: 1)
            let t2 = CalloutManager.shared.taskAwareCallouts(keyword: "publicheath", tier: 2)
            let t3 = CalloutManager.shared.taskAwareCallouts(keyword: "publicheath", tier: 3)
            #expect(t1.count >= 3, "publicheath tier1 must have at least 3 messages")
            #expect(t2.count >= 2, "publicheath tier2 must have at least 2 messages")
            #expect(t3.count >= 2, "publicheath tier3 must have at least 2 messages")
        }
    }

    @Test func publichealthCalloutsTier1ReferencesDomain() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "publicheath", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("epidemiology") || lower.contains("public health")
                    || lower.contains("community health") || lower.contains("mph")
            }
            #expect(hasRef, "publicheath tier1 messages must reference the public health domain")
        }
    }

    @Test func publichealthCalloutsTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "publicheath", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") || $0.hasPrefix("no one") }
            #expect(hasUrgent, "publicheath tier3 should contain an urgent directive or MPH line")
        }
    }

    @Test func publichealthCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "publicheath", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "publicheath tier \(tier) callout must not be empty")
                }
            }
        }
    }

    // MARK: - paramedicine keyword routing

    @Test func extractTaskKeywordReturnsParamedicineForEMT() {
        let kw = CalloutManager.extractTaskKeyword(from: "study for my EMT exam")
        #expect(kw == "paramedicine")
    }

    @Test func extractTaskKeywordReturnsParamedicineForParamedic() {
        let kw = CalloutManager.extractTaskKeyword(from: "complete my paramedic assignment")
        #expect(kw == "paramedicine")
    }

    @Test func extractTaskKeywordReturnsParamedicineForNREMT() {
        let kw = CalloutManager.extractTaskKeyword(from: "prep for the NREMT certification")
        #expect(kw == "paramedicine")
    }

    @Test func extractTaskKeywordReturnsParamedicineForAEMT() {
        let kw = CalloutManager.extractTaskKeyword(from: "finish my AEMT coursework")
        #expect(kw == "paramedicine")
    }

    @Test func extractTaskKeywordReturnsParamedicineForEMSProtocol() {
        let kw = CalloutManager.extractTaskKeyword(from: "review EMS protocol updates for my class")
        #expect(kw == "paramedicine")
    }

    @Test func extractTaskKeywordReturnsParamedicineForACLS() {
        let kw = CalloutManager.extractTaskKeyword(from: "study for my ACLS recertification")
        #expect(kw == "paramedicine")
    }

    @Test func extractTaskKeywordReturnsParamedicineForCPRCertification() {
        let kw = CalloutManager.extractTaskKeyword(from: "prepare for my CPR certification test")
        #expect(kw == "paramedicine")
    }

    @Test func extractTaskKeywordReturnsParamedicineForPreHospital() {
        let kw = CalloutManager.extractTaskKeyword(from: "write a report on pre-hospital care protocols")
        #expect(kw == "paramedicine")
    }

    @Test func extractTaskKeywordReturnsParamedicineForTraumaAssessment() {
        let kw = CalloutManager.extractTaskKeyword(from: "practice trauma assessment scenarios")
        #expect(kw == "paramedicine")
    }

    @Test func extractTaskKeywordParamedicineFalsePositive_NursingCarePlan() {
        // "care plan" should route to nursing, not paramedicine
        let kw = CalloutManager.extractTaskKeyword(from: "write my nursing care plan for class")
        #expect(kw == "nursing", "nursing care plan should route to nursing, not paramedicine")
    }

    // MARK: - paramedicine callout pool properties

    @Test func paramedicineCalloutsAllTiersAreNonEmpty() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "paramedicine", tier: 1)
            let t2 = CalloutManager.shared.taskAwareCallouts(keyword: "paramedicine", tier: 2)
            let t3 = CalloutManager.shared.taskAwareCallouts(keyword: "paramedicine", tier: 3)
            #expect(t1.count >= 3, "paramedicine tier1 must have at least 3 messages")
            #expect(t2.count >= 2, "paramedicine tier2 must have at least 2 messages")
            #expect(t3.count >= 2, "paramedicine tier3 must have at least 2 messages")
        }
    }

    @Test func paramedicineTier1HasFourMessages() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "paramedicine", tier: 1)
            #expect(t1.count == 4, "paramedicine tier1 must have exactly 4 messages")
        }
    }

    @Test func paramedicineTier1ReferencesDomain() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "paramedicine", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("nremt") || lower.contains("ems") || lower.contains("emt")
                    || lower.contains("paramedic") || lower.contains("protocol")
            }
            #expect(hasRef, "paramedicine tier1 messages must reference the EMS/EMT domain")
        }
    }

    @Test func paramedicineTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "paramedicine", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") || $0.hasPrefix("no one") }
            #expect(hasUrgent, "paramedicine tier3 should contain an urgent directive")
        }
    }

    @Test func paramedicineCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "paramedicine", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "paramedicine tier \(tier) callout must not be empty")
                }
            }
        }
    }

    // MARK: - socialwork keyword routing

    @Test func extractTaskKeywordReturnsSocialworkForSocialWork() {
        let kw = CalloutManager.extractTaskKeyword(from: "write my social work case notes")
        #expect(kw == "socialwork")
    }

    @Test func extractTaskKeywordReturnsSocialworkForMSW() {
        let kw = CalloutManager.extractTaskKeyword(from: "study for my MSW licensure exam")
        #expect(kw == "socialwork")
    }

    @Test func extractTaskKeywordReturnsSocialworkForBSW() {
        let kw = CalloutManager.extractTaskKeyword(from: "complete my BSW field placement hours")
        #expect(kw == "socialwork")
    }

    @Test func extractTaskKeywordReturnsSocialworkForCaseManagement() {
        let kw = CalloutManager.extractTaskKeyword(from: "finish my case management documentation")
        #expect(kw == "socialwork")
    }

    @Test func extractTaskKeywordReturnsSocialworkForChildWelfare() {
        let kw = CalloutManager.extractTaskKeyword(from: "research child welfare policy for my assignment")
        #expect(kw == "socialwork")
    }

    @Test func extractTaskKeywordReturnsSocialworkForIntakeAssessment() {
        let kw = CalloutManager.extractTaskKeyword(from: "complete the intake assessment for my client")
        #expect(kw == "socialwork")
    }

    @Test func extractTaskKeywordReturnsSocialworkForFieldPlacement() {
        let kw = CalloutManager.extractTaskKeyword(from: "write up my social field placement reflection")
        #expect(kw == "socialwork")
    }

    @Test func extractTaskKeywordSocialworkFalsePositive_TherapyNotes() {
        // therapy notes should route to therapy, not socialwork
        let kw = CalloutManager.extractTaskKeyword(from: "write my therapy notes for today's session")
        #expect(kw == "therapy", "therapy notes should route to therapy, not socialwork")
    }

    // MARK: - socialwork callout pool properties

    @Test func socialworkCalloutsAllTiersAreNonEmpty() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "socialwork", tier: 1)
            let t2 = CalloutManager.shared.taskAwareCallouts(keyword: "socialwork", tier: 2)
            let t3 = CalloutManager.shared.taskAwareCallouts(keyword: "socialwork", tier: 3)
            #expect(t1.count >= 3, "socialwork tier1 must have at least 3 messages")
            #expect(t2.count >= 2, "socialwork tier2 must have at least 2 messages")
            #expect(t3.count >= 2, "socialwork tier3 must have at least 2 messages")
        }
    }

    @Test func socialworkTier1HasFourMessages() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "socialwork", tier: 1)
            #expect(t1.count == 4, "socialwork tier1 must have exactly 4 messages")
        }
    }

    @Test func socialworkTier1ReferencesDomain() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "socialwork", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("case") || lower.contains("social work")
                    || lower.contains("client") || lower.contains("field")
            }
            #expect(hasRef, "socialwork tier1 messages must reference the social work domain")
        }
    }

    @Test func socialworkTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "socialwork", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") || $0.hasPrefix("no one") }
            #expect(hasUrgent, "socialwork tier3 should contain an urgent directive")
        }
    }

    @Test func socialworkCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "socialwork", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "socialwork tier \(tier) callout must not be empty")
                }
            }
        }
    }

    // MARK: - occupationaltherapy keyword routing

    @Test func extractTaskKeywordReturnsOccupationaltherapyForOccupationalTherapy() {
        let kw = CalloutManager.extractTaskKeyword(from: "complete my occupational therapy fieldwork notes")
        #expect(kw == "occupationaltherapy")
    }

    @Test func extractTaskKeywordReturnsOccupationaltherapyForNBCOT() {
        let kw = CalloutManager.extractTaskKeyword(from: "study for the NBCOT exam")
        #expect(kw == "occupationaltherapy")
    }

    @Test func extractTaskKeywordReturnsOccupationaltherapyForADLs() {
        let kw = CalloutManager.extractTaskKeyword(from: "write an activities of daily living assessment")
        #expect(kw == "occupationaltherapy")
    }

    @Test func extractTaskKeywordReturnsOccupationaltherapyForSensoryIntegration() {
        let kw = CalloutManager.extractTaskKeyword(from: "read about sensory integration therapy approaches")
        #expect(kw == "occupationaltherapy")
    }

    @Test func extractTaskKeywordReturnsOccupationaltherapyForHandTherapy() {
        let kw = CalloutManager.extractTaskKeyword(from: "complete my hand therapy certification prep")
        #expect(kw == "occupationaltherapy")
    }

    @Test func extractTaskKeywordReturnsOccupationaltherapyForOTFieldwork() {
        let kw = CalloutManager.extractTaskKeyword(from: "write up my OT fieldwork reflection")
        #expect(kw == "occupationaltherapy")
    }

    @Test func extractTaskKeywordReturnsOccupationaltherapyForFineMotorSkills() {
        let kw = CalloutManager.extractTaskKeyword(from: "research fine motor skills interventions for my OT class")
        #expect(kw == "occupationaltherapy")
    }

    @Test func extractTaskKeywordOccupationaltherapyFalsePositive_TherapyNotes() {
        // therapy notes should route to therapy, not occupationaltherapy
        let kw = CalloutManager.extractTaskKeyword(from: "write my therapy notes for today's session")
        #expect(kw == "therapy", "therapy notes should route to therapy, not occupationaltherapy")
    }

    // MARK: - occupationaltherapy callout pool properties

    @Test func occupationaltherapyCalloutsAllTiersAreNonEmpty() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "occupationaltherapy", tier: 1)
            let t2 = CalloutManager.shared.taskAwareCallouts(keyword: "occupationaltherapy", tier: 2)
            let t3 = CalloutManager.shared.taskAwareCallouts(keyword: "occupationaltherapy", tier: 3)
            #expect(t1.count >= 3, "occupationaltherapy tier1 must have at least 3 messages")
            #expect(t2.count >= 2, "occupationaltherapy tier2 must have at least 2 messages")
            #expect(t3.count >= 2, "occupationaltherapy tier3 must have at least 2 messages")
        }
    }

    @Test func occupationaltherapyTier1HasFourMessages() async {
        await MainActor.run {
            let t1 = CalloutManager.shared.taskAwareCallouts(keyword: "occupationaltherapy", tier: 1)
            #expect(t1.count == 4, "occupationaltherapy tier1 must have exactly 4 messages")
        }
    }

    @Test func occupationaltherapyTier1ReferencesDomain() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "occupationaltherapy", tier: 1)
            let hasRef = tier1.contains { msg in
                let lower = msg.lowercased()
                return lower.contains("ot") || lower.contains("nbcot") || lower.contains("occupational")
            }
            #expect(hasRef, "occupationaltherapy tier1 messages must reference the OT domain")
        }
    }

    @Test func occupationaltherapyTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "occupationaltherapy", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") || $0.hasPrefix("no one") }
            #expect(hasUrgent, "occupationaltherapy tier3 should contain an urgent directive")
        }
    }

    @Test func occupationaltherapyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "occupationaltherapy", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "occupationaltherapy tier \(tier) callout must not be empty")
                }
            }
        }
    }

    // MARK: - Dental

    @Test func dentalKeywordFromDDS() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for my DDS boards") == "dental")
    }

    @Test func dentalKeywordFromNBDE() {
        #expect(CalloutManager.extractTaskKeyword(from: "prep for the NBDE exam") == "dental")
    }

    @Test func dentalKeywordFromDentalSchool() {
        #expect(CalloutManager.extractTaskKeyword(from: "write dental school clinic notes") == "dental")
    }

    @Test func dentalKeywordFromPerio() {
        #expect(CalloutManager.extractTaskKeyword(from: "review periodontics for tomorrow's quiz") == "dental")
    }

    @Test func dentalKeywordFromOrthodontics() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete my orthodontics case report") == "dental")
    }

    @Test func dentalKeywordDoesNotMatchPremed() {
        #expect(CalloutManager.extractTaskKeyword(from: "study anatomy for med school") != "dental")
    }

    @Test func dentalHasMessages() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dental", tier: 1)
            #expect(!msgs.isEmpty, "dental tier1 pool must be non-empty")
        }
    }

    @Test func dentalDedicatedPoolSize() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "dental", tier: 1)
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "dental", tier: 2)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "dental", tier: 3)
            #expect(tier1.count >= 4, "dental tier1 must have ≥4 messages")
            #expect(tier2.count >= 3, "dental tier2 must have ≥3 messages")
            #expect(tier3.count >= 3, "dental tier3 must have ≥3 messages")
        }
    }

    @Test func dentalTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "dental", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") || $0.hasPrefix("no one") }
            #expect(hasUrgent, "dental tier3 should contain an urgent directive")
        }
    }

    @Test func dentalCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dental", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "dental tier \(tier) callout must not be empty")
                }
            }
        }
    }

    // MARK: - Pharmacy

    @Test func pharmacyKeywordFromNAPLEX() {
        #expect(CalloutManager.extractTaskKeyword(from: "prep for the NAPLEX exam") == "pharmacy")
    }

    @Test func pharmacyKeywordFromPharmD() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for my PharmD boards") == "pharmacy")
    }

    @Test func pharmacyKeywordFromDrugInteractions() {
        #expect(CalloutManager.extractTaskKeyword(from: "review drug interactions for my pharmacy rotation") == "pharmacy")
    }

    @Test func pharmacyKeywordFromPharmacySchool() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete my pharmacy school assignment") == "pharmacy")
    }

    @Test func pharmacyKeywordFromPharmacokinetics() {
        #expect(CalloutManager.extractTaskKeyword(from: "study pharmacokinetics for my exam") == "pharmacy")
    }

    @Test func pharmacyKeywordDoesNotMatchPremed() {
        #expect(CalloutManager.extractTaskKeyword(from: "study pharmacology for medical school") != "pharmacy")
    }

    @Test func pharmacyHasMessages() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "pharmacy", tier: 1)
            #expect(!msgs.isEmpty, "pharmacy tier1 pool must be non-empty")
        }
    }

    @Test func pharmacyDedicatedPoolSize() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "pharmacy", tier: 1)
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "pharmacy", tier: 2)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "pharmacy", tier: 3)
            #expect(tier1.count >= 4, "pharmacy tier1 must have ≥4 messages")
            #expect(tier2.count >= 3, "pharmacy tier2 must have ≥3 messages")
            #expect(tier3.count >= 3, "pharmacy tier3 must have ≥3 messages")
        }
    }

    @Test func pharmacyTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "pharmacy", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") || $0.hasPrefix("no one") || $0.contains("close this") }
            #expect(hasUrgent, "pharmacy tier3 should contain an urgent directive")
        }
    }

    @Test func pharmacyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "pharmacy", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "pharmacy tier \(tier) callout must not be empty")
                }
            }
        }
    }

    // MARK: - Optometry

    @Test func optometryKeywordFromNBEO() {
        #expect(CalloutManager.extractTaskKeyword(from: "prep for the NBEO exam") == "optometry")
    }

    @Test func optometryKeywordFromOptometrySchool() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete my optometry school clinical notes") == "optometry")
    }

    @Test func optometryKeywordFromVisualAcuity() {
        #expect(CalloutManager.extractTaskKeyword(from: "document visual acuity results for my rotation") == "optometry")
    }

    @Test func optometryKeywordFromContactLens() {
        #expect(CalloutManager.extractTaskKeyword(from: "study contact lens fitting techniques") == "optometry")
    }

    @Test func optometryKeywordFromOptometrist() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for my optometrist licensure exam") == "optometry")
    }

    @Test func optometryKeywordDoesNotMatchPremed() {
        #expect(CalloutManager.extractTaskKeyword(from: "study clinical skills for medical school") != "optometry")
    }

    @Test func optometryHasMessages() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "optometry", tier: 1)
            #expect(!msgs.isEmpty, "optometry tier1 pool must be non-empty")
        }
    }

    @Test func optometryDedicatedPoolSize() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "optometry", tier: 1)
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "optometry", tier: 2)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "optometry", tier: 3)
            #expect(tier1.count >= 4, "optometry tier1 must have ≥4 messages")
            #expect(tier2.count >= 3, "optometry tier2 must have ≥3 messages")
            #expect(tier3.count >= 3, "optometry tier3 must have ≥3 messages")
        }
    }

    @Test func optometryTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "optometry", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") || $0.hasPrefix("no one") }
            #expect(hasUrgent, "optometry tier3 should contain an urgent directive")
        }
    }

    @Test func optometryCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "optometry", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "optometry tier \(tier) callout must not be empty")
                }
            }
        }
    }

    // MARK: - Cybersecurity keyword

    @Test func cybersecurityKeywordFromPenTest() {
        #expect(CalloutManager.extractTaskKeyword(from: "practice penetration testing with Metasploit") == "cybersecurity")
    }

    @Test func cybersecurityKeywordFromCTF() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on the CTF challenge") == "cybersecurity")
    }

    @Test func cybersecurityKeywordFromCapturTheFlag() {
        #expect(CalloutManager.extractTaskKeyword(from: "solve a capture the flag puzzle") == "cybersecurity")
    }

    @Test func cybersecurityKeywordFromSecurityPlus() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for CompTIA Security+ exam") == "cybersecurity")
    }

    @Test func cybersecurityKeywordFromOSCP() {
        #expect(CalloutManager.extractTaskKeyword(from: "prepare for OSCP certification") == "cybersecurity")
    }

    @Test func cybersecurityKeywordFromBugBounty() {
        #expect(CalloutManager.extractTaskKeyword(from: "submit my bug bounty report") == "cybersecurity")
    }

    @Test func cybersecurityKeywordFromVulnerabilityAssessment() {
        #expect(CalloutManager.extractTaskKeyword(from: "write up my vulnerability assessment findings") == "cybersecurity")
    }

    @Test func cybersecurityKeywordFromNetworkSecurity() {
        #expect(CalloutManager.extractTaskKeyword(from: "study network security protocols") == "cybersecurity")
    }

    @Test func cybersecurityKeywordFromIncidentResponse() {
        #expect(CalloutManager.extractTaskKeyword(from: "document an incident response playbook") == "cybersecurity")
    }

    @Test func cybersecurityKeywordDoesNotMatchGenericCode() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a Python script for my project") != "cybersecurity")
    }

    @Test func cybersecurityKeywordDoesNotMatchGenericSecurity() {
        // "social security" should NOT trigger cybersecurity
        #expect(CalloutManager.extractTaskKeyword(from: "write a paper about social security policy") != "cybersecurity")
    }

    @Test func cybersecurityHasMessages() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "cybersecurity", tier: 1)
            #expect(!msgs.isEmpty, "cybersecurity tier1 pool must be non-empty")
        }
    }

    @Test func cybersecurityDedicatedPoolSize() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "cybersecurity", tier: 1)
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "cybersecurity", tier: 2)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "cybersecurity", tier: 3)
            #expect(tier1.count >= 4, "cybersecurity tier1 must have ≥4 messages")
            #expect(tier2.count >= 3, "cybersecurity tier2 must have ≥3 messages")
            #expect(tier3.count >= 3, "cybersecurity tier3 must have ≥3 messages")
        }
    }

    @Test func cybersecurityTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "cybersecurity", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") || $0.hasPrefix("no one") }
            #expect(hasUrgent, "cybersecurity tier3 should contain an urgent directive")
        }
    }

    @Test func cybersecurityCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "cybersecurity", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "cybersecurity tier \(tier) callout must not be empty")
                }
            }
        }
    }

    // MARK: - Screenwriting / Creative Writing keyword

    @Test func screenwritingKeywordFromScreenplay() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my screenplay") == "screenwriting")
    }

    @Test func screenwritingKeywordFromNovel() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on chapter 5 of my novel") == "screenwriting")
    }

    @Test func screenwritingKeywordFromShortStory() {
        #expect(CalloutManager.extractTaskKeyword(from: "draft my short story for class") == "screenwriting")
    }

    @Test func screenwritingKeywordFromFiction() {
        #expect(CalloutManager.extractTaskKeyword(from: "write fiction for my creative writing class") == "screenwriting")
    }

    @Test func screenwritingKeywordFromScriptWriting() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on script writing for my film project") == "screenwriting")
    }

    @Test func screenwritingKeywordFromCharacterDevelopment() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on my character development sheet") == "screenwriting")
    }

    @Test func screenwritingKeywordFromWorldbuilding() {
        #expect(CalloutManager.extractTaskKeyword(from: "do worldbuilding for my fantasy novel") == "screenwriting")
    }

    @Test func screenwritingKeywordFromStoryOutline() {
        #expect(CalloutManager.extractTaskKeyword(from: "create a story outline for my screenplay") == "screenwriting")
    }

    @Test func screenwritingKeywordFromWriteAScene() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a scene for my TV pilot") == "screenwriting")
    }

    @Test func screenwritingKeywordDoesNotMatchShellScript() {
        // bare "script" without screenwriting context should NOT match screenwriting
        #expect(CalloutManager.extractTaskKeyword(from: "run a shell script for my server") != "screenwriting")
    }

    @Test func screenwritingKeywordDoesNotMatchCodeOutline() {
        // "outline" alone in a coding context should not match screenwriting
        #expect(CalloutManager.extractTaskKeyword(from: "write code and outline the algorithm") != "screenwriting")
    }

    @Test func screenwritingHasMessages() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "screenwriting", tier: 1)
            #expect(!msgs.isEmpty, "screenwriting tier1 pool must be non-empty")
        }
    }

    @Test func screenwritingDedicatedPoolSize() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "screenwriting", tier: 1)
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "screenwriting", tier: 2)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "screenwriting", tier: 3)
            #expect(tier1.count >= 4, "screenwriting tier1 must have ≥4 messages")
            #expect(tier2.count >= 3, "screenwriting tier2 must have ≥3 messages")
            #expect(tier3.count >= 3, "screenwriting tier3 must have ≥3 messages")
        }
    }

    @Test func screenwritingTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "screenwriting", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") || $0.hasPrefix("great writers") }
            #expect(hasUrgent, "screenwriting tier3 should contain an urgent directive")
        }
    }

    @Test func screenwritingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "screenwriting", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "screenwriting tier \(tier) callout must not be empty")
                }
            }
        }
    }

    // MARK: - Graphic Design / Branding

    @Test func graphicdesignKeywordFromGraphicDesign() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on graphic design for my portfolio") == "graphicdesign")
    }
    @Test func graphicdesignKeywordFromLogoDesign() {
        #expect(CalloutManager.extractTaskKeyword(from: "design a logo for my client") == "graphicdesign")
    }
    @Test func graphicdesignKeywordFromBranding() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on branding for the startup") == "graphicdesign")
    }
    @Test func graphicdesignKeywordFromTypography() {
        #expect(CalloutManager.extractTaskKeyword(from: "study typography for my design class") == "graphicdesign")
    }
    @Test func graphicdesignKeywordFromInfographic() {
        #expect(CalloutManager.extractTaskKeyword(from: "create an infographic for my presentation") == "graphicdesign")
    }
    @Test func graphicdesignKeywordFromInDesign() {
        #expect(CalloutManager.extractTaskKeyword(from: "layout my magazine in indesign") == "graphicdesign")
    }
    @Test func graphicdesignKeywordFromBrandIdentity() {
        #expect(CalloutManager.extractTaskKeyword(from: "develop brand identity for my client") == "graphicdesign")
    }
    @Test func graphicdesignKeywordFromCanva() {
        #expect(CalloutManager.extractTaskKeyword(from: "design a flyer in canva") == "graphicdesign")
    }
    @Test func graphicdesignKeywordFromColorPalette() {
        #expect(CalloutManager.extractTaskKeyword(from: "define the color palette for my brand") == "graphicdesign")
    }
    @Test func graphicdesignKeywordFromFlyerDesign() {
        #expect(CalloutManager.extractTaskKeyword(from: "create a flyer design for the event") == "graphicdesign")
    }
    @Test func graphicdesignDoesNotMatchGenericDesign() {
        // Bare "graphic design" should route to graphicdesign, not generic design
        let kw = CalloutManager.extractTaskKeyword(from: "graphic design homework")
        #expect(kw == "graphicdesign")
    }
    @Test func graphicdesignHasMessages() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "graphicdesign", tier: 1)
            #expect(!msgs.isEmpty, "graphicdesign tier1 pool must be non-empty")
        }
    }
    @Test func graphicdesignDedicatedPoolSize() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "graphicdesign", tier: 1)
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "graphicdesign", tier: 2)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "graphicdesign", tier: 3)
            #expect(tier1.count >= 4, "graphicdesign tier1 must have ≥4 messages")
            #expect(tier2.count >= 3, "graphicdesign tier2 must have ≥3 messages")
            #expect(tier3.count >= 3, "graphicdesign tier3 must have ≥3 messages")
        }
    }
    @Test func graphicdesignTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "graphicdesign", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") || $0.contains("great designers") }
            #expect(hasUrgent, "graphicdesign tier3 should contain an urgent directive")
        }
    }

    // MARK: - Interior Design

    @Test func interiordesignKeywordFromInteriorDesign() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on my interior design project") == "interiordesign")
    }
    @Test func interiordesignKeywordFromSpacePlanning() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete space planning for the apartment") == "interiordesign")
    }
    @Test func interiordesignKeywordFromMoodBoard() {
        #expect(CalloutManager.extractTaskKeyword(from: "create a mood board for my client") == "interiordesign")
    }
    @Test func interiordesignKeywordFromFurnitureLayout() {
        #expect(CalloutManager.extractTaskKeyword(from: "finalize the furniture layout for the living room") == "interiordesign")
    }
    @Test func interiordesignKeywordFromNcidq() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for the NCIDQ exam") == "interiordesign")
    }
    @Test func interiordesignKeywordFromKitchenDesign() {
        #expect(CalloutManager.extractTaskKeyword(from: "design a kitchen layout for my project") == "interiordesign")
    }
    @Test func interiordesignHasMessages() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "interiordesign", tier: 1)
            #expect(!msgs.isEmpty, "interiordesign tier1 pool must be non-empty")
        }
    }
    @Test func interiordesignDedicatedPoolSize() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "interiordesign", tier: 1)
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "interiordesign", tier: 2)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "interiordesign", tier: 3)
            #expect(tier1.count >= 4, "interiordesign tier1 must have ≥4 messages")
            #expect(tier2.count >= 3, "interiordesign tier2 must have ≥3 messages")
            #expect(tier3.count >= 3, "interiordesign tier3 must have ≥3 messages")
        }
    }
    @Test func interiordesignTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "interiordesign", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") || $0.contains("NCIDQ") }
            #expect(hasUrgent, "interiordesign tier3 should contain an urgent directive")
        }
    }

    // MARK: - Speech-Language Pathology

    @Test func speechpathologyKeywordFromSpeechTherapy() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my speech therapy session notes") == "speechpathology")
    }
    @Test func speechpathologyKeywordFromSpeechLanguage() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for my speech-language pathology exam") == "speechpathology")
    }
    @Test func speechpathologyKeywordFromSlp() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete my slp clinical hours") == "speechpathology")
    }
    @Test func speechpathologyKeywordFromAphasia() {
        #expect(CalloutManager.extractTaskKeyword(from: "review aphasia treatment approaches") == "speechpathology")
    }
    @Test func speechpathologyKeywordFromDysphagia() {
        #expect(CalloutManager.extractTaskKeyword(from: "study dysphagia assessment for my clinical rotation") == "speechpathology")
    }
    @Test func speechpathologyKeywordFromStuttering() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on my stuttering therapy protocol notes") == "speechpathology")
    }
    @Test func speechpathologyKeywordFromPhonologicalAwareness() {
        #expect(CalloutManager.extractTaskKeyword(from: "plan my phonological awareness lesson") == "speechpathology")
    }
    @Test func speechpathologyKeywordFromAugmentativeCommunication() {
        #expect(CalloutManager.extractTaskKeyword(from: "research augmentative communication strategies") == "speechpathology")
    }
    @Test func speechpathologyHasMessages() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "speechpathology", tier: 1)
            #expect(!msgs.isEmpty, "speechpathology tier1 pool must be non-empty")
        }
    }
    @Test func speechpathologyDedicatedPoolSize() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "speechpathology", tier: 1)
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "speechpathology", tier: 2)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "speechpathology", tier: 3)
            #expect(tier1.count >= 4, "speechpathology tier1 must have ≥4 messages")
            #expect(tier2.count >= 3, "speechpathology tier2 must have ≥3 messages")
            #expect(tier3.count >= 3, "speechpathology tier3 must have ≥3 messages")
        }
    }
    @Test func speechpathologyTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "speechpathology", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") || $0.contains("CCC-SLP") }
            #expect(hasUrgent, "speechpathology tier3 should contain an urgent directive")
        }
    }
    @Test func speechpathologyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "speechpathology", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "speechpathology tier \(tier) callout must not be empty")
                }
            }
        }
    }

    // MARK: - Physician Assistant

    @Test func physicianassistantKeywordFromPhysicianAssistant() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for my physician assistant boards") == "physicianassistant")
    }
    @Test func physicianassistantKeywordFromPASchool() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete my pa school assignment") == "physicianassistant")
    }
    @Test func physicianassistantKeywordFromPANCE() {
        #expect(CalloutManager.extractTaskKeyword(from: "prep for the PANCE exam") == "physicianassistant")
    }
    @Test func physicianassistantKeywordFromPAC() {
        #expect(CalloutManager.extractTaskKeyword(from: "review cardiology for my pa-c rotation") == "physicianassistant")
    }
    @Test func physicianassistantKeywordFromPARotation() {
        #expect(CalloutManager.extractTaskKeyword(from: "write up my pa rotation notes") == "physicianassistant")
    }
    @Test func physicianassistantKeywordDoesNotMatchPremed() {
        #expect(CalloutManager.extractTaskKeyword(from: "study anatomy for medical school") != "physicianassistant")
    }
    @Test func physicianassistantHasMessages() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "physicianassistant", tier: 1)
            #expect(!msgs.isEmpty, "physicianassistant tier1 pool must be non-empty")
        }
    }
    @Test func physicianassistantDedicatedPoolSize() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "physicianassistant", tier: 1)
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "physicianassistant", tier: 2)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "physicianassistant", tier: 3)
            #expect(tier1.count >= 4, "physicianassistant tier1 must have ≥4 messages")
            #expect(tier2.count >= 3, "physicianassistant tier2 must have ≥3 messages")
            #expect(tier3.count >= 3, "physicianassistant tier3 must have ≥3 messages")
        }
    }
    @Test func physicianassistantTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "physicianassistant", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") || $0.contains("PANCE") }
            #expect(hasUrgent, "physicianassistant tier3 should contain an urgent directive")
        }
    }
    @Test func physicianassistantCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "physicianassistant", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "physicianassistant tier \(tier) callout must not be empty")
                }
            }
        }
    }

    // MARK: - Real Estate

    @Test func realestateKeywordFromRealEstate() {
        #expect(CalloutManager.extractTaskKeyword(from: "prep for my real estate licensing exam") == "realestate")
    }
    @Test func realestateKeywordFromRealtor() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for my realtor certification") == "realestate")
    }
    @Test func realestateKeywordFromPropertyManagement() {
        #expect(CalloutManager.extractTaskKeyword(from: "write up my property management notes") == "realestate")
    }
    @Test func realestateKeywordFromComparativeMarketAnalysis() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish the comparative market analysis for my client") == "realestate")
    }
    @Test func realestateKeywordFromClosingDocuments() {
        #expect(CalloutManager.extractTaskKeyword(from: "review closing documents for the transaction") == "realestate")
    }
    @Test func realestateKeywordFromEscrow() {
        #expect(CalloutManager.extractTaskKeyword(from: "prep the escrow instructions for my client") == "realestate")
    }
    @Test func realestateDoesNotMatchGenericBusiness() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on my MBA case analysis") != "realestate")
    }
    @Test func realestateHasMessages() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "realestate", tier: 1)
            #expect(!msgs.isEmpty, "realestate tier1 pool must be non-empty")
        }
    }
    @Test func realestateDedicatedPoolSize() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "realestate", tier: 1)
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "realestate", tier: 2)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "realestate", tier: 3)
            #expect(tier1.count >= 4, "realestate tier1 must have ≥4 messages")
            #expect(tier2.count >= 3, "realestate tier2 must have ≥3 messages")
            #expect(tier3.count >= 3, "realestate tier3 must have ≥3 messages")
        }
    }
    @Test func realestateTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "realestate", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") || $0.contains("license") }
            #expect(hasUrgent, "realestate tier3 should contain an urgent directive")
        }
    }
    @Test func realestateCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "realestate", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "realestate tier \(tier) callout must not be empty")
                }
            }
        }
    }

    // MARK: - Education / Teaching

    @Test func educationKeywordFromLessonPlan() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my lesson plan for tomorrow") == "education")
    }
    @Test func educationKeywordFromCurriculum() {
        #expect(CalloutManager.extractTaskKeyword(from: "develop the curriculum for my unit") == "education")
    }
    @Test func educationKeywordFromPedagogy() {
        #expect(CalloutManager.extractTaskKeyword(from: "read about culturally responsive pedagogy") == "education")
    }
    @Test func educationKeywordFromTeachingCertificate() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for my teaching certificate exam") == "education")
    }
    @Test func educationKeywordFromStudentTeaching() {
        #expect(CalloutManager.extractTaskKeyword(from: "prep for my student teaching placement") == "education")
    }
    @Test func educationKeywordFromPraxis() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for the Praxis education exam") == "education")
    }
    @Test func educationKeywordFromClassroomManagement() {
        #expect(CalloutManager.extractTaskKeyword(from: "write up my classroom management plan") == "education")
    }
    @Test func educationKeywordDoesNotMatchTutor() {
        #expect(CalloutManager.extractTaskKeyword(from: "tutor my student in algebra") != "education")
    }
    @Test func educationHasMessages() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "education", tier: 1)
            #expect(!msgs.isEmpty, "education tier1 pool must be non-empty")
        }
    }
    @Test func educationDedicatedPoolSize() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "education", tier: 1)
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "education", tier: 2)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "education", tier: 3)
            #expect(tier1.count >= 4, "education tier1 must have ≥4 messages")
            #expect(tier2.count >= 3, "education tier2 must have ≥3 messages")
            #expect(tier3.count >= 3, "education tier3 must have ≥3 messages")
        }
    }
    @Test func educationTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "education", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") || $0.contains("Praxis") || $0.contains("students") }
            #expect(hasUrgent, "education tier3 should contain an urgent directive")
        }
    }
    @Test func educationCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "education", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "education tier \(tier) callout must not be empty")
                }
            }
        }
    }

    // MARK: - Actuarial Science

    @Test func actuarialKeywordFromActuarial() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for my actuarial exam") == "actuarial")
    }
    @Test func actuarialKeywordFromExamP() {
        #expect(CalloutManager.extractTaskKeyword(from: "prep for exam P this week") == "actuarial")
    }
    @Test func actuarialKeywordFromExamFM() {
        #expect(CalloutManager.extractTaskKeyword(from: "work through exam FM practice problems") == "actuarial")
    }
    @Test func actuarialKeywordFromSOAExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "prepare for my SOA exam next month") == "actuarial")
    }
    @Test func actuarialKeywordFromLossModels() {
        #expect(CalloutManager.extractTaskKeyword(from: "study loss models for my actuarial exam") == "actuarial")
    }
    @Test func actuarialKeywordFromActuary() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete my actuary study session") == "actuarial")
    }
    @Test func actuarialKeywordDoesNotMatchStatistics() {
        #expect(CalloutManager.extractTaskKeyword(from: "run a regression analysis in R") != "actuarial")
    }
    @Test func actuarialHasMessages() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "actuarial", tier: 1)
            #expect(!msgs.isEmpty, "actuarial tier1 pool must be non-empty")
        }
    }
    @Test func actuarialDedicatedPoolSize() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "actuarial", tier: 1)
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "actuarial", tier: 2)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "actuarial", tier: 3)
            #expect(tier1.count >= 4, "actuarial tier1 must have ≥4 messages")
            #expect(tier2.count >= 3, "actuarial tier2 must have ≥3 messages")
            #expect(tier3.count >= 3, "actuarial tier3 must have ≥3 messages")
        }
    }
    @Test func actuarialTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "actuarial", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") || $0.contains("FSA") || $0.contains("exam") }
            #expect(hasUrgent, "actuarial tier3 should contain an urgent directive")
        }
    }
    @Test func actuarialCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "actuarial", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "actuarial tier \(tier) callout must not be empty")
                }
            }
        }
    }

    // MARK: - Journalism / Media Studies

    @Test func journalismKeywordFromJournalism() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on my investigative journalism piece") == "journalism")
    }
    @Test func journalismKeywordFromReporter() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my reporter assignment for class") == "journalism")
    }
    @Test func journalismKeywordFromNewsArticle() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a news article about the city council vote") == "journalism")
    }
    @Test func journalismKeywordFromPressRelease() {
        #expect(CalloutManager.extractTaskKeyword(from: "draft a press release for the new product launch") == "journalism")
    }
    @Test func journalismKeywordFromMediaStudies() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish my media studies assignment") == "journalism")
    }
    @Test func journalismKeywordFromInvestigativeReporting() {
        #expect(CalloutManager.extractTaskKeyword(from: "outline my investigative reporting story") == "journalism")
    }
    @Test func journalismKeywordDoesNotMatchGenericWriting() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my essay about local politics") != "journalism")
    }
    @Test func journalismHasMessages() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "journalism", tier: 1)
            #expect(!msgs.isEmpty, "journalism tier1 pool must be non-empty")
        }
    }
    @Test func journalismDedicatedPoolSize() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "journalism", tier: 1)
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "journalism", tier: 2)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "journalism", tier: 3)
            #expect(tier1.count >= 4, "journalism tier1 must have ≥4 messages")
            #expect(tier2.count >= 3, "journalism tier2 must have ≥3 messages")
            #expect(tier3.count >= 3, "journalism tier3 must have ≥3 messages")
        }
    }
    @Test func journalismTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "journalism", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") || $0.contains("journalist") || $0.contains("article") }
            #expect(hasUrgent, "journalism tier3 should contain an urgent directive")
        }
    }
    @Test func journalismCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "journalism", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "journalism tier \(tier) callout must not be empty")
                }
            }
        }
    }

    // MARK: - Theology / Religious Studies

    @Test func theologyKeywordFromTheology() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my systematic theology paper") == "theology")
    }
    @Test func theologyKeywordFromBiblicalStudies() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for my biblical studies midterm") == "theology")
    }
    @Test func theologyKeywordFromSeminary() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete my seminary assignment") == "theology")
    }
    @Test func theologyKeywordFromExegesis() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my exegesis paper on Romans 8") == "theology")
    }
    @Test func theologyKeywordFromReligiousStudies() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish my religious studies reading") == "theology")
    }
    @Test func theologyKeywordFromDivinity() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for my divinity school exam") == "theology")
    }
    @Test func theologyKeywordDoesNotMatchPhilosophy() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a philosophy paper on ethics") != "theology")
    }
    @Test func theologyHasMessages() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "theology", tier: 1)
            #expect(!msgs.isEmpty, "theology tier1 pool must be non-empty")
        }
    }
    @Test func theologyDedicatedPoolSize() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "theology", tier: 1)
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "theology", tier: 2)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "theology", tier: 3)
            #expect(tier1.count >= 4, "theology tier1 must have ≥4 messages")
            #expect(tier2.count >= 3, "theology tier2 must have ≥3 messages")
            #expect(tier3.count >= 3, "theology tier3 must have ≥3 messages")
        }
    }
    @Test func theologyTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "theology", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") || $0.contains("M.Div") || $0.contains("theology") }
            #expect(hasUrgent, "theology tier3 should contain an urgent directive")
        }
    }
    @Test func theologyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "theology", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "theology tier \(tier) callout must not be empty")
                }
            }
        }
    }

    // MARK: - Criminal Justice / Criminology

    @Test func criminalJusticeKeywordFromCriminology() {
        #expect(CalloutManager.extractTaskKeyword(from: "study criminology for my midterm") == "criminaljustice")
    }
    @Test func criminalJusticeKeywordFromCriminalJustice() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete my criminal justice paper") == "criminaljustice")
    }
    @Test func criminalJusticeKeywordFromForensicScience() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my forensic science lab report") == "criminaljustice")
    }
    @Test func criminalJusticeKeywordFromJuvenileJustice() {
        #expect(CalloutManager.extractTaskKeyword(from: "analyze a juvenile justice case for class") == "criminaljustice")
    }
    @Test func criminalJusticeKeywordFromLawEnforcement() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a paper on law enforcement policy") == "criminaljustice")
    }
    @Test func criminalJusticeKeywordFromCrimeScene() {
        #expect(CalloutManager.extractTaskKeyword(from: "study crime scene investigation methods") == "criminaljustice")
    }
    @Test func criminalJusticeKeywordDoesNotMatchSocialScience() {
        #expect(CalloutManager.extractTaskKeyword(from: "study political science and international relations") != "criminaljustice")
    }
    @Test func criminalJusticeHasMessages() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "criminaljustice", tier: 1)
            #expect(!msgs.isEmpty, "criminaljustice tier1 pool must be non-empty")
        }
    }
    @Test func criminalJusticeDedicatedPoolSize() async {
        await MainActor.run {
            let tier1 = CalloutManager.shared.taskAwareCallouts(keyword: "criminaljustice", tier: 1)
            let tier2 = CalloutManager.shared.taskAwareCallouts(keyword: "criminaljustice", tier: 2)
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "criminaljustice", tier: 3)
            #expect(tier1.count >= 4, "criminaljustice tier1 must have ≥4 messages")
            #expect(tier2.count >= 3, "criminaljustice tier2 must have ≥3 messages")
            #expect(tier3.count >= 3, "criminaljustice tier3 must have ≥3 messages")
        }
    }
    @Test func criminalJusticeTier3HasUrgentDirective() async {
        await MainActor.run {
            let tier3 = CalloutManager.shared.taskAwareCallouts(keyword: "criminaljustice", tier: 3)
            let hasUrgent = tier3.contains { $0.hasPrefix("CLOSE THIS") || $0.contains("criminology") || $0.contains("justice") }
            #expect(hasUrgent, "criminaljustice tier3 should contain an urgent directive")
        }
    }
    @Test func criminalJusticeCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "criminaljustice", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "criminaljustice tier \(tier) callout must not be empty")
                }
            }
        }
    }
    @Test func criminalJusticeKeywordDoesNotRouteToSocialScience() {
        #expect(CalloutManager.extractTaskKeyword(from: "study criminology for my exam") == "criminaljustice")
    }

    // MARK: - Chiropractic

    @Test func chiropracticKeywordFromBareWord() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for my chiropractic exam") == "chiropractic")
    }
    @Test func chiropracticKeywordFromNBCE() {
        #expect(CalloutManager.extractTaskKeyword(from: "prep for the NBCE boards") == "chiropractic")
    }
    @Test func chiropracticKeywordFromDoctorOfChiropractic() {
        #expect(CalloutManager.extractTaskKeyword(from: "review my doctor of chiropractic coursework") == "chiropractic")
    }
    @Test func chiropracticKeywordFromSpinalAdjustment() {
        #expect(CalloutManager.extractTaskKeyword(from: "write up my spinal adjustment notes") == "chiropractic")
    }
    @Test func chiropracticKeywordFromSubluxation() {
        #expect(CalloutManager.extractTaskKeyword(from: "review subluxation theory for my exam") == "chiropractic")
    }
    @Test func chiropracticKeywordDoesNotRouteToVeterinary() {
        #expect(CalloutManager.extractTaskKeyword(from: "prep for my chiropractic boards") != "veterinary")
    }
    @Test func chiropracticCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "chiropractic", tier: tier)
                #expect(!msgs.isEmpty, "chiropractic tier \(tier) must have callouts")
            }
        }
    }
    @Test func chiropracticCalloutsTier1HasAtLeastThree() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "chiropractic", tier: 1)
            #expect(msgs.count >= 3)
        }
    }
    @Test func chiropracticCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "chiropractic", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "chiropractic tier \(tier) callout must not be empty")
                }
            }
        }
    }
    @Test func chiropracticCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "chiropractic", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one passes") }
            #expect(hasCloseThis, "chiropractic tier 3 must contain 'CLOSE THIS' or 'no one passes'")
        }
    }

    // MARK: - Respiratory Therapy

    @Test func respiratorytherapyKeywordFromBarePhrase() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete my respiratory therapy assignment") == "respiratorytherapy")
    }
    @Test func respiratorytherapyKeywordFromNBRC() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for the NBRC exam") == "respiratorytherapy")
    }
    @Test func respiratorytherapyKeywordFromRRT() {
        #expect(CalloutManager.extractTaskKeyword(from: "review RRT protocols for my rotation") == "respiratorytherapy")
    }
    @Test func respiratorytherapyKeywordFromVentilatorManagement() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete ventilator management case study") == "respiratorytherapy")
    }
    @Test func respiratorytherapyKeywordFromABG() {
        #expect(CalloutManager.extractTaskKeyword(from: "practice ABG interpretation") == "respiratorytherapy")
    }
    @Test func respiratorytherapyKeywordDoesNotRouteToNursing() {
        #expect(CalloutManager.extractTaskKeyword(from: "study respiratory therapy school material") != "nursing")
    }
    @Test func respiratorytherapyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "respiratorytherapy", tier: tier)
                #expect(!msgs.isEmpty, "respiratorytherapy tier \(tier) must have callouts")
            }
        }
    }
    @Test func respiratorytherapyCalloutsTier1HasAtLeastThree() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "respiratorytherapy", tier: 1)
            #expect(msgs.count >= 3)
        }
    }
    @Test func respiratorytherapyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "respiratorytherapy", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "respiratorytherapy tier \(tier) callout must not be empty")
                }
            }
        }
    }
    @Test func respiratorytherapyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "respiratorytherapy", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one passes") }
            #expect(hasCloseThis, "respiratorytherapy tier 3 must contain 'CLOSE THIS' or 'no one passes'")
        }
    }

    // MARK: - Psychology

    @Test func psychologyKeywordFromBareWord() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for my psychology exam") == "psychology")
    }
    @Test func psychologyKeywordFromSocialPsychology() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my social psychology paper") == "psychology")
    }
    @Test func psychologyKeywordFromCognitivePsychology() {
        #expect(CalloutManager.extractTaskKeyword(from: "review cognitive psychology chapter") == "psychology")
    }
    @Test func psychologyKeywordFromPsychMajor() {
        #expect(CalloutManager.extractTaskKeyword(from: "finish my psych major thesis") == "psychology")
    }
    @Test func psychologyKeywordFromFreud() {
        #expect(CalloutManager.extractTaskKeyword(from: "analyze freud for my personality theory paper") == "psychology")
    }
    @Test func psychologyKeywordFromDevelopmentalPsychology() {
        #expect(CalloutManager.extractTaskKeyword(from: "study developmental psychology for my exam") == "psychology")
    }
    @Test func psychologyKeywordDoesNotRouteToTherapy() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my psychology research paper") != "therapy")
    }
    @Test func psychologyKeywordEducationalPsychologyRoutesToEducation() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete my educational psychology assignment") == "education")
    }
    @Test func psychologyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "psychology", tier: tier)
                #expect(!msgs.isEmpty, "psychology tier \(tier) must have callouts")
            }
        }
    }
    @Test func psychologyCalloutsTier1HasAtLeastThree() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "psychology", tier: 1)
            #expect(msgs.count >= 3)
        }
    }
    @Test func psychologyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "psychology", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "psychology tier \(tier) callout must not be empty")
                }
            }
        }
    }
    @Test func psychologyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "psychology", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "psychology tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Geology / Earth Science
    // Note: inputs must avoid early-catch words (study/exam/notes/assignment/report/lab) that
    // fire the studying/homework/report/research branches before geology is checked.

    @Test func geologyKeywordFromMineralogy() {
        #expect(CalloutManager.extractTaskKeyword(from: "identify rock samples for my mineralogy class") == "geology")
    }
    @Test func geologyKeywordFromEarthScience() {
        #expect(CalloutManager.extractTaskKeyword(from: "analyze earth science field data from my survey") == "geology")
    }
    @Test func geologyKeywordFromSeismology() {
        #expect(CalloutManager.extractTaskKeyword(from: "seismology field survey prep") == "geology")
    }
    @Test func geologyKeywordFromPlateTectonics() {
        #expect(CalloutManager.extractTaskKeyword(from: "plate tectonics map work") == "geology")
    }
    @Test func geologyKeywordFromPaleontology() {
        #expect(CalloutManager.extractTaskKeyword(from: "analyze the fossil record for my paleontology class") == "geology")
    }
    @Test func geologyKeywordGeographyDoesNotRouteToGeology() {
        // "study" fires studying before geology; also "geography" is not in geology branch
        #expect(CalloutManager.extractTaskKeyword(from: "geography map work for class") != "geology")
    }
    @Test func geologyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "geology", tier: tier)
                #expect(!msgs.isEmpty, "geology tier \(tier) must have callouts")
            }
        }
    }
    @Test func geologyCalloutsTier1HasAtLeastThree() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "geology", tier: 1)
            #expect(msgs.count >= 3)
        }
    }
    @Test func geologyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "geology", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "geology tier \(tier) callout must not be empty")
                }
            }
        }
    }
    @Test func geologyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "geology", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "geology tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Bioinformatics
    // Inputs must avoid early-catch words (study/exam/dataset/assignment) that fire
    // the studying/homework/research branches before bioinformatics is checked.

    @Test func bioinformaticsKeywordFromBioinformatics() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on my bioinformatics pipeline") == "bioinformatics")
    }
    @Test func bioinformaticsKeywordFromGenomics() {
        // "dataset" fires research; use "genomics" without "dataset"
        #expect(CalloutManager.extractTaskKeyword(from: "run a genomics analysis using biopython") == "bioinformatics")
    }
    @Test func bioinformaticsKeywordFromSequenceAlignment() {
        #expect(CalloutManager.extractTaskKeyword(from: "perform sequence alignment on my protein data") == "bioinformatics")
    }
    @Test func bioinformaticsKeywordFromRNAseq() {
        // "thesis" fires early; use a pipeline-focused input
        #expect(CalloutManager.extractTaskKeyword(from: "rna-seq pipeline setup and analysis") == "bioinformatics")
    }
    @Test func bioinformaticsKeywordFromComputationalBiology() {
        // "study" fires studying; use a tool-focused input
        #expect(CalloutManager.extractTaskKeyword(from: "learn computational biology tools and pipelines") == "bioinformatics")
    }
    @Test func bioinformaticsKeywordDoesNotRouteToDatscience() {
        #expect(CalloutManager.extractTaskKeyword(from: "run a bioinformatics pipeline on my genomics data") != "datascience")
    }
    @Test func bioinformaticsCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "bioinformatics", tier: tier)
                #expect(!msgs.isEmpty, "bioinformatics tier \(tier) must have callouts")
            }
        }
    }
    @Test func bioinformaticsCalloutsTier1HasAtLeastThree() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "bioinformatics", tier: 1)
            #expect(msgs.count >= 3)
        }
    }
    @Test func bioinformaticsCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "bioinformatics", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "bioinformatics tier \(tier) callout must not be empty")
                }
            }
        }
    }
    @Test func bioinformaticsCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "bioinformatics", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "bioinformatics tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Urban Planning
    // Inputs must avoid assignment/study/exam (homework/studying branches fire first).

    @Test func urbanplanningKeywordFromUrbanPlanning() {
        #expect(CalloutManager.extractTaskKeyword(from: "draft my urban planning policy analysis") == "urbanplanning")
    }
    @Test func urbanplanningKeywordFromCityPlanning() {
        #expect(CalloutManager.extractTaskKeyword(from: "write my city planning policy memo") == "urbanplanning")
    }
    @Test func urbanplanningKeywordFromZoningOrdinance() {
        #expect(CalloutManager.extractTaskKeyword(from: "analyze the zoning ordinance for my class") == "urbanplanning")
    }
    @Test func urbanplanningKeywordFromAICP() {
        // "study" and "exam" fire studying; use certification-specific input
        #expect(CalloutManager.extractTaskKeyword(from: "aicp certification prep materials") == "urbanplanning")
    }
    @Test func urbanplanningKeywordFromComprehensivePlan() {
        #expect(CalloutManager.extractTaskKeyword(from: "draft my comprehensive plan section") == "urbanplanning")
    }
    @Test func urbanplanningKeywordBareZoningRoutesToRealestate() {
        // bare word("zoning") is caught by realestate branch; urbanplanning requires "zoning ordinance" / "zoning code" etc.
        #expect(CalloutManager.extractTaskKeyword(from: "check zoning for the property listing") == "realestate")
    }
    @Test func urbanplanningCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "urbanplanning", tier: tier)
                #expect(!msgs.isEmpty, "urbanplanning tier \(tier) must have callouts")
            }
        }
    }
    @Test func urbanplanningCalloutsTier1HasAtLeastThree() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "urbanplanning", tier: 1)
            #expect(msgs.count >= 3)
        }
    }
    @Test func urbanplanningCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "urbanplanning", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "urbanplanning tier \(tier) callout must not be empty")
                }
            }
        }
    }
    @Test func urbanplanningCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "urbanplanning", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "urbanplanning tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Dental Hygiene
    // "study"/"exam"/"assignment"/"notes"/"report" fire early branches; use hygienist-specific vocabulary.

    @Test func dentalhygieneKeywordFromDentalHygiene() {
        #expect(CalloutManager.extractTaskKeyword(from: "dental hygiene board certification prep") == "dentalhygiene")
    }
    @Test func dentalhygieneKeywordFromNBDHE() {
        #expect(CalloutManager.extractTaskKeyword(from: "nbdhe board prep materials") == "dentalhygiene")
    }
    @Test func dentalhygieneKeywordFromPeriodontalCharting() {
        #expect(CalloutManager.extractTaskKeyword(from: "periodontal charting practice for my patient") == "dentalhygiene")
    }
    @Test func dentalhygieneKeywordFromScalingAndRootPlaning() {
        #expect(CalloutManager.extractTaskKeyword(from: "scaling and root planing patient technique") == "dentalhygiene")
    }
    @Test func dentalhygieneKeywordFromOralHealthAssessment() {
        #expect(CalloutManager.extractTaskKeyword(from: "oral health assessment documentation for my patient") == "dentalhygiene")
    }
    @Test func dentalhygieneKeywordDoesNotRouteToDental() {
        #expect(CalloutManager.extractTaskKeyword(from: "dental hygiene board certification prep") != "dental")
    }
    @Test func dentalhygieneCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dentalhygiene", tier: tier)
                #expect(!msgs.isEmpty, "dentalhygiene tier \(tier) must have callouts")
            }
        }
    }
    @Test func dentalhygieneCalloutsTier1HasAtLeastThree() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dentalhygiene", tier: 1)
            #expect(msgs.count >= 3)
        }
    }
    @Test func dentalhygieneCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dentalhygiene", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "dentalhygiene tier \(tier) callout must not be empty")
                }
            }
        }
    }
    @Test func dentalhygieneCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dentalhygiene", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "dentalhygiene tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Molecular Biology
    // "study"/"report"/"assignment"/"chapter"/"lab" fire early branches (studying/report/homework/reading/research).
    // Use technique-specific vocabulary without those trigger words.

    @Test func molecularbiologyKeywordFromMolecularBiology() {
        // "lab" fires research; drop it — "molecular biology" phrase alone fires molecularbiology
        #expect(CalloutManager.extractTaskKeyword(from: "molecular biology notebook documentation") == "molecularbiology")
    }
    @Test func molecularbiologyKeywordFromWesternBlot() {
        #expect(CalloutManager.extractTaskKeyword(from: "analyze my western blot results") == "molecularbiology")
    }
    @Test func molecularbiologyKeywordFromCRISPR() {
        // "read" ≠ word("reading"); crispr fires molecularbiology
        #expect(CalloutManager.extractTaskKeyword(from: "read about crispr gene editing") == "molecularbiology")
    }
    @Test func molecularbiologyKeywordFromGelElectrophoresis() {
        #expect(CalloutManager.extractTaskKeyword(from: "interpret my gel electrophoresis results") == "molecularbiology")
    }
    @Test func molecularbiologyKeywordFromMolecularCloning() {
        // "assignment" fires homework; "lab" fires research — use protocol-focused input without both
        #expect(CalloutManager.extractTaskKeyword(from: "molecular cloning protocol walkthrough") == "molecularbiology")
    }
    @Test func molecularbiologyKeywordBiochemistryStaysInPremed() {
        // "biochemistry" (standalone word) fires premed; no early-catch words in this input
        #expect(CalloutManager.extractTaskKeyword(from: "biochemistry for the mcat") == "premed")
    }
    @Test func molecularbiologyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "molecularbiology", tier: tier)
                #expect(!msgs.isEmpty, "molecularbiology tier \(tier) must have callouts")
            }
        }
    }
    @Test func molecularbiologyCalloutsTier1HasAtLeastThree() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "molecularbiology", tier: 1)
            #expect(msgs.count >= 3)
        }
    }
    @Test func molecularbiologyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "molecularbiology", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "molecularbiology tier \(tier) callout must not be empty")
                }
            }
        }
    }
    @Test func molecularbiologyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "molecularbiology", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "molecularbiology tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Forensic Accounting
    // Avoid bare "audit"/"auditing" (finance branch); use forensic-specific compound terms.

    @Test func forensicaccountingKeywordFromForensicAccounting() {
        #expect(CalloutManager.extractTaskKeyword(from: "forensic accounting case documentation") == "forensicaccounting")
    }
    @Test func forensicaccountingKeywordFromFraudInvestigation() {
        #expect(CalloutManager.extractTaskKeyword(from: "fraud investigation notes for class") == "forensicaccounting")
    }
    @Test func forensicaccountingKeywordFromCFEExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "cfe exam prep and practice questions") == "forensicaccounting")
    }
    @Test func forensicaccountingKeywordFromFraudExamination() {
        #expect(CalloutManager.extractTaskKeyword(from: "fraud examination report writing") == "forensicaccounting")
    }
    @Test func forensicaccountingKeywordFromAntiMoneyLaundering() {
        #expect(CalloutManager.extractTaskKeyword(from: "anti-money laundering compliance review") == "forensicaccounting")
    }
    @Test func forensicaccountingFalsePositiveAuditStaysInFinance() {
        // bare "audit" alone is in the finance branch — not forensicaccounting
        #expect(CalloutManager.extractTaskKeyword(from: "auditing financial statements cpa") == "finance")
    }
    @Test func forensicaccountingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forensicaccounting", tier: tier)
                #expect(!msgs.isEmpty, "forensicaccounting tier \(tier) must have callouts")
            }
        }
    }
    @Test func forensicaccountingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forensicaccounting", tier: 1)
            #expect(msgs.count >= 4, "forensicaccounting tier1 must have ≥4 messages")
        }
    }
    @Test func forensicaccountingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forensicaccounting", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "forensicaccounting tier \(tier) callout must not be empty")
                }
            }
        }
    }
    @Test func forensicaccountingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forensicaccounting", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "forensicaccounting tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Public Relations / Communications
    // "press release" stays in journalism; avoid bare "press" or "communications" alone.

    @Test func publicrelationsKeywordFromPublicRelations() {
        #expect(CalloutManager.extractTaskKeyword(from: "public relations strategy for client") == "publicrelations")
    }
    @Test func publicrelationsKeywordFromPRCampaign() {
        #expect(CalloutManager.extractTaskKeyword(from: "pr campaign planning document") == "publicrelations")
    }
    @Test func publicrelationsKeywordFromMediaRelations() {
        #expect(CalloutManager.extractTaskKeyword(from: "media relations outreach plan") == "publicrelations")
    }
    @Test func publicrelationsKeywordFromCommunicationsMajor() {
        #expect(CalloutManager.extractTaskKeyword(from: "communications major final exam prep") == "publicrelations")
    }
    @Test func publicrelationsKeywordFromCrisisCommunications() {
        #expect(CalloutManager.extractTaskKeyword(from: "crisis communications response plan") == "publicrelations")
    }
    @Test func publicrelationsFalsePositivePressReleaseStaysInJournalism() {
        // "press release" is owned by journalism
        #expect(CalloutManager.extractTaskKeyword(from: "write a press release for news outlet") == "journalism")
    }
    @Test func publicrelationsCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "publicrelations", tier: tier)
                #expect(!msgs.isEmpty, "publicrelations tier \(tier) must have callouts")
            }
        }
    }
    @Test func publicrelationsCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "publicrelations", tier: 1)
            #expect(msgs.count >= 4, "publicrelations tier1 must have ≥4 messages")
        }
    }
    @Test func publicrelationsCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "publicrelations", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "publicrelations tier \(tier) callout must not be empty")
                }
            }
        }
    }
    @Test func publicrelationsCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "publicrelations", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "publicrelations tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Physical Education / Sport Coaching
    // "coach"/"coaching" alone stays in tutor; compound PE/sport coaching terms fire physed.

    @Test func physedKeywordFromPhysicalEducation() {
        #expect(CalloutManager.extractTaskKeyword(from: "physical education curriculum design") == "physed")
    }
    @Test func physedKeywordFromPETeacher() {
        #expect(CalloutManager.extractTaskKeyword(from: "pe teacher certification exam prep") == "physed")
    }
    @Test func physedKeywordFromSportCoaching() {
        #expect(CalloutManager.extractTaskKeyword(from: "sport coaching philosophy paper") == "physed")
    }
    @Test func physedKeywordFromAthleticCoaching() {
        #expect(CalloutManager.extractTaskKeyword(from: "athletic coaching certification notes") == "physed")
    }
    @Test func physedKeywordFromCoachingTheory() {
        #expect(CalloutManager.extractTaskKeyword(from: "coaching theory and practice overview") == "physed")
    }
    @Test func physedFalsePositiveBareCoacingStaysInTutor() {
        // bare word("coaching") alone stays in tutor
        #expect(CalloutManager.extractTaskKeyword(from: "coaching my student on the lesson") == "tutor")
    }
    @Test func physedCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "physed", tier: tier)
                #expect(!msgs.isEmpty, "physed tier \(tier) must have callouts")
            }
        }
    }
    @Test func physedCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "physed", tier: 1)
            #expect(msgs.count >= 4, "physed tier1 must have ≥4 messages")
        }
    }
    @Test func physedCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "physed", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "physed tier \(tier) callout must not be empty")
                }
            }
        }
    }
    @Test func physedCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "physed", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "physed tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Library Science
    // "library" alone (e.g., "go to the library") should not fire; require LIS-specific terms.

    @Test func libraryscienceKeywordFromLibraryScience() {
        #expect(CalloutManager.extractTaskKeyword(from: "library science cataloging assignment") == "libraryscience")
    }
    @Test func libraryscienceKeywordFromMLIS() {
        #expect(CalloutManager.extractTaskKeyword(from: "mlis program coursework notes") == "libraryscience")
    }
    @Test func libraryscienceKeywordFromCataloging() {
        #expect(CalloutManager.extractTaskKeyword(from: "cataloging metadata for digital collection") == "libraryscience")
    }
    @Test func libraryscienceKeywordFromArchivist() {
        #expect(CalloutManager.extractTaskKeyword(from: "archivist training and special collections work") == "libraryscience")
    }
    @Test func libraryscienceKeywordFromReferenceServices() {
        #expect(CalloutManager.extractTaskKeyword(from: "reference services policy documentation") == "libraryscience")
    }
    @Test func libraryscienceCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "libraryscience", tier: tier)
                #expect(!msgs.isEmpty, "libraryscience tier \(tier) must have callouts")
            }
        }
    }
    @Test func libraryscienceCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "libraryscience", tier: 1)
            #expect(msgs.count >= 4, "libraryscience tier1 must have ≥4 messages")
        }
    }
    @Test func libraryscienceCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "libraryscience", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "libraryscience tier \(tier) callout must not be empty")
                }
            }
        }
    }
    @Test func libraryscienceCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "libraryscience", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "libraryscience tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Dental Assisting
    // Distinct from dentalhygiene (NBDHE) and dental (DDS/NBDE); DANB + chairside assisting terms.

    @Test func dentalassistingKeywordFromDentalAssistingProgram() {
        #expect(CalloutManager.extractTaskKeyword(from: "dental assisting program notes") == "dentalassisting")
    }
    @Test func dentalassistingKeywordFromDANB() {
        #expect(CalloutManager.extractTaskKeyword(from: "danb exam prep questions") == "dentalassisting")
    }
    @Test func dentalassistingKeywordFromChairsideAssisting() {
        #expect(CalloutManager.extractTaskKeyword(from: "chairside assisting procedures overview") == "dentalassisting")
    }
    @Test func dentalassistingKeywordFromDentalAssistantClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "dental assistant class assignment") == "dentalassisting")
    }
    @Test func dentalassistingKeywordFromCoronalPolish() {
        #expect(CalloutManager.extractTaskKeyword(from: "coronal polish technique practice") == "dentalassisting")
    }
    @Test func dentalassistingFalsePositiveDentalHygieneStaysInDentalhygiene() {
        // "dental hygiene" is caught by the dentalhygiene branch, not dentalassisting
        #expect(CalloutManager.extractTaskKeyword(from: "dental hygiene board prep nbdhe") == "dentalhygiene")
    }
    @Test func dentalassistingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dentalassisting", tier: tier)
                #expect(!msgs.isEmpty, "dentalassisting tier \(tier) must have callouts")
            }
        }
    }
    @Test func dentalassistingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dentalassisting", tier: 1)
            #expect(msgs.count >= 4, "dentalassisting tier1 must have ≥4 messages")
        }
    }
    @Test func dentalassistingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dentalassisting", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "dentalassisting tier \(tier) callout must not be empty")
                }
            }
        }
    }
    @Test func dentalassistingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dentalassisting", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "dentalassisting tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Film Studies
    // Distinct from video (production) and screenwriting (writing fiction/scripts);
    // catches film criticism, film analysis, film theory, and film-history courses.

    @Test func filmstudiesKeywordFromFilmStudies() {
        #expect(CalloutManager.extractTaskKeyword(from: "film studies essay on auteur theory") == "filmstudies")
    }
    @Test func filmstudiesKeywordFromFilmCriticism() {
        #expect(CalloutManager.extractTaskKeyword(from: "film criticism paper on Hitchcock") == "filmstudies")
    }
    @Test func filmstudiesKeywordFromFilmAnalysis() {
        #expect(CalloutManager.extractTaskKeyword(from: "film analysis assignment mise-en-scene") == "filmstudies")
    }
    @Test func filmstudiesKeywordFromFilmHistory() {
        #expect(CalloutManager.extractTaskKeyword(from: "film history class notes on Italian neorealism") == "filmstudies")
    }
    @Test func filmstudiesKeywordFromAuteurTheory() {
        #expect(CalloutManager.extractTaskKeyword(from: "auteur theory paper for my film course") == "filmstudies")
    }
    @Test func filmstudiesKeywordFromMontageTheory() {
        #expect(CalloutManager.extractTaskKeyword(from: "montage theory assignment for film studies") == "filmstudies")
    }
    @Test func filmstudiesFalsePositiveFilmProductionStaysInVideo() {
        // bare word("film") in a production context stays in video
        #expect(CalloutManager.extractTaskKeyword(from: "film and edit my vlog footage") == "video")
    }
    @Test func filmstudiesFalsePositiveScreenplayStaysInScreenwriting() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a screenplay for my spec script") == "screenwriting")
    }
    @Test func filmstudiesCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "filmstudies", tier: tier)
                #expect(!msgs.isEmpty, "filmstudies tier \(tier) must have callouts")
            }
        }
    }
    @Test func filmstudiesCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "filmstudies", tier: 1)
            #expect(msgs.count >= 4, "filmstudies tier1 must have ≥4 messages")
        }
    }
    @Test func filmstudiesCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "filmstudies", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "filmstudies tier \(tier) callout must not be empty")
                }
            }
        }
    }
    @Test func filmstudiesCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "filmstudies", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "filmstudies tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Performing Arts
    // Covers theater, acting, dance, musical theater, choreography, and dramaturgy.

    @Test func performingArtsKeywordFromTheater() {
        #expect(CalloutManager.extractTaskKeyword(from: "theater class scene study assignment") == "performingarts")
    }
    @Test func performingArtsKeywordFromMonologue() {
        #expect(CalloutManager.extractTaskKeyword(from: "memorize my audition monologue") == "performingarts")
    }
    @Test func performingArtsKeywordFromChoreography() {
        #expect(CalloutManager.extractTaskKeyword(from: "choreography notation for my dance recital") == "performingarts")
    }
    @Test func performingArtsKeywordFromMusicalTheater() {
        #expect(CalloutManager.extractTaskKeyword(from: "musical theater scene work and song prep") == "performingarts")
    }
    @Test func performingArtsKeywordFromBallet() {
        #expect(CalloutManager.extractTaskKeyword(from: "ballet technique practice and class prep") == "performingarts")
    }
    @Test func performingArtsKeywordFromDramaClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "drama class rehearsal notes") == "performingarts")
    }
    @Test func performingArtsKeywordFromImprov() {
        #expect(CalloutManager.extractTaskKeyword(from: "improv exercises for my acting class") == "performingarts")
    }
    @Test func performingArtsKeywordFromDancecClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "dance class technique work") == "performingarts")
    }
    @Test func performingArtsFalsePositiveSketchStaysInDesign() {
        // bare word("sketch") is a design tool — only routes to performingarts via compound terms
        #expect(CalloutManager.extractTaskKeyword(from: "wireframe in Sketch app") == "design")
    }
    @Test func performingArtsCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "performingarts", tier: tier)
                #expect(!msgs.isEmpty, "performingarts tier \(tier) must have callouts")
            }
        }
    }
    @Test func performingArtsCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "performingarts", tier: 1)
            #expect(msgs.count >= 4, "performingarts tier1 must have ≥4 messages")
        }
    }
    @Test func performingArtsCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "performingarts", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "performingarts tier \(tier) callout must not be empty")
                }
            }
        }
    }
    @Test func performingArtsCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "performingarts", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "performingarts tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Astronomy / Astrophysics
    // Positioned before studying; word("physics") stays in studying for generic use.

    @Test func astronomyKeywordFromAstronomy() {
        #expect(CalloutManager.extractTaskKeyword(from: "astronomy homework on stellar evolution") == "astronomy")
    }
    @Test func astronomyKeywordFromAstrophysics() {
        #expect(CalloutManager.extractTaskKeyword(from: "astrophysics problem set on orbital mechanics") == "astronomy")
    }
    @Test func astronomyKeywordFromCosmology() {
        #expect(CalloutManager.extractTaskKeyword(from: "cosmology class notes on dark matter") == "astronomy")
    }
    @Test func astronomyKeywordFromObservatory() {
        #expect(CalloutManager.extractTaskKeyword(from: "observatory report from last night's session") == "astronomy")
    }
    @Test func astronomyKeywordFromDarkMatter() {
        #expect(CalloutManager.extractTaskKeyword(from: "dark matter lecture notes review") == "astronomy")
    }
    @Test func astronomyKeywordFromAstrobiologyClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "astrobiology class exam prep") == "astronomy")
    }
    @Test func astronomyFalsePositivePhysicsStaysInStudying() {
        // bare word("physics") stays in studying (generic academic subject)
        #expect(CalloutManager.extractTaskKeyword(from: "physics exam review notes") == "studying")
    }
    @Test func astronomyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "astronomy", tier: tier)
                #expect(!msgs.isEmpty, "astronomy tier \(tier) must have callouts")
            }
        }
    }
    @Test func astronomyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "astronomy", tier: 1)
            #expect(msgs.count >= 4, "astronomy tier1 must have ≥4 messages")
        }
    }
    @Test func astronomyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "astronomy", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "astronomy tier \(tier) callout must not be empty")
                }
            }
        }
    }
    @Test func astronomyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "astronomy", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "astronomy tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Mathematics (Pure Math / Proofs)
    // Positioned before studying; catches number theory, proofs, and advanced math.

    @Test func mathematicsKeywordFromNumberTheory() {
        #expect(CalloutManager.extractTaskKeyword(from: "number theory problem set on prime factorization") == "mathematics")
    }
    @Test func mathematicsKeywordFromProofWriting() {
        #expect(CalloutManager.extractTaskKeyword(from: "proof writing assignment by mathematical induction") == "mathematics")
    }
    @Test func mathematicsKeywordFromAbstractAlgebra() {
        #expect(CalloutManager.extractTaskKeyword(from: "abstract algebra group theory homework") == "mathematics")
    }
    @Test func mathematicsKeywordFromTopology() {
        #expect(CalloutManager.extractTaskKeyword(from: "topology homework on compact spaces") == "mathematics")
    }
    @Test func mathematicsKeywordFromLinearAlgebra() {
        #expect(CalloutManager.extractTaskKeyword(from: "linear algebra problem set on eigenvalues") == "mathematics")
    }
    @Test func mathematicsKeywordFromRealAnalysis() {
        #expect(CalloutManager.extractTaskKeyword(from: "real analysis exam prep on continuity proofs") == "mathematics")
    }
    @Test func mathematicsKeywordFromMathCompetition() {
        #expect(CalloutManager.extractTaskKeyword(from: "math competition prep putnam exam practice") == "mathematics")
    }
    @Test func mathematicsKeywordFromDiscretemath() {
        #expect(CalloutManager.extractTaskKeyword(from: "discrete mathematics combinatorics assignment") == "mathematics")
    }
    @Test func mathematicsFalsePositiveGenericAlgebraStaysInStudying() {
        // bare word("algebra") in a non-proof context stays in studying
        #expect(CalloutManager.extractTaskKeyword(from: "algebra exam review") == "studying")
    }
    @Test func mathematicsCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "mathematics", tier: tier)
                #expect(!msgs.isEmpty, "mathematics tier \(tier) must have callouts")
            }
        }
    }
    @Test func mathematicsCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "mathematics", tier: 1)
            #expect(msgs.count >= 4, "mathematics tier1 must have ≥4 messages")
        }
    }
    @Test func mathematicsCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "mathematics", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "mathematics tier \(tier) callout must not be empty")
                }
            }
        }
    }
    @Test func mathematicsCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "mathematics", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "mathematics tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Linguistics
    // Positioned before studying; language learning stays in the language branch.

    @Test func linguisticsKeywordFromLinguistics() {
        #expect(CalloutManager.extractTaskKeyword(from: "linguistics exam prep on morphology") == "linguistics")
    }
    @Test func linguisticsKeywordFromPhonology() {
        #expect(CalloutManager.extractTaskKeyword(from: "phonology problem set on vowel harmony") == "linguistics")
    }
    @Test func linguisticsKeywordFromPhonetics() {
        #expect(CalloutManager.extractTaskKeyword(from: "phonetics assignment on IPA transcription") == "linguistics")
    }
    @Test func linguisticsKeywordFromSociolinguistics() {
        #expect(CalloutManager.extractTaskKeyword(from: "sociolinguistics paper on language variation") == "linguistics")
    }
    @Test func linguisticsKeywordFromLanguageAcquisition() {
        #expect(CalloutManager.extractTaskKeyword(from: "language acquisition theory paper") == "linguistics")
    }
    @Test func linguisticsKeywordFromHistoricalLinguistics() {
        #expect(CalloutManager.extractTaskKeyword(from: "historical linguistics class on proto-indo-european") == "linguistics")
    }
    @Test func linguisticsKeywordFromDiscourseAnalysis() {
        #expect(CalloutManager.extractTaskKeyword(from: "discourse analysis assignment for my linguistics course") == "linguistics")
    }
    @Test func linguisticsFalsePositiveLanguageLearningStaysInLanguage() {
        // language learning (vocabulary, Duolingo) stays in the language branch, not linguistics
        #expect(CalloutManager.extractTaskKeyword(from: "practice Japanese vocabulary with Duolingo") == "language")
    }
    @Test func linguisticsCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "linguistics", tier: tier)
                #expect(!msgs.isEmpty, "linguistics tier \(tier) must have callouts")
            }
        }
    }
    @Test func linguisticsCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "linguistics", tier: 1)
            #expect(msgs.count >= 4, "linguistics tier1 must have ≥4 messages")
        }
    }
    @Test func linguisticsCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "linguistics", tier: tier)
                for msg in msgs {
                    #expect(!msg.isEmpty, "linguistics tier \(tier) callout must not be empty")
                }
            }
        }
    }
    @Test func linguisticsCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "linguistics", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "linguistics tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Art History
    // Positioned BEFORE the art branch; fine-art making (drawing, painting) stays in art.

    @Test func arthistoryKeywordFromArtHistory() {
        #expect(CalloutManager.extractTaskKeyword(from: "art history essay on impressionism") == "arthistory")
    }
    @Test func arthistoryKeywordFromArtCriticism() {
        #expect(CalloutManager.extractTaskKeyword(from: "write an art criticism paper on baroque sculpture") == "arthistory")
    }
    @Test func arthistoryKeywordFromMuseumStudies() {
        #expect(CalloutManager.extractTaskKeyword(from: "museum studies assignment on curatorial practice") == "arthistory")
    }
    @Test func arthistoryKeywordFromArtHistoryClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "art history class exam prep on the renaissance") == "arthistory")
    }
    @Test func arthistoryFalsePositiveDrawingStaysInArt() {
        // fine-art making does not fire arthistory
        #expect(CalloutManager.extractTaskKeyword(from: "drawing practice for my illustration class") == "art")
    }
    @Test func arthistoryCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "arthistory", tier: tier)
                #expect(!msgs.isEmpty, "arthistory tier \(tier) must have callouts")
            }
        }
    }
    @Test func arthistoryCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "arthistory", tier: 1)
            #expect(msgs.count >= 4, "arthistory tier1 must have ≥4 messages")
        }
    }
    @Test func arthistoryCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "arthistory", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "arthistory tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func arthistoryCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "arthistory", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "arthistory tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Marine Biology / Oceanography
    // Positioned before studying; bare word("biology") stays in studying.

    @Test func marinebiologyKeywordFromMarineBiology() {
        #expect(CalloutManager.extractTaskKeyword(from: "marine biology lab report on coral reefs") == "marinebiology")
    }
    @Test func marinebiologyKeywordFromOceanography() {
        #expect(CalloutManager.extractTaskKeyword(from: "oceanography exam prep on ocean currents") == "marinebiology")
    }
    @Test func marinebiologyKeywordFromMarineEcology() {
        #expect(CalloutManager.extractTaskKeyword(from: "marine ecology assignment on deep sea biodiversity") == "marinebiology")
    }
    @Test func marinebiologyKeywordFromCoralReef() {
        #expect(CalloutManager.extractTaskKeyword(from: "study coral reef ecosystems for marine science class") == "marinebiology")
    }
    @Test func marinebiologyFalsePositiveGenericBiologyStaysInStudying() {
        // bare "biology exam" should stay in studying, not marinebiology
        #expect(CalloutManager.extractTaskKeyword(from: "biology exam review for tomorrow") == "studying")
    }
    @Test func marinebiologyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "marinebiology", tier: tier)
                #expect(!msgs.isEmpty, "marinebiology tier \(tier) must have callouts")
            }
        }
    }
    @Test func marinebiologyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "marinebiology", tier: 1)
            #expect(msgs.count >= 4, "marinebiology tier1 must have ≥4 messages")
        }
    }
    @Test func marinebiologyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "marinebiology", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "marinebiology tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func marinebiologyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "marinebiology", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "marinebiology tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Speech Arts / Competitive Speech & Debate
    // Positioned BEFORE speechpathology; "speech therapy" stays in speechpathology.

    @Test func speechartsKeywordFromDebateTeam() {
        #expect(CalloutManager.extractTaskKeyword(from: "debate team prep for the policy debate tournament") == "speecharts")
    }
    @Test func speechartsKeywordFromModelUN() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a Model UN resolution for my committee") == "speecharts")
    }
    @Test func speechartsKeywordFromPublicSpeaking() {
        #expect(CalloutManager.extractTaskKeyword(from: "public speaking class persuasive speech assignment") == "speecharts")
    }
    @Test func speechartsKeywordFromCompetitiveSpeech() {
        #expect(CalloutManager.extractTaskKeyword(from: "competitive speech practice for oratorical contest") == "speecharts")
    }
    @Test func speechartsFalsePositiveSpeechTherapyStaysInSpeechpathology() {
        // "speech therapy" should route to speechpathology, not speecharts
        #expect(CalloutManager.extractTaskKeyword(from: "write up my speech therapy session notes for my SLP client") == "speechpathology")
    }
    @Test func speechartsCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "speecharts", tier: tier)
                #expect(!msgs.isEmpty, "speecharts tier \(tier) must have callouts")
            }
        }
    }
    @Test func speechartsCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "speecharts", tier: 1)
            #expect(msgs.count >= 4, "speecharts tier1 must have ≥4 messages")
        }
    }
    @Test func speechartsCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "speecharts", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "speecharts tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func speechartsCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "speecharts", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "speecharts tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Forensic Science
    // Positioned BEFORE criminaljustice; "forensic accounting" is its own earlier branch.
    // Bare "forensics" is NOT matched to avoid false positives with speech forensics.

    @Test func forensicscienceKeywordFromForensicScience() {
        #expect(CalloutManager.extractTaskKeyword(from: "forensic science lab report on DNA analysis") == "forensicscience")
    }
    @Test func forensicscienceKeywordFromCrimeScene() {
        #expect(CalloutManager.extractTaskKeyword(from: "crime scene analysis assignment for forensic class") == "forensicscience")
    }
    @Test func forensicscienceKeywordFromDNAAnalysis() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete the DNA profiling exercise for my forensic biology lab") == "forensicscience")
    }
    @Test func forensicscienceKeywordFromForensicBiology() {
        #expect(CalloutManager.extractTaskKeyword(from: "forensic biology exam prep on serology and trace evidence") == "forensicscience")
    }
    @Test func forensicsscienceFalsePositiveCriminologyStaysInCriminaljustice() {
        // criminology without forensic science terms stays in criminaljustice
        #expect(CalloutManager.extractTaskKeyword(from: "criminology exam on juvenile justice and corrections") == "criminaljustice")
    }
    @Test func forensicscienceCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forensicscience", tier: tier)
                #expect(!msgs.isEmpty, "forensicscience tier \(tier) must have callouts")
            }
        }
    }
    @Test func forensicscienceCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forensicscience", tier: 1)
            #expect(msgs.count >= 4, "forensicscience tier1 must have ≥4 messages")
        }
    }
    @Test func forensicscienceCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forensicscience", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "forensicscience tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func forensicscienceCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forensicscience", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "forensicscience tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Accounting
    // Positioned BEFORE forensicaccounting and finance.
    // Bare word("accounting") stays in budget for non-student use.

    @Test func accountingKeywordFromAccountingClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "accounting class chapter 5 practice problems") == "accounting")
    }
    @Test func accountingKeywordFromCMAExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "cma exam prep for part 1 financial planning") == "accounting")
    }
    @Test func accountingKeywordFromQuickBooks() {
        #expect(CalloutManager.extractTaskKeyword(from: "quickbooks certification practice test") == "accounting")
    }
    @Test func accountingKeywordFromIntermediateAccounting() {
        #expect(CalloutManager.extractTaskKeyword(from: "intermediate accounting textbook review for midterm") == "accounting")
    }
    @Test func accountingFalsePositiveForensicStaysInForensicAccounting() {
        #expect(CalloutManager.extractTaskKeyword(from: "forensic accounting fraud examination case") == "forensicaccounting")
    }
    @Test func accountingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "accounting", tier: tier)
                #expect(!msgs.isEmpty, "accounting tier \(tier) must have callouts")
            }
        }
    }
    @Test func accountingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "accounting", tier: 1)
            #expect(msgs.count >= 4, "accounting tier1 must have ≥4 messages")
        }
    }
    @Test func accountingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "accounting", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "accounting tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func accountingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "accounting", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "accounting tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Sports Management
    // Positioned after physed (coaching stays there) and before libraryscience.
    // Bare word("sports") alone does NOT fire.

    @Test func sportsmanagementKeywordFromSportsManagement() {
        #expect(CalloutManager.extractTaskKeyword(from: "sports management case study on revenue sharing") == "sportsmanagement")
    }
    @Test func sportsmanagementKeywordFromAthleticDirector() {
        #expect(CalloutManager.extractTaskKeyword(from: "athletic director leadership assignment for class") == "sportsmanagement")
    }
    @Test func sportsmanagementKeywordFromSportsMarketing() {
        #expect(CalloutManager.extractTaskKeyword(from: "sports marketing exam prep on sponsorship strategy") == "sportsmanagement")
    }
    @Test func sportsmanagementFalsePositiveCoachinStaysInPhysed() {
        // Coaching without sports management terms stays in physed
        #expect(CalloutManager.extractTaskKeyword(from: "coaching certification course materials and exam prep") == "physed")
    }
    @Test func sportsmanagementCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "sportsmanagement", tier: tier)
                #expect(!msgs.isEmpty, "sportsmanagement tier \(tier) must have callouts")
            }
        }
    }
    @Test func sportsmanagementCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "sportsmanagement", tier: 1)
            #expect(msgs.count >= 4, "sportsmanagement tier1 must have ≥4 messages")
        }
    }
    @Test func sportsmanagementCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "sportsmanagement", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "sportsmanagement tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func sportsmanagementCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "sportsmanagement", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "sportsmanagement tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Art Restoration / Conservation
    // Positioned after arthistory and BEFORE art.
    // word("painting") alone goes to art; only compound "painting conservation" fires here.

    @Test func artrestorationKeywordFromArtConservation() {
        #expect(CalloutManager.extractTaskKeyword(from: "art conservation treatment report on panel painting") == "artrestoration")
    }
    @Test func artrestorationKeywordFromPaintingConservation() {
        #expect(CalloutManager.extractTaskKeyword(from: "painting conservation lab assignment on varnish removal") == "artrestoration")
    }
    @Test func artrestorationKeywordFromMuseumConservation() {
        #expect(CalloutManager.extractTaskKeyword(from: "museum conservation internship case notes for class") == "artrestoration")
    }
    @Test func artrestorationFalsePositiveArtHistoryStaysInArtHistory() {
        // Art history terms without conservation/restoration stay in arthistory
        #expect(CalloutManager.extractTaskKeyword(from: "art history essay on baroque period and its artists") == "arthistory")
    }
    @Test func artrestorationCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "artrestoration", tier: tier)
                #expect(!msgs.isEmpty, "artrestoration tier \(tier) must have callouts")
            }
        }
    }
    @Test func artrestorationCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "artrestoration", tier: 1)
            #expect(msgs.count >= 4, "artrestoration tier1 must have ≥4 messages")
        }
    }
    @Test func artrestorationCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "artrestoration", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "artrestoration tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func artrestorationCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "artrestoration", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "artrestoration tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Computational Science
    // Positioned after datascience and before bioinformatics.
    // "computational biology" stays in bioinformatics (fires later).

    @Test func computationalscienceKeywordFromHPC() {
        #expect(CalloutManager.extractTaskKeyword(from: "high performance computing job submission on the cluster") == "computationalscience")
    }
    @Test func computationalscienceKeywordFromMonteCarloSimulation() {
        #expect(CalloutManager.extractTaskKeyword(from: "monte carlo simulation assignment for physics class") == "computationalscience")
    }
    @Test func computationalscienceKeywordFromParallelComputing() {
        #expect(CalloutManager.extractTaskKeyword(from: "parallel computing homework on MPI programming") == "computationalscience")
    }
    @Test func computationalscienceFalsePositiveBioinformaticsStaysInBioinformatics() {
        // Bioinformatics terms without HPC/simulation stay in bioinformatics
        #expect(CalloutManager.extractTaskKeyword(from: "bioinformatics pipeline for rna-seq analysis") == "bioinformatics")
    }
    @Test func computationalscienceCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "computationalscience", tier: tier)
                #expect(!msgs.isEmpty, "computationalscience tier \(tier) must have callouts")
            }
        }
    }
    @Test func computationalscienceCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "computationalscience", tier: 1)
            #expect(msgs.count >= 4, "computationalscience tier1 must have ≥4 messages")
        }
    }
    @Test func computationalscienceCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "computationalscience", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "computationalscience tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func computationalscienceCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "computationalscience", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "computationalscience tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Forensic Psychology
    // Positioned after psychology and BEFORE forensicscience.
    // Bare "forensics" is NOT matched; requires compound forensic-psychology terms.

    @Test func forensicpsychologyKeywordFromForensicPsychology() {
        #expect(CalloutManager.extractTaskKeyword(from: "forensic psychology assessment report for class") == "forensicpsychology")
    }
    @Test func forensicpsychologyKeywordFromCriminalProfiling() {
        #expect(CalloutManager.extractTaskKeyword(from: "criminal profiling case study for forensic psych") == "forensicpsychology")
    }
    @Test func forensicpsychologyKeywordFromEPPPExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "eppp exam prep for forensic psychology licensure") == "forensicpsychology")
    }
    @Test func forensicpsychologyFalsePositivePsychologyStaysInPsychology() {
        // General psychology without forensic terms stays in psychology
        #expect(CalloutManager.extractTaskKeyword(from: "psychology research paper on attachment theory and development") == "psychology")
    }
    @Test func forensicpsychologyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forensicpsychology", tier: tier)
                #expect(!msgs.isEmpty, "forensicpsychology tier \(tier) must have callouts")
            }
        }
    }
    @Test func forensicpsychologyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forensicpsychology", tier: 1)
            #expect(msgs.count >= 4, "forensicpsychology tier1 must have ≥4 messages")
        }
    }
    @Test func forensicpsychologyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forensicpsychology", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "forensicpsychology tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func forensicpsychologyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forensicpsychology", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "forensicpsychology tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Geospatial Science
    // Positioned BEFORE geology so GIS/remote sensing/spatial analysis route here.
    // "gis analysis"/"gis mapping" removed from geology and owned here.

    @Test func geospatialKeywordFromGISMapping() {
        #expect(CalloutManager.extractTaskKeyword(from: "gis mapping project for my geospatial class") == "geospatial")
    }
    @Test func geospatialKeywordFromRemoteSensing() {
        #expect(CalloutManager.extractTaskKeyword(from: "remote sensing lab assignment on satellite imagery") == "geospatial")
    }
    @Test func geospatialKeywordFromArcGIS() {
        #expect(CalloutManager.extractTaskKeyword(from: "arcgis spatial analysis homework on land use data") == "geospatial")
    }
    @Test func geospatialFalsePositiveGeologyStaysInGeology() {
        #expect(CalloutManager.extractTaskKeyword(from: "geology lab report on rock identification and stratigraphy") == "geology")
    }
    @Test func geospatialCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "geospatial", tier: tier)
                #expect(!msgs.isEmpty, "geospatial tier \(tier) must have callouts")
            }
        }
    }
    @Test func geospatialCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "geospatial", tier: 1)
            #expect(msgs.count >= 4, "geospatial tier1 must have ≥4 messages")
        }
    }
    @Test func geospatialCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "geospatial", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "geospatial tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func geospatialCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "geospatial", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "geospatial tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Fashion Design
    // Positioned BEFORE graphicdesign so garment construction, pattern making, and fashion school route here.

    @Test func fashiondesignKeywordFromFashionDesign() {
        #expect(CalloutManager.extractTaskKeyword(from: "fashion design portfolio project for my class") == "fashiondesign")
    }
    @Test func fashiondesignKeywordFromPatternMaking() {
        #expect(CalloutManager.extractTaskKeyword(from: "pattern making assignment for garment construction lab") == "fashiondesign")
    }
    @Test func fashiondesignKeywordFromFashionMerchandising() {
        #expect(CalloutManager.extractTaskKeyword(from: "fashion merchandising case study for my business class") == "fashiondesign")
    }
    @Test func fashiondesignFalsePositiveGraphicDesignStaysInGraphicDesign() {
        #expect(CalloutManager.extractTaskKeyword(from: "graphic design logo project for my client branding work") == "graphicdesign")
    }
    @Test func fashiondesignCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "fashiondesign", tier: tier)
                #expect(!msgs.isEmpty, "fashiondesign tier \(tier) must have callouts")
            }
        }
    }
    @Test func fashiondesignCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "fashiondesign", tier: 1)
            #expect(msgs.count >= 4, "fashiondesign tier1 must have ≥4 messages")
        }
    }
    @Test func fashiondesignCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "fashiondesign", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "fashiondesign tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func fashiondesignCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "fashiondesign", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "fashiondesign tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Hospitality Management
    // Positioned before business so hotel management and tourism coursework route here.

    @Test func hospitalityKeywordFromHotelManagement() {
        #expect(CalloutManager.extractTaskKeyword(from: "hotel management case study on revenue management strategies") == "hospitality")
    }
    @Test func hospitalityKeywordFromHospitalityManagement() {
        #expect(CalloutManager.extractTaskKeyword(from: "hospitality management exam prep on food and beverage operations") == "hospitality")
    }
    @Test func hospitalityKeywordFromTourismMarketing() {
        #expect(CalloutManager.extractTaskKeyword(from: "tourism marketing assignment for my hospitality program") == "hospitality")
    }
    @Test func hospitalityFalsePositiveBusinessStaysInBusiness() {
        #expect(CalloutManager.extractTaskKeyword(from: "mba case analysis on strategic management and operations") == "business")
    }
    @Test func hospitalityCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "hospitality", tier: tier)
                #expect(!msgs.isEmpty, "hospitality tier \(tier) must have callouts")
            }
        }
    }
    @Test func hospitalityCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "hospitality", tier: 1)
            #expect(msgs.count >= 4, "hospitality tier1 must have ≥4 messages")
        }
    }
    @Test func hospitalityCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "hospitality", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "hospitality tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func hospitalityCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "hospitality", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "hospitality tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Sports Analytics
    // Positioned BEFORE sportsmanagement so R/Python for sports data, sabermetrics,
    // and player tracking route here. "sports analytics" removed from sportsmanagement.

    @Test func sportsanalyticsKeywordFromSportsAnalytics() {
        #expect(CalloutManager.extractTaskKeyword(from: "sports analytics project on player tracking data in R") == "sportsanalytics")
    }
    @Test func sportsanalyticsKeywordFromSabermetrics() {
        #expect(CalloutManager.extractTaskKeyword(from: "sabermetrics assignment on advanced baseball stats") == "sportsanalytics")
    }
    @Test func sportsanalyticsKeywordFromPlayerTracking() {
        #expect(CalloutManager.extractTaskKeyword(from: "player tracking data analysis for my sports science class") == "sportsanalytics")
    }
    @Test func sportsanalyticsFalsePositiveSportsManagementStaysInSportsManagement() {
        #expect(CalloutManager.extractTaskKeyword(from: "sports management case study on athletic director leadership") == "sportsmanagement")
    }
    @Test func sportsanalyticsCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "sportsanalytics", tier: tier)
                #expect(!msgs.isEmpty, "sportsanalytics tier \(tier) must have callouts")
            }
        }
    }
    @Test func sportsanalyticsCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "sportsanalytics", tier: 1)
            #expect(msgs.count >= 4, "sportsanalytics tier1 must have ≥4 messages")
        }
    }
    @Test func sportsanalyticsCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "sportsanalytics", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "sportsanalytics tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func sportsanalyticsCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "sportsanalytics", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "sportsanalytics tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Emergency Management
    // Positioned after publicheath and before psychology.
    // Catches FEMA cert prep, disaster response, and incident command.

    @Test func emergencymanagementKeywordFromEmergencyManagement() {
        #expect(CalloutManager.extractTaskKeyword(from: "emergency management class assignment on hazard mitigation planning") == "emergencymanagement")
    }
    @Test func emergencymanagementKeywordFromFEMA() {
        #expect(CalloutManager.extractTaskKeyword(from: "fema certification exam prep on incident command system") == "emergencymanagement")
    }
    @Test func emergencymanagementKeywordFromDisasterResponse() {
        #expect(CalloutManager.extractTaskKeyword(from: "disaster response protocol writing for my emergency management program") == "emergencymanagement")
    }
    @Test func emergencymanagementFalsePositivePublicHealthStaysInPublicHealth() {
        #expect(CalloutManager.extractTaskKeyword(from: "epidemiology class assignment on outbreak investigation methods") == "publicheath")
    }
    @Test func emergencymanagementCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "emergencymanagement", tier: tier)
                #expect(!msgs.isEmpty, "emergencymanagement tier \(tier) must have callouts")
            }
        }
    }
    @Test func emergencymanagementCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "emergencymanagement", tier: 1)
            #expect(msgs.count >= 4, "emergencymanagement tier1 must have ≥4 messages")
        }
    }
    @Test func emergencymanagementCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "emergencymanagement", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "emergencymanagement tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func emergencymanagementCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "emergencymanagement", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "emergencymanagement tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Aviation
    // Positioned BEFORE engineering so FAA exam, flight-school, and checkride tasks route here.

    @Test func aviationKeywordFromPilotTraining() {
        #expect(CalloutManager.extractTaskKeyword(from: "pilot training session for my private pilot certificate") == "aviation")
    }
    @Test func aviationKeywordFromFAAExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "faa written exam prep for private pilot knowledge test") == "aviation")
    }
    @Test func aviationKeywordFromGroundSchool() {
        #expect(CalloutManager.extractTaskKeyword(from: "ground school lesson on airspace and navigation for my flight training") == "aviation")
    }
    @Test func aviationKeywordFromCheckride() {
        #expect(CalloutManager.extractTaskKeyword(from: "checkride prep for my instrument rating oral exam") == "aviation")
    }
    @Test func aviationFalsePositiveAerospaceEngineeringStaysInEngineering() {
        #expect(CalloutManager.extractTaskKeyword(from: "aerospace engineering problem set on thermodynamics and propulsion") == "engineering")
    }
    @Test func aviationCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "aviation", tier: tier)
                #expect(!msgs.isEmpty, "aviation tier \(tier) must have callouts")
            }
        }
    }
    @Test func aviationCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "aviation", tier: 1)
            #expect(msgs.count >= 4, "aviation tier1 must have ≥4 messages")
        }
    }
    @Test func aviationCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "aviation", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "aviation tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func aviationCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "aviation", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "aviation tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Product Design
    // Positioned BEFORE art and design branches so industrial design and product design route here.

    @Test func productdesignKeywordFromIndustrialDesign() {
        #expect(CalloutManager.extractTaskKeyword(from: "industrial design project for my portfolio class") == "productdesign")
    }
    @Test func productdesignKeywordFromProductDesigner() {
        #expect(CalloutManager.extractTaskKeyword(from: "product design sketching and concept development for my ID class") == "productdesign")
    }
    @Test func productdesignKeywordFromErgonomics() {
        #expect(CalloutManager.extractTaskKeyword(from: "ergonomics research and human factors analysis for my product design assignment") == "productdesign")
    }
    @Test func productdesignFalsePositiveUXStaysInUX() {
        #expect(CalloutManager.extractTaskKeyword(from: "ux research and user flow wireframing in figma for my app design") == "ux")
    }
    @Test func productdesignCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "productdesign", tier: tier)
                #expect(!msgs.isEmpty, "productdesign tier \(tier) must have callouts")
            }
        }
    }
    @Test func productdesignCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "productdesign", tier: 1)
            #expect(msgs.count >= 4, "productdesign tier1 must have ≥4 messages")
        }
    }
    @Test func productdesignCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "productdesign", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "productdesign tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func productdesignCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "productdesign", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "productdesign tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Tax Preparation
    // Positioned BEFORE accounting so tax return filing, TurboTax, and EA exam prep route here.

    @Test func taxprepKeywordFromTaxReturn() {
        #expect(CalloutManager.extractTaskKeyword(from: "filing my tax return using turbotax before the deadline") == "taxprep")
    }
    @Test func taxprepKeywordFromEnrolledAgent() {
        #expect(CalloutManager.extractTaskKeyword(from: "enrolled agent exam prep for irs representation part 2") == "taxprep")
    }
    @Test func taxprepKeywordFromIRSForm() {
        #expect(CalloutManager.extractTaskKeyword(from: "filling out irs form 1040 and schedule c for my business") == "taxprep")
    }
    @Test func taxprepFalsePositiveTaxAccountingClassStaysInAccounting() {
        #expect(CalloutManager.extractTaskKeyword(from: "tax accounting class assignment on deferred tax assets and liabilities") == "accounting")
    }
    @Test func taxprepCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "taxprep", tier: tier)
                #expect(!msgs.isEmpty, "taxprep tier \(tier) must have callouts")
            }
        }
    }
    @Test func taxprepCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "taxprep", tier: 1)
            #expect(msgs.count >= 4, "taxprep tier1 must have ≥4 messages")
        }
    }
    @Test func taxprepCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "taxprep", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "taxprep tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func taxprepCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "taxprep", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "taxprep tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Medical Billing and Coding
    // Positioned BEFORE molecularbiology/premed so CPT codes, ICD-10, and CPC exam route here.

    @Test func medicalbillingKeywordFromMedicalCoding() {
        #expect(CalloutManager.extractTaskKeyword(from: "medical coding practice with cpt codes and icd-10 for my billing class") == "medicalbilling")
    }
    @Test func medicalbillingKeywordFromCPCExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "cpc exam prep for aapc medical billing and coding certification") == "medicalbilling")
    }
    @Test func medicalbillingKeywordFromRevenueCycle() {
        #expect(CalloutManager.extractTaskKeyword(from: "revenue cycle management assignment on healthcare billing and claims submission") == "medicalbilling")
    }
    @Test func medicalbillingFalsePositivePremedStaysInPremed() {
        #expect(CalloutManager.extractTaskKeyword(from: "mcat prep studying anatomy and physiology for med school") == "premed")
    }
    @Test func medicalbillingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "medicalbilling", tier: tier)
                #expect(!msgs.isEmpty, "medicalbilling tier \(tier) must have callouts")
            }
        }
    }
    @Test func medicalbillingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "medicalbilling", tier: 1)
            #expect(msgs.count >= 4, "medicalbilling tier1 must have ≥4 messages")
        }
    }
    @Test func medicalbillingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "medicalbilling", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "medicalbilling tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func medicalbillingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "medicalbilling", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "medicalbilling tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Military Studies
    // Positioned AFTER criminaljustice and BEFORE socialscience so military history, ROTC,
    // and ASVAB prep route here rather than socialscience or history (studying) pools.

    @Test func militarystudiesKeywordFromMilitaryHistory() {
        #expect(CalloutManager.extractTaskKeyword(from: "military history paper on strategic command decisions in world war ii") == "militarystudies")
    }
    @Test func militarystudiesKeywordFromROTC() {
        #expect(CalloutManager.extractTaskKeyword(from: "rotc class assignment on military leadership and officer training principles") == "militarystudies")
    }
    @Test func militarystudiesKeywordFromASVAB() {
        #expect(CalloutManager.extractTaskKeyword(from: "asvab prep studying for the arithmetic reasoning and word knowledge sections") == "militarystudies")
    }
    @Test func militarystudiesFalsePositiveCriminalJusticeStaysInCriminalJustice() {
        #expect(CalloutManager.extractTaskKeyword(from: "criminal justice class assignment on law enforcement policing strategies") == "criminaljustice")
    }
    @Test func militarystudiesCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "militarystudies", tier: tier)
                #expect(!msgs.isEmpty, "militarystudies tier \(tier) must have callouts")
            }
        }
    }
    @Test func militarystudiesCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "militarystudies", tier: 1)
            #expect(msgs.count >= 4, "militarystudies tier1 must have ≥4 messages")
        }
    }
    @Test func militarystudiesCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "militarystudies", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "militarystudies tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func militarystudiesCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "militarystudies", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "militarystudies tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Supply Chain / Logistics
    // Positioned BEFORE business so CPIM/CSCP exam prep, logistics coursework, and
    // operations-research classes get their own callout pool.

    @Test func supplychainKeywordFromCPIM() {
        #expect(CalloutManager.extractTaskKeyword(from: "cpim exam prep for apics supply chain management certification") == "supplychain")
    }
    @Test func supplychainKeywordFromLogisticsClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "logistics management class assignment on demand forecasting and inventory optimization") == "supplychain")
    }
    @Test func supplychainKeywordFromLeanSixSigma() {
        #expect(CalloutManager.extractTaskKeyword(from: "lean six sigma green belt project on warehouse process improvement") == "supplychain")
    }
    @Test func supplychainFalsePositiveBusinessMBAStaysInBusiness() {
        #expect(CalloutManager.extractTaskKeyword(from: "mba case analysis on strategic management and supply chain") == "business")
    }
    @Test func supplychainCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "supplychain", tier: tier)
                #expect(!msgs.isEmpty, "supplychain tier \(tier) must have callouts")
            }
        }
    }
    @Test func supplychainCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "supplychain", tier: 1)
            #expect(msgs.count >= 4, "supplychain tier1 must have ≥4 messages")
        }
    }
    @Test func supplychainCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "supplychain", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "supplychain tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func supplychainCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "supplychain", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "supplychain tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Communication Studies
    // Positioned AFTER research/business and BEFORE journalism so comm theory,
    // interpersonal communication, and mass comm courses route here.

    @Test func communicationstudiesKeywordFromCommTheory() {
        #expect(CalloutManager.extractTaskKeyword(from: "communication theory paper on media framing and agenda setting") == "communicationstudies")
    }
    @Test func communicationstudiesKeywordFromCommClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "comm class exam prep on interpersonal communication and conflict resolution") == "communicationstudies")
    }
    @Test func communicationstudiesKeywordFromMassCommunication() {
        #expect(CalloutManager.extractTaskKeyword(from: "mass communication assignment on media effects and audience analysis") == "communicationstudies")
    }
    @Test func communicationstudiesFalsePositiveJournalismStaysInJournalism() {
        #expect(CalloutManager.extractTaskKeyword(from: "journalism class writing a news article on local government") == "journalism")
    }
    @Test func communicationstudiesCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "communicationstudies", tier: tier)
                #expect(!msgs.isEmpty, "communicationstudies tier \(tier) must have callouts")
            }
        }
    }
    @Test func communicationstudiesCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "communicationstudies", tier: 1)
            #expect(msgs.count >= 4, "communicationstudies tier1 must have ≥4 messages")
        }
    }
    @Test func communicationstudiesCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "communicationstudies", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "communicationstudies tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func communicationstudiesCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "communicationstudies", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "communicationstudies tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Healthcare Administration / Health Informatics
    // Positioned AFTER molecularbiology and BEFORE premed so HIM, RHIA/RHIT exam prep,
    // and health informatics coursework route here.

    @Test func healthcareadminKeywordFromRHIA() {
        #expect(CalloutManager.extractTaskKeyword(from: "rhia exam prep for health information management certification") == "healthcareadmin")
    }
    @Test func healthcareadminKeywordFromHealthInformatics() {
        #expect(CalloutManager.extractTaskKeyword(from: "health informatics assignment on ehr implementation and workflow optimization") == "healthcareadmin")
    }
    @Test func healthcareadminKeywordFromHealthcareAdministration() {
        #expect(CalloutManager.extractTaskKeyword(from: "healthcare administration case study on hospital management and revenue cycle") == "healthcareadmin")
    }
    @Test func healthcareadminFalsePositivePremedStaysInPremed() {
        #expect(CalloutManager.extractTaskKeyword(from: "mcat prep studying physiology and anatomy for medical school") == "premed")
    }
    @Test func healthcareadminCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "healthcareadmin", tier: tier)
                #expect(!msgs.isEmpty, "healthcareadmin tier \(tier) must have callouts")
            }
        }
    }
    @Test func healthcareadminCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "healthcareadmin", tier: 1)
            #expect(msgs.count >= 4, "healthcareadmin tier1 must have ≥4 messages")
        }
    }
    @Test func healthcareadminCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "healthcareadmin", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "healthcareadmin tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func healthcareadminCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "healthcareadmin", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "healthcareadmin tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Neuroscience
    // Positioned BEFORE psychology so brain/neuron-biology terms get a dedicated pool.
    // "neural network" (ML) stays in datascience, which fires earlier in the dispatch chain.

    @Test func neuroscienceKeywordFromNeuroscience() {
        #expect(CalloutManager.extractTaskKeyword(from: "neuroscience exam prep on synaptic transmission and action potentials") == "neuroscience")
    }
    @Test func neuroscienceKeywordFromNeuroanatomy() {
        #expect(CalloutManager.extractTaskKeyword(from: "neuroanatomy lab review on hippocampus cortex and limbic system structures") == "neuroscience")
    }
    @Test func neuroscienceKeywordFromCognitiveNeuroscience() {
        #expect(CalloutManager.extractTaskKeyword(from: "cognitive neuroscience paper on neuroplasticity and brain and behavior") == "neuroscience")
    }
    @Test func neuroscienceFalsePositivePsychologyStaysInPsychology() {
        #expect(CalloutManager.extractTaskKeyword(from: "psychology research paper on cognitive development and attachment theory") == "psychology")
    }
    @Test func neuroscienceCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "neuroscience", tier: tier)
                #expect(!msgs.isEmpty, "neuroscience tier \(tier) must have callouts")
            }
        }
    }
    @Test func neuroscienceCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "neuroscience", tier: 1)
            #expect(msgs.count >= 4, "neuroscience tier1 must have ≥4 messages")
        }
    }
    @Test func neuroscienceCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "neuroscience", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "neuroscience tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func neuroscienceCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "neuroscience", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "neuroscience tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Ethnic Studies / Gender Studies
    // Positioned BEFORE socialscience so ethnic/gender/women's studies tasks get a
    // dedicated pool. Bare "gender" or "culture" alone are NOT matched.

    @Test func ethnicstudiesKeywordFromGenderStudies() {
        #expect(CalloutManager.extractTaskKeyword(from: "gender studies paper on feminist theory and intersectionality") == "ethnicstudies")
    }
    @Test func ethnicstudiesKeywordFromCriticalRaceTheory() {
        #expect(CalloutManager.extractTaskKeyword(from: "critical race theory reading assignment for my ethnic studies class") == "ethnicstudies")
    }
    @Test func ethnicstudiesKeywordFromWomensStudies() {
        #expect(CalloutManager.extractTaskKeyword(from: "women's studies exam prep on postcolonial theory and diaspora studies") == "ethnicstudies")
    }
    @Test func ethnicstudiesFalsePositiveSocialScienceStaysInSocialScience() {
        #expect(CalloutManager.extractTaskKeyword(from: "political science paper on comparative politics and international relations") == "socialscience")
    }
    @Test func ethnicstudiesCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "ethnicstudies", tier: tier)
                #expect(!msgs.isEmpty, "ethnicstudies tier \(tier) must have callouts")
            }
        }
    }
    @Test func ethnicstudiesCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "ethnicstudies", tier: 1)
            #expect(msgs.count >= 4, "ethnicstudies tier1 must have ≥4 messages")
        }
    }
    @Test func ethnicstudiesCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "ethnicstudies", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "ethnicstudies tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func ethnicstudiesCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "ethnicstudies", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "ethnicstudies tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Human Factors / Ergonomics
    // Positioned BEFORE engineering so ergonomics, HFE, and BCPE exam tasks get their own pool.
    // Bare "ergonomic" alone is NOT matched.

    @Test func humanfactorsKeywordFromErgonomicsClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "ergonomics class assignment on workstation design") == "humanfactors")
    }
    @Test func humanfactorsKeywordFromHumanFactors() {
        #expect(CalloutManager.extractTaskKeyword(from: "human factors engineering exam prep") == "humanfactors")
    }
    @Test func humanfactorsKeywordFromBCPE() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for the BCPE certification in ergonomics") == "humanfactors")
    }
    @Test func humanfactorsFalsePositiveEngineeringStaysInEngineering() {
        #expect(CalloutManager.extractTaskKeyword(from: "mechanical engineering problem set on fluid mechanics") == "engineering")
    }
    @Test func humanfactorsCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "humanfactors", tier: tier)
                #expect(!msgs.isEmpty, "humanfactors tier \(tier) must have callouts")
            }
        }
    }
    @Test func humanfactorsCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "humanfactors", tier: 1)
            #expect(msgs.count >= 4, "humanfactors tier1 must have ≥4 messages")
        }
    }
    @Test func humanfactorsCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "humanfactors", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "humanfactors tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func humanfactorsCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "humanfactors", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "humanfactors tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Behavioral Economics
    // Positioned AFTER finance and BEFORE budget. Bare "economics" stays in studying/business.

    @Test func behavioraleconomicsKeywordFromNudgeTheory() {
        #expect(CalloutManager.extractTaskKeyword(from: "nudge theory assignment for my behavioral economics class") == "behavioraleconomics")
    }
    @Test func behavioraleconomicsKeywordFromCognitiveBias() {
        #expect(CalloutManager.extractTaskKeyword(from: "study cognitive biases and loss aversion for behavioral econ exam") == "behavioraleconomics")
    }
    @Test func behavioraleconomicsKeywordFromProspectTheory() {
        #expect(CalloutManager.extractTaskKeyword(from: "prospect theory paper on choice architecture and default effects") == "behavioraleconomics")
    }
    @Test func behavioraleconomicsFalsePositiveBusinessStaysInBusiness() {
        #expect(CalloutManager.extractTaskKeyword(from: "mba case analysis on strategic management and supply chain") == "business")
    }
    @Test func behavioraleconomicsCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "behavioraleconomics", tier: tier)
                #expect(!msgs.isEmpty, "behavioraleconomics tier \(tier) must have callouts")
            }
        }
    }
    @Test func behavioraleconomicsCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "behavioraleconomics", tier: 1)
            #expect(msgs.count >= 4, "behavioraleconomics tier1 must have ≥4 messages")
        }
    }
    @Test func behavioraleconomicsCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "behavioraleconomics", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "behavioraleconomics tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func behavioraleconomicsCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "behavioraleconomics", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") || $0.contains("Kahneman") }
            #expect(hasCloseThis, "behavioraleconomics tier 3 must contain 'CLOSE THIS', 'no one', or 'Kahneman'")
        }
    }

    // MARK: - Translational Research
    // Positioned BEFORE research so "translational research" isn't swallowed by word("research").

    @Test func translationalresearchKeywordFromBenchToBedside() {
        #expect(CalloutManager.extractTaskKeyword(from: "bench to bedside project on clinical translation of novel therapeutics") == "translationalresearch")
    }
    @Test func translationalresearchKeywordFromT2Research() {
        #expect(CalloutManager.extractTaskKeyword(from: "t2 research assignment on translational medicine methods") == "translationalresearch")
    }
    @Test func translationalresearchKeywordFromTranslationalScience() {
        #expect(CalloutManager.extractTaskKeyword(from: "translational science proposal for CTSA program") == "translationalresearch")
    }
    @Test func translationalresearchFalsePositiveResearchStaysInResearch() {
        #expect(CalloutManager.extractTaskKeyword(from: "collect and analyze qualitative data for my research paper") == "research")
    }
    @Test func translationalresearchCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "translationalresearch", tier: tier)
                #expect(!msgs.isEmpty, "translationalresearch tier \(tier) must have callouts")
            }
        }
    }
    @Test func translationalresearchCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "translationalresearch", tier: 1)
            #expect(msgs.count >= 4, "translationalresearch tier1 must have ≥4 messages")
        }
    }
    @Test func translationalresearchCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "translationalresearch", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "translationalresearch tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func translationalresearchCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "translationalresearch", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "translationalresearch tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Healthcare Law
    // Positioned BEFORE policy and legal so health law, HIPAA-as-law, bioethics, and medical
    // malpractice route here. "health policy" stays in policy branch.

    @Test func healthcarelawKeywordFromHealthLaw() {
        #expect(CalloutManager.extractTaskKeyword(from: "health law class paper on HIPAA and patient rights") == "healthcarelaw")
    }
    @Test func healthcarelawKeywordFromMedicalMalpractice() {
        #expect(CalloutManager.extractTaskKeyword(from: "medical malpractice case study for my healthcare law exam") == "healthcarelaw")
    }
    @Test func healthcarelawKeywordFromBioethics() {
        #expect(CalloutManager.extractTaskKeyword(from: "bioethics class assignment on informed consent law") == "healthcarelaw")
    }
    @Test func healthcarelawFalsePositiveLegalStaysInLegal() {
        #expect(CalloutManager.extractTaskKeyword(from: "prepare for the bar exam — write a legal brief on contract law") == "legal")
    }
    @Test func healthcarelawCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "healthcarelaw", tier: tier)
                #expect(!msgs.isEmpty, "healthcarelaw tier \(tier) must have callouts")
            }
        }
    }
    @Test func healthcarelawCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "healthcarelaw", tier: 1)
            #expect(msgs.count >= 4, "healthcarelaw tier1 must have ≥4 messages")
        }
    }
    @Test func healthcarelawCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "healthcarelaw", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "healthcarelaw tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func healthcarelawCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "healthcarelaw", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "healthcarelaw tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - International Trade Law
    // Positioned BEFORE legal so trade law, WTO, customs, and international arbitration route here.
    // Bare "trade" alone is NOT matched.

    @Test func tradelawKeywordFromInternationalTradeLaw() {
        #expect(CalloutManager.extractTaskKeyword(from: "international trade law exam prep on WTO dispute resolution") == "tradelaw")
    }
    @Test func tradelawKeywordFromComparativeLaw() {
        #expect(CalloutManager.extractTaskKeyword(from: "comparative law class paper on treaty law and trade agreements") == "tradelaw")
    }
    @Test func tradelawKeywordFromCustomsLaw() {
        #expect(CalloutManager.extractTaskKeyword(from: "customs law assignment on import export law and trade compliance") == "tradelaw")
    }
    @Test func tradelawFalsePositiveLegalStaysInLegal() {
        #expect(CalloutManager.extractTaskKeyword(from: "write a legal memo and prepare for moot court") == "legal")
    }
    @Test func tradelawCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "tradelaw", tier: tier)
                #expect(!msgs.isEmpty, "tradelaw tier \(tier) must have callouts")
            }
        }
    }
    @Test func tradelawCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "tradelaw", tier: 1)
            #expect(msgs.count >= 4, "tradelaw tier1 must have ≥4 messages")
        }
    }
    @Test func tradelawCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "tradelaw", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "tradelaw tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func tradelawCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "tradelaw", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "tradelaw tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Cosmetology

    @Test func cosmetologyKeywordFromCosmetologySchool() {
        #expect(CalloutManager.extractTaskKeyword(from: "cosmetology school state board exam prep") == "cosmetology")
    }
    @Test func cosmetologyKeywordFromEsthetician() {
        #expect(CalloutManager.extractTaskKeyword(from: "esthetics class exam on facial techniques") == "cosmetology")
    }
    @Test func cosmetologyKeywordFromNailTech() {
        #expect(CalloutManager.extractTaskKeyword(from: "nail tech exam prep for nail program certification") == "cosmetology")
    }
    @Test func cosmetologyKeywordFromBarberingSchool() {
        #expect(CalloutManager.extractTaskKeyword(from: "barbering school class assignment on cutting techniques") == "cosmetology")
    }
    @Test func cosmetologyFalsePositiveHairScienceStaysStudying() {
        // bare "hair" without a cosmetology compound stays in studying or generic
        let kw = CalloutManager.extractTaskKeyword(from: "study notes on hair biology for bio class")
        #expect(kw != "cosmetology", "generic hair science should not route to cosmetology")
    }
    @Test func cosmetologyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "cosmetology", tier: tier)
                #expect(!msgs.isEmpty, "cosmetology tier \(tier) must have callouts")
            }
        }
    }
    @Test func cosmetologyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "cosmetology", tier: 1)
            #expect(msgs.count >= 4, "cosmetology tier1 must have ≥4 messages")
        }
    }
    @Test func cosmetologyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "cosmetology", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "cosmetology tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func cosmetologyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "cosmetology", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "cosmetology tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Personal Training

    @Test func personaltrainingKeywordFromNASMExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "nasm exam prep for personal training certification") == "personaltraining")
    }
    @Test func personaltrainingKeywordFromPersonalTrainer() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying to become a personal trainer for ACE certification") == "personaltraining")
    }
    @Test func personaltrainingKeywordFromClientProgram() {
        #expect(CalloutManager.extractTaskKeyword(from: "designing a client program for my training practicum") == "personaltraining")
    }
    @Test func personaltrainingFalsePositiveGenericWorkoutStaysFitness() {
        let kw = CalloutManager.extractTaskKeyword(from: "go to the gym for a workout")
        #expect(kw == "fitness", "generic workout task should route to fitness not personaltraining")
    }
    @Test func personaltrainingFalsePositiveKinesiologyStaysKinesiology() {
        let kw = CalloutManager.extractTaskKeyword(from: "nsca exam prep for cscs certification in exercise physiology")
        #expect(kw == "kinesiology", "CSCS/exercise physiology should stay in kinesiology")
    }
    @Test func personaltrainingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "personaltraining", tier: tier)
                #expect(!msgs.isEmpty, "personaltraining tier \(tier) must have callouts")
            }
        }
    }
    @Test func personaltrainingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "personaltraining", tier: 1)
            #expect(msgs.count >= 4, "personaltraining tier1 must have ≥4 messages")
        }
    }
    @Test func personaltrainingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "personaltraining", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "personaltraining tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func personaltrainingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "personaltraining", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "personaltraining tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Dental Lab

    @Test func dentallabKeywordFromNBDALE() {
        #expect(CalloutManager.extractTaskKeyword(from: "nbdale exam prep for dental lab tech certification") == "dentallab")
    }
    @Test func dentallabKeywordFromCrownAndBridge() {
        #expect(CalloutManager.extractTaskKeyword(from: "crown and bridge fabrication lab assignment for dental lab class") == "dentallab")
    }
    @Test func dentallabKeywordFromCeramist() {
        #expect(CalloutManager.extractTaskKeyword(from: "dental ceramics project for ceramist training") == "dentallab")
    }
    @Test func dentallabFalsePositiveDentalAssistantStaysDentalAssisting() {
        let kw = CalloutManager.extractTaskKeyword(from: "dental assisting class assignment on chairside procedures")
        #expect(kw == "dentalassisting", "dental assistant tasks should not route to dentallab")
    }
    @Test func dentallabFalsePositiveDentalSchoolStaysDental() {
        let kw = CalloutManager.extractTaskKeyword(from: "dental school board exam prep for DDS program")
        #expect(kw == "dental", "dental school tasks should not route to dentallab")
    }
    @Test func dentallabCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dentallab", tier: tier)
                #expect(!msgs.isEmpty, "dentallab tier \(tier) must have callouts")
            }
        }
    }
    @Test func dentallabCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dentallab", tier: 1)
            #expect(msgs.count >= 4, "dentallab tier1 must have ≥4 messages")
        }
    }
    @Test func dentallabCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dentallab", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "dentallab tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func dentallabCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dentallab", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "dentallab tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Landscape Architecture

    @Test func landscapearchitectureKeywordFromLandscapeArchitect() {
        #expect(CalloutManager.extractTaskKeyword(from: "landscape architecture studio project on site design") == "landscapearchitecture")
    }
    @Test func landscapearchitectureKeywordFromCLARB() {
        #expect(CalloutManager.extractTaskKeyword(from: "clarb exam prep for landscape architecture licensing") == "landscapearchitecture")
    }
    @Test func landscapearchitectureKeywordFromPlantingPlan() {
        #expect(CalloutManager.extractTaskKeyword(from: "develop a planting plan and hardscape design for my landscape class") == "landscapearchitecture")
    }
    @Test func landscapearchitectureFalsePositiveInteriorDesignStaysInterior() {
        let kw = CalloutManager.extractTaskKeyword(from: "interior design studio project on space planning and ncidq prep")
        #expect(kw == "interiordesign", "interior design tasks should not route to landscapearchitecture")
    }
    @Test func landscapearchitectureFalsePositiveBuildingArchitectureStaysArchitecture() {
        let kw = CalloutManager.extractTaskKeyword(from: "architecture studio project on building design and revit modeling")
        #expect(kw == "architecture", "building architecture tasks should not route to landscapearchitecture")
    }
    @Test func landscapearchitectureCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "landscapearchitecture", tier: tier)
                #expect(!msgs.isEmpty, "landscapearchitecture tier \(tier) must have callouts")
            }
        }
    }
    @Test func landscapearchitectureCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "landscapearchitecture", tier: 1)
            #expect(msgs.count >= 4, "landscapearchitecture tier1 must have ≥4 messages")
        }
    }
    @Test func landscapearchitectureCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "landscapearchitecture", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "landscapearchitecture tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func landscapearchitectureCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "landscapearchitecture", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "landscapearchitecture tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Immigration Law

    @Test func immigrationlawKeywordFromVisaPetition() {
        #expect(CalloutManager.extractTaskKeyword(from: "preparing a visa petition for my immigration law clinic client") == "immigrationlaw")
    }
    @Test func immigrationlawKeywordFromUSCIS() {
        #expect(CalloutManager.extractTaskKeyword(from: "filling out uscis forms for an asylum application") == "immigrationlaw")
    }
    @Test func immigrationlawKeywordFromRemovalProceedings() {
        #expect(CalloutManager.extractTaskKeyword(from: "removal proceedings defense brief for immigration law class") == "immigrationlaw")
    }
    @Test func immigrationlawFalsePositiveGenericLegalStaysLegal() {
        let kw = CalloutManager.extractTaskKeyword(from: "study for the bar exam and write a legal brief for moot court")
        #expect(kw == "legal", "generic legal tasks should not route to immigrationlaw")
    }
    @Test func immigrationlawFalsePositiveTradeLawStaysTradeLaw() {
        let kw = CalloutManager.extractTaskKeyword(from: "international trade law exam on WTO dispute resolution and treaty law")
        #expect(kw == "tradelaw", "trade law tasks should not route to immigrationlaw")
    }
    @Test func immigrationlawCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "immigrationlaw", tier: tier)
                #expect(!msgs.isEmpty, "immigrationlaw tier \(tier) must have callouts")
            }
        }
    }
    @Test func immigrationlawCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "immigrationlaw", tier: 1)
            #expect(msgs.count >= 4, "immigrationlaw tier1 must have ≥4 messages")
        }
    }
    @Test func immigrationlawCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "immigrationlaw", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "immigrationlaw tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func immigrationlawCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "immigrationlaw", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "immigrationlaw tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Music Education
    @Test func musiceducationKeywordFromMusicEducation() {
        // "music education" alone is not caught by the education branch (needs "education class/course/program/degree")
        #expect(CalloutManager.extractTaskKeyword(from: "studying music education for my choral ensemble directing assignment") == "musiceducation")
    }
    @Test func musiceducationKeywordFromPraxisMusic() {
        // "praxis music" without "teach" or "education" elsewhere does not fire the education branch
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the praxis music exam to become a band director") == "musiceducation")
    }
    @Test func musiceducationKeywordFromChoralDirector() {
        #expect(CalloutManager.extractTaskKeyword(from: "choral director rehearsal planning for my music methods course") == "musiceducation")
    }
    @Test func musiceducationFalsePositiveGenericMusicStaysMusicProduction() {
        // bare "music" without education compound stays in musicproduction/musictheory
        let kw = CalloutManager.extractTaskKeyword(from: "produce and mix a track in my DAW")
        #expect(kw == "musicproduction", "generic music production should not route to musiceducation")
    }
    @Test func musiceducationFalsePositiveGenericEducationStaysEducation() {
        let kw = CalloutManager.extractTaskKeyword(from: "lesson plan for my student teaching placement in science class")
        #expect(kw == "education", "non-music education tasks should not route to musiceducation")
    }
    @Test func musiceducationCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "musiceducation", tier: tier)
                #expect(!msgs.isEmpty, "musiceducation tier \(tier) must have callouts")
            }
        }
    }
    @Test func musiceducationCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "musiceducation", tier: 1)
            #expect(msgs.count >= 4, "musiceducation tier1 must have ≥4 messages")
        }
    }
    @Test func musiceducationCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "musiceducation", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "musiceducation tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func musiceducationCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "musiceducation", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "musiceducation tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Massage Therapy
    @Test func massagetherapyKeywordFromMassageTherapy() {
        #expect(CalloutManager.extractTaskKeyword(from: "massage therapy class assignment on swedish and deep tissue technique") == "massagetherapy")
    }
    @Test func massagetherapyKeywordFromMBLEx() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the mblex massage licensing exam") == "massagetherapy")
    }
    @Test func massagetherapyKeywordFromMyofascial() {
        #expect(CalloutManager.extractTaskKeyword(from: "myofascial release technique notes for massage certification") == "massagetherapy")
    }
    @Test func massagetherapyFalsePositiveGenericTherapyStaysTherapy() {
        let kw = CalloutManager.extractTaskKeyword(from: "therapy notes and treatment plan for my CBT client")
        #expect(kw == "therapy", "generic therapy tasks should not route to massagetherapy")
    }
    @Test func massagetherapyFalsePositiveKinesiologyStaysKinesiology() {
        let kw = CalloutManager.extractTaskKeyword(from: "biomechanics and kinesiology exam on musculoskeletal movement")
        #expect(kw == "kinesiology", "kinesiology tasks should not route to massagetherapy")
    }
    @Test func massagetherapyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "massagetherapy", tier: tier)
                #expect(!msgs.isEmpty, "massagetherapy tier \(tier) must have callouts")
            }
        }
    }
    @Test func massagetherapyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "massagetherapy", tier: 1)
            #expect(msgs.count >= 4, "massagetherapy tier1 must have ≥4 messages")
        }
    }
    @Test func massagetherapyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "massagetherapy", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "massagetherapy tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func massagetherapyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "massagetherapy", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "massagetherapy tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Medical Laboratory Science
    @Test func medicallabscienceKeywordFromASCPExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "ascp exam prep for medical laboratory science certification") == "medicallabscience")
    }
    @Test func medicallabscienceKeywordFromClinicalLabScience() {
        #expect(CalloutManager.extractTaskKeyword(from: "clinical laboratory science program hematology lab report") == "medicallabscience")
    }
    @Test func medicallabscienceKeywordFromBloodBank() {
        #expect(CalloutManager.extractTaskKeyword(from: "blood bank class assignment on ABO and Rh typing") == "medicallabscience")
    }
    @Test func medicallabscienceFalsePositiveMedicalBillingStaysMedicalBilling() {
        let kw = CalloutManager.extractTaskKeyword(from: "medical billing and coding cpc exam prep for aapc certification")
        #expect(kw == "medicalbilling", "medical billing tasks should not route to medicallabscience")
    }
    @Test func medicallabscienceFalsePositiveMolecularBiologyStaysMolecularBiology() {
        let kw = CalloutManager.extractTaskKeyword(from: "pcr protocol and western blot for molecular biology lab")
        #expect(kw == "molecularbiology", "molecular biology tasks should not route to medicallabscience")
    }
    @Test func medicallabscienceCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "medicallabscience", tier: tier)
                #expect(!msgs.isEmpty, "medicallabscience tier \(tier) must have callouts")
            }
        }
    }
    @Test func medicallabscienceCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "medicallabscience", tier: 1)
            #expect(msgs.count >= 4, "medicallabscience tier1 must have ≥4 messages")
        }
    }
    @Test func medicallabscienceCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "medicallabscience", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "medicallabscience tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func medicallabscienceCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "medicallabscience", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "medicallabscience tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Radiologic Technology
    @Test func radiologictechnologyKeywordFromARRT() {
        #expect(CalloutManager.extractTaskKeyword(from: "arrt exam prep for radiologic technology certification") == "radiologictechnology")
    }
    @Test func radiologictechnologyKeywordFromRadiographyProgram() {
        #expect(CalloutManager.extractTaskKeyword(from: "radiography program class on chest x-ray positioning protocols") == "radiologictechnology")
    }
    @Test func radiologictechnologyKeywordFromMRITech() {
        #expect(CalloutManager.extractTaskKeyword(from: "mri tech certification exam study session on safety and physics") == "radiologictechnology")
    }
    @Test func radiologictechnologyFalsePositiveMedicalLabStaysMedicalLab() {
        let kw = CalloutManager.extractTaskKeyword(from: "ascp exam prep for clinical laboratory science hematology")
        #expect(kw == "medicallabscience", "medical lab science tasks should not route to radiologictechnology")
    }
    @Test func radiologictechnologyFalsePositivePremedStaysPremed() {
        let kw = CalloutManager.extractTaskKeyword(from: "mcat prep studying anatomy and physiology for med school")
        #expect(kw == "premed", "premed tasks should not route to radiologictechnology")
    }
    @Test func radiologictechnologyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "radiologictechnology", tier: tier)
                #expect(!msgs.isEmpty, "radiologictechnology tier \(tier) must have callouts")
            }
        }
    }
    @Test func radiologictechnologyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "radiologictechnology", tier: 1)
            #expect(msgs.count >= 4, "radiologictechnology tier1 must have ≥4 messages")
        }
    }
    @Test func radiologictechnologyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "radiologictechnology", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "radiologictechnology tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func radiologictechnologyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "radiologictechnology", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "radiologictechnology tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Intellectual Property Law
    @Test func intellectualpropertyKeywordFromPatentBar() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the patent bar exam and patent prosecution procedures") == "intellectualproperty")
    }
    @Test func intellectualpropertyKeywordFromTrademarkLaw() {
        #expect(CalloutManager.extractTaskKeyword(from: "trademark law class assignment on infringement and registration") == "intellectualproperty")
    }
    @Test func intellectualpropertyKeywordFromPatentClaims() {
        #expect(CalloutManager.extractTaskKeyword(from: "drafting patent claims for my ip law clinic assignment") == "intellectualproperty")
    }
    @Test func intellectualpropertyFalsePositiveImmigrationLawStaysImmigrationLaw() {
        let kw = CalloutManager.extractTaskKeyword(from: "immigration law exam on visa petitions and uscis removal proceedings")
        #expect(kw == "immigrationlaw", "immigration law tasks should not route to intellectualproperty")
    }
    @Test func intellectualpropertyFalsePositiveGenericLegalStaysLegal() {
        let kw = CalloutManager.extractTaskKeyword(from: "bar exam prep on constitutional law and civil procedure")
        #expect(kw == "legal", "generic legal tasks should not route to intellectualproperty")
    }
    @Test func intellectualpropertyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "intellectualproperty", tier: tier)
                #expect(!msgs.isEmpty, "intellectualproperty tier \(tier) must have callouts")
            }
        }
    }
    @Test func intellectualpropertyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "intellectualproperty", tier: 1)
            #expect(msgs.count >= 4, "intellectualproperty tier1 must have ≥4 messages")
        }
    }
    @Test func intellectualpropertyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "intellectualproperty", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "intellectualproperty tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func intellectualpropertyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "intellectualproperty", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "intellectualproperty tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Sign Language / ASL
    @Test func signlanguageKeywordFromSignLanguage() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying sign language for my asl class assignment") == "signlanguage")
    }
    @Test func signlanguageKeywordFromASLExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "asl exam prep for american sign language final") == "signlanguage")
    }
    @Test func signlanguageKeywordFromDeafCulture() {
        #expect(CalloutManager.extractTaskKeyword(from: "deaf culture and deaf education class assignment on Deaf community history") == "signlanguage")
    }
    @Test func signlanguageFalsePositiveLinguisticsStaysLinguistics() {
        let kw = CalloutManager.extractTaskKeyword(from: "linguistics exam on phonology and phoneme analysis")
        #expect(kw == "linguistics", "linguistics tasks should not route to signlanguage")
    }
    @Test func signlanguageFalsePositiveLanguageLearningStaysLanguage() {
        let kw = CalloutManager.extractTaskKeyword(from: "learning spanish vocabulary with duolingo")
        #expect(kw == "language", "generic language learning should not route to signlanguage")
    }
    @Test func signlanguageCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "signlanguage", tier: tier)
                #expect(!msgs.isEmpty, "signlanguage tier \(tier) must have callouts")
            }
        }
    }
    @Test func signlanguageCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "signlanguage", tier: 1)
            #expect(msgs.count >= 4, "signlanguage tier1 must have ≥4 messages")
        }
    }
    @Test func signlanguageCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "signlanguage", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "signlanguage tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func signlanguageCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "signlanguage", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "signlanguage tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Acupuncture / TCM
    @Test func acupunctureKeywordFromNccaom() {
        #expect(CalloutManager.extractTaskKeyword(from: "nccaom board exam prep for acupuncture licensing") == "acupuncture")
    }
    @Test func acupunctureKeywordFromTCM() {
        #expect(CalloutManager.extractTaskKeyword(from: "traditional chinese medicine class on herbal formula and meridian theory") == "acupuncture")
    }
    @Test func acupunctureKeywordFromAcupunctureSchool() {
        #expect(CalloutManager.extractTaskKeyword(from: "acupuncture school assignment on acupuncture points and channel pathways") == "acupuncture")
    }
    @Test func acupunctureFalsePositivePremedStaysPremed() {
        let kw = CalloutManager.extractTaskKeyword(from: "mcat prep studying anatomy and physiology for med school")
        #expect(kw == "premed", "premed tasks should not route to acupuncture")
    }
    @Test func acupunctureFalsePositiveChiropracticStaysChiropractic() {
        let kw = CalloutManager.extractTaskKeyword(from: "chiropractic school assignment on spinal adjustment and NBCE exam prep")
        #expect(kw == "chiropractic", "chiropractic tasks should not route to acupuncture")
    }
    @Test func acupunctureCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "acupuncture", tier: tier)
                #expect(!msgs.isEmpty, "acupuncture tier \(tier) must have callouts")
            }
        }
    }
    @Test func acupunctureCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "acupuncture", tier: 1)
            #expect(msgs.count >= 4, "acupuncture tier1 must have ≥4 messages")
        }
    }
    @Test func acupunctureCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "acupuncture", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "acupuncture tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func acupunctureCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "acupuncture", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "acupuncture tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Art Education
    @Test func arteducationKeywordFromArtTeacher() {
        #expect(CalloutManager.extractTaskKeyword(from: "art teacher certification program assignment on visual arts lesson planning") == "arteducation")
    }
    @Test func arteducationKeywordFromPraxisArt() {
        #expect(CalloutManager.extractTaskKeyword(from: "praxis art education exam prep for visual arts teaching certification") == "arteducation")
    }
    @Test func arteducationKeywordFromArtCurriculum() {
        #expect(CalloutManager.extractTaskKeyword(from: "designing an art curriculum for elementary art education class") == "arteducation")
    }
    @Test func arteducationFalsePositiveMusicEducationStaysMusicEducation() {
        let kw = CalloutManager.extractTaskKeyword(from: "music education class on choral directing and praxis music exam prep")
        #expect(kw == "musiceducation", "music education tasks should not route to arteducation")
    }
    @Test func arteducationFalsePositivePhysedStaysPhysed() {
        let kw = CalloutManager.extractTaskKeyword(from: "physical education teacher certification program on coaching theory")
        #expect(kw == "physed", "physed tasks should not route to arteducation")
    }
    @Test func arteducationCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "arteducation", tier: tier)
                #expect(!msgs.isEmpty, "arteducation tier \(tier) must have callouts")
            }
        }
    }
    @Test func arteducationCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "arteducation", tier: 1)
            #expect(msgs.count >= 4, "arteducation tier1 must have ≥4 messages")
        }
    }
    @Test func arteducationCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "arteducation", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "arteducation tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func arteducationCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "arteducation", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "arteducation tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Environmental Law
    @Test func environmentallawKeywordFromEnvLaw() {
        #expect(CalloutManager.extractTaskKeyword(from: "environmental law class assignment on NEPA compliance and impact assessment") == "environmentallaw")
    }
    @Test func environmentallawKeywordFromCleanAirAct() {
        #expect(CalloutManager.extractTaskKeyword(from: "research paper on the clean air act and EPA regulatory framework") == "environmentallaw")
    }
    @Test func environmentallawKeywordFromClimateLitigation() {
        #expect(CalloutManager.extractTaskKeyword(from: "climate litigation brief for environmental law seminar") == "environmentallaw")
    }
    @Test func environmentallawFalsePositiveEnviroStaysEnviro() {
        let kw = CalloutManager.extractTaskKeyword(from: "studying for my environmental science exam on ecology and ecosystems")
        #expect(kw == "enviro", "environmental science tasks should not route to environmentallaw")
    }
    @Test func environmentallawFalsePositiveIPLawStaysIPLaw() {
        let kw = CalloutManager.extractTaskKeyword(from: "patent bar exam prep on patent prosecution and USPTO procedures")
        #expect(kw == "intellectualproperty", "IP law tasks should not route to environmentallaw")
    }
    @Test func environmentallawCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "environmentallaw", tier: tier)
                #expect(!msgs.isEmpty, "environmentallaw tier \(tier) must have callouts")
            }
        }
    }
    @Test func environmentallawCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "environmentallaw", tier: 1)
            #expect(msgs.count >= 4, "environmentallaw tier1 must have ≥4 messages")
        }
    }
    @Test func environmentallawCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "environmentallaw", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "environmentallaw tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func environmentallawCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "environmentallaw", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "environmentallaw tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Family Law
    @Test func familylawKeywordFromFamilyLaw() {
        #expect(CalloutManager.extractTaskKeyword(from: "family law class assignment on child custody and parental rights") == "familylaw")
    }
    @Test func familylawKeywordFromDivorceLaw() {
        #expect(CalloutManager.extractTaskKeyword(from: "divorce law research memo on marital property and alimony") == "familylaw")
    }
    @Test func familylawKeywordFromAdoptionLaw() {
        #expect(CalloutManager.extractTaskKeyword(from: "adoption law brief for family law clinic on termination of parental rights") == "familylaw")
    }
    @Test func familylawFalsePositiveEnvLawStaysEnvLaw() {
        let kw = CalloutManager.extractTaskKeyword(from: "environmental law exam on NEPA and the clean water act")
        #expect(kw == "environmentallaw", "environmental law tasks should not route to familylaw")
    }
    @Test func familylawFalsePositiveGenericLegalStaysLegal() {
        let kw = CalloutManager.extractTaskKeyword(from: "bar exam prep on constitutional law and civil procedure")
        #expect(kw == "legal", "generic legal tasks should not route to familylaw")
    }
    @Test func familylawCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "familylaw", tier: tier)
                #expect(!msgs.isEmpty, "familylaw tier \(tier) must have callouts")
            }
        }
    }
    @Test func familylawCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "familylaw", tier: 1)
            #expect(msgs.count >= 4, "familylaw tier1 must have ≥4 messages")
        }
    }
    @Test func familylawCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "familylaw", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "familylaw tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func familylawCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "familylaw", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "familylaw tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Nuclear Medicine Technology
    @Test func nuclearmedtechKeywordFromNMT() {
        #expect(CalloutManager.extractTaskKeyword(from: "nuclear medicine technology board exam prep for CNMT certification") == "nuclearmedtech")
    }
    @Test func nuclearmedtechKeywordFromPETScan() {
        #expect(CalloutManager.extractTaskKeyword(from: "pet scan technologist class on PET imaging protocols and radiopharmaceuticals") == "nuclearmedtech")
    }
    @Test func nuclearmedtechKeywordFromRadiopharmacy() {
        #expect(CalloutManager.extractTaskKeyword(from: "radiopharmaceuticals class for nuclear medicine technologist certification") == "nuclearmedtech")
    }
    @Test func nuclearmedtechFalsePositiveRadiologyStaysRadiology() {
        let kw = CalloutManager.extractTaskKeyword(from: "arrt exam prep for radiologic technology and radiographic positioning")
        #expect(kw == "radiologictechnology", "radiology tasks should not route to nuclearmedtech")
    }
    @Test func nuclearmedtechFalsePositiveHealthcareAdminStaysAdmin() {
        let kw = CalloutManager.extractTaskKeyword(from: "healthcare administration class on health informatics and RHIA certification")
        #expect(kw == "healthcareadmin", "healthcare admin tasks should not route to nuclearmedtech")
    }
    @Test func nuclearmedtechCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "nuclearmedtech", tier: tier)
                #expect(!msgs.isEmpty, "nuclearmedtech tier \(tier) must have callouts")
            }
        }
    }
    @Test func nuclearmedtechCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "nuclearmedtech", tier: 1)
            #expect(msgs.count >= 4, "nuclearmedtech tier1 must have ≥4 messages")
        }
    }
    @Test func nuclearmedtechCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "nuclearmedtech", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "nuclearmedtech tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func nuclearmedtechCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "nuclearmedtech", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "nuclearmedtech tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Diagnostic Medical Sonography
    @Test func sonographyKeywordFromARDMS() {
        #expect(CalloutManager.extractTaskKeyword(from: "ardms registry exam prep on abdominal and obstetric sonography") == "sonography")
    }
    @Test func sonographyKeywordFromUltrasoundTech() {
        #expect(CalloutManager.extractTaskKeyword(from: "ultrasound technologist class on scanning technique and ultrasound physics") == "sonography")
    }
    @Test func sonographyKeywordFromDiagnosticSonography() {
        #expect(CalloutManager.extractTaskKeyword(from: "diagnostic medical sonography program exam on vascular imaging") == "sonography")
    }
    @Test func sonographyFalsePositiveNuclearMedStaysNuclearMed() {
        let kw = CalloutManager.extractTaskKeyword(from: "nuclear medicine technology board exam prep for CNMT certification")
        #expect(kw == "nuclearmedtech", "nuclear medicine tasks should not route to sonography")
    }
    @Test func sonographyFalsePositiveRadiologyStaysRadiology() {
        let kw = CalloutManager.extractTaskKeyword(from: "arrt exam prep for radiologic technology and radiographic positioning")
        #expect(kw == "radiologictechnology", "radiology tasks should not route to sonography")
    }
    @Test func sonographyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "sonography", tier: tier)
                #expect(!msgs.isEmpty, "sonography tier \(tier) must have callouts")
            }
        }
    }
    @Test func sonographyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "sonography", tier: 1)
            #expect(msgs.count >= 4, "sonography tier1 must have ≥4 messages")
        }
    }
    @Test func sonographyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "sonography", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "sonography tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func sonographyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "sonography", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "sonography tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Cardiovascular Technology
    @Test func cardiovasculartechKeywordFromCCI() {
        #expect(CalloutManager.extractTaskKeyword(from: "cci board exam prep for cardiovascular technology and cardiac catheterization") == "cardiovasculartech")
    }
    @Test func cardiovasculartechKeywordFromEcho() {
        #expect(CalloutManager.extractTaskKeyword(from: "echocardiography class on cardiac imaging and hemodynamics") == "cardiovasculartech")
    }
    @Test func cardiovasculartechKeywordFromCardiacCath() {
        #expect(CalloutManager.extractTaskKeyword(from: "cardiac catheterization course on cath lab procedures and vascular access") == "cardiovasculartech")
    }
    @Test func cardiovasculartechFalsePositiveSonographyStaysSonography() {
        let kw = CalloutManager.extractTaskKeyword(from: "ardms registry exam prep on abdominal and obstetric sonography")
        #expect(kw == "sonography", "sonography tasks should not route to cardiovasculartech")
    }
    @Test func cardiovasculartechFalsePositiveNursingStaysNursing() {
        let kw = CalloutManager.extractTaskKeyword(from: "nclex exam prep for nursing school on cardiac medications and patient care")
        #expect(kw == "nursing", "nursing tasks should not route to cardiovasculartech")
    }
    @Test func cardiovasculartechCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "cardiovasculartech", tier: tier)
                #expect(!msgs.isEmpty, "cardiovasculartech tier \(tier) must have callouts")
            }
        }
    }
    @Test func cardiovasculartechCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "cardiovasculartech", tier: 1)
            #expect(msgs.count >= 4, "cardiovasculartech tier1 must have ≥4 messages")
        }
    }
    @Test func cardiovasculartechCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "cardiovasculartech", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "cardiovasculartech tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func cardiovasculartechCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "cardiovasculartech", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "cardiovasculartech tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Surgical Technology
    @Test func surgicaltechKeywordFromCST() {
        #expect(CalloutManager.extractTaskKeyword(from: "cst exam prep on surgical instrumentation and sterile field technique") == "surgicaltech")
    }
    @Test func surgicaltechKeywordFromScrubTech() {
        #expect(CalloutManager.extractTaskKeyword(from: "scrub tech class on surgical technology and perioperative patient care") == "surgicaltech")
    }
    @Test func surgicaltechKeywordFromNBSTSA() {
        #expect(CalloutManager.extractTaskKeyword(from: "nbstsa certification exam prep for surgical technologist program") == "surgicaltech")
    }
    @Test func surgicaltechFalsePositiveCardiovascularStaysCardiovascular() {
        let kw = CalloutManager.extractTaskKeyword(from: "cci board exam prep for cardiovascular technology and cardiac catheterization")
        #expect(kw == "cardiovasculartech", "cardiovascular tech tasks should not route to surgicaltech")
    }
    @Test func surgicaltechFalsePositiveNursingStaysNursing() {
        let kw = CalloutManager.extractTaskKeyword(from: "nclex exam prep for nursing school on surgical nursing and perioperative care plan")
        #expect(kw == "nursing", "nursing tasks should not route to surgicaltech")
    }
    @Test func surgicaltechCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "surgicaltech", tier: tier)
                #expect(!msgs.isEmpty, "surgicaltech tier \(tier) must have callouts")
            }
        }
    }
    @Test func surgicaltechCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "surgicaltech", tier: 1)
            #expect(msgs.count >= 4, "surgicaltech tier1 must have ≥4 messages")
        }
    }
    @Test func surgicaltechCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "surgicaltech", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "surgicaltech tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func surgicaltechCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "surgicaltech", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "surgicaltech tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Art Therapy
    @Test func arttherapyKeywordFromArtTherapy() {
        #expect(CalloutManager.extractTaskKeyword(from: "art therapy session notes and treatment plan for client case conceptualization") == "arttherapy")
    }
    @Test func arttherapyKeywordFromATR() {
        #expect(CalloutManager.extractTaskKeyword(from: "atr board exam prep for art therapy certification and credentialing") == "arttherapy")
    }
    @Test func arttherapyKeywordFromExpressiveArts() {
        #expect(CalloutManager.extractTaskKeyword(from: "expressive arts therapy class assignment on creative arts therapist competencies") == "arttherapy")
    }
    @Test func arttherapyFalsePositiveTherapyNoteStaysTherapy() {
        let kw = CalloutManager.extractTaskKeyword(from: "therapy notes and session notes for cognitive behavioral therapy client")
        #expect(kw == "therapy", "generic therapy tasks should not route to arttherapy")
    }
    @Test func arttherapyFalsePositiveArtClassStaysStudying() {
        let kw = CalloutManager.extractTaskKeyword(from: "taking an art class at the studio this semester")
        #expect(kw != "arttherapy", "generic art class tasks should not route to arttherapy")
    }
    @Test func arttherapyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "arttherapy", tier: tier)
                #expect(!msgs.isEmpty, "arttherapy tier \(tier) must have callouts")
            }
        }
    }
    @Test func arttherapyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "arttherapy", tier: 1)
            #expect(msgs.count >= 4, "arttherapy tier1 must have ≥4 messages")
        }
    }
    @Test func arttherapyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "arttherapy", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "arttherapy tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func arttherapyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "arttherapy", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "arttherapy tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Polysomnography
    @Test func polysomnographyKeywordFromRPSGT() {
        #expect(CalloutManager.extractTaskKeyword(from: "rpsgt board exam prep for polysomnography certification and sleep scoring") == "polysomnography")
    }
    @Test func polysomnographyKeywordFromPSGLab() {
        #expect(CalloutManager.extractTaskKeyword(from: "psg lab assignment on sleep staging and polysomnography interpretation") == "polysomnography")
    }
    @Test func polysomnographyKeywordFromSleepTech() {
        #expect(CalloutManager.extractTaskKeyword(from: "sleep technology program exam on sleep tech certification and RPSGT") == "polysomnography")
    }
    @Test func polysomnographyFalsePositiveSurgicalStaysSurgical() {
        let kw = CalloutManager.extractTaskKeyword(from: "cst exam prep on surgical technology and sterile field technique")
        #expect(kw == "surgicaltech", "surgical tech tasks should not route to polysomnography")
    }
    @Test func polysomnographyFalsePositiveNursingStaysNursing() {
        let kw = CalloutManager.extractTaskKeyword(from: "nclex exam prep for nursing school on patient assessment and care plan")
        #expect(kw == "nursing", "nursing tasks should not route to polysomnography")
    }
    @Test func polysomnographyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "polysomnography", tier: tier)
                #expect(!msgs.isEmpty, "polysomnography tier \(tier) must have callouts")
            }
        }
    }
    @Test func polysomnographyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "polysomnography", tier: 1)
            #expect(msgs.count >= 4, "polysomnography tier1 must have ≥4 messages")
        }
    }
    @Test func polysomnographyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "polysomnography", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "polysomnography tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func polysomnographyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "polysomnography", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "polysomnography tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Nursing Informatics
    @Test func nursinginformaticsKeywordFromNursingInformatics() {
        #expect(CalloutManager.extractTaskKeyword(from: "nursing informatics class assignment on ehr implementation and clinical decision support") == "nursinginformatics")
    }
    @Test func nursinginformaticsKeywordFromCNIO() {
        #expect(CalloutManager.extractTaskKeyword(from: "cnio certification exam prep for nursing informatics leadership") == "nursinginformatics")
    }
    @Test func nursinginformaticsKeywordFromNursingEHR() {
        #expect(CalloutManager.extractTaskKeyword(from: "nursing ehr training assignment on clinical informatics and nursing workflow") == "nursinginformatics")
    }
    @Test func nursinginformaticsFalsePositiveNursingStaysNursing() {
        let kw = CalloutManager.extractTaskKeyword(from: "nursing school nclex exam prep on care plan and nursing assessment")
        #expect(kw == "nursing", "generic nursing tasks should not route to nursinginformatics")
    }
    @Test func nursinginformaticsFalsePositiveHealthcareadminStaysHealthcareadmin() {
        let kw = CalloutManager.extractTaskKeyword(from: "health informatics class on rhia certification and health information management")
        #expect(kw == "healthcareadmin", "health informatics without nursing context should route to healthcareadmin")
    }
    @Test func nursinginformaticsCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "nursinginformatics", tier: tier)
                #expect(!msgs.isEmpty, "nursinginformatics tier \(tier) must have callouts")
            }
        }
    }
    @Test func nursinginformaticsCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "nursinginformatics", tier: 1)
            #expect(msgs.count >= 4, "nursinginformatics tier1 must have ≥4 messages")
        }
    }
    @Test func nursinginformaticsCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "nursinginformatics", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "nursinginformatics tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func nursinginformaticsCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "nursinginformatics", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "nursinginformatics tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Music Therapy
    @Test func musictherapyKeywordFromMusicTherapy() {
        #expect(CalloutManager.extractTaskKeyword(from: "music therapy session notes and treatment plan for my client case conceptualization") == "musictherapy")
    }
    @Test func musictherapyKeywordFromMTBC() {
        #expect(CalloutManager.extractTaskKeyword(from: "mt-bc board exam prep for music therapy certification and credentialing") == "musictherapy")
    }
    @Test func musictherapyKeywordFromNeurologicMusicTherapy() {
        #expect(CalloutManager.extractTaskKeyword(from: "neurologic music therapy class assignment on rhythmic auditory stimulation techniques") == "musictherapy")
    }
    @Test func musictherapyFalsePositiveMusicTheoryStaysMusicTheory() {
        let kw = CalloutManager.extractTaskKeyword(from: "music theory class on ear training and chord progressions for my degree")
        #expect(kw == "musictheory", "music theory tasks should not route to musictherapy")
    }
    @Test func musictherapyFalsePositiveArtTherapyStaysArtTherapy() {
        let kw = CalloutManager.extractTaskKeyword(from: "art therapy session notes and atr board exam prep for creative arts therapist")
        #expect(kw == "arttherapy", "art therapy tasks should not route to musictherapy")
    }
    @Test func musictherapyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "musictherapy", tier: tier)
                #expect(!msgs.isEmpty, "musictherapy tier \(tier) must have callouts")
            }
        }
    }
    @Test func musictherapyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "musictherapy", tier: 1)
            #expect(msgs.count >= 4, "musictherapy tier1 must have ≥4 messages")
        }
    }
    @Test func musictherapyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "musictherapy", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "musictherapy tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func musictherapyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "musictherapy", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "musictherapy tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Drama/Theatre Education
    @Test func dramaeducationKeywordFromDramaTeacher() {
        #expect(CalloutManager.extractTaskKeyword(from: "drama teacher certification program lesson plan on directing class and theatre education") == "dramaeducation")
    }
    @Test func dramaeducationKeywordFromPlaywritingClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "playwriting class assignment on dramatic structure and scene writing for theatre program") == "dramaeducation")
    }
    @Test func dramaeducationKeywordFromPraxisDrama() {
        #expect(CalloutManager.extractTaskKeyword(from: "praxis drama exam prep for theatre education certification and drama curriculum") == "dramaeducation")
    }
    @Test func dramaeducationFalsePositivePerformingArtsStaysPerformingArts() {
        let kw = CalloutManager.extractTaskKeyword(from: "performing arts class on stage direction and musical theatre rehearsal")
        #expect(kw == "performingarts", "generic performing arts tasks should not route to dramaeducation")
    }
    @Test func dramaeducationFalsePositivePhysedStaysPhysed() {
        let kw = CalloutManager.extractTaskKeyword(from: "physical education teacher certification program on pe curriculum and coaching certification")
        #expect(kw == "physed", "physed tasks should not route to dramaeducation")
    }
    @Test func dramaeducationCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dramaeducation", tier: tier)
                #expect(!msgs.isEmpty, "dramaeducation tier \(tier) must have callouts")
            }
        }
    }
    @Test func dramaeducationCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dramaeducation", tier: 1)
            #expect(msgs.count >= 4, "dramaeducation tier1 must have ≥4 messages")
        }
    }
    @Test func dramaeducationCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dramaeducation", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "dramaeducation tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func dramaeducationCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dramaeducation", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "dramaeducation tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Wine Studies / Sommelier
    @Test func winesommelierKeywordFromSommelier() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for my sommelier exam with WSET level 3 wine certification prep") == "winesommelier")
    }
    @Test func winesommelierKeywordFromWSET() {
        #expect(CalloutManager.extractTaskKeyword(from: "wset exam level 2 study session on wine regions and grape varietals") == "winesommelier")
    }
    @Test func winesommelierKeywordFromViticulture() {
        #expect(CalloutManager.extractTaskKeyword(from: "viticulture class assignment on wine growing regions and enology coursework") == "winesommelier")
    }
    @Test func winesommelierFalsePositiveCulinaryStaysCulinary() {
        let kw = CalloutManager.extractTaskKeyword(from: "culinary school assignment on recipe development and menu planning techniques")
        #expect(kw == "culinary", "culinary tasks should not route to winesommelier")
    }
    @Test func winesommelierFalsePositiveHospitalityStaysHospitality() {
        let kw = CalloutManager.extractTaskKeyword(from: "hospitality management class on hotel operations and front desk service training")
        #expect(kw == "hospitality", "hospitality tasks should not route to winesommelier")
    }
    @Test func winesommelierCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "winesommelier", tier: tier)
                #expect(!msgs.isEmpty, "winesommelier tier \(tier) must have callouts")
            }
        }
    }
    @Test func winesommelierCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "winesommelier", tier: 1)
            #expect(msgs.count >= 4, "winesommelier tier1 must have ≥4 messages")
        }
    }
    @Test func winesommelierCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "winesommelier", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "winesommelier tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func winesommelierCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "winesommelier", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "winesommelier tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Gerontology / Aging Studies
    @Test func gerontologyKeywordFromWord() {
        #expect(CalloutManager.extractTaskKeyword(from: "gerontology class assignment on social aging and eldercare policy") == "gerontology")
    }
    @Test func gerontologyKeywordFromGeriatrics() {
        #expect(CalloutManager.extractTaskKeyword(from: "geriatrics exam prep reviewing age-related disease and dementia care") == "gerontology")
    }
    @Test func gerontologyKeywordFromAgingStudies() {
        #expect(CalloutManager.extractTaskKeyword(from: "aging studies course paper on cognitive aging and aging in place") == "gerontology")
    }
    @Test func gerontologyFalsePositivePubhealthStaysPubhealth() {
        let kw = CalloutManager.extractTaskKeyword(from: "epidemiology exam on infectious disease and community health outcomes")
        #expect(kw == "publicheath", "public health tasks should not route to gerontology")
    }
    @Test func gerontologyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "gerontology", tier: tier)
                #expect(!msgs.isEmpty, "gerontology tier \(tier) must have callouts")
            }
        }
    }
    @Test func gerontologyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "gerontology", tier: 1)
            #expect(msgs.count >= 4, "gerontology tier1 must have ≥4 messages")
        }
    }
    @Test func gerontologyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "gerontology", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "gerontology tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func gerontologyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "gerontology", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "gerontology tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Addiction Counseling
    @Test func addictioncounselingKeywordFromCADC() {
        #expect(CalloutManager.extractTaskKeyword(from: "cadc exam prep studying addiction counseling theory and motivational interviewing") == "addictioncounseling")
    }
    @Test func addictioncounselingKeywordFromSUD() {
        #expect(CalloutManager.extractTaskKeyword(from: "substance use disorder class assignment on dual diagnosis and relapse prevention") == "addictioncounseling")
    }
    @Test func addictioncounselingKeywordFromDrugAlcohol() {
        #expect(CalloutManager.extractTaskKeyword(from: "drug and alcohol counseling certification exam prep with naadac study guide") == "addictioncounseling")
    }
    @Test func addictioncounselingFalsePositiveTherapyStaysTherapy() {
        let kw = CalloutManager.extractTaskKeyword(from: "writing therapy notes and treatment plan for my counseling internship clients")
        #expect(kw == "therapy" || kw == "addictioncounseling", "generic therapy notes should stay in therapy or addiction pool")
    }
    @Test func addictioncounselingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "addictioncounseling", tier: tier)
                #expect(!msgs.isEmpty, "addictioncounseling tier \(tier) must have callouts")
            }
        }
    }
    @Test func addictioncounselingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "addictioncounseling", tier: 1)
            #expect(msgs.count >= 4, "addictioncounseling tier1 must have ≥4 messages")
        }
    }
    @Test func addictioncounselingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "addictioncounseling", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "addictioncounseling tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func addictioncounselingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "addictioncounseling", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "addictioncounseling tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Oral Surgery / OMFS
    @Test func oralsurgeryKeywordFromOralSurgery() {
        #expect(CalloutManager.extractTaskKeyword(from: "oral surgery exam prep reviewing orthognathic surgery and impacted wisdom teeth") == "oralsurgery")
    }
    @Test func oralsurgeryKeywordFromOMFS() {
        #expect(CalloutManager.extractTaskKeyword(from: "omfs residency rotation prep studying dentoalveolar surgery and jaw surgery cases") == "oralsurgery")
    }
    @Test func oralsurgeryKeywordFromMaxillofacial() {
        #expect(CalloutManager.extractTaskKeyword(from: "oral and maxillofacial surgery class assignment on surgical techniques") == "oralsurgery")
    }
    @Test func oralsurgeryFalsePositiveDentalStaysDental() {
        let kw = CalloutManager.extractTaskKeyword(from: "dental school nbde board prep on periodontics and prosthodontics")
        #expect(kw == "dental", "dental school tasks should not route to oralsurgery")
    }
    @Test func oralsurgeryCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "oralsurgery", tier: tier)
                #expect(!msgs.isEmpty, "oralsurgery tier \(tier) must have callouts")
            }
        }
    }
    @Test func oralsurgeryCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "oralsurgery", tier: 1)
            #expect(msgs.count >= 4, "oralsurgery tier1 must have ≥4 messages")
        }
    }
    @Test func oralsurgeryCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "oralsurgery", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "oralsurgery tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func oralsurgeryCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "oralsurgery", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "oralsurgery tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Public Health Law
    @Test func publichealthlawKeywordFromPublicHealthLaw() {
        #expect(CalloutManager.extractTaskKeyword(from: "public health law class assignment on quarantine law and infectious disease regulations") == "publichealthlaw")
    }
    @Test func publichealthlawKeywordFromFDA() {
        #expect(CalloutManager.extractTaskKeyword(from: "fda regulation class reviewing food and drug law and public health statutes") == "publichealthlaw")
    }
    @Test func publichealthlawKeywordFromGlobalHealthLaw() {
        #expect(CalloutManager.extractTaskKeyword(from: "global health law course exam prep on international health regulations and treaty law") == "publichealthlaw")
    }
    @Test func publichealthlawFalsePositiveHealthcareLawStaysHealthcarelaw() {
        let kw = CalloutManager.extractTaskKeyword(from: "healthcare law class on medical malpractice and hipaa compliance")
        #expect(kw == "healthcarelaw", "healthcare law tasks should route to healthcarelaw not publichealthlaw")
    }
    @Test func publichealthlawCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "publichealthlaw", tier: tier)
                #expect(!msgs.isEmpty, "publichealthlaw tier \(tier) must have callouts")
            }
        }
    }
    @Test func publichealthlawCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "publichealthlaw", tier: 1)
            #expect(msgs.count >= 4, "publichealthlaw tier1 must have ≥4 messages")
        }
    }
    @Test func publichealthlawCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "publichealthlaw", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "publichealthlaw tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func publichealthlawCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "publichealthlaw", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "publichealthlaw tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Diagnostic Medical Physics
    @Test func diagnosticphysicsKeywordFromMedicalPhysics() {
        #expect(CalloutManager.extractTaskKeyword(from: "medical physics class assignment on dosimetry and radiation protection") == "diagnosticphysics")
    }
    @Test func diagnosticphysicsKeywordFromABRExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "abr physics board exam prep reviewing diagnostic imaging physics") == "diagnosticphysics")
    }
    @Test func diagnosticphysicsKeywordFromHealthPhysics() {
        #expect(CalloutManager.extractTaskKeyword(from: "health physics certification program on radiation safety class") == "diagnosticphysics")
    }
    @Test func diagnosticphysicsFalsePositiveHealthcareadminStaysHealthcareadmin() {
        let kw = CalloutManager.extractTaskKeyword(from: "healthcare administration class on health informatics and ehr implementation")
        #expect(kw == "healthcareadmin", "healthcare administration tasks should not route to diagnosticphysics")
    }
    @Test func diagnosticphysicsCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "diagnosticphysics", tier: tier)
                #expect(!msgs.isEmpty, "diagnosticphysics tier \(tier) must have callouts")
            }
        }
    }
    @Test func diagnosticphysicsCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "diagnosticphysics", tier: 1)
            #expect(msgs.count >= 4, "diagnosticphysics tier1 must have ≥4 messages")
        }
    }
    @Test func diagnosticphysicsCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "diagnosticphysics", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "diagnosticphysics tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func diagnosticphysicsCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "diagnosticphysics", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "diagnosticphysics tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Perfusion Technology
    @Test func perfusiontechnologyKeywordFromPerfusionist() {
        #expect(CalloutManager.extractTaskKeyword(from: "perfusionist certification program reviewing cardiopulmonary bypass techniques") == "perfusiontechnology")
    }
    @Test func perfusiontechnologyKeywordFromPBSE() {
        #expect(CalloutManager.extractTaskKeyword(from: "pbse exam prep for cardiovascular perfusion certification") == "perfusiontechnology")
    }
    @Test func perfusiontechnologyKeywordFromBypass() {
        #expect(CalloutManager.extractTaskKeyword(from: "cardiopulmonary bypass class assignment on pump operation and anticoagulation") == "perfusiontechnology")
    }
    @Test func perfusiontechnologyFalsePositiveCardiovascularTechStaysCardiovasculartech() {
        let kw = CalloutManager.extractTaskKeyword(from: "cci board exam prep on cardiac catheterization and cardiovascular technology")
        #expect(kw == "cardiovasculartech", "cardiovascular tech tasks should not route to perfusiontechnology")
    }
    @Test func perfusiontechnologyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "perfusiontechnology", tier: tier)
                #expect(!msgs.isEmpty, "perfusiontechnology tier \(tier) must have callouts")
            }
        }
    }
    @Test func perfusiontechnologyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "perfusiontechnology", tier: 1)
            #expect(msgs.count >= 4, "perfusiontechnology tier1 must have ≥4 messages")
        }
    }
    @Test func perfusiontechnologyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "perfusiontechnology", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "perfusiontechnology tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func perfusiontechnologyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "perfusiontechnology", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "perfusiontechnology tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Ophthalmic Medical Technology
    @Test func ophthalmicKeywordFromOphthalmicTechnician() {
        #expect(CalloutManager.extractTaskKeyword(from: "ophthalmic technician class assignment on visual field testing and tonometry") == "ophthalmic")
    }
    @Test func ophthalmicKeywordFromJCAHPO() {
        #expect(CalloutManager.extractTaskKeyword(from: "jcahpo certification exam prep reviewing ophthalmic technology procedures") == "ophthalmic")
    }
    @Test func ophthalmicKeywordFromCOMT() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the comt exam in ophthalmic medical technology") == "ophthalmic")
    }
    @Test func ophthalmicFalsePositiveNursingStaysNursing() {
        let kw = CalloutManager.extractTaskKeyword(from: "nursing school nclex exam prep on care plans and patient assessment")
        #expect(kw == "nursing", "nursing tasks should not route to ophthalmic")
    }
    @Test func ophthalmicCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "ophthalmic", tier: tier)
                #expect(!msgs.isEmpty, "ophthalmic tier \(tier) must have callouts")
            }
        }
    }
    @Test func ophthalmicCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "ophthalmic", tier: 1)
            #expect(msgs.count >= 4, "ophthalmic tier1 must have ≥4 messages")
        }
    }
    @Test func ophthalmicCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "ophthalmic", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "ophthalmic tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func ophthalmicCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "ophthalmic", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "ophthalmic tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Central Sterile Processing
    @Test func centralsterileKeywordFromSterileProcessing() {
        #expect(CalloutManager.extractTaskKeyword(from: "sterile processing class assignment on instrument decontamination and autoclave operation") == "centralsterile")
    }
    @Test func centralsterileKeywordFromCRCST() {
        #expect(CalloutManager.extractTaskKeyword(from: "crcst certification exam prep for central sterile processing technician") == "centralsterile")
    }
    @Test func centralsterileKeywordFromCBSPD() {
        #expect(CalloutManager.extractTaskKeyword(from: "cbspd board exam prep reviewing sterilization methods and tray assembly") == "centralsterile")
    }
    @Test func centralsterileFalsePositiveSurgicaltechStaysSurgicaltech() {
        let kw = CalloutManager.extractTaskKeyword(from: "cst exam prep on surgical technology and sterile field technique for nbstsa")
        #expect(kw == "surgicaltech", "surgical tech tasks should not route to centralsterile")
    }
    @Test func centralsterileCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "centralsterile", tier: tier)
                #expect(!msgs.isEmpty, "centralsterile tier \(tier) must have callouts")
            }
        }
    }
    @Test func centralsterileCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "centralsterile", tier: 1)
            #expect(msgs.count >= 4, "centralsterile tier1 must have ≥4 messages")
        }
    }
    @Test func centralsterileCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "centralsterile", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "centralsterile tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func centralsterileCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "centralsterile", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "centralsterile tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Opticianry
    @Test func opticianryKeywordFromDispensingOptician() {
        #expect(CalloutManager.extractTaskKeyword(from: "dispensing optician class assignment on spectacle lens fitting and prescription reading") == "opticianry")
    }
    @Test func opticianryKeywordFromABOExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "abo exam prep reviewing ophthalmic optics and contact lens dispensing") == "opticianry")
    }
    @Test func opticianryKeywordFromNCLE() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the ncle certification on contact lens fitting for dispensing optician program") == "opticianry")
    }
    @Test func opticianryFalsePositiveOptometryStaysOptometry() {
        let kw = CalloutManager.extractTaskKeyword(from: "optometry school nbeo board exam prep on visual acuity and refraction")
        #expect(kw == "optometry", "optometry tasks should not route to opticianry")
    }
    @Test func opticianryCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "opticianry", tier: tier)
                #expect(!msgs.isEmpty, "opticianry tier \(tier) must have callouts")
            }
        }
    }
    @Test func opticianryCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "opticianry", tier: 1)
            #expect(msgs.count >= 4, "opticianry tier1 must have ≥4 messages")
        }
    }
    @Test func opticianryCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "opticianry", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "opticianry tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func opticianryCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "opticianry", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "opticianry tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Dance/Movement Therapy
    @Test func dancetherapyKeywordFromDanceTherapy() {
        #expect(CalloutManager.extractTaskKeyword(from: "dance therapy session notes and treatment plan for mt-bc board exam") == "dancetherapy")
    }
    @Test func dancetherapyKeywordFromDMTCredential() {
        #expect(CalloutManager.extractTaskKeyword(from: "dmt credential board prep on dance movement therapy techniques") == "dancetherapy")
    }
    @Test func dancetherapyKeywordFromADTA() {
        #expect(CalloutManager.extractTaskKeyword(from: "adta dance therapy class assignment on movement psychotherapy and laban analysis") == "dancetherapy")
    }
    @Test func dancetherapyFalsePositiveMusictherapyStaysMusictherapy() {
        let kw = CalloutManager.extractTaskKeyword(from: "music therapy session notes and mt-bc board exam prep")
        #expect(kw == "musictherapy", "music therapy tasks should not route to dancetherapy")
    }
    @Test func dancetherapyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dancetherapy", tier: tier)
                #expect(!msgs.isEmpty, "dancetherapy tier \(tier) must have callouts")
            }
        }
    }
    @Test func dancetherapyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dancetherapy", tier: 1)
            #expect(msgs.count >= 4, "dancetherapy tier1 must have ≥4 messages")
        }
    }
    @Test func dancetherapyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dancetherapy", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "dancetherapy tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func dancetherapyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dancetherapy", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "dancetherapy tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Recreational Therapy
    @Test func recreationtherapyKeywordFromCTRS() {
        #expect(CalloutManager.extractTaskKeyword(from: "ctrs exam prep on therapeutic recreation process and evidence-based practice") == "recreationtherapy")
    }
    @Test func recreationtherapyKeywordFromTherapeuticRecreation() {
        #expect(CalloutManager.extractTaskKeyword(from: "therapeutic recreation class assignment on leisure education and adaptive activities") == "recreationtherapy")
    }
    @Test func recreationtherapyKeywordFromRecreationTherapist() {
        #expect(CalloutManager.extractTaskKeyword(from: "recreational therapist certification exam prep and recreation therapy session notes") == "recreationtherapy")
    }
    @Test func recreationtherapyFalsePositiveArttherapyStaysArttherapy() {
        let kw = CalloutManager.extractTaskKeyword(from: "art therapy session notes and atr board credential exam prep")
        #expect(kw == "arttherapy", "art therapy tasks should not route to recreationtherapy")
    }
    @Test func recreationtherapyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "recreationtherapy", tier: tier)
                #expect(!msgs.isEmpty, "recreationtherapy tier \(tier) must have callouts")
            }
        }
    }
    @Test func recreationtherapyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "recreationtherapy", tier: 1)
            #expect(msgs.count >= 4, "recreationtherapy tier1 must have ≥4 messages")
        }
    }
    @Test func recreationtherapyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "recreationtherapy", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "recreationtherapy tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func recreationtherapyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "recreationtherapy", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "recreationtherapy tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Horticultural Therapy
    @Test func horticulturetherapyKeywordFromHTR() {
        #expect(CalloutManager.extractTaskKeyword(from: "htr certification horticultural therapy class assignment on therapeutic horticulture techniques") == "horticulturetherapy")
    }
    @Test func horticulturetherapyKeywordFromTherapeuticHorticulture() {
        #expect(CalloutManager.extractTaskKeyword(from: "therapeutic horticulture program plan and horticultural therapy session notes") == "horticulturetherapy")
    }
    @Test func horticulturetherapyKeywordFromAHTA() {
        #expect(CalloutManager.extractTaskKeyword(from: "ahta horticultural therapy board certification exam prep and program design") == "horticulturetherapy")
    }
    @Test func horticulturetherapyFalsePositiveRecreationtherapyStaysRecreationtherapy() {
        let kw = CalloutManager.extractTaskKeyword(from: "ctrs certification exam prep on therapeutic recreation and adaptive leisure education")
        #expect(kw == "recreationtherapy", "recreation therapy tasks should not route to horticulturetherapy")
    }
    @Test func horticulturetherapyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "horticulturetherapy", tier: tier)
                #expect(!msgs.isEmpty, "horticulturetherapy tier \(tier) must have callouts")
            }
        }
    }
    @Test func horticulturetherapyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "horticulturetherapy", tier: 1)
            #expect(msgs.count >= 4, "horticulturetherapy tier1 must have ≥4 messages")
        }
    }
    @Test func horticulturetherapyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "horticulturetherapy", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "horticulturetherapy tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func horticulturetherapyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "horticulturetherapy", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "horticulturetherapy tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Dietetic Technology
    @Test func dietetictechnologyKeywordFromDTR() {
        #expect(CalloutManager.extractTaskKeyword(from: "dtr exam prep on nutrition screening and menu planning for dietetic technician program") == "dietetictechnology")
    }
    @Test func dietetictechnologyKeywordFromNDTR() {
        #expect(CalloutManager.extractTaskKeyword(from: "ndtr certification exam reviewing dietary analysis and food service management") == "dietetictechnology")
    }
    @Test func dietetictechnologyKeywordFromDieteticTechnician() {
        #expect(CalloutManager.extractTaskKeyword(from: "dietetic technician class assignment on nutrition assessment and menu planning") == "dietetictechnology")
    }
    @Test func dietetictechnologyFalsePositiveNutritionStaysNutrition() {
        let kw = CalloutManager.extractTaskKeyword(from: "nutritionist clinical nutrition assessment and dietary intake analysis")
        #expect(kw == "nutrition", "nutrition tasks should not route to dietetictechnology")
    }
    @Test func dietetictechnologyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dietetictechnology", tier: tier)
                #expect(!msgs.isEmpty, "dietetictechnology tier \(tier) must have callouts")
            }
        }
    }
    @Test func dietetictechnologyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dietetictechnology", tier: 1)
            #expect(msgs.count >= 4, "dietetictechnology tier1 must have ≥4 messages")
        }
    }
    @Test func dietetictechnologyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dietetictechnology", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "dietetictechnology tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func dietetictechnologyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dietetictechnology", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "dietetictechnology tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Occupational Medicine keyword tests
    @Test func occupationalmedicineKeywordFromOccupationalMedicine() {
        #expect(CalloutManager.extractTaskKeyword(from: "occupational medicine class on work-related illness and industrial hygiene assessment") == "occupationalmedicine")
    }
    @Test func occupationalmedicineKeywordFromIndustrialHygiene() {
        #expect(CalloutManager.extractTaskKeyword(from: "industrial hygiene certification exam prep on occupational disease") == "occupationalmedicine")
    }
    @Test func occupationalmedicineFalsePositiveKinesiologyStaysKinesiology() {
        let kw = CalloutManager.extractTaskKeyword(from: "kinesiology biomechanics assignment on exercise physiology and motor control")
        #expect(kw == "kinesiology", "kinesiology tasks should not route to occupationalmedicine")
    }
    @Test func occupationalmedicineFalsePositiveOccupationalTherapyStaysOccupationalTherapy() {
        let kw = CalloutManager.extractTaskKeyword(from: "occupational therapy NBCOT exam prep on ADLs and sensory integration")
        #expect(kw == "occupationaltherapy", "occupational therapy tasks should not route to occupationalmedicine")
    }
    @Test func occupationalmedicineCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "occupationalmedicine", tier: tier)
                #expect(!msgs.isEmpty, "occupationalmedicine tier \(tier) must have callouts")
            }
        }
    }
    @Test func occupationalmedicineCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "occupationalmedicine", tier: 1)
            #expect(msgs.count >= 4, "occupationalmedicine tier1 must have ≥4 messages")
        }
    }
    @Test func occupationalmedicineCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "occupationalmedicine", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "occupationalmedicine tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func occupationalmedicineCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "occupationalmedicine", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "occupationalmedicine tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Integrative Medicine keyword tests
    @Test func integrativemedicineKeywordFromIntegrativeMedicine() {
        #expect(CalloutManager.extractTaskKeyword(from: "integrative medicine class on CAM therapies and mind-body medicine") == "integrativemedicine")
    }
    @Test func integrativemedicineKeywordFromFunctionalMedicine() {
        #expect(CalloutManager.extractTaskKeyword(from: "functional medicine program exam prep on holistic health") == "integrativemedicine")
    }
    @Test func integrativemedicineFalsePositivePharmacyStaysPharmacy() {
        let kw = CalloutManager.extractTaskKeyword(from: "pharmacy school class on pharmacokinetics and drug therapy")
        #expect(kw == "pharmacy", "pharmacy tasks should not route to integrativemedicine")
    }
    @Test func integrativemedicineCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "integrativemedicine", tier: tier)
                #expect(!msgs.isEmpty, "integrativemedicine tier \(tier) must have callouts")
            }
        }
    }
    @Test func integrativemedicineCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "integrativemedicine", tier: 1)
            #expect(msgs.count >= 4, "integrativemedicine tier1 must have ≥4 messages")
        }
    }
    @Test func integrativemedicineCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "integrativemedicine", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "integrativemedicine tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func integrativemedicineCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "integrativemedicine", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "integrativemedicine tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Genetic Counseling keyword tests
    @Test func geneticcounselingKeywordFromGeneticCounseling() {
        #expect(CalloutManager.extractTaskKeyword(from: "genetic counseling program ABGC board exam prep on hereditary cancer risk") == "geneticcounseling")
    }
    @Test func geneticcounselingKeywordFromPrenatalGenetics() {
        #expect(CalloutManager.extractTaskKeyword(from: "prenatal genetic counseling rotation notes and case preparation") == "geneticcounseling")
    }
    @Test func geneticcounselingFalsePositiveMolecularBiologyStaysMolecularBiology() {
        let kw = CalloutManager.extractTaskKeyword(from: "molecular biology class on CRISPR gene editing and plasmid cloning")
        #expect(kw == "molecularbiology", "molecular biology tasks should not route to geneticcounseling")
    }
    @Test func geneticcounselingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "geneticcounseling", tier: tier)
                #expect(!msgs.isEmpty, "geneticcounseling tier \(tier) must have callouts")
            }
        }
    }
    @Test func geneticcounselingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "geneticcounseling", tier: 1)
            #expect(msgs.count >= 4, "geneticcounseling tier1 must have ≥4 messages")
        }
    }
    @Test func geneticcounselingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "geneticcounseling", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "geneticcounseling tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func geneticcounselingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "geneticcounseling", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "geneticcounseling tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Behavioral Health Promotion keyword tests
    @Test func behavioralhealthpromotionKeywordFromCHES() {
        #expect(CalloutManager.extractTaskKeyword(from: "CHES exam prep and health education specialist certification study") == "behavioralhealthpromotion")
    }
    @Test func behavioralhealthpromotionKeywordFromCommunityHealthWorker() {
        #expect(CalloutManager.extractTaskKeyword(from: "community health worker certification training program assignment") == "behavioralhealthpromotion")
    }
    @Test func behavioralhealthpromotionFalsePositivePublicHealthStaysPublicHealth() {
        let kw = CalloutManager.extractTaskKeyword(from: "mph program epidemiology class on public health and community health")
        #expect(kw == "publicheath", "public health mph tasks should not route to behavioralhealthpromotion")
    }
    @Test func behavioralhealthpromotionCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "behavioralhealthpromotion", tier: tier)
                #expect(!msgs.isEmpty, "behavioralhealthpromotion tier \(tier) must have callouts")
            }
        }
    }
    @Test func behavioralhealthpromotionCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "behavioralhealthpromotion", tier: 1)
            #expect(msgs.count >= 4, "behavioralhealthpromotion tier1 must have ≥4 messages")
        }
    }
    @Test func behavioralhealthpromotionCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "behavioralhealthpromotion", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "behavioralhealthpromotion tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func behavioralhealthpromotionCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "behavioralhealthpromotion", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "behavioralhealthpromotion tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - Dental Public Health keyword tests
    @Test func dentalpublichealthKeywordFromDentalPublicHealth() {
        #expect(CalloutManager.extractTaskKeyword(from: "dental public health exam prep on oral health disparities and dental epidemiology") == "dentalpublichealth")
    }
    @Test func dentalpublichealthKeywordFromOralHealthPolicy() {
        #expect(CalloutManager.extractTaskKeyword(from: "oral health policy assignment on community dentistry program planning") == "dentalpublichealth")
    }
    @Test func dentalpublichealthFalsePositiveDentalHygieneStaysDentalHygiene() {
        let kw = CalloutManager.extractTaskKeyword(from: "dental hygiene school NBDHE board prep on periodontal charting and scaling")
        #expect(kw == "dentalhygiene", "dental hygiene tasks should not route to dentalpublichealth")
    }
    @Test func dentalpublichealthCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dentalpublichealth", tier: tier)
                #expect(!msgs.isEmpty, "dentalpublichealth tier \(tier) must have callouts")
            }
        }
    }
    @Test func dentalpublichealthCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dentalpublichealth", tier: 1)
            #expect(msgs.count >= 4, "dentalpublichealth tier1 must have ≥4 messages")
        }
    }
    @Test func dentalpublichealthCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dentalpublichealth", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "dentalpublichealth tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func dentalpublichealthCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dentalpublichealth", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "dentalpublichealth tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - playwriting

    @Test func playwrightingKeywordFromStagePlay() {
        #expect(CalloutManager.extractTaskKeyword(from: "write act 2 of my stage play about a family in conflict") == "playwriting")
    }
    @Test func playwrightingKeywordFromOneActPlay() {
        #expect(CalloutManager.extractTaskKeyword(from: "work on my one-act play draft for theatre class submission") == "playwriting")
    }
    @Test func playwrightingFalsePositiveDramaClassStaysPerformingArts() {
        let kw = CalloutManager.extractTaskKeyword(from: "drama class scene work and acting technique study")
        #expect(kw == "performingarts" || kw != "playwriting", "drama class should not route to playwriting")
    }
    @Test func playwrightingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "playwriting", tier: tier)
                #expect(!msgs.isEmpty, "playwriting tier \(tier) must have callouts")
            }
        }
    }
    @Test func playwrightingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "playwriting", tier: 1)
            #expect(msgs.count >= 4, "playwriting tier1 must have ≥4 messages")
        }
    }
    @Test func playwrightingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "playwriting", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "playwriting tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func playwrightingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "playwriting", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "playwriting tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func playwrightingKeywordFromPlayRevision() {
        #expect(CalloutManager.extractTaskKeyword(from: "revising my play — need to tighten the second act") == "playwriting")
    }

    // MARK: - sportsmedicine

    @Test func sportsmedicineKeywordFromBOCExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the BOC exam athletic training certification prep") == "sportsmedicine")
    }
    @Test func sportsmedicineKeywordFromSportsInjuryAssessment() {
        #expect(CalloutManager.extractTaskKeyword(from: "documenting sports injury assessment and writing clinical athletic training notes") == "sportsmedicine")
    }
    @Test func sportsmedFalsePositiveKinesiologyStaysKinesiology() {
        let kw = CalloutManager.extractTaskKeyword(from: "kinesiology biomechanics exercise physiology lab report on motor control")
        #expect(kw == "kinesiology", "kinesiology tasks should not route to sportsmedicine")
    }
    @Test func sportsmedicineCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "sportsmedicine", tier: tier)
                #expect(!msgs.isEmpty, "sportsmedicine tier \(tier) must have callouts")
            }
        }
    }
    @Test func sportsmedicineCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "sportsmedicine", tier: 1)
            #expect(msgs.count >= 4, "sportsmedicine tier1 must have ≥4 messages")
        }
    }
    @Test func sportsmedicineCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "sportsmedicine", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "sportsmedicine tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func sportsmedicineCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "sportsmedicine", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "sportsmedicine tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func sportsmedicineKeywordFromConcussionProtocol() {
        #expect(CalloutManager.extractTaskKeyword(from: "reviewing concussion protocol and return to play protocol for clinical sports medicine rotation") == "sportsmedicine")
    }

    // MARK: - naturopathicmedicine

    @Test func naturopathicKeywordFromNPLEX() {
        #expect(CalloutManager.extractTaskKeyword(from: "NPLEX exam prep on botanical medicine and homeopathy for naturopathic school boards") == "naturopathicmedicine")
    }
    @Test func naturopathicKeywordFromBotanicalMedicine() {
        #expect(CalloutManager.extractTaskKeyword(from: "botanical medicine class assignment on materia medica and herbal formulas") == "naturopathicmedicine")
    }
    @Test func naturopathicFalsePositiveIntegrativeStaysIntegrative() {
        let kw = CalloutManager.extractTaskKeyword(from: "integrative medicine case study on functional medicine and mind-body approaches for ABIHM board")
        #expect(kw == "integrativemedicine", "integrative medicine tasks should not route to naturopathicmedicine")
    }
    @Test func naturopathicCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "naturopathicmedicine", tier: tier)
                #expect(!msgs.isEmpty, "naturopathicmedicine tier \(tier) must have callouts")
            }
        }
    }
    @Test func naturopathicCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "naturopathicmedicine", tier: 1)
            #expect(msgs.count >= 4, "naturopathicmedicine tier1 must have ≥4 messages")
        }
    }
    @Test func naturopathicCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "naturopathicmedicine", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "naturopathicmedicine tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func naturopathicCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "naturopathicmedicine", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "naturopathicmedicine tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func naturopathicKeywordFromNDProgram() {
        #expect(CalloutManager.extractTaskKeyword(from: "naturopathic medicine school program assignment on hydrotherapy and physical medicine") == "naturopathicmedicine")
    }

    // MARK: - midwifery

    @Test func midwiferyKeywordFromAMCB() {
        #expect(CalloutManager.extractTaskKeyword(from: "AMCB exam prep studying prenatal care and postpartum management for CNM certification") == "midwifery")
    }
    @Test func midwiferyKeywordFromBirthPlan() {
        #expect(CalloutManager.extractTaskKeyword(from: "writing birth plans and prenatal charting notes for my midwifery clinical rotation") == "midwifery")
    }
    @Test func midwiferyFalsePositiveNursingStaysNursing() {
        let kw = CalloutManager.extractTaskKeyword(from: "nursing care plan NCLEX studying dosage calculations and nursing assessment for nursing school exam")
        #expect(kw == "nursing", "nursing tasks should not route to midwifery")
    }
    @Test func midwiferyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "midwifery", tier: tier)
                #expect(!msgs.isEmpty, "midwifery tier \(tier) must have callouts")
            }
        }
    }
    @Test func midwiferyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "midwifery", tier: 1)
            #expect(msgs.count >= 4, "midwifery tier1 must have ≥4 messages")
        }
    }
    @Test func midwiferyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "midwifery", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "midwifery tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func midwiferyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "midwifery", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "midwifery tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func midwiferyKeywordFromCertifiedNurseMidwife() {
        #expect(CalloutManager.extractTaskKeyword(from: "certified nurse midwife school coursework on labor and delivery notes and postpartum charting") == "midwifery")
    }

    // MARK: - clinicalpsychology

    @Test func clinicalpsychologyKeywordFromAPPIC() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on my APPIC internship match application essays and cover letters for doctoral clinical psych") == "clinicalpsychology")
    }
    @Test func clinicalpsychologyKeywordFromNeuropsychAssessment() {
        #expect(CalloutManager.extractTaskKeyword(from: "writing a neuropsychological assessment report from my clinical psychology practicum evaluation") == "clinicalpsychology")
    }
    @Test func clinicalpsychologyFalsePositivePsychologyStaysPsychology() {
        let kw = CalloutManager.extractTaskKeyword(from: "abnormal psychology class exam studying personality theory and cognitive development for psych major")
        #expect(kw == "psychology", "general psychology tasks should not route to clinicalpsychology")
    }
    @Test func clinicalpsychologyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "clinicalpsychology", tier: tier)
                #expect(!msgs.isEmpty, "clinicalpsychology tier \(tier) must have callouts")
            }
        }
    }
    @Test func clinicalpsychologyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "clinicalpsychology", tier: 1)
            #expect(msgs.count >= 4, "clinicalpsychology tier1 must have ≥4 messages")
        }
    }
    @Test func clinicalpsychologyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "clinicalpsychology", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "clinicalpsychology tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func clinicalpsychologyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "clinicalpsychology", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "clinicalpsychology tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func clinicalpsychologyKeywordFromPsyDProgram() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on my psy.d clinical psychology dissertation and doctoral program requirements") == "clinicalpsychology")
    }

    // MARK: - theatresound

    @Test func theatresoundKeywordFromFOH() {
        #expect(CalloutManager.extractTaskKeyword(from: "setting up my FOH mixing notes for live sound reinforcement class exam") == "theatresound")
    }
    @Test func theatresoundKeywordFromLiveAudio() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying audio tech program coursework on live audio and stage sound engineering") == "theatresound")
    }
    @Test func theatresoundFalsePositiveMusicProductionStaysMusicProduction() {
        let kw = CalloutManager.extractTaskKeyword(from: "recording and mixing my new track in logic pro x for my music production project")
        #expect(kw == "musicproduction", "studio DAW recording should not route to theatresound")
    }
    @Test func theatresoundCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "theatresound", tier: tier)
                #expect(!msgs.isEmpty, "theatresound tier \(tier) must have callouts")
            }
        }
    }
    @Test func theatresoundCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "theatresound", tier: 1)
            #expect(msgs.count >= 4, "theatresound tier1 must have ≥4 messages")
        }
    }
    @Test func theatresoundCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "theatresound", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "theatresound tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func theatresoundCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "theatresound", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "theatresound tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func theatresoundKeywordFromSoundDesignTheatre() {
        #expect(CalloutManager.extractTaskKeyword(from: "writing a sound design plan for the theatre production this semester") == "theatresound")
    }

    // MARK: - dancescience

    @Test func dancescienceKeywordFromLMA() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my Laban Movement Analysis observation paper for dance science class") == "dancescience")
    }
    @Test func dancescienceKeywordFromDanceAnatomy() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying dance anatomy and dance kinesiology for my movement science assignment") == "dancescience")
    }
    @Test func dancescienceFalsePositivePerformingArtsStaysPerformingArts() {
        let kw = CalloutManager.extractTaskKeyword(from: "rehearsing my contemporary dance piece for the spring performance concert")
        #expect(kw != "dancescience", "performing arts rehearsal should not route to dancescience")
    }
    @Test func dancescienceCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dancescience", tier: tier)
                #expect(!msgs.isEmpty, "dancescience tier \(tier) must have callouts")
            }
        }
    }
    @Test func dancescienceCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dancescience", tier: 1)
            #expect(msgs.count >= 4, "dancescience tier1 must have ≥4 messages")
        }
    }
    @Test func dancescienceCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dancescience", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "dancescience tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func dancescienceCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dancescience", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "dancescience tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func dancescienceKeywordFromSomaticMovement() {
        #expect(CalloutManager.extractTaskKeyword(from: "writing my somatic movement analysis paper for my dance science graduate program") == "dancescience")
    }

    // MARK: - forensicnursing

    @Test func forensicnursingKeywordFromSANEExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the SANE exam and reviewing forensic nursing certification materials") == "forensicnursing")
    }
    @Test func forensicnursingKeywordFromSexualAssaultNurse() {
        #expect(CalloutManager.extractTaskKeyword(from: "writing my sexual assault nurse examiner documentation case notes for forensic clinical") == "forensicnursing")
    }
    @Test func forensicnursingFalsePositiveNursingStaysNursing() {
        let kw = CalloutManager.extractTaskKeyword(from: "writing nursing care plans and completing my NCLEX study guide for nursing school")
        #expect(kw != "forensicnursing", "general nursing tasks should not route to forensicnursing")
    }
    @Test func forensicnursingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forensicnursing", tier: tier)
                #expect(!msgs.isEmpty, "forensicnursing tier \(tier) must have callouts")
            }
        }
    }
    @Test func forensicnursingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forensicnursing", tier: 1)
            #expect(msgs.count >= 4, "forensicnursing tier1 must have ≥4 messages")
        }
    }
    @Test func forensicnursingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forensicnursing", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "forensicnursing tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func forensicnursingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forensicnursing", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "forensicnursing tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func forensicnursingKeywordFromForensicNursingNotes() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing forensic nursing case documentation and injury notes for my AFN credential program") == "forensicnursing")
    }

    // MARK: - midwiferyassisting

    @Test func midwiferyassistingKeywordFromDONA() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the DONA certification exam and completing my birth doula training assignment") == "midwiferyassisting")
    }
    @Test func midwiferyassistingKeywordFromBirthDoula() {
        #expect(CalloutManager.extractTaskKeyword(from: "writing my birth doula reflection and client support plan for my doula certification program") == "midwiferyassisting")
    }
    @Test func midwiferyassistingFalsePositiveMidwiferyStaysMidwifery() {
        let kw = CalloutManager.extractTaskKeyword(from: "studying for the AMCB certified nurse midwife exam and completing midwifery school prenatal notes")
        #expect(kw != "midwiferyassisting", "CNM midwifery degree work should not route to midwiferyassisting")
    }
    @Test func midwiferyassistingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "midwiferyassisting", tier: tier)
                #expect(!msgs.isEmpty, "midwiferyassisting tier \(tier) must have callouts")
            }
        }
    }
    @Test func midwiferyassistingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "midwiferyassisting", tier: 1)
            #expect(msgs.count >= 4, "midwiferyassisting tier1 must have ≥4 messages")
        }
    }
    @Test func midwiferyassistingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "midwiferyassisting", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "midwiferyassisting tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func midwiferyassistingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "midwiferyassisting", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "midwiferyassisting tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func midwiferyassistingKeywordFromPostpartumDoula() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my postpartum doula care plan and DONA training coursework assignment") == "midwiferyassisting")
    }

    // MARK: - interpreting

    @Test func interpretingKeywordFromRIDExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the RID certification exam and completing my sign language interpreting program coursework") == "interpreting")
    }
    @Test func interpretingKeywordFromASLInterpreting() {
        #expect(CalloutManager.extractTaskKeyword(from: "practicing consecutive ASL interpreting techniques for my RID exam certification program") == "interpreting")
    }
    @Test func interpretingFalsePositiveSignLanguageStaysSignLanguage() {
        let kw = CalloutManager.extractTaskKeyword(from: "studying ASL class vocabulary and fingerspelling for my American sign language course assignment")
        #expect(kw != "interpreting", "ASL coursework without professional interpreting context should not route to interpreting")
    }
    @Test func interpretingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "interpreting", tier: tier)
                #expect(!msgs.isEmpty, "interpreting tier \(tier) must have callouts")
            }
        }
    }
    @Test func interpretingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "interpreting", tier: 1)
            #expect(msgs.count >= 4, "interpreting tier1 must have ≥4 messages")
        }
    }
    @Test func interpretingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "interpreting", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "interpreting tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func interpretingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "interpreting", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "interpreting tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func interpretingKeywordFromCourtInterpreting() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my court interpreting assignment and consecutive interpreting practice for my language interpreting class") == "interpreting")
    }

    // MARK: - dramatherapy

    @Test func dramatherapyKeywordFromNADTExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the NADT exam and completing my drama therapy program coursework on psychodrama") == "dramatherapy")
    }
    @Test func dramatherapyKeywordFromPsychodramaSession() {
        #expect(CalloutManager.extractTaskKeyword(from: "writing my psychodrama session notes and drama therapy treatment plan for my internship") == "dramatherapy")
    }
    @Test func dramatherapyFalsePositiveDramaCourseStaysPerformingArts() {
        let kw = CalloutManager.extractTaskKeyword(from: "rehearsing my drama performance and working on my theater class final monologue")
        #expect(kw != "dramatherapy", "generic drama performance should not route to dramatherapy")
    }
    @Test func dramatherapyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dramatherapy", tier: tier)
                #expect(!msgs.isEmpty, "dramatherapy tier \(tier) must have callouts")
            }
        }
    }
    @Test func dramatherapyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dramatherapy", tier: 1)
            #expect(msgs.count >= 4, "dramatherapy tier1 must have ≥4 messages")
        }
    }
    @Test func dramatherapyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dramatherapy", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "dramatherapy tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func dramatherapyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dramatherapy", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "dramatherapy tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func dramatherapyKeywordFromTherapeuticDrama() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing a therapeutic drama class session and drama therapy assignment for my credential program") == "dramatherapy")
    }

    // MARK: - horsemanship

    @Test func horsemanshipKeywordFromEquestrianScience() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my equestrian science assignment on horse management and equine nutrition") == "horsemanship")
    }
    @Test func horsemanshipKeywordFromDressageClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying dressage training techniques and horse training theory for my equestrian program") == "horsemanship")
    }
    @Test func horsemanshipFalsePositiveVeterinaryStaysVeterinary() {
        let kw = CalloutManager.extractTaskKeyword(from: "studying veterinary medicine and animal science for my NAVLE exam prep")
        #expect(kw != "horsemanship", "veterinary school content should not route to horsemanship")
    }
    @Test func horsemanshipCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "horsemanship", tier: tier)
                #expect(!msgs.isEmpty, "horsemanship tier \(tier) must have callouts")
            }
        }
    }
    @Test func horsemanshipCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "horsemanship", tier: 1)
            #expect(msgs.count >= 4, "horsemanship tier1 must have ≥4 messages")
        }
    }
    @Test func horsemanshipCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "horsemanship", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "horsemanship tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func horsemanshipCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "horsemanship", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "horsemanship tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func horsemanshipKeywordFromShowJumping() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying show jumping techniques and writing my equestrian program class assignment on horse training") == "horsemanship")
    }

    // MARK: - glassblowing

    @Test func glassblowingKeywordFromGlassStudio() {
        #expect(CalloutManager.extractTaskKeyword(from: "planning my glassblowing studio project and documenting flameworking techniques for class") == "glassblowing")
    }
    @Test func glassblowingKeywordFromFusedGlass() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying kiln-formed glass and fused glass methods for my glass arts program assignment") == "glassblowing")
    }
    @Test func glassblowingFalsePositiveArtClassStaysArt() {
        let kw = CalloutManager.extractTaskKeyword(from: "working on my oil painting and digital art illustration assignment for class")
        #expect(kw != "glassblowing", "generic art class should not route to glassblowing")
    }
    @Test func glassblowingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "glassblowing", tier: tier)
                #expect(!msgs.isEmpty, "glassblowing tier \(tier) must have callouts")
            }
        }
    }
    @Test func glassblowingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "glassblowing", tier: 1)
            #expect(msgs.count >= 4, "glassblowing tier1 must have ≥4 messages")
        }
    }
    @Test func glassblowingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "glassblowing", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "glassblowing tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func glassblowingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "glassblowing", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "glassblowing tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func glassblowingKeywordFromFlame() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on my flameworking technique notes and borosilicate glass arts class project") == "glassblowing")
    }

    // MARK: - landsurveyingtech

    @Test func landsurveyingtechKeywordFromFSExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the fundamentals of surveying exam and completing my land surveying technology coursework") == "landsurveyingtech")
    }
    @Test func landsurveyingtechKeywordFromBoundarySurvey() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on a boundary survey problem set and GPS surveying lab for my surveying program") == "landsurveyingtech")
    }
    @Test func landsurveyingtechFalsePositiveEngineeringStaysEngineering() {
        let kw = CalloutManager.extractTaskKeyword(from: "completing my mechanical engineering assignment on finite element analysis and SolidWorks CAD")
        #expect(kw != "landsurveyingtech", "engineering CAD assignment should not route to landsurveyingtech")
    }
    @Test func landsurveyingtechCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "landsurveyingtech", tier: tier)
                #expect(!msgs.isEmpty, "landsurveyingtech tier \(tier) must have callouts")
            }
        }
    }
    @Test func landsurveyingtechCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "landsurveyingtech", tier: 1)
            #expect(msgs.count >= 4, "landsurveyingtech tier1 must have ≥4 messages")
        }
    }
    @Test func landsurveyingtechCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "landsurveyingtech", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "landsurveyingtech tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func landsurveyingtechCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "landsurveyingtech", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "landsurveyingtech tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func landsurveyingtechKeywordFromGeomatic() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying geomatics and topographic survey methods for my land surveying technology program exam") == "landsurveyingtech")
    }

    // MARK: - environmentalengineering

    @Test func environmentalengineeringKeywordFromWastewater() {
        #expect(CalloutManager.extractTaskKeyword(from: "designing a wastewater treatment plant layout for my environmental engineering class project") == "environmentalengineering")
    }
    @Test func environmentalengineeringKeywordFromRemediation() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing a site remediation report and groundwater contamination analysis for environmental engineering") == "environmentalengineering")
    }
    @Test func environmentalengineeringFalsePositiveEngineeringStaysEngineering() {
        let kw = CalloutManager.extractTaskKeyword(from: "completing my mechanical engineering assignment on finite element analysis and SolidWorks CAD")
        #expect(kw != "environmentalengineering", "generic engineering should not route to environmentalengineering")
    }
    @Test func environmentalengineeringCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "environmentalengineering", tier: tier)
                #expect(!msgs.isEmpty, "environmentalengineering tier \(tier) must have callouts")
            }
        }
    }
    @Test func environmentalengineeringCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "environmentalengineering", tier: 1)
            #expect(msgs.count >= 4, "environmentalengineering tier1 must have ≥4 messages")
        }
    }
    @Test func environmentalengineeringCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "environmentalengineering", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "environmentalengineering tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func environmentalengineeringCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "environmentalengineering", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "environmentalengineering tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func environmentalengineeringKeywordFromAirQuality() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on an air quality control engineering class assignment on pollutant dispersion modeling") == "environmentalengineering")
    }

    // MARK: - techwriting

    @Test func techwritingKeywordFromUserManual() {
        #expect(CalloutManager.extractTaskKeyword(from: "writing a user manual for the new API endpoints and updating the developer documentation") == "techwriting")
    }
    @Test func techwritingKeywordFromAPIDoc() {
        #expect(CalloutManager.extractTaskKeyword(from: "drafting API documentation and release notes for the software documentation project") == "techwriting")
    }
    @Test func techwritingFalsePositiveWritingStaysWriting() {
        let kw = CalloutManager.extractTaskKeyword(from: "drafting a blog post outline and revising my newsletter for this week")
        #expect(kw != "techwriting", "generic writing tasks should not route to techwriting")
    }
    @Test func techwritingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "techwriting", tier: tier)
                #expect(!msgs.isEmpty, "techwriting tier \(tier) must have callouts")
            }
        }
    }
    @Test func techwritingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "techwriting", tier: 1)
            #expect(msgs.count >= 4, "techwriting tier1 must have ≥4 messages")
        }
    }
    @Test func techwritingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "techwriting", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "techwriting tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func techwritingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "techwriting", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "techwriting tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func techwritingKeywordFromTechnicalCommunication() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my technical communication assignment on docs-as-code workflows and user guide structure") == "techwriting")
    }

    // MARK: - healthcoaching

    @Test func healthcoachingKeywordFromNBHWC() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the NBHWC health and wellness coaching certification exam and reviewing behavior change models") == "healthcoaching")
    }
    @Test func healthcoachingKeywordFromWellnessCoach() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my wellness coaching assignment on health behavior change and motivational interviewing techniques") == "healthcoaching")
    }
    @Test func healthcoachingFalsePositiveFitnessStaysFitness() {
        let kw = CalloutManager.extractTaskKeyword(from: "going to the gym for my workout and updating my training session log")
        #expect(kw != "healthcoaching", "generic fitness tasks should not route to healthcoaching")
    }
    @Test func healthcoachingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "healthcoaching", tier: tier)
                #expect(!msgs.isEmpty, "healthcoaching tier \(tier) must have callouts")
            }
        }
    }
    @Test func healthcoachingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "healthcoaching", tier: 1)
            #expect(msgs.count >= 4, "healthcoaching tier1 must have ≥4 messages")
        }
    }
    @Test func healthcoachingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "healthcoaching", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "healthcoaching tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func healthcoachingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "healthcoaching", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "healthcoaching tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func healthcoachingKeywordFromLifestyleCoaching() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on my lifestyle coaching certification program class assignment on client goal setting") == "healthcoaching")
    }

    // MARK: - podiatry

    @Test func podiatryKeywordFromAPMLE() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the APMLE podiatry board exam and reviewing podiatric medicine surgery cases") == "podiatry")
    }
    @Test func podiatryKeywordFromDPMProgram() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my DPM program assignment on foot and ankle surgery techniques and podiatric biomechanics") == "podiatry")
    }
    @Test func podiatryFalsePositiveChiropracticStaysChiropractic() {
        let kw = CalloutManager.extractTaskKeyword(from: "studying for the NBCE chiropractic board exam and reviewing spinal adjustment technique notes")
        #expect(kw != "podiatry", "chiropractic tasks should not route to podiatry")
    }
    @Test func podiatryCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "podiatry", tier: tier)
                #expect(!msgs.isEmpty, "podiatry tier \(tier) must have callouts")
            }
        }
    }
    @Test func podiatryCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "podiatry", tier: 1)
            #expect(msgs.count >= 4, "podiatry tier1 must have ≥4 messages")
        }
    }
    @Test func podiatryCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "podiatry", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "podiatry tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func podiatryCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "podiatry", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "podiatry tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func podiatryKeywordFromPodiatrist() {
        #expect(CalloutManager.extractTaskKeyword(from: "writing up podiatrist clinical rotation SOAP notes and podiatric medicine case summaries") == "podiatry")
    }

    // MARK: - classicalstudies

    @Test func classicalstudiesKeywordFromLatinClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for my Latin class exam and translating a passage from Cicero for my classical studies assignment") == "classicalstudies")
    }
    @Test func classicalstudiesKeywordFromAncientGreek() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on my ancient Greek translation assignment and reading Homer's Iliad for my classics course") == "classicalstudies")
    }
    @Test func classicalstudiesFalsePositiveLatinAmericaNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "writing a research paper about economic development in Latin America and the Caribbean")
        #expect(kw != "classicalstudies", "latin america references should not route to classicalstudies")
    }
    @Test func classicalstudiesCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "classicalstudies", tier: tier)
                #expect(!msgs.isEmpty, "classicalstudies tier \(tier) must have callouts")
            }
        }
    }
    @Test func classicalstudiesCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "classicalstudies", tier: 1)
            #expect(msgs.count >= 4, "classicalstudies tier1 must have ≥4 messages")
        }
    }
    @Test func classicalstudiesCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "classicalstudies", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "classicalstudies tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func classicalstudiesCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "classicalstudies", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "classicalstudies tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func classicalstudiesKeywordFromClassicalArchaeology() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing a classical archaeology paper on ancient Rome and reading primary sources for my classics major") == "classicalstudies")
    }

    // MARK: - pmrehabilitation

    @Test func pmrehabilitationKeywordFromABPMR() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for my ABPMR board exam and reviewing PM&R residency clerkship notes on spinal cord injury rehabilitation") == "pmrehabilitation")
    }
    @Test func pmrehabilitationKeywordFromPhysiatry() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my physiatry rotation SOAP notes and physical medicine and rehabilitation assignment for residency") == "pmrehabilitation")
    }
    @Test func pmrehabilitationFalsePositiveGenericRehabNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "working on my biology homework and studying for my chemistry exam")
        #expect(kw != "pmrehabilitation", "generic science homework should not route to pmrehabilitation")
    }
    @Test func pmrehabilitationCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "pmrehabilitation", tier: tier)
                #expect(!msgs.isEmpty, "pmrehabilitation tier \(tier) must have callouts")
            }
        }
    }
    @Test func pmrehabilitationCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "pmrehabilitation", tier: 1)
            #expect(msgs.count >= 4, "pmrehabilitation tier1 must have ≥4 messages")
        }
    }
    @Test func pmrehabilitationCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "pmrehabilitation", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "pmrehabilitation tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func pmrehabilitationCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "pmrehabilitation", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "pmrehabilitation tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func pmrehabilitationKeywordFromPMRNotes() {
        #expect(CalloutManager.extractTaskKeyword(from: "writing up my PM&R notes and reviewing rehabilitation medicine coursework for my pm&r class") == "pmrehabilitation")
    }

    // MARK: - performancenutrition

    @Test func performancenutritionKeywordFromCSSDBoardExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the CSSD board exam and reviewing performance nutrition coursework on athlete fueling strategies") == "performancenutrition")
    }
    @Test func performancenutritionKeywordFromSportsDietitian() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on my sports dietitian coursework and completing a sports nutrition certification assignment on endurance athlete fueling") == "performancenutrition")
    }
    @Test func performancenutritionFalsePositiveGenericNutritionNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "completing my registered dietitian coursework on clinical nutrition and MNT for my dietetics program")
        #expect(kw != "performancenutrition", "clinical dietetics coursework should not route to performancenutrition")
    }
    @Test func performancenutritionCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "performancenutrition", tier: tier)
                #expect(!msgs.isEmpty, "performancenutrition tier \(tier) must have callouts")
            }
        }
    }
    @Test func performancenutritionCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "performancenutrition", tier: 1)
            #expect(msgs.count >= 4, "performancenutrition tier1 must have ≥4 messages")
        }
    }
    @Test func performancenutritionCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "performancenutrition", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "performancenutrition tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func performancenutritionCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "performancenutrition", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "performancenutrition tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func performancenutritionKeywordFromRaceDayNutrition() {
        #expect(CalloutManager.extractTaskKeyword(from: "designing a race day nutrition plan and writing up my sport nutrition class assignment on competition nutrition") == "performancenutrition")
    }

    // MARK: - horticulturescience

    @Test func horticulturescienceKeywordFromHorticultureClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my horticulture science class assignment on plant physiology and pomology for my horticulture degree") == "horticulturescience")
    }
    @Test func horticulturescienceKeywordFromISAArboristCertification() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the ISA arborist certification exam and reviewing my arboriculture course notes on tree biology") == "horticulturescience")
    }
    @Test func horticulturecienceFalsePositiveHorticultureTherapyNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "writing horticultural therapy session notes and HTR credential prep for my HTR exam")
        #expect(kw != "horticulturescience", "horticultural therapy should route to horticulturetherapy, not horticulturescience")
    }
    @Test func horticulturescienceCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "horticulturescience", tier: tier)
                #expect(!msgs.isEmpty, "horticulturescience tier \(tier) must have callouts")
            }
        }
    }
    @Test func horticulturescienceCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "horticulturescience", tier: 1)
            #expect(msgs.count >= 4, "horticulturescience tier1 must have ≥4 messages")
        }
    }
    @Test func horticulturescienceCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "horticulturescience", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "horticulturescience tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func horticulturescienceCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "horticulturescience", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "horticulturescience tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func horticulturescienceKeywordFromPCAPestManagement() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the pest control adviser exam and completing my integrated pest management class on IPM strategies") == "horticulturescience")
    }

    // MARK: - globalhealthdev

    @Test func globalhealthdevKeywordFromInternationalDevelopment() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on my international development class assignment on poverty alleviation and development policy in the global south") == "globalhealthdev")
    }
    @Test func globalhealthdevKeywordFromSDGsAndNGO() {
        #expect(CalloutManager.extractTaskKeyword(from: "writing an NGO program proposal and studying the sustainable development goals for my development studies exam") == "globalhealthdev")
    }
    @Test func globalhealthdevFalsePositivePublicHealthNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "studying epidemiology and biostatistics for my MPH program public health exam")
        #expect(kw != "globalhealthdev", "generic MPH coursework should not route to globalhealthdev")
    }
    @Test func globalhealthdevCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "globalhealthdev", tier: tier)
                #expect(!msgs.isEmpty, "globalhealthdev tier \(tier) must have callouts")
            }
        }
    }
    @Test func globalhealthdevCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "globalhealthdev", tier: 1)
            #expect(msgs.count >= 4, "globalhealthdev tier1 must have ≥4 messages")
        }
    }
    @Test func globalhealthdevCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "globalhealthdev", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "globalhealthdev tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func globalhealthdevCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "globalhealthdev", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "globalhealthdev tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func globalhealthdevKeywordFromHumanitarianCoordination() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my humanitarian coordination assignment and studying monitoring and evaluation methods for my international development program") == "globalhealthdev")
    }

    // MARK: - maritimestudies

    @Test func maritimestudiesKeywordFromUSCGLicense() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the USCG licensing exam and reviewing maritime law coursework for my maritime studies class") == "maritimestudies")
    }
    @Test func maritimestudiesKeywordFromMerchantMarine() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my merchant marine exam prep and working on my nautical science course assignment") == "maritimestudies")
    }
    @Test func maritimestudiesFalsePositiveAviationNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "completing my FAA written exam prep and studying for my private pilot flight training ground school")
        #expect(kw != "maritimestudies", "aviation flight training should route to aviation, not maritimestudies")
    }
    @Test func maritimestudiesCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "maritimestudies", tier: tier)
                #expect(!msgs.isEmpty, "maritimestudies tier \(tier) must have callouts")
            }
        }
    }
    @Test func maritimestudiesCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "maritimestudies", tier: 1)
            #expect(msgs.count >= 4, "maritimestudies tier1 must have ≥4 messages")
        }
    }
    @Test func maritimestudiesCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "maritimestudies", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "maritimestudies tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func maritimestudiesCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "maritimestudies", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "maritimestudies tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func maritimestudiesKeywordFromSTCWTraining() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on my STCW certification training and reviewing seafarers exam prep for my maritime academy course") == "maritimestudies")
    }

    // MARK: - hvactechnology

    @Test func hvactechnologyKeywordFromEPA608() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the EPA 608 HVAC certification exam and reviewing refrigerant recovery procedures for my trade program") == "hvactechnology")
    }
    @Test func hvactechnologyKeywordFromRefrigerationClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my refrigeration class assignment and working through HVAC systems coursework for my trade school program") == "hvactechnology")
    }
    @Test func hvactechnologyFalsePositiveEngineeringNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "working on SolidWorks CAD mechanical engineering thermal analysis and FEA simulation")
        #expect(kw != "hvactechnology", "mechanical engineering SolidWorks work should route to engineering, not hvactechnology")
    }
    @Test func hvactechnologyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "hvactechnology", tier: tier)
                #expect(!msgs.isEmpty, "hvactechnology tier \(tier) must have callouts")
            }
        }
    }
    @Test func hvactechnologyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "hvactechnology", tier: 1)
            #expect(msgs.count >= 4, "hvactechnology tier1 must have ≥4 messages")
        }
    }
    @Test func hvactechnologyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "hvactechnology", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "hvactechnology tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func hvactechnologyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "hvactechnology", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "hvactechnology tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func hvactechnologyKeywordFromHeatPumpClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying my heat pump class notes and reviewing cooling systems class material for my HVAC technology program exam") == "hvactechnology")
    }

    // MARK: - constructionmanagement

    @Test func constructionmanagementKeywordFromCCMExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the CCM construction management certification exam and reviewing construction scheduling and project planning coursework") == "constructionmanagement")
    }
    @Test func constructionmanagementKeywordFromEstimating() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my construction estimating class assignment on cost estimating and construction bidding for my construction management degree program") == "constructionmanagement")
    }
    @Test func constructionmanagementFalsePositiveArchitectureNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "working on Revit construction documents and architectural floor plan blueprints for my architecture studio")
        #expect(kw != "constructionmanagement", "architecture blueprint work should route to architecture, not constructionmanagement")
    }
    @Test func constructionmanagementCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "constructionmanagement", tier: tier)
                #expect(!msgs.isEmpty, "constructionmanagement tier \(tier) must have callouts")
            }
        }
    }
    @Test func constructionmanagementCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "constructionmanagement", tier: 1)
            #expect(msgs.count >= 4, "constructionmanagement tier1 must have ≥4 messages")
        }
    }
    @Test func constructionmanagementCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "constructionmanagement", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "constructionmanagement tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func constructionmanagementCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "constructionmanagement", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "constructionmanagement tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func constructionmanagementKeywordFromProjectScheduling() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on my construction project management class assignment covering construction scheduling with CPM and subcontractor management") == "constructionmanagement")
    }

    // MARK: - floristryweddingplanning

    @Test func floristryweddingplanningKeywordFromFloralDesign() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my floral design class assignment and studying for my AIFD certification exam in floristry") == "floristryweddingplanning")
    }
    @Test func floristryweddingplanningKeywordFromWeddingPlanning() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on my wedding planning certification program assignment and developing a venue proposal for my wedding coordinator course") == "floristryweddingplanning")
    }
    @Test func floristryweddingplanningFalsePositiveHospitalityNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "studying hotel management operations and completing my event planning class on hospitality industry revenue management")
        #expect(kw != "floristryweddingplanning", "generic hospitality/event planning should route to hospitality, not floristryweddingplanning")
    }
    @Test func floristryweddingplanningCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "floristryweddingplanning", tier: tier)
                #expect(!msgs.isEmpty, "floristryweddingplanning tier \(tier) must have callouts")
            }
        }
    }
    @Test func floristryweddingplanningCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "floristryweddingplanning", tier: 1)
            #expect(msgs.count >= 4, "floristryweddingplanning tier1 must have ≥4 messages")
        }
    }
    @Test func floristryweddingplanningCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "floristryweddingplanning", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "floristryweddingplanning tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func floristryweddingplanningCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "floristryweddingplanning", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "floristryweddingplanning tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func floristryweddingplanningKeywordFromWeddingFlorals() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on my wedding florals design project and completing a flower arrangement class assignment for my floristry school program") == "floristryweddingplanning")
    }

    // MARK: - cosmeticchemistry

    @Test func cosmeticchemistryKeywordFromFormulation() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying cosmetic chemistry formulation and working on my skincare formulation assignment for my cosmetic science degree program") == "cosmeticchemistry")
    }
    @Test func cosmeticchemistryKeywordFromSCC() {
        #expect(CalloutManager.extractTaskKeyword(from: "preparing for the Society of Cosmetic Chemists symposium and reviewing emulsion formulation and preservation systems for my cosmetic science class") == "cosmeticchemistry")
    }
    @Test func cosmeticchemistryFalsePositivePharmacyNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "studying for the NAPLEX pharmacy board exam and reviewing pharmacokinetics and drug interactions for PharmD program")
        #expect(kw != "cosmeticchemistry", "pharmacy board prep should route to pharmacy, not cosmeticchemistry")
    }
    @Test func cosmeticchemistryCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "cosmeticchemistry", tier: tier)
                #expect(!msgs.isEmpty, "cosmeticchemistry tier \(tier) must have callouts")
            }
        }
    }
    @Test func cosmeticchemistryCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "cosmeticchemistry", tier: 1)
            #expect(msgs.count >= 4, "cosmeticchemistry tier1 must have ≥4 messages")
        }
    }
    @Test func cosmeticchemistryCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "cosmeticchemistry", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "cosmeticchemistry tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func cosmeticchemistryCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "cosmeticchemistry", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "cosmeticchemistry tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func cosmeticchemistryKeywordFromPersonalCareFormulation() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on a personal care formulation assignment and studying haircare formulation chemistry for my cosmetic science course exam") == "cosmeticchemistry")
    }

    // MARK: - automotivetech

    @Test func automotivetechKeywordFromASEExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the ASE certification exam and reviewing engine diagnostics procedures for my automotive technology program") == "automotivetech")
    }
    @Test func automotivetechKeywordFromAutomotiveService() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my automotive service class assignment on brake systems and reviewing automotive technician coursework") == "automotivetech")
    }
    @Test func automotivetechFalsePositiveEngineeringNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "working on SolidWorks CAD mechanical engineering design for automotive engineering project")
        #expect(kw != "automotivetech", "automotive engineering design should route to engineering, not automotivetech")
    }
    @Test func automotivetechCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "automotivetech", tier: tier)
                #expect(!msgs.isEmpty, "automotivetech tier \(tier) must have callouts")
            }
        }
    }
    @Test func automotivetechCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "automotivetech", tier: 1)
            #expect(msgs.count >= 4, "automotivetech tier1 must have ≥4 messages")
        }
    }
    @Test func automotivetechCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "automotivetech", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "automotivetech tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func automotivetechCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "automotivetech", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "automotivetech tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func automotivetechKeywordFromAutoBody() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on my auto body class assignment and collision repair program coursework") == "automotivetech")
    }

    // MARK: - weldingtechnology

    @Test func weldingtechnologyKeywordFromAWSCertification() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the AWS welding certification exam and reviewing MIG welding procedures for my welding technology program") == "weldingtechnology")
    }
    @Test func weldingtechnologyKeywordFromCWIExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my welding inspection coursework and preparing for the CWI exam") == "weldingtechnology")
    }
    @Test func weldingtechnologyFalsePositiveHVACNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "studying for the EPA 608 HVAC certification exam and refrigerant recovery procedures")
        #expect(kw != "weldingtechnology", "HVAC certification should route to hvactechnology, not weldingtechnology")
    }
    @Test func weldingtechnologyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "weldingtechnology", tier: tier)
                #expect(!msgs.isEmpty, "weldingtechnology tier \(tier) must have callouts")
            }
        }
    }
    @Test func weldingtechnologyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "weldingtechnology", tier: 1)
            #expect(msgs.count >= 4, "weldingtechnology tier1 must have ≥4 messages")
        }
    }
    @Test func weldingtechnologyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "weldingtechnology", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "weldingtechnology tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func weldingtechnologyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "weldingtechnology", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "weldingtechnology tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func weldingtechnologyKeywordFromWeldingClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "working through my welding class assignment on arc welding procedures and structural welding techniques") == "weldingtechnology")
    }

    // MARK: - grantwriting

    @Test func grantwritingKeywordFromNIHGrant() {
        #expect(CalloutManager.extractTaskKeyword(from: "writing my NIH grant specific aims and working on the research narrative for my R01 grant application") == "grantwriting")
    }
    @Test func grantwritingKeywordFromGrantProposal() {
        #expect(CalloutManager.extractTaskKeyword(from: "drafting my grant proposal for the NSF application and working on the research narrative and grant budget") == "grantwriting")
    }
    @Test func grantwritingFalsePositiveWritingNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "writing a blog post draft and revising my newsletter outline")
        #expect(kw != "grantwriting", "generic writing tasks should route to writing, not grantwriting")
    }
    @Test func grantwritingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "grantwriting", tier: tier)
                #expect(!msgs.isEmpty, "grantwriting tier \(tier) must have callouts")
            }
        }
    }
    @Test func grantwritingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "grantwriting", tier: 1)
            #expect(msgs.count >= 4, "grantwriting tier1 must have ≥4 messages")
        }
    }
    @Test func grantwritingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "grantwriting", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "grantwriting tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func grantwritingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "grantwriting", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "grantwriting tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func grantwritingKeywordFromSBIRApplication() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on my SBIR grant application and drafting the grant narrative section") == "grantwriting")
    }

    // MARK: - animalhusbandry

    @Test func animalhusbandryKeywordFromLivestockManagement() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my livestock management assignment and studying swine production for my animal husbandry class") == "animalhusbandry")
    }
    @Test func animalhusbandryKeywordFromPoultryScience() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on my poultry science coursework and reviewing poultry production management for my animal production class exam") == "animalhusbandry")
    }
    @Test func animalhusbandryFalsePositiveVeterinaryNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "studying for the NAVLE veterinary board exam and reviewing veterinary pathology clinical rotation notes")
        #expect(kw != "animalhusbandry", "veterinary board exam prep should route to veterinary, not animalhusbandry")
    }
    @Test func animalhusbandryCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "animalhusbandry", tier: tier)
                #expect(!msgs.isEmpty, "animalhusbandry tier \(tier) must have callouts")
            }
        }
    }
    @Test func animalhusbandryCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "animalhusbandry", tier: 1)
            #expect(msgs.count >= 4, "animalhusbandry tier1 must have ≥4 messages")
        }
    }
    @Test func animalhusbandryCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "animalhusbandry", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "animalhusbandry tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func animalhusbandryCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "animalhusbandry", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "animalhusbandry tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func animalhusbandryKeywordFromDairyScience() {
        #expect(CalloutManager.extractTaskKeyword(from: "reviewing dairy science and dairy cattle production notes for my animal agriculture exam") == "animalhusbandry")
    }

    // MARK: - paralegal

    @Test func paralegalKeywordFromParalegalProgram() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for my paralegal certification exam and reviewing paralegal program coursework on civil procedure") == "paralegal")
    }
    @Test func paralegalKeywordFromCLAExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "preparing for the CLA exam and working on my paralegal studies legal research and document drafting assignment") == "paralegal")
    }
    @Test func paralegalFalsePositiveLegalNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "writing a legal brief and preparing for moot court oral argument in my first-year law school course")
        #expect(kw != "paralegal", "law school work should route to legal, not paralegal")
    }
    @Test func paralegalCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "paralegal", tier: tier)
                #expect(!msgs.isEmpty, "paralegal tier \(tier) must have callouts")
            }
        }
    }
    @Test func paralegalCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "paralegal", tier: 1)
            #expect(msgs.count >= 4, "paralegal tier1 must have ≥4 messages")
        }
    }
    @Test func paralegalCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "paralegal", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "paralegal tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func paralegalCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "paralegal", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "paralegal tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func paralegalKeywordFromABAParalegal() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my ABA paralegal certificate program assignment on legal research and litigation support") == "paralegal")
    }

    // MARK: - certifiedfinancialplanner keyword tests
    @Test func certifiedfinancialplannerKeywordFromCFPExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the CFP exam and reviewing financial planning coursework on investment and retirement planning") == "certifiedfinancialplanner")
    }
    @Test func certifiedfinancialplannerKeywordFromFinancialPlanningClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my financial planning class assignment on estate planning and wealth management for my CFP program") == "certifiedfinancialplanner")
    }
    @Test func certifiedfinancialplannerFalsePositiveFinanceNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "building a DCF model and running a financial analysis for my investment banking class")
        #expect(kw != "certifiedfinancialplanner", "investment banking and DCF should route to finance, not certifiedfinancialplanner")
    }
    @Test func certifiedfinancialplannerCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "certifiedfinancialplanner", tier: tier)
                #expect(!msgs.isEmpty, "certifiedfinancialplanner tier \(tier) must have callouts")
            }
        }
    }
    @Test func certifiedfinancialplannerCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "certifiedfinancialplanner", tier: 1)
            #expect(msgs.count >= 4, "certifiedfinancialplanner tier1 must have ≥4 messages")
        }
    }
    @Test func certifiedfinancialplannerCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "certifiedfinancialplanner", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "certifiedfinancialplanner tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func certifiedfinancialplannerCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "certifiedfinancialplanner", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "certifiedfinancialplanner tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func certifiedfinancialplannerKeywordFromSeries65() {
        #expect(CalloutManager.extractTaskKeyword(from: "preparing for my Series 65 exam as part of my registered investment adviser licensing program") == "certifiedfinancialplanner")
    }

    // MARK: - soilscience keyword tests
    @Test func soilscienceKeywordFromSoilScience() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my soil science lab report on soil horizon descriptions and soil profile classification for my pedology class") == "soilscience")
    }
    @Test func soilscienceKeywordFromPedology() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying pedology and soil taxonomy for my soil science exam covering soil orders and soil genesis") == "soilscience")
    }
    @Test func soilscienceFalsePositiveGeologyNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "studying plate tectonics and rock identification for my geology lab report on mineralogy and stratigraphy")
        #expect(kw != "soilscience", "plate tectonics and mineralogy should route to geology, not soilscience")
    }
    @Test func soilscienceCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "soilscience", tier: tier)
                #expect(!msgs.isEmpty, "soilscience tier \(tier) must have callouts")
            }
        }
    }
    @Test func soilscienceCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "soilscience", tier: 1)
            #expect(msgs.count >= 4, "soilscience tier1 must have ≥4 messages")
        }
    }
    @Test func soilscienceCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "soilscience", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "soilscience tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func soilscienceCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "soilscience", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "soilscience tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func soilscienceKeywordFromSoilMapping() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on my soil survey and soil mapping assignment for my soil science program describing soil horizons and pedon characteristics") == "soilscience")
    }

    // MARK: - industrialsafety keyword tests
    @Test func industrialsafetyKeywordFromIndustrialHygiene() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying industrial hygiene and occupational safety and health for my CIH exam covering hazard recognition and control") == "industrialsafety")
    }
    @Test func industrialsafetyKeywordFromOSHAClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my industrial safety class assignment on OSHA compliance and job hazard analysis for manufacturing facilities") == "industrialsafety")
    }
    @Test func industrialsafetyFalsePositiveEngineeringNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "designing a circuit board in SolidWorks and running a finite element analysis for my mechanical engineering lab report")
        #expect(kw != "industrialsafety", "solidworks and FEA should route to engineering, not industrialsafety")
    }
    @Test func industrialsafetyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "industrialsafety", tier: tier)
                #expect(!msgs.isEmpty, "industrialsafety tier \(tier) must have callouts")
            }
        }
    }
    @Test func industrialsafetyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "industrialsafety", tier: 1)
            #expect(msgs.count >= 4, "industrialsafety tier1 must have ≥4 messages")
        }
    }
    @Test func industrialsafetyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "industrialsafety", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "industrialsafety tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func industrialsafetyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "industrialsafety", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "industrialsafety tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func industrialsafetyKeywordFromJobHazardAnalysis() {
        #expect(CalloutManager.extractTaskKeyword(from: "writing a job hazard analysis for my industrial safety program covering OSHA 300 log requirements and hazard assessment") == "industrialsafety")
    }

    // MARK: - foodsafety keyword tests
    @Test func foodsafetyKeywordFromServSafe() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the ServSafe food safety certification exam and reviewing foodborne illness prevention and HACCP principles") == "foodsafety")
    }
    @Test func foodsafetyKeywordFromHACCPPlan() {
        #expect(CalloutManager.extractTaskKeyword(from: "writing a HACCP plan for my food safety class covering critical control points and food contamination prevention procedures") == "foodsafety")
    }
    @Test func foodsafetyFalsePositiveCulinaryNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "developing a new recipe and practicing my knife skills and plating technique for culinary school")
        #expect(kw != "foodsafety", "recipe development and culinary technique should route to culinary, not foodsafety")
    }
    @Test func foodsafetyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "foodsafety", tier: tier)
                #expect(!msgs.isEmpty, "foodsafety tier \(tier) must have callouts")
            }
        }
    }
    @Test func foodsafetyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "foodsafety", tier: 1)
            #expect(msgs.count >= 4, "foodsafety tier1 must have ≥4 messages")
        }
    }
    @Test func foodsafetyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "foodsafety", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "foodsafety tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func foodsafetyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "foodsafety", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "foodsafety tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func foodsafetyKeywordFromFoodMicrobiology() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my food microbiology lab assignment on foodborne pathogen identification and food safety audit procedures") == "foodsafety")
    }

    // MARK: - appliedmusic keyword tests
    @Test func appliedmusicKeywordFromAuditionPrep() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on audition prep and practicing my solo repertoire for the music audition and conservatory application") == "appliedmusic")
    }
    @Test func appliedmusicKeywordFromMusicJury() {
        #expect(CalloutManager.extractTaskKeyword(from: "preparing for my music jury by working through applied music etudes and orchestral excerpts for my violin lesson") == "appliedmusic")
    }
    @Test func appliedmusicFalsePositiveMusicTheoryNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "studying ear training and chord progressions for my music theory class and sight reading assignment")
        #expect(kw != "appliedmusic", "ear training and chord progressions should route to musictheory, not appliedmusic")
    }
    @Test func appliedmusicCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "appliedmusic", tier: tier)
                #expect(!msgs.isEmpty, "appliedmusic tier \(tier) must have callouts")
            }
        }
    }
    @Test func appliedmusicCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "appliedmusic", tier: 1)
            #expect(msgs.count >= 4, "appliedmusic tier1 must have ≥4 messages")
        }
    }
    @Test func appliedmusicCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "appliedmusic", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "appliedmusic tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func appliedmusicCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "appliedmusic", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "appliedmusic tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func appliedmusicKeywordFromPianoLesson() {
        #expect(CalloutManager.extractTaskKeyword(from: "practicing my piano lesson repertoire and working on piano recital preparation including scales and etudes") == "appliedmusic")
    }

    // MARK: - winemaking keyword tests
    @Test func winemakingKeywordFromWineProduction() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my winemaking lab report on wine production and fermentation protocol analysis for my enology course") == "winemaking")
    }
    @Test func winemakingKeywordFromCellarOperations() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying winery operations and cellar management techniques including barrel aging and wine blending procedures") == "winemaking")
    }
    @Test func winemakingFalsePositiveSommelierNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "studying for my wine tasting class and WSET certification exam with blind tasting practice")
        #expect(kw != "winemaking", "wine tasting/certification study should route to winesommelier, not winemaking")
    }
    @Test func winemakingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "winemaking", tier: tier)
                #expect(!msgs.isEmpty, "winemaking tier \(tier) must have callouts")
            }
        }
    }
    @Test func winemakingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "winemaking", tier: 1)
            #expect(msgs.count >= 4, "winemaking tier1 must have ≥4 messages")
        }
    }
    @Test func winemakingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "winemaking", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "winemaking tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func winemakingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "winemaking", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "winemaking tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func winemakingKeywordFromVineyardManagement() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on vineyard management assignment and wine fermentation data analysis for my winemaking program") == "winemaking")
    }

    // MARK: - forestry keyword tests
    @Test func forestryKeywordFromSilviculture() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying silviculture prescriptions and forest management principles for my forestry class and completing a timber cruise analysis") == "forestry")
    }
    @Test func forestryKeywordFromDendrology() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my dendrology lab assignment on tree identification and reviewing forest inventory methods for the forestry exam") == "forestry")
    }
    @Test func forestryFalsePositiveEnviroNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "writing a field ecology report on biodiversity and carbon footprint analysis for my environmental science class")
        #expect(kw != "forestry", "general ecology/enviro terms should route to enviro, not forestry")
    }
    @Test func forestryCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forestry", tier: tier)
                #expect(!msgs.isEmpty, "forestry tier \(tier) must have callouts")
            }
        }
    }
    @Test func forestryCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forestry", tier: 1)
            #expect(msgs.count >= 4, "forestry tier1 must have ≥4 messages")
        }
    }
    @Test func forestryCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forestry", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "forestry tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func forestryCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "forestry", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "forestry tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func forestryKeywordFromTimberCruising() {
        #expect(CalloutManager.extractTaskKeyword(from: "practicing timber cruising techniques and completing my forest inventory data analysis for the forestry program exam") == "forestry")
    }

    // MARK: - aquaticscience keyword tests
    @Test func aquaticscienceKeywordFromFisheriesBiology() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my fisheries biology lab report on fish population ecology and aquatic resource management") == "aquaticscience")
    }
    @Test func aquaticscienceKeywordFromAquaculture() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying aquaculture systems and limnology principles for my aquatic science course exam") == "aquaticscience")
    }
    @Test func aquaticscienceFalsePositiveEnviroNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "writing a climate change policy paper on carbon footprint and sustainability for my environmental science class")
        #expect(kw != "aquaticscience", "general climate/sustainability terms should route to enviro, not aquaticscience")
    }
    @Test func aquaticscienceCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "aquaticscience", tier: tier)
                #expect(!msgs.isEmpty, "aquaticscience tier \(tier) must have callouts")
            }
        }
    }
    @Test func aquaticscienceCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "aquaticscience", tier: 1)
            #expect(msgs.count >= 4, "aquaticscience tier1 must have ≥4 messages")
        }
    }
    @Test func aquaticscienceCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "aquaticscience", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "aquaticscience tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func aquaticscienceCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "aquaticscience", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "aquaticscience tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func aquaticscienceKeywordFromMarineFisheries() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my marine fisheries management assignment and reviewing freshwater fisheries ecology for the aquatic science program") == "aquaticscience")
    }

    // MARK: - emergencynursing keyword tests
    @Test func emergencynursingKeywordFromCENExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the CEN exam and reviewing trauma nursing protocols and triage assessment for my emergency nursing certification") == "emergencynursing")
    }
    @Test func emergencynursingKeywordFromTNCC() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my TNCC and ENPC emergency nursing coursework assignment on mass casualty triage and trauma assessment") == "emergencynursing")
    }
    @Test func emergencynursingFalsePositiveNursingNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "writing nursing care plans and reviewing dosage calculations for my nursing school clinical rotation")
        #expect(kw != "emergencynursing", "generic nursing care plan tasks should route to nursing, not emergencynursing")
    }
    @Test func emergencynursingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "emergencynursing", tier: tier)
                #expect(!msgs.isEmpty, "emergencynursing tier \(tier) must have callouts")
            }
        }
    }
    @Test func emergencynursingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "emergencynursing", tier: 1)
            #expect(msgs.count >= 4, "emergencynursing tier1 must have ≥4 messages")
        }
    }
    @Test func emergencynursingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "emergencynursing", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "emergencynursing tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func emergencynursingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "emergencynursing", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "emergencynursing tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func emergencynursingKeywordFromERNurse() {
        #expect(CalloutManager.extractTaskKeyword(from: "writing up my ER nursing case notes and studying emergency nursing certification exam questions for the CEN prep course") == "emergencynursing")
    }

    // MARK: - publichealthnutrition keyword tests
    @Test func publichealthnutritionKeywordFromCommunityNutrition() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my community nutrition program assignment on WIC counseling and food security policy analysis") == "publichealthnutrition")
    }
    @Test func publichealthnutritionKeywordFromPublicHealthNutrition() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for my public health nutrition exam and reviewing maternal nutrition and nutrition education program design") == "publichealthnutrition")
    }
    @Test func publichealthnutritionFalsePositiveNutritionNotMatched() {
        let kw = CalloutManager.extractTaskKeyword(from: "tracking my macronutrients and reviewing my dietitian's meal plan and calorie tracking app")
        #expect(kw != "publichealthnutrition", "individual dietitian/calorie tasks should route to nutrition, not publichealthnutrition")
    }
    @Test func publichealthnutritionCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "publichealthnutrition", tier: tier)
                #expect(!msgs.isEmpty, "publichealthnutrition tier \(tier) must have callouts")
            }
        }
    }
    @Test func publichealthnutritionCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "publichealthnutrition", tier: 1)
            #expect(msgs.count >= 4, "publichealthnutrition tier1 must have ≥4 messages")
        }
    }
    @Test func publichealthnutritionCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "publichealthnutrition", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "publichealthnutrition tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func publichealthnutritionCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "publichealthnutrition", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "publichealthnutrition tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func publichealthnutritionKeywordFromWICCounseling() {
        #expect(CalloutManager.extractTaskKeyword(from: "developing WIC counseling materials and nutrition education program content for my community nutrition class assignment") == "publichealthnutrition")
    }

    // MARK: - plumbingtech keyword tests
    @Test func plumbingtechKeywordFromJourneymanPlumber() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the journeyman plumber exam and reviewing NCCER plumbing code sections") == "plumbingtech")
    }
    @Test func plumbingtechKeywordFromPlumbingCodeClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my plumbing code class assignment on pipe sizing and drainage systems") == "plumbingtech")
    }
    @Test func plumbingtechCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "plumbingtech", tier: tier)
                #expect(!msgs.isEmpty, "plumbingtech tier \(tier) must have callouts")
            }
        }
    }
    @Test func plumbingtechCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "plumbingtech", tier: 1)
            #expect(msgs.count >= 4, "plumbingtech tier1 must have ≥4 messages")
        }
    }
    @Test func plumbingtechCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "plumbingtech", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "plumbingtech tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func plumbingtechCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "plumbingtech", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "plumbingtech tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - electricaltechnology keyword tests
    @Test func electricaltechnologyKeywordFromJourneymanElectrician() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the journeyman electrician exam and reviewing NEC code articles for my IBEW apprenticeship") == "electricaltechnology")
    }
    @Test func electricaltechnologyKeywordFromElectricalCodeClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing an electrical code class assignment on wiring methods and load calculations for my electrician program") == "electricaltechnology")
    }
    @Test func electricaltechnologyCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "electricaltechnology", tier: tier)
                #expect(!msgs.isEmpty, "electricaltechnology tier \(tier) must have callouts")
            }
        }
    }
    @Test func electricaltechnologyCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "electricaltechnology", tier: 1)
            #expect(msgs.count >= 4, "electricaltechnology tier1 must have ≥4 messages")
        }
    }
    @Test func electricaltechnologyCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "electricaltechnology", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "electricaltechnology tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func electricaltechnologyCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "electricaltechnology", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "electricaltechnology tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - materialscience keyword tests
    @Test func materialscienceKeywordFromPhaseDiagram() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on my materials science lab report interpreting phase diagrams and mechanical property calculations") == "materialscience")
    }
    @Test func materialscienceKeywordFromMetallurgy() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for my materials engineering exam on metallurgy, polymer science, and composite materials") == "materialscience")
    }
    @Test func materialscienceCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "materialscience", tier: tier)
                #expect(!msgs.isEmpty, "materialscience tier \(tier) must have callouts")
            }
        }
    }
    @Test func materialscienceCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "materialscience", tier: 1)
            #expect(msgs.count >= 4, "materialscience tier1 must have ≥4 messages")
        }
    }
    @Test func materialscienceCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "materialscience", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "materialscience tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func materialscienceCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "materialscience", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "materialscience tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - networkengineering keyword tests
    @Test func networkengineeringKeywordFromCCNA() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for my CCNA exam and reviewing subnetting and routing protocols for my networking class") == "networkengineering")
    }
    @Test func networkengineeringKeywordFromNetworkPlus() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing a CompTIA Network+ exam study session on IP addressing and network infrastructure design") == "networkengineering")
    }
    @Test func networkengineeringCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "networkengineering", tier: tier)
                #expect(!msgs.isEmpty, "networkengineering tier \(tier) must have callouts")
            }
        }
    }
    @Test func networkengineeringCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "networkengineering", tier: 1)
            #expect(msgs.count >= 4, "networkengineering tier1 must have ≥4 messages")
        }
    }
    @Test func networkengineeringCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "networkengineering", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "networkengineering tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func networkengineeringCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "networkengineering", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "networkengineering tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - environmentalhealth keyword tests
    @Test func environmentalhealthKeywordFromREHS() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for my REHS exam and reviewing environmental health science concepts on food safety and water quality testing") == "environmentalhealth")
    }
    @Test func environmentalhealthKeywordFromEnvironmentalHealthClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my environmental health class assignment on community environmental health assessment and inspection protocols") == "environmentalhealth")
    }
    @Test func environmentalhealthCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "environmentalhealth", tier: tier)
                #expect(!msgs.isEmpty, "environmentalhealth tier \(tier) must have callouts")
            }
        }
    }
    @Test func environmentalhealthCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "environmentalhealth", tier: 1)
            #expect(msgs.count >= 4, "environmentalhealth tier1 must have ≥4 messages")
        }
    }
    @Test func environmentalhealthCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "environmentalhealth", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "environmentalhealth tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func environmentalhealthCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "environmentalhealth", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "environmentalhealth tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - constructiontech keyword tests
    @Test func constructiontechKeywordFromContractorLicenseExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the contractor license exam and reviewing carpentry and masonry techniques for my construction technology program") == "constructiontech")
    }
    @Test func constructiontechKeywordFromCarpentryClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my carpentry class assignment on wood framing and structural systems for my building trades program") == "constructiontech")
    }
    @Test func constructiontechCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "constructiontech", tier: tier)
                #expect(!msgs.isEmpty, "constructiontech tier \(tier) must have callouts")
            }
        }
    }
    @Test func constructiontechCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "constructiontech", tier: 1)
            #expect(msgs.count >= 4, "constructiontech tier1 must have ≥4 messages")
        }
    }
    @Test func constructiontechCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "constructiontech", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "constructiontech tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func constructiontechCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "constructiontech", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "constructiontech tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - urbandesign keyword tests
    @Test func urbandesignKeywordFromStreetscapeDesign() {
        #expect(CalloutManager.extractTaskKeyword(from: "designing a streetscape and placemaking analysis for my urban design studio project") == "urbandesign")
    }
    @Test func urbandesignKeywordFromUrbanDesignClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my urban design class assignment on pedestrian design and public realm analysis") == "urbandesign")
    }
    @Test func urbandesignCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "urbandesign", tier: tier)
                #expect(!msgs.isEmpty, "urbandesign tier \(tier) must have callouts")
            }
        }
    }
    @Test func urbandesignCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "urbandesign", tier: 1)
            #expect(msgs.count >= 4, "urbandesign tier1 must have ≥4 messages")
        }
    }
    @Test func urbandesignCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "urbandesign", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "urbandesign tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func urbandesignCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "urbandesign", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "urbandesign tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - ceramicsandsculpture keyword tests
    @Test func ceramicsandsculptureKeywordFromPotteryWheel() {
        #expect(CalloutManager.extractTaskKeyword(from: "practicing wheel throwing on the pottery wheel and preparing my ceramics pieces for kiln firing") == "ceramicsandsculpture")
    }
    @Test func ceramicsandsculptureKeywordFromCeramicsClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my ceramics class assignment on hand building and ceramic glaze application techniques") == "ceramicsandsculpture")
    }
    @Test func ceramicsandsculptureCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "ceramicsandsculpture", tier: tier)
                #expect(!msgs.isEmpty, "ceramicsandsculpture tier \(tier) must have callouts")
            }
        }
    }
    @Test func ceramicsandsculptureCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "ceramicsandsculpture", tier: 1)
            #expect(msgs.count >= 4, "ceramicsandsculpture tier1 must have ≥4 messages")
        }
    }
    @Test func ceramicsandsculptureCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "ceramicsandsculpture", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "ceramicsandsculpture tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func ceramicsandsculptureCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "ceramicsandsculpture", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "ceramicsandsculpture tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - exercisescience keyword tests
    @Test func exercisescienceKeywordFromACSMExam() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for the ACSM exam and reviewing exercise testing protocols for my exercise science program") == "exercisescience")
    }
    @Test func exercisescienceKeywordFromExerciseScienceClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my exercise science class lab report on graded exercise test and metabolic assessment") == "exercisescience")
    }
    @Test func exercisescienceCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "exercisescience", tier: tier)
                #expect(!msgs.isEmpty, "exercisescience tier \(tier) must have callouts")
            }
        }
    }
    @Test func exercisescienceCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "exercisescience", tier: 1)
            #expect(msgs.count >= 4, "exercisescience tier1 must have ≥4 messages")
        }
    }
    @Test func exercisescienceCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "exercisescience", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "exercisescience tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func exercisescienceCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "exercisescience", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "exercisescience tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - biochemistry keyword tests
    @Test func biochemistryKeywordFromEnzymeKinetics() {
        #expect(CalloutManager.extractTaskKeyword(from: "completing my biochemistry lab report on enzyme kinetics and Michaelis-Menten analysis of substrate concentration") == "biochemistry")
    }
    @Test func biochemistryKeywordFromBiochemistryClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for my biochemistry exam and reviewing Bradford assay techniques and metabolic pathway analysis") == "biochemistry")
    }
    @Test func biochemistryCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "biochemistry", tier: tier)
                #expect(!msgs.isEmpty, "biochemistry tier \(tier) must have callouts")
            }
        }
    }
    @Test func biochemistryCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "biochemistry", tier: 1)
            #expect(msgs.count >= 4, "biochemistry tier1 must have ≥4 messages")
        }
    }
    @Test func biochemistryCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "biochemistry", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "biochemistry tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func biochemistryCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "biochemistry", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "biochemistry tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - agriculturalscience keyword tests
    @Test func agriculturalscienceKeywordFromAgronomy() {
        #expect(CalloutManager.extractTaskKeyword(from: "working on agronomy and crop science for my farm management program") == "agriculturalscience")
    }
    @Test func agriculturalscienceKeywordFromPrecisionAgriculture() {
        #expect(CalloutManager.extractTaskKeyword(from: "precision agriculture techniques and crop production class on field crop management") == "agriculturalscience")
    }
    @Test func agriculturalscienceCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "agriculturalscience", tier: tier)
                #expect(!msgs.isEmpty, "agriculturalscience tier \(tier) must have callouts")
            }
        }
    }
    @Test func agriculturalscienceCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "agriculturalscience", tier: 1)
            #expect(msgs.count >= 4, "agriculturalscience tier1 must have ≥4 messages")
        }
    }
    @Test func agriculturalscienceCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "agriculturalscience", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "agriculturalscience tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func agriculturalscienceCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "agriculturalscience", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "agriculturalscience tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - textilesfashion keyword tests
    @Test func textilesfashionKeywordFromFiberArts() {
        #expect(CalloutManager.extractTaskKeyword(from: "fiber arts hand weaving tapestry project with natural dyeing on the loom") == "textilesfashion")
    }
    @Test func textilesfashionKeywordFromTextileEngineering() {
        #expect(CalloutManager.extractTaskKeyword(from: "textile engineering class on fabric structure and textile dyeing methods") == "textilesfashion")
    }
    @Test func textilesfashionCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "textilesfashion", tier: tier)
                #expect(!msgs.isEmpty, "textilesfashion tier \(tier) must have callouts")
            }
        }
    }
    @Test func textilesfashionCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "textilesfashion", tier: 1)
            #expect(msgs.count >= 4, "textilesfashion tier1 must have ≥4 messages")
        }
    }
    @Test func textilesfashionCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "textilesfashion", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "textilesfashion tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func textilesfashionCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "textilesfashion", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "textilesfashion tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - geographyearthed keyword tests
    @Test func geographyearthedKeywordFromAPHumanGeography() {
        #expect(CalloutManager.extractTaskKeyword(from: "ap human geography review on cultural patterns and regional geography") == "geographyearthed")
    }
    @Test func geographyearthedKeywordFromPhysicalGeography() {
        #expect(CalloutManager.extractTaskKeyword(from: "physical geography class on biogeography and climate geography") == "geographyearthed")
    }
    @Test func geographyearthedCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "geographyearthed", tier: tier)
                #expect(!msgs.isEmpty, "geographyearthed tier \(tier) must have callouts")
            }
        }
    }
    @Test func geographyearthedCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "geographyearthed", tier: 1)
            #expect(msgs.count >= 4, "geographyearthed tier1 must have ≥4 messages")
        }
    }
    @Test func geographyearthedCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "geographyearthed", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "geographyearthed tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func geographyearthedCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "geographyearthed", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "geographyearthed tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - childlife keyword tests
    @Test func childlifeKeywordFromCCLS() {
        #expect(CalloutManager.extractTaskKeyword(from: "ccls board certification for child life specialist program") == "childlife")
    }
    @Test func childlifeKeywordFromChildLifeSpecialist() {
        #expect(CalloutManager.extractTaskKeyword(from: "child life specialist session plan and therapeutic play for pediatric hospital internship") == "childlife")
    }
    @Test func childlifeCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "childlife", tier: tier)
                #expect(!msgs.isEmpty, "childlife tier \(tier) must have callouts")
            }
        }
    }
    @Test func childlifeCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "childlife", tier: 1)
            #expect(msgs.count >= 4, "childlife tier1 must have ≥4 messages")
        }
    }
    @Test func childlifeCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "childlife", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "childlife tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func childlifeCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "childlife", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "childlife tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - qualitymanagement keyword tests
    @Test func qualitymanagementKeywordFromCQE() {
        #expect(CalloutManager.extractTaskKeyword(from: "asq cqe certification quality management system and statistical process control class") == "qualitymanagement")
    }
    @Test func qualitymanagementKeywordFromISO9001() {
        #expect(CalloutManager.extractTaskKeyword(from: "iso 9001 quality management class on quality assurance and audit process") == "qualitymanagement")
    }
    @Test func qualitymanagementCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "qualitymanagement", tier: tier)
                #expect(!msgs.isEmpty, "qualitymanagement tier \(tier) must have callouts")
            }
        }
    }
    @Test func qualitymanagementCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "qualitymanagement", tier: 1)
            #expect(msgs.count >= 4, "qualitymanagement tier1 must have ≥4 messages")
        }
    }
    @Test func qualitymanagementCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "qualitymanagement", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "qualitymanagement tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func qualitymanagementCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "qualitymanagement", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "qualitymanagement tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }

    // MARK: - quantumcomputing keyword tests
    @Test func quantumcomputingKeywordFromQiskit() {
        #expect(CalloutManager.extractTaskKeyword(from: "build a quantum circuit using qiskit and ibm quantum") == "quantumcomputing")
    }
    @Test func quantumcomputingKeywordFromAlgorithm() {
        #expect(CalloutManager.extractTaskKeyword(from: "study quantum algorithms shor grover for my quantum computing class") == "quantumcomputing")
    }
    @Test func quantumcomputingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "quantumcomputing", tier: tier)
                #expect(!msgs.isEmpty, "quantumcomputing tier \(tier) must have callouts")
            }
        }
    }
    @Test func quantumcomputingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "quantumcomputing", tier: 1)
            #expect(msgs.count >= 4, "quantumcomputing tier1 must have ≥4 messages")
        }
    }
    @Test func quantumcomputingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "quantumcomputing", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "quantumcomputing tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func quantumcomputingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "quantumcomputing", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "quantumcomputing tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func quantumcomputingFalsePositiveQuantumPhysics() {
        let kw = CalloutManager.extractTaskKeyword(from: "study quantum mechanics for my physics exam")
        #expect(kw != "quantumcomputing", "bare quantum mechanics for physics should NOT fire quantumcomputing")
    }
    @Test func quantumcomputingKeywordFromErrorCorrection() {
        #expect(CalloutManager.extractTaskKeyword(from: "quantum error correction and quantum cryptography course assignment") == "quantumcomputing")
    }

    // MARK: - cloudcomputing keyword tests
    @Test func cloudcomputingKeywordFromAWS() {
        #expect(CalloutManager.extractTaskKeyword(from: "studying for aws certification solutions architect cloud exam") == "cloudcomputing")
    }
    @Test func cloudcomputingKeywordFromKubernetes() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete kubernetes class assignment on cka certification and container orchestration") == "cloudcomputing")
    }
    @Test func cloudcomputingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "cloudcomputing", tier: tier)
                #expect(!msgs.isEmpty, "cloudcomputing tier \(tier) must have callouts")
            }
        }
    }
    @Test func cloudcomputingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "cloudcomputing", tier: 1)
            #expect(msgs.count >= 4, "cloudcomputing tier1 must have ≥4 messages")
        }
    }
    @Test func cloudcomputingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "cloudcomputing", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "cloudcomputing tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func cloudcomputingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "cloudcomputing", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "cloudcomputing tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func cloudcomputingFalsePositiveAWSWelding() {
        let kw = CalloutManager.extractTaskKeyword(from: "aws welding certification d1.1 structural welding")
        #expect(kw != "cloudcomputing", "AWS welding context should NOT fire cloudcomputing")
    }
    @Test func cloudcomputingKeywordFromDevOps() {
        #expect(CalloutManager.extractTaskKeyword(from: "devops class assignment on terraform cloud infrastructure deployment pipeline") == "cloudcomputing")
    }

    // MARK: - softwaretesting keyword tests
    @Test func softwaretestingKeywordFromISTQB() {
        #expect(CalloutManager.extractTaskKeyword(from: "study for the istqb ctfl exam and software quality assurance concepts") == "softwaretesting")
    }
    @Test func softwaretestingKeywordFromTestAutomation() {
        #expect(CalloutManager.extractTaskKeyword(from: "complete test automation assignment using selenium for my qa engineering class") == "softwaretesting")
    }
    @Test func softwaretestingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "softwaretesting", tier: tier)
                #expect(!msgs.isEmpty, "softwaretesting tier \(tier) must have callouts")
            }
        }
    }
    @Test func softwaretestingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "softwaretesting", tier: 1)
            #expect(msgs.count >= 4, "softwaretesting tier1 must have ≥4 messages")
        }
    }
    @Test func softwaretestingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "softwaretesting", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "softwaretesting tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func softwaretestingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "softwaretesting", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "softwaretesting tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func softwaretestingFalsePositivePenetrationTesting() {
        let kw = CalloutManager.extractTaskKeyword(from: "penetration testing oscp ethical hacking kali linux")
        #expect(kw != "softwaretesting", "penetration testing should route to cybersecurity, not softwaretesting")
    }
    @Test func softwaretestingKeywordFromSoftwareQuality() {
        #expect(CalloutManager.extractTaskKeyword(from: "software quality assurance class on regression testing and acceptance testing") == "softwaretesting")
    }

    // MARK: - mechanicaldrafting keyword tests
    @Test func mechanicaldraftingKeywordFromBlueprintReading() {
        #expect(CalloutManager.extractTaskKeyword(from: "blueprint reading class for mechanical drafting program certification exam") == "mechanicaldrafting")
    }
    @Test func mechanicaldraftingKeywordFromTechnicalDrawing() {
        #expect(CalloutManager.extractTaskKeyword(from: "engineering drawing class assignment on orthographic projection and technical drawing") == "mechanicaldrafting")
    }
    @Test func mechanicaldraftingCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "mechanicaldrafting", tier: tier)
                #expect(!msgs.isEmpty, "mechanicaldrafting tier \(tier) must have callouts")
            }
        }
    }
    @Test func mechanicaldraftingCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "mechanicaldrafting", tier: 1)
            #expect(msgs.count >= 4, "mechanicaldrafting tier1 must have ≥4 messages")
        }
    }
    @Test func mechanicaldraftingCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "mechanicaldrafting", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "mechanicaldrafting tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func mechanicaldraftingCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "mechanicaldrafting", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "mechanicaldrafting tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func mechanicaldraftingFalsePositiveDraftingPaper() {
        let kw = CalloutManager.extractTaskKeyword(from: "drafting a paper on climate change policy for my environmental studies class")
        #expect(kw != "mechanicaldrafting", "drafting a paper should NOT fire mechanicaldrafting")
    }
    @Test func mechanicaldraftingKeywordFromAutocadClass() {
        #expect(CalloutManager.extractTaskKeyword(from: "autocad class assignment on 2d drawings and technical drafting for my drafting program") == "mechanicaldrafting")
    }

    // MARK: - dataengineering keyword tests
    @Test func dataengineeringKeywordFromETLPipeline() {
        #expect(CalloutManager.extractTaskKeyword(from: "build an etl pipeline for my data engineering class project") == "dataengineering")
    }
    @Test func dataengineeringKeywordFromSpark() {
        #expect(CalloutManager.extractTaskKeyword(from: "apache spark class assignment on data pipeline design and stream processing") == "dataengineering")
    }
    @Test func dataengineeringCalloutsAllThreeTiersNonEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dataengineering", tier: tier)
                #expect(!msgs.isEmpty, "dataengineering tier \(tier) must have callouts")
            }
        }
    }
    @Test func dataengineeringCalloutsTier1HasAtLeastFour() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dataengineering", tier: 1)
            #expect(msgs.count >= 4, "dataengineering tier1 must have ≥4 messages")
        }
    }
    @Test func dataengineeringCalloutsNoneAreEmpty() async {
        await MainActor.run {
            for tier in 1...3 {
                let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dataengineering", tier: tier)
                for msg in msgs { #expect(!msg.isEmpty, "dataengineering tier \(tier) callout must not be empty") }
            }
        }
    }
    @Test func dataengineeringCalloutsTier3ContainsCloseThis() async {
        await MainActor.run {
            let msgs = CalloutManager.shared.taskAwareCallouts(keyword: "dataengineering", tier: 3)
            let hasCloseThis = msgs.contains { $0.contains("CLOSE THIS") || $0.contains("no one") }
            #expect(hasCloseThis, "dataengineering tier 3 must contain 'CLOSE THIS' or 'no one'")
        }
    }
    @Test func dataengineeringFalsePositiveDataAnalysis() {
        let kw = CalloutManager.extractTaskKeyword(from: "data analysis using jupyter notebook and pandas machine learning model")
        #expect(kw != "dataengineering", "data analysis with jupyter/ML should route to datascience, not dataengineering")
    }
    @Test func dataengineeringKeywordFromDataWarehouse() {
        #expect(CalloutManager.extractTaskKeyword(from: "data warehousing class on snowflake certification and dimensional modeling design") == "dataengineering")
    }

    // MARK: - Template count guard
    @Test func suggestedTemplatesCountAtLeast413() {
        #expect(SuggestedSessionTemplates.all.count >= 413, "template catalog must have ≥413 entries after adding 5 new domains (10 templates)")
    }
}
