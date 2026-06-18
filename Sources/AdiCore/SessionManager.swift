import Foundation
import CoreGraphics
#if canImport(AppKit)
import AppKit
#endif

/// Central coordinator: owns the active session and drives the state machine.
@MainActor
public final class SessionManager: ObservableObject {
    public static let shared = SessionManager()

    @Published public private(set) var session: Session?
    @Published public private(set) var onTaskStatus: OnTaskStatus = .onTask
    /// True from the moment the session's target duration elapses until the session ends.
    /// Triggers the notch to auto-expand and show the "time's up" banner.
    @Published public private(set) var timerExpired: Bool = false
    /// Minimum number of AI classification frames required before the focus score is
    /// considered statistically meaningful and shown in the UI.
    public nonisolated static let minChecksForFocusScore: Int = 5

    /// Number of AI screen-classification frames that came back as "on-task" this session.
    @Published public private(set) var onTaskCheckCount: Int = 0
    /// Total AI screen-classification frames evaluated this session (on-task + off-task + ambiguous).
    @Published public private(set) var totalCheckCount: Int = 0

    /// Fraction of classified frames that were on-task (0.0–1.0).
    /// nil before any frames have been classified.
    public var focusScore: Double? {
        guard totalCheckCount > 0 else { return nil }
        return Double(onTaskCheckCount) / Double(totalCheckCount)
    }

    private let captureManager = ScreenCaptureManager.shared
    private let detector = OnTaskDetector()
    private let hosts = HostsFileManager.shared
    private let persistence = SessionPersistence.shared
    private let callout = CalloutManager.shared

    /// The agent backing verification calls. Real `AgentAIClient.shared` in production;
    /// swapped for a deterministic `MockAgentAIClient` in tests via `_injectAIClientForTesting`
    /// so races like `verifyAndEnd()` vs. manual `endSession()` can be exercised without a
    /// live network round-trip or `ANTHROPIC_API_KEY`.
    internal var _aiClient: any AgentAIService = AgentAIClient.shared

    // Set to true just before endSession() when verification succeeded, so the
    // history record knows whether the session was completed or exited early.
    private var sessionEndedSuccessfully = false

    /// Fires when the session's target duration elapses. Cancelled by endSession().
    private var durationTimerTask: Task<Void, Never>?

    /// Periodically re-opens the notch while the timer has expired but the user hasn't
    /// verified yet. Cancelled by endSession() and _resetTimerForTesting().
    /// Exposed as `internal private(set)` so tests can assert it is non-nil / nil.
    internal private(set) var timerExpiredRearmTask: Task<Void, Never>?

    /// Captures the most-recently-created SessionRecord. Only written inside endSession().
    /// Exposed for unit tests; nil until the first session ends in this process lifetime.
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
            // activate() failed (e.g. screen-capture permission denied) — roll back so
            // the session doesn't appear active and restoreIfNeeded() doesn't try to
            // restart a session that never fully started.
            // /etc/hosts may have been written before captureManager.start() threw — undo it.
            session = nil
            persistence.clear()
            captureManager.onFrame = nil
            await detector.detach()
            AppMonitor.shared.stop()
            LocalBlockServer.shared.stop()
            SleepBlocker.shared.stop()
            do { try await hosts.unblockAll() } catch {
                print("[SessionManager] hosts cleanup after failed start: \(error)")
            }
            throw error
        }
    }

    /// Opens System Settings → Privacy & Security → Screen Recording.
    private static func openScreenRecordingSettings() {
        // Force unwrap is safe: this is a constant, well-formed URL string (no user
        // input, no percent-encoding concerns) — `URL(string:)` cannot fail for it.
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        #if canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }

    public func endSession(note: String? = nil) async {
        // Finalize any in-progress pause so elapsed/duration are accurate in the record.
        if var s = session, s.phase == .paused, let pauseStart = s.pauseStartTime {
            s.pausedDuration += Date().timeIntervalSince(pauseStart)
            s.pauseStartTime = nil
            s.phase = .active
            session = s
        }
        // Record the session before clearing it so we have all the data.
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
                blockedApps: s.blockedApps
            )
            _lastEndedRecord = record
            Task { await SessionHistory.shared.record(record) }
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
            print("[SessionManager] hosts cleanup failed: \(error)")
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
        // Sync live counters back to the persisted session so a crash/relaunch can resume
        // tier escalation and show a meaningful focus score for the full session.
        // calloutCount only changes when a callout fires; check counts change every frame.
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

    // MARK: - Task verification

    /// Called when the user taps "Done". Captures the last frame and asks the agent to verify it.
    public func verifyAndEnd() async {
        guard let s = session else { return }
        guard let frame = captureManager.lastFrame else {
            // No frame yet (capture just started) — end without verification.
            await endSession()
            return
        }
        // Snapshot the session's identity. `verify()` and the post-success sleep below
        // both `await` for several seconds — long enough for the user to tap "End Session"
        // directly (or even start a brand-new session) while this call is in flight. Every
        // place below that mutates shared state must re-check `session?.id == sessionID`
        // so a stale verification result can't act on a session that's already gone.
        let sessionID = s.id
        NotchState.shared.setVerifying(true)
        do {
            let result = try await _aiClient.verify(
                image: frame,
                taskDescription: s.task,
                successCriteria: s.successCriteria
            )
            guard session?.id == sessionID else {
                // The session was ended (or replaced by a new one) while we were
                // awaiting verification — discard this result, it no longer applies.
                AppLogger.info("verification.discarded_stale", [
                    "verified": String(result.verified)
                ])
                return
            }
            NetworkMonitor.shared.recordSuccess()
            NotchState.shared.setVerificationResult(result)
            AppLogger.info("verification.result", [
                "verified": String(result.verified),
                "explanation": result.explanation
            ])
            if result.verified {
                sessionEndedSuccessfully = true
                SessionNotifier.shared.sendSessionComplete(task: s.task)
                await HapticPlayer.performSuccess()
                // Give the user up to 5s to read their stats and click End Session.
                // If they click the button first (or start a new session), `session?.id`
                // no longer matches and we must not touch the new session's state.
                try? await Task.sleep(for: .seconds(5))
                if session?.id == sessionID { await endSession() }
            } else {
                // Session continues — persist the updated history so attempt numbering
                // survives a crash/relaunch before the user retries verification.
                // Re-read session rather than using the stale `s` so any whitelisting
                // done during the verification await is not overwritten. The identity
                // check above already guarantees `session` is still this same session.
                if var updated = session {
                    updated.verificationHistory = NotchState.shared.verificationHistory
                    session = updated
                    persistence.save(updated)
                }
            }
        } catch {
            NotchState.shared.setVerifying(false)
            NetworkMonitor.shared.recordFailure()
            let userMsg = NetworkMonitor.shared.isConnected
                ? "verification failed — try again in a moment."
                : "you're offline — check your connection and try again."
            NotchState.shared.showCallout(userMsg)
            AppLogger.error("verification.failed", [
                "error": String(describing: error),
                "isConnected": String(NetworkMonitor.shared.isConnected),
            ])
        }
    }

    // MARK: - Whitelist

    /// Removes a domain from the block list for the remainder of the session.
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
            print("[SessionManager] whitelist hosts rewrite failed: \(error)")
        }
    }

    // MARK: - Reasoning memory

    /// Appends a reasoning-conversation outcome to the session so a later ask about the
    /// same domain can be answered with full context ("you already asked about this").
    public func recordReasoningAttempt(domain: String, granted: Bool, summary: String) {
        guard var s = session else { return }
        let trimmed = domain.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        s.reasoningHistory.append(ReasoningAttempt(domain: trimmed, granted: granted, summary: summary))
        session = s
        persistence.save(s)
    }

    // MARK: - Restore on launch

    /// Call on app launch to restore a session that survived a crash or relaunch.
    /// Re-wires capture and blocking so the session is truly active, not just displayed.
    public func restoreIfNeeded() async {
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
                print("[SessionManager] restore failed, session will be shown but capture is inactive: \(error)")
            }
        }
        // Restore verification attempt history so the notch shows the correct attempt number
        // if the user retries verification after a crash/relaunch.
        if !s.verificationHistory.isEmpty {
            NotchState.shared.restoreVerificationHistory(s.verificationHistory)
        }
        // Notify the user that their session survived the relaunch.
        SessionNotifier.shared.sendSessionRestored(task: s.task)
    }

    // MARK: - Test helpers

    /// Sound played when the session timer expires. "Glass" is a clean, positive chime
    /// distinct from the off-task callout sounds (Sosumi / Basso / Funk), so the user
    /// can instantly tell the difference between "done" and "get back to work".
    internal nonisolated static let timerExpiredSoundName: String = "Glass"

    /// Default re-arm interval, used as the fallback when no user preference is stored.
    /// `SettingsStore.timerExpiredRearmInterval` is the live, user-configurable value
    /// (Settings → "Remind me every"); this constant only documents/guards the default.
    /// Exposed as `internal` so tests can assert the default is exactly 10 minutes.
    internal nonisolated static let timerExpiredRearmInterval: TimeInterval = 600

    /// Called when the session's target duration elapses.
    /// Exposed as `internal` so unit tests can invoke it without sleeping real time.
    internal func handleDurationExpired() {
        guard session != nil else { return }
        timerExpired = true
        NotchState.shared.expand()
        SessionNotifier.shared.sendTimerExpired(task: session?.task ?? "")
        #if canImport(AppKit)
        NSSound(named: Self.timerExpiredSoundName)?.play()
        #endif
        // Re-arm: if the user collapses the notch without verifying, re-open it every
        // rearmInterval (user-configurable in Settings, default 10 min) until they
        // either verify or explicitly end the session.
        timerExpiredRearmTask?.cancel()
        timerExpiredRearmTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: Duration.seconds(SettingsStore.shared.timerExpiredRearmInterval))
                guard !Task.isCancelled, timerExpired, session != nil else { return }
                NotchState.shared.expand()
                SessionNotifier.shared.sendTimerExpired(task: session?.task ?? "")
                #if canImport(AppKit)
                NSSound(named: Self.timerExpiredSoundName)?.play()
                #endif
            }
        }
    }

    internal func _injectSessionForTesting(_ session: Session?) {
        self.session = session
    }

    /// Swaps the agent client for a deterministic stand-in (or restores the real
    /// `AgentAIClient.shared` by passing it back in). Lets tests control `verify()`'s
    /// timing/result without a network call — see `MockAgentAIClient`.
    internal func _injectAIClientForTesting(_ client: any AgentAIService) {
        _aiClient = client
    }

    internal func _injectCheckCountsForTesting(onTask: Int, total: Int) {
        onTaskCheckCount = onTask
        totalCheckCount  = total
    }

    /// Resets timer-expiry state without running the full session teardown.
    /// Use in unit tests after calling `handleDurationExpired()` directly.
    internal func _resetTimerForTesting() {
        durationTimerTask?.cancel()
        durationTimerTask = nil
        timerExpiredRearmTask?.cancel()
        timerExpiredRearmTask = nil
        timerExpired = false
    }

    // MARK: - Private helpers

    // MARK: - Stream failure recovery

    /// Called when ScreenCaptureManager exhausts all automatic recovery attempts.
    /// Auto-pauses the session so focus score isn't corrupted by un-monitored time,
    /// and alerts the user via the callout system.
    private func handleCaptureStreamFailure(_ error: Error) {
        guard session != nil, session?.phase == .active else { return }
        let task = session?.task ?? ""
        AppLogger.error("session.capture_stream_lost", [
            "error": String(describing: error)
        ])
        Task {
            await self.pauseSession()
            NotchState.shared.showCallout("screen recording lost — check Adia in System Settings → Privacy → Screen Recording, then resume.")
            #if canImport(AppKit)
            NSSound(named: "Basso")?.play()
            #endif
            SessionNotifier.shared.sendCaptureStreamLost(task: task)
        }
    }

    /// Wires up the capture pipeline, blocking engine, and on-task detector for a session.
    /// Throws if screen capture cannot be started (e.g. permission denied).
    private func activate(_ s: Session) async throws {
        // Restore persisted check counts so focus score continues from where it left off
        // after a crash/relaunch. For brand-new sessions both fields are 0 (the default).
        onTaskCheckCount = s.onTaskChecks
        totalCheckCount  = s.totalChecks
        callout.reset()                        // clear streak state left over from any prior session
        callout.restore(count: s.calloutCount) // for restored sessions: resume tier escalation
        callout.setTask(s.task)                // extract keyword so callouts reference the task
        SleepBlocker.shared.start()
        AppMonitor.shared.start(blockedBundleIDs: Set(s.blockedApps), task: s.task)
        await detector.attach(session: s)
        captureManager.onFrame = { [weak self] frame in
            await self?.handleFrame(frame)
        }
        captureManager.onStreamFailure = { [weak self] error in
            self?.handleCaptureStreamFailure(error)
        }

        // Local block server (non-fatal). Callback is passed into start() so it is set
        // before the listener begins accepting connections — eliminates the tiny race window
        // where a first connection could arrive before the @MainActor callback assignment.
        LocalBlockServer.shared.start(
            blockedDomains: s.blockedDomains,
            taskDescription: s.task,
            sessionStartTime: s.startTime,
            onBlockedDomainAccessed: { domain in
                Task { @MainActor in
                    guard SessionManager.shared.session != nil,
                          !NotchState.shared.showingConversation,
                          !NotchState.shared.isVerifying else { return }
                    NotchState.shared.startConversation(.reasoning(domain: domain))
                }
            }
        )

        // /etc/hosts blocking requires root — non-fatal
        do {
            try await hosts.block(domains: s.blockedDomains)
        } catch {
            print("[SessionManager] hosts blocking unavailable (needs root): \(error)")
        }

        do {
            try await captureManager.start()
            AppLogger.info("session.capture_ready")
            // Start the duration countdown only after the session is fully active.
            // For restored sessions, sleep only for the time remaining (elapsed already counts).
            if let dur = s.targetDuration {
                let remaining = max(0, dur - s.elapsed)
                durationTimerTask?.cancel()
                durationTimerTask = Task {
                    if remaining > 0 {
                        try? await Task.sleep(for: Duration.seconds(remaining))
                    }
                    guard !Task.isCancelled else { return }
                    handleDurationExpired()
                }
            }
        } catch CaptureError.permissionDenied {
            AppLogger.error("session.capture_permission_denied")
            NotchState.shared.showCallout("Screen Recording permission needed — enable Adia in System Settings, then start again.")
            Self.openScreenRecordingSettings()
            throw CaptureError.permissionDenied
        } catch {
            NotchState.shared.showCallout("Couldn't start screen monitoring: \(error.localizedDescription)")
            throw error
        }
    }
}

// MARK: - HapticPlayer

/// Delivers Force Touch haptic feedback at key moments.
/// The two-pulse success sequence is more celebratory than a single pulse — the second
/// beat lands ~50 ms after the first, which the trackpad registers as a distinct event.
@MainActor
enum HapticPlayer {
    /// Gap between the two success pulses. Short enough to feel simultaneous, long enough
    /// for the trackpad firmware to fire two separate actuations.
    nonisolated static let successPulseDelay: Duration = .milliseconds(50)

    /// Fires two rapid `.levelChange` pulses for a "tada" feel on verified session completion.
    /// Safe to call on Macs without a Force Touch trackpad — the call is silently ignored.
    static func performSuccess() async {
        #if canImport(AppKit)
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
        try? await Task.sleep(for: successPulseDelay)
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
        #endif
    }
}
