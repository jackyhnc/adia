import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// System-wide keyboard shortcut (⌃⌥A) that expands the Adia notch from anywhere.
/// When no session is active, opens the session creation form.
/// During an active session, toggles expand/collapse.
@MainActor
public final class GlobalHotkeyManager {
    public static let shared = GlobalHotkeyManager()

    /// Human-readable label shown in Settings.
    public static let shortcutLabel = "⌃⌥A"

    private var localMonitor: Any?
    private var globalMonitor: Any?

    private init() {}

    public func start() {
        #if canImport(AppKit)
        // Local monitor: runs when Adia's own window is key. Return nil to consume
        // the event so it doesn't reach any other local responder.
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let keyCode = event.keyCode
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard flags == [.control, .option], keyCode == 0x00 else { return event }
            Task { @MainActor in GlobalHotkeyManager.shared.fire() }
            return nil
        }
        // Global monitor: runs when any other app is active. We can observe but
        // not consume — the front app still sees the keystroke. ⌃⌥A is uncommon
        // enough that double-handling is not a practical concern.
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            let keyCode = event.keyCode
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard flags == [.control, .option], keyCode == 0x00 else { return }
            Task { @MainActor in GlobalHotkeyManager.shared.fire() }
        }
        #endif
    }

    public func stop() {
        #if canImport(AppKit)
        if let m = localMonitor  { NSEvent.removeMonitor(m); localMonitor  = nil }
        if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }
        #endif
    }

    private func fire() {
        if SessionManager.shared.session == nil {
            NotchState.shared.startCreating()
        } else {
            NotchState.shared.toggle()
        }
    }
}
