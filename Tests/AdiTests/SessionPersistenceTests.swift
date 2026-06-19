import Testing
import Foundation
@testable import AdiCore

@Suite("SessionPersistence")
struct SessionPersistenceTests {

    @Test func saveLoadRoundTrip() throws {
        let p = SessionPersistence.shared
        let original = Session(
            task: "Write ENGL 101 essay",
            successCriteria: "Submit to Canvas",
            phase: .active,
            whitelistedDomains: ["jstor.org"]
        )
        p.save(original)
        let loaded = try #require(p.load())
        #expect(loaded.id == original.id)
        #expect(loaded.task == original.task)
        #expect(loaded.successCriteria == original.successCriteria)
        #expect(loaded.whitelistedDomains == original.whitelistedDomains)
        p.clear()
    }

    @Test func clearRemovesSession() {
        let p = SessionPersistence.shared
        let s = Session(task: "t", successCriteria: "c")
        p.save(s)
        p.clear()
        #expect(p.load() == nil)
    }

    @Test func loadNilWhenEmpty() {
        let p = SessionPersistence.shared
        p.clear()
        #expect(p.load() == nil)
    }

    @Test func saveLoadRoundTripPreservesCalloutCount() throws {
        let p = SessionPersistence.shared
        let original = Session(
            task: "Write ENGL 101 essay",
            successCriteria: "Submit to Canvas",
            phase: .active,
            calloutCount: 4
        )
        p.save(original)
        let loaded = try #require(p.load())
        #expect(loaded.calloutCount == 4)
        p.clear()
    }

    @Test func calloutCountDefaultsToZeroForLegacySession() throws {
        // Strip the calloutCount key from a freshly-encoded session to simulate old persisted data
        // (sessions saved before callout persistence was added). Uses a valid startTime so the
        // 24-hour staleness guard in load() doesn't discard the record.
        let p = SessionPersistence.shared
        let original = Session(task: "old task", successCriteria: "old criteria", phase: .active, calloutCount: 99)
        let encoded = try JSONEncoder().encode(original)
        let jsonObject = (try JSONSerialization.jsonObject(with: encoded)) as? [String: Any]
        var dict = try #require(jsonObject)
        dict.removeValue(forKey: "calloutCount")
        let stripped = try JSONSerialization.data(withJSONObject: dict)
        UserDefaults.standard.set(stripped, forKey: "adia.activeSession")
        let loaded = try #require(p.load())
        #expect(loaded.calloutCount == 0)
        p.clear()
    }

    @Test func saveLoadRoundTripPreservesVerificationHistory() throws {
        let p = SessionPersistence.shared
        let attempts = [
            VerificationAttempt(
                timestamp: Date(timeIntervalSinceNow: -60),
                result: VerificationResult(verified: false, explanation: "canvas not open"),
                attemptNumber: 1
            ),
            VerificationAttempt(
                timestamp: Date(timeIntervalSinceNow: -10),
                result: VerificationResult(verified: false, explanation: "essay tab not visible"),
                attemptNumber: 2
            ),
        ]
        let original = Session(
            task: "Write ENGL 101 essay",
            successCriteria: "Submit to Canvas",
            phase: .active,
            verificationHistory: attempts
        )
        p.save(original)
        let loaded = try #require(p.load())
        #expect(loaded.verificationHistory.count == 2)
        #expect(loaded.verificationHistory[0].attemptNumber == 1)
        #expect(loaded.verificationHistory[0].result.explanation == "canvas not open")
        #expect(loaded.verificationHistory[1].attemptNumber == 2)
        #expect(loaded.verificationHistory[1].result.verified == false)
        p.clear()
    }

    @Test func verificationHistoryDefaultsToEmptyForLegacySession() throws {
        // Strip the verificationHistory key to simulate sessions persisted before this feature.
        let p = SessionPersistence.shared
        let original = Session(
            task: "old task",
            successCriteria: "old criteria",
            phase: .active,
            verificationHistory: [
                VerificationAttempt(
                    result: VerificationResult(verified: false, explanation: "not done"),
                    attemptNumber: 1
                )
            ]
        )
        let encoded = try JSONEncoder().encode(original)
        let jsonObject = (try JSONSerialization.jsonObject(with: encoded)) as? [String: Any]
        var dict = try #require(jsonObject)
        dict.removeValue(forKey: "verificationHistory")
        let stripped = try JSONSerialization.data(withJSONObject: dict)
        UserDefaults.standard.set(stripped, forKey: "adia.activeSession")
        let loaded = try #require(p.load())
        #expect(loaded.verificationHistory.isEmpty)
        p.clear()
    }

    @Test func saveLoadRoundTripPreservesTargetDuration() throws {
        let p = SessionPersistence.shared
        let original = Session(
            task: "Write essay",
            successCriteria: "Submit to Canvas",
            phase: .active,
            targetDuration: 5400
        )
        p.save(original)
        let loaded = try #require(p.load())
        #expect(loaded.targetDuration == 5400)
        p.clear()
    }

    @Test func targetDurationDefaultsToNilForLegacySession() throws {
        let p = SessionPersistence.shared
        let original = Session(task: "old task", successCriteria: "c", phase: .active, targetDuration: 3600)
        let encoded = try JSONEncoder().encode(original)
        var dict = try #require((try JSONSerialization.jsonObject(with: encoded)) as? [String: Any])
        dict.removeValue(forKey: "targetDuration")
        let stripped = try JSONSerialization.data(withJSONObject: dict)
        UserDefaults.standard.set(stripped, forKey: "adia.activeSession")
        let loaded = try #require(p.load())
        #expect(loaded.targetDuration == nil)
        p.clear()
    }

    @Test func nilTargetDurationRoundTrips() throws {
        let p = SessionPersistence.shared
        let original = Session(task: "t", successCriteria: "c", phase: .active, targetDuration: nil)
        p.save(original)
        let loaded = try #require(p.load())
        #expect(loaded.targetDuration == nil)
        p.clear()
    }
}
