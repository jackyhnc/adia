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

    // Stored reference so a new streak or reset() cancels a pending auto-dismiss.
    // Without this, two consecutive streaks produce two tasks; the first task's
    // 8s timer fires mid-second-streak and clears the wrong callout.
    private var autoDismissTask: Task<Void, Never>?

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
        // Cancel any pending auto-dismiss from a prior streak before starting a new one.
        autoDismissTask?.cancel()
        autoDismissTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(8))
                NotchState.shared.clearCallout()
            } catch {
                // Task was cancelled — reset() was called or a new streak started.
            }
        }
    }

    /// Resets streak counters and clears any active callout.
    /// Call this when a session ends or a new session starts so stale streak
    /// state from the prior session doesn't suppress the first callout.
    public func reset() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
        consecutiveOffTask = 0
        hasFiredForStreak = false
        NotchState.shared.clearCallout()
    }
}
