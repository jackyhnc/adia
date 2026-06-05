import Testing
import Foundation
@testable import AdiCore

@MainActor
@Suite("SleepBlocker", .serialized)
struct SleepBlockerTests {

    private func makeBlocker() -> SleepBlocker { SleepBlocker.shared }

    @Test func inactiveByDefault() {
        let b = makeBlocker()
        b.stop()          // ensure clean state
        #expect(!b.isActive)
    }

    @Test func startActivatesBlocker() {
        let b = makeBlocker()
        b.stop()
        b.start()
        #expect(b.isActive)
        b.stop()          // cleanup
    }

    @Test func stopDeactivatesBlocker() {
        let b = makeBlocker()
        b.start()
        b.stop()
        #expect(!b.isActive)
    }

    @Test func doubleStartIsIdempotent() {
        let b = makeBlocker()
        b.stop()
        b.start()
        b.start()         // second call must not double-assert
        #expect(b.isActive)
        b.stop()
    }

    @Test func stopWithoutStartIsNoOp() {
        let b = makeBlocker()
        b.stop()
        // Must not crash or change state to active.
        #expect(!b.isActive)
        b.stop()
        #expect(!b.isActive)
    }

    @Test func restartAfterStopWorks() {
        let b = makeBlocker()
        b.start()
        b.stop()
        #expect(!b.isActive)
        b.start()
        #expect(b.isActive)
        b.stop()
    }
}
