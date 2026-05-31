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
        level = .init(rawValue: NSWindow.Level.statusBar.rawValue + 1)
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// MARK: - NotchWindowController

@MainActor
public final class NotchWindowController: NSWindowController {

    // MARK: Layout constants
    private static let expandedWidth: CGFloat           = 360
    private static let expandedHeight: CGFloat          = 190
    // Extra height for active-session view when a callout banner is visible:
    // the red alert bar (~64pt) pushes task + buttons past the base frame.
    private static let calloutExpandedHeight: CGFloat   = 260
    // Tier-3 callout uses larger font + more padding, needing 20pt more room.
    private static let tier3CalloutExpandedHeight: CGFloat = 280
    private static let creationExpandedHeight: CGFloat  = 310
    private static let conversationHeight: CGFloat      = 390
    private static let verificationHeight: CGFloat      = 220
    // Idle state is taller than the active-session base to accommodate the stats line.
    private static let idleExpandedHeight: CGFloat      = 220
    // Each pinned template button adds this much height to the idle panel.
    private static let perTemplateHeight: CGFloat       = 34

    // Small always-visible indicator shown when collapsed, sitting just below the
    // notch so the physical camera housing never hides it.
    private static let indicatorWidth: CGFloat          = 78
    private static let indicatorHeight: CGFloat         = 22
    // Gap between the bottom of the notch/menu bar and our panel.
    private static let topGap: CGFloat                  = 6

    // MARK: Private state
    private var notchPanel: NotchPanel { window as! NotchPanel }
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    public init() {
        let panel = NotchPanel()
        super.init(window: panel)

        let rootView = NotchRootView(state: .shared, session: .shared)
        panel.contentView = NSHostingView(rootView: rootView)

        positionPanel(animate: false)
        panel.orderFrontRegardless()

        observeState()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    // MARK: State observation

    private func observeState() {
        // Single handler: positionPanel reads all state from NotchState.shared directly,
        // so every property that affects panel size can share the same sink.
        let reposition: (Any) -> Void = { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.positionPanel(animate: true)
                self.notchPanel.hasShadow = NotchState.shared.isExpanded
            }
        }

        NotchState.shared.$isExpanded.dropFirst().sink(receiveValue: reposition).store(in: &cancellables)
        NotchState.shared.$isCreating.dropFirst().sink(receiveValue: reposition).store(in: &cancellables)
        NotchState.shared.$showingConversation.dropFirst().sink(receiveValue: reposition).store(in: &cancellables)
        NotchState.shared.$isVerifying.dropFirst().sink(receiveValue: reposition).store(in: &cancellables)
        NotchState.shared.$verificationResult.dropFirst().sink(receiveValue: reposition).store(in: &cancellables)
        NotchState.shared.$calloutMessage.dropFirst().sink(receiveValue: reposition).store(in: &cancellables)
        // Session start/end changes the height between idle (220pt) and active (190pt).
        SessionManager.shared.$session.dropFirst().sink(receiveValue: reposition).store(in: &cancellables)
        // Template count changes idle height.
        NotchState.shared.$idleTemplateCount.dropFirst().sink(receiveValue: reposition).store(in: &cancellables)
    }

    // MARK: Panel sizing / positioning

    private func positionPanel(animate: Bool) {
        guard let screen = NSScreen.main else { return }
        let target = targetFrame(screen: screen)
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

    /// Reads all panel-sizing state from NotchState.shared. Called exclusively from
    /// @MainActor context, so direct singleton access is safe and avoids the prior
    /// inconsistency of mixing boolean parameters with singleton reads.
    private func targetFrame(screen: NSScreen) -> NSRect {
        let state = NotchState.shared
        let base = notchBaseRect(screen: screen)

        // Collapsed: a small indicator pill centered just below the notch so it's
        // always visible (never hidden behind the camera housing).
        guard state.isExpanded else {
            let w = Self.indicatorWidth
            let h = Self.indicatorHeight
            let x = screen.frame.midX - w / 2
            let y = base.minY - Self.topGap - h
            return NSRect(x: x, y: y, width: w, height: h)
        }

        let h: CGFloat
        if state.showingConversation {
            h = Self.conversationHeight
        } else if state.isVerifying || state.verificationResult != nil {
            h = Self.verificationHeight
        } else if state.isCreating {
            h = Self.creationExpandedHeight
        } else if state.calloutMessage != nil {
            h = state.calloutTier >= 3 ? Self.tier3CalloutExpandedHeight : Self.calloutExpandedHeight
        } else if SessionManager.shared.session == nil {
            let tc = CGFloat(min(state.idleTemplateCount, 2))
            h = Self.idleExpandedHeight + tc * Self.perTemplateHeight
        } else {
            h = Self.expandedHeight
        }

        // Hang the card below the notch/menu bar, centered, fully on screen.
        let w = Self.expandedWidth
        let x = screen.frame.midX - w / 2
        let y = base.minY - Self.topGap - h
        return NSRect(x: x, y: y, width: w, height: h)
    }
}
