import Testing
import Foundation
@testable import AdiCore

@Suite("FocusInsights")
struct FocusInsightsTests {

    // MARK: - Helpers

    private func record(
        startHour: Int = 10,
        weekday: Int? = nil,
        durationMinutes: Int = 30,
        completed: Bool = true,
        onTask: Int = 8,
        total: Int = 10
    ) -> SessionRecord {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!

        var comps = DateComponents()
        comps.year = 2026
        comps.month = 6
        if let wd = weekday {
            comps.weekday = wd
            comps.weekOfYear = 25
        } else {
            comps.day = 15
        }
        comps.hour = startHour
        comps.minute = 0
        let start = cal.date(from: comps) ?? Date()
        let end = start.addingTimeInterval(Double(durationMinutes) * 60)
        return SessionRecord(
            task: "Study",
            successCriteria: "Done",
            startTime: start,
            endTime: end,
            completedSuccessfully: completed,
            calloutCount: 0,
            onTaskChecks: onTask,
            totalChecks: total
        )
    }

    private var utcCalendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        return cal
    }

    // MARK: - Empty input

    @Test func emptyRecordsReturnsNilInsights() {
        let result = computeFocusInsights(from: [], calendar: utcCalendar)
        #expect(result.sessionCount == 0)
        #expect(result.avgSessionMinutes == nil)
        #expect(result.completionRate == nil)
        #expect(result.avgFocusScore == nil)
        #expect(result.bestHour == nil)
        #expect(result.bestWeekday == nil)
        #expect(result.trend == .insufficient)
    }

    // MARK: - Average session duration

    @Test func avgSessionMinutesComputedCorrectly() {
        let records = [
            record(durationMinutes: 60),
            record(durationMinutes: 30),
            record(durationMinutes: 90),
        ]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.avgSessionMinutes == 60)
    }

    @Test func avgSessionMinutesSingleSession() {
        let records = [record(durationMinutes: 45)]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.avgSessionMinutes == 45)
    }

    // MARK: - Completion rate

    @Test func completionRateAllCompleted() {
        let records = [
            record(completed: true),
            record(completed: true),
            record(completed: true),
        ]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.completionRate == 1.0)
    }

    @Test func completionRateNoneCompleted() {
        let records = [
            record(completed: false),
            record(completed: false),
        ]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.completionRate == 0.0)
    }

    @Test func completionRateMixed() {
        let records = [
            record(completed: true),
            record(completed: false),
            record(completed: true),
            record(completed: false),
        ]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.completionRate == 0.5)
    }

    // MARK: - Average focus score

    @Test func avgFocusScoreComputedFromScoredSessions() {
        let records = [
            record(onTask: 8, total: 10),  // 0.8
            record(onTask: 6, total: 10),  // 0.6
        ]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.avgFocusScore != nil)
        #expect(abs(result.avgFocusScore! - 0.7) < 0.001)
    }

    @Test func avgFocusScoreNilWhenNoScoredSessions() {
        let records = [
            record(onTask: 0, total: 0),
            record(onTask: 0, total: 0),
        ]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.avgFocusScore == nil)
    }

    @Test func avgFocusScoreIgnoresUnscoredSessions() {
        let records = [
            record(onTask: 9, total: 10),  // 0.9
            record(onTask: 0, total: 0),   // nil — excluded
            record(onTask: 7, total: 10),  // 0.7
        ]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.avgFocusScore != nil)
        #expect(abs(result.avgFocusScore! - 0.8) < 0.001)
    }

    // MARK: - Best hour

    @Test func bestHourRequiresMinimumScoredSessions() {
        // Only 3 scored sessions — below the 4-session threshold
        let records = [
            record(startHour: 10, onTask: 9, total: 10),
            record(startHour: 10, onTask: 8, total: 10),
            record(startHour: 14, onTask: 5, total: 10),
        ]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.bestHour == nil)
    }

    @Test func bestHourPicksHighestAvgFocusScore() {
        let records = [
            record(startHour: 9, onTask: 9, total: 10),
            record(startHour: 9, onTask: 8, total: 10),
            record(startHour: 14, onTask: 5, total: 10),
            record(startHour: 14, onTask: 4, total: 10),
        ]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.bestHour == 9)
    }

    @Test func bestHourRequiresAtLeastTwoSessionsPerHour() {
        // Hour 9 has 1 session with perfect score, but needs 2 to qualify.
        // Hour 14 has 2 sessions.
        let records = [
            record(startHour: 9, onTask: 10, total: 10),
            record(startHour: 14, onTask: 6, total: 10),
            record(startHour: 14, onTask: 7, total: 10),
            record(startHour: 14, onTask: 5, total: 10),
        ]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.bestHour == 14)
    }

    // MARK: - Best weekday

    @Test func bestWeekdayRequiresMinSessions() {
        let records = [
            record(weekday: 2, durationMinutes: 120),
            record(weekday: 3, durationMinutes: 30),
        ]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.bestWeekday == nil)
    }

    @Test func bestWeekdayPicksMostFocusedMinutes() {
        let records = [
            record(weekday: 2, durationMinutes: 120), // Monday
            record(weekday: 2, durationMinutes: 60),   // Monday = 180m
            record(weekday: 4, durationMinutes: 90),   // Wednesday = 90m
            record(weekday: 6, durationMinutes: 30),   // Friday = 30m
        ]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.bestWeekday == 2) // Monday
    }

    // MARK: - Trend

    @Test func trendInsufficientWithFewScoredSessions() {
        let records = [
            record(onTask: 8, total: 10),
            record(onTask: 7, total: 10),
        ]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.trend == .insufficient)
    }

    @Test func trendImprovingWhenNewerSessionsBetter() {
        var cal = utcCalendar
        let base = cal.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 10))!
        let records = (0..<6).map { i -> SessionRecord in
            let start = base.addingTimeInterval(Double(i) * 86400)
            let end = start.addingTimeInterval(1800)
            let onTask = i < 3 ? 5 : 9
            return SessionRecord(
                task: "Study", successCriteria: "Done",
                startTime: start, endTime: end,
                completedSuccessfully: true, calloutCount: 0,
                onTaskChecks: onTask, totalChecks: 10
            )
        }
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.trend == .improving)
    }

    @Test func trendDecliningWhenNewerSessionsWorse() {
        let base = utcCalendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 10))!
        let records = (0..<6).map { i -> SessionRecord in
            let start = base.addingTimeInterval(Double(i) * 86400)
            let end = start.addingTimeInterval(1800)
            let onTask = i < 3 ? 9 : 4
            return SessionRecord(
                task: "Study", successCriteria: "Done",
                startTime: start, endTime: end,
                completedSuccessfully: true, calloutCount: 0,
                onTaskChecks: onTask, totalChecks: 10
            )
        }
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.trend == .declining)
    }

    @Test func trendSteadyWhenScoresFlat() {
        let base = utcCalendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 10))!
        let records = (0..<6).map { i -> SessionRecord in
            let start = base.addingTimeInterval(Double(i) * 86400)
            let end = start.addingTimeInterval(1800)
            return SessionRecord(
                task: "Study", successCriteria: "Done",
                startTime: start, endTime: end,
                completedSuccessfully: true, calloutCount: 0,
                onTaskChecks: 7, totalChecks: 10
            )
        }
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.trend == .steady)
    }

    @Test func trendIgnoresUnscoredSessions() {
        let base = utcCalendar.date(from: DateComponents(year: 2026, month: 6, day: 1, hour: 10))!
        var records: [SessionRecord] = (0..<4).map { i in
            let start = base.addingTimeInterval(Double(i) * 86400)
            let end = start.addingTimeInterval(1800)
            return SessionRecord(
                task: "Study", successCriteria: "Done",
                startTime: start, endTime: end,
                completedSuccessfully: true, calloutCount: 0,
                onTaskChecks: 7, totalChecks: 10
            )
        }
        // Add an unscored session (totalChecks=0) — should not affect trend calc
        let unscoredStart = base.addingTimeInterval(5 * 86400)
        records.append(SessionRecord(
            task: "Study", successCriteria: "Done",
            startTime: unscoredStart, endTime: unscoredStart.addingTimeInterval(600),
            completedSuccessfully: false, calloutCount: 0,
            onTaskChecks: 0, totalChecks: 0
        ))
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.trend == .steady)
    }

    // MARK: - Session count

    @Test func sessionCountMatchesInput() {
        let records = [record(), record(), record(), record(), record()]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.sessionCount == 5)
    }

    // MARK: - Display helpers

    @Test func formatHourRangeMorning() {
        #expect(formatHourRange(9) == "9 AM – 10 AM")
    }

    @Test func formatHourRangeNoon() {
        #expect(formatHourRange(12) == "12 PM – 1 PM")
    }

    @Test func formatHourRangeAfternoon() {
        #expect(formatHourRange(14) == "2 PM – 3 PM")
    }

    @Test func formatHourRangeMidnight() {
        #expect(formatHourRange(0) == "12 AM – 1 AM")
    }

    @Test func formatHourRangeElevenPM() {
        #expect(formatHourRange(23) == "11 PM – 12 AM")
    }

    @Test func formatHourRangeElevenAM() {
        #expect(formatHourRange(11) == "11 AM – 12 PM")
    }

    @Test func formatWeekdaySunday() {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US")
        #expect(formatWeekday(1, calendar: cal) == "Sunday")
    }

    @Test func formatWeekdaySaturday() {
        var cal = Calendar(identifier: .gregorian)
        cal.locale = Locale(identifier: "en_US")
        #expect(formatWeekday(7, calendar: cal) == "Saturday")
    }

    @Test func formatWeekdayOutOfRangeReturnsUnknown() {
        #expect(formatWeekday(0) == "Unknown")
        #expect(formatWeekday(8) == "Unknown")
    }

    @Test func trendLabelValues() {
        let (sym, text) = trendLabel(.improving)
        #expect(sym == "arrow.up.right")
        #expect(text == "Improving")

        let (sym2, text2) = trendLabel(.declining)
        #expect(sym2 == "arrow.down.right")
        #expect(text2 == "Declining")

        let (sym3, text3) = trendLabel(.steady)
        #expect(sym3 == "arrow.right")
        #expect(text3 == "Steady")

        let (sym4, text4) = trendLabel(.insufficient)
        #expect(sym4 == "questionmark")
        #expect(text4 == "Not enough data")
    }

    // MARK: - Edge cases

    @Test func allSessionsZeroDuration() {
        let records = [
            record(durationMinutes: 0),
            record(durationMinutes: 0),
            record(durationMinutes: 0),
        ]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.avgSessionMinutes == 0)
    }

    @Test func perfectFocusScore() {
        let records = [
            record(onTask: 10, total: 10),
            record(onTask: 10, total: 10),
        ]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.avgFocusScore == 1.0)
    }

    @Test func zeroFocusScore() {
        let records = [
            record(onTask: 0, total: 10),
            record(onTask: 0, total: 10),
        ]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.avgFocusScore == 0.0)
    }

    // MARK: - Capture reliability

    @Test func captureReliabilityRateNilWhenNoSessions() {
        let result = computeFocusInsights(from: [], calendar: utcCalendar)
        #expect(result.captureReliabilityRate == nil)
    }

    @Test func captureReliabilityRatePerfectWhenNoFailures() {
        let records = [record(), record(), record()]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.captureReliabilityRate == 1.0)
    }

    @Test func captureReliabilityRateReflectsStreamFailures() {
        let ok = record()
        let failed = SessionRecord(
            task: "Study", successCriteria: "Done",
            startTime: Date(timeIntervalSinceNow: -3600), endTime: Date(),
            completedSuccessfully: true, calloutCount: 0,
            streamFailureCount: 2
        )
        let records = [ok, ok, failed]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(abs((result.captureReliabilityRate ?? 0) - (2.0 / 3.0)) < 0.001)
    }

    // MARK: - Average pauses per session

    @Test func avgPausesPerSessionNilWhenNoSessions() {
        let result = computeFocusInsights(from: [], calendar: utcCalendar)
        #expect(result.avgPausesPerSession == nil)
    }

    @Test func avgPausesPerSessionZeroWhenNoPauses() {
        let records = [record(), record()]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.avgPausesPerSession == 0.0)
    }

    @Test func avgPausesPerSessionComputedCorrectly() {
        let noPause = record()
        let paused = SessionRecord(
            task: "Study", successCriteria: "Done",
            startTime: Date(timeIntervalSinceNow: -3600), endTime: Date(),
            completedSuccessfully: true, calloutCount: 0,
            pauseCount: 3
        )
        let records = [noPause, paused]
        let result = computeFocusInsights(from: records, calendar: utcCalendar)
        #expect(result.avgPausesPerSession == 1.5)
    }
}
