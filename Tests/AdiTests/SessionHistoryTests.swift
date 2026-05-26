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
}
