import Foundation
import CoreGraphics
#if canImport(AppKit)
import AppKit
#endif

/// Central coordinator: owns the active session and drives the state machine.
@MainActor
public final class SessionManager: ObservableObject {
    public static let shared = SessionManager()

    @Published public internal(set) var session: Session?
    @Published public private(set) var onTaskStatus: OnTaskStatus = .onTask
    @Published public internal(set) var timerExpired: Bool = false
    public nonisolated static let minChecksForFocusScore: Int = 5

    @Published public internal(set) var onTaskCheckCount: Int = 0
    @Published public internal(set) var totalCheckCount: Int = 0

    public var focusScore: Double? {
        guard totalCheckCount > 0 else { return nil }
        return Double(onTaskCheckCount) / Double(totalCheckCount)
    }

    let captureManager = ScreenCaptureManager.shared
    let detector = OnTaskDetector()
    let hosts = HostsFileManager.shared
    let persistence = SessionPersistence.shared
    let callout = CalloutManager.shared

    internal var _aiClient: any AgentAIService = AgentAIClient.shared

    var sessionEndedSuccessfully = false

    var durationTimerTask: Task<Void, Never>?

    internal var timerExpiredRearmTask: Task<Void, Never>?

    internal private(set) var _lastEndedRecord: SessionRecord?

    private init() {}

    // MARK: - Session lifecycle

    public func start(task: String, successCriteria: String, targetDuration: TimeInterval? = nil) async throws {
        AppLogger.info("session.start_requested", [
            "taskLength": String(task.count),
            "criteriaLength": String(successCriteria.count)
        ])
        let s = Session(
            task: task,
            successCriteria: successCriteria,
            phase: .active,
            blockedDomains: SettingsStore.shared.effectiveBlockedDomains,
            blockedApps: SettingsStore.shared.effectiveBlockedApps,
            targetDuration: targetDuration
        )
        do {
            try await activate(s)
            session = s
            persistence.save(s)
        } catch {
            AppLogger.error("session.start_failed", ["error": String(describing: error)])
            session = nil
            persistence.clear()
            captureManager.onFrame = nil
            await detector.detach()
            AppMonitor.shared.stop()
            LocalBlockServer.shared.stop()
            SleepBlocker.shared.stop()
            do { try await hosts.unblockAll() } catch {
                AppLogger.error("session.hosts_cleanup_after_failed_start", ["error": "\(error)"])
            }
            throw error
        }
    }

    public func endSession(note: String? = nil) async {
        if var s = session, s.phase == .paused, let pauseStart = s.pauseStartTime {
            s.pausedDuration += Date().timeIntervalSince(pauseStart)
            s.pauseStartTime = nil
            s.phase = .active
            session = s
        }
        if let s = session {
            AppLogger.info("session.ending", [
                "completedSuccessfully": String(sessionEndedSuccessfully),
                "elapsedSeconds": String(Int(s.elapsed))
            ])
            let record = SessionRecord(
                task: s.task,
                successCriteria: s.successCriteria,
                startTime: s.startTime,
                endTime: Date(),
                completedSuccessfully: sessionEndedSuccessfully,
                calloutCount: callout.calloutCount,
                note: note,
                onTaskChecks: onTaskCheckCount,
                totalChecks: totalCheckCount,
                reasoningAttempts: s.reasoningHistory.count,
                reasoningGranted: s.reasoningHistory.filter(\.granted).count,
                blockedDomains: s.blockedDomains,
                blockedApps: s.blockedApps,
                pauseCount: s.pauseCount,
                totalPausedSeconds: Int(s.pausedDuration),
                streamFailureCount: s.streamFailureCount
            )
            _lastEndedRecord = record
            let wasSuccessful = sessionEndedSuccessfully
            Task {
                await SessionHistory.shared.record(record)
                guard wasSuccessful else { return }
                let stats = await SessionHistory.shared.stats()
                // Persist streak so broken-streak detection on next launch has a baseline.
                UserDefaults.standard.set(stats.streak, forKey: "adia.lastActiveStreak")
                if let milestone = SessionNotifier.streakMilestoneValue(stats.streak) {
                    let milestoneKey = "adia.lastNotifiedStreakMilestone"
                    let last = UserDefaults.standard.integer(forKey: milestoneKey)
                    if last < milestone {
                        UserDefaults.standard.set(milestone, forKey: milestoneKey)
                        SessionNotifier.shared.sendStreakMilestone(days: milestone)
                    }
                }
            }
        }
        sessionEndedSuccessfully = false
        onTaskCheckCount = 0
        totalCheckCount  = 0
        durationTimerTask?.cancel()
        durationTimerTask = nil
        timerExpiredRearmTask?.cancel()
        timerExpiredRearmTask = nil
        timerExpired = false

        captureManager.stop()
        AppMonitor.shared.stop()
        LocalBlockServer.shared.stop()
        SleepBlocker.shared.stop()
        do { try await hosts.unblockAll() } catch {
            AppLogger.error("session.hosts_cleanup_failed", ["error": "\(error)"])
        }
        await detector.detach()
        persistence.clear()
        session = nil
        onTaskStatus = .onTask

        NotchState.shared.clearCallout()
        NotchState.shared.setVerifying(false)
        NotchState.shared.setVerificationResult(nil)
        NotchState.shared.exitConversation()
        NotchState.shared.collapse()
    }

    // MARK: - Pause / Resume

    public func pauseSession() async {
        guard var s = session, s.phase == .active else { return }
        AppLogger.info("session.pausing", ["elapsedSeconds": String(Int(s.elapsed))])
        s.phase = .paused
        s.pauseStartTime = Date()
        s.pauseCount += 1
        session = s
        persistence.save(s)

        captureManager.stop()
        AppMonitor.shared.stop()
        SleepBlocker.shared.stop()
        await detector.detach()
        durationTimerTask?.cancel()
        durationTimerTask = nil
        timerExpiredRearmTask?.cancel()
        timerExpiredRearmTask = nil

        NotchState.shared.clearCallout()
        onTaskStatus = .onTask
    }

    public func resumeSession() async {
        guard var s = session, s.phase == .paused else { return }
        if let pauseStart = s.pauseStartTime {
            s.pausedDuration += Date().timeIntervalSince(pauseStart)
        }
        s.pauseStartTime = nil
        s.phase = .active
        session = s
        persistence.save(s)
        AppLogger.info("session.resuming", ["pausedDurationTotal": String(Int(s.pausedDuration))])

        do {
            try await activate(s)
        } catch {
            AppLogger.error("session.resume_failed", ["error": String(describing: error)])
        }
    }

    // MARK: - Frame handling

    public func handleFrame(_ frame: CGImage) async {
        let classification = await detector.evaluate(frame: frame)
        let status = classification.status
        onTaskStatus = status
        callout.evaluate(status, reason: classification.reason)
        totalCheckCount += 1
        if status == .onTask { onTaskCheckCount += 1 }
        if var s = session {
            var dirty = false
            if s.calloutCount != callout.calloutCount {
                s.calloutCount = callout.calloutCount
                dirty = true
            }
            if s.onTaskChecks != onTaskCheckCount {
                s.onTaskChecks = onTaskCheckCount
                dirty = true
            }
            if s.totalChecks != totalCheckCount {
                s.totalChecks = totalCheckCount
                dirty = true
            }
            if dirty {
                session = s
                persistence.save(s)
            }
        }
    }

    // MARK: - Whitelist

    public func whitelist(domain: String) async {
        guard var s = session else { return }
        let trimmed = domain.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        let base = trimmed.hasPrefix("www.") ? String(trimmed.dropFirst(4)) : trimmed
        guard !s.whitelistedDomains.contains(base) else { return }
        s.whitelistedDomains.append(base)
        s.blockedDomains.removeAll { $0 == base || $0 == "www.\(base)" }
        session = s
        persistence.save(s)
        do {
            try await hosts.block(domains: s.blockedDomains)
        } catch {
            AppLogger.error("session.whitelist_hosts_rewrite_failed", ["error": "\(error)"])
        }
    }

    // MARK: - Reasoning memory

    public func recordReasoningAttempt(domain: String, granted: Bool, summary: String) {
        guard var s = session else { return }
        let trimmed = domain.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        s.reasoningHistory.append(ReasoningAttempt(domain: trimmed, granted: granted, summary: summary))
        session = s
        persistence.save(s)
    }

    // MARK: - Restore on launch

    public func restoreIfNeeded() async {
        await checkStreakBreak()
        guard let saved = persistence.load() else { return }
        var s = saved
        let wasPaused = s.phase == .paused
        if wasPaused {
            session = s
            persistence.save(s)
        } else {
            s.phase = .active
            session = s
            persistence.save(s)
            do {
                try await activate(s)
            } catch {
                AppLogger.error("session.restore_failed", ["error": "\(error)"])
            }
        }
        if !s.verificationHistory.isEmpty {
            NotchState.shared.restoreVerificationHistory(s.verificationHistory)
        }
        SessionNotifier.shared.sendSessionRestored(task: s.task)
    }

    // MARK: - Streak break detection

    /// Checks whether the user's active streak has dropped to 0 since the last successful session.
    /// - Resets `adia.lastNotifiedStreakMilestone` to 0 whenever the streak hits 0, so milestones
    ///   can be re-earned on the next streak run.
    /// - Fires a re-engagement notification when the broken streak was ≥7 days.
    /// Called once per app launch from `restoreIfNeeded()`.
    internal func checkStreakBreak() async {
        let activeKey = "adia.lastActiveStreak"
        let milestoneKey = "adia.lastNotifiedStreakMilestone"
        let lastActive = UserDefaults.standard.integer(forKey: activeKey)
        guard lastActive > 0 else { return }
        let stats = await SessionHistory.shared.stats()
        guard stats.streak == 0 else { return }
        // Streak has broken. Reset both keys so milestones can be re-earned.
        UserDefaults.standard.set(0, forKey: activeKey)
        UserDefaults.standard.set(0, forKey: milestoneKey)
        // Only notify for meaningful streaks (≥7 days) to avoid banner fatigue.
        guard lastActive >= 7 else { return }
        SessionNotifier.shared.sendStreakBroken(previousStreak: lastActive)
    }

    // MARK: - Test helpers

    internal func _injectSessionForTesting(_ session: Session?) {
        self.session = session
    }

    internal func _injectAIClientForTesting(_ client: any AgentAIService) {
        _aiClient = client
    }

    internal func _injectCheckCountsForTesting(onTask: Int, total: Int) {
        onTaskCheckCount = onTask
        totalCheckCount  = total
    }

    internal func _resetTimerForTesting() {
        durationTimerTask?.cancel()
        durationTimerTask = nil
        timerExpiredRearmTask?.cancel()
        timerExpiredRearmTask = nil
        timerExpired = false
    }
}
