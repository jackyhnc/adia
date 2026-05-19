import Testing
import Foundation
import CoreGraphics
@testable import AdiCore

@Suite("OnTaskDetector")
struct OnTaskDetectorTests {

    /// Creates a minimal 1x1 CGImage for use as a dummy frame.
    private func dummyFrame() -> CGImage {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let ctx = CGContext(
            data: nil,
            width: 1, height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        return ctx.makeImage()!
    }

    @Test func returnsOnTaskWhenNoSessionAttached() async {
        let detector = OnTaskDetector()
        await detector.detach()
        let status = await detector.evaluate(frame: dummyFrame())
        #expect(status == .onTask)
    }

    @Test func returnsOnTaskWhenAPIKeyNotConfigured() async {
        let detector = OnTaskDetector()
        let session = Session(task: "Study", successCriteria: "Finish chapter")
        await detector.attach(session: session)
        // Force isConfigured to return false regardless of env
        await ClaudeClient.shared._setIsConfiguredOverride(false)
        defer { Task { await ClaudeClient.shared._setIsConfiguredOverride(nil) } }

        let status = await detector.evaluate(frame: dummyFrame())
        #expect(status == .onTask)
    }

    @Test func rateLimitReturnsCachedStatusWithinMinInterval() async {
        let detector = OnTaskDetector()
        let session = Session(task: "Write code", successCriteria: "PR merged")
        await detector.attach(session: session)

        // Inject state: last checked just now, cached status is .offTask
        await detector._setLastEvaluatedAtForTesting(Date())
        await detector._setLastStatusForTesting(.offTask)

        // Within minInterval → returns cached .offTask without any API call
        let status = await detector.evaluate(frame: dummyFrame())
        #expect(status == .offTask)
    }

    @Test func rateLimitExpiredAllowsNewEvaluation() async {
        let detector = OnTaskDetector()
        let session = Session(task: "Study", successCriteria: "Done")
        await detector.attach(session: session)

        // Force isConfigured false so classify() guard fires after rate-limit check
        await ClaudeClient.shared._setIsConfiguredOverride(false)
        defer { Task { await ClaudeClient.shared._setIsConfiguredOverride(nil) } }

        // Set last evaluated to 2 seconds ago (beyond 1s minInterval)
        await detector._setLastEvaluatedAtForTesting(Date(timeIntervalSinceNow: -2.0))
        await detector._setLastStatusForTesting(.offTask)

        // Rate limit expired + no API key → returns .onTask (from the isConfigured guard)
        let status = await detector.evaluate(frame: dummyFrame())
        #expect(status == .onTask)
    }
}

// Actor accessor for the testing override
extension ClaudeClient {
    func _setIsConfiguredOverride(_ value: Bool?) {
        _isConfiguredOverride = value
    }
}
