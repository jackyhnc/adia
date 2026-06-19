import Foundation
import CoreGraphics
#if canImport(AppKit)
import AppKit
#endif

/// Anthropic Claude-backed AI client for goal parsing, screen classification,
/// verification, and conversational guardrails.
public actor AgentAIClient {
    public static let shared = AgentAIClient()

    // Force unwrap is safe: constant, well-formed URL string — `URL(string:)` cannot fail for it.
    private let baseURL = URL(string: "https://api.anthropic.com/v1/messages")!
    private let anthropicVersion = "2023-06-01"
    private let fastModel: String
    private let strongModel: String
    private let urlSession: URLSession

    private init() {
        let env = ProcessInfo.processInfo.environment
        fastModel   = env["ADIA_CLAUDE_FAST_MODEL"]   ?? "claude-haiku-4-5-20251001"
        strongModel = env["ADIA_CLAUDE_STRONG_MODEL"] ?? "claude-sonnet-4-6"

        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 30
        cfg.timeoutIntervalForResource = 60
        urlSession = URLSession(configuration: cfg)
    }

    /// Resolve the configured Claude / Anthropic API key.
    private func currentKey() async -> String? {
        if let k = await MainActor.run(body: { SettingsStore.shared.agentAIKey }),
           Self.looksLikeAnthropicKey(k) { return k }
        let env = ProcessInfo.processInfo.environment
        if let k = env["ANTHROPIC_API_KEY"],   Self.looksLikeAnthropicKey(k) { return k }
        if let k = env["ADIA_AGENT_AI_KEY"],   Self.looksLikeAnthropicKey(k) { return k }
        if let k = EmbeddedSecrets.resolvedKey, Self.looksLikeAnthropicKey(k) { return k }
        return nil
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
        guard let key = await currentKey() else { throw AgentAIError.missingAPIKey }
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
        let text = try await post(key: key, model: fastModel, system: system,
                                  messages: messages, maxTokens: 500)
        return Self.parseClassification(text)
    }

    // MARK: - Task verification

    public func verify(
        image: CGImage,
        taskDescription: String,
        successCriteria: String
    ) async throws -> VerificationResult {
        guard let key = await currentKey() else { throw AgentAIError.missingAPIKey }
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
        let text = try await post(key: key, model: strongModel, system: system,
                                  messages: messages, maxTokens: 700)
        return Self.parseVerification(text)
    }

    // MARK: - Goal parsing (session creation)

    /// Turns a free-text statement of intent ("write my history essay", "homework",
    /// "make a presentation") into a task + a best-effort success signal.
    public func parseGoal(_ input: String) async throws -> GoalParse {
        guard let key = await currentKey() else { throw AgentAIError.missingAPIKey }
        let system = """
        You help someone start a focus session. They tell you, in their own words,
        what they're about to work on. Convert it into:
          - task: a one-line description of the work, keeping their wording. Do NOT
            invent specifics they didn't say.
          - successCriteria: a best-effort, screen-observable signal that it's done.
            Infer something reasonable yourself — never ask the user to specify it.

        THE ONLY BAR: could a later screenshot plausibly show whether this work is
        happening and whether it's finished? If yes, ACCEPT it — no matter how broadly
        it's worded. You must NOT demand extra detail (problem numbers, slide counts,
        chapter names, word counts). Naming the subject or deliverable is enough.

        ACCEPT (ok:true) — these all have enough to verify from a screen:
          "study for my biology exam", "homework", "make a presentation",
          "write my history essay", "fix the login bug", "resolve this customer ticket",
          "do research on tariffs", "edit my resume".
        REJECT (ok:false) — only when there is NOTHING to verify because no subject or
        deliverable is given at all:
          "work", "be productive", "do stuff", "get things done", "focus".
        Also reject input that is empty, a joke, or clearly NOT a focus session
        (watching YouTube/TikTok/Netflix, scrolling social media, gaming, "doing nothing").
        When you reject, ask ONE short, friendly question for just the missing subject —
        never ask them to be "more specific" about a task that already names one.

        Respond ONLY with valid JSON, no markdown:
        {"ok":true,"task":"...","successCriteria":"..."}
        or
        {"ok":false,"question":"..."}
        """
        let messages: [[String: Any]] = [[
            "role": "user",
            "content": input,
        ]]
        let text = try await post(key: key, model: fastModel, system: system,
                                  messages: messages, maxTokens: 500)
        return Self.parseGoalResponse(text, original: input)
    }

    // MARK: - Conversational chat (reasoning / early-exit)

    public func chat(
        messages: [ChatMessage],
        systemPrompt: String,
        useStrongModel: Bool
    ) async throws -> String {
        guard let key = await currentKey() else { throw AgentAIError.missingAPIKey }
        let apiMessages: [[String: Any]] = messages.map { msg in
            ["role": msg.role.rawValue, "content": msg.content]
        }
        let model = useStrongModel ? strongModel : fastModel
        return try await post(key: key, model: model, system: systemPrompt,
                              messages: apiMessages, maxTokens: 900)
    }

    // MARK: - Streaming chat

    /// Streams a chat response token-by-token via the Anthropic streaming Messages API.
    /// Returns an AsyncThrowingStream that yields text chunks as they arrive from the server.
    /// The caller accumulates chunks to produce the full response.
    public func chatStream(
        messages: [ChatMessage],
        systemPrompt: String,
        useStrongModel: Bool
    ) async throws -> AsyncThrowingStream<String, Error> {
        guard let key = await currentKey() else { throw AgentAIError.missingAPIKey }

        // Capture actor-isolated state into local constants before escaping the actor.
        let session  = urlSession
        let model    = useStrongModel ? strongModel : fastModel
        let apiURL   = baseURL
        let version  = anthropicVersion

        let apiMessages: [[String: Any]] = messages.map { msg in
            ["role": msg.role.rawValue, "content": msg.content] as [String: Any]
        }
        var body: [String: Any] = [
            "model":      model,
            "max_tokens": 900,
            "stream":     true,
            "messages":   apiMessages,
        ]
        if !systemPrompt.isEmpty {
            body["system"] = [
                ["type": "text", "text": systemPrompt,
                 "cache_control": ["type": "ephemeral"]] as [String: Any]
            ]
        }

        var req = URLRequest(url: apiURL)
        req.httpMethod = "POST"
        req.setValue(key,         forHTTPHeaderField: "x-api-key")
        req.setValue(version,     forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        return AsyncThrowingStream { continuation in
            Task {
                do {
                    let (asyncBytes, response) = try await session.bytes(for: req)
                    let http       = response as? HTTPURLResponse
                    let statusCode = http?.statusCode ?? 0
                    guard (200..<300).contains(statusCode) else {
                        throw AgentAIError.httpError(statusCode,
                            "streaming failed with HTTP \(statusCode)")
                    }
                    for try await line in asyncBytes.lines {
                        if let chunk = AgentAIClient.parseSSELine(line) {
                            continuation.yield(chunk)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    /// Parses one Server-Sent Events line and returns the text delta it carries.
    /// Returns nil for all non-text-delta events (message_start, ping, etc.).
    internal static func parseSSELine(_ line: String) -> String? {
        guard line.hasPrefix("data: ") else { return nil }
        let json = String(line.dropFirst(6))
        guard json != "[DONE]",
              let data  = json.data(using: .utf8),
              let obj   = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              (obj["type"] as? String) == "content_block_delta",
              let delta = obj["delta"] as? [String: Any],
              (delta["type"] as? String) == "text_delta",
              let text  = delta["text"] as? String
        else { return nil }
        return text
    }

    // MARK: - HTTP

    /// Max number of retries after the initial attempt. Retries only on 429 and 5xx.
    internal static let maxRetries = 3

    /// Returns true if the HTTP status code warrants a retry (rate-limit or server error).
    /// 4xx errors other than 429 (bad request, auth failure, etc.) are not retried.
    internal static func isRetryableStatusCode(_ code: Int) -> Bool {
        code == 429 || (500...599).contains(code)
    }

    /// Exponential backoff with ±20% jitter: base 1 s, doubling each retry, capped at 30 s.
    /// When `retryAfterSeconds` is present (parsed from the `Retry-After` header on a 429
    /// response), it overrides the exponential calculation — still capped at 30 s so a
    /// misbehaving server cannot stall the app indefinitely.
    ///
    /// - Parameters:
    ///   - attempt: 1-based retry index (1 → 1 s base, 2 → 2 s, 3 → 4 s, …)
    ///   - retryAfterSeconds: server-supplied delay hint; `nil` → use exponential formula.
    internal static func retryDelay(attempt: Int, retryAfterSeconds: TimeInterval?) -> TimeInterval {
        if let explicit = retryAfterSeconds {
            return min(max(explicit, 0), 30.0)
        }
        let base = pow(2.0, Double(attempt - 1)) // 1s, 2s, 4s, 8s, …
        let jitter = Double.random(in: 0.8...1.2)
        return min(base * jitter, 30.0)
    }

    /// Posts to the Anthropic Messages API and returns the first text block.
    /// Retries up to `maxRetries` times on 429 and 5xx with exponential backoff.
    private func post(
        key: String,
        model: String,
        system: String,
        messages: [[String: Any]],
        maxTokens: Int
    ) async throws -> String {
        var body: [String: Any] = [
            "model": model,
            "max_tokens": maxTokens,
            "messages": messages,
        ]
        if !system.isEmpty {
            // Array format enables prompt caching (GA — no beta header needed).
            // The system prompt is stable within a session; cache_control marks it as
            // cacheable so repeated classify() calls reuse the cached prefix.
            body["system"] = [
                ["type": "text", "text": system, "cache_control": ["type": "ephemeral"]] as [String: Any]
            ]
        }

        var req = URLRequest(url: baseURL)
        req.httpMethod = "POST"
        req.setValue(key, forHTTPHeaderField: "x-api-key")
        req.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        var retryAttempt = 0
        while true {
            let (data, response) = try await urlSession.data(for: req)
            let http = response as? HTTPURLResponse
            let statusCode = http?.statusCode ?? 0

            if (200..<300).contains(statusCode) {
                guard
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                    let text = Self.extractOutputText(from: json)
                else {
                    throw AgentAIError.decodingError("unexpected response shape")
                }
                return text
            }

            let bodyStr = String(data: data, encoding: .utf8) ?? "<unreadable>"
            let err = AgentAIError.httpError(statusCode, bodyStr)

            retryAttempt += 1
            guard Self.isRetryableStatusCode(statusCode), retryAttempt <= Self.maxRetries else {
                throw err
            }

            // For 429: honour the server's Retry-After hint when present.
            let retryAfter: TimeInterval? = http.flatMap { resp in
                guard let v = resp.value(forHTTPHeaderField: "Retry-After"),
                      let secs = TimeInterval(v) else { return nil }
                return secs
            }
            let delay = Self.retryDelay(attempt: retryAttempt, retryAfterSeconds: retryAfter)
            AppLogger.warning("api.retry", [
                "attempt":      String(retryAttempt),
                "statusCode":   String(statusCode),
                "delaySeconds": String(format: "%.1f", delay),
                "model":        model,
            ])
            try await Task.sleep(for: Duration.seconds(delay))
        }
    }

    // MARK: - Image helpers

    /// Maximum pixel dimension (width or height) for images sent to the Claude vision API.
    /// Claude internally scales images to fit a 1568×1568 box, so sending larger frames
    /// wastes bandwidth and increases latency without improving classification accuracy.
    /// 1024 keeps payloads compact while preserving enough detail for text/UI recognition.
    internal static let maxVisionDimension: Int = 1024

    /// Downscales a CGImage so its longest side fits within `maxDimension`.
    /// Returns the original image unchanged if it already fits.
    internal static func resizeForVision(_ image: CGImage, maxDimension: Int = maxVisionDimension) -> CGImage {
        let w = image.width
        let h = image.height
        guard max(w, h) > maxDimension else { return image }

        let scale: Double
        if w >= h {
            scale = Double(maxDimension) / Double(w)
        } else {
            scale = Double(maxDimension) / Double(h)
        }
        let newW = max(1, Int(Double(w) * scale))
        let newH = max(1, Int(Double(h) * scale))

        guard let ctx = CGContext(
            data: nil,
            width: newW,
            height: newH,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return image
        }
        ctx.interpolationQuality = .high
        ctx.draw(image, in: CGRect(x: 0, y: 0, width: newW, height: newH))
        return ctx.makeImage() ?? image
    }

    /// Anthropic base64 image content block.
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
        let resized = Self.resizeForVision(image)
        let nsImage = NSImage(cgImage: resized, size: NSSize(width: resized.width, height: resized.height))
        guard
            let tiff   = nsImage.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiff),
            let jpeg   = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.72])
        else {
            throw AgentAIError.decodingError("JPEG encoding failed")
        }
        return jpeg.base64EncodedString()
        #else
        throw AgentAIError.decodingError("image encoding unavailable on this platform")
        #endif
    }

    // MARK: - Response parsers

    static func parseClassification(_ text: String) -> OnTaskClassification {
        let cleaned = stripMarkdownFences(text)
        guard
            let data   = cleaned.data(using: .utf8),
            let json   = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let status = json["status"] as? String
        else {
            AppLogger.warning("ai.classify_parse_failed", [
                "rawLength": String(text.count),
                "preview": String(text.prefix(200)),
            ])
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

    static func parseGoalResponse(_ text: String, original: String) -> GoalParse {
        guard
            let data = stripMarkdownFences(text).data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return GoalParse(
                ok: false,
                task: nil,
                successCriteria: nil,
                question: "I couldn't understand that. What should I be able to see on screen when you're done?"
            )
        }

        if let ok = json["ok"] as? Bool, ok == false {
            let q = (json["question"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return GoalParse(
                ok: false,
                task: nil,
                successCriteria: nil,
                question: (q?.isEmpty == false ? q : nil)
                    ?? "What are you working on? Just name the subject or what you're trying to finish."
            )
        }

        let task = ((json["task"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines))
            .flatMap { $0.isEmpty ? nil : $0 } ?? original
        var criteria = (json["successCriteria"] as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if criteria.isEmpty {
            criteria = "On-screen, the work \"\(task)\" looks finished."
        }
        return GoalParse(ok: true, task: task, successCriteria: criteria, question: nil)
    }

    /// Cheap local guard run BEFORE the model call.
    public static func localGoalRejectionReason(_ input: String) -> String? {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = cleaned.lowercased()
        if cleaned.isEmpty {
            return "Tell me what you're working on."
        }
        // Single-word or short phrases that are unambiguously leisure when used as
        // the entire input (exact match only — prevents false positives like
        // "gaming the algorithm" or "chilling the dough").
        let leisureExact: Set<String> = [
            "stuff", "something", "anything", "whatever", "idk", "nothing",
            "chill", "relax", "browse", "scroll", "scrolling", "doomscroll",
            "gaming", "vibing", "chilling", "chillin",
        ]
        if leisureExact.contains(lower) {
            return "That doesn't look like a focus session. What do you want to get done?"
        }
        // Entertainment / social platforms: if the input contains one of these names
        // it's almost certainly leisure (99%+ of the time). The rare edge case of
        // "youtube API integration" or "netflix engineering blog" passes to the model
        // which handles it correctly; local rejection is for obvious cases only.
        let entertainmentPlatforms = [
            "youtube", "tiktok", "instagram", "netflix",
            "hulu", "twitch", "snapchat",
        ]
        if entertainmentPlatforms.contains(where: { lower.contains($0) }) {
            return "That doesn't look like a focus session. What do you want to get done?"
        }
        return nil
    }

    static func parseVerification(_ text: String) -> VerificationResult {
        let cleaned = stripMarkdownFences(text)
        guard
            let data        = cleaned.data(using: .utf8),
            let json        = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let verified    = json["verified"]    as? Bool,
            let explanation = json["explanation"] as? String
        else {
            AppLogger.warning("ai.verify_parse_failed", [
                "rawLength": String(text.count),
                "preview": String(text.prefix(200)),
            ])
            return VerificationResult(verified: false, explanation: text)
        }
        return VerificationResult(verified: verified, explanation: explanation)
    }

    private static func stripMarkdownFences(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func looksLikeAnthropicKey(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("sk-ant-")
    }

    private static func extractOutputText(from json: [String: Any]) -> String? {
        guard let content = json["content"] as? [[String: Any]] else { return nil }
        let pieces = content.compactMap { block -> String? in
            guard (block["type"] as? String) == "text" else { return nil }
            return block["text"] as? String
        }
        let joined = pieces.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        return joined.isEmpty ? nil : joined
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

/// What `NotchView.SessionCreationFormView.submit()` should do with a `GoalParse`
/// result: either start the session with the (trimmed, non-empty) task/criteria,
/// or surface a clarifying question and let the user revise their input.
public enum GoalSubmissionOutcome: Sendable, Equatable {
    case accepted(task: String, successCriteria: String)
    case needsClarification(question: String)
}

extension GoalParse {
    /// Pure decision mirroring `submit()`'s branch logic — extracted so the
    /// accept/reject/fallback paths can be tested without SwiftUI, `@MainActor`,
    /// or a network round-trip. `ok == false`, a missing/blank `task`, or a
    /// missing/blank `successCriteria` all fall through to `.needsClarification`,
    /// using the model's own `question` when present and non-blank, else `defaultQuestion`.
    public func resolveSubmission(
        defaultQuestion: String = "What would I be able to see on screen when this is done?"
    ) -> GoalSubmissionOutcome {
        guard ok,
              let task = task?.trimmingCharacters(in: .whitespacesAndNewlines),
              let criteria = successCriteria?.trimmingCharacters(in: .whitespacesAndNewlines),
              !task.isEmpty,
              !criteria.isEmpty
        else {
            let q = question?.trimmingCharacters(in: .whitespacesAndNewlines)
            return .needsClarification(question: (q?.isEmpty == false ? q : nil) ?? defaultQuestion)
        }
        return .accepted(task: task, successCriteria: criteria)
    }
}

public enum AgentAIError: Error, Sendable {
    case missingAPIKey
    case httpError(Int, String)
    case decodingError(String)
}
