import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// Watches consecutive off-task frames and fires friend-like callouts after a threshold.
@MainActor
public final class CalloutManager {
    public static let shared = CalloutManager()

    private var consecutiveOffTask = 0
    private var hasFiredForStreak = false
    private let threshold = 2  // frames before callout fires (~4-6 seconds at 1fps)

    /// Total callouts fired in the current session. Reset to 0 when reset() is called.
    public private(set) var calloutCount: Int = 0

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
    // Tracks the last fired callout so consecutive streaks never repeat the same message.
    private var lastFiredMessage: String?

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
        let candidates = Self.callouts.filter { $0 != lastFiredMessage }
        let message = (candidates.isEmpty ? Self.callouts : candidates).randomElement() ?? "focus."
        display(message)
    }

    /// Fires an immediate callout for a blocked app becoming frontmost (no threshold needed).
    public func fireAppCallout(_ message: String) {
        display(message)
    }

    private func display(_ message: String) {
        calloutCount += 1
        lastFiredMessage = message
        NotchState.shared.showCallout(message)
        // Cancel any pending auto-dismiss from a prior callout before starting a new one.
        autoDismissTask?.cancel()
        autoDismissTask = Task { @MainActor in
            do {
                try await Task.sleep(for: .seconds(8))
                NotchState.shared.clearCallout()
            } catch {
                // Task was cancelled — reset() was called or a new callout fired.
            }
        }
        #if canImport(AppKit)
        // Shout — a sharp alert sound so the user can't ignore drifting off.
        NSSound(named: "Sosumi")?.play()
        #endif
    }

    /// Resets streak counters and clears any active callout.
    /// Call this when a session ends or a new session starts so stale streak
    /// state from the prior session doesn't suppress the first callout.
    public func reset() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
        consecutiveOffTask = 0
        hasFiredForStreak = false
        lastFiredMessage = nil
        calloutCount = 0
        NotchState.shared.clearCallout()
    }
}
