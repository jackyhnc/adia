import Testing
@testable import AdiCore

@Suite("HistoryInsightsSection")
struct HistoryInsightsSectionTests {

    // MARK: - streakBreakChipLabel

    @Test("returns nil when totalBreaks is zero")
    func hiddenWhenNoBreaks() {
        #expect(HistoryInsightsSection.streakBreakChipLabel(totalBreaks: 0, mostBroken: nil) == nil)
    }

    @Test("returns nil when totalBreaks is zero even if mostBroken is set")
    func hiddenWhenNoBreaksWithMostBroken() {
        #expect(HistoryInsightsSection.streakBreakChipLabel(totalBreaks: 0, mostBroken: 7) == nil)
    }

    @Test("returns Streak breaks label when totalBreaks > 0 and mostBroken is nil")
    func showsBreakCountWhenNoFragileData() {
        let chip = HistoryInsightsSection.streakBreakChipLabel(totalBreaks: 3, mostBroken: nil)
        #expect(chip != nil)
        #expect(chip?.label == "Streak breaks")
        #expect(chip?.value == "3")
    }

    @Test("break count value reflects totalBreaks argument")
    func breakCountValueMatchesArgument() {
        let chip = HistoryInsightsSection.streakBreakChipLabel(totalBreaks: 12, mostBroken: nil)
        #expect(chip?.value == "12")
    }

    @Test("returns Fragile streak label when totalBreaks > 0 and mostBroken is set")
    func showsFragileStreakWhenMostBrokenKnown() {
        let chip = HistoryInsightsSection.streakBreakChipLabel(totalBreaks: 2, mostBroken: 5)
        #expect(chip != nil)
        #expect(chip?.label == "Fragile streak")
    }

    @Test("fragile streak value includes day suffix from mostBroken")
    func fragileStreakValueHasDaySuffix() {
        let chip = HistoryInsightsSection.streakBreakChipLabel(totalBreaks: 1, mostBroken: 14)
        #expect(chip?.value == "14d")
    }

    @Test("fragile streak value uses mostBroken not totalBreaks")
    func fragileStreakValueUsesMostBroken() {
        let chip = HistoryInsightsSection.streakBreakChipLabel(totalBreaks: 99, mostBroken: 3)
        #expect(chip?.value == "3d")
        #expect(chip?.label == "Fragile streak")
    }

    @Test("single break with mostBroken=1 shows 1d")
    func singleBreakSingleDayStreak() {
        let chip = HistoryInsightsSection.streakBreakChipLabel(totalBreaks: 1, mostBroken: 1)
        #expect(chip?.value == "1d")
    }
}
