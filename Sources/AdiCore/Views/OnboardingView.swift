import SwiftUI
import AppKit

public struct OnboardingView: View {
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var license = LicenseManager.shared

    public enum Step: Int { case welcome, apiKey, license, done }
    @State private var step: Step = .welcome
    @State private var apiKeyDraft: String = ""
    @State private var licenseKeyDraft: String = ""
    @State private var emailDraft: String = ""
    @State private var activationError: String?
    @State private var activating = false

    public var onFinish: () -> Void

    public init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    public var body: some View {
        VStack(spacing: 0) {
            header
            Divider().padding(.vertical, 12)
            Group {
                switch step {
                case .welcome: welcome
                case .apiKey:  apiKeyScreen
                case .license: licenseScreen
                case .done:    Color.clear
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            footer
        }
        .padding(24)
        .frame(width: 520, height: 460)
        .background(Color(NSColor.windowBackgroundColor))
    }

    private var header: some View {
        HStack {
            Text("Welcome to Adia").font(.title2).bold()
            Spacer()
            Text(stepLabel).foregroundStyle(.secondary).font(.caption)
        }
    }

    private var stepLabel: String {
        switch step {
        case .welcome: return "1 of 3"
        case .apiKey:  return "2 of 3"
        case .license: return "3 of 3"
        case .done:    return ""
        }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("The friend in your notch who keeps you on task.")
                .font(.title3)
            Text("Tell Adia what you're working on. It watches your screen, blocks distracting sites, and calls you out when you wander off — like a friend sitting next to you.")
                .foregroundStyle(.secondary)
            Spacer()
            Label("Adia needs Screen Recording permission to work. macOS will ask you on first session.", systemImage: "info.circle")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
    }

    private var apiKeyScreen: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OpenAI API key").font(.headline)
            Text("Adia uses GPT to watch your screen. You bring your own API key — we never see your data.")
                .foregroundStyle(.secondary)
                .font(.callout)
            SecureField("sk-proj-...", text: $apiKeyDraft)
                .textFieldStyle(.roundedBorder)
            Link("Get a key from platform.openai.com →",
                 destination: URL(string: "https://platform.openai.com/api-keys")!)
                .font(.callout)
            Spacer()
        }
    }

    private var licenseScreen: some View {
        VStack(alignment: .leading, spacing: 12) {
            switch license.status {
            case .licensed(let email, let plan):
                Label("Activated as \(email) (\(plan))", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            case .trial(let days):
                Label("Trial active — \(days) day\(days == 1 ? "" : "s") left",
                      systemImage: "clock")
            default:
                EmptyView()
            }

            Text("Have a license key?").font(.headline)
            TextField("Email", text: $emailDraft).textFieldStyle(.roundedBorder)
            TextField("ADIA-XXXX-XXXX-XXXX", text: $licenseKeyDraft)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button(activating ? "Activating…" : "Activate") {
                    Task { await activate() }
                }
                .disabled(activating || licenseKeyDraft.isEmpty || emailDraft.isEmpty)

                Spacer()

                Button("Start 7-day trial") {
                    license.startTrialIfNeeded()
                }
                .disabled({ if case .trial = license.status { return true }; return false }())
            }

            if let err = activationError {
                Text(err).foregroundStyle(.red).font(.callout)
            }

            Spacer()
            Link("Buy a license at adia.app →",
                 destination: URL(string: "https://adia.app/pricing")!)
                .font(.callout)
        }
    }

    private var footer: some View {
        HStack {
            if step != .welcome {
                Button("Back") { step = Step(rawValue: step.rawValue - 1) ?? .welcome }
            }
            Spacer()
            Button(continueLabel) { advance() }
                .buttonStyle(.borderedProminent)
                .disabled(!canAdvance)
        }
    }

    private var continueLabel: String {
        switch step {
        case .welcome: return "Continue"
        case .apiKey:  return "Continue"
        case .license: return "Finish"
        case .done:    return "Done"
        }
    }

    private var canAdvance: Bool {
        switch step {
        case .welcome: return true
        case .apiKey:  return !apiKeyDraft.trimmingCharacters(in: .whitespaces).isEmpty
            || settings.hasAPIKey
        case .license: return license.isUsable
        case .done:    return true
        }
    }

    private func advance() {
        switch step {
        case .welcome:
            step = .apiKey
        case .apiKey:
            if !apiKeyDraft.trimmingCharacters(in: .whitespaces).isEmpty {
                settings.setAPIKey(apiKeyDraft)
            }
            step = .license
        case .license:
            onFinish()
        case .done:
            onFinish()
        }
    }

    private func activate() async {
        activating = true
        activationError = nil
        let err = await license.activate(key: licenseKeyDraft, email: emailDraft)
        activating = false
        activationError = err
    }
}
