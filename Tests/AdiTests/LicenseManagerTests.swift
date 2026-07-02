import Testing
import Foundation
@testable import AdiCore

// MARK: - Mock URL protocol for intercepting HTTP calls in tests

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    /// Set this before each test that triggers a network call.
    static var requestHandler: (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private func makeMockSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

private func makeISO() -> ISO8601DateFormatter { ISO8601DateFormatter() }

// MARK: - Suite

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

    // MARK: - fetchSeats tests

    @Test func fetchSeatsPopulatesSeatsOnSuccess() async {
        let iso = makeISO()
        let firstSeen = Date(timeIntervalSinceNow: -86400 * 3)
        let lastSeen  = Date(timeIntervalSinceNow: -3600)

        await MainActor.run {
            LicenseManager.shared.resetForTesting()
            LicenseManager.shared._injectLicenseForTesting(LicenseInfo(
                key: "ADIA-SEAT-TEST-0001",
                email: "seat@example.com",
                plan: "monthly",
                issuedAt: Date(timeIntervalSinceNow: -86400),
                expiresAt: nil,
                lastValidatedAt: Date()
            ))
        }

        let responseBody: [String: Any] = [
            "key": "ADIA-SEAT-TEST-0001",
            "plan": "monthly",
            "status": "active",
            "seatCount": 2,
            "seats": [
                ["machineHash": "aabbccdd11223344", "firstSeen": iso.string(from: firstSeen), "lastSeen": iso.string(from: lastSeen)],
                ["machineHash": "deadbeefcafebabe", "firstSeen": iso.string(from: firstSeen), "lastSeen": iso.string(from: lastSeen)],
            ],
        ]

        MockURLProtocol.requestHandler = { req in
            let data = try JSONSerialization.data(withJSONObject: responseBody)
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (resp, data)
        }

        await MainActor.run { LicenseManager.shared.urlSession = makeMockSession() }
        await LicenseManager.shared.fetchSeats()

        await MainActor.run {
            #expect(LicenseManager.shared.seats.count == 2)
            #expect(LicenseManager.shared.seats[0].machineHash == "aabbccdd11223344")
            #expect(LicenseManager.shared.seats[1].machineHash == "deadbeefcafebabe")
            #expect(LicenseManager.shared.seatsLoading == false)
        }
    }

    @Test func fetchSeatsNoopsWhenNotLicensed() async {
        await MainActor.run {
            LicenseManager.shared.resetForTesting() // status == .unknown
            LicenseManager.shared.urlSession = makeMockSession()
        }
        // If fetchSeats fires a request we'll crash because requestHandler is nil.
        MockURLProtocol.requestHandler = nil

        await LicenseManager.shared.fetchSeats()

        await MainActor.run {
            #expect(LicenseManager.shared.seats.isEmpty)
            #expect(LicenseManager.shared.seatsLoading == false)
        }
    }

    @Test func fetchSeatsHandlesServerError() async {
        await MainActor.run {
            LicenseManager.shared.resetForTesting()
            LicenseManager.shared._injectLicenseForTesting(LicenseInfo(
                key: "ADIA-SEAT-ERR-0001",
                email: "err@example.com",
                plan: "yearly",
                issuedAt: Date(),
                expiresAt: nil,
                lastValidatedAt: Date()
            ))
            LicenseManager.shared.urlSession = makeMockSession()
        }

        MockURLProtocol.requestHandler = { req in
            let data = try JSONSerialization.data(withJSONObject: ["error": "internal error"])
            let resp = HTTPURLResponse(url: req.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
            return (resp, data)
        }

        await LicenseManager.shared.fetchSeats()

        // Should not crash and seats should stay empty
        await MainActor.run {
            #expect(LicenseManager.shared.seats.isEmpty)
            #expect(LicenseManager.shared.seatsLoading == false)
        }
    }

    // MARK: - deactivateMachine tests

    @Test func deactivateMachineSuccessReturnsNil() async {
        let iso = makeISO()
        let now  = Date()
        let past = now.addingTimeInterval(-86400)

        await MainActor.run {
            LicenseManager.shared.resetForTesting()
            LicenseManager.shared._injectLicenseForTesting(LicenseInfo(
                key: "ADIA-DEAC-TEST-0001",
                email: "deac@example.com",
                plan: "lifetime",
                issuedAt: past,
                expiresAt: nil,
                lastValidatedAt: now
            ))
            LicenseManager.shared.urlSession = makeMockSession()
        }

        // First call = deactivate (POST /api/license/deactivate → 200)
        // Second call = fetchSeats (GET /api/license/seats → 200 with empty seats)
        var callCount = 0
        MockURLProtocol.requestHandler = { req in
            callCount += 1
            if callCount == 1 {
                // deactivate response
                let data = try JSONSerialization.data(withJSONObject: ["ok": true, "key": "ADIA-DEAC-TEST-0001", "seatsNow": 0])
                let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (resp, data)
            } else {
                // fetchSeats response (triggered internally after deactivation)
                let data = try JSONSerialization.data(withJSONObject: [
                    "key": "ADIA-DEAC-TEST-0001", "plan": "lifetime",
                    "status": "active", "seatCount": 0, "seats": [] as [[String: String]],
                ])
                let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                return (resp, data)
            }
        }

        let errorMsg = await LicenseManager.shared.deactivateMachine("oldmachinehash1234")

        #expect(errorMsg == nil)
        await MainActor.run {
            #expect(LicenseManager.shared.seats.isEmpty)
        }
    }

    @Test func deactivateMachineReturnsErrorWhenNotLicensed() async {
        await MainActor.run {
            LicenseManager.shared.resetForTesting() // status == .unknown
            LicenseManager.shared.urlSession = makeMockSession()
        }
        MockURLProtocol.requestHandler = nil // should never be called

        let errorMsg = await LicenseManager.shared.deactivateMachine("some-machine-hash")
        #expect(errorMsg != nil)
        #expect(errorMsg == "Not licensed.")
    }

    @Test func deactivateMachineReturnsErrorOnServerFailure() async {
        await MainActor.run {
            LicenseManager.shared.resetForTesting()
            LicenseManager.shared._injectLicenseForTesting(LicenseInfo(
                key: "ADIA-DEAC-FAIL-0001",
                email: "fail@example.com",
                plan: "monthly",
                issuedAt: Date(),
                expiresAt: nil,
                lastValidatedAt: Date()
            ))
            LicenseManager.shared.urlSession = makeMockSession()
        }

        MockURLProtocol.requestHandler = { req in
            let data = try JSONSerialization.data(withJSONObject: ["error": "machine not found"])
            let resp = HTTPURLResponse(url: req.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
            return (resp, data)
        }

        let errorMsg = await LicenseManager.shared.deactivateMachine("nonexistent-machine")
        #expect(errorMsg != nil)
        // Error message should contain context, not be nil
        if let msg = errorMsg {
            #expect(msg.hasPrefix("Could not deactivate:"))
        }
    }

    // MARK: - changeEmail tests

    @Test func changeEmailSuccessUpdatesStatusEmail() async {
        await MainActor.run {
            LicenseManager.shared.resetForTesting()
            LicenseManager.shared._injectLicenseForTesting(LicenseInfo(
                key: "ADIA-CHNG-TEST-0001",
                email: "old@example.com",
                plan: "lifetime",
                issuedAt: Date(timeIntervalSinceNow: -86400),
                expiresAt: nil,
                lastValidatedAt: Date()
            ))
            LicenseManager.shared.urlSession = makeMockSession()
        }

        MockURLProtocol.requestHandler = { req in
            let data = try JSONSerialization.data(withJSONObject: [
                "ok": true,
                "key": "ADIA-CHNG-TEST-0001",
                "email": "new@example.com",
                "plan": "lifetime",
            ])
            let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
            return (resp, data)
        }

        let err = await LicenseManager.shared.changeEmail(newEmail: "New@Example.com")
        #expect(err == nil)
        await MainActor.run {
            if case .licensed(let em, _) = LicenseManager.shared.status {
                #expect(em == "new@example.com")
            } else {
                Issue.record("expected .licensed after changeEmail, got \(LicenseManager.shared.status)")
            }
        }
    }

    @Test func changeEmailReturnsErrorWhenNotLicensed() async {
        await MainActor.run {
            LicenseManager.shared.resetForTesting() // status == .unknown
            LicenseManager.shared.urlSession = makeMockSession()
        }
        MockURLProtocol.requestHandler = nil // must not be called

        let err = await LicenseManager.shared.changeEmail(newEmail: "any@example.com")
        #expect(err == "Not licensed.")
    }

    @Test func changeEmailReturnsErrorOnServerFailure() async {
        await MainActor.run {
            LicenseManager.shared.resetForTesting()
            LicenseManager.shared._injectLicenseForTesting(LicenseInfo(
                key: "ADIA-CHNG-FAIL-0001",
                email: "current@example.com",
                plan: "monthly",
                issuedAt: Date(),
                expiresAt: nil,
                lastValidatedAt: Date()
            ))
            LicenseManager.shared.urlSession = makeMockSession()
        }

        MockURLProtocol.requestHandler = { req in
            let data = try JSONSerialization.data(withJSONObject: ["error": "email already in use"])
            let resp = HTTPURLResponse(url: req.url!, statusCode: 422, httpVersion: nil, headerFields: nil)!
            return (resp, data)
        }

        let err = await LicenseManager.shared.changeEmail(newEmail: "taken@example.com")
        #expect(err != nil)
        if let msg = err {
            #expect(msg.hasPrefix("Could not update email:"))
        }
    }

    @Test func changeEmailRejectsEmptyNewEmail() async {
        await MainActor.run {
            LicenseManager.shared.resetForTesting()
            LicenseManager.shared._injectLicenseForTesting(LicenseInfo(
                key: "ADIA-CHNG-EMTY-0001",
                email: "user@example.com",
                plan: "yearly",
                issuedAt: Date(),
                expiresAt: nil,
                lastValidatedAt: Date()
            ))
            LicenseManager.shared.urlSession = makeMockSession()
        }
        MockURLProtocol.requestHandler = nil // must not be called

        let err = await LicenseManager.shared.changeEmail(newEmail: "   ")
        #expect(err == "New email is empty.")
    }

    @Test func changeEmailRejectsSameEmailAsCurrentEmail() async {
        await MainActor.run {
            LicenseManager.shared.resetForTesting()
            LicenseManager.shared._injectLicenseForTesting(LicenseInfo(
                key: "ADIA-CHNG-SAME-0001",
                email: "same@example.com",
                plan: "lifetime",
                issuedAt: Date(),
                expiresAt: nil,
                lastValidatedAt: Date()
            ))
            LicenseManager.shared.urlSession = makeMockSession()
        }
        MockURLProtocol.requestHandler = nil // must not be called

        // Supply same email in different case — still same after normalization
        let err = await LicenseManager.shared.changeEmail(newEmail: "SAME@Example.COM")
        #expect(err == "New email is the same as your current email.")
    }
}
