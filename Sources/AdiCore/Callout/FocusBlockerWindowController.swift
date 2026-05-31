import AppKit
import SwiftUI
import Combine

// MARK: - BlockerPanel

/// Borderless full-screen panel that sits ABOVE the notch panel and covers the
/// distraction. Non-activating so it doesn't yank the app into the foreground,
/// but key-capable so its buttons are clickable.
private final class BlockerPanel: NSPanel {
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        isReleasedWhenClosed = false
        hidesOnDeactivate = false
        // One above the notch panel (statusBar + 1) so the takeover covers it too.
        level = .init(rawValue: NSWindow.Level.statusBar.rawValue + 2)
        backgroundColor = .clear
        isOpaque = false
        hasShadow = false
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    }

    required init?(coder: NSCoder) { nil }
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

// MARK: - FocusBlockerWindowController

/// Owns the takeover panel and shows/hides it in response to NotchState.isBlocking.
/// Mirrors the observe-the-singleton pattern used by NotchWindowController.
@MainActor
public final class FocusBlockerWindowController: NSWindowController {

    private var blockerPanel: NSPanel { window as! NSPanel }
    private var cancellables = Set<AnyCancellable>()

    public init() {
        let panel = BlockerPanel()
        super.init(window: panel)
        panel.contentView = NSHostingView(rootView: FocusBlockerView(state: .shared))
        observe()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { nil }

    private func observe() {
        NotchState.shared.$isBlocking
            .removeDuplicates()
            .sink { [weak self] blocking in
                Task { @MainActor [weak self] in self?.apply(blocking) }
            }
            .store(in: &cancellables)
    }

    private func apply(_ blocking: Bool) {
        if blocking {
            // Cover the full screen the user is actually looking at.
            let screen = NSScreen.main ?? NSScreen.screens.first
            if let frame = screen?.frame {
                blockerPanel.setFrame(frame, display: true)
            }
            blockerPanel.orderFrontRegardless()
            blockerPanel.makeKey()
        } else {
            blockerPanel.orderOut(nil)
        }
    }
}

// MARK: - FocusBlockerView

/// The full-screen intervention. Dims the distraction and forces a deliberate
/// choice: get back to work, or sit through a few seconds of friction before you
/// can opt to keep wasting time. You can always get past it — but never mindlessly.
struct FocusBlockerView: View {
    @ObservedObject var state: NotchState

    // Seconds the "keep scrolling" escape hatch stays disabled.
    private let frictionSeconds = 5
    @State private var secondsLeft = 5

    var body: some View {
        ZStack {
            // Obscure whatever's behind it.
            Color.black.opacity(0.55)
            Rectangle().fill(.ultraThinMaterial)

            VStack(spacing: 24) {
                Text(state.blockerMessage ?? "back to work.")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                if let goal = SessionManager.shared.session?.task, !goal.isEmpty {
                    VStack(spacing: 6) {
                        Text("YOU SAID YOU'D")
                            .font(.system(size: 13, weight: .semibold))
                            .tracking(2)
                            .foregroundStyle(.white.opacity(0.55))
                        Text(goal)
                            .font(.system(size: 22, weight: .medium, design: .rounded))
                            .foregroundStyle(.white.opacity(0.92))
                            .multilineTextAlignment(.center)
                    }
                }

                HStack(spacing: 16) {
                    Button(action: dismiss) {
                        Text("Back to work")
                            .font(.system(size: 17, weight: .semibold))
                            .padding(.horizontal, 28)
                            .padding(.vertical, 14)
                            .background(Color.white, in: Capsule())
                            .foregroundStyle(.black)
                    }
                    .buttonStyle(.plain)
                    .keyboardShortcut(.defaultAction)

                    Button(action: dismiss) {
                        Text(secondsLeft > 0 ? "keep scrolling (\(secondsLeft))" : "keep scrolling")
                            .font(.system(size: 17, weight: .medium))
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(Color.white.opacity(0.12), in: Capsule())
                            .foregroundStyle(.white.opacity(secondsLeft > 0 ? 0.4 : 0.8))
                    }
                    .buttonStyle(.plain)
                    .disabled(secondsLeft > 0)
                }
                .padding(.top, 8)
            }
            .padding(40)
        }
        .ignoresSafeArea()
        .onChange(of: state.isBlocking) { _, blocking in
            if blocking { startFriction() }
        }
        .onAppear { if state.isBlocking { startFriction() } }
    }

    private func dismiss() {
        CalloutManager.shared.dismissBlocker()
    }

    private func startFriction() {
        secondsLeft = frictionSeconds
        Task { @MainActor in
            while secondsLeft > 0 {
                try? await Task.sleep(for: .seconds(1))
                // Stop counting if the takeover was dismissed meanwhile.
                guard state.isBlocking else { return }
                secondsLeft -= 1
            }
        }
    }
}
