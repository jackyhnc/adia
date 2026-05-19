import Foundation
import CoreGraphics

public actor OnTaskDetector {
    private let client: ClaudeClient
    private var currentSession: Session?
    private var lastEvaluatedAt: Date?
    private let minInterval: TimeInterval = 2.5  // don't hammer the API faster than ~1 call per 2.5s

    public init(client: ClaudeClient = .shared) {
        self.client = client
    }

    public func attach(session: Session) {
        currentSession = session
        lastEvaluatedAt = nil
    }

    public func detach() {
        currentSession = nil
        lastEvaluatedAt = nil
    }

    public func evaluate(frame: CGImage) async -> OnTaskStatus {
        guard let session = currentSession else { return .onTask }
        guard await client.isConfigured() else { return .onTask }

        let now = Date()
        if let last = lastEvaluatedAt, now.timeIntervalSince(last) < minInterval {
            return .ambiguous  // skip frame, carry previous signal forward as ambiguous
        }
        lastEvaluatedAt = now

        do {
            let result = try await client.classify(
                image: frame,
                taskDescription: session.task,
                successCriteria: session.successCriteria
            )
            return result.status
        } catch {
            return .ambiguous
        }
    }
}
