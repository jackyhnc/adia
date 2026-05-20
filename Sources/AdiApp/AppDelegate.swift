import AppKit
import SwiftUI
import AdiCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var notchController: NotchWindowController?
    private var onboardingWindow: NSWindow?
    private var windowCloseObserver: NSObjectProtocol?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        // Restore accessory policy when every non-panel window closes (e.g. Settings).
        // willCloseNotification fires just before close; the Task hop ensures the window
        // is fully gone before we check NSApp.windows.
        windowCloseObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                let hasRegularWindow = NSApp.windows.contains { !($0 is NSPanel) && $0.isVisible }
                if !hasRegularWindow {
                    NSApp.setActivationPolicy(.accessory)
                }
            }
        }

        Task {
            await LicenseManager.shared.bootstrap()
            let needsOnboarding = !SettingsStore.shared.hasAPIKey
                || LicenseManager.shared.status == .unknown
            if needsOnboarding {
                showOnboarding()
            } else {
                showNotch()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    private func showNotch() {
        if notchController == nil {
            notchController = NotchWindowController()
        }
        notchController?.showWindow(nil)
        Task { await SessionManager.shared.restoreIfNeeded() }
    }

    private func showOnboarding() {
        let hosting = NSHostingController(rootView: OnboardingView { [weak self] in
            self?.finishOnboarding()
        })
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable]
        window.title = "Welcome to Adia"
        window.center()
        window.isReleasedWhenClosed = false
        NSApp.setActivationPolicy(.regular)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindow = window
    }

    private func finishOnboarding() {
        if case .unknown = LicenseManager.shared.status {
            LicenseManager.shared.startTrialIfNeeded()
        }
        onboardingWindow?.close()
        onboardingWindow = nil
        NSApp.setActivationPolicy(.accessory)
        showNotch()
    }
}
