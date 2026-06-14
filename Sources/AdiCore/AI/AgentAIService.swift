import Foundation
import CoreGraphics

/// Abstraction over the Claude-backed agent. `AgentAIClient` is the real,
/// network-backed implementation; tests substitute a deterministic stand-in
/// (see `MockAgentAIClient`) so `SessionManager`/`ConversationManager`/
/// `OnTaskDetector` logic can be exercised without an `ANTHROPIC_API_KEY` or
/// a live network round-trip.
public protocol AgentAIService: Sendable {
    func isConfigured() async -> Bool

    func classify(
        image: CGImage,
        taskDescription: String,
        successCriteria: String
    ) async throws -> OnTaskClassification

    func verify(
        image: CGImage,
        taskDescription: String,
        successCriteria: String
    ) async throws -> VerificationResult

    func parseGoal(_ input: String) async throws -> GoalParse

    func chat(
        messages: [ChatMessage],
        systemPrompt: String
    ) async throws -> String

    func chatStream(
        messages: [ChatMessage],
        systemPrompt: String
    ) async throws -> AsyncThrowingStream<String, Error>
}

extension AgentAIClient: AgentAIService {}
