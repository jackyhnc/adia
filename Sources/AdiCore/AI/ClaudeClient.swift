import Foundation
import CoreGraphics
#if canImport(AppKit)
import AppKit
#endif

/// Backend AI client. Despite the name (kept for blast-radius reasons), it currently
/// hits OpenAI's Chat Completions API — gpt-5.4-mini for all three call types.
/// Swap the model + base URL constants below to switch providers.
public actor ClaudeClient {
    public static let shared = ClaudeClient()

    private let baseURL = URL(string: "https://api.openai.com/v1/chat/completions")!
    private let model = "gpt-5.4-mini"
    private let urlSession: URLSession

    private init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 30
        cfg.timeoutIntervalForResource = 60
        urlSession = URLSession(configuration: cfg)
    }

    /// Resolve API key from SettingsStore (Keychain) first, then env vars.
    /// Accepts OPENAI_API_KEY or ANTHROPIC_API_KEY (the latter for back-compat
    /// with existing setups — the value is what matters, not the variable name).
    private func currentKey() async -> String? {
        if let k = await MainActor.run(body: { SettingsStore.shared.anthropicAPIKey }),
           !k.isEmpty { return k }
        let env = ProcessInfo.processInfo.environment
        if let k = env["OPENAI_API_KEY"], !k.isEmpty { return k }
        return env["ANTHROPIC_API_KEY"]
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
        let messages: [[String: Any]] = [
            ["role": "system", "content": system],
            ["role": "user", "content": [
                ["type": "text", "text": "Classify this screen. JSON only."],
                imageContent(b64, detail: "low"),
            ]],
        ]
        let text = try await post(key: key, messages: messages, maxTokens: 150)
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
        let messages: [[String: Any]] = [
            ["role": "system", "content": system],
            ["role": "user", "content": [
                ["type": "text", "text": "Is the task verifiably complete? JSON only."],
                imageContent(b64, detail: "high"),
            ]],
        ]
        let text = try await post(key: key, messages: messages, maxTokens: 300)
        return parseVerification(text)
    }

    // MARK: - Conversational chat (reasoning / early-exit)

    public func chat(
        messages: [ChatMessage],
        systemPrompt: String
    ) async throws -> String {
        guard let key = await currentKey() else { throw ClaudeError.missingAPIKey }
        var apiMessages: [[String: Any]] = [["role": "system", "content": systemPrompt]]
        for msg in messages {
            apiMessages.append(["role": msg.role.rawValue, "content": msg.content])
        }
        return try await post(key: key, messages: apiMessages, maxTokens: 600)
    }

    // MARK: - HTTP

    /// Posts a Chat Completions request and returns the assistant message text.
    /// Uses `max_completion_tokens` (gpt-5.x family) and falls back to `max_tokens`
    /// on 400 for older models that don't recognize the newer field.
    private func post(
        key: String,
        messages: [[String: Any]],
        maxTokens: Int
    ) async throws -> String {
        var body: [String: Any] = [
            "model": model,
            "messages": messages,
            "max_completion_tokens": maxTokens,
        ]

        var req = URLRequest(url: baseURL)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        var (data, response) = try await urlSession.data(for: req)
        var statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        // Retry with `max_tokens` for legacy models that reject `max_completion_tokens`.
        if statusCode == 400,
           let errStr = String(data: data, encoding: .utf8),
           errStr.contains("max_completion_tokens") {
            body.removeValue(forKey: "max_completion_tokens")
            body["max_tokens"] = maxTokens
            req.httpBody = try JSONSerialization.data(withJSONObject: body)
            (data, response) = try await urlSession.data(for: req)
            statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        }

        guard (200..<300).contains(statusCode) else {
            let bodyStr = String(data: data, encoding: .utf8) ?? "<unreadable>"
            throw ClaudeError.httpError(statusCode, bodyStr)
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = json["choices"] as? [[String: Any]],
            let first = choices.first,
            let message = first["message"] as? [String: Any],
            let text = message["content"] as? String
        else {
            throw ClaudeError.decodingError("unexpected response shape")
        }
        return text
    }

    // MARK: - Image helpers

    /// OpenAI Chat Completions image content: data URL with optional `detail`.
    private func imageContent(_ base64: String, detail: String) -> [String: Any] {
        [
            "type": "image_url",
            "image_url": [
                "url": "data:image/jpeg;base64,\(base64)",
                "detail": detail,
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

    private func parseClassification(_ text: String) -> OnTaskClassification {
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

    private func parseVerification(_ text: String) -> VerificationResult {
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

public enum ClaudeError: Error, Sendable {
    case missingAPIKey
    case httpError(Int, String)
    case decodingError(String)
}
