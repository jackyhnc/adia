import Foundation
#if canImport(UserNotifications)
@preconcurrency import UserNotifications
#endif
#if canImport(AppKit)
import AppKit
#endif

/// Posts macOS system notifications for key session lifecycle events.
/// On non-macOS platforms all methods are no-ops.
///
/// Registers itself as `UNUserNotificationCenter.delegate` so banners fire
/// even when Adia is the frontmost application (macOS suppresses them otherwise).
@MainActor
public final class SessionNotifier: NSObject {
    public static let shared = SessionNotifier()

    /// `UNUserNotificationCenter.current()` *crashes the whole process* (uncaught
    /// `NSInternalInconsistencyException`, "bundleProxyForCurrentProcess is nil") when
    /// called from a binary that isn't a proper `.app` bundle — e.g. `swift test` /
    /// `swiftpm-testing-helper`, used by CI and `swift test` from the command line.
    /// It's an Objective-C exception that aborts via `libc++abi` before Swift error
    /// handling runs, so it cannot be caught — the only option is to never call it
    /// outside a real app bundle. `Bundle.main.bundleIdentifier` is reliably nil in
    /// that context and non-nil inside the real Adia.app.
    private static let canUseNotificationCenter: Bool = Bundle.main.bundleIdentifier != nil

    private override init() {
        super.init()
        #if canImport(UserNotifications)
        guard Self.canUseNotificationCenter else { return }
        UNUserNotificationCenter.current().delegate = self
        #endif
    }

    /// Requests system notification permission once. Safe to call multiple times.
    public func requestPermission() {
        #if canImport(UserNotifications)
        guard Self.canUseNotificationCenter else { return }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        #endif
    }

    /// Fires a "Session complete ✓" banner when the user's task is verified by Claude.
    public func sendSessionComplete(task: String) {
        #if canImport(UserNotifications)
        let content = UNMutableNotificationContent()
        content.title = "Session complete ✓"
        content.body = task.isEmpty ? "Great work." : task
        content.sound = .default
        schedule(content, id: "adia.session.complete")
        #endif
    }

    /// Fires a "Time's up" banner when the session's target duration elapses.
    public func sendTimerExpired(task: String) {
        #if canImport(UserNotifications)
        let content = UNMutableNotificationContent()
        content.title = "Time's up ⏰"
        content.body = task.isEmpty ? "Open Adia to verify your work." : "Open Adia to verify: \(task)"
        content.sound = .default
        schedule(content, id: "adia.session.timer_expired")
        #endif
    }

    /// Fires a banner explaining why a blocked app was force-hidden, so the user
    /// understands what happened instead of just seeing an app vanish mid-use.
    /// Uses a stable identifier so rapid re-activations of the same app replace
    /// the previous banner rather than stacking up a pile of notifications.
    public func sendBlockedAppHidden(appName: String, task: String) {
        #if canImport(UserNotifications)
        let content = UNMutableNotificationContent()
        content.title = "closed \(appName)"
        content.body = Self.blockedAppHiddenBody(task: task)
        content.sound = .default
        schedule(content, id: "adia.session.blocked_app_hidden")
        #endif
    }

    /// Pure body-text builder for `sendBlockedAppHidden`, exposed so tests can
    /// verify the friend-like copy without needing a real `UNNotificationContent`.
    static func blockedAppHiddenBody(task: String) -> String {
        task.isEmpty
            ? "that's not what you're working on. get back to it."
            : "that's not \"\(task)\". get back to it."
    }

    /// Fires a "Session restored" banner when a crash-recovered session is re-activated on launch.
    public func sendSessionRestored(task: String) {
        #if canImport(UserNotifications)
        let content = UNMutableNotificationContent()
        content.title = "Session restored"
        content.body = task.isEmpty ? "Your focus session is still active." : task
        schedule(content, id: "adia.session.restored")
        #endif
    }

    /// Fires a banner when screen capture stops unexpectedly and automatic recovery fails.
    public func sendCaptureStreamLost(task: String) {
        #if canImport(UserNotifications)
        let content = UNMutableNotificationContent()
        content.title = "Screen recording lost"
        content.body = task.isEmpty
            ? "Session paused — check Screen Recording permission and resume."
            : "Session paused — re-enable Screen Recording to continue: \(task)"
        content.sound = .default
        schedule(content, id: "adia.session.capture_lost")
        #endif
    }

    // MARK: - Streak milestone notifications

    /// Calendar days at which the app celebrates a consecutive-day focus streak.
    nonisolated public static let streakMilestoneDays: Set<Int> = [3, 7, 14, 21, 30]

    /// If `streak` is a recognized milestone, returns that milestone value; otherwise nil.
    nonisolated public static func streakMilestoneValue(_ streak: Int) -> Int? {
        streakMilestoneDays.contains(streak) ? streak : nil
    }

    /// Direct, friend-like copy for each streak milestone.
    /// Exposed for unit tests — all text must match Adia's informal tone.
    nonisolated public static func streakMilestoneBody(days: Int) -> String {
        switch days {
        case 3:  return "3 days in a row. the streak is on."
        case 7:  return "one full week. you're building something."
        case 14: return "two weeks straight. momentum is real."
        case 21: return "21 days. habits don't form by accident."
        case 30: return "30 days. you locked in for a month."
        default: return "\(days) days in a row. keep going."
        }
    }

    /// Fires a streak milestone banner celebrating a consecutive-day focus achievement.
    public func sendStreakMilestone(days: Int) {
        #if canImport(UserNotifications)
        let content = UNMutableNotificationContent()
        content.title = "\(days)-day streak 🔥"
        content.body = Self.streakMilestoneBody(days: days)
        content.sound = .default
        schedule(content, id: "adia.streak.milestone.\(days)")
        #endif
    }

    /// Expands the notch panel. Called when the user taps a notification banner.
    /// Exposed as `internal` (not private) so unit tests can invoke it directly
    /// without needing a real `UNNotificationResponse`.
    func expandNotch() {
        NotchState.shared.expand()
    }

    #if canImport(UserNotifications)
    private func schedule(_ content: UNMutableNotificationContent, id: String) {
        guard Self.canUseNotificationCenter else { return }
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { AppLogger.error("notifier.schedule_failed", ["error": "\(error)"]) }
        }
    }
    #endif
}

// MARK: - UNUserNotificationCenterDelegate

#if canImport(UserNotifications)
extension SessionNotifier: UNUserNotificationCenterDelegate {
    /// Options returned to the system when a notification fires while Adia is frontmost.
    /// Exposed as a constant so tests can verify the value without needing a real `UNNotification`.
    /// `nonisolated` so the `nonisolated` `willPresent` method can read it without an actor hop.
    nonisolated public static let foregroundPresentationOptions: UNNotificationPresentationOptions = [.banner, .sound]

    /// Called when a notification is about to be presented while the app is frontmost.
    /// Returning `.banner` and `.sound` overrides macOS's default suppression so
    /// Adia's session-complete and session-restored banners always appear.
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler(SessionNotifier.foregroundPresentationOptions)
    }

    /// Called when the user taps an Adia notification banner.
    /// Brings the app to the front and expands the notch so the user can
    /// immediately see the current session state without hunting for the window.
    nonisolated public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        Task { @MainActor in
            SessionNotifier.shared.expandNotch()
            #if canImport(AppKit)
            NSApp.activate(ignoringOtherApps: true)
            #endif
        }
        completionHandler()
    }
}
#endif
