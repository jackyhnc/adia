import Foundation
import CoreGraphics

public actor OnTaskDetector {
    private let client: ClaudeClient
    private var currentSession: Session?

    // Rate-limit guard: don't call the API faster than once per second even if
    // the capture pipeline delivers frames quicker than its configured 1 FPS.
    private var lastEvaluatedAt: Date?
    private var lastStatus: OnTaskStatus = .onTask
    private let minInterval: TimeInterval = 1.0

    public init(client: ClaudeClient = .shared) {
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

    public func evaluate(frame: CGImage) async -> OnTaskStatus {
        guard let session = currentSession else { return .onTask }
        guard await client.isConfigured() else { return .onTask }

        let now = Date()
        if let last = lastEvaluatedAt, now.timeIntervalSince(last) < minInterval {
            return lastStatus
        }
        lastEvaluatedAt = now

        do {
            let result = try await client.classify(
                image: frame,
                taskDescription: session.task,
                successCriteria: session.successCriteria
            )
            lastStatus = result.status
            return result.status
        } catch {
            return lastStatus
        }
    }
}
