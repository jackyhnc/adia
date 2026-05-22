import Testing
@testable import AdiCore

@Suite("CalloutManager")
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
}
