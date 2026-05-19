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
}
