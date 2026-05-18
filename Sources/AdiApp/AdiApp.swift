import SwiftUI

@main
struct AdiApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No visible window — the app lives in the notch panel.
        // Settings scene is required for @main App to compile without a WindowGroup.
        Settings {
            EmptyView()
        }
    }
}
