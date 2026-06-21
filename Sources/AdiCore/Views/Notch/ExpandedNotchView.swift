import SwiftUI

struct ExpandedView: View {
    @ObservedObject var state: NotchState
    @ObservedObject var session: SessionManager
    @ObservedObject private var conversation: ConversationManager = .shared
    @ObservedObject private var network: NetworkMonitor = .shared

    @State private var completionNote: String = ""
    @FocusState private var noteFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(Color.white.opacity(0.07))
            content
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            NotchIslandShape(radius: 26)
                .fill(Color(red: 0.015, green: 0.016, blue: 0.018))
        )
        .overlay(
            NotchIslandShape(radius: 26)
                .stroke(Color.white.opacity(0.055), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 8)
        .clipShape(NotchIslandShape(radius: 26))
        .onChange(of: state.verificationResult?.verified) { _, _ in
            completionNote = ""
        }
    }

    @ViewBuilder
    private var content: some View {
        if state.showingConversation {
            ConversationView(manager: .shared)
        } else if state.isVerifying {
            verifyingBody
        } else if state.verificationResult != nil {
            VerificationResultBody(
                state: state,
                session: session,
                completionNote: $completionNote,
                noteFieldFocused: $noteFieldFocused
            )
        } else if session.session?.phase == .paused {
            PausedSessionBody(session: session)
        } else if session.session != nil {
            ActiveSessionBody(state: state, session: session)
        } else {
            idleBody
        }
    }

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
            if session.session == nil && !state.showingConversation {
                Button {
                    NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                } label: {
                    Image(systemName: "gearshape")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.4))
                        .frame(width: 22, height: 22)
                        .background(Color.white.opacity(0.07))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
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

    @ViewBuilder
    private var idleBody: some View {
        IdleBody(state: state, session: session)
    }
}
