import Foundation
#if canImport(AppKit)
import AppKit
#endif

@MainActor
enum HapticPlayer {
    nonisolated static let successPulseDelay: Duration = .milliseconds(50)

    static func performSuccess() async {
        #if canImport(AppKit)
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
        try? await Task.sleep(for: successPulseDelay)
        NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .default)
        #endif
    }
}
