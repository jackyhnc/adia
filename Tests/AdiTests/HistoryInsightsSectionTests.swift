import Testing
import Foundation
@testable import AdiCore

// MARK: - Fixture helpers

private func makeWeekStats(weekCount: Int, weekMinutes: Int) -> SessionStats {
    SessionStats(todayCount: 0, todayMinutes: 0,
                 weekCount: weekCount, weekMinutes: weekMinutes,
                 streak: 0)
}

// MARK: - HistoryWeeklySection.weekSummaryText

@Suite("HistoryWeeklySection.weekSummaryText")
struct HistoryWeeklySectionTests {

    @Test("zero minutes shows session count only")
    func zeroMinutesShowsCountOnly() {
        let s = makeWeekStats(weekCount: 3, weekMinutes: 0)
        #expect(HistoryWeeklySection.weekSummaryText(s) == "3 sessions this week")
    }

    @Test("singular session label when weekCount is 1")
    func singularSessionLabel() {
        let s = makeWeekStats(weekCount: 1, weekMinutes: 0)
        #expect(HistoryWeeklySection.weekSummaryText(s) == "1 session this week")
    }

    @Test("minutes-only duration (no hours)")
    func minutesOnly() {
        let s = makeWeekStats(weekCount: 2, weekMinutes: 45)
        #expect(HistoryWeeklySection.weekSummaryText(s) == "2 sessions this week · 45m")
    }

    @Test("hours-only duration (exact hour, zero leftover minutes)")
    func hoursOnly() {
        let s = makeWeekStats(weekCount: 4, weekMinutes: 120)
        #expect(HistoryWeeklySection.weekSummaryText(s) == "4 sessions this week · 2h")
    }

    @Test("hours and minutes combined duration")
    func hoursAndMinutes() {
        let s = makeWeekStats(weekCount: 5, weekMinutes: 90)
        #expect(HistoryWeeklySection.weekSummaryText(s) == "5 sessions this week · 1h 30m")
    }

    @Test("exactly 1 minute")
    func oneMinute() {
        let s = makeWeekStats(weekCount: 1, weekMinutes: 1)
        #expect(HistoryWeeklySection.weekSummaryText(s) == "1 session this week · 1m")
    }

    @Test("large duration (10h 5m)")
    func largeDuration() {
        let s = makeWeekStats(weekCount: 10, weekMinutes: 605)
        #expect(HistoryWeeklySection.weekSummaryText(s) == "10 sessions this week · 10h 5m")
    }
}

// MARK: - HistoryInsightsSection.streakBreakChipLabel

@Suite("HistoryInsightsSection.streakBreakChipLabel")
struct HistoryInsightsSectionTests {

    // MARK: - Hidden when no breaks

    @Test("returns nil when totalBreaks is 0")
    func hiddenWhenNoBreaks() {
        let result = HistoryInsightsSection.streakBreakChipLabel(totalBreaks: 0, mostBroken: nil)
        #expect(result == nil)
    }

    @Test("returns nil when totalBreaks is 0 even with a mostBroken value")
    func hiddenWhenNoBreaksIgnoresMostBroken() {
        let result = HistoryInsightsSection.streakBreakChipLabel(totalBreaks: 0, mostBroken: 7)
        #expect(result == nil)
    }

    // MARK: - Count label (no fragile streak length)

    @Test("shows Streak breaks label with count when mostBroken is nil")
    func showsBreakCountLabel() {
        let result = HistoryInsightsSection.streakBreakChipLabel(totalBreaks: 3, mostBroken: nil)
        #expect(result?.label == "Streak breaks")
        #expect(result?.value == "3")
    }

    @Test("count value matches totalBreaks exactly")
    func breakCountValueMatchesTotalBreaks() {
        for count in [1, 5, 12] {
            let result = HistoryInsightsSection.streakBreakChipLabel(totalBreaks: count, mostBroken: nil)
            #expect(result?.value == "\(count)")
        }
    }

    // MARK: - Fragile streak label (mostBroken present)

    @Test("shows Fragile streak label with Nd suffix when mostBroken is set")
    func showsFragileStreakLabel() {
        let result = HistoryInsightsSection.streakBreakChipLabel(totalBreaks: 2, mostBroken: 14)
        #expect(result?.label == "Fragile streak")
        #expect(result?.value == "14d")
    }

    @Test("fragile value uses mostBroken length in days suffix")
    func fragileValueUsesMostBrokenLength() {
        for days in [1, 7, 30] {
            let result = HistoryInsightsSection.streakBreakChipLabel(totalBreaks: 1, mostBroken: days)
            #expect(result?.value == "\(days)d")
        }
    }

    @Test("fragile label takes precedence over break count even when totalBreaks is 1")
    func fragilePreferredOverCountForSingleBreak() {
        let result = HistoryInsightsSection.streakBreakChipLabel(totalBreaks: 1, mostBroken: 5)
        #expect(result?.label == "Fragile streak")
    }
}
