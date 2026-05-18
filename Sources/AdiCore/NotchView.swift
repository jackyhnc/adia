import SwiftUI

// MARK: - Root

/// Installed as the content of NotchWindowController's NSHostingView.
/// Switches between collapsed pill and expanded card.
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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(Color.white.opacity(0.07))
            if let s = session.session {
                activeBody(s)
            } else {
                idleBody
            }
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

    // MARK: Header

    private var header: some View {
        HStack {
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
        VStack(alignment: .leading, spacing: 6) {
            Text(s.task)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .center) {
                // Live elapsed timer — no @State needed, TimelineView handles it
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
        .padding(.top, 12)

        HStack(spacing: 8) {
            AdiButton(label: "Done", style: .primary) {
                Task { try? await SessionManager.shared.endSession() }
            }
            AdiButton(label: "Chat", style: .secondary) {
                // Reasoning conversation — implemented in task 11
            }
            Spacer()
            AdiButton(label: "Exit", style: .destructive) {
                Task { try? await SessionManager.shared.endSession() }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 14)
    }

    // MARK: Idle body

    private var idleBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("No active session")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.45))

            AdiButton(label: "Start Session", style: .primary) {
                // Session creation — implemented in task 4
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
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
