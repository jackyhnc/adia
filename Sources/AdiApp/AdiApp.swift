import SwiftUI
import AdiCore

@main
struct AdiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No default window — Adia lives in the notch overlay only.
        Settings {
            SettingsView()
        }
    }
}
