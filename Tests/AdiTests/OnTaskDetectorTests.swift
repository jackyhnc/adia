import Testing
import Foundation
import CoreGraphics
@testable import AdiCore

/// Tests run serially: AgentAIClient.shared._isConfiguredOverride is mutated across tests.
@Suite("OnTaskDetector", .serialized)
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
        await AgentAIClient.shared._setIsConfiguredOverride(false)
        defer { Task { await AgentAIClient.shared._setIsConfiguredOverride(nil) } }

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
        await AgentAIClient.shared._setIsConfiguredOverride(false)
        defer { Task { await AgentAIClient.shared._setIsConfiguredOverride(nil) } }

        // Set last evaluated to 2 seconds ago (beyond 1s minInterval)
        await detector._setLastEvaluatedAtForTesting(Date(timeIntervalSinceNow: -2.0))
        await detector._setLastStatusForTesting(.offTask)

        // Rate limit expired + no API key → returns .onTask (from the isConfigured guard)
        let status = await detector.evaluate(frame: dummyFrame())
        #expect(status == .onTask)
    }

    /// With a real (non-`AgentAIClient`) backing client injected via the
    /// `AgentAIService` DI seam, `evaluate` runs the full classify path
    /// deterministically — no `ANTHROPIC_API_KEY`/network needed.
    @Test func evaluateReturnsClassificationFromInjectedMockClient() async {
        let mock = MockAgentAIClient()
        await mock.setClassifyResult(.success(OnTaskClassification(status: .offTask, confidence: 0.92, reason: "Reddit is open")))
        let detector = OnTaskDetector(client: mock)
        let session = Session(task: "Write essay", successCriteria: "Submitted to Canvas")
        await detector.attach(session: session)

        let status = await detector.evaluate(frame: dummyFrame())
        #expect(status == .offTask)
        #expect(await mock.classifyCallCount == 1)
    }

    /// `evaluate` falls back to the cached `lastStatus` (rather than crashing or
    /// returning `.onTask`) when the underlying client throws mid-classification.
    @Test func evaluateFallsBackToLastStatusWhenClientThrows() async {
        let mock = MockAgentAIClient()
        await mock.setClassifyResult(.failure(MockAgentAIError(message: "rate limited")))
        let detector = OnTaskDetector(client: mock)
        let session = Session(task: "Write essay", successCriteria: "Submitted to Canvas")
        await detector.attach(session: session)
        await detector._setLastStatusForTesting(.offTask)
        // Force the rate-limit guard to allow this call through immediately.
        await detector._setLastEvaluatedAtForTesting(Date(timeIntervalSinceNow: -2.0))

        let status = await detector.evaluate(frame: dummyFrame())
        #expect(status == .offTask, "on failure, evaluate should return the cached lastStatus rather than resetting to onTask")
        #expect(await mock.classifyCallCount == 1)
    }
}

// Actor accessor for the testing override
extension AgentAIClient {
    func _setIsConfiguredOverride(_ value: Bool?) {
        _isConfiguredOverride = value
    }
}
