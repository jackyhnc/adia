import Foundation
#if canImport(IOKit)
import IOKit.pwr_mgt
#endif

/// Prevents the display from sleeping while a focus session is active.
/// Wraps IOPMAssertionCreateWithName / IOPMAssertionRelease.
/// On non-macOS platforms the implementation is a no-op stub (tracks state only).
@MainActor
public final class SleepBlocker {
    public static let shared = SleepBlocker()

    #if canImport(IOKit)
    private var assertionID: IOPMAssertionID = 0
    #endif
    private var _isActive = false

    private init() {}

    /// Prevents the display from sleeping. Idempotent — calling more than once is safe.
    public func start() {
        guard !_isActive else { return }
        #if canImport(IOKit)
        let result = IOPMAssertionCreateWithName(
            kIOPMAssertPreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            "Adia focus session" as CFString,
            &assertionID
        )
        _isActive = (result == kIOReturnSuccess)
        #else
        _isActive = true
        #endif
    }

    /// Re-enables display sleep. Safe to call without a prior start().
    public func stop() {
        guard _isActive else { return }
        #if canImport(IOKit)
        IOPMAssertionRelease(assertionID)
        assertionID = 0
        #endif
        _isActive = false
    }

    public var isActive: Bool { _isActive }
}
