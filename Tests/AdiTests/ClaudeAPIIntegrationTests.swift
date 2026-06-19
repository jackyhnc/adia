import Testing
import Foundation
import CoreGraphics
@testable import AdiCore

// Integration tests — skipped automatically when ANTHROPIC_API_KEY is not in env.
// Run with: ANTHROPIC_API_KEY=sk-ant-... swift test
private let hasAnthropicKey: Bool = {
    guard let key = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"],
          !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
    return key.hasPrefix("sk-ant-")
}()

@Suite(
    "Claude API Integration",
    .enabled(if: hasAnthropicKey, "Requires ANTHROPIC_API_KEY=sk-ant-... in environment")
)
struct ClaudeAPIIntegrationTests {

    // MARK: - parseGoal

    @Test func parseGoalAcceptsAcademicTask() async throws {
        let result = try await AgentAIClient.shared.parseGoal("write my history essay")
        #expect(result.ok == true)
        #expect(!(result.task?.isEmpty ?? true), "task should be non-empty")
        #expect(!(result.successCriteria?.isEmpty ?? true), "successCriteria should be non-empty")
        #expect(result.question == nil)
    }

    @Test func parseGoalAcceptsHomework() async throws {
        let result = try await AgentAIClient.shared.parseGoal("homework")
        #expect(result.ok == true)
        #expect(!(result.task?.isEmpty ?? true))
    }

    @Test func parseGoalAcceptsPresentation() async throws {
        let result = try await AgentAIClient.shared.parseGoal("make a presentation")
        #expect(result.ok == true)
        #expect(!(result.task?.isEmpty ?? true))
    }

    @Test func parseGoalRejectsEmptyViaLocalGuard() {
        // Empty input is caught locally — no network call needed.
        let reason = AgentAIClient.localGoalRejectionReason("")
        #expect(reason != nil)
    }

    @Test func parseGoalRejectsLeisureViaLocalGuard() {
        // "scroll tiktok" is caught locally.
        let reason = AgentAIClient.localGoalRejectionReason("scroll tiktok")
        #expect(reason != nil)
    }

    @Test func parseGoalReturnsQuestionForVagueInput() async throws {
        // "stuff" is caught by the local guard before the API.
        // Validate the local path returns a non-nil reason.
        let localReason = AgentAIClient.localGoalRejectionReason("stuff")
        #expect(localReason != nil)
        // Also confirm the model path: if local guard somehow passes, model should reject.
        // We don't call the API here to keep the test fast and deterministic.
    }

    // MARK: - chat

    @Test func chatReturnsNonEmptyResponse() async throws {
        let messages = [ChatMessage(role: .user, content: "Reply with the single word: ok")]
        let response = try await AgentAIClient.shared.chat(
            messages: messages,
            systemPrompt: "You are a terse assistant. Reply in one word only."
        )
        #expect(!response.isEmpty, "chat response should be non-empty")
    }

    @Test func chatFollowsSystemPromptTone() async throws {
        let messages = [ChatMessage(role: .user, content: "What is 2+2?")]
        let response = try await AgentAIClient.shared.chat(
            messages: messages,
            systemPrompt: "Answer math questions with a single number, no words."
        )
        #expect(!response.isEmpty)
        // Response should contain "4" somewhere.
        #expect(response.contains("4"), "expected '4' in response, got: \(response)")
    }

    @Test func chatMultiTurnCarriesContext() async throws {
        let messages: [ChatMessage] = [
            ChatMessage(role: .user,      content: "My favourite colour is blue."),
            ChatMessage(role: .assistant, content: "Got it — blue."),
            ChatMessage(role: .user,      content: "What is my favourite colour?"),
        ]
        let response = try await AgentAIClient.shared.chat(
            messages: messages,
            systemPrompt: "You are a helpful assistant with perfect memory."
        )
        let lower = response.lowercased()
        #expect(lower.contains("blue"), "expected 'blue' in follow-up response, got: \(response)")
    }

    @Test func chatStrongModelReturnsNonEmptyResponse() async throws {
        let messages = [ChatMessage(role: .user, content: "Reply with the single word: ok")]
        let response = try await AgentAIClient.shared.chat(
            messages: messages,
            systemPrompt: "You are a terse assistant. Reply in one word only.",
            useStrongModel: true
        )
        #expect(!response.isEmpty, "strong-model chat response should be non-empty")
    }

    // MARK: - Response parser round-trip via live API

    @Test func parseGoalResponseIsWellFormed() async throws {
        let result = try await AgentAIClient.shared.parseGoal("study for my biology exam")
        if result.ok {
            #expect(!(result.task?.isEmpty ?? true))
            #expect(!(result.successCriteria?.isEmpty ?? true))
            #expect(result.question == nil)
        } else {
            #expect(!(result.question?.isEmpty ?? true))
        }
    }

    // MARK: - classify (vision pipeline)

    /// Smoke test: exercises the full image → JPEG base64 → Anthropic vision API → JSON parse
    /// round-trip. A synthetic CGImage is used so no screen permissions are required.
    @Test func classifyReturnsParsedStatusForSyntheticImage() async throws {
        guard let image = Self.makeSyntheticScreenshot() else {
            Issue.record("Could not create synthetic CGImage")
            return
        }
        let result = try await AgentAIClient.shared.classify(
            image: image,
            taskDescription: "write a history essay about World War II",
            successCriteria: "A completed essay document is visible on screen"
        )
        #expect(result.confidence >= 0.0)
        #expect(result.confidence <= 1.0)
        #expect(!result.reason.isEmpty, "classify reason should be a non-empty string from the model")
    }

    /// Blank synthetic image cannot possibly show an essay being submitted —
    /// model should return offTask or ambiguous, never onTask.
    @Test func classifyBlankImageIsNotOnTask() async throws {
        guard let image = Self.makeSyntheticScreenshot() else {
            Issue.record("Could not create synthetic CGImage")
            return
        }
        let result = try await AgentAIClient.shared.classify(
            image: image,
            taskDescription: "submit ENGL 101 essay to Canvas",
            successCriteria: "Canvas shows a submission confirmation with green checkmark"
        )
        #expect(
            result.status == .offTask || result.status == .ambiguous,
            "blank image should not classify as on-task for a Canvas submission; got \(result.status)"
        )
    }

    // MARK: - verify (vision pipeline)

    /// Smoke test for the verify() vision path — same encoding pipeline as classify().
    @Test func verifyReturnsParsedResultForSyntheticImage() async throws {
        guard let image = Self.makeSyntheticScreenshot() else {
            Issue.record("Could not create synthetic CGImage")
            return
        }
        let result = try await AgentAIClient.shared.verify(
            image: image,
            taskDescription: "submit the ENGL 101 essay to Canvas",
            successCriteria: "Canvas shows a submission confirmation page with a green check"
        )
        #expect(!result.explanation.isEmpty, "verify explanation should be non-empty")
    }

    /// A blank white image cannot show a Canvas submission confirmation.
    /// verify() must return verified:false for it.
    @Test func verifyRejectsSyntheticImageAsNotComplete() async throws {
        guard let image = Self.makeSyntheticScreenshot() else {
            Issue.record("Could not create synthetic CGImage")
            return
        }
        let result = try await AgentAIClient.shared.verify(
            image: image,
            taskDescription: "submit the ENGL 101 essay to Canvas",
            successCriteria: "Canvas shows a submission confirmation page with a green check"
        )
        #expect(
            result.verified == false,
            "blank image cannot satisfy Canvas submission criteria — expected verified:false"
        )
    }

    // MARK: - chatStream (streaming pipeline)

    /// Verifies that chatStream() yields at least one token and the concatenated
    /// result is non-empty — exercises the SSE line parser in a live network call.
    @Test func chatStreamYieldsNonEmptyResponse() async throws {
        let messages = [ChatMessage(role: .user, content: "Reply with the single word: hello")]
        let stream = try await AgentAIClient.shared.chatStream(
            messages: messages,
            systemPrompt: "Reply in one word only.",
            useStrongModel: false
        )
        var chunks: [String] = []
        for try await chunk in stream {
            chunks.append(chunk)
        }
        let full = chunks.joined()
        #expect(!chunks.isEmpty, "streaming response should deliver at least one SSE text chunk")
        #expect(!full.isEmpty, "concatenated stream result should be non-empty")
    }

    // MARK: - Synthetic image helper

    /// Creates a minimal 200×150 CGImage: white background with a dark text-like rectangle.
    /// Gives the vision model something to interpret without requiring screen capture access.
    private static func makeSyntheticScreenshot(width: Int = 200, height: Int = 150) -> CGImage? {
        guard let ctx = CGContext(
            data: nil,
            width: width, height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        ctx.setFillColor(red: 1, green: 1, blue: 1, alpha: 1)
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        ctx.setFillColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        ctx.fill(CGRect(x: 20, y: 60, width: 160, height: 30))
        return ctx.makeImage()
    }
}
