import SwiftUI
import AppKit
import CoreGraphics

/// First-launch onboarding introduces Adia, captures the user's Claude API key when
/// needed, and gets Screen Recording permission inline.
public struct OnboardingView: View {
    public enum Step: Int, CaseIterable { case welcome, key, permission }

    @State private var step: Step = .welcome
    @State private var screenGranted: Bool = CGPreflightScreenCaptureAccess()
    @ObservedObject private var settings = SettingsStore.shared
    @State private var apiKeyDraft: String = ""
    @State private var apiKeyError: String?
    @State private var polling = false
    @State private var settingsOpened = false
    @FocusState private var apiKeyFocused: Bool

    public var onFinish: () -> Void
    public init(onFinish: @escaping () -> Void) { self.onFinish = onFinish }

    private static let bg = Color(red: 0.055, green: 0.055, blue: 0.06)

    public var body: some View {
        ZStack {
            Self.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.horizontal, 44)
                    .padding(.top, 52)
                footer
            }
        }
        .frame(width: 560, height: 620)
        .onAppear {
            screenGranted = CGPreflightScreenCaptureAccess()
            if settings.hasAPIKey && !screenGranted {
                step = .permission
            }
        }
    }

    // MARK: - Content switcher

    @ViewBuilder
    private var content: some View {
        switch step {
        case .welcome:    welcome
        case .key:        key
        case .permission: permission
        }
    }

    // MARK: - Claude API key

    private var key: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                Circle()
                    .fill(settings.hasAPIKey ? Color.green.opacity(0.14) : Color.white.opacity(0.07))
                    .frame(width: 96, height: 96)
                Image(systemName: settings.hasAPIKey ? "checkmark" : "key.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(settings.hasAPIKey ? .green : .white.opacity(0.9))
            }
            Text(settings.hasAPIKey ? "Claude is connected" : "Connect Claude")
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 22)
            Text(settings.hasAPIKey
                 ? "Adia can now classify your screen and verify finished work."
                 : "Paste your Claude API key. It is stored in macOS Keychain and used only from this Mac.")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
                .padding(.horizontal, 8)
            Spacer()
            if !settings.hasAPIKey {
                VStack(alignment: .leading, spacing: 8) {
                    SecureField("sk-ant-...", text: $apiKeyDraft)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, design: .monospaced))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 11)
                        .background(Color.white.opacity(0.07))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(apiKeyError == nil ? Color.white.opacity(0.12) : Color.red.opacity(0.55), lineWidth: 0.5)
                        )
                        .focused($apiKeyFocused)
                        .onSubmit { saveAPIKey() }
                    if let apiKeyError {
                        Text(apiKeyError)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.orange.opacity(0.9))
                    }
                }
                .padding(.horizontal, 8)
                .onAppear {
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(250))
                        apiKeyFocused = true
                    }
                }
                Link("Get a Claude API key at console.anthropic.com",
                     destination: URL(string: "https://console.anthropic.com/settings/keys")!)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.65))
                    .padding(.top, 14)
            }
            Spacer()
        }
    }

    // MARK: - Welcome

    private var welcome: some View {
        VStack(spacing: 0) {
            Spacer()
            Text("adia")
                .font(.system(size: 58, weight: .black, design: .rounded))
                .foregroundStyle(.white)
            Text("the friend in your notch\nwho keeps you on task")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.top, 10)
            Spacer()
            VStack(alignment: .leading, spacing: 16) {
                featureRow("eye.fill", "Watches your screen",
                           "Sees what you're doing, second by second.")
                featureRow("hand.raised.fill", "Calls you out",
                           "Drift off and it nudges you back — instantly.")
                featureRow("checkmark.seal.fill", "Verifies you're done",
                           "Checks you actually finished before you stop.")
            }
            Spacer()
        }
    }

    // MARK: - Permission

    private var permission: some View {
        VStack(spacing: 0) {
            Spacer()
            ZStack {
                Circle()
                    .fill(screenGranted ? Color.green.opacity(0.14) : Color.white.opacity(0.07))
                    .frame(width: 96, height: 96)
                Image(systemName: screenGranted ? "checkmark" : "rectangle.inset.filled.badge.record")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(screenGranted ? .green : .white.opacity(0.9))
            }
            Text(screenGranted ? "Screen Recording is on" : "Request screen access")
                .font(.system(size: 23, weight: .bold))
                .foregroundStyle(.white)
                .padding(.top, 22)
            Text(screenGranted
                 ? "You're ready. Adia can see your screen to keep you honest."
                 : "Adia needs Screen Recording to tell when you wander off task. Click request access, drag Adia into the allowed apps list if macOS asks, then turn it on.")
                .font(.system(size: 14))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
                .padding(.horizontal, 8)
            Spacer()
            if !screenGranted {
                pillButton(settingsOpened ? "Check Access" : "Request Access", filled: true) {
                    requestPermission()
                }
                Text(settingsOpened
                     ? "Turn Adia on in System Settings. If Adia is missing, drag it from Finder into the app list, enable it, and Adia will bring you back here."
                     : "Adia will open the exact Privacy setting and reveal the app in Finder so it can be dragged into the list.")
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.3))
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
                    .padding(.horizontal, 12)
                Button {
                    relaunchApp()
                } label: {
                    Text("I enabled it - Restart Adia")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.6))
                        .underline()
                }
                .buttonStyle(.plain)
                .padding(.top, 14)
            }
            Spacer()
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack {
            HStack(spacing: 7) {
                ForEach(visibleSteps, id: \.rawValue) { s in
                    Circle()
                        .fill(s == step ? Color.white : Color.white.opacity(0.18))
                        .frame(width: 7, height: 7)
                }
            }
            Spacer()
            pillButton(continueLabel, filled: true, compact: true) { advance() }
                .opacity(canAdvance ? 1 : 0.4)
                .allowsHitTesting(canAdvance)
        }
        .padding(.horizontal, 44)
        .padding(.bottom, 34)
    }

    private var visibleSteps: [Step] {
        Step.allCases.filter { s in
            switch s {
            case .welcome: return true
            case .key: return !settings.hasAPIKey
            case .permission: return !screenGranted
            }
        }
    }

    private var continueLabel: String {
        switch step {
        case .welcome:    return settings.hasAPIKey && screenGranted ? "Open Adia" : "Continue"
        case .key:        return settings.hasAPIKey ? "Continue" : "Save Key"
        case .permission: return "Open Adia"
        }
    }

    private var canAdvance: Bool {
        switch step {
        case .welcome:    return true
        case .key:        return settings.hasAPIKey || !apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .permission: return screenGranted
        }
    }

    private func advance() {
        switch step {
        case .welcome:
            if !settings.hasAPIKey {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { step = .key }
            } else if !screenGranted {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { step = .permission }
            } else {
                onFinish()
            }
        case .key:
            if settings.hasAPIKey {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { step = .permission }
            } else {
                saveAPIKey()
            }
        case .permission:
            if screenGranted { onFinish() }
        }
    }

    private func saveAPIKey() {
        let trimmed = apiKeyDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            apiKeyError = "Paste your Claude API key to continue."
            return
        }
        guard settings.setAPIKey(trimmed) else {
            apiKeyError = "That does not look like a Claude key (should start with sk-ant-)."
            return
        }
        apiKeyDraft = ""
        apiKeyError = nil
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            step = screenGranted ? .welcome : .permission
        }
        if screenGranted { onFinish() }
    }

    // MARK: - Permission flow

    private func requestPermission() {
        if CGPreflightScreenCaptureAccess() {
            screenGranted = true
            return
        }
        // Triggers the system prompt the first time; afterwards it's a no-op that
        // just reflects current status.
        if CGRequestScreenCaptureAccess() {
            screenGranted = true
            return
        }
        // Not granted in-process — open the Settings pane and poll for the toggle.
        settingsOpened = true
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
        NSWorkspace.shared.open(URL(string:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
        startPolling()
    }

    /// macOS only grants Screen Recording to a fresh process, so once the user has
    /// flipped the toggle we relaunch a new instance and quit this one. On the next
    /// launch the permission preflight passes and onboarding moves straight on.
    private func relaunchApp() {
        let url = Bundle.main.bundleURL
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(at: url, configuration: config) { _, _ in
            Task { @MainActor in NSApp.terminate(nil) }
        }
    }

    private func startPolling() {
        guard !polling else { return }
        polling = true
        Task { @MainActor in
            for _ in 0..<600 where !screenGranted {   // ~10 min cap
                try? await Task.sleep(for: .seconds(1))
                if CGPreflightScreenCaptureAccess() {
                    withAnimation { screenGranted = true }
                    NSApp.activate(ignoringOtherApps: true)
                    try? await Task.sleep(for: .milliseconds(450))
                    onFinish()
                    break
                }
            }
            polling = false
        }
    }

    // MARK: - Building blocks

    @ViewBuilder
    private func featureRow(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundStyle(.white)
                Text(subtitle).font(.system(size: 12)).foregroundStyle(.white.opacity(0.45))
            }
            Spacer()
        }
    }

    @ViewBuilder
    private func pillButton(_ label: String, filled: Bool, compact: Bool = false,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(filled ? .black : .white)
                .padding(.horizontal, compact ? 22 : 30)
                .padding(.vertical, compact ? 10 : 14)
                .background(filled ? Color.white : Color.white.opacity(0.10))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
