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
    @Published public private(set) var mode: ConversationMode?
    @Published public private(set) var accessGranted: Bool? = nil

    private init() {}

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
    }

    // MARK: - Messaging

    public func send(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty, !isLoading else { return }
        messages.append(ChatMessage(role: .user, content: trimmed))
        isLoading = true
        Task { @MainActor in
            do {
                let reply = try await AgentAIClient.shared.chat(
                    messages: messages,
                    systemPrompt: systemPrompt(for: mode)
                )
                messages.append(ChatMessage(role: .assistant, content: reply))
                if case .reasoning = mode {
                    parseAccessDecision(from: reply)
                }
            } catch {
                messages.append(ChatMessage(role: .assistant, content: "something went wrong. try again."))
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
            let memory = domain.map { Self.memoryFragment(for: $0, history: session?.reasoningHistory ?? []) } ?? ""
            return """
            You are Adia, a strict focus monitor. A student wants access to \(site) while working on: "\(task)". \
            Success criteria: "\(criteria)".
            Be a firm but fair friend. One sentence per message. Push back on weak excuses.
            If the reason is genuinely task-relevant, end your message with exactly: [ACCESS GRANTED]
            If you're denying, end with: [ACCESS DENIED]
            Never grant access for entertainment or distraction. No corporate tone — be direct.\(memory)
            """
        case .earlyExit:
            return """
            You are Adia. A student wants to quit their focus session after \(elapsed) min. Task: "\(task)".
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
}
