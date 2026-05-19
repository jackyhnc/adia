import Foundation
import CoreGraphics
#if canImport(AppKit)
import AppKit
#endif

public actor ClaudeClient {
    public static let shared = ClaudeClient()

    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let urlSession: URLSession

    private init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 30
        cfg.timeoutIntervalForResource = 60
        urlSession = URLSession(configuration: cfg)
    }

    /// Resolve API key from SettingsStore (Keychain) first, then env var.
    private func currentKey() async -> String? {
        if let k = await MainActor.run(body: { SettingsStore.shared.anthropicAPIKey }),
           !k.isEmpty { return k }
        return ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
    }

    public func isConfigured() async -> Bool {
        await currentKey() != nil
    }

    // MARK: - On-task classification (claude-haiku-4-5)

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
                imageContent(b64),
                ["type": "text", "text": "Classify this screen. JSON only."]
            ]
        ]]
        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 150,
            "system": system,
            "messages": messages
        ]
        let text = try await post(key: key, body: body)
        return parseClassification(text)
    }

    // MARK: - Task verification (claude-sonnet-4-6)

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
                imageContent(b64),
                ["type": "text", "text": "Is the task verifiably complete? JSON only."]
            ]
        ]]
        let body: [String: Any] = [
            "model": "claude-sonnet-4-6",
            "max_tokens": 300,
            "system": system,
            "messages": messages
        ]
        let text = try await post(key: key, body: body)
        return parseVerification(text)
    }

    // MARK: - Conversational chat (for reasoning / early-exit flows)

    public func chat(
        messages: [ChatMessage],
        systemPrompt: String
    ) async throws -> String {
        guard let key = await currentKey() else { throw ClaudeError.missingAPIKey }
        let apiMessages: [[String: Any]] = messages.map { msg in
            ["role": msg.role.rawValue, "content": msg.content]
        }
        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 600,
            "system": systemPrompt,
            "messages": apiMessages
        ]
        return try await post(key: key, body: body)
    }

    // MARK: - HTTP

    private func post(key: String, body: [String: Any]) async throws -> String {
        var req = URLRequest(url: baseURL)
        req.httpMethod = "POST"
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "content-type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await urlSession.data(for: req)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<unreadable>"
            throw ClaudeError.httpError(statusCode, body)
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let content = (json["content"] as? [[String: Any]])?.first,
            let text = content["text"] as? String
        else {
            throw ClaudeError.decodingError("unexpected response shape")
        }
        return text
    }

    // MARK: - Image helpers

    private func imageContent(_ base64: String) -> [String: Any] {
        [
            "type": "image",
            "source": [
                "type": "base64",
                "media_type": "image/jpeg",
                "data": base64
            ] as [String: Any]
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
