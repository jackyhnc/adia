import Testing
import Foundation
@testable import AdiCore

@Suite("LicenseManager — state machine")
struct LicenseManagerTests {

    @Test func startsUnknownAfterReset() async {
        await MainActor.run {
            LicenseManager.shared.resetForTesting()
            #expect(LicenseManager.shared.status == .unknown)
            #expect(LicenseManager.shared.isUsable == false)
        }
    }

    @Test func startTrialMovesToTrialState() async {
        await MainActor.run {
            LicenseManager.shared.resetForTesting()
            LicenseManager.shared.startTrialIfNeeded()
            if case .trial(let days) = LicenseManager.shared.status {
                #expect(days >= 6 && days <= 7)
            } else {
                Issue.record("expected .trial, got \(LicenseManager.shared.status)")
            }
            #expect(LicenseManager.shared.isUsable == true)
        }
    }

    @Test func startTrialIsIdempotent() async {
        await MainActor.run {
            LicenseManager.shared.resetForTesting()
            LicenseManager.shared.startTrialIfNeeded()
            // Force trial start to 3 days ago, then call again — should NOT reset to fresh 7 days.
            LicenseManager.shared._setTrialStartDateForTesting(Date().addingTimeInterval(-3 * 86_400))
            LicenseManager.shared.startTrialIfNeeded()
            if case .trial(let days) = LicenseManager.shared.status {
                #expect(days <= 4) // ~4 days left after 3 elapsed
            } else {
                Issue.record("expected .trial, got \(LicenseManager.shared.status)")
            }
        }
    }

    @Test func trialExpiresAfterSevenDays() async {
        await MainActor.run {
            LicenseManager.shared.resetForTesting()
            // Backdate trial start to 8 days ago — well past the 7-day window.
            LicenseManager.shared._setTrialStartDateForTesting(Date().addingTimeInterval(-8 * 86_400))
            #expect(LicenseManager.shared.status == .trialExpired)
            #expect(LicenseManager.shared.isUsable == false)
        }
    }

    @Test func deactivateReturnsToUnknown() async {
        await MainActor.run {
            LicenseManager.shared.resetForTesting()
            LicenseManager.shared.startTrialIfNeeded()
            // Even with an active trial, deactivate (which only clears license)
            // should leave the trial in place — it only removes licensed state.
            LicenseManager.shared.deactivate()
            if case .trial = LicenseManager.shared.status {
                // ok — trial untouched
            } else {
                Issue.record("deactivate should not clear an active trial")
            }
            // Now reset entirely and confirm unknown.
            LicenseManager.shared.resetForTesting()
            #expect(LicenseManager.shared.status == .unknown)
        }
    }

    @Test func isUsableMatrix() async {
        await MainActor.run {
            LicenseManager.shared.resetForTesting()
            // unknown
            #expect(LicenseManager.shared.isUsable == false)
            // trial
            LicenseManager.shared.startTrialIfNeeded()
            #expect(LicenseManager.shared.isUsable == true)
            // trialExpired
            LicenseManager.shared._setTrialStartDateForTesting(Date().addingTimeInterval(-30 * 86_400))
            #expect(LicenseManager.shared.isUsable == false)
        }
    }
}
