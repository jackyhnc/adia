import Foundation
import CoreGraphics

extension String {
    func appendToFile(_ path: String) throws {
        if let fh = FileHandle(forWritingAtPath: path) {
            fh.seekToEndOfFile(); fh.write(Data(self.utf8)); fh.closeFile()
        } else {
            try self.write(toFile: path, atomically: false, encoding: .utf8)
        }
    }
}

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
            return lastStatus
        }

        // Only hop to MainActor to read the API key when we're about to make a call.
        guard await client.isConfigured() else { return .onTask }
        lastEvaluatedAt = now

        do {
            let result = try await client.classify(
                image: frame,
                taskDescription: session.task,
                successCriteria: session.successCriteria
            )
            try? "[\(Date())] classify status=\(result.status) conf=\(result.confidence) reason=\(result.reason)\n"
                .appendToFile("/tmp/adia_ai.log")
            lastStatus = result.status
            return result.status
        } catch {
            try? "[\(Date())] classify ERROR \(error)\n".appendToFile("/tmp/adia_ai.log")
            return lastStatus
        }
    }
}
