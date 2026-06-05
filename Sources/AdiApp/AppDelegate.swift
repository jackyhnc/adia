import AppKit
import SwiftUI
import AdiCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var notchController: NotchWindowController?
    private var blockerController: FocusBlockerWindowController?
    private var onboardingWindow: NSWindow?
    private var windowCloseObserver: NSObjectProtocol?

    static let onboardingDoneKey = "adia.hasCompletedOnboarding"

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)

        // Keep Adia in the Dock even when the notch overlay is the only visible UI.
        windowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                NSApp.setActivationPolicy(.regular)
            }
        }

        Task {
            await LicenseManager.shared.bootstrap()
            // Silently start the trial on first launch so the user never sees
            // the license screen unless they've actually run out of trial.
            LicenseManager.shared.startTrialIfNeeded()
            // Onboarding is the welcome + Screen Recording permission flow.
            // API key configuration lives in Settings/Keychain or local env for dev.
            if UserDefaults.standard.bool(forKey: Self.onboardingDoneKey) {
                showNotch()
            } else {
                showOnboarding()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    private func showNotch() {
        if notchController == nil {
            notchController = NotchWindowController()
        }
        // The takeover window lives for the whole session lifetime, hidden until an
        // ignored callout escalates (NotchState.isBlocking).
        if blockerController == nil {
            blockerController = FocusBlockerWindowController()
        }
        notchController?.showWindow(nil)
        GlobalHotkeyManager.shared.start()
        MenuBarManager.shared.start()
        SessionNotifier.shared.requestPermission()
        Task { await SessionManager.shared.restoreIfNeeded() }
    }

    private func showOnboarding() {
        let hosting = NSHostingController(rootView: OnboardingView { [weak self] in
            self?.finishOnboarding()
        })
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isMovableByWindowBackground = true
        window.backgroundColor = NSColor(red: 0.055, green: 0.055, blue: 0.06, alpha: 1)
        window.center()
        window.isReleasedWhenClosed = false
        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = window
    }

    private func finishOnboarding() {
        UserDefaults.standard.set(true, forKey: Self.onboardingDoneKey)
        if case .unknown = LicenseManager.shared.status {
            LicenseManager.shared.startTrialIfNeeded()
        }
        onboardingWindow?.close()
        onboardingWindow = nil
        NSApp.setActivationPolicy(.regular)
        showNotch()
    }
}
