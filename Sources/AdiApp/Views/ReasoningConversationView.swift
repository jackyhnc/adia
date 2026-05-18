import SwiftUI
import AdiCore

/// Chat UI where the user argues for access to a blocked site.
/// AI grants (whitelists) or denies with strict reasoning.
struct ReasoningConversationView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isThinking = false
    @State private var requestedDomain = ""
    @FocusState private var inputFocused: Bool

    private let systemPrompt = """
    You are Adia, a strict focus assistant. A student is in a deep work session and trying to access a blocked website.
    Your job: be like a blunt friend who holds them accountable.
    - Allow access ONLY if the reason is genuinely task-relevant (e.g. research needed for the essay, tool needed to complete the task).
    - Deny social media, entertainment, "quick breaks", vague reasons, or anything that sounds like procrastination.
    - Be direct and brief (1-2 sentences). If you're granting access, end your message with exactly: GRANT_ACCESS:<domain>
    - If denying, be slightly harsh but not mean. Examples: "that's not your essay." / "you don't need Twitter to finish this."
    - Remember context across this conversation.
    """

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            messagesArea
            Divider()
            inputArea
        }
        .frame(width: 400, height: 480)
        .onAppear {
            inputFocused = true
            addInitialPrompt()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Make your case")
                    .font(.system(size: 15, weight: .semibold))
                if let session = appState.session {
                    Text("Session: \(session.task.description)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button("Close") { dismiss() }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var messagesArea: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(messages.enumerated()), id: \.offset) { _, msg in
                        messageBubble(msg)
                    }
                    if isThinking {
                        thinkingIndicator
                    }
                }
                .padding(12)
                .id("bottom")
            }
            .onChange(of: messages.count) { _, _ in
                withAnimation { proxy.scrollTo("bottom") }
            }
            .onChange(of: isThinking) { _, _ in
                withAnimation { proxy.scrollTo("bottom") }
            }
        }
    }

    private func messageBubble(_ message: ChatMessage) -> some View {
        let isUser = message.role == "user"
        return HStack {
            if isUser { Spacer(minLength: 40) }
            Text(message.content)
                .font(.system(size: 13))
                .foregroundColor(isUser ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isUser ? Color.accentColor : Color(nsColor: .controlBackgroundColor))
                .cornerRadius(12)
            if !isUser { Spacer(minLength: 40) }
        }
    }

    private var thinkingIndicator: some View {
        HStack {
            ProgressView()
                .scaleEffect(0.7)
                .tint(.secondary)
            Text("thinking…")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal, 12)
    }

    private var inputArea: some View {
        HStack(spacing: 8) {
            TextField("Why do you need this site?", text: $inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .lineLimit(1...4)
                .focused($inputFocused)
                .onSubmit { sendMessage() }
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))

            Button {
                sendMessage()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .accentColor)
            }
            .buttonStyle(.plain)
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isThinking)
        }
        .padding(12)
    }

    private func addInitialPrompt() {
        let intro = ChatMessage(
            role: "assistant",
            content: "yo. what site do you need and why?"
        )
        messages.append(intro)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""

        let userMsg = ChatMessage(role: "user", content: text)
        messages.append(userMsg)
        isThinking = true

        Task {
            do {
                let reply = try await appState.claudeClient.chat(
                    messages: messages,
                    systemPrompt: systemPrompt
                )

                await MainActor.run {
                    isThinking = false
                    if let range = reply.range(of: "GRANT_ACCESS:") {
                        let domainStart = reply.index(range.upperBound, offsetBy: 0)
                        let domain = String(reply[domainStart...])
                            .components(separatedBy: .whitespacesAndNewlines)
                            .first ?? ""
                        if !domain.isEmpty {
                            appState.whitelistDomain(domain)
                            appState.showCallout = false
                            let cleanReply = reply.replacingOccurrences(of: "GRANT_ACCESS:\(domain)", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                            messages.append(ChatMessage(role: "assistant", content: cleanReply.isEmpty ? "Alright, \(domain) is unblocked. Get back to it." : cleanReply))
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
                            return
                        }
                    }
                    messages.append(ChatMessage(role: "assistant", content: reply))
                }
            } catch {
                await MainActor.run {
                    isThinking = false
                    messages.append(ChatMessage(role: "assistant", content: "Error: \(error.localizedDescription)"))
                }
            }
        }
    }
}
