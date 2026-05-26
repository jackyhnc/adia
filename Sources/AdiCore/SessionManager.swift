import Foundation
import CoreGraphics

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

    public func start(task: String, successCriteria: String) async throws {
        let s = Session(
            task: task,
            successCriteria: successCriteria,
            phase: .active,
            blockedDomains: SettingsStore.shared.effectiveBlockedDomains
        )
        session = s
        persistence.save(s)
        do {
            try await activate(s)
        } catch {
            // activate() failed (e.g. screen-capture permission denied) — roll back so
            // the session doesn't appear active and restoreIfNeeded() doesn't try to
            // restart a session that never fully started.
            // /etc/hosts may have been written before captureManager.start() threw — undo it.
            session = nil
            persistence.clear()
            captureManager.onFrame = nil
            await detector.detach()
            LocalBlockServer.shared.stop()
            do { try await hosts.unblockAll() } catch {
                print("[SessionManager] hosts cleanup after failed start: \(error)")
            }
            throw error
        }
    }

    public func endSession() async {
        // Record the session before clearing it so we have all the data.
        if let s = session {
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
        LocalBlockServer.shared.stop()
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
    }

    // MARK: - Task verification

    /// Called when the user taps "Done". Captures last frame, sends to Claude for verification.
    public func verifyAndEnd() async {
        guard let s = session else { return }
        guard let frame = captureManager.lastFrame else {
            // No frame yet (capture just started) — end without verification.
            await endSession()
            return
        }
        NotchState.shared.setVerifying(true)
        do {
            let result = try await ClaudeClient.shared.verify(
                image: frame,
                taskDescription: s.task,
                successCriteria: s.successCriteria
            )
            NotchState.shared.setVerificationResult(result)
            if result.verified {
                sessionEndedSuccessfully = true
                // Brief pause so the user sees "verified ✓" before everything unblocks.
                try? await Task.sleep(for: .seconds(1.2))
                await endSession()
            }
            // If not verified, session stays active — user sees the explanation.
        } catch {
            NotchState.shared.setVerifying(false)
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
    }

    // MARK: - Test helpers

    internal func _injectSessionForTesting(_ session: Session?) {
        self.session = session
    }

    // MARK: - Private helpers

    /// Wires up the capture pipeline, blocking engine, and on-task detector for a session.
    /// Throws if screen capture cannot be started (e.g. permission denied).
    private func activate(_ s: Session) async throws {
        callout.reset()  // clear streak state left over from any prior session
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

        try await captureManager.start()
    }
}
