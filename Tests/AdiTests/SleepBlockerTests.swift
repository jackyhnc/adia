import Testing
import Foundation
#if canImport(IOKit)
import IOKit.pwr_mgt
#endif
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

    // MARK: - IOPMCopyAssertionsByProcess integration

    /// Verifies the assertion is actually registered in the OS-level power management
    /// table, not just tracked by our own `isActive` flag.
    /// Skips gracefully when `IOPMCopyAssertionsByProcess` is unavailable (e.g. sandbox).
    @Test func startRegistersAssertionWithOS() {
        #if canImport(IOKit)
        let b = makeBlocker()
        b.stop()
        b.start()
        defer { b.stop() }

        var rawDict: Unmanaged<CFDictionary>?
        let queryResult = IOPMCopyAssertionsByProcess(&rawDict)
        guard queryResult == kIOReturnSuccess, let rawDict else {
            // Sandboxed environments may deny this query — treat as an expected skip.
            return
        }
        let dict = rawDict.takeRetainedValue() as NSDictionary
        let pid = NSNumber(value: ProcessInfo.processInfo.processIdentifier)
        guard let entries = dict[pid] as? [[String: AnyObject]] else {
            // Our PID has no assertions — report the failure with context.
            Issue.record("No power assertions found for pid \(pid); expected 'Adia focus session'")
            return
        }
        let found = entries.contains { entry in
            (entry[kIOPMAssertionNameKey as String] as? String) == "Adia focus session"
        }
        #expect(found, "Expected IOPMAssertion named 'Adia focus session' for pid \(pid)")
        #endif
    }

    @Test func stopRemovesAssertionFromOS() {
        #if canImport(IOKit)
        let b = makeBlocker()
        b.stop()
        b.start()
        b.stop()

        var rawDict: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsByProcess(&rawDict) == kIOReturnSuccess, let rawDict else { return }
        let dict = rawDict.takeRetainedValue() as NSDictionary
        let pid = NSNumber(value: ProcessInfo.processInfo.processIdentifier)
        let entries = dict[pid] as? [[String: AnyObject]] ?? []
        let found = entries.contains { entry in
            (entry[kIOPMAssertionNameKey as String] as? String) == "Adia focus session"
        }
        #expect(!found, "Expected 'Adia focus session' assertion to be gone after stop()")
        #endif
    }
}
