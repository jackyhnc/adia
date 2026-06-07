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

    /// The active session's task description, used to explain *why* a blocked
    /// app was hidden (e.g. "that's not \"write essay\". get back to it.").
    /// Set on `start(blockedBundleIDs:task:)`, cleared on `stop()`.
    /// `internal private(set)` so tests can assert it without exposing a setter.
    internal private(set) var currentTask: String = ""

    /// How often (in milliseconds) the re-hide loop polls the frontmost application.
    /// 200 ms is fast enough to catch Command-Tab re-activations within a single
    /// human-perceptible frame while staying cheap on CPU.
    static let reHideIntervalMilliseconds: Int = 200

    /// Background task that periodically checks whether the frontmost app is blocked
    /// and re-hides it if so. Catches cases where `NSRunningApplication.hide()` fired
    /// in response to an activation notification but the user Command-Tabbed back before
    /// the hide completed.
    internal private(set) var reHideTask: Task<Void, Never>?

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
    /// `task` is the session's task description, surfaced in the "closed <app>"
    /// notification so the user knows why the app vanished.
    public func start(blockedBundleIDs: Set<String>, task: String = "") {
        stop()  // remove any prior observer before registering a new one
        self.blockedBundleIDs = blockedBundleIDs
        self.currentTask = task
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
        startReHideLoop()
    }

    /// Stop monitoring and clear the blocked list.
    public func stop() {
        #if canImport(AppKit)
        if let obs = observation {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            observation = nil
        }
        #endif
        reHideTask?.cancel()
        reHideTask = nil
        blockedBundleIDs = []
        currentTask = ""
    }

    private func startReHideLoop() {
        reHideTask?.cancel()
        reHideTask = Task { [weak self] in
            while !Task.isCancelled {
                self?.reHideIfNeeded()
                try? await Task.sleep(for: .milliseconds(Self.reHideIntervalMilliseconds))
            }
        }
    }

    private func reHideIfNeeded() {
        guard Self.forceHidesBlockedApps, !blockedBundleIDs.isEmpty else { return }
        #if canImport(AppKit)
        guard
            let frontmost = NSWorkspace.shared.frontmostApplication,
            let bundleID = frontmost.bundleIdentifier,
            blockedBundleIDs.contains(bundleID)
        else { return }
        frontmost.hide()
        #endif
    }

    private func handle(bundleID: String, appName: String) {
        guard blockedBundleIDs.contains(bundleID) else { return }
        CalloutManager.shared.fireAppCallout(Self.callout(for: appName))
        #if canImport(AppKit)
        // Enforce "no soft blocks": immediately hide the app so the user cannot
        // continue using it after dismissing or ignoring the callout.
        if Self.forceHidesBlockedApps {
            NSWorkspace.shared.runningApplications
                .first { $0.bundleIdentifier == bundleID }?
                .hide()
            // Explain *why* the app vanished — without this, force-hiding looks
            // like a crash or glitch rather than deliberate enforcement.
            SessionNotifier.shared.sendBlockedAppHidden(appName: appName, task: currentTask)
        }
        #endif
    }

    /// When true, blocked apps are force-hidden the moment they activate during a session.
    /// Enforces the "no soft blocks" design principle: the user cannot continue using a
    /// blocked app simply by ignoring the callout banner.
    public static let forceHidesBlockedApps: Bool = true

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
