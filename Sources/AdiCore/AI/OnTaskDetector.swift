import Foundation
import CoreGraphics

// Placeholder — full implementation in On-task Detection task.
public actor OnTaskDetector {
    private let client: ClaudeClient
    private var currentSession: Session?

    public init(client: ClaudeClient = .shared) {
        self.client = client
    }

    public func attach(session: Session) {
        currentSession = session
    }

    public func detach() {
        currentSession = nil
    }

    public func evaluate(frame: CGImage) async -> OnTaskStatus {
        guard let session = currentSession else { return .onTask }
        guard await client.isConfigured() else { return .onTask }
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
