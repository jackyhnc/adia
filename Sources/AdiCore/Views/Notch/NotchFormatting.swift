import SwiftUI

internal func notchHeatmapDayAbbrev(_ date: Date) -> String {
    let w = Calendar.current.component(.weekday, from: date)
    return ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"][(w - 1) % 7]
}

internal func notchHeatmapTooltip(_ day: DayActivity) -> String {
    if day.sessionCount == 0 { return "no sessions" }
    let sessions = day.sessionCount == 1 ? "1 session" : "\(day.sessionCount) sessions"
    let h = day.minutes / 60
    let m = day.minutes % 60
    let time: String
    if h > 0 && m > 0 { time = "\(h)h \(m)m" }
    else if h > 0 { time = "\(h)h" }
    else if m > 0 { time = "\(m)m" }
    else { time = "<1m" }
    return "\(sessions) · \(time)"
}

internal func streakDisplayLabel(current: Int, best: Int) -> String {
    let base = "🔥 \(current)d streak"
    guard best > current else { return base }
    return "\(base) (best: \(best)d)"
}

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

internal func focusScoreColor(_ score: Double) -> Color {
    if score >= 0.8 { return .green.opacity(0.75) }
    if score >= 0.6 { return .yellow.opacity(0.75) }
    return Color(red: 1, green: 0.3, blue: 0.3).opacity(0.75)
}

internal func verificationRelativeTime(_ date: Date, now: Date = Date()) -> String {
    let elapsed = max(0, Int(now.timeIntervalSince(date)))
    if elapsed < 60 { return "just now" }
    let totalMinutes = elapsed / 60
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    if hours > 0 && minutes > 0 { return "\(hours)h \(minutes)m ago" }
    if hours > 0 { return "\(hours)h ago" }
    return "\(totalMinutes)m ago"
}

internal func whitelistedDomainsLabel(_ domains: [String], maxVisible: Int = 3) -> String {
    guard !domains.isEmpty else { return "" }
    if domains.count <= maxVisible {
        return domains.joined(separator: ", ")
    }
    let visible = domains.prefix(maxVisible).joined(separator: ", ")
    return "\(visible) +\(domains.count - maxVisible) more"
}

internal func sessionElapsedLabel(seconds: Int) -> String {
    let total = max(0, seconds)
    let h = total / 3600
    let m = (total % 3600) / 60
    if h > 0 && m > 0 { return "\(h)h \(m)m" }
    if h > 0 { return "\(h)h" }
    if m > 0 { return "\(m)m" }
    return "<1m"
}

internal func dailyGoalProgressLabel(todayMinutes: Int, goalMinutes: Int) -> String {
    guard goalMinutes > 0 else { return "" }
    let goalText = compactDuration(goalMinutes)
    if todayMinutes >= goalMinutes { return "\(goalText) daily goal reached!" }
    let progressText = todayMinutes > 0 ? compactDuration(todayMinutes) : "0m"
    return "\(progressText) of \(goalText) daily goal"
}

internal func dailyGoalCollapsedLabel(todayMinutes: Int, goalMinutes: Int) -> String {
    guard goalMinutes > 0 else { return "" }
    let progress = todayMinutes > 0 ? compactDuration(todayMinutes) : "0m"
    let goal = compactDuration(goalMinutes)
    if todayMinutes >= goalMinutes { return "\(progress) / \(goal) ✓" }
    return "\(progress) / \(goal)"
}

private func compactDuration(_ minutes: Int) -> String {
    let h = minutes / 60
    let m = minutes % 60
    if h > 0 && m > 0 { return "\(h)h \(m)m" }
    if h > 0 { return "\(h)h" }
    return "\(m)m"
}
