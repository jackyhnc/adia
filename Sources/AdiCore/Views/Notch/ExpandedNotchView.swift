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

    // MARK: Content switcher

    @ViewBuilder
    private var content: some View {
        if state.showingConversation {
            ConversationView(manager: .shared)
        } else if state.isVerifying {
            verifyingBody
        } else if let result = state.verificationResult {
            verificationResultBody(result)
        } else if let s = session.session, s.phase == .paused {
            pausedBody(s)
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

    // MARK: Active session body

    @ViewBuilder
    private func activeBody(_ s: Session) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let callout = state.calloutMessage {
                CalloutBanner(message: callout, tier: state.calloutTier, reason: state.calloutReason) {
                    state.startConversation(.reasoning(domain: nil))
                }
            } else if session.timerExpired {
                TimerExpiredBanner {
                    Task { await SessionManager.shared.verifyAndEnd() }
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(s.task)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle((state.calloutMessage != nil || session.timerExpired) ? .white.opacity(0.5) : .white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .center) {
                    TimelineView(.periodic(from: s.startTime, by: 1.0)) { ctx in
                        let activeElapsed = max(0, ctx.date.timeIntervalSince(s.startTime) - s.pausedDuration)
                        HStack(spacing: 8) {
                            Text(elapsedFromSeconds(Int(activeElapsed)))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.6))
                            if let target = s.targetDuration {
                                let remaining = max(0, target - activeElapsed)
                                Text(durationRemaining(remaining))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.35))
                            }
                        }
                    }
                    if let score = session.focusScore,
                       session.totalCheckCount >= SessionManager.minChecksForFocusScore {
                        Text("\(Int(score * 100))%")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundStyle(focusScoreColor(score))
                            .transition(.opacity)
                    }
                    Spacer()
                    if NetworkMonitor.shared.isCircuitOpen {
                        OfflineBadge()
                    } else {
                        StatusBadge(status: session.onTaskStatus)
                    }
                }

                if let target = s.targetDuration {
                    TimelineView(.periodic(from: s.startTime, by: 1.0)) { ctx in
                        let activeElapsed = max(0, ctx.date.timeIntervalSince(s.startTime) - s.pausedDuration)
                        ProgressBar(progress: CGFloat(min(1.0, activeElapsed / target)))
                    }
                    .frame(height: 3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, (state.calloutMessage != nil || session.timerExpired) ? 8 : 12)

            if !s.whitelistedDomains.isEmpty {
                WhitelistedDomainsRow(domains: s.whitelistedDomains)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                    .transition(.opacity)
            }

            HStack(spacing: 8) {
                AdiButton(label: "Done", style: .primary) {
                    Task { await SessionManager.shared.verifyAndEnd() }
                }
                AdiButton(label: "Pause", style: .secondary) {
                    Task { await SessionManager.shared.pauseSession() }
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
        .animation(.easeOut(duration: 0.2), value: session.timerExpired)
    }

    // MARK: Paused session body

    @ViewBuilder
    private func pausedBody(_ s: Session) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "pause.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.orange)
                Text("Session Paused")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.orange)
            }
            .padding(.bottom, 2)

            Text(s.task)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 8) {
                Text(sessionElapsedLabel(seconds: Int(s.elapsed)))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.4))
                Text("paused")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.orange.opacity(0.6))
                if let score = session.focusScore,
                   session.totalCheckCount >= SessionManager.minChecksForFocusScore {
                    Text("\(Int(score * 100))%")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(focusScoreColor(score))
                }
            }

            if !s.whitelistedDomains.isEmpty {
                WhitelistedDomainsRow(domains: s.whitelistedDomains)
                    .padding(.top, 4)
            }

            HStack(spacing: 8) {
                AdiButton(label: "Resume", style: .primary) {
                    Task { await SessionManager.shared.resumeSession() }
                }
                Spacer()
                AdiButton(label: "End Session", style: .destructive) {
                    Task { await SessionManager.shared.endSession() }
                }
            }
            .padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
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
        let history = state.verificationHistory
        let previousAttempts = history.count > 1 ? Array(history.dropLast()) : []

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: result.verified ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(result.verified ? .green : Color(red: 1, green: 0.3, blue: 0.3))
                Text(result.verified ? "task verified ✓" : "not done yet")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                if history.count > 1 {
                    Text("attempt \(history.count)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white.opacity(0.3))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.07))
                        .clipShape(Capsule())
                }
            }

            Text(result.explanation)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.55))
                .fixedSize(horizontal: false, vertical: true)

            if result.verified {
                if let s = session.session {
                    HStack(spacing: 8) {
                        Label(sessionElapsedLabel(seconds: Int(s.elapsed)), systemImage: "clock.fill")
                        if s.calloutCount > 0 {
                            Text("·")
                                .foregroundStyle(.white.opacity(0.2))
                            Label(
                                "\(s.calloutCount) callout\(s.calloutCount == 1 ? "" : "s")",
                                systemImage: "exclamationmark.bubble.fill"
                            )
                        }
                        if let score = session.focusScore, session.totalCheckCount >= SessionManager.minChecksForFocusScore {
                            Text("·")
                                .foregroundStyle(.white.opacity(0.2))
                            Label("\(Int(score * 100))% focused", systemImage: "target")
                        }
                        if !s.reasoningHistory.isEmpty {
                            Text("·")
                                .foregroundStyle(.white.opacity(0.2))
                            let granted = s.reasoningHistory.filter(\.granted).count
                            Label(
                                "asked \(s.reasoningHistory.count)×, \(granted) granted",
                                systemImage: "bubble.left.and.text.bubble.right.fill"
                            )
                        }
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
                }
                VStack(alignment: .leading, spacing: 4) {
                    Text("SESSION NOTE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.3))
                        .tracking(1.2)
                    ZStack(alignment: .leading) {
                        if completionNote.isEmpty && !noteFieldFocused {
                            Text("Add a note…")
                                .font(.system(size: 11))
                                .foregroundStyle(.white.opacity(0.22))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .allowsHitTesting(false)
                        }
                        TextField("", text: $completionNote)
                            .font(.system(size: 11))
                            .foregroundStyle(.white)
                            .textFieldStyle(.plain)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .focused($noteFieldFocused)
                            .onSubmit {
                                let trimmed = completionNote.trimmingCharacters(in: .whitespaces)
                                completionNote = ""
                                Task { await SessionManager.shared.endSession(note: trimmed.isEmpty ? nil : trimmed) }
                            }
                    }
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.white.opacity(noteFieldFocused ? 0.15 : 0.07), lineWidth: 0.5)
                    )
                }
                .padding(.top, 6)
                AdiButton(label: "End Session", style: .primary) {
                    let trimmed = completionNote.trimmingCharacters(in: .whitespaces)
                    completionNote = ""
                    Task { await SessionManager.shared.endSession(note: trimmed.isEmpty ? nil : trimmed) }
                }
                .padding(.top, 6)
            } else {
                if let domain = session.session?.whitelistedDomains.last {
                    HStack(spacing: 4) {
                        Image(systemName: "link")
                            .font(.system(size: 10))
                        Text("\(domain) is whitelisted — go finish there")
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.white.opacity(0.38))
                    .padding(.top, 2)
                }
                HStack(spacing: 8) {
                    AdiButton(label: "Try again", style: .secondary) {
                        Task { await SessionManager.shared.verifyAndEnd() }
                    }
                    AdiButton(label: "Keep going", style: .primary) {
                        NotchState.shared.setVerificationResult(nil)
                        NotchState.shared.collapse()
                    }
                }
                .padding(.top, 4)
            }

            if !previousAttempts.isEmpty {
                Divider()
                    .overlay(Color.white.opacity(0.08))
                    .padding(.top, 4)

                Text("PREVIOUS ATTEMPTS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(1.2)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(previousAttempts.reversed().enumerated()), id: \.offset) { _, attempt in
                            VerificationAttemptRow(attempt: attempt)
                        }
                    }
                }
                .frame(maxHeight: 100)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: Idle body

    @ViewBuilder
    private var idleBody: some View {
        IdleBody(state: state, session: session)
    }

    // MARK: Helpers

    private func elapsedFromSeconds(_ total: Int) -> String {
        let t = max(0, total)
        let h = t / 3600
        let m = (t % 3600) / 60
        let s = t % 60
        return h > 0
            ? String(format: "%d:%02d:%02d", h, m, s)
            : String(format: "%02d:%02d", m, s)
    }

    private func durationRemaining(_ seconds: TimeInterval) -> String {
        guard seconds > 0 else { return "done" }
        let total = Int(seconds)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 && m > 0 { return "\(h)h \(m)m left" }
        if h > 0 { return "\(h)h left" }
        if m > 0 { return "\(m)m left" }
        return "< 1m left"
    }

}
