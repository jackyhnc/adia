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

    private override init() {
        super.init()
        #if canImport(UserNotifications)
        UNUserNotificationCenter.current().delegate = self
        #endif
    }

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

    /// Expands the notch panel. Called when the user taps a notification banner.
    /// Exposed as `internal` (not private) so unit tests can invoke it directly
    /// without needing a real `UNNotificationResponse`.
    func expandNotch() {
        NotchState.shared.expand()
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
