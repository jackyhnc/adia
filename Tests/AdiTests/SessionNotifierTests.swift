import Testing
import Foundation
@testable import AdiCore
#if canImport(UserNotifications)
@preconcurrency import UserNotifications
#endif

// `sharedIsRegisteredAsNotificationDelegate` calls `UNUserNotificationCenter.current()`
// directly (to read back `.delegate`), which *crashes the whole process* (uncaught
// NSInternalInconsistencyException "bundleProxyForCurrentProcess is nil") when run
// from a binary that isn't a proper .app bundle — e.g. the `swift test` /
// `swiftpm-testing-helper` process used by CI and `swift test` from the command line.
// There's no way to catch this (it aborts via libc++abi before Swift error handling
// runs), so the whole suite is skipped there rather than risk one test taking down the
// process. (`SessionNotifier` itself guards its own `UNUserNotificationCenter` calls —
// see `SessionNotifier.canUseNotificationCenter` — so `.shared` alone is safe; this
// gate exists for the test that reaches past it to the framework directly.)
// `Bundle.main.bundleIdentifier` is reliably nil in that context and non-nil inside
// the real Adia.app.
private let runningInAppBundle: Bool = Bundle.main.bundleIdentifier != nil

@MainActor
@Suite(
    "SessionNotifier",
    .serialized,
    .enabled(if: runningInAppBundle, "UNUserNotificationCenter crashes the swift test process outside an app bundle")
)
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

    /// Verifies that tapping a notification banner expands the notch from its collapsed state.
    @Test func notificationTapExpandsNotchFromCollapsed() {
        NotchState.shared.collapse()
        SessionNotifier.shared.expandNotch()
        #expect(NotchState.shared.isExpanded)
    }

    /// Verifies that `expandNotch()` is idempotent — calling it while the notch
    /// is already expanded does not collapse or otherwise disturb it.
    @Test func notificationTapIsIdempotentWhenAlreadyExpanded() {
        NotchState.shared.expand()
        SessionNotifier.shared.expandNotch()
        #expect(NotchState.shared.isExpanded)
    }

    // MARK: - blockedAppHiddenBody(task:) — pure copy builder

    /// Verifies the body explains the situation by name when a task is set —
    /// users should never see a bare "get back to it" if Adia knows the task.
    @Test func blockedAppHiddenBodyMentionsTaskWhenPresent() {
        let body = SessionNotifier.blockedAppHiddenBody(task: "write essay")
        #expect(body.contains("write essay"))
    }

    /// Verifies the body falls back to a generic friend-like message when the
    /// session has no task description (e.g. a restored session edge case).
    @Test func blockedAppHiddenBodyFallsBackWhenTaskIsEmpty() {
        let body = SessionNotifier.blockedAppHiddenBody(task: "")
        #expect(!body.isEmpty)
        #expect(!body.contains("\"\""))
    }

    /// Verifies the copy stays in Adia's direct, friend-like voice (no corporate
    /// "this application has been blocked" phrasing).
    @Test func blockedAppHiddenBodyIsNotEmpty() {
        for task in ["", "submit ENGL 101 essay to Canvas", "read chapter 3"] {
            #expect(!SessionNotifier.blockedAppHiddenBody(task: task).isEmpty)
        }
    }

    /// Verifies the delegate responds to the `didReceive` selector so
    /// macOS will invoke it when the user taps a banner.
    @Test func delegateImplementsDidReceiveSelector() {
        let notifier = SessionNotifier.shared
        let sel = NSSelectorFromString("userNotificationCenter:didReceive:withCompletionHandler:")
        #expect(notifier.responds(to: sel))
    }
}
