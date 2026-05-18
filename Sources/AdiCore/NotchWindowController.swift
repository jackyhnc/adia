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
    private static let expandedWidth: CGFloat           = 340
    private static let expandedHeight: CGFloat          = 190
    private static let creationExpandedHeight: CGFloat  = 268
    private static let conversationHeight: CGFloat      = 390
    private static let verificationHeight: CGFloat      = 220

    // MARK: Private state
    private var notchPanel: NotchPanel { window as! NotchPanel }
    private var cancellables = Set<AnyCancellable>()

    // MARK: Init

    public init() {
        let panel = NotchPanel()
        super.init(window: panel)

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
        // Combine all state signals that affect panel size.
        Publishers.CombineLatest4(
            NotchState.shared.$isExpanded,
            NotchState.shared.$isCreating,
            NotchState.shared.$showingConversation,
            NotchState.shared.$isVerifying
        )
        .dropFirst()
        .sink { [weak self] expanded, creating, conversation, verifying in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.positionPanel(
                    expanded: expanded,
                    creating: creating,
                    conversation: conversation,
                    verifying: verifying,
                    animate: true
                )
                self.notchPanel.hasShadow = expanded
            }
        }
        .store(in: &cancellables)

        // Also react to verificationResult appearing (different height than verifying spinner).
        NotchState.shared.$verificationResult
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.positionPanel(
                        expanded: NotchState.shared.isExpanded,
                        creating: NotchState.shared.isCreating,
                        conversation: NotchState.shared.showingConversation,
                        verifying: NotchState.shared.isVerifying,
                        animate: true
                    )
                }
            }
            .store(in: &cancellables)
    }

    // MARK: Panel sizing / positioning

    private func positionPanel(
        expanded: Bool,
        creating: Bool = false,
        conversation: Bool = false,
        verifying: Bool = false,
        animate: Bool
    ) {
        guard let screen = NSScreen.main else { return }
        let target = targetFrame(
            expanded: expanded,
            creating: creating,
            conversation: conversation,
            verifying: verifying,
            screen: screen
        )
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

    private func targetFrame(
        expanded: Bool,
        creating: Bool,
        conversation: Bool,
        verifying: Bool,
        screen: NSScreen
    ) -> NSRect {
        let base = notchBaseRect(screen: screen)
        guard expanded else { return base }

        let h: CGFloat
        if conversation {
            h = Self.conversationHeight
        } else if verifying || NotchState.shared.verificationResult != nil {
            h = Self.verificationHeight
        } else if creating {
            h = Self.creationExpandedHeight
        } else {
            h = Self.expandedHeight
        }

        let w = max(base.width, Self.expandedWidth)
        let x = screen.frame.midX - w / 2
        let y = base.maxY - h
        return NSRect(x: x, y: y, width: w, height: h)
    }
}
