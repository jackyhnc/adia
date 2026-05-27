import Testing
import Foundation
@testable import AdiCore

@Suite("SessionHistory")
struct SessionHistoryTests {

    // Each test gets a fresh temp file so tests don't share state.
    private func makeHistory() throws -> SessionHistory {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("AdiTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("history.json")
        return SessionHistory(fileURL: url)
    }

    private func makeRecord(
        task: String = "Study",
        completedSuccessfully: Bool = true,
        calloutCount: Int = 0,
        startOffset: TimeInterval = -3600
    ) -> SessionRecord {
        SessionRecord(
            task: task,
            successCriteria: "Done",
            startTime: Date(timeIntervalSinceNow: startOffset),
            endTime: Date(),
            completedSuccessfully: completedSuccessfully,
            calloutCount: calloutCount
        )
    }

    // MARK: - load() on empty file

    @Test func loadFromMissingFileReturnsEmpty() async throws {
        let history = try makeHistory()
        let records = await history.load()
        #expect(records.isEmpty)
    }

    // MARK: - record() and load()

    @Test func recordAndLoadRoundTrip() async throws {
        let history = try makeHistory()
        let r = makeRecord(task: "Write essay")
        await history.record(r)
        let loaded = await history.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].task == "Write essay")
        #expect(loaded[0].completedSuccessfully == true)
    }

    @Test func recordPrependsNewestFirst() async throws {
        let history = try makeHistory()
        let first  = makeRecord(task: "First")
        let second = makeRecord(task: "Second")
        await history.record(first)
        await history.record(second)
        let loaded = await history.load()
        #expect(loaded.count == 2)
        // Most recently recorded should be at index 0
        #expect(loaded[0].task == "Second")
        #expect(loaded[1].task == "First")
    }

    @Test func recordPreservesAllFields() async throws {
        let history = try makeHistory()
        let start = Date(timeIntervalSinceNow: -5400)
        let end   = Date()
        let r = SessionRecord(
            task: "Read textbook",
            successCriteria: "Finish chapter 3",
            startTime: start,
            endTime: end,
            completedSuccessfully: false,
            calloutCount: 3
        )
        await history.record(r)
        let loaded = await history.load()
        let entry = loaded[0]
        #expect(entry.task == "Read textbook")
        #expect(entry.successCriteria == "Finish chapter 3")
        #expect(abs(entry.startTime.timeIntervalSince(start)) < 0.001)
        #expect(abs(entry.endTime.timeIntervalSince(end)) < 0.001)
        #expect(entry.completedSuccessfully == false)
        #expect(entry.calloutCount == 3)
    }

    // MARK: - Cap at maxRecords

    @Test func capsAtMaxRecords() async throws {
        let history = try makeHistory()
        let limit = SessionHistory.maxRecords
        for i in 0..<(limit + 10) {
            await history.record(makeRecord(task: "Session \(i)"))
        }
        let loaded = await history.load()
        #expect(loaded.count == limit)
    }

    @Test func capKeepsNewest() async throws {
        let history = try makeHistory()
        let limit = SessionHistory.maxRecords
        for i in 0..<(limit + 5) {
            await history.record(makeRecord(task: "Session \(i)"))
        }
        let loaded = await history.load()
        // After overflow, index 0 should be the last-inserted (highest i)
        #expect(loaded[0].task == "Session \(limit + 4)")
    }

    // MARK: - clear()

    @Test func clearEmptiesHistory() async throws {
        let history = try makeHistory()
        await history.record(makeRecord())
        await history.clear()
        let loaded = await history.load()
        #expect(loaded.isEmpty)
    }

    // MARK: - duration computed property

    @Test func durationIsPositive() {
        let r = makeRecord(startOffset: -3600)
        #expect(r.duration >= 3599)
    }

    // MARK: - Multiple records accumulate

    @Test func multipleRecordsAccumulate() async throws {
        let history = try makeHistory()
        await history.record(makeRecord(task: "A"))
        await history.record(makeRecord(task: "B"))
        await history.record(makeRecord(task: "C"))
        let loaded = await history.load()
        #expect(loaded.count == 3)
    }

    // MARK: - stats()

    @Test func statsEmptyHistoryReturnsZeros() async throws {
        let history = try makeHistory()
        let s = await history.stats()
        #expect(s.todayCount == 0)
        #expect(s.todayMinutes == 0)
        #expect(s.streak == 0)
    }

    @Test func statsTodayCountAndMinutes() async throws {
        let history = try makeHistory()
        // 30-minute session that ended just now, started 30 min ago
        let r = SessionRecord(
            task: "Study",
            successCriteria: "Done",
            startTime: Date(timeIntervalSinceNow: -1800),
            endTime: Date(),
            completedSuccessfully: true,
            calloutCount: 0
        )
        await history.record(r)
        let s = await history.stats()
        #expect(s.todayCount == 1)
        #expect(s.todayMinutes == 30)
    }

    @Test func statsIgnoresOldSessions() async throws {
        let history = try makeHistory()
        // Session from 3 days ago
        let old = SessionRecord(
            task: "Old",
            successCriteria: "Done",
            startTime: Date(timeIntervalSinceNow: -3 * 86400),
            endTime: Date(timeIntervalSinceNow: -3 * 86400 + 3600),
            completedSuccessfully: true,
            calloutCount: 0
        )
        await history.record(old)
        let s = await history.stats()
        #expect(s.todayCount == 0)
        #expect(s.todayMinutes == 0)
    }

    @Test func statsStreakSingleDayToday() async throws {
        let history = try makeHistory()
        await history.record(makeRecord(task: "Focus"))
        let s = await history.stats()
        #expect(s.streak == 1)
    }

    @Test func statsStreakTwoDays() async throws {
        let history = try makeHistory()
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        guard let yesterday = cal.date(byAdding: .day, value: -1, to: today),
              let todayNoon = cal.date(bySettingHour: 12, minute: 0, second: 0, of: today),
              let yesterdayNoon = cal.date(bySettingHour: 12, minute: 0, second: 0, of: yesterday)
        else {
            return
        }
        let r1 = SessionRecord(
            task: "Today",
            successCriteria: "Done",
            startTime: todayNoon,
            endTime: Date(timeInterval: 3600, since: todayNoon),
            completedSuccessfully: true,
            calloutCount: 0
        )
        let r2 = SessionRecord(
            task: "Yesterday",
            successCriteria: "Done",
            startTime: yesterdayNoon,
            endTime: Date(timeInterval: 3600, since: yesterdayNoon),
            completedSuccessfully: true,
            calloutCount: 0
        )
        await history.record(r1)
        await history.record(r2)
        let s = await history.stats()
        #expect(s.todayCount == 1)
        #expect(s.streak == 2)
    }

    @Test func statsWeekCountAndMinutes() async throws {
        let history = try makeHistory()
        let cal = Calendar.current
        let now = Date()
        // Session from today (within the week)
        let todayRecord = SessionRecord(
            task: "Today",
            successCriteria: "Done",
            startTime: Date(timeIntervalSinceNow: -3600),
            endTime: now,
            completedSuccessfully: true,
            calloutCount: 0
        )
        // Session from 2 days ago — may or may not be in the same week; use a date that's
        // definitely in the same ISO week (within 6 days from start of week).
        guard let twoDaysAgo = cal.date(byAdding: .day, value: -2, to: now) else { return }
        let twoDaysAgoRecord = SessionRecord(
            task: "Two days ago",
            successCriteria: "Done",
            startTime: Date(timeInterval: -3600, since: twoDaysAgo),
            endTime: twoDaysAgo,
            completedSuccessfully: true,
            calloutCount: 0
        )
        let thisWeek = cal.isDate(twoDaysAgo, equalTo: now, toGranularity: .weekOfYear)
        await history.record(todayRecord)
        await history.record(twoDaysAgoRecord)
        let s = await history.stats()
        #expect(s.weekCount == (thisWeek ? 2 : 1))
        #expect(s.weekMinutes >= 60)  // at least the 60-minute today session
    }

    @Test func statsWeekIgnoresSessionsFromLastWeek() async throws {
        let history = try makeHistory()
        // Session from 10 days ago — guaranteed to be in a prior week
        let old = SessionRecord(
            task: "Old",
            successCriteria: "Done",
            startTime: Date(timeIntervalSinceNow: -10 * 86400 - 3600),
            endTime: Date(timeIntervalSinceNow: -10 * 86400),
            completedSuccessfully: true,
            calloutCount: 0
        )
        await history.record(old)
        let s = await history.stats()
        #expect(s.weekCount == 0)
        #expect(s.weekMinutes == 0)
    }

    @Test func statsStreakBrokenByGap() async throws {
        let history = try makeHistory()
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // Session today and 3 days ago (gap in between) → streak = 1 (today only)
        guard let threeDaysAgo = cal.date(byAdding: .day, value: -3, to: today),
              let todayNoon = cal.date(bySettingHour: 12, minute: 0, second: 0, of: today),
              let oldNoon = cal.date(bySettingHour: 12, minute: 0, second: 0, of: threeDaysAgo)
        else {
            return
        }
        await history.record(SessionRecord(
            task: "Today",
            successCriteria: "Done",
            startTime: todayNoon,
            endTime: Date(timeInterval: 1800, since: todayNoon),
            completedSuccessfully: true,
            calloutCount: 0
        ))
        await history.record(SessionRecord(
            task: "3 days ago",
            successCriteria: "Done",
            startTime: oldNoon,
            endTime: Date(timeInterval: 1800, since: oldNoon),
            completedSuccessfully: true,
            calloutCount: 0
        ))
        let s = await history.stats()
        #expect(s.streak == 1)  // gap breaks the streak
    }
}

// MARK: - idleStatsSummary formatting tests

@Suite("IdleStatsSummary")
struct IdleStatsSummaryTests {

    private func stats(todayCount: Int = 0, todayMinutes: Int = 0,
                       weekCount: Int = 0, weekMinutes: Int = 0,
                       streak: Int = 0) -> SessionStats {
        SessionStats(todayCount: todayCount, todayMinutes: todayMinutes,
                     weekCount: weekCount, weekMinutes: weekMinutes,
                     streak: streak)
    }

    @Test func todayCountNoTime() {
        let s = stats(todayCount: 1)
        #expect(idleStatsSummary(s) == "1 session")
    }

    @Test func todayCountPluralNoTime() {
        let s = stats(todayCount: 3)
        #expect(idleStatsSummary(s) == "3 sessions")
    }

    @Test func todayCountWithMinutes() {
        let s = stats(todayCount: 2, todayMinutes: 45)
        #expect(idleStatsSummary(s) == "2 sessions · 45m")
    }

    @Test func todayCountWithHoursAndMinutes() {
        let s = stats(todayCount: 1, todayMinutes: 90)
        #expect(idleStatsSummary(s) == "1 session · 1h 30m")
    }

    @Test func todayCountWithExactHour() {
        let s = stats(todayCount: 2, todayMinutes: 120)
        #expect(idleStatsSummary(s) == "2 sessions · 2h")
    }

    // When today is zero, fall back to weekly framing.
    @Test func weekFallbackNoTime() {
        let s = stats(weekCount: 4)
        #expect(idleStatsSummary(s) == "4 sessions this week")
    }

    @Test func weekFallbackSingularNoTime() {
        let s = stats(weekCount: 1)
        #expect(idleStatsSummary(s) == "1 session this week")
    }

    @Test func weekFallbackWithMinutes() {
        let s = stats(weekCount: 5, weekMinutes: 200)
        // 200m = 3h 20m
        #expect(idleStatsSummary(s) == "5 sessions this week · 3h 20m")
    }

    @Test func allZeros() {
        let s = stats()
        // Should not normally be displayed (caller guards weekCount > 0 || todayCount > 0),
        // but function should not crash.
        #expect(idleStatsSummary(s) == "0 sessions this week")
    }
}
