import Testing
import Foundation
@testable import AdiCore

@Suite("AppLogger")
struct AppLoggerTests {

    @Test func logFileURLIsInsideAdiDirectory() {
        let url = AppLogger.logFileURL
        #expect(url.lastPathComponent == "adia.log")
        #expect(url.deletingLastPathComponent().lastPathComponent == "Adia")
    }

    @Test func infoWritesToLogFile() throws {
        let url = AppLogger.logFileURL
        let dir = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let sizeBefore = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? UInt64) ?? 0

        AppLogger.info("test.info_event", ["key": "value"])

        let sizeAfter = (try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? UInt64) ?? 0
        #expect(sizeAfter > sizeBefore)

        let contents = try String(contentsOf: url, encoding: .utf8)
        let lastLine = contents.components(separatedBy: "\n").filter { !$0.isEmpty }.last ?? ""
        #expect(lastLine.contains("\"level\":\"info\""))
        #expect(lastLine.contains("\"event\":\"test.info_event\""))
        #expect(lastLine.contains("\"key\":\"value\""))
    }

    @Test func warningWritesCorrectLevel() throws {
        AppLogger.warning("test.warning_event")

        let contents = try String(contentsOf: AppLogger.logFileURL, encoding: .utf8)
        let lastLine = contents.components(separatedBy: "\n").filter { !$0.isEmpty }.last ?? ""
        #expect(lastLine.contains("\"level\":\"warning\""))
        #expect(lastLine.contains("\"event\":\"test.warning_event\""))
    }

    @Test func errorWritesCorrectLevel() throws {
        AppLogger.error("test.error_event", ["detail": "something broke"])

        let contents = try String(contentsOf: AppLogger.logFileURL, encoding: .utf8)
        let lastLine = contents.components(separatedBy: "\n").filter { !$0.isEmpty }.last ?? ""
        #expect(lastLine.contains("\"level\":\"error\""))
        #expect(lastLine.contains("\"event\":\"test.error_event\""))
        #expect(lastLine.contains("\"detail\":\"something broke\""))
    }

    @Test func logEntryContainsISO8601Timestamp() throws {
        AppLogger.info("test.timestamp_check")

        let contents = try String(contentsOf: AppLogger.logFileURL, encoding: .utf8)
        let lastLine = contents.components(separatedBy: "\n").filter { !$0.isEmpty }.last ?? ""
        #expect(lastLine.contains("\"timestamp\":\"20"))
    }

    @Test func emptyFieldsProducesValidJSON() throws {
        AppLogger.info("test.no_fields")

        let contents = try String(contentsOf: AppLogger.logFileURL, encoding: .utf8)
        let lastLine = contents.components(separatedBy: "\n").filter { !$0.isEmpty }.last ?? ""
        let data = Data(lastLine.utf8)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let parsed = try #require(json)
        #expect(parsed["event"] as? String == "test.no_fields")
        #expect((parsed["fields"] as? [String: String])?.isEmpty == true)
    }
}
