import Testing
import Foundation
@testable import AdiCore

@Suite("SessionPersistence")
struct SessionPersistenceTests {

    func makeTemp() -> (SessionPersistence, URL) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("adia_session_\(UUID().uuidString).json")
        return (SessionPersistence(fileURL: url), url)
    }

    @Test("Save and load returns equal session")
    func saveLoad() throws {
        let (p, url) = makeTemp()
        defer { try? FileManager.default.removeItem(at: url) }

        let task = SessionTask(description: "Write essay", successCriteria: "Submit to Canvas")
        let session = Session(task: task, status: .active, whitelist: ["google.com"])

        try p.save(session)
        let loaded = try p.load()

        #expect(loaded?.id == session.id)
        #expect(loaded?.status == session.status)
        #expect(loaded?.task.description == session.task.description)
        #expect(loaded?.whitelist == session.whitelist)
    }

    @Test("Load returns nil when no file exists")
    func loadMissing() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("nonexistent_\(UUID().uuidString).json")
        let p = SessionPersistence(fileURL: url)

        let result = try p.load()
        #expect(result == nil)
    }

    @Test("Clear removes the saved file")
    func clear() throws {
        let (p, url) = makeTemp()
        defer { try? FileManager.default.removeItem(at: url) }

        let task = SessionTask(description: "t", successCriteria: "c")
        try p.save(Session(task: task))
        try p.clear()

        let result = try p.load()
        #expect(result == nil)
    }

    @Test("Overwrite replaces previous session")
    func overwrite() throws {
        let (p, url) = makeTemp()
        defer { try? FileManager.default.removeItem(at: url) }

        let task1 = SessionTask(description: "first", successCriteria: "done1")
        let task2 = SessionTask(description: "second", successCriteria: "done2")

        try p.save(Session(task: task1))
        try p.save(Session(task: task2))

        let loaded = try p.load()
        #expect(loaded?.task.description == "second")
    }
}
