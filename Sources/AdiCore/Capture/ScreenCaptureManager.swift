import Foundation
import CoreGraphics
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

// @unchecked Sendable is safe here: start/stop are always called from
// SessionManager which is @MainActor, and onFrame is set before start().
public final class ScreenCaptureManager: @unchecked Sendable {
    public static let shared = ScreenCaptureManager()
    private init() {}

    public var onFrame: (@Sendable (CGImage) async -> Void)? {
        get { bridge.onFrame }
        set { bridge.onFrame = newValue }
    }

    private var stream: SCStream?
    private let bridge = StreamOutputBridge()

    public func start() async throws {
        let hasAccess = CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess()
        guard hasAccess else { throw CaptureError.permissionDenied }

        let content = try await SCShareableContent.current
        guard let display = content.displays.first else {
            throw CaptureError.noDisplayFound
        }

        let cfg = SCStreamConfiguration()
        // Half-resolution is sufficient for vision inference and halves data volume.
        cfg.width  = max(1, display.width  / 2)
        cfg.height = max(1, display.height / 2)
        cfg.minimumFrameInterval = CMTime(seconds: 1.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        cfg.pixelFormat   = kCVPixelFormatType_32BGRA
        cfg.capturesAudio = false
        cfg.showsCursor   = false

        let filter = SCContentFilter(
            display: display,
            excludingApplications: [],
            exceptingWindows: []
        )
        let s = SCStream(filter: filter, configuration: cfg, delegate: nil)
        try s.addStreamOutput(bridge, type: .screen, sampleHandlerQueue: .global(qos: .userInitiated))
        try await s.startCapture()
        stream = s
    }

    public func stop() {
        stream?.stopCapture { _ in }
        stream = nil
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

    public func start() async throws { throw CaptureError.unavailable }
    public func stop() {}
}

public enum CaptureError: Error, Sendable {
    case unavailable
}

#endif
