import Testing
import Foundation
@testable import AdiCore

@Suite("AgentAIClient parsing")
struct AgentAIClientParsingTests {

    @Test func parsesOnTask() {
        let c = AgentAIClient.parseClassification(#"{"status":"onTask","confidence":0.95,"reason":"Screen shows essay editor."}"#)
        #expect(c.status == .onTask)
        #expect(abs(c.confidence - 0.95) < 0.001)
        #expect(c.reason == "Screen shows essay editor.")
    }

    @Test func parsesOffTask() {
        let c = AgentAIClient.parseClassification(#"{"status":"offTask","confidence":0.88,"reason":"Reddit open."}"#)
        #expect(c.status == .offTask)
        #expect(abs(c.confidence - 0.88) < 0.001)
    }

    @Test func parsesAmbiguous() {
        let c = AgentAIClient.parseClassification(#"{"status":"ambiguous","confidence":0.5,"reason":"Transitional."}"#)
        #expect(c.status == .ambiguous)
    }

    @Test func fallsBackToAmbiguousOnBadJSON() {
        let c = AgentAIClient.parseClassification("not json at all")
        #expect(c.status == .ambiguous)
        #expect(abs(c.confidence - 0.5) < 0.001)
    }

    @Test func stripsMarkdownFences() {
        let raw = "```json\n{\"status\":\"onTask\",\"confidence\":0.9,\"reason\":\"ok\"}\n```"
        let c = AgentAIClient.parseClassification(raw)
        #expect(c.status == .onTask)
    }

    @Test func unknownStatusFallsToAmbiguous() {
        let c = AgentAIClient.parseClassification(#"{"status":"unknown","confidence":0.6,"reason":"?"}"#)
        #expect(c.status == .ambiguous)
    }

    @Test func missingConfidenceDefaultsTo07() {
        let c = AgentAIClient.parseClassification(#"{"status":"onTask","reason":"ok"}"#)
        #expect(abs(c.confidence - 0.7) < 0.001)
    }

    // MARK: - Verification parsing

    @Test func parsesVerifiedTrue() {
        let r = AgentAIClient.parseVerification(#"{"verified":true,"explanation":"Canvas confirmation page visible."}"#)
        #expect(r.verified)
        #expect(r.explanation == "Canvas confirmation page visible.")
    }

    @Test func parsesVerifiedFalse() {
        let r = AgentAIClient.parseVerification(#"{"verified":false,"explanation":"No submission receipt on screen."}"#)
        #expect(!r.verified)
        #expect(r.explanation == "No submission receipt on screen.")
    }

    @Test func verificationFallsBackOnBadJSON() {
        let r = AgentAIClient.parseVerification("garbage")
        #expect(!r.verified)
    }

    @Test func verificationStripsMarkdown() {
        let raw = "```json\n{\"verified\":false,\"explanation\":\"nope\"}\n```"
        let r = AgentAIClient.parseVerification(raw)
        #expect(!r.verified)
        #expect(r.explanation == "nope")
    }

    @Test func verificationStripsMarkdownVerifiedTrue() {
        let raw = "```json\n{\"verified\":true,\"explanation\":\"done\"}\n```"
        let r = AgentAIClient.parseVerification(raw)
        #expect(r.verified)
        #expect(r.explanation == "done")
    }

    // MARK: - Local goal rejection

    @Test func localRejectionAcceptsEssay() {
        #expect(AgentAIClient.localGoalRejectionReason("write my history essay") == nil)
    }

    @Test func localRejectionAcceptsHomework() {
        #expect(AgentAIClient.localGoalRejectionReason("homework") == nil)
    }

    @Test func localRejectionAcceptsPresentation() {
        #expect(AgentAIClient.localGoalRejectionReason("make a presentation") == nil)
    }

    @Test func localRejectionRejectsEmpty() {
        #expect(AgentAIClient.localGoalRejectionReason("") != nil)
    }

    @Test func localRejectionRejectsWhitespace() {
        #expect(AgentAIClient.localGoalRejectionReason("   ") != nil)
    }

    @Test func localRejectionRejectsStuff() {
        #expect(AgentAIClient.localGoalRejectionReason("stuff") != nil)
    }

    @Test func localRejectionRejectsYouTube() {
        #expect(AgentAIClient.localGoalRejectionReason("watch youtube") != nil)
    }

    @Test func localRejectionRejectsTikTok() {
        #expect(AgentAIClient.localGoalRejectionReason("scroll tiktok") != nil)
    }
}
