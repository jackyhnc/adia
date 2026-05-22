import Foundation

/// Watches consecutive off-task frames and fires friend-like callouts after a threshold.
@MainActor
public final class CalloutManager {
    public static let shared = CalloutManager()

    private var consecutiveOffTask = 0
    private var hasFiredForStreak = false
    private let threshold = 2  // frames before callout fires (~4-6 seconds at 1fps)

    private static let callouts: [String] = [
        "yo, what are you doing?",
        "this isn't your essay.",
        "stop.",
        "back to work.",
        "that's not why you're here.",
        "focus.",
        "you literally just started.",
        "seriously?",
        "get off that.",
        "c'mon.",
    ]

    private init() {}

    /// Call this with each new on-task classification.
    public func evaluate(_ status: OnTaskStatus) {
        switch status {
        case .offTask:
            consecutiveOffTask += 1
            if consecutiveOffTask >= threshold && !hasFiredForStreak {
                hasFiredForStreak = true
                fire()
            }
        case .onTask:
            reset()
        case .ambiguous:
            break
        }
    }

    private func fire() {
        let message = Self.callouts.randomElement() ?? "focus."
        NotchState.shared.showCallout(message)
        // Auto-dismiss after 8 seconds if the user hasn't recovered to on-task yet.
        Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(8))
            guard let self, self.hasFiredForStreak else { return }
            NotchState.shared.clearCallout()
        }
    }

    /// Resets streak counters and clears any active callout.
    /// Call this when a session ends or a new session starts so stale streak
    /// state from the prior session doesn't suppress the first callout.
    public func reset() {
        consecutiveOffTask = 0
        hasFiredForStreak = false
        NotchState.shared.clearCallout()
    }
}
