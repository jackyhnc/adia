import Foundation

// MARK: - Response parsers (extension on AgentAIClient)

extension AgentAIClient {

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

    // MARK: - Classification parsing

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

    // MARK: - Goal-response parsing

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

    // MARK: - Local goal rejection

    public static func localGoalRejectionReason(_ input: String) -> String? {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = cleaned.lowercased()
        if cleaned.isEmpty {
            return "Tell me what you're working on."
        }
        // PRD-specified vague inputs with no verifiable subject or deliverable:
        // "work", "be productive", "do stuff", "get things done", "focus".
        // Exact-match (whole input) so "work on my thesis" / "focus on chemistry"
        // still pass through to the model — only the bare word is caught locally.
        let leisureExact: Set<String> = [
            "stuff", "something", "anything", "whatever", "idk", "nothing",
            "chill", "relax", "browse", "scroll", "scrolling", "doomscroll",
            "gaming", "vibing", "chilling", "chillin",
            // PRD §REJECT: no subject or deliverable
            "work", "focus",
            "be productive", "do stuff", "do work", "get things done", "get stuff done",
            "be focused", "stay focused",
            // obvious motivation-speak with no concrete deliverable
            "hustle", "grind",
            "do nothing", "procrastinate",
            // clearly non-work activities — no subject or deliverable whatsoever
            "sleep", "nap",
            "eat", "lunch", "dinner", "breakfast", "brunch",
            // gaming / sports — pure leisure, no deliverable
            "sports", "watching",
            "play games", "play video games", "play videogames",
            "video games", "videogames",
            "watch sports", "watch tv", "watch television",
            "watch a movie", "watch movies", "watch a show", "watch shows",
            // specific game titles — bare input with no deliverable
            "fortnite", "minecraft", "roblox", "valorant", "overwatch",
            "apex legends", "apex", "call of duty", "cod",
            "league of legends", "league", "lol",
            // "play <game>" phrases
            "play fortnite", "play minecraft", "play roblox", "play valorant",
            "play overwatch", "play apex", "play call of duty", "play cod",
            "play league of legends", "play league",
            // social media platforms with no deliverable (bare platform names)
            "twitter", "reddit", "facebook", "x",
            // social-media scrolling / visiting intents — no deliverable
            "scroll twitter", "browse twitter", "check twitter", "open twitter", "visit twitter",
            "scroll reddit", "browse reddit", "check reddit", "open reddit", "visit reddit",
            "scroll facebook", "browse facebook", "check facebook", "open facebook", "visit facebook",
            // "x" needs explicit entries — too short for the entertainmentPlatforms contains check
            "scroll x", "browse x", "check x", "open x", "visit x",
            "scroll instagram", "check instagram", "open instagram", "visit instagram",
            "scroll tiktok", "open tiktok", "check tiktok", "browse tiktok", "visit tiktok",
            "scroll snapchat", "check snapchat", "open snapchat", "browse snapchat", "visit snapchat",
        ]
        if leisureExact.contains(lower) {
            return "That doesn't look like a focus session. What do you want to get done?"
        }
        let entertainmentPlatforms = [
            "youtube", "tiktok", "instagram", "netflix",
            "hulu", "twitch", "snapchat",
        ]
        if entertainmentPlatforms.contains(where: { lower.contains($0) }) {
            return "That doesn't look like a focus session. What do you want to get done?"
        }
        return nil
    }

    // MARK: - Verification parsing

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

    // MARK: - Helpers

    static func stripMarkdownFences(_ text: String) -> String {
        text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func looksLikeAnthropicKey(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.hasPrefix("sk-ant-")
    }

    static func extractOutputText(from json: [String: Any]) -> String? {
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
