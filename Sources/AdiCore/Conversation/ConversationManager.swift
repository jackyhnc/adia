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
                let reply = try await ClaudeClient.shared.chat(
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
        Task { @MainActor in
            await SessionManager.shared.whitelist(domain: domain)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            NotchState.shared.exitConversation()
        }
    }

    public func denyAccess() {
        accessGranted = false
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
            let site = domain.flatMap { $0.isEmpty ? nil : $0 } ?? "that site"
            return "why do you need \(site) right now?"
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
            return """
            You are Adia, a strict focus monitor. A student wants access to \(site) while working on: "\(task)". \
            Success criteria: "\(criteria)".
            Be a firm but fair friend. One sentence per message. Push back on weak excuses.
            If the reason is genuinely task-relevant, end your message with exactly: [ACCESS GRANTED]
            If you're denying, end with: [ACCESS DENIED]
            Never grant access for entertainment or distraction. No corporate tone — be direct.
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
    public static func parseAccessDecision(in reply: String) -> Bool? {
        if reply.contains("[ACCESS GRANTED]") { return true }
        if reply.contains("[ACCESS DENIED]") { return false }
        return nil
    }

    private func parseAccessDecision(from reply: String) {
        guard let decision = Self.parseAccessDecision(in: reply) else { return }
        accessGranted = decision
        if decision, case .reasoning(let domain) = mode, let d = domain, !d.isEmpty {
            Task { @MainActor in
                await SessionManager.shared.whitelist(domain: d)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                NotchState.shared.exitConversation()
            }
        }
    }
}
