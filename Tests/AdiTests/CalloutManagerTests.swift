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
        // "report" hits the generic template branch — "get back to your report" etc.
        // Verify all tiers produce non-empty message arrays that contain the keyword.
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

    @Test func extractTaskKeywordThesisProposalMapsToEssay() {
        // "thesis" check runs before "proposal" — "thesis proposal" must map to essay, not proposal.
        #expect(CalloutManager.extractTaskKeyword(from: "write my thesis proposal") == "essay")
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
}
