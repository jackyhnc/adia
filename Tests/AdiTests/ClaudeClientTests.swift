import Testing
@testable import AdiCore

// Tests for pure parsing logic in ClaudeClient — no network calls, no API key required.

@Suite("ClaudeClient response parsing")
struct ClaudeClientParsingTests {

    @Test("OnTaskClassification parses onTask")
    func parsesOnTask() {
        let classification = ClaudeClientTestHelper.parseClassification(
            #"{"status":"onTask","confidence":0.95,"reason":"Screen shows essay editor."}"#
        )
        #expect(classification.status == .onTask)
        #expect(classification.confidence == 0.95)
        #expect(classification.reason == "Screen shows essay editor.")
    }

    @Test("OnTaskClassification parses offTask")
    func parsesOffTask() {
        let classification = ClaudeClientTestHelper.parseClassification(
            #"{"status":"offTask","confidence":0.88,"reason":"Reddit open."}"#
        )
        #expect(classification.status == .offTask)
        #expect(classification.confidence == 0.88)
    }

    @Test("OnTaskClassification falls back to ambiguous on bad JSON")
    func fallsBackOnBadJson() {
        let classification = ClaudeClientTestHelper.parseClassification("not json at all")
        #expect(classification.status == .ambiguous)
        #expect(classification.confidence == 0.5)
    }

    @Test("OnTaskClassification strips markdown fences")
    func stripsMarkdownFences() {
        let raw = "```json\n{\"status\":\"onTask\",\"confidence\":0.9,\"reason\":\"ok\"}\n```"
        let classification = ClaudeClientTestHelper.parseClassification(raw)
        #expect(classification.status == .onTask)
    }

    @Test("VerificationResult parses verified=true")
    func parsesVerified() {
        let result = ClaudeClientTestHelper.parseVerification(
            #"{"verified":true,"explanation":"Canvas confirmation page visible."}"#
        )
        #expect(result.verified == true)
        #expect(result.explanation == "Canvas confirmation page visible.")
    }

    @Test("VerificationResult parses verified=false")
    func parsesNotVerified() {
        let result = ClaudeClientTestHelper.parseVerification(
            #"{"verified":false,"explanation":"No submission receipt on screen."}"#
        )
        #expect(result.verified == false)
    }

    @Test("VerificationResult falls back on bad JSON")
    func verificationFallsBack() {
        let result = ClaudeClientTestHelper.parseVerification("garbage")
        #expect(result.verified == false)
    }

    @Test("VerificationResult strips markdown fences")
    func verificationStripsMarkdown() {
        let raw = "```json\n{\"verified\":false,\"explanation\":\"nope\"}\n```"
        let result = ClaudeClientTestHelper.parseVerification(raw)
        #expect(result.verified == false)
        #expect(result.explanation == "nope")
    }
}

// Exposes ClaudeClient's private parsing logic for unit testing
// via internal test helpers that replicate the stripping + parsing.
enum ClaudeClientTestHelper {
    static func parseClassification(_ text: String) -> OnTaskClassification {
        let cleaned = stripMarkdownFences(text)
        guard
            let data   = cleaned.data(using: .utf8),
            let json   = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let status = json["status"] as? String
        else {
            return OnTaskClassification(status: .ambiguous, confidence: 0.5, reason: text)
        }
        let onTaskStatus: OnTaskStatus
        switch status {
        case "onTask":  onTaskStatus = .onTask
        case "offTask": onTaskStatus = .offTask
        default:        onTaskStatus = .ambiguous
        }
        let confidence = json["confidence"] as? Double ?? 0.7
        let reason     = json["reason"]     as? String ?? ""
        return OnTaskClassification(status: onTaskStatus, confidence: confidence, reason: reason)
    }

    static func parseVerification(_ text: String) -> VerificationResult {
        let cleaned = stripMarkdownFences(text)
        guard
            let data        = cleaned.data(using: .utf8),
            let json        = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let verified    = json["verified"]    as? Bool,
            let explanation = json["explanation"] as? String
        else {
            return VerificationResult(verified: false, explanation: text)
        }
        return VerificationResult(verified: verified, explanation: explanation)
    }

    private static func stripMarkdownFences(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
