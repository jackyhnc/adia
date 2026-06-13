import Testing
import Foundation
@testable import AdiCore

@Suite("Session model")
struct SessionModelTests {

    @Test func defaultPhaseIsIdle() {
        let s = Session(task: "Write essay", successCriteria: "Submit to Canvas")
        #expect(s.phase == .idle)
    }

    @Test func defaultBlockedDomainsPopulated() {
        #expect(!Session.defaultBlockedDomains.isEmpty)
    }

    @Test func defaultBlockedDomainsIncludeCoreDistractors() {
        let domains = Session.defaultBlockedDomains
        for expected in ["twitter.com", "reddit.com", "youtube.com", "instagram.com",
                         "tiktok.com", "facebook.com", "netflix.com", "linkedin.com",
                         "amazon.com"] {
            #expect(domains.contains(expected), "expected \(expected) in default blocked domains")
        }
    }

    @Test func whitelistedDomainsEmpty() {
        let s = Session(task: "t", successCriteria: "c")
        #expect(s.whitelistedDomains.isEmpty)
    }

    @Test func elapsedNonNegative() {
        let s = Session(task: "t", successCriteria: "c")
        #expect(s.elapsed >= 0)
    }

    @Test func elapsedReflectsStartTime() {
        let startTime = Date(timeIntervalSinceNow: -60)
        let s = Session(task: "t", successCriteria: "c", startTime: startTime)
        // Allow ±2s of test-execution jitter around the expected 60s
        #expect(s.elapsed >= 58 && s.elapsed <= 62)
    }

    @Test func codableRoundTrip() throws {
        let original = Session(
            task: "Write essay",
            successCriteria: "Submit",
            phase: .active,
            whitelistedDomains: ["example.com"]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Session.self, from: data)
        #expect(decoded.id == original.id)
        #expect(decoded.task == original.task)
        #expect(decoded.phase == original.phase)
        #expect(decoded.whitelistedDomains == original.whitelistedDomains)
    }
}

@Suite("Session duration goal")
struct SessionDurationTests {

    @Test func targetDurationDefaultsToNil() {
        let s = Session(task: "t", successCriteria: "c")
        #expect(s.targetDuration == nil)
    }

    @Test func targetDurationStoredInInit() {
        let s = Session(task: "t", successCriteria: "c", targetDuration: 5400)
        #expect(s.targetDuration == 5400)
    }

    @Test func targetDurationPreservedInCodableRoundTrip() throws {
        let s = Session(task: "t", successCriteria: "c", targetDuration: 5400)
        let data = try JSONEncoder().encode(s)
        let decoded = try JSONDecoder().decode(Session.self, from: data)
        #expect(decoded.targetDuration == 5400)
    }

    @Test func nilTargetDurationPreservedInCodableRoundTrip() throws {
        let s = Session(task: "t", successCriteria: "c", targetDuration: nil)
        let data = try JSONEncoder().encode(s)
        let decoded = try JSONDecoder().decode(Session.self, from: data)
        #expect(decoded.targetDuration == nil)
    }

    @Test func legacySessionWithoutTargetDurationDecodesAsNil() throws {
        let s = Session(task: "old task", successCriteria: "c", phase: .active, targetDuration: 3600)
        let encoded = try JSONEncoder().encode(s)
        var dict = try #require((try JSONSerialization.jsonObject(with: encoded)) as? [String: Any])
        dict.removeValue(forKey: "targetDuration")
        let stripped = try JSONSerialization.data(withJSONObject: dict)
        let decoded = try JSONDecoder().decode(Session.self, from: stripped)
        #expect(decoded.targetDuration == nil)
    }

    @Test func targetDurationNotEncodedWhenNil() throws {
        let s = Session(task: "t", successCriteria: "c", targetDuration: nil)
        let data = try JSONEncoder().encode(s)
        let dict = try #require((try JSONSerialization.jsonObject(with: data)) as? [String: Any])
        #expect(dict["targetDuration"] == nil)
    }

    // MARK: - reasoningHistory

    @Test func reasoningHistoryDefaultsToEmpty() {
        let s = Session(task: "t", successCriteria: "c")
        #expect(s.reasoningHistory.isEmpty)
    }

    @Test func reasoningHistoryPreservedInCodableRoundTrip() throws {
        let attempt = ReasoningAttempt(domain: "youtube.com", granted: false, summary: "no academic reason given")
        let s = Session(task: "t", successCriteria: "c", reasoningHistory: [attempt])
        let data = try JSONEncoder().encode(s)
        let decoded = try JSONDecoder().decode(Session.self, from: data)
        #expect(decoded.reasoningHistory.count == 1)
        #expect(decoded.reasoningHistory[0].domain == "youtube.com")
        #expect(decoded.reasoningHistory[0].granted == false)
        #expect(decoded.reasoningHistory[0].summary == "no academic reason given")
    }

    @Test func legacySessionWithoutReasoningHistoryDecodesAsEmpty() throws {
        let s = Session(task: "old task", successCriteria: "c", phase: .active)
        let encoded = try JSONEncoder().encode(s)
        var dict = try #require((try JSONSerialization.jsonObject(with: encoded)) as? [String: Any])
        dict.removeValue(forKey: "reasoningHistory")
        let stripped = try JSONSerialization.data(withJSONObject: dict)
        let decoded = try JSONDecoder().decode(Session.self, from: stripped)
        #expect(decoded.reasoningHistory.isEmpty)
    }
}

@Suite("ChatMessage")
struct ChatMessageTests {

    @Test func roleRoundTrip() throws {
        let msg = ChatMessage(role: .assistant, content: "yo, focus up")
        let data = try JSONEncoder().encode(msg)
        let decoded = try JSONDecoder().decode(ChatMessage.self, from: data)
        #expect(decoded.role == ChatMessage.Role.assistant)
        #expect(decoded.content == msg.content)
    }
}

@Suite("VerificationResult")
struct VerificationResultTests {

    @Test func verifiedResultEncodesCorrectly() throws {
        let r = VerificationResult(verified: true, explanation: "Canvas shows submitted.")
        let data = try JSONEncoder().encode(r)
        let decoded = try JSONDecoder().decode(VerificationResult.self, from: data)
        #expect(decoded.verified)
        #expect(decoded.explanation == r.explanation)
    }
}
