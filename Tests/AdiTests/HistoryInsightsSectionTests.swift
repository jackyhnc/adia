import Testing
import Foundation
@testable import AdiCore

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
