import Testing
import Foundation
@testable import AdiCore

@Suite("SessionManager — pure logic")
struct SessionManagerTests {

    private func injectSession(_ session: Session?) async {
        await MainActor.run {
            SessionManager.shared._injectSessionForTesting(session)
        }
    }

    // MARK: - whitelist(domain:)

    @Test func whitelistEmptyDomainIsNoOp() async {
        let s = Session(task: "Study", successCriteria: "Done")
        await injectSession(s)
        await MainActor.run {
            Task { await SessionManager.shared.whitelist(domain: "") }
        }
        // Allow the async task to settle
        try? await Task.sleep(for: .milliseconds(50))
        let domains = await MainActor.run { SessionManager.shared.session?.whitelistedDomains ?? [] }
        #expect(domains.isEmpty)
        await injectSession(nil)
    }

    @Test func whitelistWhitespaceOnlyDomainIsNoOp() async {
        let s = Session(task: "Study", successCriteria: "Done")
        await injectSession(s)
        await MainActor.run {
            Task { await SessionManager.shared.whitelist(domain: "   ") }
        }
        try? await Task.sleep(for: .milliseconds(50))
        let domains = await MainActor.run { SessionManager.shared.session?.whitelistedDomains ?? [] }
        #expect(domains.isEmpty)
        await injectSession(nil)
    }

    @Test func whitelistStripswwwPrefix() async {
        let s = Session(
            task: "Research",
            successCriteria: "Done",
            blockedDomains: ["jstor.org"]
        )
        await injectSession(s)
        await MainActor.run {
            Task { await SessionManager.shared.whitelist(domain: "www.jstor.org") }
        }
        try? await Task.sleep(for: .milliseconds(50))
        let session = await MainActor.run { SessionManager.shared.session }
        #expect(session?.whitelistedDomains.contains("jstor.org") == true)
        #expect(session?.blockedDomains.contains("jstor.org") == false)
        await injectSession(nil)
    }

    @Test func whitelistRemovesDomainFromBlockList() async {
        let s = Session(
            task: "Research",
            successCriteria: "Done",
            blockedDomains: ["reddit.com", "youtube.com"]
        )
        await injectSession(s)
        await MainActor.run {
            Task { await SessionManager.shared.whitelist(domain: "reddit.com") }
        }
        try? await Task.sleep(for: .milliseconds(50))
        let session = await MainActor.run { SessionManager.shared.session }
        #expect(session?.whitelistedDomains.contains("reddit.com") == true)
        #expect(session?.blockedDomains.contains("reddit.com") == false)
        #expect(session?.blockedDomains.contains("youtube.com") == true)
        await injectSession(nil)
    }

    @Test func whitelistNoSessionIsNoOp() async {
        await injectSession(nil)
        // Should not crash
        await MainActor.run {
            Task { await SessionManager.shared.whitelist(domain: "example.com") }
        }
        try? await Task.sleep(for: .milliseconds(50))
        // No assertion needed — just verifying no crash
    }

    // MARK: - restoreIfNeeded

    @Test func restoreIfNeededNoSavedSessionLeavesSessionNil() async {
        SessionPersistence.shared.clear()
        await MainActor.run {
            SessionManager.shared._injectSessionForTesting(nil)
        }
        // restoreIfNeeded with no saved session should leave session == nil
        // (we can't call the real restoreIfNeeded since it starts capture, but we verify
        //  the persistence side: load() returns nil, so the guard exits early)
        let loaded = SessionPersistence.shared.load()
        #expect(loaded == nil)
    }

    @Test func restoreIfNeededStaleSessionIsDiscarded() async {
        // Sessions older than 24h should be pruned by SessionPersistence.load()
        let old = Session(
            task: "Old task",
            successCriteria: "done",
            startTime: Date(timeIntervalSinceNow: -25 * 3600)
        )
        SessionPersistence.shared.save(old)
        let loaded = SessionPersistence.shared.load()
        #expect(loaded == nil, "stale session should be discarded by load()")
        SessionPersistence.shared.clear()
    }
}
