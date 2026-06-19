import SwiftUI

struct CollapsedView: View {
    @ObservedObject var state: NotchState
    @ObservedObject var session: SessionManager
    @ObservedObject private var network: NetworkMonitor = .shared
    @ObservedObject private var settings: SettingsStore = .shared
    @State private var idleStreak: Int = 0
    @State private var idleTodayCount: Int = 0
    @State private var idleTodayMinutes: Int = 0

    var body: some View {
        HStack(spacing: 5) {
            if let s = session.session, s.targetDuration != nil {
                TimelineView(.periodic(from: s.startTime, by: 1.0)) { ctx in
                    let activeElapsed = max(0, ctx.date.timeIntervalSince(s.startTime) - s.pausedDuration - (s.pauseStartTime.map { ctx.date.timeIntervalSince($0) } ?? 0))
                    let progress = s.targetDuration.map { min(1.0, activeElapsed / $0) }
                    ProgressDot(color: dotColor, progress: progress)
                }
            } else {
                Circle()
                    .fill(dotColor)
                    .frame(width: 7, height: 7)
            }

            if let s = session.session {
                if s.phase == .paused {
                    Text(collapsedElapsedSeconds(Int(s.elapsed)))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                    Text("||")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(.orange.opacity(0.8))
                } else {
                    TimelineView(.periodic(from: s.startTime, by: 60)) { ctx in
                        let activeSeconds = max(0, Int(ctx.date.timeIntervalSince(s.startTime) - s.pausedDuration))
                        Text(collapsedElapsedSeconds(activeSeconds))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                if let score = session.focusScore,
                   session.totalCheckCount >= SessionManager.minChecksForFocusScore {
                    Text("\(Int(score * 100))%")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundStyle(focusScoreColor(score))
                        .transition(.opacity)
                }
            } else if let goal = settings.dailyFocusGoalMinutes {
                HStack(spacing: 6) {
                    Text(dailyGoalCollapsedLabel(todayMinutes: idleTodayMinutes, goalMinutes: goal))
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(idleTodayMinutes >= goal ? .green.opacity(0.8) : .white.opacity(0.5))
                    if idleStreak > 1 {
                        Text("🔥 \(idleStreak)d")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.orange.opacity(0.85))
                    }
                }
            } else if idleTodayCount > 0 || idleStreak > 1 {
                HStack(spacing: 6) {
                    if idleTodayCount > 0 {
                        Text(collapsedIdleStats())
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    if idleStreak > 1 {
                        Text("🔥 \(idleStreak)d")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(.orange.opacity(0.85))
                    }
                }
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
            let s = await SessionHistory.shared.stats()
            idleStreak = s.streak
            idleTodayCount = s.todayCount
            idleTodayMinutes = s.todayMinutes
        }
    }

    private func collapsedElapsedSeconds(_ total: Int) -> String {
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m" }
        return "Focus"
    }

    private func collapsedIdleStats() -> String {
        let h = idleTodayMinutes / 60
        let m = idleTodayMinutes % 60
        if h > 0 && m > 0 { return "\(idleTodayCount) · \(h)h \(m)m" }
        if h > 0 { return "\(idleTodayCount) · \(h)h" }
        if m > 0 { return "\(idleTodayCount) · \(m)m" }
        return "\(idleTodayCount)"
    }

    private var dotColor: Color {
        guard let s = session.session else { return .white.opacity(0.35) }
        if s.phase == .paused { return .orange }
        if network.isCircuitOpen { return .gray }
        switch session.onTaskStatus {
        case .onTask:    return .green
        case .offTask:   return .red
        case .ambiguous: return .orange
        }
    }
}
