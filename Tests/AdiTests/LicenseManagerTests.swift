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
            LicenseManager.shared._setTrialStartDateForTesting(Date().addingTimeInterval(-8 * 86_400))
            #expect(LicenseManager.shared.status == .trialExpired)
            #expect(LicenseManager.shared.isUsable == false)
        }
    }

    @Test func licensedFromInjectedInfo() async {
        await MainActor.run {
            LicenseManager.shared.resetForTesting()
            let info = LicenseInfo(
                key: "ADIA-TEST-TEST-TEST",
                email: "test@example.com",
                plan: "lifetime",
                issuedAt: Date(),
                expiresAt: nil,
                lastValidatedAt: Date()
            )
            LicenseManager.shared._injectLicenseForTesting(info)
            if case .licensed(let email, let plan) = LicenseManager.shared.status {
                #expect(email == "test@example.com")
                #expect(plan == "lifetime")
            } else {
                Issue.record("expected .licensed, got \(LicenseManager.shared.status)")
            }
            #expect(LicenseManager.shared.isUsable == true)
        }
    }

    @Test func deactivateClearsLicenseKeychain() async {
        await MainActor.run {
            LicenseManager.shared.resetForTesting()
            let info = LicenseInfo(
                key: "ADIA-DACT-TEST-0001",
                email: "user@example.com",
                plan: "monthly",
                issuedAt: Date(),
                expiresAt: nil,
                lastValidatedAt: Date()
            )
            LicenseManager.shared._injectLicenseForTesting(info)
            LicenseManager.shared.deactivate()
            // License should be gone from Keychain
            #expect(LicenseManager.shared.currentLicense() == nil)
        }
    }

    @Test func offlineGraceKeepsLicensedWithinWindow() async {
        await MainActor.run {
            LicenseManager.shared.resetForTesting()
            // License expired yesterday but lastValidated only 3 hours ago — within 14-day grace
            let yesterday = Date(timeIntervalSinceNow: -86400)
            let info = LicenseInfo(
                key: "ADIA-GRCE-TEST-0001",
                email: "grace@example.com",
                plan: "monthly",
                issuedAt: Date(timeIntervalSinceNow: -32 * 86400),
                expiresAt: yesterday,
                lastValidatedAt: Date(timeIntervalSinceNow: -3600)
            )
            LicenseManager.shared._injectLicenseForTesting(info)
            if case .licensed = LicenseManager.shared.status { } else {
                Issue.record("expected .licensed within grace period, got \(LicenseManager.shared.status)")
            }
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
