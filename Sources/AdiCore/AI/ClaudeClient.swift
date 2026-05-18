import Foundation
import CoreGraphics

// Placeholder — full implementation in the Claude API Client task.
// Reads ANTHROPIC_API_KEY from the process environment; never hard-codes credentials.
public actor ClaudeClient {
    public static let shared = ClaudeClient()

    private let apiKey: String?
    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!

    private init() {
        apiKey = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
    }

    // Returns nil when no API key is configured (e.g., in tests).
    public var isConfigured: Bool { apiKey != nil }

    public func classify(
        image: CGImage,
        taskDescription: String,
        successCriteria: String
    ) async throws -> OnTaskClassification {
        // Vision call to claude-haiku-4-5 — implemented in Claude API Client task.
        throw ClaudeError.notImplemented
    }

    public func verify(
        image: CGImage,
        taskDescription: String,
        successCriteria: String
    ) async throws -> VerificationResult {
        // Reasoning call to claude-sonnet-4-6 — implemented in Task Verification task.
        throw ClaudeError.notImplemented
    }

    public func chat(
        messages: [ChatMessage],
        systemPrompt: String
    ) async throws -> String {
        // Text conversation — implemented in Reasoning Conversation task.
        throw ClaudeError.notImplemented
    }
}

public struct OnTaskClassification: Sendable {
    public let status: OnTaskStatus
    public let confidence: Double
    public let reason: String

    public init(status: OnTaskStatus, confidence: Double, reason: String) {
        self.status = status
        self.confidence = confidence
        self.reason = reason
    }
}

public enum ClaudeError: Error, Sendable {
    case notImplemented
    case missingAPIKey
    case httpError(Int, String)
    case decodingError(String)
}
