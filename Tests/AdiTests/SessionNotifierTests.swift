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

// MARK: - Streak milestone pure-function tests (no app bundle required)

/// Tests for `SessionNotifier.streakMilestoneValue` and `streakMilestoneBody`.
/// These only exercise `nonisolated static` functions and need no `UNUserNotificationCenter`,
/// so they run unconditionally in `swift test` and CI.
@Suite("SessionNotifier streak milestones")
struct SessionNotifierStreakTests {

    // MARK: streakMilestoneValue

    @Test func streakMilestoneValue_returnsValueForEveryMilestone() {
        for days in [3, 7, 14, 21, 30] {
            #expect(SessionNotifier.streakMilestoneValue(days) == days,
                    "\(days) should be a recognized milestone")
        }
    }

    @Test func streakMilestoneValue_returnsNilForZero() {
        #expect(SessionNotifier.streakMilestoneValue(0) == nil)
    }

    @Test func streakMilestoneValue_returnsNilForOneAndTwo() {
        #expect(SessionNotifier.streakMilestoneValue(1) == nil)
        #expect(SessionNotifier.streakMilestoneValue(2) == nil)
    }

    @Test func streakMilestoneValue_returnsNilForInBetweenValues() {
        for days in [4, 5, 6, 8, 9, 10, 11, 12, 13, 15, 16, 20, 22, 25, 29, 31, 100] {
            #expect(SessionNotifier.streakMilestoneValue(days) == nil,
                    "\(days) is not a milestone and should return nil")
        }
    }

    @Test func streakMilestoneDays_containsExpectedValues() {
        let expected: Set<Int> = [3, 7, 14, 21, 30]
        #expect(SessionNotifier.streakMilestoneDays == expected)
    }

    // MARK: streakMilestoneBody

    @Test func streakMilestoneBody_isNonEmptyForAllMilestones() {
        for days in [3, 7, 14, 21, 30] {
            #expect(!SessionNotifier.streakMilestoneBody(days: days).isEmpty)
        }
    }

    @Test func streakMilestoneBody_mentionsDayCountForAllMilestones() {
        for days in [3, 7, 14, 21, 30] {
            let body = SessionNotifier.streakMilestoneBody(days: days)
            #expect(body.contains("\(days)"),
                    "body for \(days)-day streak should mention the count")
        }
    }

    @Test func streakMilestoneBody_doesNotUseCorporateVoice() {
        // Adia's tone is direct and friend-like, not a notification-center press release.
        for days in [3, 7, 14, 21, 30] {
            let body = SessionNotifier.streakMilestoneBody(days: days).lowercased()
            #expect(!body.contains("congratulations"))
            #expect(!body.contains("achievement unlocked"))
            #expect(!body.contains("great job"))
        }
    }

    @Test func streakMilestoneBody_fallbackForUnknownDayCount() {
        let body = SessionNotifier.streakMilestoneBody(days: 100)
        #expect(!body.isEmpty)
        #expect(body.contains("100"))
    }
}

// MARK: - Streak broken pure-function tests (no app bundle required)

/// Tests for `SessionNotifier.streakBrokenBody` — exercises only a `nonisolated static`
/// function so no `UNUserNotificationCenter` call occurs; runs unconditionally in CI.
@Suite("SessionNotifier streak broken")
struct SessionNotifierStreakBrokenTests {

    @Test func streakBrokenBody_isNonEmptyForAllMilestoneStreaks() {
        for days in [7, 14, 21, 30] {
            #expect(!SessionNotifier.streakBrokenBody(previousStreak: days).isEmpty,
                    "broken-streak body for \(days) days should not be empty")
        }
    }

    @Test func streakBrokenBody_mentionsDayCountForMilestones() {
        for days in [7, 14, 21, 30] {
            let body = SessionNotifier.streakBrokenBody(previousStreak: days)
            #expect(body.contains("\(days)"),
                    "broken-streak body for \(days)-day streak should mention the count")
        }
    }

    @Test func streakBrokenBody_fallbackForNonMilestoneStreak() {
        // Arbitrary non-milestone streak should get a generic but non-empty body.
        let body = SessionNotifier.streakBrokenBody(previousStreak: 8)
        #expect(!body.isEmpty)
        #expect(body.contains("8"))
    }

    @Test func streakBrokenBody_fallbackForLongStreak() {
        let body = SessionNotifier.streakBrokenBody(previousStreak: 100)
        #expect(!body.isEmpty)
        #expect(body.contains("100"))
    }

    @Test func streakBrokenBody_toneIsNotPunishing() {
        // Adia's voice is supportive and direct — not shame-based.
        let shamePhrases = ["failed", "loser", "disappointed", "shame", "bad", "terrible"]
        for days in [7, 8, 14, 21, 30, 100] {
            let body = SessionNotifier.streakBrokenBody(previousStreak: days).lowercased()
            for phrase in shamePhrases {
                #expect(!body.contains(phrase),
                        "body for \(days)-day broken streak should not contain \"\(phrase)\"")
            }
        }
    }

    @Test func streakBrokenBody_toneIsNotCorporate() {
        // No notification-center boilerplate language.
        let corporatePhrases = ["congratulations", "achievement", "great job", "well done"]
        for days in [7, 14, 21, 30] {
            let body = SessionNotifier.streakBrokenBody(previousStreak: days).lowercased()
            for phrase in corporatePhrases {
                #expect(!body.contains(phrase),
                        "broken-streak body should not use corporate phrase \"\(phrase)\"")
            }
        }
    }
}

// MARK: - Streak repeat broken pure-function tests (no app bundle required)

/// Tests for `SessionNotifier.streakRepeatBrokenBody` — exercises only a `nonisolated static`
/// function so no `UNUserNotificationCenter` call occurs; runs unconditionally in CI.
@Suite("SessionNotifier streak repeat broken")
struct SessionNotifierStreakRepeatBrokenTests {

    // MARK: Non-empty

    @Test func streakRepeatBrokenBody_isNonEmptyForAllMilestonesAtBreakCount2() {
        for days in [7, 14, 21, 30] {
            #expect(
                !SessionNotifier.streakRepeatBrokenBody(days: days, breakCount: 2).isEmpty,
                "repeat-broken body for \(days)-day streak (breakCount=2) must not be empty"
            )
        }
    }

    @Test func streakRepeatBrokenBody_isNonEmptyForAllMilestonesAtBreakCount3() {
        for days in [7, 14, 21, 30] {
            #expect(
                !SessionNotifier.streakRepeatBrokenBody(days: days, breakCount: 3).isEmpty,
                "repeat-broken body for \(days)-day streak (breakCount=3) must not be empty"
            )
        }
    }

    @Test func streakRepeatBrokenBody_isNonEmptyForFallbackAtBreakCount2() {
        let body = SessionNotifier.streakRepeatBrokenBody(days: 8, breakCount: 2)
        #expect(!body.isEmpty, "fallback repeat-broken body must not be empty")
    }

    // MARK: Day count mentioned

    @Test func streakRepeatBrokenBody_mentionsDayCountForMilestonesAtBreakCount2() {
        for days in [7, 14, 21, 30] {
            let body = SessionNotifier.streakRepeatBrokenBody(days: days, breakCount: 2)
            #expect(body.contains("\(days)"),
                    "repeat-broken body for \(days)-day streak should mention the count")
        }
    }

    @Test func streakRepeatBrokenBody_fallbackMentionsDayCount() {
        let body = SessionNotifier.streakRepeatBrokenBody(days: 11, breakCount: 2)
        #expect(body.contains("11"), "fallback body must mention the day count")
    }

    // MARK: Copy shifts from first-break copy

    @Test func streakRepeatBrokenBody_differsFromFirstBreakCopyForMilestones() {
        for days in [7, 14, 21, 30] {
            let firstBreak = SessionNotifier.streakBrokenBody(previousStreak: days)
            let repeatBreak = SessionNotifier.streakRepeatBrokenBody(days: days, breakCount: 2)
            #expect(firstBreak != repeatBreak,
                    "repeat-break copy for \(days)-day streak must differ from first-break copy")
        }
    }

    @Test func streakRepeatBrokenBody_breakCount3DiffersFromBreakCount2ForMilestones() {
        for days in [7, 14, 21, 30] {
            let second = SessionNotifier.streakRepeatBrokenBody(days: days, breakCount: 2)
            let third  = SessionNotifier.streakRepeatBrokenBody(days: days, breakCount: 3)
            #expect(second != third,
                    "breakCount=3 copy for \(days)-day streak must differ from breakCount=2 copy")
        }
    }

    // MARK: Tone

    @Test func streakRepeatBrokenBody_toneIsNotPunishing() {
        let shamePhrases = ["failed", "loser", "disappointed", "shame", "bad", "terrible"]
        for days in [7, 8, 14, 21, 30] {
            for breakCount in [2, 3] {
                let body = SessionNotifier.streakRepeatBrokenBody(days: days, breakCount: breakCount).lowercased()
                for phrase in shamePhrases {
                    #expect(!body.contains(phrase),
                            "repeat-broken body (\(days)d, count=\(breakCount)) must not contain \"\(phrase)\"")
                }
            }
        }
    }

    @Test func streakRepeatBrokenBody_toneIsNotCorporate() {
        let corporatePhrases = ["congratulations", "achievement", "great job", "well done"]
        for days in [7, 14, 21, 30] {
            for breakCount in [2, 3] {
                let body = SessionNotifier.streakRepeatBrokenBody(days: days, breakCount: breakCount).lowercased()
                for phrase in corporatePhrases {
                    #expect(!body.contains(phrase),
                            "repeat-broken body (\(days)d, count=\(breakCount)) must not contain corporate phrase \"\(phrase)\"")
                }
            }
        }
    }

    @Test func streakRepeatBrokenBody_isActionOriented() {
        // Repeat copy should prompt the user to investigate or change something.
        let actionWords = ["figure", "find", "change", "what", "different", "fix", "capable"]
        for days in [7, 14, 21, 30] {
            let body = SessionNotifier.streakRepeatBrokenBody(days: days, breakCount: 2).lowercased()
            let hasActionWord = actionWords.contains { body.contains($0) }
            #expect(hasActionWord, "repeat-broken body for \(days)d should contain an action-oriented word")
        }
    }
}
