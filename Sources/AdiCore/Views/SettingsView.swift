import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Root Settings Window

public struct SettingsView: View {
    /// Persisted so the user lands on their last-used tab on re-open.
    @AppStorage("settingsSelectedTab") private var selectedTab: Int = 0

    /// Per-tab window heights (points). Each value is hand-tuned to the natural
    /// content density of that tab — avoiding wasted whitespace on compact tabs
    /// while giving scrollable tabs more breathing room.
    nonisolated static let tabHeights: [Int: CGFloat] = [
        0: 400,   // Account  — 3 compact sections
        1: 560,   // Blocking — many toggles, benefits from tall viewport
        2: 460,   // Templates — list + footer row
        3: 540,   // History  — heatmap + session list
    ]

    var currentHeight: CGFloat { Self.tabHeights[selectedTab] ?? 500 }

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            AccountSettingsTab()
                .tabItem { Label("Account", systemImage: "person.circle") }
                .tag(0)
            BlockingSettingsTab()
                .tabItem { Label("Blocking", systemImage: "hand.raised.fill") }
                .tag(1)
            TemplatesSettingsTab()
                .tabItem { Label("Templates", systemImage: "pin.fill") }
                .tag(2)
            HistoryTab()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(3)
        }
        .padding(20)
        .frame(width: 480, height: currentHeight)
        .animation(.easeOut(duration: 0.18), value: selectedTab)
    }
}

// MARK: - Account Tab

private struct AccountSettingsTab: View {
    @ObservedObject private var settings = SettingsStore.shared
    @ObservedObject private var license  = LicenseManager.shared

    @State private var apiKeyDraft:  String = ""
    @State private var editingAPIKey: Bool  = false
    @State private var apiKeyError: String?
    @State private var licenseKey:   String = ""
    @State private var email:        String = ""
    @State private var activating:   Bool   = false
    @State private var activateError: String?

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
        }
        .formStyle(.grouped)
    }

    // MARK: API Key row

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
}

// MARK: - Blocking Tab

private struct BlockingSettingsTab: View {
    @ObservedObject private var settings = SettingsStore.shared
    @State private var newDomain = ""
    @FocusState private var addDomainFocused: Bool
    @State private var newAppBundleID = ""
    @FocusState private var addAppFocused: Bool
    @State private var showingAppPicker = false

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
                        .focused($addDomainFocused)
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

            Section {
                ForEach(Session.defaultBlockedApps) { app in
                    Toggle(app.name, isOn: Binding(
                        get: { settings.isDefaultAppEnabled(app.id) },
                        set: { settings.setDefaultApp(app.id, enabled: $0) }
                    ))
                }
            } header: {
                Text("Blocked Apps")
            } footer: {
                Text("When one of these apps becomes active during a session, Adia calls you out immediately.")
                    .foregroundStyle(.secondary)
            }

            Section {
                if settings.customBlockedApps.isEmpty {
                    Text("No custom apps")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(settings.customBlockedApps, id: \.self) { bundleID in
                        HStack {
                            Text(bundleID)
                                .font(.system(.body, design: .monospaced))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                settings.removeCustomApp(bundleID)
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundStyle(.red.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                Button {
                    showingAppPicker = true
                } label: {
                    Label("Pick from running apps…", systemImage: "apps.iphone.badge.plus")
                }
                .popover(isPresented: $showingAppPicker, arrowEdge: .bottom) {
                    RunningAppsPickerView(
                        alreadyBlocked: Set(settings.effectiveBlockedApps),
                        isPresented: $showingAppPicker,
                        onPick: { settings.addCustomApp($0) }
                    )
                }
                HStack {
                    TextField("e.g. com.hnc.Discord", text: $newAppBundleID)
                        .focused($addAppFocused)
                        .font(.system(.body, design: .monospaced))
                        .onSubmit { addApp() }
                    Button("Add") { addApp() }
                        .disabled(newAppBundleID.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            } header: {
                Text("Custom Apps")
            } footer: {
                Text("Pick a running app to add it instantly, or type a bundle identifier manually.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }

    private func addDomain() {
        settings.addCustomDomain(newDomain)
        newDomain = ""
        addDomainFocused = false
    }

    private func addApp() {
        let id = newAppBundleID.trimmingCharacters(in: .whitespaces)
        guard !id.isEmpty else { return }
        settings.addCustomApp(id)
        newAppBundleID = ""
        addAppFocused = false
    }
}

// MARK: - Running Apps Picker

private struct RunningAppInfo: Identifiable {
    let id: String      // bundle identifier
    let name: String
    let icon: NSImage?
}

private struct RunningAppsPickerView: View {
    let alreadyBlocked: Set<String>
    @Binding var isPresented: Bool
    let onPick: (String) -> Void

    @State private var query = ""
    @State private var apps: [RunningAppInfo] = []

    private var filtered: [RunningAppInfo] {
        guard !query.isEmpty else { return apps }
        let q = query.lowercased()
        return apps.filter {
            $0.name.lowercased().contains(q) || $0.id.lowercased().contains(q)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            TextField("Search apps…", text: $query)
                .textFieldStyle(.roundedBorder)
                .padding(12)

            Divider()

            if filtered.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "apps.iphone")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text(query.isEmpty ? "No blockable apps running." : "No apps match \"\(query)\".")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 180)
                .frame(maxWidth: .infinity)
            } else {
                List(filtered) { app in
                    Button {
                        onPick(app.id)
                        isPresented = false
                    } label: {
                        HStack(spacing: 10) {
                            Group {
                                if let icon = app.icon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .interpolation(.high)
                                } else {
                                    Image(systemName: "app.fill")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .frame(width: 28, height: 28)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(app.name)
                                    .fontWeight(.medium)
                                    .foregroundStyle(alreadyBlocked.contains(app.id) ? .secondary : .primary)
                                Text(app.id)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundStyle(.tertiary)
                            }

                            Spacer()

                            if alreadyBlocked.contains(app.id) {
                                Text("Blocked")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(.secondary.opacity(0.12), in: Capsule())
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(alreadyBlocked.contains(app.id))
                }
                .frame(height: 260)
                .listStyle(.plain)
            }
        }
        .frame(width: 320)
        .task { loadApps() }
    }

    private func loadApps() {
        let defaultIDs = Set(Session.defaultBlockedAppBundleIDs)
        var seen = Set<String>()
        var result: [RunningAppInfo] = []
        for app in NSWorkspace.shared.runningApplications {
            guard
                let bundleID = app.bundleIdentifier,
                let name = app.localizedName,
                !name.isEmpty,
                !bundleID.hasPrefix("com.apple."),
                seen.insert(bundleID).inserted,
                !defaultIDs.contains(bundleID)
            else { continue }
            result.append(RunningAppInfo(id: bundleID, name: name, icon: app.icon))
        }
        result.sort { $0.name.localizedCompare($1.name) == .orderedAscending }
        apps = result
    }
}

// MARK: - History Tab

/// Pure filter — extracted for testability.
internal func filterRecords(
    _ records: [SessionRecord],
    query: String,
    completed: Bool?
) -> [SessionRecord] {
    var result = records
    if let c = completed {
        result = result.filter { $0.completedSuccessfully == c }
    }
    let q = query.trimmingCharacters(in: .whitespaces).lowercased()
    guard !q.isEmpty else { return result }
    return result.filter {
        $0.task.lowercased().contains(q) ||
        $0.successCriteria.lowercased().contains(q) ||
        ($0.note?.lowercased().contains(q) ?? false)
    }
}

/// A single day bucket used by `groupedByDay`. `id` equals the section label.
internal struct DayGroup: Identifiable {
    var id: String { label }
    let label: String
    var records: [SessionRecord]
}

/// Returns the display label for a date: "Today", "Yesterday", or a locale-aware date string.
/// `now` controls the year comparison; `calendar` controls today/yesterday checks.
internal func dayLabel(for date: Date, calendar: Calendar = .current, now: Date = Date()) -> String {
    if calendar.isDateInToday(date)     { return "Today" }
    if calendar.isDateInYesterday(date) { return "Yesterday" }
    let currentYear = calendar.component(.year, from: now)
    let dateYear    = calendar.component(.year, from: date)
    if dateYear == currentYear {
        return date.formatted(.dateTime.month(.wide).day())
    }
    return date.formatted(.dateTime.month(.wide).day().year())
}

/// Formats compact trailing stats for the selectable record row.
/// Returns "45m", "45m · 3⚠", "45m · 87%", "45m · 3⚠ · 87%", or with
/// "asked N×" and/or "N blocked" suffixes appended when applicable.
/// `minChecks` is passed explicitly so tests can override without touching the singleton.
internal func selectableRowStats(record: SessionRecord, minChecks: Int) -> String {
    let total = max(0, Int(record.duration))
    let h = total / 3600
    let m = (total % 3600) / 60
    let dur: String
    if h > 0 { dur = "\(h)h \(m)m" }
    else if m > 0 { dur = "\(m)m" }
    else { dur = "<1m" }
    var parts = [dur]
    if record.calloutCount > 0 { parts.append("\(record.calloutCount)⚠") }
    if let score = record.focusScore, record.totalChecks >= minChecks {
        parts.append("\(Int(score * 100))%")
    }
    if record.reasoningAttempts > 0 { parts.append("asked \(record.reasoningAttempts)×") }
    if record.blockedDomains.count > 0 { parts.append("\(record.blockedDomains.count) blocked") }
    return parts.joined(separator: " · ")
}

/// Groups records (expected newest-first) into `DayGroup` buckets without reordering.
internal func groupedByDay(
    _ records: [SessionRecord],
    calendar: Calendar = .current,
    now: Date = Date()
) -> [DayGroup] {
    var result: [DayGroup] = []
    for record in records {
        let label = dayLabel(for: record.startTime, calendar: calendar, now: now)
        if !result.isEmpty && result[result.count - 1].label == label {
            result[result.count - 1].records.append(record)
        } else {
            result.append(DayGroup(label: label, records: [record]))
        }
    }
    return result
}

private struct HistoryTab: View {
    @State private var records: [SessionRecord] = []
    @State private var stats: SessionStats? = nil
    @State private var heatmapDays: [DayActivity] = []
    @State private var showingClearAlert: Bool = false
    @State private var expandedRecordID: UUID? = nil
    @State private var searchText: String = ""
    @AppStorage("historyCompletionFilter") private var completionFilter: CompletionFilter = .all
    @State private var isSelectMode: Bool = false
    @State private var selectedIDs: Set<UUID> = []

    private enum CompletionFilter: String, CaseIterable {
        case all = "All", completed = "Done", exitedEarly = "Exited"
        var boolValue: Bool? {
            switch self {
            case .all: nil
            case .completed: true
            case .exitedEarly: false
            }
        }
    }

    private var filteredRecords: [SessionRecord] {
        filterRecords(records, query: searchText, completed: completionFilter.boolValue)
    }

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
                    if heatmapDays.count == 7 {
                        weeklySection(stats)
                    }
                    searchFilterBar
                    if filteredRecords.isEmpty {
                        VStack(spacing: 6) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 24))
                                .foregroundStyle(.tertiary)
                            Text("No matching sessions")
                                .font(.callout)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        List {
                            ForEach(groupedByDay(filteredRecords)) { group in
                                Section {
                                    ForEach(group.records) { record in
                                        if isSelectMode {
                                            SelectableRecordRow(
                                                record: record,
                                                isSelected: selectedIDs.contains(record.id)
                                            )
                                            .contentShape(Rectangle())
                                            .onTapGesture { toggleSelection(record.id) }
                                        } else {
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
                                                        heatmapDays = await SessionHistory.shared.weeklyHeatmap()
                                                    }
                                                }
                                            )
                                        }
                                    }
                                } header: {
                                    Text(group.label)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                        .textCase(nil)
                                }
                            }
                        }
                        .listStyle(.inset)
                    }

                    HStack {
                        if isSelectMode {
                            Button("Delete \(selectedIDs.count) selected") { deleteSelected() }
                                .buttonStyle(.borderless)
                                .font(.callout)
                                .foregroundStyle(.red.opacity(0.7))
                                .padding(.leading, 12)
                                .padding(.vertical, 8)
                                .opacity(selectedIDs.isEmpty ? 0 : 1)
                                .disabled(selectedIDs.isEmpty)
                            Spacer()
                            Menu("Export \(selectedIDs.count)…") {
                                Button("CSV…") {
                                    let selected = records.filter { selectedIDs.contains($0.id) }
                                    presentExportPanel(records: selected, filename: "adia-selected-sessions.csv")
                                }
                                Button("JSON…") {
                                    let selected = records.filter { selectedIDs.contains($0.id) }
                                    presentExportPanelJSON(records: selected, filename: "adia-selected-sessions.json")
                                }
                            }
                            .menuStyle(.borderlessButton)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .opacity(selectedIDs.isEmpty ? 0 : 1)
                            .disabled(selectedIDs.isEmpty)
                            Button(allFilteredSelected ? "Deselect All" : "Select All") {
                                toggleSelectAll()
                            }
                            .keyboardShortcut("a", modifiers: .command)
                            .buttonStyle(.borderless)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            Button("Done") {
                                isSelectMode = false
                                selectedIDs = []
                            }
                            .buttonStyle(.borderless)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 12)
                            .padding(.vertical, 8)
                        } else {
                            Button("Clear All") { showingClearAlert = true }
                                .buttonStyle(.borderless)
                                .font(.callout)
                                .foregroundStyle(.red.opacity(0.7))
                                .padding(.leading, 12)
                                .padding(.vertical, 8)
                            Spacer()
                            Button("Select") {
                                isSelectMode = true
                                expandedRecordID = nil
                                selectedIDs = []
                            }
                            .buttonStyle(.borderless)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            Menu("Export…") {
                                Button("CSV…") {
                                    presentExportPanel(records: records, filename: "adia-history.csv")
                                }
                                Button("JSON…") {
                                    presentExportPanelJSON(records: records, filename: "adia-history.json")
                                }
                            }
                            .menuStyle(.borderlessButton)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .padding(.trailing, 12)
                            .padding(.vertical, 8)
                        }
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
                    heatmapDays = []
                    expandedRecordID = nil
                    isSelectMode = false
                    selectedIDs = []
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete all \(records.count) session record\(records.count == 1 ? "" : "s"). This cannot be undone.")
        }
        .task {
            records = await SessionHistory.shared.load()
            stats = await SessionHistory.shared.stats()
            heatmapDays = await SessionHistory.shared.weeklyHeatmap()
        }
    }

    @ViewBuilder
    private func weeklySection(_ s: SessionStats?) -> some View {
        VStack(spacing: 0) {
            if let s, s.weekCount > 0 {
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
                .padding(.top, 9)
                .padding(.bottom, 6)
            }
            WeekHeatmapView(days: heatmapDays)
                .padding(.horizontal, 16)
                .padding(.top, s == nil || (s?.weekCount ?? 0) == 0 ? 9.0 : 0.0)
                .padding(.bottom, 9)
        }
        .background(.background)
    }

    @ViewBuilder
    private var searchFilterBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12))
                    .foregroundStyle(.tertiary)
                TextField("Search sessions…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                if !searchText.isEmpty {
                    Button { searchText = ""; completionFilter = .all } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.primary.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            Picker("", selection: $completionFilter) {
                ForEach(CompletionFilter.allCases, id: \.self) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 136)
            .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
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

    private var allFilteredSelected: Bool {
        !filteredRecords.isEmpty && filteredRecords.allSatisfy { selectedIDs.contains($0.id) }
    }

    private func toggleSelectAll() {
        if allFilteredSelected {
            selectedIDs = []
        } else {
            selectedIDs = Set(filteredRecords.map { $0.id })
        }
    }

    private func toggleSelection(_ id: UUID) {
        if selectedIDs.contains(id) { selectedIDs.remove(id) } else { selectedIDs.insert(id) }
    }

    private func deleteSelected() {
        let ids = selectedIDs
        Task { @MainActor in
            await SessionHistory.shared.deleteMultiple(ids: ids)
            withAnimation(.easeOut(duration: 0.18)) {
                records.removeAll { ids.contains($0.id) }
                if let expanded = expandedRecordID, ids.contains(expanded) { expandedRecordID = nil }
            }
            selectedIDs = []
            if records.isEmpty { isSelectMode = false }
            stats = await SessionHistory.shared.stats()
            heatmapDays = await SessionHistory.shared.weeklyHeatmap()
        }
    }

    private func presentExportPanel(records: [SessionRecord], filename: String) {
        let csv = sessionRecordsToCSV(records)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.commaSeparatedText]
        panel.nameFieldStringValue = filename
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? csv.write(to: url, atomically: true, encoding: .utf8)
        }
    }

    private func presentExportPanelJSON(records: [SessionRecord], filename: String) {
        let json = sessionRecordsToJSON(records)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = filename
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? json.write(to: url, atomically: true, encoding: .utf8)
        }
    }
}

// MARK: - Week Heatmap

/// Formats a minute count as a compact duration string: "45m", "1h", "1h 30m".
internal func heatmapFormatMinutes(_ minutes: Int) -> String {
    let h = minutes / 60
    let m = minutes % 60
    if h > 0 && m > 0 { return "\(h)h \(m)m" }
    if h > 0 { return "\(h)h" }
    return "\(m)m"
}

/// Parses a human-typed duration string into a whole number of minutes.
/// Accepts: "90", "90m", "90min", "2h", "1h30m", "1h 30m".
/// Returns nil for empty input, zero result, or unrecognised patterns.
internal func parseCustomDuration(_ raw: String) -> Int? {
    let s = raw.trimmingCharacters(in: .whitespaces).lowercased()
    guard !s.isEmpty else { return nil }
    let scanner = Scanner(string: s)
    scanner.charactersToBeSkipped = nil
    guard let first = scanner.scanInt() else { return nil }
    _ = scanner.scanCharacters(from: .whitespaces)
    if scanner.scanString("h") != nil {
        _ = scanner.scanCharacters(from: .whitespaces)
        let extra = scanner.scanInt() ?? 0
        for suffix in ["mins", "min", "m"] {
            if scanner.scanString(suffix) != nil { break }
        }
        guard scanner.isAtEnd else { return nil }
        let total = first * 60 + extra
        return total > 0 ? total : nil
    }
    for suffix in ["mins", "min", "m"] {
        if scanner.scanString(suffix) != nil { break }
    }
    guard scanner.isAtEnd else { return nil }
    return first > 0 ? first : nil
}

/// Returns the tooltip label for a single heatmap column day.
internal func heatmapTooltipText(for day: DayActivity) -> String {
    if day.sessionCount == 0 { return "no sessions" }
    let sessions = day.sessionCount == 1 ? "1 session" : "\(day.sessionCount) sessions"
    return "\(sessions) · \(heatmapFormatMinutes(day.minutes))"
}

private struct WeekHeatmapView: View {
    let days: [DayActivity]
    @State private var hoveredIndex: Int? = nil

    private var maxMinutes: Int { max(1, days.map(\.minutes).max() ?? 1) }

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(days.indices, id: \.self) { i in
                columnView(days[i])
                    .onHover { isHovering in hoveredIndex = isHovering ? i : nil }
                    .zIndex(hoveredIndex == i ? 1 : 0)
                    .overlay(alignment: .top) {
                        if hoveredIndex == i {
                            tooltipLabel(days[i])
                                .offset(y: -26)
                                .transition(.opacity)
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.12), value: hoveredIndex)
    }

    private func tooltipLabel(_ day: DayActivity) -> some View {
        Text(heatmapTooltipText(for: day))
            .font(.system(size: 9, weight: .medium))
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 4, style: .continuous))
            .fixedSize()
    }

    private func columnView(_ day: DayActivity) -> some View {
        let isToday = Calendar.current.isDateInToday(day.date)
        let fraction = day.minutes > 0
            ? CGFloat(day.minutes) / CGFloat(maxMinutes)
            : 0
        // minimum visible height of 4pt when sessions exist, 0 otherwise
        let filledH: CGFloat = fraction > 0 ? max(4, fraction * 40) : 0

        return VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                // track — dimmer for empty days so active days read as more distinct
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.secondary.opacity(day.minutes > 0 ? 0.1 : 0.05))
                    .frame(height: 40)
                // fill
                if filledH > 0 {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(isToday ? Color.accentColor : Color.accentColor.opacity(0.45))
                        .frame(height: filledH)
                }
            }
            Text(dayAbbrev(day.date))
                .font(.system(size: 9, weight: isToday ? .bold : .regular))
                .foregroundStyle(isToday ? Color.primary : Color.secondary)
                .frame(width: 24)
        }
        .frame(maxWidth: .infinity)
    }

    private func dayAbbrev(_ date: Date) -> String {
        let w = Calendar.current.component(.weekday, from: date)
        return ["Su", "Mo", "Tu", "We", "Th", "Fr", "Sa"][(w - 1) % 7]
    }
}

// MARK: - Session Record Row

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
                        if let score = record.focusScore, record.totalChecks >= SessionManager.minChecksForFocusScore {
                            Label("\(Int(score * 100))% focused", systemImage: "target")
                        }
                        if record.reasoningAttempts > 0 {
                            Label(
                                "asked \(record.reasoningAttempts)×",
                                systemImage: "bubble.left.and.text.bubble.right"
                            )
                        }
                        if record.blockedDomains.count > 0 {
                            Label(
                                "\(record.blockedDomains.count) site\(record.blockedDomains.count == 1 ? "" : "s") blocked",
                                systemImage: "hand.raised.fill"
                            )
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
                        if let score = record.focusScore, record.totalChecks >= SessionManager.minChecksForFocusScore {
                            detailField("Focus score", "\(Int(score * 100))%")
                        }
                    }

                    if record.reasoningAttempts > 0 {
                        detailField("Site access asks",
                            "\(record.reasoningAttempts) asked, \(record.reasoningGranted) granted")
                    }

                    if !record.blockedDomains.isEmpty {
                        detailField(
                            "Blocked sites",
                            record.blockedDomains.prefix(5).joined(separator: ", ") +
                                (record.blockedDomains.count > 5
                                    ? " +\(record.blockedDomains.count - 5) more"
                                    : "")
                        )
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

// MARK: - Selectable Record Row

private struct SelectableRecordRow: View {
    let record: SessionRecord
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? Color.accentColor : Color.primary.opacity(0.3))
                .font(.system(size: 18))

            VStack(alignment: .leading, spacing: 2) {
                Text(record.task)
                    .font(.body)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Image(systemName: record.completedSuccessfully
                          ? "checkmark.circle.fill" : "arrow.uturn.left.circle.fill")
                        .foregroundStyle(record.completedSuccessfully ? Color.green : Color.secondary)
                        .font(.system(size: 11))
                    Text(record.startTime, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(selectableRowStats(record: record, minChecks: SessionManager.minChecksForFocusScore))
                .font(.system(size: 11, design: .monospaced))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

// MARK: - Templates Tab

private struct TemplatesSettingsTab: View {
    @ObservedObject private var settings = SettingsStore.shared
    @State private var templates: [SessionTemplate] = []
    @State private var editingTemplate: SessionTemplate? = nil

    var body: some View {
        VStack(spacing: 0) {
            if templates.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "pin.slash")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No saved templates")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("Tap the pin icon when starting a session to save it as a template.")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 280)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(templates) { template in
                        TemplateRow(template: template) {
                            editingTemplate = template
                        } onDelete: {
                            let id = template.id
                            Task { @MainActor in
                                await SessionTemplateStore.shared.delete(id: id)
                                await reloadTemplates()
                            }
                        }
                    }
                    .onMove { fromOffsets, toOffset in
                        templates.move(fromOffsets: fromOffsets, toOffset: toOffset)
                        Task { await SessionTemplateStore.shared.reorder(fromOffsets: fromOffsets, toOffset: toOffset) }
                    }
                }
                .listStyle(.inset)
            }

            // Footer always visible so the setting is configurable before templates are added.
            HStack(spacing: 0) {
                Text(templates.isEmpty
                     ? "No templates yet"
                     : "\(templates.count) template\(templates.count == 1 ? "" : "s") · drag to reorder")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                Spacer()
                Toggle("Notch: use reorder", isOn: $settings.idleTemplatesFollowManualOrder)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .help("When on, the notch quick-launch row shows templates in your drag order. When off, it shows the two most-recently used.")
                    .padding(.horizontal, 12)
            }
            .background(.background)
        }
        .task { await reloadTemplates() }
        .sheet(item: $editingTemplate) { template in
            EditTemplateSheet(template: template) {
                Task { @MainActor in await reloadTemplates() }
            }
        }
    }

    private func reloadTemplates() async {
        templates = await SessionTemplateStore.shared.load()
    }
}

// MARK: - Template Row

private struct TemplateRow: View {
    let template: SessionTemplate
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "pin.fill")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(template.task)
                    .font(.body)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                if !template.successCriteria.isEmpty {
                    Text(template.successCriteria)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    if template.useCount > 0 {
                        Label("\(template.useCount) use\(template.useCount == 1 ? "" : "s")",
                              systemImage: "play.fill")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    if let date = template.lastUsedAt {
                        Text(date, style: .relative)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            HStack(spacing: 6) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .help("Edit template")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red.opacity(0.8))
                }
                .buttonStyle(.borderless)
                .help("Delete template")
            }
        }
        .padding(.vertical, 3)
    }
}

// MARK: - Edit Template Sheet

private struct EditTemplateSheet: View {
    let template: SessionTemplate
    let onSave: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var taskDraft: String
    @State private var criteriaDraft: String
    @State private var selectedMinutes: Int?
    /// Free-form duration text typed by the user (e.g. "2h", "90m", "1h30m").
    /// Pre-populated when the template's stored duration doesn't match any preset chip.
    @State private var customText: String

    private static let durationPresets: [(Int, String)] = [(25, "25m"), (45, "45m"), (60, "1h"), (90, "90m")]

    init(template: SessionTemplate, onSave: @escaping () -> Void) {
        self.template = template
        self.onSave = onSave
        _taskDraft = State(initialValue: template.task)
        _criteriaDraft = State(initialValue: template.successCriteria)
        // Snap stored seconds to the nearest preset; nil if no match or no stored duration.
        let storedMinutes = template.preferredDuration.map { Int($0 / 60) }
        let presetSet = Set(Self.durationPresets.map(\.0))
        let snapped: Int? = storedMinutes.flatMap { presetSet.contains($0) ? $0 : nil }
        _selectedMinutes = State(initialValue: snapped)
        // Pre-fill custom text when stored duration doesn't match any preset.
        let customMinutes = storedMinutes.flatMap { presetSet.contains($0) ? nil : $0 }
        _customText = State(initialValue: customMinutes.map { heatmapFormatMinutes($0) } ?? "")
    }

    private var parsedCustomMinutes: Int? { parseCustomDuration(customText) }

    private var canSave: Bool {
        !taskDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !criteriaDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Edit Template")
                .font(.headline)
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 12)

            Divider()

            Form {
                Section {
                    TextField("Task description", text: $taskDraft, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Working on")
                }

                Section {
                    TextField("Success criteria", text: $criteriaDraft, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Done when")
                }

                Section {
                    HStack(spacing: 6) {
                        ForEach(Self.durationPresets, id: \.0) { minutes, label in
                            Button {
                                withAnimation(.easeOut(duration: 0.1)) {
                                    if selectedMinutes == minutes {
                                        selectedMinutes = nil
                                    } else {
                                        selectedMinutes = minutes
                                        customText = ""
                                    }
                                }
                            } label: {
                                Text(label)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(selectedMinutes == minutes ? .white : .secondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        selectedMinutes == minutes
                                            ? Color.accentColor
                                            : Color.secondary.opacity(0.12),
                                        in: RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                        if selectedMinutes != nil {
                            Button {
                                withAnimation(.easeOut(duration: 0.1)) { selectedMinutes = nil }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.tertiary)
                                    .font(.system(size: 13))
                            }
                            .buttonStyle(.plain)
                            .help("Clear duration goal")
                        }
                    }
                    HStack(spacing: 6) {
                        TextField("or type a custom duration (e.g. 2h, 90m, 1h30m)", text: $customText)
                            .font(.system(size: 12))
                            .onChange(of: customText) {
                                if !customText.trimmingCharacters(in: .whitespaces).isEmpty {
                                    selectedMinutes = nil
                                }
                            }
                        if !customText.isEmpty {
                            Button { customText = "" } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.tertiary)
                                    .font(.system(size: 13))
                            }
                            .buttonStyle(.plain)
                            .help("Clear custom duration")
                        }
                    }
                } header: {
                    Text("Duration goal")
                } footer: {
                    VStack(alignment: .leading, spacing: 4) {
                        if selectedMinutes == nil {
                            if let parsed = parsedCustomMinutes {
                                Text("= \(heatmapFormatMinutes(parsed))")
                                    .foregroundStyle(.green.opacity(0.9))
                            } else if !customText.trimmingCharacters(in: .whitespaces).isEmpty {
                                Text("Couldn't parse — try "2h", "90m", or "1h30m".")
                                    .foregroundStyle(.orange.opacity(0.8))
                            }
                        }
                        let hasGoal = selectedMinutes != nil || parsedCustomMinutes != nil
                        Text(hasGoal
                             ? "A progress arc will appear in the notch during this session."
                             : "No time limit — session runs until you click Done.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)

            Divider()

            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.cancelAction)
                    .buttonStyle(.borderless)
                Spacer()
                Button("Save") {
                    let id = template.id
                    let t = taskDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    let c = criteriaDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    let dur: TimeInterval? = selectedMinutes.map { TimeInterval($0 * 60) }
                        ?? parsedCustomMinutes.map { TimeInterval($0 * 60) }
                    Task {
                        await SessionTemplateStore.shared.update(id: id, task: t, successCriteria: c, preferredDuration: dur)
                        onSave()
                    }
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .frame(width: 380, height: 400)
    }
}
