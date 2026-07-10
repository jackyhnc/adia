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
}
