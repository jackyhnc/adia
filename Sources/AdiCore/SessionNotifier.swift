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

    // MARK: - Daily goal notifications

    /// Pure body-text builder for `sendDailyGoalAchieved`, exposed so tests can verify
    /// the friend-like copy without needing a real `UNNotificationContent`.
    nonisolated public static func dailyGoalAchievedBody(goalMinutes: Int) -> String {
        switch goalMinutes {
        case 60:  return "an hour of focus today. goal's done."
        case 120: return "two hours of focus today. goal's done."
        default:  return "\(goalMinutes) minutes of focus today. goal's done."
        }
    }

    /// Fires a "daily goal ✓" banner the first time the user's today-total focus minutes
    /// crosses the configured daily goal. Safe to call multiple times — only the first
    /// call per calendar day schedules a notification.
    public func sendDailyGoalAchieved(goalMinutes: Int) {
        #if canImport(UserNotifications)
        let content = UNMutableNotificationContent()
        content.title = "daily goal ✓"
        content.body = Self.dailyGoalAchievedBody(goalMinutes: goalMinutes)
        content.sound = .default
        schedule(content, id: "adia.daily.goal_achieved")
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

    // MARK: - Streak broken notifications

    /// Friend-like re-engagement copy when a streak is broken.
    /// Direct but not punishing — treats the user as an adult who can pick it back up.
    nonisolated public static func streakBrokenBody(previousStreak: Int) -> String {
        switch previousStreak {
        case 7:  return "you had a week going. don't let one miss end it."
        case 14: return "14 days down. pick it back up — today counts."
        case 21: return "21-day streak, gone. you know how to build one. do it again."
        case 30: return "30 days. one break doesn't erase that. start fresh today."
        default: return "you had a \(previousStreak)-day streak going. start the next one today."
        }
    }

    /// Pattern-aware re-engagement copy for when the same milestone streak breaks a second or
    /// third+ time. Tone shifts from "you can pick it back up" to "here's what to actually change."
    /// `breakCount` is the number of times this day-count streak has now been broken (≥ 2).
    nonisolated public static func streakRepeatBrokenBody(days: Int, breakCount: Int) -> String {
        switch days {
        case 7:
            return breakCount >= 3
                ? "the 7-day wall keeps showing up. figure out which day trips you and change that day."
                : "7-day streak again. you know the pattern — find the day that breaks it."
        case 14:
            return breakCount >= 3
                ? "14 days three times. weeks 1–2 aren't the problem. what shifts in week 3?"
                : "you've had a 14-day streak before. something specific ends it. find that thing."
        case 21:
            return breakCount >= 3
                ? "21 days keeps getting close. the last week needs something different."
                : "21 days again. you know how to start one. figure out what stops week 3."
        case 30:
            return breakCount >= 3
                ? "multiple times near 30 days. you're capable — something specific is in the way. what is it?"
                : "you've almost hit 30 before. you're not unlucky. find the one thing and fix it."
        default:
            return breakCount >= 3
                ? "same pattern, again. this isn't random. figure out what to change and change it."
                : "you've broken a \(days)-day streak before. you know what gets in the way now."
        }
    }

    /// Fires a re-engagement banner when the user misses a day after a ≥7-day streak.
    /// Increments the persistent break count for this day total and selects pattern-aware
    /// copy if this milestone has been broken before.
    /// Uses a stable identifier so rapid launches don't stack banners.
    public func sendStreakBroken(previousStreak: Int) {
        #if canImport(UserNotifications)
        let breakCount = SettingsStore.shared.incrementStreakBreak(days: previousStreak)
        let content = UNMutableNotificationContent()
        content.title = "streak ended at \(previousStreak) days"
        content.body = breakCount >= 2
            ? Self.streakRepeatBrokenBody(days: previousStreak, breakCount: breakCount)
            : Self.streakBrokenBody(previousStreak: previousStreak)
        content.sound = .default
        schedule(content, id: "adia.streak.broken")
        #endif
    }

    // MARK: - Morning nudge

    private static let morningNudgeID = "adia.morning.nudge"
    private static let lastScheduledNudgeDateKey = "adia.lastScheduledMorningNudgeDate"

    /// Full pool of morning nudge notification titles. All entries are short, direct, and
    /// friend-like. Exposed so tests can verify every variant without relying on random selection.
    nonisolated public static let morningNudgeTitles: [String] = [
        "haven't started yet",
        "no session today",
        "day's not started",
        "still at zero",
        "nothing yet today",
        "today's untouched",
        "no work yet today",
        "zero sessions so far",
        "day's still empty",
    ]

    /// Returns a random morning nudge title from `morningNudgeTitles`.
    nonisolated public static func morningNudgeTitle() -> String {
        morningNudgeTitles.randomElement() ?? morningNudgeTitles[0]
    }

    /// Full pool of morning nudge messages. All entries pass the same tone constraints:
    /// friend-like, action-oriented, no corporate/punishing language, no all-caps shouting.
    /// Exposed so tests can verify every variant without relying on random selection.
    nonisolated public static let morningNudgeMessages: [String] = [
        "no sessions yet today. open adia and pick a task.",
        "haven't started yet. pick something and begin.",
        "today's at zero sessions. what are you working on?",
        "still no focus session today. open adia.",
        "day's ticking. no session yet — pick a task.",
        "you haven't started yet. whatever it is, begin now.",
        "nothing yet today. open adia and get going.",
        "zero sessions today. open adia and start one.",
        "today's still empty. pick a task and get moving.",
    ]

    /// Returns a random morning nudge message from `morningNudgeMessages`.
    /// Exposed as a pure function so tests can verify tone without a notification center.
    nonisolated public static func morningNudgeBody() -> String {
        morningNudgeMessages.randomElement() ?? morningNudgeMessages[0]
    }

    /// Schedules a one-time morning nudge notification for the next occurrence of `hour`.
    /// Replaces any existing pending morning nudge request with the same identifier.
    /// When `hour` has not yet passed today, the notification fires today; when it has,
    /// it fires tomorrow — callers should guard with the current hour before calling (see
    /// `scheduleMorningNudgeIfNeeded`).
    public func scheduleMorningNudge(hour: Int) {
        #if canImport(UserNotifications)
        guard Self.canUseNotificationCenter else { return }
        let title = Self.morningNudgeTitle()
        var components = DateComponents()
        components.hour = hour
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = Self.morningNudgeBody()
        content.sound = .default
        let request = UNNotificationRequest(identifier: Self.morningNudgeID, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) { error in
            if let error { AppLogger.error("notifier.morning_nudge_schedule_failed", ["error": "\(error)"]) }
        }
        AppLogger.info("notifier.morning_nudge_scheduled", ["hour": "\(hour)", "title": title])
        #endif
    }

    /// Cancels any pending morning nudge notification. Safe to call multiple times — no-op when
    /// no request is pending.
    public func cancelMorningNudge() {
        #if canImport(UserNotifications)
        guard Self.canUseNotificationCenter else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.morningNudgeID])
        #endif
    }

    /// Cancels any existing morning nudge, clears the per-day gate, then reschedules.
    /// Call after the user changes the nudge hour in Settings so the new time takes effect immediately.
    public func rescheduleMorningNudge() {
        cancelMorningNudge()
        UserDefaults.standard.removeObject(forKey: Self.lastScheduledNudgeDateKey)
        scheduleMorningNudgeIfNeeded()
    }

    /// Schedules a morning nudge for today if all of the following hold:
    /// 1. `morningNudgeEnabled` is true in SettingsStore.
    /// 2. Today's nudge has not already been scheduled (gated by a UserDefaults date key).
    /// 3. The configured nudge hour has not yet passed for today.
    ///
    /// Called on app launch from `SessionManager.restoreIfNeeded()` so the nudge is always
    /// armed once per calendar day as long as the app starts before the nudge hour.
    public func scheduleMorningNudgeIfNeeded() {
        guard SettingsStore.shared.morningNudgeEnabled else { return }
        let nudgeHour = SettingsStore.shared.morningNudgeHour
        let todayStr = Self.nudgeTodayDateString()
        guard UserDefaults.standard.string(forKey: Self.lastScheduledNudgeDateKey) != todayStr else { return }
        let currentHour = Calendar.current.component(.hour, from: Date())
        guard currentHour < nudgeHour else { return }
        UserDefaults.standard.set(todayStr, forKey: Self.lastScheduledNudgeDateKey)
        scheduleMorningNudge(hour: nudgeHour)
    }

    /// "yyyy-MM-dd" string for today. Duplicates `SessionManager.todayDateString()` to avoid
    /// a cross-type internal dependency between two unrelated @MainActor classes.
    private nonisolated static func nudgeTodayDateString() -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.locale = Locale(identifier: "en_US_POSIX")
        return fmt.string(from: Date())
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
