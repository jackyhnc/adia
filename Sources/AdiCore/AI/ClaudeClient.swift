import Foundation
import CoreGraphics
#if canImport(AppKit)
import AppKit
#endif

/// Anthropic Claude API client.
/// Uses claude-haiku-4-5-20251001 for fast on-task classification and
/// claude-sonnet-4-6 for verification (higher reasoning quality).
public actor ClaudeClient {
    public static let shared = ClaudeClient()

    private let baseURL     = URL(string: "https://api.anthropic.com/v1/messages")!  // hardcoded constant — URL(_:) always succeeds
    private let haikuModel  = "claude-haiku-4-5-20251001"
    private let sonnetModel = "claude-sonnet-4-6"
    private let urlSession: URLSession

    private init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 30
        cfg.timeoutIntervalForResource = 60
        urlSession = URLSession(configuration: cfg)
    }

    /// Resolve API key: Keychain (SettingsStore) first, then ANTHROPIC_API_KEY env var.
    private func currentKey() async -> String? {
        if let k = await MainActor.run(body: { SettingsStore.shared.anthropicAPIKey }),
           !k.isEmpty { return k }
        let env = ProcessInfo.processInfo.environment
        if let k = env["ANTHROPIC_API_KEY"], !k.isEmpty { return k }
        return EmbeddedSecrets.resolvedKey
    }

    // Set to non-nil in unit tests to override the real key check.
    internal var _isConfiguredOverride: Bool? = nil

    public func isConfigured() async -> Bool {
        if let override = _isConfiguredOverride { return override }
        return await currentKey() != nil
    }

    // MARK: - On-task classification

    public func classify(
        image: CGImage,
        taskDescription: String,
        successCriteria: String
    ) async throws -> OnTaskClassification {
        guard let key = await currentKey() else { throw ClaudeError.missingAPIKey }
        let b64 = try encodeImageToBase64(image)
        let system = """
        You are a strict focus monitor watching a student's screen during a deep work session.
        Task: \(taskDescription)
        Success criteria: \(successCriteria)
        Classify whether the user is currently working on the task or has drifted.
        Rules:
        - "onTask" = screen content directly relates to completing the described task
        - "offTask" = screen shows unrelated content (social media, games, etc.)
        - "ambiguous" = unclear or transitional state
        Respond ONLY with valid JSON — no prose, no markdown fences:
        {"status":"onTask","confidence":0.95,"reason":"one sentence"}
        """
        let messages: [[String: Any]] = [[
            "role": "user",
            "content": [
                ["type": "text", "text": "Classify this screen. JSON only."],
                imageContent(b64),
            ] as [[String: Any]],
        ]]
        let text = try await post(key: key, model: haikuModel, system: system,
                                  messages: messages, maxTokens: 150)
        return parseClassification(text)
    }

    // MARK: - Task verification

    public func verify(
        image: CGImage,
        taskDescription: String,
        successCriteria: String
    ) async throws -> VerificationResult {
        guard let key = await currentKey() else { throw ClaudeError.missingAPIKey }
        let b64 = try encodeImageToBase64(image)
        let system = """
        You are a strict task verifier. A student claims to have completed their work.
        Task: \(taskDescription)
        Success criteria: \(successCriteria)
        Look for concrete, visible evidence on screen: confirmation pages, submission receipts,
        file names with expected content, timestamps, or any indicator the criteria is truly met.
        Be strict — partial progress does not count as verified.
        Respond ONLY with valid JSON:
        {"verified":true,"explanation":"one sentence explaining what you see as evidence"}
        or
        {"verified":false,"explanation":"one sentence explaining what is missing"}
        """
        let messages: [[String: Any]] = [[
            "role": "user",
            "content": [
                ["type": "text", "text": "Is the task verifiably complete? JSON only."],
                imageContent(b64),
            ] as [[String: Any]],
        ]]
        let text = try await post(key: key, model: sonnetModel, system: system,
                                  messages: messages, maxTokens: 300)
        return parseVerification(text)
    }

    // MARK: - Goal parsing (session creation)

    /// Turns a free-text statement of intent ("write my history essay") into a
    /// concrete task + success criteria. If the input is too vague to know when
    /// the user would be done, returns a clarifying question instead of guessing.
    public func parseGoal(_ input: String) async throws -> GoalParse {
        guard let key = await currentKey() else { throw ClaudeError.missingAPIKey }
        let system = """
        You help a student start a focus session. They tell you, in their own words,
        what they're about to work on. Convert it into:
          - task: a clear one-line description of the work
          - successCriteria: a concrete, screen-observable signal that it's done
        If the statement is too vague to define a finish line, DO NOT guess — ask one
        short clarifying question that offers two concrete options.
        Respond ONLY with valid JSON, no markdown:
        {"ok":true,"task":"...","successCriteria":"..."}
        or
        {"ok":false,"question":"Can you be more specific — e.g. X or Y?"}
        """
        let messages: [[String: Any]] = [
            ["role": "user", "content": input],
        ]
        let text = try await post(key: key, model: haikuModel, system: system,
                                  messages: messages, maxTokens: 200)
        return parseGoalResponse(text, original: input)
    }

    // MARK: - Conversational chat (reasoning / early-exit)

    public func chat(
        messages: [ChatMessage],
        systemPrompt: String
    ) async throws -> String {
        guard let key = await currentKey() else { throw ClaudeError.missingAPIKey }
        let apiMessages: [[String: Any]] = messages.map { msg in
            ["role": msg.role.rawValue, "content": msg.content]
        }
        return try await post(key: key, model: haikuModel, system: systemPrompt,
                              messages: apiMessages, maxTokens: 600)
    }

    // MARK: - HTTP

    /// Posts to the Anthropic Messages API and returns the first content block's text.
    private func post(
        key: String,
        model: String,
        system: String,
        messages: [[String: Any]],
        maxTokens: Int
    ) async throws -> String {
        let body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "system": system,
            "messages": messages,
        ]

        var req = URLRequest(url: baseURL)
        req.httpMethod = "POST"
        req.setValue(key,          forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await urlSession.data(for: req)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        guard (200..<300).contains(statusCode) else {
            let bodyStr = String(data: data, encoding: .utf8) ?? "<unreadable>"
            throw ClaudeError.httpError(statusCode, bodyStr)
        }

        guard
            let json    = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = json["content"] as? [[String: Any]],
            let first   = content.first,
            let text    = first["text"] as? String
        else {
            throw ClaudeError.decodingError("unexpected response shape")
        }
        return text
    }

    // MARK: - Image helpers

    /// Anthropic Messages API image content block (base64 source).
    private func imageContent(_ base64: String) -> [String: Any] {
        [
            "type": "image",
            "source": [
                "type": "base64",
                "media_type": "image/jpeg",
                "data": base64,
            ] as [String: Any],
        ]
    }

    private func encodeImageToBase64(_ image: CGImage) throws -> String {
        #if canImport(AppKit)
        let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))
        guard
            let tiff   = nsImage.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let jpeg   = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.72])
        else {
            throw ClaudeError.decodingError("JPEG encoding failed")
        }
        return jpeg.base64EncodedString()
        #else
        throw ClaudeError.decodingError("image encoding unavailable on this platform")
        #endif
    }

    // MARK: - Response parsers

    func parseClassification(_ text: String) -> OnTaskClassification {
        let cleaned = stripMarkdownFences(text)
        guard
            let data   = cleaned.data(using: .utf8),
            let json   = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let status = json["status"] as? String
        else {
            return OnTaskClassification(status: .ambiguous, confidence: 0.5, reason: text)
        }
        let onTaskStatus: OnTaskStatus
        switch status {
        case "onTask":  onTaskStatus = .onTask
        case "offTask": onTaskStatus = .offTask
        default:        onTaskStatus = .ambiguous
        }
        let confidence = json["confidence"] as? Double ?? 0.7
        let reason     = json["reason"]     as? String ?? ""
        return OnTaskClassification(status: onTaskStatus, confidence: confidence, reason: reason)
    }

    private func parseGoalResponse(_ text: String, original: String) -> GoalParse {
        let cleaned = stripMarkdownFences(text)
        guard
            let data = cleaned.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            // Couldn't parse a structured reply — fall back to using the raw input
            // as the task so the user is never blocked by a model hiccup.
            return GoalParse(ok: true, task: original, successCriteria: "", question: nil)
        }
        if let ok = json["ok"] as? Bool, ok == false, let q = json["question"] as? String {
            return GoalParse(ok: false, task: nil, successCriteria: nil, question: q)
        }
        let task = (json["task"] as? String) ?? original
        let criteria = (json["successCriteria"] as? String) ?? ""
        return GoalParse(ok: true, task: task, successCriteria: criteria, question: nil)
    }

    func parseVerification(_ text: String) -> VerificationResult {
        let cleaned = stripMarkdownFences(text)
        guard
            let data        = cleaned.data(using: .utf8),
            let json        = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let verified    = json["verified"]    as? Bool,
            let explanation = json["explanation"] as? String
        else {
            return VerificationResult(verified: false, explanation: text)
        }
        return VerificationResult(verified: verified, explanation: explanation)
    }

    private func stripMarkdownFences(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Supporting types

public struct OnTaskClassification: Sendable {
    public let status: OnTaskStatus
    public let confidence: Double
    public let reason: String

    public init(status: OnTaskStatus, confidence: Double, reason: String) {
        self.status     = status
        self.confidence = confidence
        self.reason     = reason
    }
}

public struct GoalParse: Sendable {
    public let ok: Bool
    public let task: String?
    public let successCriteria: String?
    public let question: String?

    public init(ok: Bool, task: String?, successCriteria: String?, question: String?) {
        self.ok = ok
        self.task = task
        self.successCriteria = successCriteria
        self.question = question
    }
}

public enum ClaudeError: Error, Sendable {
    case missingAPIKey
    case httpError(Int, String)
    case decodingError(String)
}
