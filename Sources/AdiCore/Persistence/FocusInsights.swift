import Foundation

// MARK: - FocusInsights

/// Aggregated focus patterns derived from session history.
/// All fields are computed by pure functions from `[SessionRecord]`.
public struct FocusInsights: Sendable, Equatable {
    /// Average session duration in minutes. nil when no sessions.
    public let avgSessionMinutes: Int?
    /// Fraction of sessions that were verified complete (0.0–1.0). nil when no sessions.
    public let completionRate: Double?
    /// Mean focus score across sessions that have one (0.0–1.0). nil when none qualify.
    public let avgFocusScore: Double?
    /// Hour of day (0–23) with the highest average focus score. nil when insufficient data.
    public let bestHour: Int?
    /// Day of week (1=Sunday … 7=Saturday) with the most total focused minutes. nil when no sessions.
    public let bestWeekday: Int?
    /// Focus trend comparing recent sessions to older ones.
    public let trend: FocusTrend
    /// Total number of sessions analyzed.
    public let sessionCount: Int
}

/// Direction the user's focus score is moving.
public enum FocusTrend: String, Sendable, Equatable {
    case improving
    case declining
    case steady
    case insufficient
}

// MARK: - Computation

/// Minimum sessions required before insights are shown.
internal let insightsMinSessions = 3
/// Minimum sessions with a focus score needed for trend/avgFocusScore.
internal let insightsMinScoredSessions = 4
/// Threshold delta for trend detection: ±0.05 = steady.
internal let insightsTrendThreshold = 0.05

/// Computes focus insights from a set of session records. Pure function.
internal func computeFocusInsights(
    from records: [SessionRecord],
    calendar: Calendar = .current
) -> FocusInsights {
    guard !records.isEmpty else {
        return FocusInsights(
            avgSessionMinutes: nil, completionRate: nil, avgFocusScore: nil,
            bestHour: nil, bestWeekday: nil, trend: .insufficient, sessionCount: 0
        )
    }

    let avgMinutes = Int(records.reduce(0.0) { $0 + $1.duration } / Double(records.count) / 60.0)
    let completionRate = Double(records.filter(\.completedSuccessfully).count) / Double(records.count)

    let scored = records.filter { $0.focusScore != nil }
    let avgFocus: Double? = scored.isEmpty ? nil :
        scored.reduce(0.0) { $0 + ($1.focusScore ?? 0) } / Double(scored.count)

    let bestHour = computeBestHour(scored, calendar: calendar)
    let bestWeekday = computeBestWeekday(records, calendar: calendar)
    let trend = computeTrend(scored)

    return FocusInsights(
        avgSessionMinutes: avgMinutes,
        completionRate: completionRate,
        avgFocusScore: avgFocus,
        bestHour: bestHour,
        bestWeekday: bestWeekday,
        trend: trend,
        sessionCount: records.count
    )
}

/// Returns the hour (0–23) with the highest average focus score.
/// Requires at least `insightsMinScoredSessions` scored sessions total,
/// and at least 2 sessions in the winning hour to avoid flukes.
private func computeBestHour(
    _ scored: [SessionRecord],
    calendar: Calendar
) -> Int? {
    guard scored.count >= insightsMinScoredSessions else { return nil }
    var hourSums: [Int: Double] = [:]
    var hourCounts: [Int: Int] = [:]
    for r in scored {
        let h = calendar.component(.hour, from: r.startTime)
        hourSums[h, default: 0] += r.focusScore ?? 0
        hourCounts[h, default: 0] += 1
    }
    return hourSums
        .filter { (hourCounts[$0.key] ?? 0) >= 2 }
        .max(by: { a, b in
            // Safe: filter above guarantees all keys exist in hourCounts with value >= 2
            let avgA = a.value / Double(hourCounts[a.key]!)
            let avgB = b.value / Double(hourCounts[b.key]!)
            return avgA < avgB
        })?
        .key
}

/// Returns the weekday (1=Sunday … 7=Saturday) with the most total focused minutes.
private func computeBestWeekday(
    _ records: [SessionRecord],
    calendar: Calendar
) -> Int? {
    guard records.count >= insightsMinSessions else { return nil }
    var weekdayMinutes: [Int: Double] = [:]
    for r in records {
        let wd = calendar.component(.weekday, from: r.startTime)
        weekdayMinutes[wd, default: 0] += r.duration / 60.0
    }
    return weekdayMinutes.max(by: { $0.value < $1.value })?.key
}

/// Compares the average focus score of the newer half vs the older half.
private func computeTrend(_ scored: [SessionRecord]) -> FocusTrend {
    guard scored.count >= insightsMinScoredSessions else { return .insufficient }
    let sorted = scored.sorted { $0.startTime < $1.startTime }
    let mid = sorted.count / 2
    let olderHalf = Array(sorted.prefix(mid))
    let newerHalf = Array(sorted.suffix(sorted.count - mid))
    guard !olderHalf.isEmpty, !newerHalf.isEmpty else { return .insufficient }

    let olderAvg = olderHalf.reduce(0.0) { $0 + ($1.focusScore ?? 0) } / Double(olderHalf.count)
    let newerAvg = newerHalf.reduce(0.0) { $0 + ($1.focusScore ?? 0) } / Double(newerHalf.count)
    let delta = newerAvg - olderAvg
    if delta > insightsTrendThreshold { return .improving }
    if delta < -insightsTrendThreshold { return .declining }
    return .steady
}

// MARK: - Display helpers

/// Formats an hour (0–23) as a human-readable time range, e.g. "2 PM – 3 PM".
internal func formatHourRange(_ hour: Int) -> String {
    let start: String
    let end: String
    if hour == 0 { start = "12 AM"; end = "1 AM" }
    else if hour < 12 { start = "\(hour) AM"; end = hour == 11 ? "12 PM" : "\(hour + 1) AM" }
    else if hour == 12 { start = "12 PM"; end = "1 PM" }
    else { start = "\(hour - 12) PM"; end = hour == 23 ? "12 AM" : "\(hour - 11) PM" }
    return "\(start) – \(end)"
}

/// Formats a weekday number (1=Sunday … 7=Saturday) as a name.
internal func formatWeekday(_ weekday: Int, calendar: Calendar = .current) -> String {
    let symbols = calendar.weekdaySymbols
    guard weekday >= 1, weekday <= symbols.count else { return "Unknown" }
    return symbols[weekday - 1]
}

/// Returns a short emoji + label for the trend.
internal func trendLabel(_ trend: FocusTrend) -> (symbol: String, text: String) {
    switch trend {
    case .improving:    return ("arrow.up.right", "Improving")
    case .declining:    return ("arrow.down.right", "Declining")
    case .steady:       return ("arrow.right", "Steady")
    case .insufficient: return ("questionmark", "Not enough data")
    }
}
