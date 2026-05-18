import Testing
import Foundation
@testable import AdiCore

@Suite("Session model")
struct SessionStateTests {

    @Test("Session initialises with correct defaults")
    func defaults() {
        let task = SessionTask(description: "Write essay", successCriteria: "Submit to Canvas")
        let session = Session(task: task)

        #expect(session.status == .idle)
        #expect(session.whitelist.isEmpty)
        #expect(session.offTaskCount == 0)
        #expect(session.lastOnTaskStatus == .unknown)
        #expect(session.endTime == nil)
    }

    @Test("Elapsed time rounds correctly")
    func elapsedTime() throws {
        let start = Date(timeIntervalSinceNow: -90)
        let task = SessionTask(description: "t", successCriteria: "c")
        let session = Session(task: task, startTime: start)

        #expect(session.elapsedTime >= 89)
        #expect(session.elapsedTime <= 91)
    }

    @Test("elapsedFormatted shows mm:ss for under an hour")
    func elapsedFormatted() {
        let start = Date(timeIntervalSinceNow: -125)
        let task = SessionTask(description: "t", successCriteria: "c")
        let session = Session(task: task, startTime: start)
        let formatted = session.elapsedFormatted()
        #expect(formatted.contains(":"))
        #expect(!formatted.isEmpty)
    }

    @Test("Session codable round-trip preserves all fields")
    func codableRoundTrip() throws {
        let task = SessionTask(description: "Write essay", successCriteria: "Submit to Canvas")
        let original = Session(
            task: task,
            status: .active,
            whitelist: ["google.com", "docs.google.com"],
            lastOnTaskStatus: .onTask,
            offTaskCount: 3
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Session.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.status == original.status)
        #expect(decoded.task.description == original.task.description)
        #expect(decoded.task.successCriteria == original.task.successCriteria)
        #expect(decoded.whitelist == original.whitelist)
        #expect(decoded.lastOnTaskStatus == original.lastOnTaskStatus)
        #expect(decoded.offTaskCount == original.offTaskCount)
    }

    @Test("SessionStatus raw values are stable")
    func statusRawValues() {
        #expect(SessionStatus.idle.rawValue == "idle")
        #expect(SessionStatus.active.rawValue == "active")
        #expect(SessionStatus.completed.rawValue == "completed")
        #expect(SessionStatus.abandoned.rawValue == "abandoned")
    }

    @Test("OnTaskStatus raw values are stable")
    func onTaskStatusRawValues() {
        #expect(OnTaskStatus.onTask.rawValue == "onTask")
        #expect(OnTaskStatus.offTask.rawValue == "offTask")
        #expect(OnTaskStatus.ambiguous.rawValue == "ambiguous")
        #expect(OnTaskStatus.unknown.rawValue == "unknown")
    }
}
