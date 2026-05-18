import Testing
@testable import AdiCore

@Suite("Session Model")
struct SessionStateTests {

    @Test("Default session starts in idle phase")
    func defaultPhaseIsIdle() {
        let s = Session(task: "Write essay", successCriteria: "Submit to Canvas")
        #expect(s.phase == .idle)
    }

    @Test("Default blocked domains are non-empty")
    func defaultBlockedDomainsPopulated() {
        let s = Session(task: "t", successCriteria: "c")
        #expect(!s.defaultBlockedDomains.isEmpty)
    }

    @Test("Whitelisted domains start empty")
    func whitelistedDomainsEmpty() {
        let s = Session(task: "t", successCriteria: "c")
        #expect(s.whitelistedDomains.isEmpty)
    }

    @Test("Elapsed time is non-negative")
    func elapsedNonNegative() {
        let s = Session(task: "t", successCriteria: "c")
        #expect(s.elapsed >= 0)
    }

    @Test("Session is Codable round-trip")
    func codableRoundTrip() throws {
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

@Suite("ChatMessage")
struct ChatMessageTests {

    @Test("Role round-trips through Codable")
    func roleRoundTrip() throws {
        let msg = ChatMessage(role: .assistant, content: "yo, focus up")
        let data = try JSONEncoder().encode(msg)
        let decoded = try JSONDecoder().decode(ChatMessage.self, from: data)
        #expect(decoded.role == .assistant)
        #expect(decoded.content == msg.content)
    }
}

@Suite("VerificationResult")
struct VerificationResultTests {

    @Test("Verified result encodes correctly")
    func verifiedResult() throws {
        let r = VerificationResult(verified: true, explanation: "Canvas shows submitted.")
        let data = try JSONEncoder().encode(r)
        let decoded = try JSONDecoder().decode(VerificationResult.self, from: data)
        #expect(decoded.verified)
        #expect(decoded.explanation == r.explanation)
    }
}
