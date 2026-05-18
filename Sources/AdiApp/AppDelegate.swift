import AppKit
import AdiCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var notchController: NotchWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Run as agent — no dock icon, no menu bar icon.
        NSApp.setActivationPolicy(.accessory)
        notchController = NotchWindowController()
        notchController?.showWindow(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
