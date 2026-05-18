import Testing
import Foundation
@testable import AdiCore

@Suite("SessionPersistence")
struct SessionPersistenceTests {

    @Test func saveLoadRoundTrip() throws {
        let p = SessionPersistence.shared
        let original = Session(
            task: "Write ENGL 101 essay",
            successCriteria: "Submit to Canvas",
            phase: .active,
            whitelistedDomains: ["jstor.org"]
        )
        p.save(original)
        let loaded = try #require(p.load())
        #expect(loaded.id == original.id)
        #expect(loaded.task == original.task)
        #expect(loaded.successCriteria == original.successCriteria)
        #expect(loaded.whitelistedDomains == original.whitelistedDomains)
        p.clear()
    }

    @Test func clearRemovesSession() {
        let p = SessionPersistence.shared
        let s = Session(task: "t", successCriteria: "c")
        p.save(s)
        p.clear()
        #expect(p.load() == nil)
    }

    @Test func loadNilWhenEmpty() {
        let p = SessionPersistence.shared
        p.clear()
        #expect(p.load() == nil)
    }
}
