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
}
