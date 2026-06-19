import SwiftUI
import AppKit

struct BlockingSettingsTab: View {
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
                VStack(alignment: .leading, spacing: 4) {
                    Text("Disabled domains are skipped in new sessions but not unblocked mid-session.")
                    Text("Each blocked domain also automatically blocks its mobile (m.), AMP (amp.), image (i.), music (music.), TV (tv.), and older (old., en.) subdomains — so bypass tricks like m.reddit.com or music.youtube.com are covered without extra configuration.")
                }
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

struct RunningAppsPickerView: View {
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
