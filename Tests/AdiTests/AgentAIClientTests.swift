import Testing
import Foundation
@testable import AdiCore

@Suite("AgentAIClient parsing")
struct AgentAIClientParsingTests {

    @Test func parsesOnTask() {
        let c = parseClassification(#"{"status":"onTask","confidence":0.95,"reason":"Screen shows essay editor."}"#)
        #expect(c.status == .onTask)
        #expect(abs(c.confidence - 0.95) < 0.001)
        #expect(c.reason == "Screen shows essay editor.")
    }

    @Test func parsesOffTask() {
        let c = parseClassification(#"{"status":"offTask","confidence":0.88,"reason":"Reddit open."}"#)
        #expect(c.status == .offTask)
        #expect(abs(c.confidence - 0.88) < 0.001)
    }

    @Test func fallsBackToAmbiguousOnBadJSON() {
        let c = parseClassification("not json at all")
        #expect(c.status == .ambiguous)
        #expect(abs(c.confidence - 0.5) < 0.001)
    }

    @Test func stripsMarkdownFences() {
        let raw = "```json\n{\"status\":\"onTask\",\"confidence\":0.9,\"reason\":\"ok\"}\n```"
        let c = parseClassification(raw)
        #expect(c.status == .onTask)
    }

    @Test func parsesVerifiedTrue() {
        let r = parseVerification(#"{"verified":true,"explanation":"Canvas confirmation page visible."}"#)
        #expect(r.verified)
        #expect(r.explanation == "Canvas confirmation page visible.")
    }

    @Test func parsesVerifiedFalse() {
        let r = parseVerification(#"{"verified":false,"explanation":"No submission receipt on screen."}"#)
        #expect(!r.verified)
    }

    @Test func verificationFallsBackOnBadJSON() {
        let r = parseVerification("garbage")
        #expect(!r.verified)
    }

    @Test func verificationStripsMarkdown() {
        let raw = "```json\n{\"verified\":false,\"explanation\":\"nope\"}\n```"
        let r = parseVerification(raw)
        #expect(!r.verified)
        #expect(r.explanation == "nope")
    }

    // MARK: - Helpers

    private func parseClassification(_ text: String) -> OnTaskClassification {
        let cleaned = strip(text)
        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let status = json["status"] as? String
        else {
            return OnTaskClassification(status: .ambiguous, confidence: 0.5, reason: text)
        }
        let s: OnTaskStatus
        switch status {
        case "onTask":  s = .onTask
        case "offTask": s = .offTask
        default:        s = .ambiguous
        }
        return OnTaskClassification(
            status: s,
            confidence: json["confidence"] as? Double ?? 0.7,
            reason: json["reason"] as? String ?? ""
        )
    }

    private func parseVerification(_ text: String) -> VerificationResult {
        let cleaned = strip(text)
        guard let data = cleaned.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let verified = json["verified"] as? Bool,
              let explanation = json["explanation"] as? String
        else {
            return VerificationResult(verified: false, explanation: text)
        }
        return VerificationResult(verified: verified, explanation: explanation)
    }

    private func strip(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
