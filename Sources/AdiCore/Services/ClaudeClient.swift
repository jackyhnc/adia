import Foundation

// MARK: - Protocol (enables mocking in tests)

public protocol ClaudeClientProtocol: Sendable {
    func classify(image: Data, task: SessionTask) async throws -> OnTaskClassification
    func verify(image: Data, task: SessionTask) async throws -> VerificationResult
    func chat(messages: [ChatMessage], systemPrompt: String?) async throws -> String
}

// MARK: - Result types

public struct OnTaskClassification: Sendable {
    public let status: OnTaskStatus
    public let reason: String
    public let confidence: Double

    public init(status: OnTaskStatus, reason: String, confidence: Double) {
        self.status = status
        self.reason = reason
        self.confidence = confidence
    }
}

public struct VerificationResult: Sendable {
    public let verified: Bool
    public let explanation: String

    public init(verified: Bool, explanation: String) {
        self.verified = verified
        self.explanation = explanation
    }
}

public struct ChatMessage: Codable, Sendable, Equatable {
    public let role: String
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

// MARK: - Errors

public enum ClaudeError: Error, LocalizedError, Sendable {
    case httpError(Int, String)
    case parseError(String)
    case missingAPIKey

    public var errorDescription: String? {
        switch self {
        case .httpError(let code, let body): return "HTTP \(code): \(body)"
        case .parseError(let msg): return "Parse error: \(msg)"
        case .missingAPIKey: return "ANTHROPIC_API_KEY not set in environment"
        }
    }
}

// MARK: - Real implementation

public final class ClaudeClient: ClaudeClientProtocol {
    private let apiKey: String
    private let urlSession: URLSession

    private static let apiURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private static let haiku = "claude-haiku-4-5"
    private static let sonnet = "claude-sonnet-4-6"

    public init(apiKey: String, urlSession: URLSession = .shared) {
        self.apiKey = apiKey
        self.urlSession = urlSession
    }

    public static func fromEnvironment() throws -> ClaudeClient {
        guard let key = ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"], !key.isEmpty else {
            throw ClaudeError.missingAPIKey
        }
        return ClaudeClient(apiKey: key)
    }

    public func classify(image: Data, task: SessionTask) async throws -> OnTaskClassification {
        let prompt = """
        You are monitoring a student's screen during a deep work session.
        Task: \(task.description)
        Success criteria: \(task.successCriteria)

        Analyze this screenshot. Is the student on-task?
        Respond with ONLY valid JSON (no markdown, no explanation outside JSON):
        {"status":"on_task"|"off_task"|"ambiguous","reason":"brief reason under 20 words","confidence":0.0-1.0}
        """
        let text = try await sendVision(model: Self.haiku, prompt: prompt, imageData: image)
        return try parseClassification(text)
    }

    public func verify(image: Data, task: SessionTask) async throws -> VerificationResult {
        let prompt = """
        You are verifying task completion.
        Task: \(task.description)
        Success criteria: \(task.successCriteria)

        Analyze the screenshot for concrete evidence of completion: confirmation pages, file names, timestamps, checkmarks.
        Respond with ONLY valid JSON:
        {"verified":true|false,"explanation":"what you see and why, under 40 words"}
        """
        let text = try await sendVision(model: Self.sonnet, prompt: prompt, imageData: image)
        return try parseVerification(text)
    }

    public func chat(messages: [ChatMessage], systemPrompt: String?) async throws -> String {
        var body: [String: Any] = [
            "model": Self.sonnet,
            "max_tokens": 1024,
            "messages": messages.map { ["role": $0.role, "content": $0.content] },
        ]
        if let system = systemPrompt {
            body["system"] = system
        }
        let data = try await request(body: body)
        return try extractText(from: data)
    }

    // MARK: - Private

    private func sendVision(model: String, prompt: String, imageData: Data) async throws -> String {
        let base64 = imageData.base64EncodedString()
        let body: [String: Any] = [
            "model": model,
            "max_tokens": 256,
            "messages": [[
                "role": "user",
                "content": [
                    [
                        "type": "image",
                        "source": [
                            "type": "base64",
                            "media_type": "image/png",
                            "data": base64,
                        ],
                    ],
                    ["type": "text", "text": prompt],
                ],
            ]],
        ]
        let data = try await request(body: body)
        return try extractText(from: data)
    }

    private func request(body: [String: Any]) async throws -> Data {
        var req = URLRequest(url: Self.apiURL)
        req.httpMethod = "POST"
        req.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await urlSession.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw ClaudeError.httpError(status, body)
        }
        return data
    }

    private func extractText(from data: Data) throws -> String {
        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = json["content"] as? [[String: Any]],
            let first = content.first,
            let text = first["text"] as? String
        else {
            throw ClaudeError.parseError("unexpected response structure")
        }
        return text
    }

    private func parseClassification(_ text: String) throws -> OnTaskClassification {
        let jsonStr = extractJSON(from: text)
        guard
            let data = jsonStr.data(using: .utf8),
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let statusStr = json["status"] as? String,
            let reason = json["reason"] as? String,
            let confidence = (json["confidence"] as? NSNumber).map({ $0.doubleValue })
        else {
            throw ClaudeError.parseError("invalid classification response: \(text)")
        }

        let status: OnTaskStatus
        switch statusStr {
        case "on_task": status = .onTask
        case "off_task": status = .offTask
        case "ambiguous": status = .ambiguous
        default: status = .unknown
        }
        return OnTaskClassification(status: status, reason: reason, confidence: confidence)
    }

    private func parseVerification(_ text: String) throws -> VerificationResult {
        let jsonStr = extractJSON(from: text)
        guard
            let data = jsonStr.data(using: .utf8),
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let verified = json["verified"] as? Bool,
            let explanation = json["explanation"] as? String
        else {
            throw ClaudeError.parseError("invalid verification response: \(text)")
        }
        return VerificationResult(verified: verified, explanation: explanation)
    }

    private func extractJSON(from text: String) -> String {
        guard
            let start = text.firstIndex(of: "{"),
            let end = text.lastIndex(of: "}")
        else { return text }
        return String(text[start...end])
    }
}
