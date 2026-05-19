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

    // Fires after threshold (2) consecutive off-task frames, not before.
    @Test func offTaskThresholdFires() async {
        await MainActor.run {
            // Reset state
            CalloutManager.shared.evaluate(.onTask)
            NotchState.shared.clearCallout()

            // First off-task frame: below threshold (threshold = 2)
            CalloutManager.shared.evaluate(.offTask)
            #expect(NotchState.shared.calloutMessage == nil, "should not fire before threshold")

            // Second off-task frame: meets threshold
            CalloutManager.shared.evaluate(.offTask)
            #expect(NotchState.shared.calloutMessage != nil, "should fire at threshold")

            // Third off-task frame: already fired, no duplicate
            let afterTwo = NotchState.shared.calloutMessage
            CalloutManager.shared.evaluate(.offTask)
            #expect(NotchState.shared.calloutMessage == afterTwo, "should not change after streak already fired")

            // Back on task resets the streak
            CalloutManager.shared.evaluate(.onTask)
            #expect(NotchState.shared.calloutMessage == nil, "onTask clears callout")
        }
    }

    // Streak resets let a second callout fire on new off-task run.
    @Test func streakResetsOnOnTask() async {
        await MainActor.run {
            CalloutManager.shared.evaluate(.onTask)
            NotchState.shared.clearCallout()

            // First streak
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask)
            #expect(NotchState.shared.calloutMessage != nil)

            // Reset with onTask
            CalloutManager.shared.evaluate(.onTask)
            #expect(NotchState.shared.calloutMessage == nil)

            // Second streak should also fire
            CalloutManager.shared.evaluate(.offTask)
            CalloutManager.shared.evaluate(.offTask)
            #expect(NotchState.shared.calloutMessage != nil, "second streak should also fire")

            CalloutManager.shared.evaluate(.onTask)
        }
    }
}
