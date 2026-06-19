import Foundation

public enum ConversationMode: Sendable, Equatable {
    case reasoning(domain: String?)
    case earlyExit
}

@MainActor
public final class ConversationManager: ObservableObject {
    public static let shared = ConversationManager()

    @Published public private(set) var messages: [ChatMessage] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var streamingContent: String? = nil
    @Published public private(set) var mode: ConversationMode?
    @Published public private(set) var accessGranted: Bool? = nil

    /// Real `AgentAIClient.shared` in production; swapped for `MockAgentAIClient`
    /// in tests via `_injectAIClientForTesting` for deterministic chat replies.
    internal var _aiClient: any AgentAIService = AgentAIClient.shared

    private init() {}

    /// See `SessionManager._injectAIClientForTesting` — same seam, same purpose.
    internal func _injectAIClientForTesting(_ client: any AgentAIService) {
        _aiClient = client
    }

    // MARK: - Lifecycle

    public func start(mode: ConversationMode) {
        self.mode = mode
        messages = []
        accessGranted = nil
        let opening = openingMessage(for: mode)
        messages.append(ChatMessage(role: .assistant, content: opening))
    }

    public func reset() {
        mode = nil
        messages = []
        accessGranted = nil
        isLoading = false
        streamingContent = nil
    }

    // MARK: - Messaging

    public func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isLoading else { return }
        messages.append(ChatMessage(role: .user, content: trimmed))
        isLoading = true
        streamingContent = ""
        Task { @MainActor in
            do {
                if NetworkMonitor.shared.isCircuitOpen {
                    throw ConversationOfflineError()
                }
                let stream = try await _aiClient.chatStream(
                    messages: messages,
                    systemPrompt: systemPrompt(for: mode),
                    useStrongModel: true
                )
                var accumulated = ""
                for try await chunk in stream {
                    accumulated += chunk
                    streamingContent = accumulated
                }
                streamingContent = nil
                NetworkMonitor.shared.recordSuccess()
                // Guard against a stream that completes without yielding any text
                // (e.g. a malformed SSE response with no text_delta events) so the
                // UI never shows an empty bubble.
                let finalContent = accumulated.isEmpty
                    ? "something went wrong. try again."
                    : accumulated
                messages.append(ChatMessage(role: .assistant, content: finalContent))
                if case .reasoning = mode {
                    parseAccessDecision(from: finalContent)
                }
            } catch is ConversationOfflineError {
                streamingContent = nil
                messages.append(ChatMessage(role: .assistant, content: "you're offline — check your connection and try again."))
            } catch {
                streamingContent = nil
                NetworkMonitor.shared.recordFailure()
                let offlineMsg = NetworkMonitor.shared.isConnected
                    ? "something went wrong. try again."
                    : "you're offline — check your connection and try again."
                messages.append(ChatMessage(role: .assistant, content: offlineMsg))
            }
            isLoading = false
        }
    }

    // MARK: - Actions

    /// Called by the "Grant Access" button or when AI grants in-band.
    public func grantAccess(domain: String) {
        accessGranted = true
        recordOutcome(domain: domain, granted: true)
        Task { @MainActor in
            await SessionManager.shared.whitelist(domain: domain)
        }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(800))
            NotchState.shared.exitConversation()
        }
    }

    public func denyAccess() {
        accessGranted = false
        if case .reasoning(let domain) = mode, let d = domain, !d.isEmpty {
            recordOutcome(domain: d, granted: false)
        }
    }

    /// Persists this conversation's verdict to the session so a later ask about the
    /// same domain carries memory of what was already argued and decided.
    private func recordOutcome(domain: String, granted: Bool) {
        let summary = Self.summarize(messages: messages)
        SessionManager.shared.recordReasoningAttempt(domain: domain, granted: granted, summary: summary)
    }

    /// Pure helper: the last assistant message, trimmed of decision tags and truncated
    /// to a length safe for re-injection into a future system prompt.
    public nonisolated static func summarize(messages: [ChatMessage], maxLength: Int = 160) -> String {
        guard let last = messages.last(where: { $0.role == .assistant }) else { return "" }
        var text = last.content
            .replacingOccurrences(of: "[ACCESS GRANTED]", with: "")
            .replacingOccurrences(of: "[ACCESS DENIED]", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if text.count > maxLength {
            text = String(text.prefix(maxLength)).trimmingCharacters(in: .whitespacesAndNewlines) + "…"
        }
        return text
    }

    /// Called by the "Exit Session" button.
    public func confirmEarlyExit() {
        Task { @MainActor in
            await SessionManager.shared.endSession()
        }
    }

    // MARK: - Prompts

    private func openingMessage(for mode: ConversationMode?) -> String {
        switch mode {
        case .reasoning(let domain):
            if let d = domain, !d.isEmpty {
                return "why do you need \(d) right now?"
            }
            return "what's up?"
        case .earlyExit:
            return "you want to stop? what happened?"
        case nil:
            return "what's up?"
        }
    }

    private func systemPrompt(for mode: ConversationMode?) -> String {
        let session = SessionManager.shared.session
        let task = session?.task ?? "their task"
        let criteria = session?.successCriteria ?? ""
        let elapsed = session.map { Int($0.elapsed / 60) } ?? 0

        switch mode {
        case .reasoning(let domain):
            let site = domain.flatMap { $0.isEmpty ? nil : $0 } ?? "this website"
            let history = session?.reasoningHistory ?? []
            let memory = domain.map { Self.memoryFragment(for: $0, history: history) } ?? ""
            let crossSignal = domain.map { Self.crossDomainSignal(for: $0, history: history) } ?? ""
            return """
            You are Adia, a strict focus monitor. A student wants access to \(site) while working on: "\(task)". \
            Success criteria: "\(criteria)".
            Be a firm but fair friend. One sentence per message. Push back on weak excuses.
            If the reason is genuinely task-relevant, end your message with exactly: [ACCESS GRANTED]
            If you're denying, end with: [ACCESS DENIED]
            Never grant access for entertainment or distraction. No corporate tone — be direct.\(memory)\(crossSignal)
            """
        case .earlyExit:
            let criteriaNote = criteria.isEmpty ? "" : " Success criteria: \"\(criteria)\"."
            return """
            You are Adia. A student wants to quit their focus session after \(elapsed) min. Task: "\(task)".\(criteriaNote)
            Try to talk them out of it — be a friend who genuinely wants them to succeed. \
            Ask what's wrong. Offer to adjust. Keep replies to 1-2 sentences.
            If they insist multiple times, let them go without judgment.
            """
        case nil:
            return "You are Adia, a focus assistant."
        }
    }

    /// Pure helper: returns true for GRANTED, false for DENIED, nil if neither.
    public nonisolated static func parseAccessDecision(in reply: String) -> Bool? {
        if reply.contains("[ACCESS GRANTED]") { return true }
        if reply.contains("[ACCESS DENIED]") { return false }
        return nil
    }

    private func parseAccessDecision(from reply: String) {
        guard let decision = Self.parseAccessDecision(in: reply) else { return }
        accessGranted = decision
        guard case .reasoning(let domain) = mode, let d = domain, !d.isEmpty else { return }
        recordOutcome(domain: d, granted: decision)
        if decision {
            Task { @MainActor in
                await SessionManager.shared.whitelist(domain: d)
            }
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(1))
                NotchState.shared.exitConversation()
            }
        }
    }

    // MARK: - Memory injection

    /// Pure helper: renders prior reasoning attempts for `domain` as a system-prompt
    /// fragment so the AI can call out repeat asks instead of starting fresh each time.
    /// Returns "" when there's no relevant history (the common case — first ask).
    public nonisolated static func memoryFragment(for domain: String, history: [ReasoningAttempt]) -> String {
        let trimmed = domain.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "" }
        let prior = history.filter { $0.domain.caseInsensitiveCompare(trimmed) == .orderedSame }
        guard !prior.isEmpty else { return "" }
        let lines = prior.enumerated().map { index, attempt -> String in
            let verdict = attempt.granted ? "GRANTED" : "DENIED"
            let reason = attempt.summary.isEmpty ? "no reason recorded" : attempt.summary
            return "  \(index + 1). \(verdict) — \(reason)"
        }
        return """

        Earlier this session, the user already asked about \(trimmed) \(prior.count == 1 ? "once" : "\(prior.count) times"):
        \(lines.joined(separator: "\n"))
        Use this memory — call out repeat asks, and don't let them re-litigate a denial with the same weak reason.
        """
    }

    /// Pure helper: detects a "house style" cross-domain pattern — the user trying
    /// several *different* sites this session and getting turned down more often than
    /// not. Returns "" unless the pattern is real (>= 2 distinct other domains AND
    /// denials outnumber grants among them), so a single unrelated prior ask — or a
    /// history of legitimately-granted asks elsewhere — never makes the AI suspicious
    /// of what might be a perfectly genuine first-time request.
    public nonisolated static func crossDomainSignal(for domain: String, history: [ReasoningAttempt]) -> String {
        let trimmed = domain.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "" }

        let others = history.filter { $0.domain.caseInsensitiveCompare(trimmed) != .orderedSame }
        guard !others.isEmpty else { return "" }

        var distinctDomains = Set<String>()
        var grantedCount = 0
        var deniedCount = 0
        for attempt in others {
            distinctDomains.insert(attempt.domain.lowercased())
            if attempt.granted { grantedCount += 1 } else { deniedCount += 1 }
        }
        guard distinctDomains.count >= 2, deniedCount > grantedCount else { return "" }

        let grantedClause = grantedCount > 0 ? ", \(grantedCount) granted" : ""
        return """

        Beyond \(trimmed), the user has asked about \(distinctDomains.count) other sites this session — \(deniedCount) of those asks were denied\(grantedClause). That's a pattern worth weighing (they may be testing your limits), but still judge *this* request on its own merits — don't let history elsewhere sink a genuinely good reason.
        """
    }
}

private struct ConversationOfflineError: Error {}
