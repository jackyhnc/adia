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

// MARK: - Collapsed pill

private struct CollapsedView: View {
    @ObservedObject var state: NotchState
    @ObservedObject var session: SessionManager
    @State private var idleStreak: Int = 0

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(dotColor)
                .frame(width: 7, height: 7)
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
        .background(Color(red: 0.06, green: 0.06, blue: 0.06))
        .clipShape(Capsule())
        .contentShape(Capsule())
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
            if let callout = state.calloutMessage {
                let tier = state.calloutTier
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: tier >= 3 ? "exclamationmark.3" : "exclamationmark.triangle.fill")
                            .font(.system(size: tier >= 3 ? 18 : 16, weight: .bold))
                            .foregroundStyle(.white)
                        Text(callout)
                            .font(.system(size: tier >= 3 ? 19 : 17, weight: .heavy))
                            .foregroundStyle(.white)
                    }
                    Button {
                        state.startConversation(.reasoning(domain: nil))
                    } label: {
                        Text("actually, I need this →")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.vertical, tier >= 3 ? 16 : 12)
                .background(calloutBackground(tier: tier))
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
        IdleBody(state: state, session: session)
    }

    // MARK: Helpers

    /// Background color for the callout banner, darkening with escalation tier.
    private func calloutBackground(tier: Int) -> Color {
        switch tier {
        case 1: return Color(red: 0.85, green: 0.15, blue: 0.15)
        case 2: return Color(red: 0.70, green: 0.05, blue: 0.05)
        default: return Color(red: 0.50, green: 0.00, blue: 0.00)
        }
    }

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

    @State private var inputText: String = ""
    @State private var clarifyingQuestion: String?
    @State private var isThinking: Bool = false
    @State private var pinAsTemplate: Bool = false
    @FocusState private var inputFocused: Bool

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

            // The AI asks for more detail when the goal is too vague to verify.
            if let q = clarifyingQuestion {
                Text(q)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.orange.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .transition(.opacity)
            }

            HStack(spacing: 8) {
                AdiButton(label: isThinking ? "Thinking…" : "Go", style: .primary) {
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
        isThinking = true
        clarifyingQuestion = nil
        let shouldPin = pinAsTemplate
        Task { @MainActor in
            defer { isThinking = false }
            do {
                let parsed = try await ClaudeClient.shared.parseGoal(text)
                if parsed.ok {
                    let task = parsed.task ?? text
                    let criteria = parsed.successCriteria ?? ""
                    try await session.start(task: task, successCriteria: criteria)
                    if shouldPin {
                        Task { await SessionTemplateStore.shared.add(task: task, successCriteria: criteria) }
                    }
                    state.stopCreating()
                } else {
                    withAnimation { clarifyingQuestion = parsed.question ?? "Can you be more specific?" }
                }
            } catch CaptureError.permissionDenied {
                withAnimation {
                    clarifyingQuestion = "Screen Recording permission required. Grant it in System Settings, then try again."
                }
            } catch {
                // Network/parse failure — don't trap the user; start with their raw words.
                do {
                    try await session.start(task: text, successCriteria: "")
                    if shouldPin {
                        Task { await SessionTemplateStore.shared.add(task: text, successCriteria: "") }
                    }
                    state.stopCreating()
                } catch CaptureError.permissionDenied {
                    withAnimation {
                        clarifyingQuestion = "Screen Recording permission required. Grant it in System Settings, then try again."
                    }
                } catch {
                    withAnimation { clarifyingQuestion = "Couldn't start — try again." }
                }
            }
        }
    }
}

// MARK: - Idle Body

private struct IdleBody: View {
    @ObservedObject var state: NotchState
    @ObservedObject var session: SessionManager
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
        // Re-run whenever a session ends (id changes from UUID → nil) so stats stay fresh.
        .task(id: session.session?.id) {
            sessionStats = await SessionHistory.shared.stats()
            lastRecord = await SessionHistory.shared.load().first
            let sorted = await SessionTemplateStore.shared.sorted()
            templates = Array(sorted.prefix(2))
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

    private func launchTemplate(_ t: SessionTemplate) {
        templateError = nil
        Task { @MainActor in
            do {
                try await SessionManager.shared.start(task: t.task, successCriteria: t.successCriteria)
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
