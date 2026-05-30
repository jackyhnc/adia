import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// Observes NSWorkspace app-activation events and fires an immediate callout
/// whenever a blocked app becomes the frontmost application during a session.
@MainActor
public final class AppMonitor {
    public static let shared = AppMonitor()

    private var blockedBundleIDs: Set<String> = []
    private var observation: NSObjectProtocol?

    // Format strings use %@ for the app name; plain strings are generic fallbacks.
    static let callouts: [String] = [
        "yo, why are you in %@?",
        "close %@. now.",
        "get out of %@.",
        "%@ isn't going to write it for you.",
        "that's not your task.",
        "close that.",
        "get back to work.",
        "seriously?",
    ]

    private init() {}

    /// Start monitoring. Fires an immediate callout whenever a blocked app activates.
    public func start(blockedBundleIDs: Set<String>) {
        stop()  // remove any prior observer before registering a new one
        self.blockedBundleIDs = blockedBundleIDs
        guard !blockedBundleIDs.isEmpty else { return }
        #if canImport(AppKit)
        observation = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { notification in
            guard
                let app = notification.userInfo?[
                    NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                let bundleID = app.bundleIdentifier
            else { return }
            let name = app.localizedName ?? bundleID
            Task { @MainActor in
                AppMonitor.shared.handle(bundleID: bundleID, appName: name)
            }
        }
        #endif
    }

    /// Stop monitoring and clear the blocked list.
    public func stop() {
        #if canImport(AppKit)
        if let obs = observation {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            observation = nil
        }
        #endif
        blockedBundleIDs = []
    }

    private func handle(bundleID: String, appName: String) {
        guard blockedBundleIDs.contains(bundleID) else { return }
        CalloutManager.shared.fireAppCallout(Self.callout(for: appName))
    }

    /// Returns a callout message for a blocked app. Internal for direct testing.
    static func callout(for appName: String) -> String {
        let withName = callouts.filter { $0.contains("%@") }
        let plain    = callouts.filter { !$0.contains("%@") }
        // Randomly pick a named or generic callout so messages stay varied.
        if !withName.isEmpty && Bool.random(), let template = withName.randomElement() {
            return String(format: template, appName)
        }
        return plain.randomElement() ?? "close that."
    }
}
