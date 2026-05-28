import SwiftUI
import AppKit
import UniformTypeIdentifiers

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
    @State private var stats: SessionStats? = nil
    @State private var showingClearAlert: Bool = false
    @State private var expandedRecordID: UUID? = nil

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
                VStack(spacing: 0) {
                    if let s = stats, s.weekCount > 0 {
                        weeklySummaryHeader(s)
                    }
                    List(records) { record in
                        SessionRecordRow(
                            record: record,
                            isExpanded: expandedRecordID == record.id,
                            onTap: {
                                withAnimation(.easeOut(duration: 0.18)) {
                                    expandedRecordID = expandedRecordID == record.id ? nil : record.id
                                }
                            },
                            onNoteChange: { newNote in
                                let id = record.id
                                Task { @MainActor in
                                    await SessionHistory.shared.updateNote(id: id, note: newNote)
                                    if let idx = records.firstIndex(where: { $0.id == id }) {
                                        var updated = records[idx]
                                        updated.note = newNote.isEmpty ? nil : newNote
                                        records[idx] = updated
                                    }
                                }
                            },
                            onDelete: {
                                let id = record.id
                                Task { @MainActor in
                                    await SessionHistory.shared.delete(id: id)
                                    withAnimation(.easeOut(duration: 0.18)) {
                                        records.removeAll { $0.id == id }
                                        if expandedRecordID == id { expandedRecordID = nil }
                                    }
                                    stats = await SessionHistory.shared.stats()
                                }
                            }
                        )
                    }
                    .listStyle(.inset)

                    HStack {
                        Button("Clear All") { showingClearAlert = true }
                            .buttonStyle(.borderless)
                            .font(.callout)
                            .foregroundStyle(.red.opacity(0.7))
                            .padding(.leading, 12)
                            .padding(.vertical, 8)
                        Spacer()
                        Button("Export CSV…") { exportCSV(records) }
                            .buttonStyle(.borderless)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 12)
                            .padding(.vertical, 8)
                    }
                    .background(.background)
                }
            }
        }
        .alert("Clear session history?", isPresented: $showingClearAlert) {
            Button("Clear", role: .destructive) {
                Task { @MainActor in
                    await SessionHistory.shared.clear()
                    records = []
                    stats = nil
                    expandedRecordID = nil
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all \(records.count) session record\(records.count == 1 ? "" : "s"). This cannot be undone.")
        }
        .task {
            records = await SessionHistory.shared.load()
            stats = await SessionHistory.shared.stats()
        }
    }

    private func weeklySummaryHeader(_ s: SessionStats) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.secondary)
            Text(weekSummaryText(s))
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.secondary)
            if s.streak > 1 {
                Text("🔥 \(s.streak)d streak")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2)
                    .background(.orange.opacity(0.1))
                    .clipShape(Capsule())
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background(.background)
    }

    private func weekSummaryText(_ s: SessionStats) -> String {
        let sessions = "\(s.weekCount) session\(s.weekCount == 1 ? "" : "s") this week"
        guard s.weekMinutes > 0 else { return sessions }
        let h = s.weekMinutes / 60
        let m = s.weekMinutes % 60
        let time: String
        if h > 0 && m > 0 { time = "\(h)h \(m)m" }
        else if h > 0 { time = "\(h)h" }
        else { time = "\(m)m" }
        return "\(sessions) · \(time)"
    }

    private func exportCSV(_ records: [SessionRecord]) {
        var csv = "Date,Task,Success Criteria,Duration (min),Completed,Callouts,Note\n"
        let fmt = ISO8601DateFormatter()
        for r in records {
            let date = fmt.string(from: r.startTime)
            let task = r.task.replacingOccurrences(of: "\"", with: "\"\"")
            let criteria = r.successCriteria.replacingOccurrences(of: "\"", with: "\"\"")
            let mins = Int(r.duration / 60)
            let done = r.completedSuccessfully ? "Yes" : "No"
            let note = (r.note ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            csv += "\"\(date)\",\"\(task)\",\"\(criteria)\",\(mins),\(done),\(r.calloutCount),\"\(note)\"\n"
        }

        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = "adia-history.csv"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

private struct SessionRecordRow: View {
    let record: SessionRecord
    let isExpanded: Bool
    let onTap: () -> Void
    /// Called with the trimmed note text (empty string means "clear note") when
    /// the user commits an edit via Return or by moving focus away.
    var onNoteChange: ((String) -> Void)? = nil
    /// Called when the user taps the trash button in the expanded detail panel.
    var onDelete: (() -> Void)? = nil

    @State private var noteDraft: String = ""
    @FocusState private var noteFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Summary row — always visible
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

                HStack(spacing: 6) {
                    Text(record.startTime, style: .date)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 2)
            .contentShape(Rectangle())
            .onTapGesture { onTap() }

            // Detail panel — shown when expanded
            if isExpanded {
                VStack(alignment: .leading, spacing: 10) {
                    Divider()
                        .padding(.top, 6)

                    detailField("Task", record.task)

                    if !record.successCriteria.isEmpty {
                        detailField("Done when", record.successCriteria)
                    }

                    HStack(alignment: .top, spacing: 20) {
                        detailField("Started",
                            record.startTime.formatted(date: .abbreviated, time: .shortened))
                        detailField("Ended",
                            record.endTime.formatted(date: .abbreviated, time: .shortened))
                    }

                    HStack(alignment: .top, spacing: 20) {
                        detailField("Duration", formattedDuration(record.duration))
                        detailField("Callouts",
                            record.calloutCount == 0 ? "None" : "\(record.calloutCount)")
                    }

                    noteEditorField

                    if onDelete != nil {
                        HStack {
                            Spacer()
                            Button {
                                onDelete?()
                            } label: {
                                Label("Delete session", systemImage: "trash")
                                    .font(.callout)
                                    .foregroundStyle(.red.opacity(0.7))
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.bottom, 8)
                .padding(.leading, 26) // visually aligns with task text
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeOut(duration: 0.18), value: isExpanded)
        .onAppear { noteDraft = record.note ?? "" }
        .onChange(of: record.note) { _, newNote in noteDraft = newNote ?? "" }
    }

    // MARK: Note editor

    @ViewBuilder
    private var noteEditorField: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NOTE")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)
                .tracking(0.8)
            ZStack(alignment: .leading) {
                if noteDraft.isEmpty && !noteFocused {
                    Text("Add a note…")
                        .font(.callout)
                        .foregroundStyle(Color.primary.opacity(0.25))
                        .allowsHitTesting(false)
                }
                TextField("", text: $noteDraft)
                    .font(.callout)
                    .textFieldStyle(.plain)
                    .focused($noteFocused)
                    .onSubmit { commitNote() }
                    .onChange(of: noteFocused) { _, isFocused in
                        if !isFocused { commitNote() }
                    }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(Color.primary.opacity(noteFocused ? 0.18 : 0.08), lineWidth: 0.5)
            )
        }
    }

    private func commitNote() {
        onNoteChange?(noteDraft.trimmingCharacters(in: .whitespaces))
    }

    @ViewBuilder
    private func detailField(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.tertiary)
                .tracking(0.8)
            Text(value)
                .font(.callout)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
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
