import Foundation
import CoreGraphics
#if canImport(AppKit)
import AppKit
#endif

extension SessionManager {

    // MARK: - Timer constants

    /// Sound played when the session timer expires.
    internal nonisolated static let timerExpiredSoundName: String = "Glass"

    /// Default re-arm interval (10 min). `SettingsStore.timerExpiredRearmInterval` is the
    /// live, user-configurable value; this constant documents/guards the default.
    internal nonisolated static let timerExpiredRearmInterval: TimeInterval = 600

    // MARK: - Screen Recording settings

    static func openScreenRecordingSettings() {
        // Force unwrap is safe: constant, well-formed URL string.
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        #if canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }

    // MARK: - Task verification

    /// Called when the user taps "Done". Captures the last frame and asks the agent to verify it.
    public func verifyAndEnd() async {
        guard let s = session else { return }
        guard let frame = captureManager.lastFrame else {
            await endSession()
            return
        }
        let sessionID = s.id
        NotchState.shared.setVerifying(true)
        do {
            let result = try await _aiClient.verify(
                image: frame,
                taskDescription: s.task,
                successCriteria: s.successCriteria
            )
            guard session?.id == sessionID else {
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
                try? await Task.sleep(for: .seconds(5))
                if session?.id == sessionID { await endSession() }
            } else {
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

    // MARK: - Duration timer

    /// Called when the session's target duration elapses.
    internal func handleDurationExpired() {
        guard session != nil else { return }
        timerExpired = true
        NotchState.shared.expand()
        SessionNotifier.shared.sendTimerExpired(task: session?.task ?? "")
        #if canImport(AppKit)
        NSSound(named: Self.timerExpiredSoundName)?.play()
        #endif
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

    // MARK: - Stream failure recovery

    /// Called when ScreenCaptureManager exhausts all automatic recovery attempts.
    func handleCaptureStreamFailure(_ error: Error) {
        guard session != nil, session?.phase == .active else { return }
        if var s = session {
            s.streamFailureCount += 1
            session = s
            persistence.save(s)
        }
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

    // MARK: - Activation pipeline

    /// Wires up the capture pipeline, blocking engine, and on-task detector for a session.
    func activate(_ s: Session) async throws {
        onTaskCheckCount = s.onTaskChecks
        totalCheckCount  = s.totalChecks
        callout.reset()
        callout.restore(count: s.calloutCount)
        callout.setTask(s.task)
        SleepBlocker.shared.start()
        AppMonitor.shared.start(blockedBundleIDs: Set(s.blockedApps), task: s.task)
        await detector.attach(session: s)
        captureManager.onFrame = { [weak self] frame in
            await self?.handleFrame(frame)
        }
        captureManager.onStreamFailure = { [weak self] error in
            self?.handleCaptureStreamFailure(error)
        }

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

        do {
            try await hosts.block(domains: s.blockedDomains)
        } catch {
            AppLogger.warning("session.hosts_blocking_unavailable", ["error": "\(error)"])
        }

        do {
            try await captureManager.start()
            AppLogger.info("session.capture_ready")
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
