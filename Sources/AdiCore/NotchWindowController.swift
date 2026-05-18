import AppKit

// Placeholder — implemented fully in the Notch UI task.
@MainActor
public final class NotchWindowController: NSWindowController {
    public convenience init() {
        // Temporary plain window until the notch panel is implemented.
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = false
        self.init(window: window)
    }
}
