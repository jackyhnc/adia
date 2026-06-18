import Foundation
import CoreGraphics
#if canImport(AppKit)
import AppKit
#endif
#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
import CoreMedia
import CoreVideo

// Bridges SCStreamOutput (ObjC protocol) into Swift actor world.
// Must be a class to satisfy NSObject/ObjC requirements.
private final class StreamOutputBridge: NSObject, SCStreamOutput, @unchecked Sendable {
    var onFrame: (@Sendable (CGImage) async -> Void)?

    func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard type == .screen else { return }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        guard let cgImage = cgImage(from: pixelBuffer) else { return }
        let callback = onFrame
        Task { await callback?(cgImage) }
        let mgr = ScreenCaptureManager.shared
        mgr.lastFrame = cgImage
        mgr.lastFrameReceivedAt = Date()
    }

    private func cgImage(from pixelBuffer: CVPixelBuffer) -> CGImage? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        guard let base = CVPixelBufferGetBaseAddress(pixelBuffer) else { return nil }
        let w   = CVPixelBufferGetWidth(pixelBuffer)
        let h   = CVPixelBufferGetHeight(pixelBuffer)
        let bpr = CVPixelBufferGetBytesPerRow(pixelBuffer)
        let bitmapInfo = CGBitmapInfo(rawValue:
            CGImageAlphaInfo.premultipliedFirst.rawValue |
            CGBitmapInfo.byteOrder32Little.rawValue
        )
        guard let ctx = CGContext(
            data: base,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: bpr,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: bitmapInfo.rawValue
        ) else { return nil }
        return ctx.makeImage()
    }
}

/// Receives SCStream lifecycle errors (stream stopped by system, permission revoked, etc.)
/// and triggers recovery via a callback to the owning ScreenCaptureManager.
private final class StreamDelegate: NSObject, SCStreamDelegate, @unchecked Sendable {
    var onStreamStopped: (@Sendable (_ error: Error) -> Void)?

    func stream(_ stream: SCStream, didStopWithError error: Error) {
        AppLogger.error("capture.stream_stopped", [
            "error": String(describing: error),
            "errorCode": String((error as NSError).code),
            "errorDomain": (error as NSError).domain
        ])
        onStreamStopped?(error)
    }
}

// @unchecked Sendable is safe here: start/stop are always called from
// SessionManager which is @MainActor, and onFrame is set before start().
public final class ScreenCaptureManager: @unchecked Sendable {
    public static let shared = ScreenCaptureManager()
    private init() {}

    public var onFrame: (@Sendable (CGImage) async -> Void)? {
        get { bridge.onFrame }
        set { bridge.onFrame = newValue }
    }

    /// Called on the main actor when the stream fails and automatic recovery is exhausted.
    /// SessionManager sets this to auto-pause the session and notify the user.
    public var onStreamFailure: (@MainActor @Sendable (_ error: Error) -> Void)?

    // Most-recent captured frame. Written from the stream queue, read from @MainActor.
    // Protected by a lock for Swift 6 sendability.
    private let frameLock = NSLock()
    private var _lastFrame: CGImage?
    public var lastFrame: CGImage? {
        get { frameLock.withLock { _lastFrame } }
        set { frameLock.withLock { _lastFrame = newValue } }
    }

    private let frameTimeLock = NSLock()
    private var _lastFrameReceivedAt: Date?
    /// Timestamp of the most recently received frame. Updated on the stream queue.
    public var lastFrameReceivedAt: Date? {
        get { frameTimeLock.withLock { _lastFrameReceivedAt } }
        set { frameTimeLock.withLock { _lastFrameReceivedAt = newValue } }
    }

    private var stream: SCStream?
    private let bridge = StreamOutputBridge()
    private let streamDelegate = StreamDelegate()
    private var recoveryTask: Task<Void, Never>?
    private var watchdogTask: Task<Void, Never>?

    /// Maximum number of automatic restart attempts before giving up.
    internal static let maxRecoveryAttempts = 3
    /// Base delay (in seconds) for exponential backoff between restart attempts.
    internal static let recoveryBaseDelay: TimeInterval = 2.0
    /// If no frames arrive within this interval, the watchdog proactively triggers
    /// stream recovery — catches silent hangs that never fire `didStopWithError`.
    internal static let frameStalenessTimeout: TimeInterval = 10.0
    /// How often the watchdog checks for frame staleness.
    internal static let watchdogCheckInterval: TimeInterval = 5.0

    public func start() async throws {
        recoveryTask?.cancel()
        recoveryTask = nil
        watchdogTask?.cancel()
        watchdogTask = nil

        // `CGPreflightScreenCaptureAccess()` can return stale false after local
        // rebuilds/re-signing even when System Settings shows the app enabled.
        // Request once if needed, then let ScreenCaptureKit be the source of
        // truth and map its failure into a user-facing permission error.
        if !CGPreflightScreenCaptureAccess() {
            AppLogger.warning("capture.preflight_failed")
            #if canImport(AppKit)
            await MainActor.run {
                NSApp.setActivationPolicy(.regular)
                NSApp.activate(ignoringOtherApps: true)
            }
            #endif
            _ = CGRequestScreenCaptureAccess()
        }

        try await startStream()
        lastFrameReceivedAt = Date()
        startWatchdog()

        streamDelegate.onStreamStopped = { [weak self] error in
            guard let self else { return }
            self.attemptRecovery(originalError: error)
        }
    }

    public func stop() {
        watchdogTask?.cancel()
        watchdogTask = nil
        recoveryTask?.cancel()
        recoveryTask = nil
        streamDelegate.onStreamStopped = nil
        stream?.stopCapture { _ in }
        stream = nil
        lastFrame = nil
        lastFrameReceivedAt = nil
        AppLogger.info("capture.stopped")
    }

    /// The inner start logic, shared between initial start and recovery restarts.
    private func startStream() async throws {
        let content: SCShareableContent
        do {
            content = try await SCShareableContent.current
        } catch {
            AppLogger.error("capture.shareable_content_failed", [
                "error": String(describing: error)
            ])
            throw CaptureError.permissionDenied
        }
        guard let display = content.displays.first else {
            AppLogger.error("capture.no_display_found")
            throw CaptureError.noDisplayFound
        }

        let cfg = SCStreamConfiguration()
        // Half-resolution is sufficient for vision inference and halves data volume.
        cfg.width  = max(1, display.width  / 2)
        cfg.height = max(1, display.height / 2)
        cfg.minimumFrameInterval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        cfg.pixelFormat   = kCVPixelFormatType_32BGRA
        cfg.capturesAudio = false
        cfg.showsCursor   = false

        let filter = SCContentFilter(
            display: display,
            excludingApplications: [],
            exceptingWindows: []
        )
        let s = SCStream(filter: filter, configuration: cfg, delegate: streamDelegate)
        try s.addStreamOutput(bridge, type: .screen, sampleHandlerQueue: .global(qos: .userInitiated))
        try await s.startCapture()
        stream = s
        AppLogger.info("capture.started", [
            "width": String(cfg.width),
            "height": String(cfg.height),
            "frameIntervalSeconds": "0.5"
        ])
    }

    /// Periodically checks whether frames are still arriving. If the gap exceeds
    /// `frameStalenessTimeout`, triggers recovery proactively — catches silent
    /// stream hangs where `SCStreamDelegate.didStopWithError` is never called.
    private func startWatchdog() {
        watchdogTask?.cancel()
        watchdogTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(Self.watchdogCheckInterval))
                guard !Task.isCancelled else { return }
                guard let self else { return }
                guard self.stream != nil else { return }
                guard let lastTime = self.lastFrameReceivedAt else { continue }
                let gap = Date().timeIntervalSince(lastTime)
                if gap >= Self.frameStalenessTimeout {
                    AppLogger.warning("capture.watchdog_stale", [
                        "gapSeconds": String(format: "%.1f", gap),
                        "timeout": String(Self.frameStalenessTimeout)
                    ])
                    self.lastFrameReceivedAt = Date()
                    let error = NSError(
                        domain: "com.adia.capture",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Frame staleness watchdog triggered after \(Int(gap))s"]
                    )
                    self.attemptRecovery(originalError: error)
                    return
                }
            }
        }
    }

    /// Attempts to restart the stream with exponential backoff.
    private func attemptRecovery(originalError: Error) {
        recoveryTask?.cancel()
        recoveryTask = Task { [weak self] in
            guard let self else { return }
            for attempt in 1...Self.maxRecoveryAttempts {
                let delay = Self.recoveryBaseDelay * pow(2.0, Double(attempt - 1))
                AppLogger.warning("capture.recovery_attempt", [
                    "attempt": String(attempt),
                    "maxAttempts": String(Self.maxRecoveryAttempts),
                    "delaySeconds": String(delay)
                ])
                try? await Task.sleep(for: .seconds(delay))
                guard !Task.isCancelled else { return }

                do {
                    try await self.startStream()
                    self.lastFrameReceivedAt = Date()
                    self.startWatchdog()
                    AppLogger.info("capture.recovery_succeeded", ["attempt": String(attempt)])
                    return
                } catch {
                    AppLogger.error("capture.recovery_failed", [
                        "attempt": String(attempt),
                        "error": String(describing: error)
                    ])
                }
            }

            guard !Task.isCancelled else { return }
            AppLogger.error("capture.recovery_exhausted", [
                "originalError": String(describing: originalError),
                "attempts": String(Self.maxRecoveryAttempts)
            ])
            let failureCallback = self.onStreamFailure
            let err = originalError
            Task { @MainActor in
                failureCallback?(err)
            }
        }
    }
}

public enum CaptureError: Error, Sendable {
    case permissionDenied
    case noDisplayFound
}

#else

// Stub for non-macOS platforms (Linux CI, etc.)
public final class ScreenCaptureManager: @unchecked Sendable {
    public static let shared = ScreenCaptureManager()
    private init() {}

    public var onFrame: (@Sendable (CGImage) async -> Void)?
    public var onStreamFailure: (@MainActor @Sendable (_ error: Error) -> Void)?
    public var lastFrame: CGImage? { nil }
    public var lastFrameReceivedAt: Date? { nil }

    internal static let maxRecoveryAttempts = 3
    internal static let recoveryBaseDelay: TimeInterval = 2.0
    internal static let frameStalenessTimeout: TimeInterval = 10.0
    internal static let watchdogCheckInterval: TimeInterval = 5.0

    public func start() async throws { throw CaptureError.unavailable }
    public func stop() {}
}

public enum CaptureError: Error, Sendable {
    case unavailable
}

#endif
