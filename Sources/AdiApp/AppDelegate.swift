import AppKit
import AdiCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    var notchController: NotchWindowController?
    var appState: AppState?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock — we live in the notch only
        NSApp.setActivationPolicy(.accessory)

        let state = AppState()
        self.appState = state

        // Restore in-progress session from disk
        if let saved = try? SessionPersistence.shared.load(), saved.status == .active {
            state.session = saved
        }

        let controller = NotchWindowController(appState: state)
        notchController = controller
        controller.show()
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Ensure hosts are unblocked if app quits unexpectedly mid-session
        if appState?.session?.status == .active {
            try? BlockingEngine.shared.unblockAll()
        }
    }
}
