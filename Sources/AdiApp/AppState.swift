import SwiftUI
import AdiCore

@MainActor
final class AppState: ObservableObject {
    // MARK: - Published state

    @Published var session: Session?
    @Published var onTaskStatus: OnTaskStatus = .unknown
    @Published var showCallout: Bool = false
    @Published var calloutMessage: String = ""
    @Published var isVerifying: Bool = false
    @Published var verificationResult: VerificationResult?
    @Published var isExpanded: Bool = false

    // MARK: - Dependencies

    let claudeClient: any ClaudeClientProtocol
    let persistence = SessionPersistence.shared
    let blockingEngine = BlockingEngine.shared

    private var detector: OnTaskDetector?
    private var captureManager: ScreenCaptureManager?

    init(claudeClient: (any ClaudeClientProtocol)? = nil) {
        if let client = claudeClient {
            self.claudeClient = client
        } else if let client = try? ClaudeClient.fromEnvironment() {
            self.claudeClient = client
        } else {
            // No API key — stub that always returns unknown (app still usable for blocking)
            self.claudeClient = StubClaudeClient()
        }
    }

    // MARK: - Session lifecycle

    func startSession(task: SessionTask) {
        var s = Session(task: task, status: .active)
        // Block default list minus any existing whitelisted domains
        let toBlock = DefaultBlockList.domains.filter { !s.whitelist.contains($0) }
        do {
            try blockingEngine.block(domains: toBlock)
        } catch {
            // Log but don't block startup — user may not have granted privileges yet
            print("[Adia] blocking failed: \(error)")
        }
        s.status = .active
        session = s
        try? persistence.save(s)

        startDetection()
    }

    func endSession(verified: Bool) {
        session?.status = verified ? .completed : .abandoned
        session?.endTime = Date()
        if let s = session { try? persistence.save(s) }
        stopDetection()
        try? blockingEngine.unblockAll()
        session = nil
        onTaskStatus = .unknown
        showCallout = false
        isExpanded = false
    }

    func whitelistDomain(_ domain: String) {
        guard session != nil else { return }
        session?.whitelist.append(domain)
        if let s = session { try? persistence.save(s) }
        // Rebuild block list excluding newly whitelisted domain
        let toBlock = DefaultBlockList.domains.filter { !(session?.whitelist.contains($0) ?? false) }
        try? blockingEngine.block(domains: toBlock)
    }

    func verifyCompletion() {
        guard let s = session else { return }
        isVerifying = true
        Task {
            do {
                let capture = ScreenCaptureManager()
                let frames = try await capture.startCapture()
                var frame: CGImage?
                for await img in frames {
                    frame = img
                    break  // just one frame for verification
                }
                try? await capture.stopCapture()

                guard let img = frame, let data = img.pngData() else {
                    await MainActor.run { self.isVerifying = false }
                    return
                }

                let result = try await claudeClient.verify(image: data, task: s.task)
                await MainActor.run {
                    self.verificationResult = result
                    self.isVerifying = false
                    if result.verified {
                        self.endSession(verified: true)
                    }
                }
            } catch {
                await MainActor.run { self.isVerifying = false }
            }
        }
    }

    // MARK: - Detection loop

    private func startDetection() {
        let capture = ScreenCaptureManager()
        captureManager = capture
        let detector = OnTaskDetector(client: claudeClient, captureManager: capture)
        self.detector = detector
        detector.onClassification = { [weak self] classification in
            guard let self else { return }
            self.onTaskStatus = classification.status
            self.session?.lastOnTaskStatus = classification.status
            if classification.status == .offTask {
                self.session?.offTaskCount += 1
                self.triggerCallout(for: classification)
            } else {
                self.showCallout = false
            }
            if let s = self.session { try? self.persistence.save(s) }
        }
        guard let session else { return }
        detector.start(session: session)
    }

    private func stopDetection() {
        detector?.stop()
        detector = nil
        captureManager = nil
    }

    private func triggerCallout(for classification: OnTaskClassification) {
        calloutMessage = CalloutManager.message(for: classification)
        showCallout = true
        isExpanded = true
    }
}

// Stub used when ANTHROPIC_API_KEY is absent — lets the app run without AI features
private struct StubClaudeClient: ClaudeClientProtocol {
    func classify(image: Data, task: SessionTask) async throws -> OnTaskClassification {
        OnTaskClassification(status: .unknown, reason: "API key not configured", confidence: 0)
    }
    func verify(image: Data, task: SessionTask) async throws -> VerificationResult {
        VerificationResult(verified: false, explanation: "API key not configured")
    }
    func chat(messages: [ChatMessage], systemPrompt: String?) async throws -> String {
        "API key not configured. Add ANTHROPIC_API_KEY to the environment."
    }
}
