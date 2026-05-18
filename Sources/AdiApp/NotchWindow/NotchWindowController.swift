import AppKit
import SwiftUI
import AdiCore

/// NSPanel that lives in the notch area. Collapsed = slim pill; expanded = full card.
final class NotchWindowController: NSObject {
    private let panel: NSPanel
    private let appState: AppState

    // Geometry constants
    private static let panelWidth: CGFloat = 380
    private static let collapsedHeight: CGFloat = 8
    private static let expandedHeight: CGFloat = 180

    init(appState: AppState) {
        self.appState = appState

        let panel = NSPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .statusBar
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.isFloatingPanel = true
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        panel.ignoresMouseEvents = false

        let hostingView = NSHostingView(rootView:
            NotchView()
                .environmentObject(appState)
        )
        panel.contentView = hostingView
        self.panel = panel
        super.init()

        // React to appState.isExpanded changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExpansionChange),
            name: .adiaNotchExpandedChanged,
            object: nil
        )
    }

    func show() {
        repositionPanel(expanded: false)
        panel.orderFrontRegardless()
    }

    func collapse() {
        setExpanded(false)
    }

    func expand() {
        setExpanded(true)
    }

    // MARK: - Private

    private func setExpanded(_ expanded: Bool) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            repositionPanel(expanded: expanded)
        }
    }

    private func repositionPanel(expanded: Bool) {
        guard let screen = NSScreen.main else { return }
        let sf = screen.frame
        let menuBarHeight = NSStatusBar.system.thickness
        let height = expanded ? Self.expandedHeight : Self.collapsedHeight
        let x = sf.midX - Self.panelWidth / 2
        // Top of panel aligned with bottom of menu bar, panel grows downward
        let y = sf.maxY - menuBarHeight - height

        panel.animator().setFrame(
            NSRect(x: x, y: y, width: Self.panelWidth, height: height),
            display: true
        )
    }

    @objc private func handleExpansionChange(_ notification: Notification) {
        guard let expanded = notification.userInfo?["expanded"] as? Bool else { return }
        setExpanded(expanded)
    }
}

extension Notification.Name {
    static let adiaNotchExpandedChanged = Notification.Name("adiaNotchExpandedChanged")
}
