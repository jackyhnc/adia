import Foundation
import CoreGraphics
#if canImport(AppKit)
import AppKit
#endif

/// Provider-backed AI client for goal parsing, screen classification, verification,
/// and conversational guardrails.
public actor AgentAIClient {
    public static let shared = AgentAIClient()

    private let baseURL = URL(string: "https://api.openai.com/v1/responses")!
    private let fastModel: String
    private let strongModel: String
    private let urlSession: URLSession

    private init() {
        let env = ProcessInfo.processInfo.environment
        fastModel = env["ADIA_OPENAI_FAST_MODEL"] ?? env["ADIA_OPENAI_MODEL"] ?? "gpt-5-mini"
        strongModel = env["ADIA_OPENAI_STRONG_MODEL"] ?? env["ADIA_OPENAI_MODEL"] ?? "gpt-5-mini"

        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest  = 30
        cfg.timeoutIntervalForResource = 60
        urlSession = URLSession(configuration: cfg)
    }

    /// Resolve the configured agent AI key.
    private func currentKey() async -> String? {
        if let k = await MainActor.run(body: { SettingsStore.shared.agentAIKey }),
           Self.looksLikeOpenAIKey(k) { return k }
        let env = ProcessInfo.processInfo.environment
        if let k = env["OPENAI_API_KEY"], Self.looksLikeOpenAIKey(k) { return k }
        if let k = env["ADIA_AGENT_AI_KEY"], Self.looksLikeOpenAIKey(k) { return k }
        if let k = EmbeddedSecrets.resolvedKey, Self.looksLikeOpenAIKey(k) { return k }
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
        let input: [[String: Any]] = [[
            "role": "user",
            "content": [
                ["type": "input_text", "text": "Classify this screen. JSON only."],
                imageContent(b64, detail: "low"),
            ] as [[String: Any]],
        ]]
        let text = try await post(key: key, model: fastModel, instructions: system,
                                  input: input, maxOutputTokens: 500)
        return parseClassification(text)
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
        let input: [[String: Any]] = [[
            "role": "user",
            "content": [
                ["type": "input_text", "text": "Is the task verifiably complete? JSON only."],
                imageContent(b64, detail: "high"),
            ] as [[String: Any]],
        ]]
        let text = try await post(key: key, model: strongModel, instructions: system,
                                  input: input, maxOutputTokens: 700)
        return parseVerification(text)
    }

    // MARK: - Goal parsing (session creation)

    /// Turns a free-text statement of intent ("write my history essay", "homework",
    /// "make a presentation") into a task + a best-effort success signal. The bar is
    /// deliberately LOW: we only need enough to later judge, from a screenshot,
    /// whether the person is on-task and whether they've finished. The real judgment
    /// happens at classification + verification time, not here.
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
        let responseInput: [[String: Any]] = [[
            "role": "user",
            "content": [
                ["type": "input_text", "text": input],
            ],
        ]]
        let text = try await post(key: key, model: fastModel, instructions: system,
                                  input: responseInput, maxOutputTokens: 500)
        return parseGoalResponse(text, original: input)
    }

    // MARK: - Conversational chat (reasoning / early-exit)

    public func chat(
        messages: [ChatMessage],
        systemPrompt: String
    ) async throws -> String {
        guard let key = await currentKey() else { throw AgentAIError.missingAPIKey }
        let apiInput: [[String: Any]] = messages.map { msg in
            [
                "role": msg.role.rawValue,
                "content": [
                    ["type": "input_text", "text": msg.content],
                ],
            ]
        }
        return try await post(key: key, model: fastModel, instructions: systemPrompt,
                              input: apiInput, maxOutputTokens: 900)
    }

    // MARK: - HTTP

    /// Posts to OpenAI Responses API and returns the first output text block.
    private func post(
        key: String,
        model: String,
        instructions: String,
        input: [[String: Any]],
        maxOutputTokens: Int
    ) async throws -> String {
        let body: [String: Any] = [
            "model": model,
            "instructions": instructions,
            "input": input,
            "max_output_tokens": maxOutputTokens,
            "reasoning": ["effort": "minimal"],
        ]

        var req = URLRequest(url: baseURL)
        req.httpMethod = "POST"
        req.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await urlSession.data(for: req)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

        guard (200..<300).contains(statusCode) else {
            let bodyStr = String(data: data, encoding: .utf8) ?? "<unreadable>"
            throw AgentAIError.httpError(statusCode, bodyStr)
        }

        guard
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let text = Self.extractOutputText(from: json)
        else {
            throw AgentAIError.decodingError("unexpected response shape")
        }
        return text
    }

    // MARK: - Image helpers

    /// Responses API image content block (base64 data URL).
    private func imageContent(_ base64: String, detail: String) -> [String: Any] {
        [
            "type": "input_image",
            "image_url": "data:image/jpeg;base64,\(base64)",
            "detail": detail,
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
            throw AgentAIError.decodingError("JPEG encoding failed")
        }
        return jpeg.base64EncodedString()
        #else
        throw AgentAIError.decodingError("image encoding unavailable on this platform")
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
        // If the model couldn't be parsed at all (network glitch / malformed JSON),
        // do not silently start a session with invented criteria. Only accept when
        // the model deliberately returns valid ok:true JSON.
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

    /// Cheap local guard run BEFORE the model call. Intentionally minimal: it only
    /// catches empty input and obvious non-work ("doing nothing", scrolling social,
    /// watching video). Real work/study tasks — including broad ones like "homework"
    /// or "study" — pass straight through to the (permissive) model parser.
    public static func localGoalRejectionReason(_ input: String) -> String? {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = cleaned.lowercased()
        if cleaned.isEmpty {
            return "Tell me what you're working on."
        }
        // Pure-leisure / non-task inputs (exact match only, so "research instagram
        // marketing" or "study netflix's business model" still pass).
        let leisureExact: Set<String> = [
            "stuff", "something", "anything", "whatever", "idk", "nothing",
            "chill", "relax", "browse", "scroll", "scrolling", "doomscroll"
        ]
        if leisureExact.contains(lower) {
            return "That doesn't look like a focus session. What do you want to get done?"
        }
        if lower.contains("youtube") || lower.contains("tiktok")
            || lower.contains("instagram") || lower.contains("netflix") {
            return "That doesn't look like a focus session. What do you want to get done?"
        }
        return nil
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

    private static func looksLikeOpenAIKey(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("sk-") && !trimmed.hasPrefix("sk-ant-")
    }

    private static func extractOutputText(from json: [String: Any]) -> String? {
        if let direct = json["output_text"] as? String, !direct.isEmpty {
            return direct
        }
        guard let output = json["output"] as? [[String: Any]] else { return nil }
        var pieces: [String] = []
        for item in output {
            guard let content = item["content"] as? [[String: Any]] else { continue }
            for block in content {
                if let text = block["text"] as? String {
                    pieces.append(text)
                } else if let text = block["output_text"] as? String {
                    pieces.append(text)
                }
            }
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

public enum AgentAIError: Error, Sendable {
    case missingAPIKey
    case httpError(Int, String)
    case decodingError(String)
}
