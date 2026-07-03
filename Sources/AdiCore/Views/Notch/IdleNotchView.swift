import SwiftUI

struct IdleTaskID: Hashable {
    var sessionID: UUID?
    var followManualOrder: Bool
}

struct IdleBody: View {
    @ObservedObject var state: NotchState
    @ObservedObject var session: SessionManager
    @ObservedObject private var settings = SettingsStore.shared
    @State private var sessionStats: SessionStats? = nil
    @State private var lastRecord: SessionRecord? = nil
    @State private var templates: [SessionTemplate] = []
    @State private var templateError: String? = nil
    @State private var heatmapDays: [DayActivity] = []

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
        .task(id: IdleTaskID(sessionID: session.session?.id, followManualOrder: settings.idleTemplatesFollowManualOrder)) {
            sessionStats = await SessionHistory.shared.stats()
            lastRecord = await SessionHistory.shared.load().first
            let ordered = settings.idleTemplatesFollowManualOrder
                ? await SessionTemplateStore.shared.load()
                : await SessionTemplateStore.shared.sorted()
            templates = Array(ordered.prefix(2))
            heatmapDays = await SessionHistory.shared.weeklyHeatmap()
            NotchState.shared.idleTemplateCount = templates.count
            NotchState.shared.idleHasNote = lastRecord?.note != nil
            NotchState.shared.idleHasHeatmap = heatmapDays.contains { $0.sessionCount > 0 }
            NotchState.shared.idleHasDailyGoal = settings.dailyFocusGoalMinutes != nil
        }
    }

    private var idleContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let s = sessionStats, s.todayCount > 0 || s.weekCount > 0 {
                statsLine(s)
            }

            if let goal = settings.dailyFocusGoalMinutes {
                DailyGoalProgressRow(
                    todayMinutes: sessionStats?.todayMinutes ?? 0,
                    goalMinutes: goal
                )
            }

            if heatmapDays.contains(where: { $0.sessionCount > 0 }) {
                NotchHeatmapView(days: heatmapDays)
            }

            if !templates.isEmpty {
                templateSection
            } else if settings.showSuggestedTemplates {
                suggestedSection
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
                VStack(alignment: .leading, spacing: 3) {
                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                            state.startCreating(prefill: record.task)
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11))
                            Text(record.task)
                                .font(.system(size: 11))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            if record.duration >= 60 {
                                Text(sessionElapsedLabel(seconds: Int(record.duration)))
                                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            }
                        }
                        .foregroundStyle(.white.opacity(0.35))
                    }
                    .buttonStyle(.plain)

                    if let note = record.note {
                        Text(note)
                            .font(.system(size: 10).italic())
                            .foregroundStyle(.white.opacity(0.28))
                            .lineLimit(2)
                            .padding(.leading, 17)
                    }
                }
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

    @ViewBuilder
    private var suggestedSection: some View {
        let suggestions = Array(SuggestedSessionTemplates.all.prefix(SuggestedSessionTemplates.displayCount))
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text("SUGGESTIONS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
                    .tracking(1.5)
                Spacer()
                Button {
                    withAnimation(.easeOut(duration: 0.15)) {
                        settings.showSuggestedTemplates = false
                    }
                } label: {
                    Text("hide")
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.2))
                }
                .buttonStyle(.plain)
                .help("Hide suggestions. Re-enable in Settings → Templates.")
            }

            ForEach(suggestions, id: \.task) { s in
                suggestedButton(s)
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

    private func suggestedButton(_ s: SuggestedTemplate) -> some View {
        Button {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                state.startCreating(prefill: s.task, duration: s.preferredDuration)
            }
        } label: {
            HStack(spacing: 7) {
                Image(systemName: s.icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
                Text(s.task)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
                Spacer()
                if let dur = s.preferredDuration {
                    Text(templateDurationLabel(dur))
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .foregroundStyle(.white.opacity(0.25))
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
            )
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
            if s.streak > 0 {
                Text("·")
                    .foregroundStyle(.white.opacity(0.2))
                Text(streakLabel(s))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.orange.opacity(0.8))
            }
        }
    }

    private func streakLabel(_ s: SessionStats) -> String {
        streakDisplayLabel(current: s.streak, best: s.bestStreak)
    }
}
