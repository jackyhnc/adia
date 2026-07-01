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

    // MARK: - Local rejection — gaming / streaming additions

    @Test func localRejectionRejectsGaming() {
        // Exact-match: standalone "gaming" as a session goal is pure leisure.
        #expect(AgentAIClient.localGoalRejectionReason("gaming") != nil)
    }

    @Test func localRejectionRejectsVibing() {
        #expect(AgentAIClient.localGoalRejectionReason("vibing") != nil)
    }

    @Test func localRejectionRejectsChilling() {
        #expect(AgentAIClient.localGoalRejectionReason("chilling") != nil)
    }

    @Test func localRejectionRejectsHulu() {
        #expect(AgentAIClient.localGoalRejectionReason("watch hulu") != nil)
    }

    @Test func localRejectionRejectsTwitch() {
        #expect(AgentAIClient.localGoalRejectionReason("browse twitch") != nil)
    }

    @Test func localRejectionRejectsSnapchat() {
        #expect(AgentAIClient.localGoalRejectionReason("snapchat") != nil)
    }

    // gaming should NOT block legitimate tasks where "gaming" appears as a word
    // in a different context — but the exact-match guard only fires when the ENTIRE
    // input is "gaming", so "gaming the algorithm" must still pass through to the model.
    @Test func localRejectionAcceptsGamingContext() {
        // "gaming the algorithm" is a strategy phrase, not a leisure request.
        #expect(AgentAIClient.localGoalRejectionReason("gaming the algorithm") == nil)
    }

    @Test func localRejectionAcceptsGameDevelopment() {
        // "game development" is a legitimate software project.
        #expect(AgentAIClient.localGoalRejectionReason("finish game development feature") == nil)
    }

    // MARK: - Local rejection — gaming / sports phrases

    @Test func localRejectionRejectsPlayGames() {
        #expect(AgentAIClient.localGoalRejectionReason("play games") != nil)
    }

    @Test func localRejectionRejectsVideoGames() {
        #expect(AgentAIClient.localGoalRejectionReason("video games") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("videogames") != nil)
    }

    @Test func localRejectionRejectsPlayVideoGames() {
        #expect(AgentAIClient.localGoalRejectionReason("play video games") != nil)
    }

    @Test func localRejectionRejectsSports() {
        #expect(AgentAIClient.localGoalRejectionReason("sports") != nil)
    }

    @Test func localRejectionRejectsWatchSports() {
        #expect(AgentAIClient.localGoalRejectionReason("watch sports") != nil)
    }

    @Test func localRejectionRejectsWatchTV() {
        #expect(AgentAIClient.localGoalRejectionReason("watch tv") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("watch television") != nil)
    }

    @Test func localRejectionRejectsWatchAMovie() {
        #expect(AgentAIClient.localGoalRejectionReason("watch a movie") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("watch movies") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("watch a show") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("watch shows") != nil)
    }

    @Test func localRejectionRejectsWatching() {
        // Bare "watching" with no subject is pure leisure.
        #expect(AgentAIClient.localGoalRejectionReason("watching") != nil)
    }

    // Counter-cases: gaming/sports words inside a real task description must pass through.
    @Test func localRejectionAcceptsSportsAnalysis() {
        // Exact-match only fires on the whole input — longer phrases always pass through.
        #expect(AgentAIClient.localGoalRejectionReason("analyze sports statistics for econ class") == nil)
    }

    @Test func localRejectionAcceptsMovieScript() {
        #expect(AgentAIClient.localGoalRejectionReason("write a movie script for film class") == nil)
    }

    @Test func localRejectionAcceptsGameDesign() {
        #expect(AgentAIClient.localGoalRejectionReason("finish the game design document") == nil)
    }

    @Test func localRejectionAcceptsTVProduction() {
        #expect(AgentAIClient.localGoalRejectionReason("draft the tv show pilot script") == nil)
    }

    // MARK: - Local rejection — specific game titles

    @Test func localRejectionRejectsFortnite() {
        #expect(AgentAIClient.localGoalRejectionReason("fortnite") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("play fortnite") != nil)
    }

    @Test func localRejectionRejectsMinecraft() {
        #expect(AgentAIClient.localGoalRejectionReason("minecraft") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("play minecraft") != nil)
    }

    @Test func localRejectionRejectsRoblox() {
        #expect(AgentAIClient.localGoalRejectionReason("roblox") != nil)
    }

    @Test func localRejectionRejectsValorant() {
        #expect(AgentAIClient.localGoalRejectionReason("valorant") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("play valorant") != nil)
    }

    @Test func localRejectionRejectsCallOfDuty() {
        #expect(AgentAIClient.localGoalRejectionReason("call of duty") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("cod") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("play call of duty") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("play cod") != nil)
    }

    @Test func localRejectionRejectsLeagueOfLegends() {
        #expect(AgentAIClient.localGoalRejectionReason("league of legends") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("league") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("play league of legends") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("play league") != nil)
    }

    @Test func localRejectionRejectsOverwatch() {
        #expect(AgentAIClient.localGoalRejectionReason("overwatch") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("play overwatch") != nil)
    }

    // Counter-cases: game names embedded in a real deliverable must pass through.
    @Test func localRejectionAcceptsMinecraftMod() {
        // "write a minecraft mod" has a deliverable — must reach the model
        #expect(AgentAIClient.localGoalRejectionReason("write a minecraft mod") == nil)
    }

    @Test func localRejectionAcceptsRobloxGame() {
        #expect(AgentAIClient.localGoalRejectionReason("build a roblox game for my cs class") == nil)
    }

    @Test func localRejectionAcceptsFortniteAnalysis() {
        #expect(AgentAIClient.localGoalRejectionReason("write a marketing analysis for fortnite") == nil)
    }

    @Test func localRejectionAcceptsLeagueEssay() {
        #expect(AgentAIClient.localGoalRejectionReason("write an essay about league of legends and esports") == nil)
    }

    // MARK: - Local rejection — PRD-specified vague inputs (no subject / deliverable)

    // The PRD lists "work", "be productive", "do stuff", "get things done", "focus" as
    // inputs that must be rejected because there is nothing verifiable. These are caught
    // locally (no API call) via exact-match on the full lowercased input, so longer
    // phrasings like "work on my thesis" or "focus on chemistry" still pass through.

    @Test func localRejectionRejectsWork() {
        #expect(AgentAIClient.localGoalRejectionReason("work") != nil)
    }

    @Test func localRejectionAcceptsWorkWithSubject() {
        // "work" inside a longer phrase has a subject — must reach the model
        #expect(AgentAIClient.localGoalRejectionReason("work on my thesis") == nil)
    }

    @Test func localRejectionRejectsFocus() {
        #expect(AgentAIClient.localGoalRejectionReason("focus") != nil)
    }

    @Test func localRejectionAcceptsFocusWithSubject() {
        #expect(AgentAIClient.localGoalRejectionReason("focus on chemistry") == nil)
    }

    @Test func localRejectionRejectsBeProductive() {
        #expect(AgentAIClient.localGoalRejectionReason("be productive") != nil)
    }

    @Test func localRejectionRejectsDoStuff() {
        #expect(AgentAIClient.localGoalRejectionReason("do stuff") != nil)
    }

    @Test func localRejectionRejectsDoWork() {
        #expect(AgentAIClient.localGoalRejectionReason("do work") != nil)
    }

    @Test func localRejectionRejectsGetThingsDone() {
        #expect(AgentAIClient.localGoalRejectionReason("get things done") != nil)
    }

    @Test func localRejectionRejectsGetStuffDone() {
        #expect(AgentAIClient.localGoalRejectionReason("get stuff done") != nil)
    }

    @Test func localRejectionRejectsBeFocused() {
        #expect(AgentAIClient.localGoalRejectionReason("be focused") != nil)
    }

    @Test func localRejectionRejectsStayFocused() {
        #expect(AgentAIClient.localGoalRejectionReason("stay focused") != nil)
    }

    @Test func localRejectionRejectsHustle() {
        #expect(AgentAIClient.localGoalRejectionReason("hustle") != nil)
    }

    @Test func localRejectionRejectsGrind() {
        // bare "grind" is motivation-speak with no deliverable
        #expect(AgentAIClient.localGoalRejectionReason("grind") != nil)
    }

    @Test func localRejectionAcceptsGrindWithTarget() {
        // "grind leetcode" is a real task (practicing interview problems)
        #expect(AgentAIClient.localGoalRejectionReason("grind leetcode") == nil)
    }

    @Test func localRejectionRejectsDoNothing() {
        #expect(AgentAIClient.localGoalRejectionReason("do nothing") != nil)
    }

    @Test func localRejectionRejectsProcrastinate() {
        #expect(AgentAIClient.localGoalRejectionReason("procrastinate") != nil)
    }

    @Test func localRejectionAcceptsBeFocusedInLongerPhrase() {
        // "be focused while reading chapter 4" is a real task — must reach the model
        #expect(AgentAIClient.localGoalRejectionReason("be focused while reading chapter 4") == nil)
    }

    // MARK: - Local rejection — non-work activities (sleep, eat, etc.)
    //
    // Clearly non-work inputs with no subject or deliverable are rejected locally (no API call).
    // Exact-match on the full lowercased input, so "sleep research for psych class" still passes.

    @Test func localRejectionRejectsSleep() {
        #expect(AgentAIClient.localGoalRejectionReason("sleep") != nil)
    }

    @Test func localRejectionRejectsNap() {
        #expect(AgentAIClient.localGoalRejectionReason("nap") != nil)
    }

    @Test func localRejectionRejectsEat() {
        #expect(AgentAIClient.localGoalRejectionReason("eat") != nil)
    }

    @Test func localRejectionRejectsLunch() {
        #expect(AgentAIClient.localGoalRejectionReason("lunch") != nil)
    }

    @Test func localRejectionRejectsDinner() {
        #expect(AgentAIClient.localGoalRejectionReason("dinner") != nil)
    }

    @Test func localRejectionRejectsBreakfast() {
        #expect(AgentAIClient.localGoalRejectionReason("breakfast") != nil)
    }

    @Test func localRejectionRejectsBrunch() {
        #expect(AgentAIClient.localGoalRejectionReason("brunch") != nil)
    }

    // Counter-cases: inputs that contain these words but have a real subject/deliverable
    // must pass through to the model unchanged.

    @Test func localRejectionAcceptsSleepResearch() {
        // academic topic — sleep as a research subject, not an activity
        #expect(AgentAIClient.localGoalRejectionReason("sleep research for psych class") == nil)
    }

    @Test func localRejectionAcceptsLunchPresentation() {
        // presenting at a lunch meeting — real deliverable
        #expect(AgentAIClient.localGoalRejectionReason("prepare for lunch presentation") == nil)
    }

    @Test func localRejectionAcceptsDinnerEvent() {
        // planning a dinner event could be a real task
        #expect(AgentAIClient.localGoalRejectionReason("plan the dinner event for Friday") == nil)
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

    // MARK: - GoalParse → GoalSubmissionOutcome (NotchView.submit() branch logic)
    //
    // `SessionCreationFormView.submit()` switches on what `parseGoal` returns to decide
    // whether to start the session or show a clarifying question. That branch logic lived
    // inline in a `View` (untestable without SwiftUI/@MainActor/network) — `resolveSubmission`
    // extracts it as a pure function on `GoalParse` so every accept/reject/fallback path has
    // a deterministic test, mirroring the pure-parser coverage above.

    @Test func resolveSubmissionAcceptsValidGoal() {
        let g = GoalParse(ok: true, task: "write my essay", successCriteria: "Essay submitted on Canvas.", question: nil)
        #expect(g.resolveSubmission() == .accepted(task: "write my essay", successCriteria: "Essay submitted on Canvas."))
    }

    @Test func resolveSubmissionTrimsAcceptedFields() {
        let g = GoalParse(ok: true, task: "  write my essay  ", successCriteria: "  done when submitted  ", question: nil)
        #expect(g.resolveSubmission() == .accepted(task: "write my essay", successCriteria: "done when submitted"))
    }

    @Test func resolveSubmissionAsksClarificationWhenModelRejects() {
        let g = GoalParse(ok: false, task: nil, successCriteria: nil, question: "What subject is this for?")
        #expect(g.resolveSubmission() == .needsClarification(question: "What subject is this for?"))
    }

    @Test func resolveSubmissionUsesDefaultQuestionWhenModelRejectsWithoutOne() {
        let g = GoalParse(ok: false, task: nil, successCriteria: nil, question: nil)
        #expect(g.resolveSubmission() == .needsClarification(question: "What would I be able to see on screen when this is done?"))
    }

    @Test func resolveSubmissionUsesDefaultQuestionWhenModelRejectionQuestionIsBlank() {
        let g = GoalParse(ok: false, task: nil, successCriteria: nil, question: "   ")
        #expect(g.resolveSubmission() == .needsClarification(question: "What would I be able to see on screen when this is done?"))
    }

    @Test func resolveSubmissionAsksClarificationWhenTaskMissingDespiteOk() {
        // Defensive: `parseGoalResponse` never produces this shape (it falls back to
        // `original`), but `GoalParse` can be constructed directly — e.g. by a future
        // parser or a test mock — so the guard must hold for the full type, not just
        // the values one code path happens to produce.
        let g = GoalParse(ok: true, task: nil, successCriteria: "Essay submitted.", question: "Anything else?")
        #expect(g.resolveSubmission() == .needsClarification(question: "Anything else?"))
    }

    @Test func resolveSubmissionAsksClarificationWhenTaskBlankDespiteOk() {
        let g = GoalParse(ok: true, task: "   ", successCriteria: "Essay submitted.", question: nil)
        #expect(g.resolveSubmission() == .needsClarification(question: "What would I be able to see on screen when this is done?"))
    }

    @Test func resolveSubmissionAsksClarificationWhenCriteriaMissingDespiteOk() {
        let g = GoalParse(ok: true, task: "write my essay", successCriteria: nil, question: nil)
        #expect(g.resolveSubmission() == .needsClarification(question: "What would I be able to see on screen when this is done?"))
    }

    @Test func resolveSubmissionAsksClarificationWhenCriteriaBlankDespiteOk() {
        let g = GoalParse(ok: true, task: "write my essay", successCriteria: "   ", question: nil)
        #expect(g.resolveSubmission() == .needsClarification(question: "What would I be able to see on screen when this is done?"))
    }

    @Test func resolveSubmissionRespectsCustomDefaultQuestion() {
        let g = GoalParse(ok: false, task: nil, successCriteria: nil, question: nil)
        #expect(g.resolveSubmission(defaultQuestion: "Tell me more?") == .needsClarification(question: "Tell me more?"))
    }

    // MARK: - Retry/backoff helpers

    @Test func isRetryable429() {
        #expect(AgentAIClient.isRetryableStatusCode(429))
    }

    @Test func isRetryable500() {
        #expect(AgentAIClient.isRetryableStatusCode(500))
    }

    @Test func isRetryable503() {
        #expect(AgentAIClient.isRetryableStatusCode(503))
    }

    @Test func isRetryable599() {
        #expect(AgentAIClient.isRetryableStatusCode(599))
    }

    @Test func isNotRetryable400() {
        #expect(!AgentAIClient.isRetryableStatusCode(400))
    }

    @Test func isNotRetryable401() {
        #expect(!AgentAIClient.isRetryableStatusCode(401))
    }

    @Test func isNotRetryable403() {
        #expect(!AgentAIClient.isRetryableStatusCode(403))
    }

    @Test func isNotRetryable404() {
        #expect(!AgentAIClient.isRetryableStatusCode(404))
    }

    @Test func isNotRetryable200() {
        #expect(!AgentAIClient.isRetryableStatusCode(200))
    }

    @Test func retryDelayAttempt1IsAboutOneSecond() {
        // attempt=1 → base=1s, jitter ±20% → [0.8, 1.2]
        let d = AgentAIClient.retryDelay(attempt: 1, retryAfterSeconds: nil)
        #expect(d >= 0.8 && d <= 1.2)
    }

    @Test func retryDelayAttempt2IsAboutTwoSeconds() {
        // attempt=2 → base=2s → [1.6, 2.4]
        let d = AgentAIClient.retryDelay(attempt: 2, retryAfterSeconds: nil)
        #expect(d >= 1.6 && d <= 2.4)
    }

    @Test func retryDelayAttempt3IsAboutFourSeconds() {
        // attempt=3 → base=4s → [3.2, 4.8]
        let d = AgentAIClient.retryDelay(attempt: 3, retryAfterSeconds: nil)
        #expect(d >= 3.2 && d <= 4.8)
    }

    @Test func retryDelayIsCappedAt30Seconds() {
        // attempt=10 → base=512s → should cap at 30s
        let d = AgentAIClient.retryDelay(attempt: 10, retryAfterSeconds: nil)
        #expect(d <= 30.0)
    }

    @Test func retryDelayUsesRetryAfterHeaderWhenPresent() {
        let d = AgentAIClient.retryDelay(attempt: 1, retryAfterSeconds: 12.0)
        #expect(abs(d - 12.0) < 0.001)
    }

    @Test func retryDelayCapRetryAfterAt30() {
        let d = AgentAIClient.retryDelay(attempt: 1, retryAfterSeconds: 120.0)
        #expect(abs(d - 30.0) < 0.001)
    }

    @Test func retryDelayRetryAfterZeroIsZero() {
        let d = AgentAIClient.retryDelay(attempt: 1, retryAfterSeconds: 0)
        #expect(abs(d) < 0.001)
    }

    @Test func maxRetriesIsThree() {
        #expect(AgentAIClient.maxRetries == 3)
    }

    // MARK: - SSE streaming line parser

    @Test func parseSSELineReturnsTextForTextDeltaEvent() {
        let line = #"data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":"hello"}}"#
        #expect(AgentAIClient.parseSSELine(line) == "hello")
    }

    @Test func parseSSELineReturnsEmptyStringTextDelta() {
        // Empty text deltas are valid — yield them so the caller can decide.
        let line = #"data: {"type":"content_block_delta","index":0,"delta":{"type":"text_delta","text":""}}"#
        #expect(AgentAIClient.parseSSELine(line) == "")
    }

    @Test func parseSSELineIgnoresMessageStartEvent() {
        let line = #"data: {"type":"message_start","message":{"id":"msg_01","type":"message"}}"#
        #expect(AgentAIClient.parseSSELine(line) == nil)
    }

    @Test func parseSSELineIgnoresPingEvent() {
        let line = #"data: {"type":"ping"}"#
        #expect(AgentAIClient.parseSSELine(line) == nil)
    }

    @Test func parseSSELineIgnoresContentBlockStart() {
        let line = #"data: {"type":"content_block_start","index":0,"content_block":{"type":"text","text":""}}"#
        #expect(AgentAIClient.parseSSELine(line) == nil)
    }

    @Test func parseSSELineIgnoresMessageDelta() {
        let line = #"data: {"type":"message_delta","delta":{"stop_reason":"end_turn"}}"#
        #expect(AgentAIClient.parseSSELine(line) == nil)
    }

    @Test func parseSSELineIgnoresMessageStop() {
        let line = #"data: {"type":"message_stop"}"#
        #expect(AgentAIClient.parseSSELine(line) == nil)
    }

    @Test func parseSSELineIgnoresNonDataLines() {
        #expect(AgentAIClient.parseSSELine("event: content_block_delta") == nil)
        #expect(AgentAIClient.parseSSELine("") == nil)
        #expect(AgentAIClient.parseSSELine(":") == nil)
    }

    @Test func parseSSELineIgnoresDoneTerminator() {
        #expect(AgentAIClient.parseSSELine("data: [DONE]") == nil)
    }

    @Test func parseSSELineIgnoresInputTokensDelta() {
        // input_json_delta is not a text delta — should be ignored.
        let line = #"data: {"type":"content_block_delta","index":0,"delta":{"type":"input_json_delta","partial_json":"{}"}}"#
        #expect(AgentAIClient.parseSSELine(line) == nil)
    }
}

// MARK: - Image resize for vision API

@Suite("AgentAIClient image resize")
struct AgentAIClientResizeTests {

    private func makeImage(width: Int, height: Int) -> CGImage? {
        guard let ctx = CGContext(
            data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        return ctx.makeImage()
    }

    @Test func maxVisionDimensionIs1024() {
        #expect(AgentAIClient.maxVisionDimension == 1024)
    }

    @Test func smallImagePassesThrough() {
        guard let img = makeImage(width: 100, height: 80) else { return }
        let result = AgentAIClient.resizeForVision(img)
        #expect(result.width == 100)
        #expect(result.height == 80)
    }

    @Test func exactlyAtMaxPassesThrough() {
        guard let img = makeImage(width: 1024, height: 768) else { return }
        let result = AgentAIClient.resizeForVision(img)
        #expect(result.width == 1024)
        #expect(result.height == 768)
    }

    @Test func wideImageIsDownscaled() {
        guard let img = makeImage(width: 2560, height: 1600) else { return }
        let result = AgentAIClient.resizeForVision(img)
        #expect(result.width == 1024)
        #expect(result.height == 640)
    }

    @Test func tallImageIsDownscaled() {
        guard let img = makeImage(width: 1200, height: 2400) else { return }
        let result = AgentAIClient.resizeForVision(img)
        #expect(result.width == 512)
        #expect(result.height == 1024)
    }

    @Test func squareImageIsDownscaled() {
        guard let img = makeImage(width: 2048, height: 2048) else { return }
        let result = AgentAIClient.resizeForVision(img)
        #expect(result.width == 1024)
        #expect(result.height == 1024)
    }

    @Test func customMaxDimensionIsRespected() {
        guard let img = makeImage(width: 800, height: 600) else { return }
        let result = AgentAIClient.resizeForVision(img, maxDimension: 400)
        #expect(result.width == 400)
        #expect(result.height == 300)
    }

    // MARK: - Local rejection — social media scrolling intents

    @Test func localRejectionRejectsBareTwitter() {
        #expect(AgentAIClient.localGoalRejectionReason("twitter") != nil)
    }

    @Test func localRejectionRejectsBareReddit() {
        #expect(AgentAIClient.localGoalRejectionReason("reddit") != nil)
    }

    @Test func localRejectionRejectsBareFacebook() {
        #expect(AgentAIClient.localGoalRejectionReason("facebook") != nil)
    }

    @Test func localRejectionRejectsBareX() {
        #expect(AgentAIClient.localGoalRejectionReason("x") != nil)
    }

    @Test func localRejectionRejectsScrollTwitter() {
        #expect(AgentAIClient.localGoalRejectionReason("scroll twitter") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("browse twitter") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("check twitter") != nil)
    }

    @Test func localRejectionRejectsScrollReddit() {
        #expect(AgentAIClient.localGoalRejectionReason("scroll reddit") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("browse reddit") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("check reddit") != nil)
    }

    @Test func localRejectionRejectsScrollFacebook() {
        #expect(AgentAIClient.localGoalRejectionReason("scroll facebook") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("browse facebook") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("check facebook") != nil)
    }

    @Test func localRejectionRejectsScrollInstagram() {
        #expect(AgentAIClient.localGoalRejectionReason("scroll instagram") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("check instagram") != nil)
    }

    @Test func localRejectionRejectsScrollTikTok() {
        #expect(AgentAIClient.localGoalRejectionReason("scroll tiktok") != nil)
        #expect(AgentAIClient.localGoalRejectionReason("open tiktok") != nil)
    }

    // Counter-cases: social platform names embedded in real tasks must pass through.
    @Test func localRejectionAcceptsTwitterAnalysis() {
        #expect(AgentAIClient.localGoalRejectionReason("analyze twitter engagement data for my marketing thesis") == nil)
    }

    @Test func localRejectionAcceptsRedditPost() {
        #expect(AgentAIClient.localGoalRejectionReason("write a reddit post about my research findings") == nil)
    }

    @Test func localRejectionAcceptsFacebookAds() {
        #expect(AgentAIClient.localGoalRejectionReason("build a facebook ads campaign report") == nil)
    }

    @Test func fourKDisplayHalfResIsDownscaled() {
        guard let img = makeImage(width: 1920, height: 1080) else { return }
        let result = AgentAIClient.resizeForVision(img)
        #expect(result.width == 1024)
        #expect(result.height == 576)
    }

    @Test func fiveKDisplayHalfResIsDownscaled() {
        guard let img = makeImage(width: 2560, height: 1440) else { return }
        let result = AgentAIClient.resizeForVision(img)
        #expect(result.width == 1024)
        #expect(result.height == 576)
    }
}
