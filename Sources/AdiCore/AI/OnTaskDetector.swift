import Foundation
import CoreGraphics

public actor OnTaskDetector {
    private let client: AgentAIClient
    private var currentSession: Session?

    // Rate-limit guard: fast enough to catch drift quickly without queueing
    // overlapping model calls when ScreenCaptureKit delivers frames faster.
    private var lastEvaluatedAt: Date?
    private var lastStatus: OnTaskStatus = .onTask
    private let minInterval: TimeInterval = 0.6

    public init(client: AgentAIClient = .shared) {
        self.client = client
    }

    public func attach(session: Session) {
        currentSession = session
        lastEvaluatedAt = nil
        lastStatus = .onTask
    }

    public func detach() {
        currentSession = nil
    }

    // MARK: - Test helpers (internal)

    internal func _setLastEvaluatedAtForTesting(_ date: Date) {
        lastEvaluatedAt = date
    }

    internal func _setLastStatusForTesting(_ status: OnTaskStatus) {
        lastStatus = status
    }

    public func evaluate(frame: CGImage) async -> OnTaskStatus {
        guard let session = currentSession else { return .onTask }

        // Rate-limit check first — skips the isConfigured() MainActor hop on
        // every throttled frame (all but 1 per second at 1 FPS capture).
        let now = Date()
        if let last = lastEvaluatedAt, now.timeIntervalSince(last) < minInterval {
            AppLogger.info("classification.throttled", [
                "lastStatus": lastStatus.rawValue
            ])
            return lastStatus
        }

        // Only hop to MainActor to read the API key when we're about to make a call.
        guard await client.isConfigured() else {
            AppLogger.warning("classification.skipped", ["reason": "missing_api_key"])
            return .onTask
        }
        lastEvaluatedAt = now

        do {
            let startedAt = Date()
            let result = try await client.classify(
                image: frame,
                taskDescription: session.task,
                successCriteria: session.successCriteria
            )
            AppLogger.info("classification.result", [
                "status": result.status.rawValue,
                "confidence": String(format: "%.2f", result.confidence),
                "durationMs": String(Int(Date().timeIntervalSince(startedAt) * 1000)),
                "reason": result.reason
            ])
            lastStatus = result.status
            return result.status
        } catch {
            AppLogger.error("classification.failed", [
                "error": String(describing: error),
                "lastStatus": lastStatus.rawValue
            ])
            return lastStatus
        }
    }
}
