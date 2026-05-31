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

    // MARK: - updateNote()

    @Test func updateNoteSetsNote() async throws {
        let history = try makeHistory()
        let r = makeRecord(task: "Study")
        await history.record(r)
        await history.updateNote(id: r.id, note: "Got through chapter 4 in one go.")
        let loaded = await history.load()
        #expect(loaded[0].note == "Got through chapter 4 in one go.")
    }

    @Test func updateNoteTrimsWhitespace() async throws {
        let history = try makeHistory()
        let r = makeRecord()
        await history.record(r)
        await history.updateNote(id: r.id, note: "  good session  ")
        let loaded = await history.load()
        #expect(loaded[0].note == "good session")
    }

    @Test func updateNoteWithEmptyStringClearsNote() async throws {
        let history = try makeHistory()
        let r = makeRecord()
        await history.record(r)
        await history.updateNote(id: r.id, note: "initial note")
        await history.updateNote(id: r.id, note: "")
        let loaded = await history.load()
        #expect(loaded[0].note == nil)
    }

    @Test func updateNoteOnMissingIDIsNoop() async throws {
        let history = try makeHistory()
        let r = makeRecord(task: "Real")
        await history.record(r)
        await history.updateNote(id: UUID(), note: "ghost note")
        let loaded = await history.load()
        #expect(loaded[0].note == nil)
        #expect(loaded.count == 1)
    }

    @Test func updateNotePreservesOtherRecords() async throws {
        let history = try makeHistory()
        let a = makeRecord(task: "A")
        let b = makeRecord(task: "B")
        await history.record(a)
        await history.record(b)
        await history.updateNote(id: a.id, note: "Note for A")
        let loaded = await history.load()
        // Newest-first order: b is index 0, a is index 1
        let noteA = loaded.first(where: { $0.id == a.id })?.note
        let noteB = loaded.first(where: { $0.id == b.id })?.note
        #expect(noteA == "Note for A")
        #expect(noteB == nil)
    }

    // MARK: - delete()

    @Test func deleteRemovesSingleRecord() async throws {
        let history = try makeHistory()
        let a = makeRecord(task: "A")
        let b = makeRecord(task: "B")
        await history.record(a)
        await history.record(b)
        await history.delete(id: a.id)
        let loaded = await history.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].id == b.id)
    }

    @Test func deleteOnMissingIDIsNoop() async throws {
        let history = try makeHistory()
        await history.record(makeRecord(task: "Keep"))
        await history.delete(id: UUID())
        let loaded = await history.load()
        #expect(loaded.count == 1)
    }

    @Test func deleteUpdatesStats() async throws {
        let history = try makeHistory()
        // Two today-sessions; delete one; stats should reflect only one remaining.
        let a = SessionRecord(
            task: "A",
            successCriteria: "Done",
            startTime: Date(timeIntervalSinceNow: -3600),
            endTime: Date(),
            completedSuccessfully: true,
            calloutCount: 0
        )
        let b = SessionRecord(
            task: "B",
            successCriteria: "Done",
            startTime: Date(timeIntervalSinceNow: -1800),
            endTime: Date(),
            completedSuccessfully: true,
            calloutCount: 0
        )
        await history.record(a)
        await history.record(b)
        await history.delete(id: a.id)
        let s = await history.stats()
        #expect(s.todayCount == 1)
        #expect(s.weekCount == 1)
    }

    @Test func deleteLastRecordYieldsZeroStats() async throws {
        let history = try makeHistory()
        let r = makeRecord()
        await history.record(r)
        await history.delete(id: r.id)
        let s = await history.stats()
        #expect(s.todayCount == 0)
        #expect(s.streak == 0)
        let loaded = await history.load()
        #expect(loaded.isEmpty)
    }

    // MARK: - deleteMultiple

    @Test func deleteMultipleRemovesAllSpecified() async throws {
        let history = try makeHistory()
        let a = makeRecord(task: "A")
        let b = makeRecord(task: "B")
        let c = makeRecord(task: "C")
        await history.record(a)
        await history.record(b)
        await history.record(c)
        await history.deleteMultiple(ids: [a.id, c.id])
        let loaded = await history.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].task == "B")
    }

    @Test func deleteMultipleNoOpForUnknownIDs() async throws {
        let history = try makeHistory()
        let r = makeRecord(task: "Keep me")
        await history.record(r)
        await history.deleteMultiple(ids: [UUID(), UUID()])
        let loaded = await history.load()
        #expect(loaded.count == 1)
        #expect(loaded[0].task == "Keep me")
    }

    @Test func deleteMultipleEmptySetIsNoOp() async throws {
        let history = try makeHistory()
        let r = makeRecord(task: "Keep me too")
        await history.record(r)
        await history.deleteMultiple(ids: [])
        let loaded = await history.load()
        #expect(loaded.count == 1)
    }

    // MARK: - note round-trip through Codable

    @Test func noteRoundTripsThroughJSON() async throws {
        let history = try makeHistory()
        let r = SessionRecord(
            task: "Study",
            successCriteria: "Done",
            startTime: Date(timeIntervalSinceNow: -3600),
            endTime: Date(),
            completedSuccessfully: true,
            calloutCount: 0,
            note: "really dialed in today"
        )
        await history.record(r)
        let loaded = await history.load()
        #expect(loaded[0].note == "really dialed in today")
    }

    @Test func nilNoteEncodesAndDecodesAsNil() async throws {
        let history = try makeHistory()
        let r = makeRecord()
        #expect(r.note == nil)
        await history.record(r)
        let loaded = await history.load()
        #expect(loaded[0].note == nil)
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

// MARK: - filterRecords tests

@Suite("filterRecords")
struct FilterRecordsTests {

    private func record(
        task: String = "write essay",
        criteria: String = "submit to Canvas",
        note: String? = nil,
        completed: Bool = true
    ) -> SessionRecord {
        SessionRecord(
            task: task,
            successCriteria: criteria,
            startTime: Date(timeIntervalSinceNow: -3600),
            endTime: Date(),
            completedSuccessfully: completed,
            calloutCount: 0,
            note: note
        )
    }

    @Test func emptyQueryReturnsAll() {
        let records = [record(task: "essay"), record(task: "coding")]
        let result = filterRecords(records, query: "", completed: nil)
        #expect(result.count == 2)
    }

    @Test func whitespaceOnlyQueryReturnsAll() {
        let records = [record(task: "essay"), record(task: "coding")]
        let result = filterRecords(records, query: "   ", completed: nil)
        #expect(result.count == 2)
    }

    @Test func queryMatchesTaskCaseInsensitive() {
        let records = [record(task: "Write Essay"), record(task: "read textbook")]
        let result = filterRecords(records, query: "essay", completed: nil)
        #expect(result.count == 1)
        #expect(result[0].task == "Write Essay")
    }

    @Test func queryMatchesSuccessCriteria() {
        let records = [
            record(task: "biology hw", criteria: "submit to Canvas"),
            record(task: "coding", criteria: "push PR"),
        ]
        let result = filterRecords(records, query: "canvas", completed: nil)
        #expect(result.count == 1)
        #expect(result[0].task == "biology hw")
    }

    @Test func queryMatchesNote() {
        let records = [
            record(task: "research", note: "found great paper"),
            record(task: "coding", note: nil),
        ]
        let result = filterRecords(records, query: "great paper", completed: nil)
        #expect(result.count == 1)
        #expect(result[0].task == "research")
    }

    @Test func queryNoMatchReturnsEmpty() {
        let records = [record(task: "essay"), record(task: "coding")]
        let result = filterRecords(records, query: "quantum physics", completed: nil)
        #expect(result.isEmpty)
    }

    @Test func completedFilterKeepsOnlyCompleted() {
        let records = [
            record(task: "done task", completed: true),
            record(task: "early exit", completed: false),
        ]
        let result = filterRecords(records, query: "", completed: true)
        #expect(result.count == 1)
        #expect(result[0].task == "done task")
    }

    @Test func exitedFilterKeepsOnlyExited() {
        let records = [
            record(task: "done task", completed: true),
            record(task: "gave up", completed: false),
        ]
        let result = filterRecords(records, query: "", completed: false)
        #expect(result.count == 1)
        #expect(result[0].task == "gave up")
    }

    @Test func nilCompletedFilterKeepsAll() {
        let records = [
            record(task: "done", completed: true),
            record(task: "exited", completed: false),
        ]
        let result = filterRecords(records, query: "", completed: nil)
        #expect(result.count == 2)
    }

    @Test func combinedQueryAndCompletionFilter() {
        let records = [
            record(task: "essay", completed: true),
            record(task: "essay draft", completed: false),
            record(task: "coding", completed: true),
        ]
        let result = filterRecords(records, query: "essay", completed: true)
        #expect(result.count == 1)
        #expect(result[0].task == "essay")
    }

    @Test func emptyInputReturnsEmpty() {
        let result = filterRecords([], query: "anything", completed: nil)
        #expect(result.isEmpty)
    }
}

// MARK: - groupedByDay tests

@Suite("groupedByDay")
struct GroupedByDayTests {

    private func record(startOffset: TimeInterval, task: String = "Study") -> SessionRecord {
        SessionRecord(
            task: task,
            successCriteria: "Done",
            startTime: Date(timeIntervalSinceNow: startOffset),
            endTime: Date(timeIntervalSinceNow: startOffset + 3600),
            completedSuccessfully: true,
            calloutCount: 0
        )
    }

    @Test func emptyInputReturnsEmpty() {
        #expect(groupedByDay([]).isEmpty)
    }

    @Test func singleTodayRecordProducesTodayGroup() {
        let r = record(startOffset: -1800)
        let groups = groupedByDay([r])
        #expect(groups.count == 1)
        #expect(groups[0].label == "Today")
        #expect(groups[0].records.count == 1)
    }

    @Test func multipleTodayRecordsCollapsedIntoOneGroup() {
        let r1 = record(startOffset: -600, task: "A")
        let r2 = record(startOffset: -1200, task: "B")
        let r3 = record(startOffset: -1800, task: "C")
        let groups = groupedByDay([r1, r2, r3])
        #expect(groups.count == 1)
        #expect(groups[0].label == "Today")
        #expect(groups[0].records.count == 3)
    }

    @Test func recordOrderPreservedWithinGroup() {
        let r1 = record(startOffset: -300, task: "First")
        let r2 = record(startOffset: -600, task: "Second")
        let groups = groupedByDay([r1, r2])
        #expect(groups.count == 1)
        #expect(groups[0].records[0].task == "First")
        #expect(groups[0].records[1].task == "Second")
    }

    @Test func todayAndYesterdayFormTwoSections() {
        // 25 hours ago is always "yesterday" in calendar terms.
        let todayRec     = record(startOffset: -600,   task: "Today session")
        let yesterdayRec = record(startOffset: -90000, task: "Yesterday session")
        let groups = groupedByDay([todayRec, yesterdayRec])
        #expect(groups.count == 2)
        #expect(groups[0].label == "Today")
        #expect(groups[1].label == "Yesterday")
        #expect(groups[0].records[0].task == "Today session")
        #expect(groups[1].records[0].task == "Yesterday session")
    }

    @Test func pastYearLabelContainsYear() {
        // ~400 days ago is always in a prior calendar year.
        let offset: TimeInterval = -400 * 86400
        let r = record(startOffset: offset)
        let expectedYear = Calendar.current.component(.year, from: Date(timeIntervalSinceNow: offset))
        let groups = groupedByDay([r])
        #expect(groups.count == 1)
        #expect(groups[0].label.contains("\(expectedYear)"))
    }

    @Test func currentYearLabelOmitsYear() {
        // 30 days ago is almost always in the current calendar year (fails only in
        // the first 30 days of the year, an acceptable edge case).
        let offset: TimeInterval = -30 * 86400
        let now = Date()
        let date = Date(timeIntervalSinceNow: offset)
        let cal = Calendar.current
        guard cal.component(.year, from: date) == cal.component(.year, from: now) else { return }
        let r = record(startOffset: offset)
        let groups = groupedByDay([r])
        #expect(groups.count == 1)
        let label = groups[0].label
        #expect(label != "Today" && label != "Yesterday")
        #expect(!label.contains("\(cal.component(.year, from: now))"))
    }

    @Test func threeDifferentDaysProduceThreeSections() {
        let today     = record(startOffset: -600,    task: "T")
        let yesterday = record(startOffset: -90000,  task: "Y")   // 25h ago
        let twoDays   = record(startOffset: -180000, task: "2D")  // 50h ago
        let groups = groupedByDay([today, yesterday, twoDays])
        #expect(groups.count == 3)
        #expect(groups[0].label == "Today")
        #expect(groups[1].label == "Yesterday")
    }
}

// MARK: - weeklyHeatmapData tests

@Suite("weeklyHeatmapData")
struct WeeklyHeatmapDataTests {

    private func makeRecord(calendarDaysAgo: Int, durationMinutes: Int = 60) -> SessionRecord {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        let dayStart = cal.date(byAdding: .day, value: -calendarDaysAgo, to: today)!
        let noon = cal.date(bySettingHour: 12, minute: 0, second: 0, of: dayStart)!
        return SessionRecord(
            task: "Study",
            successCriteria: "Done",
            startTime: noon,
            endTime: Date(timeInterval: TimeInterval(durationMinutes * 60), since: noon),
            completedSuccessfully: true,
            calloutCount: 0
        )
    }

    @Test func emptyHistoryReturnsSevenZeroDays() {
        let result = weeklyHeatmapData([])
        #expect(result.count == 7)
        #expect(result.allSatisfy { $0.sessionCount == 0 && $0.minutes == 0 })
    }

    @Test func alwaysReturnsSeven() {
        let result = weeklyHeatmapData([makeRecord(calendarDaysAgo: 3)])
        #expect(result.count == 7)
    }

    @Test func todaySessionShowsInLastSlot() {
        let r = makeRecord(calendarDaysAgo: 0, durationMinutes: 45)
        let result = weeklyHeatmapData([r])
        let today = result.last!
        #expect(today.sessionCount == 1)
        #expect(today.minutes == 45)
        // all others empty
        #expect(result.dropLast().allSatisfy { $0.sessionCount == 0 })
    }

    @Test func yesterdaySessionShowsInSecondToLastSlot() {
        let r = makeRecord(calendarDaysAgo: 1, durationMinutes: 30)
        let result = weeklyHeatmapData([r])
        #expect(result[5].sessionCount == 1)
        #expect(result[5].minutes == 30)
        #expect(result[6].sessionCount == 0)
    }

    @Test func sessionSixDaysAgoShowsInFirstSlot() {
        let r = makeRecord(calendarDaysAgo: 6, durationMinutes: 60)
        let result = weeklyHeatmapData([r])
        #expect(result[0].sessionCount == 1)
        #expect(result[0].minutes == 60)
        #expect(result[1...].allSatisfy { $0.sessionCount == 0 })
    }

    @Test func sessionSevenDaysAgoNotIncluded() {
        let r = makeRecord(calendarDaysAgo: 7, durationMinutes: 60)
        let result = weeklyHeatmapData([r])
        #expect(result.allSatisfy { $0.sessionCount == 0 })
    }

    @Test func multipleSessionsSameDayAccumulate() {
        let r1 = makeRecord(calendarDaysAgo: 0, durationMinutes: 30)
        let r2 = makeRecord(calendarDaysAgo: 0, durationMinutes: 45)
        let result = weeklyHeatmapData([r1, r2])
        let today = result.last!
        #expect(today.sessionCount == 2)
        #expect(today.minutes == 75)
    }

    @Test func resultIsOrderedOldestFirst() {
        let result = weeklyHeatmapData([])
        for i in 1..<result.count {
            #expect(result[i].date > result[i - 1].date)
        }
    }

    @Test func datesAreCalendarDayBoundaries() {
        let result = weeklyHeatmapData([])
        let cal = Calendar.current
        for day in result {
            let startOfDay = cal.startOfDay(for: day.date)
            #expect(abs(day.date.timeIntervalSince(startOfDay)) < 1)
        }
    }

    @Test func lastSlotIsToday() {
        let result = weeklyHeatmapData([])
        #expect(Calendar.current.isDateInToday(result.last!.date))
    }

    @Test func firstSlotIsSixDaysAgo() {
        let result = weeklyHeatmapData([])
        let cal = Calendar.current
        let sixDaysAgo = cal.date(byAdding: .day, value: -6, to: cal.startOfDay(for: Date()))!
        #expect(abs(result.first!.date.timeIntervalSince(sixDaysAgo)) < 1)
    }
}
