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

    @Test func startWithCallbackParameterSetsCallbackBeforeListenerBegins() {
        let server = LocalBlockServer(forTesting: ())
        var callbackDomain: String?
        server.start(
            blockedDomains: [],
            taskDescription: "Test task",
            onBlockedDomainAccessed: { domain in callbackDomain = domain }
        )
        #expect(server.onBlockedDomainAccessed != nil)
        server.stop()
        _ = callbackDomain
    }

    @Test func stopClearsOnBlockedDomainAccessed() {
        let server = LocalBlockServer(forTesting: ())
        server.start(
            blockedDomains: ["youtube.com"],
            taskDescription: "Study",
            onBlockedDomainAccessed: { _ in }
        )
        #expect(server.onBlockedDomainAccessed != nil)
        server.stop()
        #expect(server.onBlockedDomainAccessed == nil)
    }

    @Test func startWithNilCallbackLeavesCallbackNil() {
        let server = LocalBlockServer(forTesting: ())
        server.start(blockedDomains: [], taskDescription: "No callback")
        #expect(server.onBlockedDomainAccessed == nil)
        server.stop()
    }

    @Test func secondStartOverridesPreviousCallback() {
        let server = LocalBlockServer(forTesting: ())
        server.start(
            blockedDomains: [],
            taskDescription: "First",
            onBlockedDomainAccessed: { _ in }
        )
        #expect(server.onBlockedDomainAccessed != nil)
        // Second start without a callback: previous callback must be replaced with nil.
        server.start(blockedDomains: [], taskDescription: "Second")
        #expect(server.onBlockedDomainAccessed == nil)
        server.stop()
    }

    // MARK: - isoFormat

    @Test func isoFormatProducesISO8601String() {
        // A known epoch value: 2024-01-15T10:30:00Z = 1705314600
        let date = Date(timeIntervalSince1970: 1_705_314_600)
        let iso = LocalBlockServer.isoFormat(date)
        #expect(iso == "2024-01-15T10:30:00Z")
    }

    @Test func isoFormatRoundTrips() {
        let original = Date(timeIntervalSince1970: 1_700_000_000)
        let iso = LocalBlockServer.isoFormat(original)
        let parsed = ISO8601DateFormatter().date(from: iso)
        #expect(parsed != nil)
        #expect(abs(parsed!.timeIntervalSince(original)) < 1.0)
    }

    // MARK: - elapsedScriptTag

    @Test func elapsedScriptTagContainsProvidedISO() {
        let iso = "2024-01-15T10:30:00Z"
        let script = LocalBlockServer.elapsedScriptTag(startISO: iso)
        #expect(script.contains(iso))
    }

    @Test func elapsedScriptTagContainsSetInterval() {
        let script = LocalBlockServer.elapsedScriptTag(startISO: "2024-01-01T00:00:00Z")
        #expect(script.contains("setInterval"))
    }

    @Test func elapsedScriptTagReferencesElapsedElementID() {
        let script = LocalBlockServer.elapsedScriptTag(startISO: "2024-01-01T00:00:00Z")
        #expect(script.contains("getElementById('elapsed')") || script.contains("getElementById(\"elapsed\")"))
    }

    @Test func elapsedScriptTagIsWrappedInScriptTags() {
        let script = LocalBlockServer.elapsedScriptTag(startISO: "2024-01-01T00:00:00Z")
        #expect(script.contains("<script>"))
        #expect(script.contains("</script>"))
    }

    // MARK: - blockedHTML elapsed integration

    @Test func blockedHTMLContainsElapsedDivAlways() {
        let html = LocalBlockServer.blockedHTML(domain: "youtube.com", taskDescription: "write essay")
        #expect(html.contains("id=\"elapsed\""))
    }

    @Test func blockedHTMLIncludesScriptWhenStartTimeGiven() {
        let start = Date(timeIntervalSince1970: 1_705_314_600)
        let html = LocalBlockServer.blockedHTML(
            domain: "youtube.com",
            taskDescription: "write essay",
            sessionStartTime: start
        )
        #expect(html.contains("<script>"))
        #expect(html.contains(LocalBlockServer.isoFormat(start)))
    }

    @Test func blockedHTMLOmitsScriptWhenNoStartTime() {
        let html = LocalBlockServer.blockedHTML(
            domain: "youtube.com",
            taskDescription: "write essay",
            sessionStartTime: nil
        )
        #expect(!html.contains("<script>"))
    }

    @Test func blockedHTMLStartDoesNotCrashWithStartTime() {
        let start = Date()
        LocalBlockServer.shared.start(
            blockedDomains: ["youtube.com"],
            taskDescription: "Study session",
            sessionStartTime: start
        )
        LocalBlockServer.shared.stop()
    }
}
