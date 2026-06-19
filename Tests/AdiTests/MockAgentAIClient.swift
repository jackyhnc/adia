import Foundation
import CoreGraphics
@testable import AdiCore

/// `Sendable`-safe stand-in for `Error` so `Result<_, MockAgentAIError>` stays
/// `Sendable` and can be set on the mock from a different task than the one
/// that consumes it (the whole point of an actor-backed mock).
struct MockAgentAIError: Error, Sendable, Equatable {
    let message: String
}

/// Deterministic stand-in for `AgentAIClient` — lets tests control the timing
/// and outcome of every agent call without a live network round-trip or an
/// `ANTHROPIC_API_KEY`. An actor (mirroring the real client) because
/// `AgentAIService` requires `Sendable`, and tests configure canned responses
/// from one task while `SessionManager`/`ConversationManager`/`OnTaskDetector`
/// call into it from another.
actor MockAgentAIClient: AgentAIService {
    private var configured = true
    private var verifyResult: Result<VerificationResult, MockAgentAIError> =
        .success(VerificationResult(verified: true, explanation: "mock: looks done"))
    private var verifyDelay: Duration = .zero
    private var classifyResult: Result<OnTaskClassification, MockAgentAIError> =
        .success(OnTaskClassification(status: .onTask, confidence: 0.9, reason: "mock"))
    private var parseGoalResult: Result<GoalParse, MockAgentAIError> =
        .success(GoalParse(ok: true, task: "mock task", successCriteria: "mock criteria", question: nil))
    private var chatResult: Result<String, MockAgentAIError> = .success("mock reply")
    /// When non-nil, `chatStream` yields each element as a separate chunk instead of
    /// emitting a single `chatResult` string. Set to `[]` to simulate a stream that
    /// completes without emitting any text.
    private var chatStreamChunks: [String]? = nil

    private(set) var verifyCallCount = 0
    private(set) var classifyCallCount = 0
    private(set) var parseGoalCallCount = 0
    private(set) var chatCallCount = 0
    /// Tracks the `useStrongModel` value from the most recent `chat`/`chatStream` call.
    private(set) var lastUseStrongModel: Bool? = nil

    // MARK: - Configuration (call before injecting into the system under test)

    func setConfigured(_ value: Bool) {
        configured = value
    }

    func setVerifyResult(_ result: Result<VerificationResult, MockAgentAIError>, delay: Duration = .zero) {
        verifyResult = result
        verifyDelay = delay
    }

    func setClassifyResult(_ result: Result<OnTaskClassification, MockAgentAIError>) {
        classifyResult = result
    }

    func setParseGoalResult(_ result: Result<GoalParse, MockAgentAIError>) {
        parseGoalResult = result
    }

    func setChatResult(_ result: Result<String, MockAgentAIError>) {
        chatResult = result
        chatStreamChunks = nil  // clear any prior chunk override
    }

    /// Configures `chatStream` to yield each element as a distinct SSE chunk.
    /// Pass `[]` to simulate a stream that completes without yielding any text.
    func setChatStreamChunks(_ chunks: [String]) {
        chatStreamChunks = chunks
    }

    // MARK: - AgentAIService

    func isConfigured() async -> Bool {
        configured
    }

    func classify(
        image: CGImage,
        taskDescription: String,
        successCriteria: String
    ) async throws -> OnTaskClassification {
        classifyCallCount += 1
        return try classifyResult.get()
    }

    func verify(
        image: CGImage,
        taskDescription: String,
        successCriteria: String
    ) async throws -> VerificationResult {
        verifyCallCount += 1
        if verifyDelay > .zero {
            try? await Task.sleep(for: verifyDelay)
        }
        return try verifyResult.get()
    }

    func parseGoal(_ input: String) async throws -> GoalParse {
        parseGoalCallCount += 1
        return try parseGoalResult.get()
    }

    func chat(messages: [ChatMessage], systemPrompt: String, useStrongModel: Bool) async throws -> String {
        chatCallCount += 1
        lastUseStrongModel = useStrongModel
        return try chatResult.get()
    }

    func chatStream(messages: [ChatMessage], systemPrompt: String, useStrongModel: Bool) async throws -> AsyncThrowingStream<String, Error> {
        chatCallCount += 1
        lastUseStrongModel = useStrongModel
        if let chunks = chatStreamChunks {
            return AsyncThrowingStream { continuation in
                for chunk in chunks {
                    continuation.yield(chunk)
                }
                continuation.finish()
            }
        }
        let result = chatResult
        return AsyncThrowingStream { continuation in
            switch result {
            case .success(let text):
                continuation.yield(text)
                continuation.finish()
            case .failure(let error):
                continuation.finish(throwing: error)
            }
        }
    }
}
