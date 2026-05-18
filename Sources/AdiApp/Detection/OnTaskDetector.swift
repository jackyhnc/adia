import Foundation
import AdiCore

/// Runs a continuous detection loop: capture → classify → publish.
final class OnTaskDetector: @unchecked Sendable {
    private let client: any ClaudeClientProtocol
    private let captureManager: ScreenCaptureManager
    private var detectionTask: Task<Void, Never>?

    /// Called on the main actor whenever a new classification arrives.
    var onClassification: @MainActor @Sendable (OnTaskClassification) -> Void = { _ in }

    init(client: any ClaudeClientProtocol, captureManager: ScreenCaptureManager) {
        self.client = client
        self.captureManager = captureManager
    }

    func start(session: Session) {
        let client = self.client
        let captureManager = self.captureManager
        let task = session.task
        let callback = onClassification

        detectionTask = Task.detached(priority: .utility) {
            do {
                let frames = try await captureManager.startCapture()
                for await frame in frames {
                    guard !Task.isCancelled else { break }
                    guard let data = frame.pngData() else { continue }

                    do {
                        let classification = try await client.classify(image: data, task: task)
                        await MainActor.run { callback(classification) }
                    } catch {
                        // Skip frame on API error; don't crash the loop
                    }
                }
            } catch {
                // Capture setup failed (e.g. permission denied) — stop silently
            }
        }
    }

    func stop() {
        detectionTask?.cancel()
        detectionTask = nil
        Task.detached { [captureManager] in
            try? await captureManager.stopCapture()
        }
    }
}
