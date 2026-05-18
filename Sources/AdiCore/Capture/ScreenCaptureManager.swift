import Foundation
import CoreGraphics
#if canImport(ScreenCaptureKit)
import ScreenCaptureKit
#endif

// Placeholder — full ScreenCaptureKit implementation in the Screen Capture Pipeline task.
// Emits CGImage frames on a regular interval for the on-task detector.
public final class ScreenCaptureManager: @unchecked Sendable {
    public static let shared = ScreenCaptureManager()
    private init() {}

    // Will be replaced by SCStream delegate output.
    public var onFrame: (@Sendable (CGImage) async -> Void)?

    public func start() async throws {
        // SCStream setup goes here.
    }

    public func stop() {
        // SCStream teardown.
    }
}
