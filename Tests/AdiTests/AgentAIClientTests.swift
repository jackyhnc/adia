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

    // MARK: - Goal-response parsing (model round-trip → GoalParse)
    //
    // `parseGoal(_:)` is gated on a live `ANTHROPIC_API_KEY` (see
    // `ClaudeAPIIntegrationTests`, which never runs in CI), but the pure JSON → GoalParse
    // mapping it delegates to — `parseGoalResponse(_:original:)` — had zero coverage even
    // though its siblings `parseClassification`/`parseVerification` are fully tested.
    // These exercise that mapping directly, deterministically, with no network involved.

    @Test func parsesAcceptedGoal() {
        let g = AgentAIClient.parseGoalResponse(
            #"{"ok":true,"task":"write my history essay","successCriteria":"Essay submitted on Canvas with a confirmation receipt visible."}"#,
            original: "write my history essay"
        )
        #expect(g.ok)
        #expect(g.task == "write my history essay")
        #expect(g.successCriteria == "Essay submitted on Canvas with a confirmation receipt visible.")
        #expect(g.question == nil)
    }

    @Test func acceptedGoalFallsBackToOriginalWhenTaskMissing() {
        let g = AgentAIClient.parseGoalResponse(
            #"{"ok":true,"successCriteria":"Slides look complete."}"#,
            original: "make a presentation"
        )
        #expect(g.ok)
        #expect(g.task == "make a presentation")
    }

    @Test func acceptedGoalFallsBackToOriginalWhenTaskBlank() {
        let g = AgentAIClient.parseGoalResponse(
            #"{"ok":true,"task":"   ","successCriteria":"Slides look complete."}"#,
            original: "make a presentation"
        )
        #expect(g.task == "make a presentation")
    }

    @Test func acceptedGoalSynthesizesCriteriaWhenMissing() {
        let g = AgentAIClient.parseGoalResponse(
            #"{"ok":true,"task":"homework"}"#,
            original: "homework"
        )
        #expect(g.ok)
        #expect(g.successCriteria == "On-screen, the work \"homework\" looks finished.")
    }

    @Test func acceptedGoalSynthesizesCriteriaWhenBlank() {
        let g = AgentAIClient.parseGoalResponse(
            #"{"ok":true,"task":"homework","successCriteria":"   "}"#,
            original: "homework"
        )
        #expect(g.successCriteria == "On-screen, the work \"homework\" looks finished.")
    }

    @Test func acceptedGoalTrimsWhitespace() {
        let g = AgentAIClient.parseGoalResponse(
            #"{"ok":true,"task":"  write my essay  ","successCriteria":"  done when submitted  "}"#,
            original: "write my essay"
        )
        #expect(g.task == "write my essay")
        #expect(g.successCriteria == "done when submitted")
    }

    @Test func rejectsWithModelQuestion() {
        let g = AgentAIClient.parseGoalResponse(
            #"{"ok":false,"question":"What subject is this for?"}"#,
            original: "work"
        )
        #expect(!g.ok)
        #expect(g.task == nil)
        #expect(g.successCriteria == nil)
        #expect(g.question == "What subject is this for?")
    }

    @Test func rejectsWithDefaultQuestionWhenModelOmitsOne() {
        let g = AgentAIClient.parseGoalResponse(#"{"ok":false}"#, original: "work")
        #expect(!g.ok)
        #expect(g.question == "What are you working on? Just name the subject or what you're trying to finish.")
    }

    @Test func rejectsWithDefaultQuestionWhenModelQuestionIsBlank() {
        let g = AgentAIClient.parseGoalResponse(#"{"ok":false,"question":"   "}"#, original: "work")
        #expect(g.question == "What are you working on? Just name the subject or what you're trying to finish.")
    }

    @Test func rejectsWithDefaultQuestionOnUnparsableJSON() {
        let g = AgentAIClient.parseGoalResponse("not json at all", original: "be productive")
        #expect(!g.ok)
        #expect(g.task == nil)
        #expect(g.successCriteria == nil)
        #expect(g.question == "I couldn't understand that. What should I be able to see on screen when you're done?")
    }

    @Test func goalResponseStripsMarkdownFences() {
        let raw = "```json\n{\"ok\":true,\"task\":\"edit my resume\",\"successCriteria\":\"Resume saved with updated date.\"}\n```"
        let g = AgentAIClient.parseGoalResponse(raw, original: "edit my resume")
        #expect(g.ok)
        #expect(g.task == "edit my resume")
        #expect(g.successCriteria == "Resume saved with updated date.")
    }
}
