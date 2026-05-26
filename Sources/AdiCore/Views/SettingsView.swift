import SwiftUI
import AppKit

// MARK: - Root Settings Window

public struct SettingsView: View {
    public init() {}

    public var body: some View {
        TabView {
            AccountSettingsTab()
                .tabItem { Label("Account", systemImage: "person.circle") }
                .tag(0)
            BlockingSettingsTab()
                .tabItem { Label("Blocking", systemImage: "hand.raised.fill") }
                .tag(1)
            HistoryTab()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(2)
        }
        .padding(20)
        .frame(width: 480, height: 440)
    }
}

// MARK: - Account Tab

private struct AccountSettingsTab: View {
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var license  = LicenseManager.shared

    @State private var apiKeyDraft:  String = ""
    @State private var editingAPIKey: Bool  = false
    @State private var licenseKey:   String = ""
    @State private var email:        String = ""
    @State private var activating:   Bool   = false
    @State private var activateError: String?

    var body: some View {
        Form {
            Section {
                apiKeyRow
            } header: {
                Text("Anthropic API Key")
            } footer: {
                Text("Used for screen analysis. Never sent to Adia servers.")
                    .foregroundStyle(.secondary)
            }

            Section {
                licenseRow
            } header: {
                Text("License")
            }
        }
        .formStyle(.grouped)
    }

    // MARK: API Key row

    @ViewBuilder
    private var apiKeyRow: some View {
        if editingAPIKey {
            HStack {
                SecureField("sk-ant-…", text: $apiKeyDraft)
                Button("Save") {
                    settings.setAPIKey(apiKeyDraft)
                    apiKeyDraft   = ""
                    editingAPIKey = false
                }
                .disabled(apiKeyDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                Button("Cancel") {
                    apiKeyDraft   = ""
                    editingAPIKey = false
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
        } else {
            HStack {
                if settings.hasAPIKey {
                    Text(maskedKey)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                } else {
                    Text("Not set")
                        .foregroundStyle(.red)
                }
                Spacer()
                Button(settings.hasAPIKey ? "Update" : "Add") {
                    editingAPIKey = true
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private var maskedKey: String {
        guard let k = settings.anthropicAPIKey, k.count > 8 else { return "sk-•••••••" }
        let prefix = k.hasPrefix("sk-") ? String(k.prefix(min(7, k.count))) : "sk-"
        return "\(prefix)…\(k.suffix(6))"
    }

    // MARK: License row

    @ViewBuilder
    private var licenseRow: some View {
        switch license.status {
        case .licensed(let em, let plan):
            LabeledContent("Status") {
                Label("\(plan) — \(em)", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }
        case .trial(let days):
            VStack(alignment: .leading, spacing: 8) {
                LabeledContent("Status") {
                    Label("\(days) day\(days == 1 ? "" : "s") left in trial",
                          systemImage: "clock")
                        .foregroundStyle(.orange)
                }
                Link("Upgrade at adia.app →",
                     destination: URL(string: "https://adia.app/pricing")!)
                    .font(.callout)
            }
        case .trialExpired, .invalid:
            VStack(alignment: .leading, spacing: 8) {
                Label("Trial expired", systemImage: "exclamationmark.circle")
                    .foregroundStyle(.red)
                activateSection
            }
        default:
            activateSection
        }
    }

    @ViewBuilder
    private var activateSection: some View {
        TextField("Email", text: $email)
        SecureField("License key (ADIA-XXXX-XXXX-XXXX)", text: $licenseKey)
        HStack {
            Button(activating ? "Activating…" : "Activate License") {
                Task { await activate() }
            }
            .disabled(activating || licenseKey.isEmpty || email.isEmpty)
            Spacer()
            Link("Buy a license →",
                 destination: URL(string: "https://adia.app/pricing")!)
                .font(.callout)
        }
        if let err = activateError {
            Text(err).foregroundStyle(.red).font(.callout)
        }
    }

    private func activate() async {
        activating    = true
        activateError = nil
        activateError = await license.activate(key: licenseKey, email: email)
        activating    = false
    }
}

// MARK: - Blocking Tab

private struct BlockingSettingsTab: View {
    @ObservedObject private var settings = SettingsStore.shared
    @State private var newDomain = ""
    @FocusState private var addFieldFocused: Bool

    var body: some View {
        Form {
            Section {
                ForEach(Session.defaultBlockedDomains, id: \.self) { domain in
                    Toggle(domain, isOn: Binding(
                        get: { settings.isDefaultDomainEnabled(domain) },
                        set: { settings.setDefaultDomain(domain, enabled: $0) }
                    ))
                }
            } header: {
                Text("Default Block List")
            } footer: {
                Text("Disabled domains are skipped in new sessions but not unblocked mid-session.")
                    .foregroundStyle(.secondary)
            }

            Section {
                if settings.customBlockedDomains.isEmpty {
                    Text("No custom domains")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(settings.customBlockedDomains, id: \.self) { domain in
                        HStack {
                            Text(domain)
                            Spacer()
                            Button {
                                settings.removeCustomDomain(domain)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                HStack {
                    TextField("e.g. chess.com", text: $newDomain)
                        .focused($addFieldFocused)
                        .onSubmit { addDomain() }
                    Button("Add") { addDomain() }
                        .disabled(newDomain.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } header: {
                Text("Custom Domains")
            } footer: {
                Text("Additional sites to block. Enter the domain without https:// or www.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func addDomain() {
        settings.addCustomDomain(newDomain)
        newDomain = ""
        addFieldFocused = false
    }
}

// MARK: - History Tab

private struct HistoryTab: View {
    @State private var records: [SessionRecord] = []

    var body: some View {
        Group {
            if records.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No sessions yet")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Completed sessions will appear here.")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(records) { record in
                    SessionRecordRow(record: record)
                }
                .listStyle(.inset)
            }
        }
        .task {
            records = await SessionHistory.shared.load()
        }
    }
}

private struct SessionRecordRow: View {
    let record: SessionRecord

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: record.completedSuccessfully ? "checkmark.circle.fill" : "arrow.uturn.left.circle.fill")
                .foregroundStyle(record.completedSuccessfully ? .green : .secondary)
                .font(.system(size: 16))
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.task)
                    .font(.body)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Label(formattedDuration(record.duration), systemImage: "clock")
                    if record.calloutCount > 0 {
                        Label("\(record.calloutCount) callout\(record.calloutCount == 1 ? "" : "s")",
                              systemImage: "exclamationmark.bubble")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer()

            Text(record.startTime, style: .date)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }

    private func formattedDuration(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval))
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m" }
        return "<1m"
    }
}
