import Testing
import Foundation
@testable import AdiCore
#if canImport(UserNotifications)
@preconcurrency import UserNotifications
#endif

@MainActor
@Suite("SessionNotifier", .serialized)
struct SessionNotifierTests {

    /// Verifies that accessing `SessionNotifier.shared` registers it as the
    /// `UNUserNotificationCenter` delegate, which is required for foreground banner delivery.
    @Test func sharedIsRegisteredAsNotificationDelegate() {
        #if canImport(UserNotifications)
        let notifier = SessionNotifier.shared
        let delegate = UNUserNotificationCenter.current().delegate
        #expect((delegate as AnyObject?) === (notifier as AnyObject))
        #endif
    }

    /// Verifies that `SessionNotifier` declares `UNUserNotificationCenterDelegate` conformance
    /// so macOS will invoke `willPresent` while the app is frontmost.
    @Test func conformsToUNUserNotificationCenterDelegate() {
        #if canImport(UserNotifications)
        #expect(SessionNotifier.shared is any UNUserNotificationCenterDelegate)
        #endif
    }

    /// Verifies the foreground presentation options include `.banner` and `.sound`
    /// so notifications are visible even when Adia is the active application.
    @Test func foregroundPresentationOptionsIncludeBannerAndSound() {
        #if canImport(UserNotifications)
        let opts = SessionNotifier.foregroundPresentationOptions
        #expect(opts.contains(.banner))
        #expect(opts.contains(.sound))
        #endif
    }
}
