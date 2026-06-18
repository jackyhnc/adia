import Testing
import Foundation
@testable import AdiCore

@Suite("ScreenCaptureManager constants")
struct ScreenCaptureManagerConstantsTests {

    @Test func maxRecoveryAttemptsIsThree() {
        #expect(ScreenCaptureManager.maxRecoveryAttempts == 3)
    }

    @Test func recoveryBaseDelayIsTwoSeconds() {
        #expect(ScreenCaptureManager.recoveryBaseDelay == 2.0)
    }

    @Test func frameStalenessTimeoutIsTenSeconds() {
        #expect(ScreenCaptureManager.frameStalenessTimeout == 10.0)
    }

    @Test func watchdogCheckIntervalIsFiveSeconds() {
        #expect(ScreenCaptureManager.watchdogCheckInterval == 5.0)
    }

    @Test func watchdogFasterThanStalenessTimeout() {
        #expect(ScreenCaptureManager.watchdogCheckInterval < ScreenCaptureManager.frameStalenessTimeout)
    }

    @Test func recoveryBackoffFormula() {
        let base = ScreenCaptureManager.recoveryBaseDelay
        let expected = [base * 1, base * 2, base * 4]
        for attempt in 1...ScreenCaptureManager.maxRecoveryAttempts {
            let delay = base * pow(2.0, Double(attempt - 1))
            #expect(delay == expected[attempt - 1])
        }
    }
}

@Suite("ScreenCaptureManager singleton")
struct ScreenCaptureManagerSingletonTests {

    @Test func sharedIsSameInstance() {
        let a = ScreenCaptureManager.shared
        let b = ScreenCaptureManager.shared
        #expect(a === b)
    }

    @Test func stopIsIdempotent() {
        let mgr = ScreenCaptureManager.shared
        mgr.stop()
        mgr.stop()
    }
}

#if !canImport(ScreenCaptureKit)
@Suite("ScreenCaptureManager stub (non-macOS)")
struct ScreenCaptureManagerStubTests {

    @Test func lastFrameAlwaysNil() {
        #expect(ScreenCaptureManager.shared.lastFrame == nil)
    }

    @Test func lastFrameReceivedAtAlwaysNil() {
        #expect(ScreenCaptureManager.shared.lastFrameReceivedAt == nil)
    }

    @Test func startThrowsUnavailable() async {
        do {
            try await ScreenCaptureManager.shared.start()
            Issue.record("Expected CaptureError.unavailable")
        } catch is CaptureError {
            // expected
        } catch {
            Issue.record("Wrong error type: \(error)")
        }
    }
}
#endif
