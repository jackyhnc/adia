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

    /// - Parameter useStrongModel: When `true`, routes to `claude-sonnet-4-6` instead of
    ///   the fast haiku model. Use for high-stakes conversations (early-exit motivation,
    ///   site-access reasoning) where nuanced judgment beats raw speed.
    func chat(
        messages: [ChatMessage],
        systemPrompt: String,
        useStrongModel: Bool
    ) async throws -> String

    /// Streaming variant — same model-selection semantics as `chat`.
    func chatStream(
        messages: [ChatMessage],
        systemPrompt: String,
        useStrongModel: Bool
    ) async throws -> AsyncThrowingStream<String, Error>
}

// MARK: - Convenience overloads (fast model default)
extension AgentAIService {
    public func chat(
        messages: [ChatMessage],
        systemPrompt: String
    ) async throws -> String {
        try await chat(messages: messages, systemPrompt: systemPrompt, useStrongModel: false)
    }

    public func chatStream(
        messages: [ChatMessage],
        systemPrompt: String
    ) async throws -> AsyncThrowingStream<String, Error> {
        try await chatStream(messages: messages, systemPrompt: systemPrompt, useStrongModel: false)
    }
}

extension AgentAIClient: AgentAIService {}
