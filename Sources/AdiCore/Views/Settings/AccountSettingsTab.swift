import SwiftUI

struct AccountSettingsTab: View {
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var license  = LicenseManager.shared

    @State private var apiKeyDraft:  String = ""
    @State private var editingAPIKey: Bool  = false
    @State private var apiKeyError: String?
    @State private var licenseKey:   String = ""
    @State private var email:        String = ""
    @State private var activating:   Bool   = false
    @State private var activateError: String?
    @State private var deactivatingMachine: String? = nil
    @State private var deactivateError: String?
    @State private var editingEmail: Bool = false
    @State private var newEmailDraft: String = ""
    @State private var changingEmail: Bool = false
    @State private var emailChangeError: String?
    @State private var emailChangeSuccess: Bool = false
    @State private var showDeactivateThisMacAlert: Bool = false
    @State private var deactivatingThisMac: Bool = false
    @State private var deactivateThisMacError: String?

    var body: some View {
        Form {
            Section {
                apiKeyRow
            } header: {
                Text("Claude API Key")
            } footer: {
                Text("Used for screen analysis. Never sent to Adia servers.")
                    .foregroundStyle(.secondary)
            }

            Section {
                licenseRow
            } header: {
                Text("License")
            }

            if case .licensed = license.status {
                changeEmailSection
                seatsSection
            }

            Section {
                LabeledContent("Open / close Adia") {
                    Text(GlobalHotkeyManager.shortcutLabel)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Toggle("Show in menu bar", isOn: Binding(
                    get: { settings.showMenuBarItem },
                    set: { newValue in
                        settings.showMenuBarItem = newValue
                        if newValue {
                            MenuBarManager.shared.start()
                        } else {
                            MenuBarManager.shared.stop()
                        }
                    }
                ))
            } header: {
                Text("Keyboard Shortcuts")
            } footer: {
                Text("Works globally — press from any app to expand the notch. The menu bar icon provides the same controls on non-notch Macs.")
                    .foregroundStyle(.secondary)
            }

            Section {
                Picker("Remind me every", selection: $settings.timerExpiredRearmMinutes) {
                    ForEach(SettingsStore.timerExpiredRearmMinuteOptions, id: \.self) { minutes in
                        Text("\(minutes) min").tag(minutes)
                    }
                }
            } header: {
                Text("Reminders")
            } footer: {
                Text("When your session's timer runs out, Adia re-opens the notch on this interval until you verify you're done or end the session.")
                    .foregroundStyle(.secondary)
            }

            DailyGoalSection(settings: settings)
        }
        .formStyle(.grouped)
        .alert("Deactivate This Mac?", isPresented: $showDeactivateThisMacAlert) {
            Button("Deactivate", role: .destructive) {
                Task { await doDeactivateThisMac() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes Adia from this Mac and frees your license seat. You can reactivate anytime.")
        }
    }

    @ViewBuilder
    private var apiKeyRow: some View {
        if editingAPIKey {
            HStack {
                SecureField("sk-ant-...", text: $apiKeyDraft)
                Button("Save") {
                    if settings.setAPIKey(apiKeyDraft) {
                        apiKeyDraft   = ""
                        apiKeyError = nil
                        editingAPIKey = false
                    } else {
                        apiKeyError = "Enter a Claude API key (starts with sk-ant-)."
                    }
                }
                .disabled(apiKeyDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                Button("Cancel") {
                    apiKeyDraft   = ""
                    apiKeyError = nil
                    editingAPIKey = false
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }
            if let apiKeyError {
                Text(apiKeyError)
                    .font(.callout)
                    .foregroundStyle(.red)
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
        guard let k = settings.agentAIKey, k.count > 8 else { return "sk-•••••••" }
        let prefix = k.hasPrefix("sk-") ? String(k.prefix(min(7, k.count))) : "sk-"
        return "\(prefix)…\(k.suffix(6))"
    }

    @ViewBuilder
    private var licenseRow: some View {
        switch license.status {
        case .licensed(let em, let plan):
            LabeledContent("Status") {
                Label("\(plan) — \(em)", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
            }
            HStack {
                Spacer()
                if deactivatingThisMac {
                    ProgressView().scaleEffect(0.8)
                } else {
                    Button("Deactivate This Mac") {
                        showDeactivateThisMacAlert = true
                    }
                    .foregroundStyle(.red)
                    .buttonStyle(.borderless)
                }
            }
            if let err = deactivateThisMacError {
                Text(err).foregroundStyle(.red).font(.callout)
            }
        case .trial(let days):
            VStack(alignment: .leading, spacing: 8) {
                LabeledContent("Status") {
                    Label("\(days) day\(days == 1 ? "" : "s") left in trial",
                          systemImage: "clock")
                        .foregroundStyle(.orange)
                }
                Link("Upgrade at adia.app →",
                     // Force unwrap is safe: constant, well-formed URL string.
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
    private var seatsSection: some View {
        Section {
            if license.seatsLoading && license.seats.isEmpty {
                HStack {
                    ProgressView().scaleEffect(0.8)
                    Text("Loading seats…").foregroundStyle(.secondary)
                }
            } else if license.seats.isEmpty {
                Text("No seat data available.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(license.seats) { seat in
                    HStack(spacing: 0) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(seat.shortHash)
                                    .font(.system(.body, design: .monospaced))
                                if seat.isCurrentMachine {
                                    Text("this Mac")
                                        .font(.caption2)
                                        .foregroundStyle(.white)
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Color.accentColor, in: Capsule())
                                }
                            }
                            Text("Last seen \(seat.lastSeen.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if !seat.isCurrentMachine {
                            Button {
                                Task { await deactivateSeat(seat) }
                            } label: {
                                if deactivatingMachine == seat.machineHash {
                                    ProgressView().scaleEffect(0.7)
                                } else {
                                    Text("Remove")
                                        .foregroundStyle(.red)
                                        .font(.callout)
                                }
                            }
                            .buttonStyle(.borderless)
                            .disabled(deactivatingMachine != nil)
                        }
                    }
                }
                if let err = deactivateError {
                    Text(err).foregroundStyle(.red).font(.callout)
                }
            }
        } header: {
            HStack {
                Text("Activated Machines")
                Spacer()
                Button {
                    Task { await license.fetchSeats() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .disabled(license.seatsLoading)
            }
        } footer: {
            Text("Each license allows up to 2 simultaneous machines. Remove a machine to free a seat.")
                .foregroundStyle(.secondary)
        }
        .task { await license.fetchSeats() }
    }

    private func deactivateSeat(_ seat: SeatInfo) async {
        deactivatingMachine = seat.machineHash
        deactivateError = nil
        deactivateError = await license.deactivateMachine(seat.machineHash)
        deactivatingMachine = nil
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
                 // Force unwrap is safe: constant, well-formed URL string.
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

    @ViewBuilder
    private var changeEmailSection: some View {
        Section {
            if editingEmail {
                HStack {
                    TextField("New email address", text: $newEmailDraft)
                        .textContentType(.emailAddress)
                    Button(changingEmail ? "Saving…" : "Save") {
                        Task { await doChangeEmail() }
                    }
                    .disabled(changingEmail || newEmailDraft.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button("Cancel") {
                        newEmailDraft      = ""
                        emailChangeError   = nil
                        emailChangeSuccess = false
                        editingEmail       = false
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                if let err = emailChangeError {
                    Text(err).foregroundStyle(.red).font(.callout)
                }
                if emailChangeSuccess {
                    Text("Email updated.").foregroundStyle(.green).font(.callout)
                }
            } else {
                HStack {
                    if case .licensed(let em, _) = license.status {
                        Text(em).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Change") { editingEmail = true }
                        .buttonStyle(.borderless)
                }
            }
        } header: {
            Text("Email Address")
        } footer: {
            Text("The email address associated with your license. Used to log in to adia.app.")
                .foregroundStyle(.secondary)
        }
    }

    private func doDeactivateThisMac() async {
        deactivatingThisMac = true
        deactivateThisMacError = nil
        deactivateThisMacError = await license.deactivateThisMac()
        deactivatingThisMac = false
    }

    private func doChangeEmail() async {
        changingEmail      = true
        emailChangeError   = nil
        emailChangeSuccess = false
        let err = await license.changeEmail(newEmail: newEmailDraft)
        if err == nil {
            emailChangeSuccess = true
            newEmailDraft      = ""
            editingEmail       = false
        } else {
            emailChangeError = err
        }
        changingEmail = false
    }
}

// MARK: - Daily Goal Section

struct DailyGoalSection: View {
    @ObservedObject var settings: SettingsStore
    @State private var customGoalText: String = ""

    private var parsedCustomMinutes: Int? { parseCustomDuration(customGoalText) }
    private var isPreset: Bool {
        guard let goal = settings.dailyFocusGoalMinutes else { return false }
        return SettingsStore.dailyGoalPresets.contains { $0.0 == goal }
    }

    var body: some View {
        Section {
            HStack(spacing: 4) {
                ForEach(SettingsStore.dailyGoalPresets, id: \.0) { minutes, label in
                    Button {
                        if settings.dailyFocusGoalMinutes == minutes {
                            settings.dailyFocusGoalMinutes = nil
                        } else {
                            settings.dailyFocusGoalMinutes = minutes
                            customGoalText = ""
                        }
                    } label: {
                        Text(label)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(settings.dailyFocusGoalMinutes == minutes ? .white : .secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                settings.dailyFocusGoalMinutes == minutes
                                    ? Color.accentColor
                                    : Color.secondary.opacity(0.12),
                                in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                }
                if settings.dailyFocusGoalMinutes != nil {
                    Button {
                        settings.dailyFocusGoalMinutes = nil
                        customGoalText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                    .help("Clear daily goal")
                }
            }
            HStack(spacing: 6) {
                TextField("or type a custom goal (e.g. 2h, 90m, 1h30m)", text: $customGoalText)
                    .font(.system(size: 12))
                    .onSubmit {
                        if let parsed = parsedCustomMinutes {
                            settings.dailyFocusGoalMinutes = parsed
                            customGoalText = ""
                        }
                    }
                    .onChange(of: customGoalText) {
                        if let parsed = parsedCustomMinutes {
                            settings.dailyFocusGoalMinutes = parsed
                        }
                    }
                if !customGoalText.isEmpty {
                    Button { customGoalText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .font(.system(size: 13))
                    }
                    .buttonStyle(.plain)
                }
            }
        } header: {
            Text("Daily Focus Goal")
        } footer: {
            VStack(alignment: .leading, spacing: 4) {
                if !isPreset, let parsed = parsedCustomMinutes {
                    Text("= \(heatmapFormatMinutes(parsed))")
                        .foregroundStyle(.green.opacity(0.9))
                } else if !customGoalText.trimmingCharacters(in: .whitespaces).isEmpty, parsedCustomMinutes == nil {
                    Text("Couldn't parse — try \"2h\", \"90m\", or \"1h30m\".")
                        .foregroundStyle(.orange.opacity(0.8))
                }
                Text(settings.dailyFocusGoalMinutes != nil
                     ? "The notch shows your progress toward this goal each day."
                     : "Set a daily target to track your focus consistency.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
