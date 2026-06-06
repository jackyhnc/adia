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

    private let captureManager = ScreenCaptureManager.shared
    private let detector = OnTaskDetector()
    private let hosts = HostsFileManager.shared
    private let persistence = SessionPersistence.shared
    private let callout = CalloutManager.shared

    // Set to true just before endSession() when verification succeeded, so the
    // history record knows whether the session was completed or exited early.
    private var sessionEndedSuccessfully = false

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
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        #if canImport(AppKit)
        NSWorkspace.shared.open(url)
        #endif
    }

    public func endSession() async {
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
                calloutCount: callout.calloutCount
            )
            Task { await SessionHistory.shared.record(record) }
        }
        sessionEndedSuccessfully = false

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

    // MARK: - Frame handling

    public func handleFrame(_ frame: CGImage) async {
        let status = await detector.evaluate(frame: frame)
        onTaskStatus = status
        callout.evaluate(status)
        // Sync the live calloutCount back to the persisted session so a restored session
        // can resume tier escalation from the right tier. Only writes when count changed
        // (i.e. when a callout just fired) — not on every frame.
        if var s = session, s.calloutCount != callout.calloutCount {
            s.calloutCount = callout.calloutCount
            session = s
            persistence.save(s)
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
        NotchState.shared.setVerifying(true)
        do {
            let result = try await AgentAIClient.shared.verify(
                image: frame,
                taskDescription: s.task,
                successCriteria: s.successCriteria
            )
            NotchState.shared.setVerificationResult(result)
            AppLogger.info("verification.result", [
                "verified": String(result.verified),
                "explanation": result.explanation
            ])
            if result.verified {
                sessionEndedSuccessfully = true
                SessionNotifier.shared.sendSessionComplete(task: s.task)
                // Give the user up to 5s to read their stats and click End Session.
                // If they click the button first, session becomes nil and the guard below
                // prevents a redundant endSession() call.
                try? await Task.sleep(for: .seconds(5))
                if session != nil { await endSession() }
            } else {
                // Session continues — persist the updated history so attempt numbering
                // survives a crash/relaunch before the user retries verification.
                // Re-read session rather than using the stale `s` so any whitelisting
                // done during the verification await is not overwritten.
                if var updated = session {
                    updated.verificationHistory = NotchState.shared.verificationHistory
                    session = updated
                    persistence.save(updated)
                }
            }
        } catch {
            NotchState.shared.setVerifying(false)
            AppLogger.error("verification.failed", ["error": String(describing: error)])
            print("[SessionManager] verification error: \(error)")
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

    // MARK: - Restore on launch

    /// Call on app launch to restore a session that survived a crash or relaunch.
    /// Re-wires capture and blocking so the session is truly active, not just displayed.
    public func restoreIfNeeded() async {
        guard let saved = persistence.load() else { return }
        var s = saved
        s.phase = .active
        session = s
        persistence.save(s)
        do {
            try await activate(s)
        } catch {
            print("[SessionManager] restore failed, session will be shown but capture is inactive: \(error)")
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

    internal func _injectSessionForTesting(_ session: Session?) {
        self.session = session
    }

    // MARK: - Private helpers

    /// Wires up the capture pipeline, blocking engine, and on-task detector for a session.
    /// Throws if screen capture cannot be started (e.g. permission denied).
    private func activate(_ s: Session) async throws {
        callout.reset()                        // clear streak state left over from any prior session
        callout.restore(count: s.calloutCount) // for restored sessions: resume tier escalation
        callout.setTask(s.task)                // extract keyword so callouts reference the task
        SleepBlocker.shared.start()
        AppMonitor.shared.start(blockedBundleIDs: Set(s.blockedApps))
        await detector.attach(session: s)
        captureManager.onFrame = { [weak self] frame in
            await self?.handleFrame(frame)
        }

        // Local block server (non-fatal)
        LocalBlockServer.shared.start(blockedDomains: s.blockedDomains, taskDescription: s.task)

        // /etc/hosts blocking requires root — non-fatal
        do {
            try await hosts.block(domains: s.blockedDomains)
        } catch {
            print("[SessionManager] hosts blocking unavailable (needs root): \(error)")
        }

        do {
            try await captureManager.start()
            AppLogger.info("session.capture_ready")
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
