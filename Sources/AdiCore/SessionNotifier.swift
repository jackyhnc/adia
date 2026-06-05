import Foundation
#if canImport(UserNotifications)
@preconcurrency import UserNotifications
#endif

/// Posts macOS system notifications for key session lifecycle events.
/// On non-macOS platforms all methods are no-ops.
@MainActor
public final class SessionNotifier {
    public static let shared = SessionNotifier()

    private init() {}

    /// Requests system notification permission once. Safe to call multiple times.
    public func requestPermission() {
        #if canImport(UserNotifications)
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

    /// Fires a "Session restored" banner when a crash-recovered session is re-activated on launch.
    public func sendSessionRestored(task: String) {
        #if canImport(UserNotifications)
        let content = UNMutableNotificationContent()
        content.title = "Session restored"
        content.body = task.isEmpty ? "Your focus session is still active." : task
        schedule(content, id: "adia.session.restored")
        #endif
    }

    #if canImport(UserNotifications)
    private func schedule(_ content: UNMutableNotificationContent, id: String) {
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { print("[SessionNotifier] notification error: \(error)") }
        }
    }
    #endif
}
