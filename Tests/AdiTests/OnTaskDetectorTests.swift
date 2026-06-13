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

        // Within minInterval (1.0s at 0 on-task streak) → returns cached .offTask without any API call
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

        // Set last evaluated to 2 seconds ago (beyond 1s base minInterval)
        await detector._setLastEvaluatedAtForTesting(Date(timeIntervalSinceNow: -2.0))
        await detector._setLastStatusForTesting(.offTask)

        // Rate limit expired + no API key → returns .onTask (from the isConfigured guard)
        let status = await detector.evaluate(frame: dummyFrame())
        #expect(status == .onTask)
    }

    // MARK: - Adaptive polling rate

    @Test func adaptiveIntervalIsOneSecondAtSessionStart() async {
        let detector = OnTaskDetector()
        let session = Session(task: "Study", successCriteria: "Done")
        await detector.attach(session: session)
        // Fresh attach: 0 consecutive on-task frames → 1.0s interval
        let interval = await detector.adaptiveMinInterval
        #expect(interval == 1.0)
    }

    @Test func adaptiveIntervalBacksOffAfterThreeOnTaskFrames() async {
        let detector = OnTaskDetector()
        let session = Session(task: "Study", successCriteria: "Done")
        await detector.attach(session: session)
        await detector._setConsecutiveOnTaskFramesForTesting(3)
        let interval = await detector.adaptiveMinInterval
        #expect(interval == 3.0)
    }

    @Test func adaptiveIntervalMaxesOutAtTenOnTaskFrames() async {
        let detector = OnTaskDetector()
        let session = Session(task: "Study", successCriteria: "Done")
        await detector.attach(session: session)
        await detector._setConsecutiveOnTaskFramesForTesting(10)
        let interval = await detector.adaptiveMinInterval
        #expect(interval == 8.0)
    }

    @Test func onTaskResultIncrementsConsecutiveCounter() async {
        let mock = MockAgentAIClient()
        await mock.setClassifyResult(.success(OnTaskClassification(status: .onTask, confidence: 0.95, reason: "Working")))
        let detector = OnTaskDetector(client: mock)
        let session = Session(task: "Write essay", successCriteria: "Submitted")
        await detector.attach(session: session)

        _ = await detector.evaluate(frame: dummyFrame())
        let count = await detector._consecutiveOnTaskFrames()
        #expect(count == 1)
    }

    @Test func offTaskResultResetsConsecutiveCounter() async {
        let mock = MockAgentAIClient()
        await mock.setClassifyResult(.success(OnTaskClassification(status: .offTask, confidence: 0.9, reason: "Reddit open")))
        let detector = OnTaskDetector(client: mock)
        let session = Session(task: "Write essay", successCriteria: "Submitted")
        await detector.attach(session: session)
        // Simulate a prior on-task streak
        await detector._setConsecutiveOnTaskFramesForTesting(7)

        _ = await detector.evaluate(frame: dummyFrame())
        let count = await detector._consecutiveOnTaskFrames()
        #expect(count == 0, "off-task result should reset the consecutive counter")
    }

    @Test func ambiguousResultResetsConsecutiveCounter() async {
        let mock = MockAgentAIClient()
        await mock.setClassifyResult(.success(OnTaskClassification(status: .ambiguous, confidence: 0.5, reason: "Unclear")))
        let detector = OnTaskDetector(client: mock)
        let session = Session(task: "Write essay", successCriteria: "Submitted")
        await detector.attach(session: session)
        await detector._setConsecutiveOnTaskFramesForTesting(5)

        _ = await detector.evaluate(frame: dummyFrame())
        let count = await detector._consecutiveOnTaskFrames()
        #expect(count == 0, "ambiguous result should reset the consecutive counter")
    }

    @Test func deepFocusStreakThrottlesSubsequentFrames() async {
        let mock = MockAgentAIClient()
        await mock.setClassifyResult(.success(OnTaskClassification(status: .onTask, confidence: 0.99, reason: "Deep work")))
        let detector = OnTaskDetector(client: mock)
        let session = Session(task: "Write essay", successCriteria: "Submitted")
        await detector.attach(session: session)

        // Simulate 10 consecutive on-task frames → 8s interval
        await detector._setConsecutiveOnTaskFramesForTesting(10)
        await detector._setLastEvaluatedAtForTesting(Date(timeIntervalSinceNow: -4.0))
        await detector._setLastStatusForTesting(.onTask)

        // 4s has elapsed but interval is 8s → should throttle (return cached, no classify call)
        let beforeCount = await mock.classifyCallCount
        _ = await detector.evaluate(frame: dummyFrame())
        let afterCount = await mock.classifyCallCount
        #expect(afterCount == beforeCount, "should throttle: 4s < 8s adaptive interval")
    }

    @Test func attachResetsAdaptiveState() async {
        let detector = OnTaskDetector()
        let session = Session(task: "Study", successCriteria: "Done")
        await detector.attach(session: session)
        await detector._setConsecutiveOnTaskFramesForTesting(15)

        // Re-attach (new session) resets everything
        await detector.attach(session: session)
        let count = await detector._consecutiveOnTaskFrames()
        let interval = await detector.adaptiveMinInterval
        #expect(count == 0)
        #expect(interval == 1.0)
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
