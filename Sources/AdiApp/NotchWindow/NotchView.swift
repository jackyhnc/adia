import SwiftUI
import AdiCore

/// Root SwiftUI view rendered inside the notch NSPanel.
struct NotchView: View {
    @EnvironmentObject var appState: AppState
    @State private var showSessionCreation = false
    @State private var showEarlyExit = false
    @State private var showReasoning = false

    var body: some View {
        ZStack {
            // Background pill
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.92))

            if appState.isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            } else {
                collapsedIndicator
            }
        }
        .animation(.easeInOut(duration: 0.2), value: appState.isExpanded)
        .onTapGesture {
            if appState.session == nil {
                showSessionCreation = true
            }
            appState.isExpanded.toggle()
            NotificationCenter.default.post(
                name: .adiaNotchExpandedChanged,
                object: nil,
                userInfo: ["expanded": appState.isExpanded]
            )
        }
        .sheet(isPresented: $showSessionCreation) {
            SessionCreationView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showEarlyExit) {
            EarlyExitView()
                .environmentObject(appState)
        }
        .sheet(isPresented: $showReasoning) {
            ReasoningConversationView()
                .environmentObject(appState)
        }
    }

    // MARK: - Collapsed

    private var collapsedIndicator: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
        }
        .padding(.horizontal, 10)
    }

    // MARK: - Expanded

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let session = appState.session {
                activeSessionContent(session)
            } else {
                idleContent
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func activeSessionContent(_ session: Session) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.task.description)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
                Text(session.elapsedFormatted())
                    .font(.system(size: 11, weight: .medium).monospacedDigit())
                    .foregroundColor(.white.opacity(0.6))
            }

            if appState.showCallout {
                Text(appState.calloutMessage)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.orange)
                    .transition(.opacity)
            }

            if appState.isVerifying {
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.6)
                        .tint(.white)
                    Text("Verifying…")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            if let result = appState.verificationResult, !result.verified {
                Text(result.explanation)
                    .font(.system(size: 10))
                    .foregroundColor(.red.opacity(0.9))
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                actionButton("Done", color: .green) {
                    appState.verificationResult = nil
                    appState.verifyCompletion()
                }
                actionButton("Exit", color: .red.opacity(0.8)) {
                    showEarlyExit = true
                }
                if appState.showCallout {
                    actionButton("Explain", color: .blue.opacity(0.8)) {
                        showReasoning = true
                    }
                }
            }
        }
    }

    private var idleContent: some View {
        HStack {
            Text("Tap to start a session")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        }
    }

    private func actionButton(_ label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(color)
                .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private var statusColor: Color {
        switch appState.onTaskStatus {
        case .onTask: return .green
        case .offTask: return .orange
        case .ambiguous: return .yellow
        case .unknown: return .white.opacity(0.4)
        }
    }
}
