import SwiftUI
import AppKit

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

// MARK: - Top-attached island shape

private struct NotchIslandShape: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(radius, rect.width / 2, rect.height / 2)
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - r, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - r),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Progress dot (collapsed notch indicator)

/// Shows a plain colored dot when `progress` is nil, or a thin arc ring with a
/// center dot when `progress` is set (0…1). Used in the collapsed notch to visualise
/// progress toward a target duration.
private struct ProgressDot: View {
    let color: Color
    let progress: Double?

    var body: some View {
        if let p = progress {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 1.5)
                Circle()
                    .trim(from: 0, to: CGFloat(p))
                    .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Circle()
                    .fill(color)
                    .frame(width: 5, height: 5)
            }
            .frame(width: 13, height: 13)
        } else {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
        }
    }
}

// MARK: - Progress bar (expanded active session)

/// Full-width horizontal progress bar — 3pt tall. Uses GeometryReader to fill the
/// available width so the fill accurately reflects `progress` (0…1).
private struct ProgressBar: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(Color.white.opacity(0.5))
                    .frame(width: geo.size.width * max(0, min(1, progress)))
            }
        }
        .frame(height: 3)
    }
}

// MARK: - Collapsed pill

private struct CollapsedView: View {
    @ObservedObject var state: NotchState
    @ObservedObject var session: SessionManager
    @State private var idleStreak: Int = 0

    var body: some View {
        HStack(spacing: 5) {
            // Dot — shows a progress arc when a target duration is set for the active session.
            if let s = session.session, s.targetDuration != nil {
                TimelineView(.periodic(from: s.startTime, by: 1.0)) { ctx in
                    let elapsed = max(0, ctx.date.timeIntervalSince(s.startTime))
                    let progress = s.targetDuration.map { min(1.0, elapsed / $0) }
                    ProgressDot(color: dotColor, progress: progress)
                }
            } else {
                Circle()
                    .fill(dotColor)
                    .frame(width: 7, height: 7)
            }

            if let s = session.session {
                TimelineView(.periodic(from: s.startTime, by: 60)) { ctx in
                    Text(collapsedElapsed(from: s.startTime, to: ctx.date))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
            } else if idleStreak > 1 {
                Text("🔥 \(idleStreak)d")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.orange.opacity(0.85))
            }
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.015, green: 0.016, blue: 0.018))
        .clipShape(NotchIslandShape(radius: 14))
        .contentShape(NotchIslandShape(radius: 14))
        .onTapGesture { state.expand() }
        .onHover { if $0 { state.expand() } }
        .task(id: session.session?.id) {
            guard session.session == nil else { return }
            idleStreak = await SessionHistory.shared.stats().streak
        }
    }

    private func collapsedElapsed(from start: Date, to now: Date) -> String {
        let total = max(0, Int(now.timeIntervalSince(start)))
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m" }
        return "Focus"
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

    @State private var completionNote: String = ""
    @FocusState private var noteFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(Color.white.opacity(0.07))
            content
        }
        // maxHeight: .infinity ensures the dark background fills the entire fixed-size
        // NSPanel rather than stopping at content height, which would leave the lower
        // portion of the panel transparent (clear panel background shows through).
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
            // Reset the draft note whenever the verification card changes state.
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
            // Settings gear — only shown when no session is active.
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
            // Callout banner — appears only when you've been caught off-task.
            // Visually escalates with the session callout tier: deeper red, larger
            // text, and a heavier icon as the user keeps drifting off task.
            // Tier-3 banners also shake horizontally on first appearance via keyframeAnimator.
            if let callout = state.calloutMessage {
                CalloutBanner(message: callout, tier: state.calloutTier) {
                    state.startConversation(.reasoning(domain: nil))
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(s.task)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(state.calloutMessage != nil ? .white.opacity(0.5) : .white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(alignment: .center) {
                    TimelineView(.periodic(from: s.startTime, by: 1.0)) { ctx in
                        HStack(spacing: 8) {
                            Text(elapsed(from: s.startTime, to: ctx.date))
                                .font(.system(size: 12, weight: .medium, design: .monospaced))
                                .foregroundStyle(.white.opacity(0.6))
                            if let target = s.targetDuration {
                                let remaining = max(0, target - ctx.date.timeIntervalSince(s.startTime))
                                Text(durationRemaining(remaining))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(.white.opacity(0.35))
                            }
                        }
                    }
                    Spacer()
                    StatusBadge(status: session.onTaskStatus)
                }

                if let target = s.targetDuration {
                    TimelineView(.periodic(from: s.startTime, by: 1.0)) { ctx in
                        let progress = min(1.0, ctx.date.timeIntervalSince(s.startTime) / target)
                        ProgressBar(progress: CGFloat(progress))
                    }
                    .frame(height: 3)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, state.calloutMessage != nil ? 8 : 12)

            HStack(spacing: 8) {
                AdiButton(label: "Done", style: .primary) {
                    Task { await SessionManager.shared.verifyAndEnd() }
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
                // Stats row while session is still active — endSession() will clear it.
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
                        if let score = session.focusScore, session.totalCheckCount >= 5 {
                            Text("·")
                                .foregroundStyle(.white.opacity(0.2))
                            Label("\(Int(score * 100))% focused", systemImage: "target")
                        }
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.45))
                }
                // Quick note field — lets the user annotate the session immediately
                // at the moment of completion rather than hunting for it in History later.
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
                // Surface the most recently whitelisted domain as a hint — the user may
                // need to visit it to complete the task (e.g. upload to Canvas, submit a form).
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

    private func elapsed(from start: Date, to now: Date) -> String {
        let total = max(0, Int(now.timeIntervalSince(start)))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
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

// MARK: - Callout Banner

/// Escalating callout banner shown at the top of the active-session notch card.
/// Tier 3 banners play a brief horizontal shake on first appearance so the message
/// is impossible to dismiss with a casual glance.
private struct CalloutBanner: View {
    let message: String
    let tier: Int
    let onChat: () -> Void

    // Toggled each time a tier-3 callout fires to trigger the keyframe animator.
    @State private var shakeTrigger: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: tier >= 3 ? "exclamationmark.3" : "exclamationmark.triangle.fill")
                    .font(.system(size: tier >= 3 ? 18 : 16, weight: .bold))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.system(size: tier >= 3 ? 19 : 17, weight: .heavy))
                    .foregroundStyle(.white)
            }
            Button(action: onChat) {
                Text("actually, I need this →")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, tier >= 3 ? 16 : 12)
        .background(bannerBackground)
        // Horizontal shake: 9px amplitude dampening to 0 over ~280ms, tier-3 only.
        .keyframeAnimator(initialValue: CGFloat(0), trigger: shakeTrigger) { content, offsetX in
            content.offset(x: offsetX)
        } keyframes: { _ in
            LinearKeyframe(CGFloat(0),  duration: 0.01)
            LinearKeyframe(CGFloat(-9), duration: 0.05)
            LinearKeyframe(CGFloat(9),  duration: 0.05)
            LinearKeyframe(CGFloat(-7), duration: 0.05)
            LinearKeyframe(CGFloat(7),  duration: 0.05)
            LinearKeyframe(CGFloat(-4), duration: 0.04)
            LinearKeyframe(CGFloat(4),  duration: 0.04)
            LinearKeyframe(CGFloat(0),  duration: 0.04)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        // Fire shake when a tier-3 callout first appears (initial: true) or its message changes.
        .onChange(of: message, initial: true) {
            if tier >= 3 { shakeTrigger.toggle() }
        }
    }

    private var bannerBackground: Color {
        switch tier {
        case 1: return Color(red: 0.85, green: 0.15, blue: 0.15)
        case 2: return Color(red: 0.70, green: 0.05, blue: 0.05)
        default: return Color(red: 0.50, green: 0.00, blue: 0.00)
        }
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

// MARK: - Verification Attempt Row

/// Compact row representing one past (non-current) verification attempt in the history list.
private struct VerificationAttemptRow: View {
    let attempt: VerificationAttempt

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: attempt.result.verified ? "checkmark.circle.fill" : "xmark.circle")
                .font(.system(size: 10))
                .foregroundStyle(attempt.result.verified ? .green.opacity(0.7) : Color(red: 1, green: 0.3, blue: 0.3).opacity(0.6))
                .frame(width: 14)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Attempt \(attempt.attemptNumber)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.45))
                    Text(relativeTime(attempt.timestamp))
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.25))
                }
                Text(attempt.result.explanation)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.35))
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private func relativeTime(_ date: Date) -> String {
        let elapsed = Int(Date().timeIntervalSince(date))
        if elapsed < 60 { return "just now" }
        let minutes = elapsed / 60
        return "\(minutes)m ago"
    }
}

// MARK: - Session Creation Form

private struct SessionCreationFormView: View {
    @ObservedObject var state: NotchState
    @ObservedObject var session: SessionManager

    @State private var inputText: String = ""
    @State private var clarifyingQuestion: String?
    @State private var isThinking: Bool = false
    @State private var pinAsTemplate: Bool = false
    @State private var targetMinutes: Int? = nil
    @FocusState private var inputFocused: Bool

    private let durationPresets: [(Int, String)] = [(25, "25m"), (45, "45m"), (60, "1h"), (90, "90m")]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("WHAT ARE YOU DOING?")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.35))
                .tracking(1.5)
                .padding(.bottom, 4)

            ZStack(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text("e.g. finish my history essay and submit it on Canvas")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.22))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 7)
                        .allowsHitTesting(false)
                }
                TextField("", text: $inputText, axis: .vertical)
                    .lineLimit(2...3)
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .focused($inputFocused)
                    .onSubmit { submit() }
            }
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(clarifyingQuestion != nil
                            ? Color.orange.opacity(0.5)
                            : Color.white.opacity(0.10), lineWidth: 0.5)
            )

            // Duration goal — optional quick-select chips. Tapping a selected chip deselects it.
            HStack(spacing: 0) {
                Text("DURATION")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(1.5)
                Spacer()
                HStack(spacing: 4) {
                    ForEach(durationPresets, id: \.0) { minutes, label in
                        Button {
                            withAnimation(.easeOut(duration: 0.1)) {
                                targetMinutes = (targetMinutes == minutes) ? nil : minutes
                            }
                        } label: {
                            Text(label)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(targetMinutes == minutes ? .black : .white.opacity(0.5))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(targetMinutes == minutes ? Color.white : Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, 8)

            // Adia asks for more detail when the goal is too vague to verify.
            if let q = clarifyingQuestion {
                Text(q)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.orange.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .transition(.opacity)
            }

            HStack(spacing: 8) {
                AdiButton(label: isThinking ? "Checking..." : "Go", style: .primary) {
                    submit()
                }
                .opacity(canSubmit ? 1 : 0.45)
                .allowsHitTesting(canSubmit && !isThinking)

                Button("Cancel") {
                    withAnimation(.easeOut(duration: 0.18)) { state.stopCreating() }
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.4))

                Spacer()

                if canSubmit {
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) { pinAsTemplate.toggle() }
                    } label: {
                        Image(systemName: pinAsTemplate ? "pin.fill" : "pin")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(pinAsTemplate ? .white.opacity(0.85) : .white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .help(pinAsTemplate ? "Will save as pinned template" : "Pin as template")
                    .transition(.opacity)
                }
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .animation(.easeOut(duration: 0.2), value: clarifyingQuestion)
        .onAppear {
            if let prefill = state.sessionCreationPrefill, !prefill.isEmpty {
                inputText = prefill
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                inputFocused = true
            }
        }
    }

    private var canSubmit: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func submit() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !isThinking else { return }
        if let reason = AgentAIClient.localGoalRejectionReason(text) {
            withAnimation { clarifyingQuestion = reason }
            AppLogger.warning("goal.rejected_locally", ["reason": reason])
            return
        }
        isThinking = true
        clarifyingQuestion = nil
        let shouldPin = pinAsTemplate
        let durationSeconds: TimeInterval? = targetMinutes.map { TimeInterval($0 * 60) }
        Task { @MainActor in
            defer { isThinking = false }
            do {
                let parsed = try await AgentAIClient.shared.parseGoal(text)
                guard parsed.ok,
                      let task = parsed.task?.trimmingCharacters(in: .whitespacesAndNewlines),
                      let criteria = parsed.successCriteria?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !task.isEmpty,
                      !criteria.isEmpty
                else {
                    let question = parsed.question ?? "What would I be able to see on screen when this is done?"
                    AppLogger.warning("goal.rejected_by_model", ["question": question])
                    withAnimation { clarifyingQuestion = question }
                    return
                }
                AppLogger.info("goal.accepted", [
                    "taskLength": String(task.count),
                    "criteriaLength": String(criteria.count)
                ])
                try await session.start(task: task, successCriteria: criteria, targetDuration: durationSeconds)
                if shouldPin {
                    Task { await SessionTemplateStore.shared.add(task: task, successCriteria: criteria, preferredDuration: durationSeconds) }
                }
                state.stopCreating()
            } catch CaptureError.permissionDenied {
                withAnimation {
                    clarifyingQuestion = "Screen Recording permission required. Grant it in System Settings, then try again."
                }
            } catch AgentAIError.missingAPIKey {
                AppLogger.error("goal.validation_unavailable", ["reason": "missing_api_key"])
                withAnimation {
                    clarifyingQuestion = "Adia is not configured for monitoring yet. Add a Claude API key in Settings, then try again."
                }
            } catch {
                AppLogger.error("goal.start_failed", ["error": String(describing: error)])
                withAnimation { clarifyingQuestion = "Couldn't start — try again." }
            }
        }
    }
}

// MARK: - Idle Body

/// Composite key so `.task` re-fires on session change OR sort-order setting change.
private struct IdleTaskID: Hashable {
    var sessionID: UUID?
    var followManualOrder: Bool
}

private struct IdleBody: View {
    @ObservedObject var state: NotchState
    @ObservedObject var session: SessionManager
    @ObservedObject private var settings = SettingsStore.shared
    @State private var sessionStats: SessionStats? = nil
    @State private var lastRecord: SessionRecord? = nil
    @State private var templates: [SessionTemplate] = []
    @State private var templateError: String? = nil

    var body: some View {
        Group {
            if state.isCreating {
                SessionCreationFormView(state: state, session: session)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            } else {
                idleContent
                    .transition(.opacity)
            }
        }
        // Re-run when a session ends OR when the template sort-order setting changes.
        .task(id: IdleTaskID(sessionID: session.session?.id, followManualOrder: settings.idleTemplatesFollowManualOrder)) {
            sessionStats = await SessionHistory.shared.stats()
            lastRecord = await SessionHistory.shared.load().first
            let ordered = settings.idleTemplatesFollowManualOrder
                ? await SessionTemplateStore.shared.load()
                : await SessionTemplateStore.shared.sorted()
            templates = Array(ordered.prefix(2))
            NotchState.shared.idleTemplateCount = templates.count
        }
    }

    private var idleContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let s = sessionStats, s.todayCount > 0 || s.weekCount > 0 {
                statsLine(s)
            }

            if !templates.isEmpty {
                templateSection
            }

            if let err = templateError {
                Text(err)
                    .font(.system(size: 10))
                    .foregroundStyle(.orange.opacity(0.8))
                    .lineLimit(2)
                    .transition(.opacity)
            }

            Text("No active session")
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.45))

            AdiButton(label: "Start Session", style: .primary) {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                    state.startCreating()
                }
            }

            if let record = lastRecord {
                Button {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                        state.startCreating(prefill: record.task)
                    }
                } label: {
                    Label(record.task, systemImage: "arrow.clockwise")
                        .font(.system(size: 11))
                        .lineLimit(1)
                        .foregroundStyle(.white.opacity(0.35))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .animation(.easeOut(duration: 0.18), value: templateError)
    }

    @ViewBuilder
    private var templateSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("PINNED")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.3))
                .tracking(1.5)

            ForEach(templates) { t in
                templateButton(t)
            }
        }
    }

    private func templateButton(_ t: SessionTemplate) -> some View {
        Button {
            launchTemplate(t)
        } label: {
            HStack(spacing: 7) {
                Image(systemName: "pin.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.35))
                Text(t.task)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .lineLimit(1)
                Spacer()
                if let dur = t.preferredDuration {
                    Text(templateDurationLabel(dur))
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.35))
                }
                Image(systemName: "play.fill")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.25))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.07))
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func templateDurationLabel(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        if mins >= 60 {
            let h = mins / 60
            let m = mins % 60
            return m == 0 ? "\(h)h" : "\(h)h\(m)m"
        }
        return "\(mins)m"
    }

    private func launchTemplate(_ t: SessionTemplate) {
        templateError = nil
        Task { @MainActor in
            do {
                try await SessionManager.shared.start(
                    task: t.task,
                    successCriteria: t.successCriteria,
                    targetDuration: t.preferredDuration
                )
                Task { await SessionTemplateStore.shared.recordUse(id: t.id) }
                NotchState.shared.collapse()
            } catch CaptureError.permissionDenied {
                withAnimation {
                    templateError = "Screen Recording permission required — enable Adia in System Settings."
                }
            } catch {
                withAnimation {
                    templateError = "Couldn't start session — try again."
                }
            }
        }
    }

    private func statsLine(_ s: SessionStats) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.35))
            Text(idleStatsSummary(s))
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
            if s.streak > 1 {
                Text("·")
                    .foregroundStyle(.white.opacity(0.2))
                Text("🔥 \(s.streak)d streak")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.orange.opacity(0.8))
            }
        }
    }
}

// MARK: - Idle stats formatting (internal for testing)

// When today has no sessions but this week does, use weekly framing so the idle
// screen shows meaningful context ("3 sessions this week · 2h") on a slow day.
internal func idleStatsSummary(_ s: SessionStats) -> String {
    let count: Int
    let minutes: Int
    let suffix: String
    if s.todayCount > 0 {
        count = s.todayCount
        minutes = s.todayMinutes
        suffix = "session\(count == 1 ? "" : "s")"
    } else {
        count = s.weekCount
        minutes = s.weekMinutes
        suffix = "session\(count == 1 ? "" : "s") this week"
    }
    let base = "\(count) \(suffix)"
    guard minutes > 0 else { return base }
    let h = minutes / 60
    let m = minutes % 60
    let time: String
    if h > 0 && m > 0 { time = "\(h)h \(m)m" }
    else if h > 0 { time = "\(h)h" }
    else { time = "\(m)m" }
    return "\(base) · \(time)"
}

// MARK: - Session completion helpers (internal for testing)

/// Returns a compact elapsed-time label for the session completion card.
/// Examples: "<1m", "45m", "1h", "1h 30m".
internal func sessionElapsedLabel(seconds: Int) -> String {
    let total = max(0, seconds)
    let h = total / 3600
    let m = (total % 3600) / 60
    if h > 0 && m > 0 { return "\(h)h \(m)m" }
    if h > 0 { return "\(h)h" }
    if m > 0 { return "\(m)m" }
    return "<1m"
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
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 13)
                .padding(.vertical, 6)
                .frame(minWidth: 42)
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
