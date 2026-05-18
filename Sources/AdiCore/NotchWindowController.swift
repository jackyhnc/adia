import AppKit
import SwiftUI
import Combine

// MARK: - NotchPanel

/// Borderless, non-activating NSPanel that floats above all windows.
/// Lives in the notch area on MacBook Pro; falls back to top-center on other Macs.
private final class NotchPanel: NSPanel {
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        configure()
    }

    required init?(coder: NSCoder) { nil }

    private func configure() {
        isMovable = false
        isMovableByWindowBackground = false
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        // Float above status bar items and fullscreen apps.
        level = .init(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    }

    // Accept mouse events without making the app the key application.
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// MARK: - NotchWindowController

@MainActor
public final class NotchWindowController: NSWindowController {

    // MARK: Layout constants
    private static let expandedWidth: CGFloat  = 340
    private static let expandedHeight: CGFloat = 190

    // MARK: Private state
    private var notchPanel: NotchPanel { window as! NotchPanel }  // always safe: we create it
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    public init() {
        let panel = NotchPanel()
        super.init(window: panel)

        // SwiftUI content — singletons are passed explicitly so the view init
        // runs in this @MainActor context where accessing them is safe.
        let rootView = NotchRootView(state: .shared, session: .shared)
        panel.contentView = NSHostingView(rootView: rootView)

        positionPanel(expanded: false, animate: false)
        panel.orderFrontRegardless()

        observeState()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    // MARK: State observation

    private func observeState() {
        NotchState.shared.$isExpanded
            .dropFirst()
            .sink { [weak self] expanded in
                // Sink fires on whatever thread publishes; hop to MainActor explicitly.
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.positionPanel(expanded: expanded, animate: true)
                    self.notchPanel.hasShadow = expanded
                }
            }
            .store(in: &cancellables)
    }

    // MARK: Panel sizing / positioning

    private func positionPanel(expanded: Bool, animate: Bool) {
        guard let screen = NSScreen.main else { return }
        let target = targetFrame(expanded: expanded, screen: screen)
        if animate {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.28
                ctx.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                notchPanel.animator().setFrame(target, display: true)
            }
        } else {
            notchPanel.setFrame(target, display: false)
        }
    }

    /// The notch slot on MacBook Pro 14/16". Falls back to a top-center pill on other Macs.
    private func notchBaseRect(screen: NSScreen) -> NSRect {
        if #available(macOS 12.0, *),
           screen.safeAreaInsets.top > 0,
           let left = screen.auxiliaryTopLeftArea,
           let right = screen.auxiliaryTopRightArea {
            return NSRect(
                x: left.maxX,
                y: screen.frame.maxY - screen.safeAreaInsets.top,
                width: right.minX - left.maxX,
                height: screen.safeAreaInsets.top
            )
        }
        let w: CGFloat = 200
        let h: CGFloat = 32
        return NSRect(
            x: screen.frame.midX - w / 2,
            y: screen.frame.maxY - h,
            width: w,
            height: h
        )
    }

    private func targetFrame(expanded: Bool, screen: NSScreen) -> NSRect {
        let base = notchBaseRect(screen: screen)
        guard expanded else { return base }
        let w = max(base.width, Self.expandedWidth)
        let h = Self.expandedHeight
        let x = screen.frame.midX - w / 2
        let y = base.maxY - h   // grows downward from the notch top edge
        return NSRect(x: x, y: y, width: w, height: h)
    }
}
