import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// Watches consecutive off-task frames and fires friend-like callouts after a threshold.
/// Messages escalate in intensity across three tiers as the session callout count grows.
@MainActor
public final class CalloutManager {
    public static let shared = CalloutManager()

    private var consecutiveOffTask = 0
    private var hasFiredForStreak = false
    private var hasEscalatedForStreak = false
    private let threshold = 2  // frames before the notch callout fires (~4-6s at 0.5fps)
    // If the callout is ignored and the streak continues, escalate to a full-screen
    // takeover. Two more off-task frames past the callout (~another 4-6s).
    private let escalateThreshold = 4

    /// Total callouts fired in the current session. Only zeroed by reset() (session start/end),
    /// not by on-task recovery — used for tier escalation across the session.
    public private(set) var calloutCount: Int = 0

    // MARK: - Tiered message pools

    // Tier 1 (callouts 1–2): friendly but direct
    private static let tier1Callouts: [String] = [
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

    // Tier 2 (callouts 3–4): noticeably stronger
    private static let tier2Callouts: [String] = [
        "this is the third time.",
        "stop procrastinating.",
        "you keep getting distracted.",
        "get back to work. now.",
        "we're not playing around.",
        "close that. open your work.",
        "still?",
        "what are you doing to yourself.",
    ]

    // Tier 3 (callout 5+): harshest, no-nonsense
    private static let tier3Callouts: [String] = [
        "STOP.",
        "you're wasting your own time.",
        "every minute here hurts you.",
        "you asked me to hold you accountable.",
        "the work is not going to do itself.",
        "put it down. right now.",
        "I am not letting this slide.",
    ]

    // Stored reference so a new streak or reset() cancels a pending auto-dismiss.
    // Without this, two consecutive streaks produce two tasks; the first task's
    // dismiss timer fires mid-second-streak and clears the wrong callout.
    private var autoDismissTask: Task<Void, Never>?
    // Tracks the last fired callout so consecutive streaks never repeat the same message.
    private var lastFiredMessage: String?

    private init() {}

    // MARK: - Public interface

    /// Call this with each new on-task classification.
    public func evaluate(_ status: OnTaskStatus) {
        switch status {
        case .offTask:
            consecutiveOffTask += 1
            if consecutiveOffTask >= threshold && !hasFiredForStreak {
                hasFiredForStreak = true
                fire()
            }
            if consecutiveOffTask >= escalateThreshold && !hasEscalatedForStreak {
                hasEscalatedForStreak = true
                escalate()
            }
        case .onTask:
            // Only reset the per-streak counters; calloutCount is session-level
            // and must survive recovery so tier escalation works across the session.
            resetStreak()
        case .ambiguous:
            break
        }
    }

    /// Fires an immediate callout for a blocked app becoming frontmost (no threshold needed).
    public func fireAppCallout(_ message: String) {
        display(message, tier: currentTier())
    }

    // MARK: - Escalation logic

    /// Returns 1, 2, or 3 based on callouts already fired this session.
    /// Called before calloutCount is incremented, so 0 = first callout.
    internal func currentTier() -> Int {
        if calloutCount < 2 { return 1 }
        if calloutCount < 4 { return 2 }
        return 3
    }

    /// Auto-dismiss delay: longer at higher tiers so the user can't easily ignore it.
    nonisolated internal static func dismissDelay(for tier: Int) -> Duration {
        switch tier {
        case 1: return .seconds(8)
        case 2: return .seconds(12)
        default: return .seconds(20)
        }
    }

    /// Escalates an ignored callout into the full-screen takeover.
    private func escalate() {
        let message = lastFiredMessage ?? "back to work."
        NotchState.shared.showBlocker(message)
        #if canImport(AppKit)
        NSSound(named: "Sosumi")?.play()
        #endif
    }

    /// Called by the takeover UI when the user dismisses it. We intentionally do NOT
    /// clear `hasEscalatedForStreak`, so dismissing doesn't immediately re-throw the
    /// takeover while they're still on the same off-task streak — it re-arms only
    /// after they go back on task (which calls reset()).
    public func dismissBlocker() {
        NotchState.shared.clearBlocker()
    }

    /// Resets the current off-task streak without touching the session-level calloutCount.
    /// Called on on-task recovery so a new streak can fire again, but tier escalation
    /// persists because calloutCount is preserved.
    private func resetStreak() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
        consecutiveOffTask = 0
        hasFiredForStreak = false
        hasEscalatedForStreak = false
        NotchState.shared.clearCallout()
        NotchState.shared.clearBlocker()
        // lastFiredMessage intentionally preserved: dedup works across streaks within a session.
    }

    /// Full session reset — zeroes calloutCount and clears all state.
    /// Called by SessionManager.activate() at session start and by tests between sessions.
    public func reset() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
        consecutiveOffTask = 0
        hasFiredForStreak = false
        hasEscalatedForStreak = false
        lastFiredMessage = nil
        calloutCount = 0
        NotchState.shared.clearCallout()
        NotchState.shared.clearBlocker()
    }

    // MARK: - Private

    private func fire() {
        let tier = currentTier()
        let pool: [String]
        switch tier {
        case 1: pool = Self.tier1Callouts
        case 2: pool = Self.tier2Callouts
        default: pool = Self.tier3Callouts
        }
        let candidates = pool.filter { $0 != lastFiredMessage }
        let message = (candidates.isEmpty ? pool : candidates).randomElement() ?? "focus."
        display(message, tier: tier)
    }

    private func display(_ message: String, tier: Int = 1) {
        calloutCount += 1
        lastFiredMessage = message
        NotchState.shared.showCallout(message, tier: tier)
        // Cancel any pending auto-dismiss from a prior callout before starting a new one.
        autoDismissTask?.cancel()
        autoDismissTask = Task { @MainActor in
            do {
                try await Task.sleep(for: Self.dismissDelay(for: tier))
                NotchState.shared.clearCallout()
            } catch {
                // Task was cancelled — resetStreak()/reset() was called or a new callout fired.
            }
        }
        #if canImport(AppKit)
        switch tier {
        case 2: NSSound(named: "Basso")?.play()   // deeper thud — unmistakably escalated
        case 3: NSSound(named: "Funk")?.play()    // most alarming — can't be ignored
        default: NSSound(named: "Sosumi")?.play()
        }
        #endif
    }
}
