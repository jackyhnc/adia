import SwiftUI

struct TemplatesSettingsTab: View {
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
    @State private var customText: String

    private static let durationPresets: [(Int, String)] = [(25, "25m"), (45, "45m"), (60, "1h"), (90, "90m")]

    init(template: SessionTemplate, onSave: @escaping () -> Void) {
        self.template = template
        self.onSave = onSave
        _taskDraft = State(initialValue: template.task)
        _criteriaDraft = State(initialValue: template.successCriteria)
        let storedMinutes = template.preferredDuration.map { Int($0 / 60) }
        let presetSet = Set(Self.durationPresets.map(\.0))
        let snapped: Int? = storedMinutes.flatMap { presetSet.contains($0) ? $0 : nil }
        _selectedMinutes = State(initialValue: snapped)
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
