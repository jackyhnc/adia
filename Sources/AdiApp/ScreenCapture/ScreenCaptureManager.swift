import AppKit
import ScreenCaptureKit
import CoreMedia
import CoreImage
import ImageIO

/// Wraps SCStream and emits CGImage frames via AsyncStream at ~0.5 FPS.
final class ScreenCaptureManager: NSObject, SCStreamOutput, SCStreamDelegate, @unchecked Sendable {
    private var stream: SCStream?
    // Set once before stream starts; read-only from callback thread afterwards.
    private var frameContinuation: AsyncStream<CGImage>.Continuation?
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])

    func startCapture() async throws -> AsyncStream<CGImage> {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        guard let display = content.displays.first else {
            throw SCError.noDisplay
        }

        let filter = SCContentFilter(display: display, excludingWindows: [])

        let config = SCStreamConfiguration()
        config.width = Int(display.width / 2)
        config.height = Int(display.height / 2)
        config.minimumFrameInterval = CMTime(value: 2, timescale: 1)
        config.pixelFormat = kCVPixelFormatType_32BGRA
        config.showsCursor = false

        let (asyncStream, continuation) = AsyncStream<CGImage>.makeStream()
        frameContinuation = continuation

        let scStream = try SCStream(filter: filter, configuration: config, delegate: self)
        try scStream.addStreamOutput(self, type: .screen, sampleHandlerQueue: .global(qos: .utility))
        try await scStream.startCapture()
        self.stream = scStream

        return asyncStream
    }

    func stopCapture() async throws {
        try await stream?.stopCapture()
        frameContinuation?.finish()
        frameContinuation = nil
        stream = nil
    }

    nonisolated func stream(
        _ stream: SCStream,
        didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
        of type: SCStreamOutputType
    ) {
        guard type == .screen,
              let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        else { return }

        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) else { return }
        frameContinuation?.yield(cgImage)
    }

    nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
        frameContinuation?.finish()
    }
}

enum SCError: Error, LocalizedError {
    case noDisplay
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .noDisplay: return "No display found for screen capture."
        case .permissionDenied: return "Screen Recording permission is required. Grant it in System Settings → Privacy."
        }
    }
}

extension CGImage {
    func pngData() -> Data? {
        let data = CFDataCreateMutable(nil, 0)! as NSMutableData
        guard let destination = CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil)
        else { return nil }
        CGImageDestinationAddImage(destination, self, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        return data as Data
    }
}
