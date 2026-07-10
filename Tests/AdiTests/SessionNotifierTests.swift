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

// MARK: - Morning nudge pure-function tests (no app bundle required)

/// Tests for `SessionNotifier.morningNudgeBody` and `morningNudgeMessages`.
/// Exercises only `nonisolated static` members, so no `UNUserNotificationCenter` call
/// occurs and the suite runs unconditionally in CI.
///
/// The property-based tests iterate over the full `morningNudgeMessages` pool so that
/// a passing suite guarantees every variant ships with the right tone — not just the
/// random one that happened to be picked during this particular test run.
@Suite("SessionNotifier morning nudge")
struct SessionNotifierMorningNudgeTests {

    // MARK: - Pool shape

    @Test func morningNudgeMessages_poolIsNonEmpty() {
        #expect(!SessionNotifier.morningNudgeMessages.isEmpty)
    }

    @Test func morningNudgeMessages_hasAtLeastThreeVariants() {
        #expect(SessionNotifier.morningNudgeMessages.count >= 3,
                "pool should have multiple variants to reduce notification fatigue")
    }

    @Test func morningNudgeMessages_allVariantsAreUnique() {
        let messages = SessionNotifier.morningNudgeMessages
        #expect(Set(messages).count == messages.count, "pool should not contain duplicate messages")
    }

    @Test func morningNudgeBody_returnsNonEmptyString() {
        #expect(!SessionNotifier.morningNudgeBody().isEmpty)
    }

    // MARK: - Tone constraints (checked across every pool variant)

    @Test func morningNudgeMessages_noneAreEmpty() {
        for message in SessionNotifier.morningNudgeMessages {
            #expect(!message.isEmpty, "every morning nudge variant must be non-empty")
        }
    }

    @Test func morningNudgeMessages_noneUseCorporateLanguage() {
        let corporatePhrases = ["congratulations", "achievement", "great job", "well done", "perfect", "awesome"]
        for message in SessionNotifier.morningNudgeMessages {
            let lower = message.lowercased()
            for phrase in corporatePhrases {
                #expect(!lower.contains(phrase),
                        "morning nudge variant '\(message)' must not use corporate language: '\(phrase)'")
            }
        }
    }

    @Test func morningNudgeMessages_allReferenceStartingWork() {
        let actionWords = ["start", "session", "task", "open", "begin", "yet", "today", "going", "now"]
        for message in SessionNotifier.morningNudgeMessages {
            let lower = message.lowercased()
            #expect(actionWords.contains { lower.contains($0) },
                    "morning nudge variant '\(message)' must reference starting work or the current state")
        }
    }

    @Test func morningNudgeMessages_noneUsePunishingLanguage() {
        let shamePhrases = ["failed", "loser", "disappointed", "shame", "terrible", "bad person"]
        for message in SessionNotifier.morningNudgeMessages {
            let lower = message.lowercased()
            for phrase in shamePhrases {
                #expect(!lower.contains(phrase),
                        "morning nudge variant '\(message)' must not use punishing language: '\(phrase)'")
            }
        }
    }

    @Test func morningNudgeMessages_noneContainAllCapsWords() {
        for message in SessionNotifier.morningNudgeMessages {
            let hasShoutingWord = message.components(separatedBy: .whitespaces)
                .filter { $0.count > 1 }
                .contains { w in w == w.uppercased() && w.first?.isLetter == true }
            #expect(!hasShoutingWord,
                    "morning nudge variant '\(message)' must not contain shouting all-caps words")
        }
    }

    @Test func morningNudgeMessages_hasNineVariants() {
        #expect(SessionNotifier.morningNudgeMessages.count == 9,
                "messages pool must have exactly 9 variants for parity with the morningNudgeTitles pool")
    }

    @Test func morningNudgeMessages_allVariantsAreLowercase() {
        for message in SessionNotifier.morningNudgeMessages {
            #expect(message == message.lowercased(),
                    "message '\(message)' must be fully lowercase — friend-like tone uses no capitalization")
        }
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

// MARK: - Daily goal achieved pure-function tests (no app bundle required)

/// Tests for `SessionNotifier.dailyGoalAchievedBody` — exercises only a `nonisolated static`
/// function so no `UNUserNotificationCenter` call occurs; runs unconditionally in CI.
@Suite("SessionNotifier daily goal achieved")
struct SessionNotifierDailyGoalTests {

    // MARK: Non-empty

    @Test func dailyGoalAchievedBody_isNonEmptyForCommonGoals() {
        for minutes in [15, 30, 45, 60, 90, 120, 180] {
            #expect(
                !SessionNotifier.dailyGoalAchievedBody(goalMinutes: minutes).isEmpty,
                "daily-goal body for \(minutes) min must not be empty"
            )
        }
    }

    // MARK: Mentions the minute count

    @Test func dailyGoalAchievedBody_mentionsMinuteCountForNonRoundHours() {
        // Exact hours (60, 120) use "hour/hours" phrasing; everything else must mention the number.
        for minutes in [15, 30, 45, 90, 180] {
            let body = SessionNotifier.dailyGoalAchievedBody(goalMinutes: minutes)
            #expect(body.contains("\(minutes)"),
                    "body for \(minutes)-min goal should mention the minute count")
        }
    }

    @Test func dailyGoalAchievedBody_60minUsesHourPhrasing() {
        let body = SessionNotifier.dailyGoalAchievedBody(goalMinutes: 60).lowercased()
        #expect(body.contains("hour"), "60-min goal body should use 'hour' phrasing")
    }

    @Test func dailyGoalAchievedBody_120minUsesHourPhrasing() {
        let body = SessionNotifier.dailyGoalAchievedBody(goalMinutes: 120).lowercased()
        #expect(body.contains("hour"), "120-min goal body should use 'hour' phrasing")
    }

    // MARK: Tone

    @Test func dailyGoalAchievedBody_toneIsNotCorporate() {
        let corporatePhrases = ["congratulations", "achievement", "great job", "well done", "amazing"]
        for minutes in [30, 60, 90, 120] {
            let body = SessionNotifier.dailyGoalAchievedBody(goalMinutes: minutes).lowercased()
            for phrase in corporatePhrases {
                #expect(!body.contains(phrase),
                        "daily-goal body for \(minutes) min must not use corporate phrase \"\(phrase)\"")
            }
        }
    }

    @Test func dailyGoalAchievedBody_confirmsGoalIsComplete() {
        // Every variant should make it clear the goal is done.
        let completionWords = ["done", "hit", "goal"]
        for minutes in [15, 30, 45, 60, 90, 120, 180] {
            let body = SessionNotifier.dailyGoalAchievedBody(goalMinutes: minutes).lowercased()
            let hasCompletionWord = completionWords.contains { body.contains($0) }
            #expect(hasCompletionWord,
                    "daily-goal body for \(minutes) min should confirm the goal is complete")
        }
    }

    // MARK: todayDateString helper

    @Test func todayDateString_matchesExpectedFormat() {
        let str = SessionManager.todayDateString()
        // Must be exactly "yyyy-MM-dd" — 10 characters, digits and hyphens only.
        #expect(str.count == 10, "date string must be 10 characters")
        #expect(str.filter({ $0 == "-" }).count == 2, "date string must have exactly 2 hyphens")
        let parts = str.split(separator: "-")
        #expect(parts.count == 3, "date string must have 3 components")
        #expect(parts[0].count == 4, "year component must be 4 digits")
        #expect(parts[1].count == 2, "month component must be 2 digits")
        #expect(parts[2].count == 2, "day component must be 2 digits")
    }

    @Test func todayDateString_containsCurrentYear() {
        let str = SessionManager.todayDateString()
        // The year in the string must be the current calendar year.
        let year = Calendar.current.component(.year, from: Date())
        #expect(str.hasPrefix(String(year)), "date string must start with the current year \(year)")
    }

    @Test func todayDateString_isStableWithinSameSecond() {
        // Two consecutive calls must return the same string (same calendar day).
        let a = SessionManager.todayDateString()
        let b = SessionManager.todayDateString()
        #expect(a == b, "two consecutive todayDateString calls must return the same value")
    }
}

// MARK: - Morning nudge title variants

/// Property-based tests for the `morningNudgeTitles` pool.
/// Mirrors the structure of `SessionNotifierMorningNudgeTests` for consistency.
@Suite("SessionNotifier — morning nudge titles")
struct SessionNotifierMorningNudgeTitleTests {

    @Test func morningNudgeTitles_poolIsNonEmpty() {
        #expect(!SessionNotifier.morningNudgeTitles.isEmpty)
    }

    @Test func morningNudgeTitles_hasAtLeastThreeVariants() {
        #expect(SessionNotifier.morningNudgeTitles.count >= 3,
                "pool must have at least 3 variants to meaningfully reduce notification fatigue")
    }

    @Test func morningNudgeTitles_allVariantsAreUnique() {
        let titles = SessionNotifier.morningNudgeTitles
        #expect(Set(titles).count == titles.count, "every title variant must be unique")
    }

    @Test func morningNudgeTitle_returnsNonEmptyString() {
        #expect(!SessionNotifier.morningNudgeTitle().isEmpty)
    }

    @Test func morningNudgeTitles_noneAreEmpty() {
        for title in SessionNotifier.morningNudgeTitles {
            #expect(!title.isEmpty, "every title variant must be non-empty")
        }
    }

    @Test func morningNudgeTitles_noneUseCorporateLanguage() {
        let banned = ["congratulations", "achievement", "great job", "well done", "awesome"]
        for title in SessionNotifier.morningNudgeTitles {
            let lower = title.lowercased()
            for word in banned {
                #expect(!lower.contains(word), "title '\(title)' must not use corporate language '\(word)'")
            }
        }
    }

    @Test func morningNudgeTitles_noneUsePunishingLanguage() {
        let banned = ["failed", "loser", "disappointed", "shame", "terrible", "pathetic"]
        for title in SessionNotifier.morningNudgeTitles {
            let lower = title.lowercased()
            for word in banned {
                #expect(!lower.contains(word), "title '\(title)' must not use punishing language '\(word)'")
            }
        }
    }

    @Test func morningNudgeTitles_noneContainAllCapsWords() {
        for title in SessionNotifier.morningNudgeTitles {
            let words = title.split(separator: " ").map(String.init)
            for word in words where word.count > 1 {
                let letters = word.filter { $0.isLetter }
                #expect(letters != letters.uppercased() || letters.isEmpty,
                        "title '\(title)' must not contain an all-caps word '\(word)'")
            }
        }
    }

    @Test func morningNudgeTitles_hasNineVariants() {
        #expect(SessionNotifier.morningNudgeTitles.count == 9,
                "titles pool must have exactly 9 variants for parity with the morningNudgeMessages pool")
    }

    @Test func morningNudgeTitles_allVariantsAreLowercase() {
        for title in SessionNotifier.morningNudgeTitles {
            #expect(title == title.lowercased(),
                    "title '\(title)' must be fully lowercase — friend-like tone uses no capitalization")
        }
    }
}
