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
}

// MARK: - SessionHistory

public actor SessionHistory {
    public static let shared = SessionHistory()

    internal static let maxRecords = 50

    private let fileURL: URL

    // Production init: writes to ~/Library/Application Support/Adia/history.json
    private init() {
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

    /// Deletes the history file.
    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    /// Computes a stats snapshot from the current history.
    public func stats() -> SessionStats {
        let records = _load()
        guard !records.isEmpty else {
            return SessionStats(todayCount: 0, todayMinutes: 0, weekCount: 0, weekMinutes: 0, streak: 0)
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
            return SessionStats(todayCount: todayRecords.count, todayMinutes: todayMinutes,
                                weekCount: weekRecords.count, weekMinutes: weekMinutes, streak: 0)
        }

        var streak = 0
        var day = startDay
        while daySet.contains(day) {
            streak += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }

        return SessionStats(todayCount: todayRecords.count, todayMinutes: todayMinutes,
                            weekCount: weekRecords.count, weekMinutes: weekMinutes, streak: streak)
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
