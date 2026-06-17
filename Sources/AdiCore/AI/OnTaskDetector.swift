import Foundation
import CoreGraphics

public actor OnTaskDetector {
    private let client: any AgentAIService
    private var currentSession: Session?

    // Rate-limit guard: skips overlapping classify() calls when ScreenCaptureKit
    // delivers frames faster than the model can respond.
    private var lastEvaluatedAt: Date?
    private var lastStatus: OnTaskStatus = .onTask
    private var lastReason: String = ""

    // Adaptive back-off: consecutive on-task frames let the interval grow so we
    // call the model less during deep focus, while any off-task result snaps it back.
    private var consecutiveOnTaskFrames: Int = 0

    // Adaptive interval: tighter polling when uncertain, relaxed during focus streaks.
    // 0–2 on-task frames: 1s  (catch drift fast)
    // 3–9 on-task frames: 3s  (steady focus — back off)
    // 10+ on-task frames: 8s  (deep focus — check infrequently)
    var adaptiveMinInterval: TimeInterval {
        switch consecutiveOnTaskFrames {
        case 0..<3:  return 1.0
        case 3..<10: return 3.0
        default:     return 8.0
        }
    }

    public init(client: any AgentAIService = AgentAIClient.shared) {
        self.client = client
    }

    public func attach(session: Session) {
        currentSession = session
        lastEvaluatedAt = nil
        lastStatus = .onTask
        lastReason = ""
        consecutiveOnTaskFrames = 0
    }

    public func detach() {
        currentSession = nil
        consecutiveOnTaskFrames = 0
    }

    // MARK: - Test helpers (internal)

    internal func _setLastEvaluatedAtForTesting(_ date: Date) {
        lastEvaluatedAt = date
    }

    internal func _setLastStatusForTesting(_ status: OnTaskStatus) {
        lastStatus = status
    }

    internal func _setConsecutiveOnTaskFramesForTesting(_ count: Int) {
        consecutiveOnTaskFrames = count
    }

    internal func _consecutiveOnTaskFrames() -> Int {
        consecutiveOnTaskFrames
    }

    public func evaluate(frame: CGImage) async -> OnTaskClassification {
        guard let session = currentSession else {
            return OnTaskClassification(status: .onTask, confidence: 0, reason: "")
        }

        // Adaptive rate-limit: skips the isConfigured() MainActor hop on throttled frames.
        let now = Date()
        let interval = adaptiveMinInterval
        if let last = lastEvaluatedAt, now.timeIntervalSince(last) < interval {
            AppLogger.info("classification.throttled", [
                "lastStatus": lastStatus.rawValue,
                "intervalSeconds": String(format: "%.1f", interval),
                "consecutiveOnTask": String(consecutiveOnTaskFrames),
            ])
            return OnTaskClassification(status: lastStatus, confidence: 0, reason: lastReason)
        }

        // Only hop to MainActor to read the API key when we're about to make a call.
        guard await client.isConfigured() else {
            AppLogger.warning("classification.skipped", ["reason": "missing_api_key"])
            return OnTaskClassification(status: .onTask, confidence: 0, reason: "")
        }
        lastEvaluatedAt = now

        do {
            let startedAt = Date()
            let result = try await client.classify(
                image: frame,
                taskDescription: session.task,
                successCriteria: session.successCriteria
            )
            // Update adaptive counter: grow streak on on-task, reset immediately otherwise.
            if result.status == .onTask {
                consecutiveOnTaskFrames += 1
            } else {
                consecutiveOnTaskFrames = 0
            }
            AppLogger.info("classification.result", [
                "status": result.status.rawValue,
                "confidence": String(format: "%.2f", result.confidence),
                "durationMs": String(Int(Date().timeIntervalSince(startedAt) * 1000)),
                "reason": result.reason,
                "consecutiveOnTask": String(consecutiveOnTaskFrames),
                "nextIntervalSeconds": String(format: "%.1f", adaptiveMinInterval),
            ])
            lastStatus = result.status
            lastReason = result.reason
            return result
        } catch {
            AppLogger.error("classification.failed", [
                "error": String(describing: error),
                "lastStatus": lastStatus.rawValue
            ])
            return OnTaskClassification(status: lastStatus, confidence: 0, reason: lastReason)
        }
    }
}
