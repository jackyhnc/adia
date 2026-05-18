import SwiftUI
import AdiCore

/// AI tries to keep the user in the session. User can always override.
struct EarlyExitView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isThinking = false
    @State private var showOverrideConfirm = false
    @FocusState private var inputFocused: Bool

    private var systemPrompt: String {
        let session = appState.session
        return """
        You are Adia. A student wants to quit their deep work session early.
        Session task: \(session?.task.description ?? "unknown")
        Success criteria: \(session?.task.successCriteria ?? "unknown")
        Elapsed time: \(session?.elapsedFormatted() ?? "0:00")

        Your job: be a direct, motivating friend. Try ONCE to convince them to stay.
        Be brief (1-2 sentences). Acknowledge their struggle but push back.
        After your first reply, if they still want to quit, just say "okay" and wish them well.
        Do NOT guilt-trip excessively. They can always leave.
        """
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            messagesArea
            Divider()
            bottomArea
        }
        .frame(width: 400, height: 420)
        .onAppear {
            addInitialMessage()
            inputFocused = true
        }
        .alert("Exit session?", isPresented: $showOverrideConfirm) {
            Button("Exit anyway", role: .destructive) {
                appState.endSession(verified: false)
                dismiss()
            }
            Button("Keep going", role: .cancel) {}
        } message: {
            Text("Your session will end and all sites will be unblocked.")
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Leaving already?")
                    .font(.system(size: 15, weight: .semibold))
                if let session = appState.session {
                    Text(session.elapsedFormatted() + " in")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            Button("Exit anyway") {
                showOverrideConfirm = true
            }
            .buttonStyle(.plain)
            .foregroundColor(.red)
            .font(.system(size: 12, weight: .medium))
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
                        HStack {
                            ProgressView().scaleEffect(0.7).tint(.secondary)
                            Text("…").foregroundColor(.secondary).font(.system(size: 12))
                            Spacer()
                        }.padding(.horizontal, 12)
                    }
                }
                .padding(12)
                .id("bottom")
            }
            .onChange(of: messages.count) { _, _ in
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

    private var bottomArea: some View {
        HStack(spacing: 8) {
            TextField("Reply…", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .focused($inputFocused)
                .onSubmit { sendReply() }
                .padding(8)
                .background(Color(nsColor: .textBackgroundColor))
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.3)))

            Button { sendReply() } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(inputText.isEmpty ? .gray : .accentColor)
            }
            .buttonStyle(.plain)
            .disabled(inputText.isEmpty || isThinking)
        }
        .padding(12)
    }

    private func addInitialMessage() {
        isThinking = true
        Task {
            do {
                let reply = try await appState.claudeClient.chat(
                    messages: [ChatMessage(role: "user", content: "I want to quit my session early.")],
                    systemPrompt: systemPrompt
                )
                await MainActor.run {
                    isThinking = false
                    messages.append(ChatMessage(role: "assistant", content: reply))
                }
            } catch {
                await MainActor.run {
                    isThinking = false
                    messages.append(ChatMessage(role: "assistant", content: "You sure? You've come this far."))
                }
            }
        }
    }

    private func sendReply() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        messages.append(ChatMessage(role: "user", content: text))
        isThinking = true

        Task {
            do {
                let allMessages = [ChatMessage(role: "user", content: "I want to quit my session early.")] + messages
                let reply = try await appState.claudeClient.chat(messages: allMessages, systemPrompt: systemPrompt)
                await MainActor.run {
                    isThinking = false
                    messages.append(ChatMessage(role: "assistant", content: reply))
                }
            } catch {
                await MainActor.run {
                    isThinking = false
                }
            }
        }
    }
}
