import SwiftUI

// MARK: - Root

/// Installed as the content of NotchWindowController's NSHostingView.
struct NotchRootView: View {
    @ObservedObject var state: NotchState
    @ObservedObject var session: SessionManager

    var body: some View {
        ZStack {
            if state.isExpanded {
                ExpandedView(state: state, session: session)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.96, anchor: .top).combined(with: .opacity),
                        removal:   .scale(scale: 0.96, anchor: .top).combined(with: .opacity)
                    ))
            } else {
                CollapsedView(state: state, session: session)
                    .transition(.opacity)
            }
        }
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: state.isExpanded)
    }
}

// MARK: - Collapsed pill

private struct CollapsedView: View {
    @ObservedObject var state: NotchState
    @ObservedObject var session: SessionManager

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(dotColor)
                .frame(width: 7, height: 7)
            if session.session != nil {
                Text("Focus")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.85))
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.06, green: 0.06, blue: 0.06))
        .clipShape(Capsule())
        .contentShape(Capsule())
        .onTapGesture { state.expand() }
        .onHover { if $0 { state.expand() } }
    }

    private var dotColor: Color {
        guard session.session != nil else { return .white.opacity(0.35) }
        switch session.onTaskStatus {
        case .onTask:    return .green
        case .offTask:   return .red
        case .ambiguous: return .orange
        }
    }
}

// MARK: - Expanded card

private struct ExpandedView: View {
    @ObservedObject var state: NotchState
    @ObservedObject var session: SessionManager
    @ObservedObject private var conversation: ConversationManager = .shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(Color.white.opacity(0.07))
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.07, green: 0.07, blue: 0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.55), radius: 24, x: 0, y: 10)
    }

    // MARK: Content switcher

    @ViewBuilder
    private var content: some View {
        if state.showingConversation {
            ConversationView(manager: .shared)
        } else if state.isVerifying {
            verifyingBody
        } else if let result = state.verificationResult {
            verificationResultBody(result)
        } else if let s = session.session {
            activeBody(s)
        } else {
            idleBody
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            if state.showingConversation {
                Button {
                    state.exitConversation()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 22, height: 22)
                        .background(Color.white.opacity(0.07))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
            Text("ADIA")
                .font(.system(size: 10, weight: .black, design: .rounded))
                .foregroundStyle(.white.opacity(0.45))
                .tracking(2.5)
            Spacer()
            Button { state.collapse() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 22, height: 22)
                    .background(Color.white.opacity(0.07))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
    }

    // MARK: Active session body

    @ViewBuilder
    private func activeBody(_ s: Session) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Callout banner
            if let callout = state.calloutMessage {
                Text(callout)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 4)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(s.task)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(state.calloutMessage != nil ? .white.opacity(0.5) : .white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .center) {
                    TimelineView(.periodic(from: s.startTime, by: 1.0)) { ctx in
                        Text(elapsed(from: s.startTime, to: ctx.date))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    Spacer()
                    StatusBadge(status: session.onTaskStatus)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, state.calloutMessage != nil ? 8 : 12)

            HStack(spacing: 8) {
                AdiButton(label: "Done", style: .primary) {
                    Task { await SessionManager.shared.verifyAndEnd() }
                }
                AdiButton(label: "Chat", style: .secondary) {
                    state.startConversation(.reasoning(domain: nil))
                }
                Spacer()
                AdiButton(label: "Exit", style: .destructive) {
                    state.startConversation(.earlyExit)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .padding(.bottom, 14)
        }
        .animation(.easeOut(duration: 0.2), value: state.calloutMessage)
    }

    // MARK: Verifying body

    private var verifyingBody: some View {
        VStack(spacing: 10) {
            ProgressView()
                .progressViewStyle(.circular)
                .scaleEffect(0.7)
                .tint(.white.opacity(0.6))
            Text("checking your work…")
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }

    // MARK: Verification result body

    @ViewBuilder
    private func verificationResultBody(_ result: VerificationResult) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: result.verified ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(result.verified ? .green : Color(red: 1, green: 0.3, blue: 0.3))
                Text(result.verified ? "task verified ✓" : "not done yet")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Text(result.explanation)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)

            if !result.verified {
                AdiButton(label: "Keep going", style: .primary) {
                    NotchState.shared.setVerificationResult(nil)
                    NotchState.shared.collapse()
                }
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: Idle body

    @ViewBuilder
    private var idleBody: some View {
        if state.isCreating {
            SessionCreationFormView(state: state, session: session)
                .transition(.asymmetric(
                    insertion: .move(edge: .bottom).combined(with: .opacity),
                    removal: .opacity
                ))
        } else {
            VStack(alignment: .leading, spacing: 10) {
                Text("No active session")
                    .font(.system(size: 13))
                    .foregroundStyle(.white.opacity(0.45))
                AdiButton(label: "Start Session", style: .primary) {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        state.startCreating()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .transition(.opacity)
        }
    }

    // MARK: Helpers

    private func elapsed(from start: Date, to now: Date) -> String {
        let total = max(0, Int(now.timeIntervalSince(start)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }
}

// MARK: - StatusBadge

private struct StatusBadge: View {
    let status: OnTaskStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.14))
        .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .onTask:    return .green
        case .offTask:   return Color(red: 1, green: 0.3, blue: 0.3)
        case .ambiguous: return .orange
        }
    }

    private var label: String {
        switch status {
        case .onTask:    return "On Task"
        case .offTask:   return "Off Task"
        case .ambiguous: return "Check In"
        }
    }
}

// MARK: - Session Creation Form

private struct SessionCreationFormView: View {
    @ObservedObject var state: NotchState
    @ObservedObject var session: SessionManager

    @State private var taskText: String = ""
    @State private var criteriaText: String = ""
    @State private var isStarting: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            fieldGroup(
                label: "WORKING ON",
                placeholder: "e.g. Write my ENGL 101 essay",
                text: $taskText,
                multiline: true
            )
            .padding(.bottom, 8)

            fieldGroup(
                label: "DONE WHEN",
                placeholder: "e.g. Submitted to Canvas",
                text: $criteriaText,
                multiline: false
            )
            .padding(.bottom, 14)

            HStack(spacing: 8) {
                AdiButton(label: isStarting ? "Starting…" : "Go", style: .primary) {
                    startSession()
                }
                .opacity(canStart ? 1 : 0.45)
                .allowsHitTesting(canStart && !isStarting)

                Button("Cancel") {
                    withAnimation(.easeOut(duration: 0.18)) {
                        state.stopCreating()
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.4))
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 14)
    }

    private var canStart: Bool {
        !taskText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func startSession() {
        let t = taskText.trimmingCharacters(in: .whitespaces)
        let c = criteriaText.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty, !isStarting else { return }
        isStarting = true
        Task { @MainActor in
            do {
                try await session.start(task: t, successCriteria: c)
                state.stopCreating()
            } catch {
                print("[SessionCreation] start failed: \(error)")
            }
            isStarting = false
        }
    }

    @ViewBuilder
    private func fieldGroup(
        label: String,
        placeholder: String,
        text: Binding<String>,
        multiline: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.35))
                .tracking(1.5)

            ZStack(alignment: .topLeading) {
                if text.wrappedValue.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.22))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 7)
                        .allowsHitTesting(false)
                }
                if multiline {
                    TextField("", text: text, axis: .vertical)
                        .lineLimit(2...2)
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 7)
                } else {
                    TextField("", text: text)
                        .font(.system(size: 12))
                        .foregroundStyle(.white)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 7)
                }
            }
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
            )
        }
    }
}

// MARK: - AdiButton

private enum AdiButtonStyle { case primary, secondary, destructive }

private struct AdiButton: View {
    let label: String
    let style: AdiButtonStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(foreground)
                .padding(.horizontal, 13)
                .padding(.vertical, 6)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var foreground: Color {
        switch style {
        case .primary:     return .black
        case .secondary:   return .white
        case .destructive: return Color(red: 1, green: 0.3, blue: 0.3)
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:     Color.white
        case .secondary:   Color.white.opacity(0.10)
        case .destructive: Color.red.opacity(0.13)
        }
    }
}
