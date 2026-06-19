import Foundation
import Combine
#if canImport(AppKit)
import AppKit
#endif

/// Manages the Adia status item in the macOS menu bar.
/// Left-click toggles the notch panel; right-click shows a context menu.
/// The item is only created when the user's `showMenuBarItem` setting is on.
@MainActor
public final class MenuBarManager {
    public static let shared = MenuBarManager()

    #if canImport(AppKit)
    private var statusItem: NSStatusItem?
    #endif
    private var sessionCancellable: AnyCancellable?

    private init() {}

    // MARK: - Lifecycle

    /// Creates the status item if the user setting permits and it isn't already running.
    public func start() {
        #if canImport(AppKit)
        guard SettingsStore.shared.showMenuBarItem else { return }
        guard statusItem == nil else { return }

        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = item.button {
            button.image = Self.statusImage(active: false)
            button.action = #selector(handleClick)
            button.target = self
            // Receive both button-up variants so right-click reaches handleClick.
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        statusItem = item

        sessionCancellable = SessionManager.shared.$session
            .receive(on: RunLoop.main)
            .sink { [weak self] session in
                self?.updateIcon(hasSession: session != nil)
            }
        #endif
    }

    /// Removes the status item and tears down Combine subscriptions.
    public func stop() {
        #if canImport(AppKit)
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
            statusItem = nil
        }
        #endif
        sessionCancellable = nil
    }

    // MARK: - Icon

    /// SF Symbol image for the status bar. Template images adapt to dark / light mode.
    /// Exposed as `internal` so it can be verified in tests on macOS.
    static func statusImage(active: Bool) -> NSImage? {
        #if canImport(AppKit)
        let name = active ? "a.circle.fill" : "a.circle"
        let img = NSImage(systemSymbolName: name, accessibilityDescription: "Adia")
        img?.isTemplate = true
        return img
        #else
        return nil
        #endif
    }

    private func updateIcon(hasSession: Bool) {
        #if canImport(AppKit)
        statusItem?.button?.image = Self.statusImage(active: hasSession)
        #endif
    }

    // MARK: - Click handling

    @objc private func handleClick() {
        #if canImport(AppKit)
        guard let event = NSApp.currentEvent else { fire(); return }
        if event.type == .rightMouseUp {
            showContextMenu()
        } else {
            fire()
        }
        #endif
    }

    /// Same toggle logic as GlobalHotkeyManager.
    private func fire() {
        if SessionManager.shared.session == nil {
            NotchState.shared.startCreating()
        } else {
            NotchState.shared.toggle()
        }
    }

    // MARK: - Context menu

    #if canImport(AppKit)
    private func showContextMenu() {
        let menu = NSMenu()

        let headerTitle: String
        if let s = SessionManager.shared.session {
            let phaseLabel = s.phase == .paused ? "Session Paused" : "Session Active"
            let offlineLabel = NetworkMonitor.shared.isCircuitOpen ? " (Offline)" : ""
            headerTitle = "Adia — \(phaseLabel)\(offlineLabel)"
        } else {
            headerTitle = "Adia — Focus App"
        }
        let header = NSMenuItem(title: headerTitle, action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(.separator())

        if let s = SessionManager.shared.session {
            if s.phase == .paused {
                let resume = NSMenuItem(title: "Resume Session", action: #selector(resumeSession), keyEquivalent: "")
                resume.target = self
                menu.addItem(resume)
            } else {
                let pause = NSMenuItem(title: "Pause Session", action: #selector(pauseSession), keyEquivalent: "")
                pause.target = self
                menu.addItem(pause)
            }
            let item = NSMenuItem(title: "End Session", action: #selector(endSession), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        } else {
            let item = NSMenuItem(title: "Start Session…", action: #selector(startSession), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }

        menu.addItem(.separator())

        let settings = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(settings)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Adia", action: #selector(quitAdia), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        // Assign the menu, trigger a synthetic click so AppKit positions and shows
        // it, then clear the assignment so future left-clicks route to handleClick.
        statusItem?.menu = menu
        statusItem?.button?.performClick(nil)
        statusItem?.menu = nil
    }
    #endif

    // MARK: - Menu actions

    @objc private func startSession() {
        NotchState.shared.startCreating()
    }

    @objc private func pauseSession() {
        Task { await SessionManager.shared.pauseSession() }
    }

    @objc private func resumeSession() {
        Task { await SessionManager.shared.resumeSession() }
    }

    @objc private func endSession() {
        Task { await SessionManager.shared.endSession() }
    }

    @objc private func openSettings() {
        #if canImport(AppKit)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)
        #endif
    }

    @objc private func quitAdia() {
        #if canImport(AppKit)
        NSApp.terminate(nil)
        #endif
    }
}
