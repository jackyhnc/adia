import Foundation

// MARK: - SessionStats

/// Snapshot of the user's focus activity, used by the idle notch UI.
public struct SessionStats: Sendable {
    /// Sessions that started today (local calendar day).
    public let todayCount: Int
    /// Total focused minutes logged today.
    public let todayMinutes: Int
    /// Sessions that started during the current calendar week (locale-aware week start).
    public let weekCount: Int
    /// Total focused minutes during the current calendar week.
    public let weekMinutes: Int
    /// Consecutive calendar days with ≥1 session, ending at the most recent session day.
    /// 0 if there have been no sessions, or if the last session was more than 1 day ago.
    public let streak: Int
    /// Total sessions across all time in the stored history window.
    /// Defaults to 0 so call sites that don't need all-time stats compile without changes.
    public let allTimeCount: Int
    /// Total focused minutes across all time in the stored history window.
    public let allTimeMinutes: Int
    /// Longest consecutive-day streak ever recorded in the current history.
    /// Equal to `streak` when the user is currently on their personal best.
    public let bestStreak: Int

    public init(
        todayCount: Int,
        todayMinutes: Int,
        weekCount: Int,
        weekMinutes: Int,
        streak: Int,
        allTimeCount: Int = 0,
        allTimeMinutes: Int = 0,
        bestStreak: Int = 0
    ) {
        self.todayCount    = todayCount
        self.todayMinutes  = todayMinutes
        self.weekCount     = weekCount
        self.weekMinutes   = weekMinutes
        self.streak        = streak
        self.allTimeCount  = allTimeCount
        self.allTimeMinutes = allTimeMinutes
        self.bestStreak    = bestStreak
    }
}

// MARK: - DayActivity

/// Focus activity for a single calendar day, used by the weekly heatmap.
public struct DayActivity: Sendable {
    /// The start of the calendar day (midnight local time).
    public let date: Date
    /// Number of sessions that started on this day.
    public let sessionCount: Int
    /// Total focused minutes logged on this day.
    public let minutes: Int
}

/// Returns `[DayActivity]` for the 7 calendar days ending on `today` (oldest first).
/// Index 0 = 6 days ago, index 6 = today. Pure function, directly testable.
internal func weeklyHeatmapData(
    _ records: [SessionRecord],
    calendar: Calendar = .current,
    today: Date = Date()
) -> [DayActivity] {
    let todayStart = calendar.startOfDay(for: today)
    return (0..<7).compactMap { offset -> DayActivity? in
        guard let date = calendar.date(byAdding: .day, value: offset - 6, to: todayStart)
        else { return nil }
        let dayRecs = records.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
        let mins = Int(dayRecs.reduce(0.0) { $0 + $1.duration } / 60)
        return DayActivity(date: date, sessionCount: dayRecs.count, minutes: mins)
    }
}

/// Computes the best (longest) consecutive-day streak across all sessions.
/// Each calendar day that contains at least one session counts as one day in the streak.
/// Multiple sessions on the same day count as a single day for streak purposes.
/// Returns 0 for an empty record set. Pure function, directly testable.
internal func computeBestStreak(
    from records: [SessionRecord],
    calendar: Calendar = .current
) -> Int {
    guard !records.isEmpty else { return 0 }
    let daySet = Set(records.map { calendar.startOfDay(for: $0.startTime) })
    let sorted = daySet.sorted()
    guard sorted.count > 1 else { return 1 }
    var best = 1
    var current = 1
    for i in 1..<sorted.count {
        let prev = sorted[i - 1]
        let curr = sorted[i]
        let diff = calendar.dateComponents([.day], from: prev, to: curr).day ?? 0
        if diff == 1 {
            current += 1
            if current > best { best = current }
        } else {
            current = 1
        }
    }
    return best
}

// MARK: - CSV export

/// Wraps `value` in double-quotes if it contains a comma, double-quote, CR, or LF.
/// Embedded double-quotes are escaped by doubling them (RFC 4180).
private func csvEscape(_ value: String) -> String {
    let needsQuoting = value.contains(",") || value.contains("\"")
        || value.contains("\n") || value.contains("\r")
    guard needsQuoting else { return value }
    return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
}

/// Returns `records` formatted as RFC 4180 CSV with a header row.
/// Columns: id, task, successCriteria, startTime, endTime, durationSeconds,
/// completedSuccessfully, calloutCount, onTaskChecks, totalChecks, focusScore,
/// reasoningAttempts, reasoningGranted, blockedSites, note.
/// `focusScore` is empty when no frames were classified; `note` is empty when nil.
/// `blockedSites` lists domains separated by `|` (pipe), quoted when non-empty.
/// Empty input returns only the header row (no trailing newline).
internal func sessionRecordsToCSV(_ records: [SessionRecord]) -> String {
    let iso = ISO8601DateFormatter()
    let header = "id,task,successCriteria,startTime,endTime,durationSeconds,completedSuccessfully,calloutCount,onTaskChecks,totalChecks,focusScore,reasoningAttempts,reasoningGranted,blockedSites,blockedApps,note"
    let rows = records.map { r -> String in
        let cols: [String] = [
            r.id.uuidString,
            csvEscape(r.task),
            csvEscape(r.successCriteria),
            iso.string(from: r.startTime),
            iso.string(from: r.endTime),
            String(Int(r.duration)),
            r.completedSuccessfully ? "true" : "false",
            String(r.calloutCount),
            String(r.onTaskChecks),
            String(r.totalChecks),
            r.focusScore.map { String(format: "%.3f", $0) } ?? "",
            String(r.reasoningAttempts),
            String(r.reasoningGranted),
            r.blockedDomains.isEmpty ? "" : csvEscape(r.blockedDomains.joined(separator: "|")),
            r.blockedApps.isEmpty ? "" : csvEscape(r.blockedApps.joined(separator: "|")),
            r.note.map { csvEscape($0) } ?? ""
        ]
        return cols.joined(separator: ",")
    }
    return ([header] + rows).joined(separator: "\n")
}

// MARK: - JSON export

/// Returns `records` as a pretty-printed UTF-8 JSON string.
/// Dates are ISO 8601 (fractional seconds). Empty input returns `"[]"`.
internal func sessionRecordsToJSON(_ records: [SessionRecord]) -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    encoder.dateEncodingStrategy = .iso8601
    guard let data = try? encoder.encode(records),
          let text = String(data: data, encoding: .utf8) else { return "[]" }
    return text
}

// MARK: - SessionHistory

public actor SessionHistory {
    public static let shared = SessionHistory()

    internal static let maxRecords = 50

    private let fileURL: URL

    // Production init: writes to ~/Library/Application Support/Adia/history.json
    private init() {
        // Force unwrap is safe: `.userDomainMask` always resolves to exactly one
        // directory (~/Library/Application Support) on macOS — `urls(for:in:)`
        // never returns an empty array for this combination.
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let dir = support.appendingPathComponent("Adia", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("history.json")
    }

    // Test init: caller supplies an arbitrary path so production data is never touched.
    internal init(fileURL: URL) {
        self.fileURL = fileURL
    }

    // MARK: - Public API

    /// Prepend a new record and trim to maxRecords. Newest entry is always first.
    public func record(_ entry: SessionRecord) {
        var records = _load()
        records.insert(entry, at: 0)
        if records.count > Self.maxRecords {
            records = Array(records.prefix(Self.maxRecords))
        }
        _save(records)
    }

    /// Returns all records, newest first.
    public func load() -> [SessionRecord] { _load() }

    /// Updates the note field for the record with the given id. No-op if not found.
    /// Passing an empty or whitespace-only string clears the note (stores nil).
    public func updateNote(id: UUID, note: String) {
        var records = _load()
        guard let idx = records.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = note.trimmingCharacters(in: .whitespaces)
        records[idx].note = trimmed.isEmpty ? nil : trimmed
        _save(records)
    }

    /// Removes a single record by id. No-op if not found.
    public func delete(id: UUID) {
        var records = _load()
        records.removeAll { $0.id == id }
        _save(records)
    }

    /// Removes all records whose id is contained in `ids`. No-op for unknown ids or empty set.
    public func deleteMultiple(ids: Set<UUID>) {
        guard !ids.isEmpty else { return }
        var records = _load()
        records.removeAll { ids.contains($0.id) }
        _save(records)
    }

    /// Deletes the history file.
    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// Returns all history records as RFC 4180 CSV (header row included).
    /// Suitable for export via NSSavePanel or share sheet.
    public func exportCSV() -> String {
        sessionRecordsToCSV(_load())
    }

    /// Returns all history records as a pretty-printed JSON string.
    /// Suitable for export via NSSavePanel or share sheet.
    public func exportJSON() -> String {
        sessionRecordsToJSON(_load())
    }

    /// Returns the last 7 calendar days of activity as a heatmap dataset.
    public func weeklyHeatmap() -> [DayActivity] {
        weeklyHeatmapData(_load())
    }

    /// Computes focus pattern insights from the full session history.
    public func insights() -> FocusInsights {
        computeFocusInsights(from: _load())
    }

    /// Computes a stats snapshot from the current history.
    public func stats() -> SessionStats {
        let records = _load()
        guard !records.isEmpty else {
            return SessionStats(todayCount: 0, todayMinutes: 0, weekCount: 0, weekMinutes: 0, streak: 0,
                                allTimeCount: 0, allTimeMinutes: 0, bestStreak: 0)
        }
        let cal = Calendar.current
        let now = Date()

        let todayRecords = records.filter { cal.isDate($0.startTime, inSameDayAs: now) }
        let todayMinutes = Int(todayRecords.reduce(0.0) { $0 + $1.duration } / 60)

        let weekRecords = records.filter { cal.isDate($0.startTime, equalTo: now, toGranularity: .weekOfYear) }
        let weekMinutes = Int(weekRecords.reduce(0.0) { $0 + $1.duration } / 60)

        // Build the set of calendar days that contain at least one session.
        let daySet = Set(records.map { cal.startOfDay(for: $0.startTime) })
        let today = cal.startOfDay(for: now)

        // Walk backward from the most recent session day that includes today or yesterday.
        let startDay: Date
        if daySet.contains(today) {
            startDay = today
        } else if let yesterday = cal.date(byAdding: .day, value: -1, to: today),
                  daySet.contains(yesterday) {
            startDay = yesterday
        } else {
            let allTimeMins = Int(records.reduce(0.0) { $0 + $1.duration } / 60)
            let best = computeBestStreak(from: records, calendar: cal)
            return SessionStats(todayCount: todayRecords.count, todayMinutes: todayMinutes,
                                weekCount: weekRecords.count, weekMinutes: weekMinutes, streak: 0,
                                allTimeCount: records.count, allTimeMinutes: allTimeMins,
                                bestStreak: best)
        }

        var streak = 0
        var day = startDay
        while daySet.contains(day) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }

        let allTimeMins = Int(records.reduce(0.0) { $0 + $1.duration } / 60)
        let best = computeBestStreak(from: records, calendar: cal)
        return SessionStats(todayCount: todayRecords.count, todayMinutes: todayMinutes,
                            weekCount: weekRecords.count, weekMinutes: weekMinutes, streak: streak,
                            allTimeCount: records.count, allTimeMinutes: allTimeMins,
                            bestStreak: best)
    }

    // MARK: - Private helpers

    private func _load() -> [SessionRecord] {
        guard let data = try? Data(contentsOf: fileURL),
              let records = try? JSONDecoder().decode([SessionRecord].self, from: data)
        else { return [] }
        return records
    }

    private func _save(_ records: [SessionRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
