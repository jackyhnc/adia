import Foundation
import CoreGraphics

// Central coordinator: owns the active session and drives the state machine.
@MainActor
public final class SessionManager: ObservableObject {
    public static let shared = SessionManager()

    @Published public private(set) var session: Session?
    @Published public private(set) var onTaskStatus: OnTaskStatus = .onTask

    private let captureManager = ScreenCaptureManager.shared
    private let detector = OnTaskDetector()
    private let hosts = HostsFileManager.shared

    private init() {}

    // MARK: - Session lifecycle

    public func start(task: String, successCriteria: String) async throws {
        let s = Session(task: task, successCriteria: successCriteria, phase: .active)
        session = s
        await detector.attach(session: s)
        // Blocking requires root; failure is non-fatal — the Blocking Engine task
        // adds a privileged XPC helper for this.
        do {
            try await hosts.block(domains: s.blockedDomains)
        } catch {
            print("[SessionManager] hosts blocking unavailable: \(error)")
        }
        try await captureManager.start()
    }

    public func endSession() async throws {
        captureManager.stop()
        try await hosts.unblockAll()
        await detector.detach()
        session = nil
        onTaskStatus = .onTask
    }

    public func handleFrame(_ frame: CoreGraphics.CGImage) async {
        let status = await detector.evaluate(frame: frame)
        onTaskStatus = status
    }
}
