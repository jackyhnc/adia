import SwiftUI

/// Embedded chat UI used for both the reasoning conversation and the early-exit conversation.
public struct ConversationView: View {
    @ObservedObject public var manager: ConversationManager
    @State private var inputText: String = ""
    /// Guards against two .onAppear callbacks firing in the same render pass — the
    /// messages.count == 1 check is not safe because a second callback can fire before
    /// the first send() increments the message array.
    @State private var didAutoSend = false

    public init(manager: ConversationManager = .shared) {
        self.manager = manager
    }

    public var body: some View {
        VStack(spacing: 0) {
            messageList
            Divider().overlay(Color.white.opacity(0.07))
            inputRow
            actionButtons
        }
    }

    /// When reasoning mode opens for a specific blocked domain, auto-send a user message
    /// so the AI replies immediately without the user needing to type first.
    /// Called from `.onAppear` on the first AI bubble. The `didAutoSend` flag prevents
    /// a double-send if two .onAppear callbacks race in the same render pass.
    private func autoSendOpeningIfNeeded() {
        guard !didAutoSend,
              case .reasoning(let domain) = manager.mode,
              let d = domain, !d.isEmpty,
              !manager.isLoading else { return }
        didAutoSend = true
        manager.send("I'm trying to access \(d)")
    }

    // MARK: - Message list

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(alignment: .leading, spacing: 6) {
                    ForEach(manager.messages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                            .onAppear {
                                if msg.id == manager.messages.first?.id {
                                    autoSendOpeningIfNeeded()
                                }
                            }
                    }
                    if let streaming = manager.streamingContent {
                        StreamingBubble(text: streaming)
                            .id("streaming")
                    } else if manager.isLoading {
                        // Fallback for any non-streaming loading state.
                        TypingIndicator()
                            .id("typing")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            // Fill the available height inside the fixed-size conversation panel
            // (ExpandedView uses maxHeight: .infinity so this scroll view gets
            // all panel space minus the input row and action buttons).
            .frame(maxHeight: .infinity)
            .onChange(of: manager.mode) {
                // Reset the auto-send guard whenever the conversation mode changes so that
                // reopening the view for a different domain fires the opening message again.
                // Without this reset the flag persists across mode changes within the same
                // view lifetime, silently skipping the auto-send for the second domain.
                didAutoSend = false
                // Clear any stale draft text so the user doesn't see leftover input from a
                // previous mode's conversation when the view is reused for a new one.
                inputText = ""
            }
            .onChange(of: manager.messages.count) {
                withAnimation(.easeOut(duration: 0.15)) {
                    if let last = manager.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: manager.streamingContent) {
                withAnimation(.easeOut(duration: 0.05)) {
                    proxy.scrollTo("streaming", anchor: .bottom)
                }
            }
            .onChange(of: manager.isLoading) {
                if manager.isLoading {
                    withAnimation { proxy.scrollTo("typing", anchor: .bottom) }
                }
            }
        }
    }

    // MARK: - Input row

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField("explain yourself...", text: $inputText)
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .textFieldStyle(.plain)
                .submitLabel(.send)
                .onSubmit { sendMessage() }
                .disabled(manager.isLoading)

            Button(action: sendMessage) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.black)
                    .frame(width: 22, height: 22)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .opacity(canSend ? 1 : 0.35)
            .disabled(!canSend)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty && !manager.isLoading
    }

    // MARK: - Action buttons

    @ViewBuilder
    private var actionButtons: some View {
        switch manager.mode {
        case .reasoning(let domain):
            reasoningActions(domain: domain ?? "")
        case .earlyExit:
            exitActions
        case nil:
            EmptyView()
        }
    }

    @ViewBuilder
    private func reasoningActions(domain: String) -> some View {
        if let granted = manager.accessGranted {
            Text(granted ? "✓ access granted" : "⊘ access denied")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(granted ? Color.green : Color(red: 1, green: 0.3, blue: 0.3))
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 8)
        } else if !domain.isEmpty {
            // Grant/deny chips for a specific blocked domain.
            HStack(spacing: 8) {
                ActionChip(label: "Grant Access", color: .green) {
                    manager.grantAccess(domain: domain)
                }
                ActionChip(label: "Keep Blocked", color: Color(red: 1, green: 0.3, blue: 0.3)) {
                    manager.denyAccess()
                    NotchState.shared.exitConversation()
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        } else {
            // No specific domain — user opened Chat while on-task. Give them a way to close.
            ActionChip(label: "Close", color: Color.white.opacity(0.5)) {
                NotchState.shared.exitConversation()
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
    }

    private var exitActions: some View {
        HStack(spacing: 8) {
            ActionChip(label: "Keep Going", color: .green) {
                NotchState.shared.exitConversation()
            }
            ActionChip(label: "End Session", color: Color(red: 1, green: 0.3, blue: 0.3)) {
                manager.confirmEarlyExit()
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 10)
    }

    // MARK: - Helpers

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty else { return }
        inputText = ""
        manager.send(text)
    }
}

// MARK: - MessageBubble

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            if message.role == .assistant {
                Text("adia")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(1)
                    .padding(.top, 2)
                    .frame(width: 30, alignment: .trailing)
            } else {
                Spacer().frame(width: 30)
            }

            Text(cleanedContent)
                .font(.system(size: 12))
                .foregroundStyle(message.role == .assistant ? .white : .white.opacity(0.75))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var cleanedContent: String {
        let stripped = message.content
            .replacingOccurrences(of: "[ACCESS GRANTED]", with: "")
            .replacingOccurrences(of: "[ACCESS DENIED]", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // When the agent responds with only the decision token and no surrounding text,
        // `stripped` is empty — show a short contextual fallback instead of a blank bubble.
        if stripped.isEmpty {
            if message.content.contains("[ACCESS GRANTED]") { return "ok, you're in." }
            if message.content.contains("[ACCESS DENIED]") { return "no." }
        }
        return stripped
    }
}

// MARK: - StreamingBubble

/// Shows an assistant message as it arrives token-by-token.
/// Displays "…" when the buffer is still empty (first network RTT).
private struct StreamingBubble: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Text("adia")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.3))
                .tracking(1)
                .padding(.top, 2)
                .frame(width: 30, alignment: .trailing)
            Text(text.isEmpty ? "…" : text)
                .font(.system(size: 12))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - TypingIndicator

private struct TypingIndicator: View {
    @State private var phase: Int = 0
    private let timer = Timer.publish(every: 0.4, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(Color.white.opacity(i == phase ? 0.7 : 0.2))
                    .frame(width: 4, height: 4)
            }
        }
        .padding(.leading, 36)
        .onReceive(timer) { _ in
            phase = (phase + 1) % 3
        }
    }
}

// MARK: - ActionChip

private struct ActionChip: View {
    let label: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(color)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(color.opacity(0.25), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
    }
}
