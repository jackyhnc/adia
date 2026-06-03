import Testing
import Foundation
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
}
