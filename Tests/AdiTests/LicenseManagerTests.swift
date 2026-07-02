import Testing
import Foundation
@testable import AdiCore

// MARK: - LockedBox

/// Thread-safe mutable wrapper for test use. Lets Swift 6 @Sendable closures capture
/// mutable state by reference without triggering strict-concurrency errors.
final class LockedBox<T>: @unchecked Sendable {
    private var _value: T
    private let lock = NSLock()
    init(_ value: T) { _value = value }
    var value: T {
        get { lock.withLock { _value } }
        set { lock.withLock { _value = newValue } }
    }
    func mutate(_ body: (inout T) -> Void) { lock.withLock { body(&_value) } }
}

// MARK: - MockURLProtocol

/// URLProtocol stub that intercepts every request made through a URLSession whose
/// configuration lists `MockURLProtocol` in `protocolClasses`. Register a per-test
/// handler via `setHandler(_:)` and call `clearHandler()` after.
final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) -> (statusCode: Int, body: Data)

    private static let lock = NSLock()
    private static var _handler: Handler?

    static func setHandler(_ h: @escaping Handler) { lock.withLock { _handler = h } }
    static func clearHandler() { lock.withLock { _handler = nil } }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let handler = Self.lock.withLock { Self._handler }
        let (status, body) = handler?(request) ?? (500, Data("{}".utf8))
        // Force-unwrap: url on a URLRequest that passed canInit is always non-nil.
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

// MARK: - LicenseManager — state machine

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
            // Force trial start to 3 days ago — second call should NOT reset to fresh 7 days.
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
            #expect(LicenseManager.shared.currentLicense() == nil)
        }
    }

    @Test func offlineGraceKeepsLicensedWithinWindow() async {
        await MainActor.run {
            LicenseManager.shared.resetForTesting()
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
            #expect(LicenseManager.shared.isUsable == false)
            LicenseManager.shared.startTrialIfNeeded()
            #expect(LicenseManager.shared.isUsable == true)
            LicenseManager.shared._setTrialStartDateForTesting(Date().addingTimeInterval(-30 * 86_400))
            #expect(LicenseManager.shared.isUsable == false)
        }
    }
}

// MARK: - LicenseManager — seats API (mocked network)

@Suite("LicenseManager — seats API")
struct LicenseManagerSeatsTests {

    private func mockSession() -> URLSession {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: cfg)
    }

    @MainActor
    private func setupLicensed(key: String = "ADIA-SEAT-TEST-0001",
                                email: String = "seats@example.com") {
        LicenseManager.shared.resetForTesting()
        LicenseManager.shared._injectLicenseForTesting(LicenseInfo(
            key: key, email: email, plan: "lifetime",
            issuedAt: Date(), expiresAt: nil, lastValidatedAt: Date()
        ))
        LicenseManager.shared.urlSession = mockSession()
    }

    @MainActor
    private func cleanup() {
        MockURLProtocol.clearHandler()
        LicenseManager.shared.resetForTesting()
        LicenseManager.shared.urlSession = .shared
    }

    // MARK: fetchSeats

    @Test func fetchSeatsPopulatesSeats() async {
        let iso = ISO8601DateFormatter()
        let now = iso.string(from: Date())
        let yesterday = iso.string(from: Date(timeIntervalSinceNow: -86400))
        let body = """
        {"key":"ADIA-SEAT-TEST-0001","plan":"lifetime","status":"active","seatCount":2,
         "seats":[
           {"machineHash":"aabbccdd11223344","firstSeen":"\(yesterday)","lastSeen":"\(now)"},
           {"machineHash":"deadbeef00000000","firstSeen":"\(yesterday)","lastSeen":"\(yesterday)"}
         ]}
        """.data(using: .utf8)!

        MockURLProtocol.setHandler { _ in (200, body) }
        await MainActor.run { setupLicensed() }
        await LicenseManager.shared.fetchSeats()
        await MainActor.run {
            #expect(LicenseManager.shared.seats.count == 2)
            #expect(LicenseManager.shared.seats[0].machineHash == "aabbccdd11223344")
            #expect(LicenseManager.shared.seats[1].machineHash == "deadbeef00000000")
            #expect(LicenseManager.shared.seatsLoading == false)
            cleanup()
        }
    }

    @Test func fetchSeatsHandlesServerError() async {
        MockURLProtocol.setHandler { _ in
            (401, #"{"error":"unauthorized"}"#.data(using: .utf8)!)
        }
        await MainActor.run { setupLicensed() }
        await LicenseManager.shared.fetchSeats()
        await MainActor.run {
            #expect(LicenseManager.shared.seats.isEmpty)
            #expect(LicenseManager.shared.seatsLoading == false)
            cleanup()
        }
    }

    @Test func fetchSeatsNoOpsWhenNotLicensed() async {
        let requestMade = LockedBox(false)
        MockURLProtocol.setHandler { _ in
            requestMade.value = true
            return (200, Data())
        }
        await MainActor.run {
            LicenseManager.shared.resetForTesting()  // not licensed
            LicenseManager.shared.urlSession = mockSession()
        }
        await LicenseManager.shared.fetchSeats()
        await MainActor.run {
            #expect(!requestMade.value, "fetchSeats must not touch the network when not licensed")
            #expect(LicenseManager.shared.seats.isEmpty)
            cleanup()
        }
    }

    @Test func fetchSeatsIgnoresRowsWithBadDates() async {
        let goodDate = ISO8601DateFormatter().string(from: Date())
        let body = """
        {"key":"ADIA-SEAT-TEST-0001","plan":"lifetime","status":"active","seatCount":2,
         "seats":[
           {"machineHash":"goodhash00000001","firstSeen":"\(goodDate)","lastSeen":"\(goodDate)"},
           {"machineHash":"badhash000000002","firstSeen":"not-a-date","lastSeen":"\(goodDate)"}
         ]}
        """.data(using: .utf8)!

        MockURLProtocol.setHandler { _ in (200, body) }
        await MainActor.run { setupLicensed() }
        await LicenseManager.shared.fetchSeats()
        await MainActor.run {
            // Bad-date row silently dropped by compactMap in serverFetchSeats.
            #expect(LicenseManager.shared.seats.count == 1)
            #expect(LicenseManager.shared.seats[0].machineHash == "goodhash00000001")
            cleanup()
        }
    }

    // MARK: deactivateMachine

    @Test func deactivateMachineSuccessRefreshesSeats() async {
        let callCount = LockedBox(0)
        MockURLProtocol.setHandler { req in
            callCount.mutate { $0 += 1 }
            if req.httpMethod == "POST", (req.url?.path ?? "").hasSuffix("/deactivate") {
                return (200, #"{"ok":true,"key":"ADIA-SEAT-TEST-0001","seatsNow":0}"#.data(using: .utf8)!)
            }
            // GET /seats — called automatically by fetchSeats() after deactivate succeeds.
            return (200, #"{"key":"ADIA-SEAT-TEST-0001","plan":"lifetime","status":"active","seatCount":0,"seats":[]}"#.data(using: .utf8)!)
        }
        await MainActor.run { setupLicensed() }

        let error = await LicenseManager.shared.deactivateMachine("aabbccdd11223344")

        await MainActor.run {
            #expect(error == nil)
            #expect(LicenseManager.shared.seats.isEmpty)
            // POST /deactivate (1) + GET /seats via fetchSeats (2).
            #expect(callCount.value == 2)
            cleanup()
        }
    }

    @Test func deactivateMachineReturnsErrorOnServerFailure() async {
        MockURLProtocol.setHandler { _ in
            (404, #"{"error":"Machine not found in activations."}"#.data(using: .utf8)!)
        }
        await MainActor.run { setupLicensed() }

        let error = await LicenseManager.shared.deactivateMachine("nonexistent00000")

        await MainActor.run {
            #expect(error != nil)
            #expect(error?.contains("Could not deactivate") == true)
            cleanup()
        }
    }

    @Test func deactivateMachineNoOpsWhenNotLicensed() async {
        let requestMade = LockedBox(false)
        MockURLProtocol.setHandler { _ in
            requestMade.value = true
            return (200, Data())
        }
        await MainActor.run {
            LicenseManager.shared.resetForTesting()  // not licensed
            LicenseManager.shared.urlSession = mockSession()
        }

        let error = await LicenseManager.shared.deactivateMachine("anyhash00000000")

        await MainActor.run {
            #expect(error == "Not licensed.")
            #expect(!requestMade.value, "deactivateMachine must not touch the network when not licensed")
            cleanup()
        }
    }
}
