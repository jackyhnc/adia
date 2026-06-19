import Testing
import Foundation
@testable import AdiCore

@Suite("NetworkMonitor", .serialized)
struct NetworkMonitorTests {

    // MARK: - Circuit breaker threshold

    @Test func circuitBreakerThresholdIsThree() {
        #expect(NetworkMonitor.circuitBreakerThreshold == 3)
    }

    // MARK: - isCircuitOpen

    @Test @MainActor func circuitClosedWhenConnectedAndNoFailures() {
        let monitor = NetworkMonitor.shared
        monitor._setConnectedForTesting(true)
        monitor._setConsecutiveFailuresForTesting(0)
        #expect(!monitor.isCircuitOpen)
    }

    @Test @MainActor func circuitOpenWhenDisconnected() {
        let monitor = NetworkMonitor.shared
        monitor._setConnectedForTesting(false)
        monitor._setConsecutiveFailuresForTesting(0)
        #expect(monitor.isCircuitOpen)
        monitor._setConnectedForTesting(true)
    }

    @Test @MainActor func circuitOpenWhenFailuresReachThreshold() {
        let monitor = NetworkMonitor.shared
        monitor._setConnectedForTesting(true)
        monitor._setConsecutiveFailuresForTesting(3)
        #expect(monitor.isCircuitOpen)
        monitor._setConsecutiveFailuresForTesting(0)
    }

    @Test @MainActor func circuitClosedBelowThreshold() {
        let monitor = NetworkMonitor.shared
        monitor._setConnectedForTesting(true)
        monitor._setConsecutiveFailuresForTesting(2)
        #expect(!monitor.isCircuitOpen)
        monitor._setConsecutiveFailuresForTesting(0)
    }

    // MARK: - recordSuccess / recordFailure

    @Test @MainActor func recordSuccessResetsFailures() {
        let monitor = NetworkMonitor.shared
        monitor._setConsecutiveFailuresForTesting(2)
        monitor.recordSuccess()
        #expect(monitor.consecutiveFailures == 0)
    }

    @Test @MainActor func recordFailureIncrementsCount() {
        let monitor = NetworkMonitor.shared
        monitor._setConsecutiveFailuresForTesting(0)
        monitor.recordFailure()
        #expect(monitor.consecutiveFailures == 1)
        monitor.recordFailure()
        #expect(monitor.consecutiveFailures == 2)
        monitor._setConsecutiveFailuresForTesting(0)
    }

    @Test @MainActor func resetCircuitBreakerClearsFailures() {
        let monitor = NetworkMonitor.shared
        monitor._setConsecutiveFailuresForTesting(5)
        monitor.resetCircuitBreaker()
        #expect(monitor.consecutiveFailures == 0)
        #expect(!monitor.isCircuitOpen)
    }

    // MARK: - OnTaskDetector circuit breaker integration

    @Test func detectorSkipsAPICallWhenCircuitOpen() async {
        let mock = MockAgentAIClient()
        await mock.setClassifyResult(.success(OnTaskClassification(status: .offTask, confidence: 0.9, reason: "distracted")))
        let detector = OnTaskDetector(client: mock)
        let session = Session(task: "Write essay", successCriteria: "Submitted")
        await detector.attach(session: session)
        await detector._setLastStatusForTesting(.onTask)

        await MainActor.run {
            NetworkMonitor.shared._setConnectedForTesting(false)
        }

        let result = await detector.evaluate(frame: dummyFrame())
        // Should return cached .onTask, not the mock's .offTask
        #expect(result.status == .onTask)
        #expect(await mock.classifyCallCount == 0, "circuit breaker should skip the API call entirely")

        await MainActor.run {
            NetworkMonitor.shared._setConnectedForTesting(true)
            NetworkMonitor.shared._setConsecutiveFailuresForTesting(0)
        }
    }

    @Test func detectorSkipsAPICallWhenConsecutiveFailuresHitThreshold() async {
        let mock = MockAgentAIClient()
        await mock.setClassifyResult(.success(OnTaskClassification(status: .offTask, confidence: 0.9, reason: "distracted")))
        let detector = OnTaskDetector(client: mock)
        let session = Session(task: "Write essay", successCriteria: "Submitted")
        await detector.attach(session: session)
        await detector._setLastStatusForTesting(.ambiguous)

        await MainActor.run {
            NetworkMonitor.shared._setConnectedForTesting(true)
            NetworkMonitor.shared._setConsecutiveFailuresForTesting(3)
        }

        let result = await detector.evaluate(frame: dummyFrame())
        #expect(result.status == .ambiguous)
        #expect(await mock.classifyCallCount == 0)

        await MainActor.run {
            NetworkMonitor.shared._setConsecutiveFailuresForTesting(0)
        }
    }

    @Test func detectorCallsAPIWhenCircuitClosed() async {
        let mock = MockAgentAIClient()
        await mock.setClassifyResult(.success(OnTaskClassification(status: .offTask, confidence: 0.9, reason: "Reddit")))
        let detector = OnTaskDetector(client: mock)
        let session = Session(task: "Write essay", successCriteria: "Submitted")
        await detector.attach(session: session)

        await MainActor.run {
            NetworkMonitor.shared._setConnectedForTesting(true)
            NetworkMonitor.shared._setConsecutiveFailuresForTesting(0)
        }

        let result = await detector.evaluate(frame: dummyFrame())
        #expect(result.status == .offTask)
        #expect(await mock.classifyCallCount == 1)
    }

    @Test func classifySuccessResetsFailureCounter() async {
        let mock = MockAgentAIClient()
        await mock.setClassifyResult(.success(OnTaskClassification(status: .onTask, confidence: 0.95, reason: "Working")))
        let detector = OnTaskDetector(client: mock)
        let session = Session(task: "Write essay", successCriteria: "Submitted")
        await detector.attach(session: session)

        await MainActor.run {
            NetworkMonitor.shared._setConnectedForTesting(true)
            NetworkMonitor.shared._setConsecutiveFailuresForTesting(2)
        }

        _ = await detector.evaluate(frame: dummyFrame())
        let failures = await MainActor.run { NetworkMonitor.shared.consecutiveFailures }
        #expect(failures == 0)
    }

    @Test func classifyFailureIncrementsFailureCounter() async {
        let mock = MockAgentAIClient()
        await mock.setClassifyResult(.failure(MockAgentAIError(message: "timeout")))
        let detector = OnTaskDetector(client: mock)
        let session = Session(task: "Write essay", successCriteria: "Submitted")
        await detector.attach(session: session)

        await MainActor.run {
            NetworkMonitor.shared._setConnectedForTesting(true)
            NetworkMonitor.shared._setConsecutiveFailuresForTesting(0)
        }

        _ = await detector.evaluate(frame: dummyFrame())
        let failures = await MainActor.run { NetworkMonitor.shared.consecutiveFailures }
        #expect(failures == 1)

        await MainActor.run {
            NetworkMonitor.shared._setConsecutiveFailuresForTesting(0)
        }
    }

    // MARK: - Helpers

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
}
