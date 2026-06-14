import Testing
import Foundation
@testable import AdiCore

@Suite("LocalBlockServer")
struct LocalBlockServerTests {

    @Test func startDoesNotCrash() {
        LocalBlockServer.shared.start(
            blockedDomains: ["youtube.com", "reddit.com"],
            taskDescription: "Write essay"
        )
        LocalBlockServer.shared.stop()
    }

    @Test func stopTwiceIsSafe() {
        LocalBlockServer.shared.start(
            blockedDomains: ["twitter.com"],
            taskDescription: "Coding task"
        )
        LocalBlockServer.shared.stop()
        // Second stop should not crash
        LocalBlockServer.shared.stop()
    }

    @Test func doubleStartReleasedPriorListener() {
        LocalBlockServer.shared.start(
            blockedDomains: ["netflix.com"],
            taskDescription: "First task"
        )
        // Second start cancels the previous listener and starts fresh
        LocalBlockServer.shared.start(
            blockedDomains: ["youtube.com"],
            taskDescription: "Second task"
        )
        LocalBlockServer.shared.stop()
    }

    @Test func stopWithoutStartIsSafe() {
        // Isolated instance via internal test init — never started
        let server = LocalBlockServer(forTesting: ())
        server.stop()
        server.stop()
    }

    @Test func startWithEmptyDomainsDoesNotCrash() {
        LocalBlockServer.shared.start(blockedDomains: [], taskDescription: "")
        LocalBlockServer.shared.stop()
    }

    // MARK: - htmlEscape

    @Test func htmlEscapePassthroughForPlainText() {
        #expect(LocalBlockServer.htmlEscape("hello world") == "hello world")
    }

    @Test func htmlEscapeAmpersand() {
        #expect(LocalBlockServer.htmlEscape("bread & butter") == "bread &amp; butter")
    }

    @Test func htmlEscapeAngleBrackets() {
        #expect(LocalBlockServer.htmlEscape("<script>alert(1)</script>") == "&lt;script&gt;alert(1)&lt;/script&gt;")
    }

    @Test func htmlEscapeDoubleQuote() {
        #expect(LocalBlockServer.htmlEscape("say \"hello\"") == "say &quot;hello&quot;")
    }

    @Test func htmlEscapeAllSpecialCharsInTaskDescription() {
        let input = "submit <ENGL 101> essay & \"cover page\""
        let escaped = LocalBlockServer.htmlEscape(input)
        #expect(escaped.contains("&lt;ENGL 101&gt;"))
        #expect(escaped.contains("&amp;"))
        #expect(escaped.contains("&quot;cover page&quot;"))
        #expect(!escaped.contains("<ENGL"))
    }

    @Test func htmlEscapeEmptyString() {
        #expect(LocalBlockServer.htmlEscape("") == "")
    }

    // MARK: - shouldNotifyCallback (rate-limiting for auto-reasoning trigger)

    @Test func shouldNotifyCallbackFirstCallReturnsTrue() {
        #expect(LocalBlockServer.shouldNotifyCallback(
            forDomain: "youtube.com",
            lastDomain: nil,
            lastNotifiedAt: nil,
            now: Date()
        ))
    }

    @Test func shouldNotifyCallbackSameDomainWithinIntervalReturnsFalse() {
        let now = Date()
        let recent = now.addingTimeInterval(-5)
        #expect(!LocalBlockServer.shouldNotifyCallback(
            forDomain: "youtube.com",
            lastDomain: "youtube.com",
            lastNotifiedAt: recent,
            now: now,
            minInterval: 10.0
        ))
    }

    @Test func shouldNotifyCallbackSameDomainAfterIntervalReturnsTrue() {
        let now = Date()
        let old = now.addingTimeInterval(-15)
        #expect(LocalBlockServer.shouldNotifyCallback(
            forDomain: "youtube.com",
            lastDomain: "youtube.com",
            lastNotifiedAt: old,
            now: now,
            minInterval: 10.0
        ))
    }

    @Test func shouldNotifyCallbackDifferentDomainIgnoresInterval() {
        let now = Date()
        let recent = now.addingTimeInterval(-2)
        #expect(LocalBlockServer.shouldNotifyCallback(
            forDomain: "reddit.com",
            lastDomain: "youtube.com",
            lastNotifiedAt: recent,
            now: now,
            minInterval: 10.0
        ))
    }

    @Test func shouldNotifyCallbackExactlyAtIntervalBoundaryReturnsTrue() {
        let now = Date()
        let boundary = now.addingTimeInterval(-10)
        #expect(LocalBlockServer.shouldNotifyCallback(
            forDomain: "twitter.com",
            lastDomain: "twitter.com",
            lastNotifiedAt: boundary,
            now: now,
            minInterval: 10.0
        ))
    }

    @Test func onBlockedDomainAccessedCallbackCanBeSetAndCleared() {
        let server = LocalBlockServer(forTesting: ())
        var fired = false
        server.onBlockedDomainAccessed = { _ in fired = true }
        #expect(server.onBlockedDomainAccessed != nil)
        server.onBlockedDomainAccessed = nil
        #expect(server.onBlockedDomainAccessed == nil)
        _ = fired  // suppress unused warning
    }
}
