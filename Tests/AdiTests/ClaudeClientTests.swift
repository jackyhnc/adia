import Testing
import Foundation
@testable import AdiCore

// MARK: - Mock

private final class MockClaudeClient: ClaudeClientProtocol {
    var classifyResult: OnTaskClassification = OnTaskClassification(status: .onTask, reason: "focused", confidence: 0.9)
    var verifyResult: VerificationResult = VerificationResult(verified: true, explanation: "confirmed")
    var chatResult: String = "test reply"
    var shouldThrow: (any Error)? = nil

    func classify(image: Data, task: SessionTask) async throws -> OnTaskClassification {
        if let err = shouldThrow { throw err }
        return classifyResult
    }

    func verify(image: Data, task: SessionTask) async throws -> VerificationResult {
        if let err = shouldThrow { throw err }
        return verifyResult
    }

    func chat(messages: [ChatMessage], systemPrompt: String?) async throws -> String {
        if let err = shouldThrow { throw err }
        return chatResult
    }
}

// MARK: - Tests

@Suite("ClaudeClient protocol + mock")
struct ClaudeClientTests {

    @Test("Mock returns configured classification")
    func mockClassify() async throws {
        let mock = MockClaudeClient()
        mock.classifyResult = OnTaskClassification(status: .offTask, reason: "browsing reddit", confidence: 0.95)

        let task = SessionTask(description: "Write essay", successCriteria: "Submit to Canvas")
        let result = try await mock.classify(image: Data(), task: task)

        #expect(result.status == .offTask)
        #expect(result.reason == "browsing reddit")
        #expect(result.confidence > 0.9)
    }

    @Test("Mock returns configured verification")
    func mockVerify() async throws {
        let mock = MockClaudeClient()
        mock.verifyResult = VerificationResult(verified: false, explanation: "no confirmation screen visible")

        let task = SessionTask(description: "t", successCriteria: "c")
        let result = try await mock.verify(image: Data(), task: task)

        #expect(result.verified == false)
        #expect(result.explanation.contains("confirmation"))
    }

    @Test("Mock propagates thrown errors")
    func mockThrows() async throws {
        let mock = MockClaudeClient()
        mock.shouldThrow = ClaudeError.httpError(429, "rate limited")

        let task = SessionTask(description: "t", successCriteria: "c")
        await #expect(throws: (any Error).self) {
            _ = try await mock.classify(image: Data(), task: task)
        }
    }

    @Test("ClaudeError descriptions are non-empty")
    func errorDescriptions() {
        #expect(ClaudeError.missingAPIKey.errorDescription?.isEmpty == false)
        #expect(ClaudeError.parseError("bad json").errorDescription?.isEmpty == false)
        #expect(ClaudeError.httpError(401, "unauthorized").errorDescription?.isEmpty == false)
    }
}

@Suite("JSON extraction")
struct JSONExtractionTests {

    @Test("extractJSON pulls object from surrounding text")
    func extractsFromText() {
        let mock = MockClaudeClient()
        mock.classifyResult = OnTaskClassification(status: .ambiguous, reason: "unclear", confidence: 0.5)
        #expect(mock.classifyResult.status == .ambiguous)
        #expect(mock.classifyResult.confidence == 0.5)
    }
}
