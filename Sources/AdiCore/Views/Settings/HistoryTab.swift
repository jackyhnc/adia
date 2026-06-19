import SwiftUI
import AppKit
import UniformTypeIdentifiers

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

struct DayGroup: Identifiable {
    var id: String { label }
    let label: String
    var records: [SessionRecord]
}

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

internal func allTimeSummaryText(_ s: SessionStats) -> String {
    let count = s.allTimeCount
    let sessions = "\(count) session\(count == 1 ? "" : "s")"
    guard s.allTimeMinutes > 0 else { return "\(sessions) total" }
    let h = s.allTimeMinutes / 60
    let m = s.allTimeMinutes % 60
    let time: String
    if h > 0 && m > 0 { time = "\(h)h \(m)m" }
    else if h > 0 { time = "\(h)h" }
    else { time = "\(m)m" }
    return "\(sessions) · \(time) total"
}

struct HistoryTab: View {
    @State private var records: [SessionRecord] = []
    @State private var stats: SessionStats? = nil
    @State private var heatmapDays: [DayActivity] = []
    @State private var insights: FocusInsights? = nil
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
                    if let ins = insights, ins.sessionCount >= insightsMinSessions {
                        insightsSection(ins)
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
                                                        insights = await SessionHistory.shared.insights()
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
                    insights = nil
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
            insights = await SessionHistory.shared.insights()
        }
    }

    @ViewBuilder
    private func weeklySection(_ s: SessionStats?) -> some View {
        VStack(spacing: 0) {
            if let s, s.weekCount > 0 || s.allTimeCount > 0 {
                VStack(alignment: .leading, spacing: 4) {
                    if s.weekCount > 0 {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(.secondary)
                            Text(weekSummaryText(s))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(.secondary)
                            if s.streak > 0 {
                                Text(streakDisplayLabel(current: s.streak, best: s.bestStreak))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2)
                                    .background(.orange.opacity(0.1))
                                    .clipShape(Capsule())
                            }
                            Spacer()
                        }
                    }
                    if s.allTimeCount > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 10, weight: .regular))
                                .foregroundStyle(.tertiary)
                            Text(allTimeSummaryText(s))
                                .font(.system(size: 11))
                                .foregroundStyle(.tertiary)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 9)
                .padding(.bottom, 6)
            }
            WeekHeatmapView(days: heatmapDays)
                .padding(.horizontal, 16)
                .padding(.top, (s == nil || ((s?.weekCount ?? 0) == 0 && (s?.allTimeCount ?? 0) == 0)) ? 9.0 : 0.0)
                .padding(.bottom, 9)
        }
        .background(.background)
    }

    @ViewBuilder
    private func insightsSection(_ ins: FocusInsights) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.yellow)
                Text("Focus Insights")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            HStack(spacing: 16) {
                if let avg = ins.avgSessionMinutes {
                    insightChip(icon: "timer", label: "Avg session", value: heatmapFormatMinutes(avg))
                }
                if let rate = ins.completionRate {
                    insightChip(icon: "checkmark.circle", label: "Completed", value: "\(Int(rate * 100))%")
                }
                if let score = ins.avgFocusScore {
                    insightChip(icon: "eye", label: "Focus", value: "\(Int(score * 100))%")
                }
            }
            HStack(spacing: 16) {
                if let hour = ins.bestHour {
                    insightChip(icon: "clock", label: "Peak hour", value: formatHourRange(hour))
                }
                if let wd = ins.bestWeekday {
                    insightChip(icon: "calendar", label: "Best day", value: formatWeekday(wd))
                }
                if ins.trend != .insufficient {
                    let t = trendLabel(ins.trend)
                    insightChip(icon: t.symbol, label: "Trend", value: t.text)
                }
            }
            HStack(spacing: 16) {
                if let reliability = ins.captureReliabilityRate, reliability < 1.0 {
                    insightChip(icon: "antenna.radiowaves.left.and.right", label: "Capture reliability", value: "\(Int(reliability * 100))%")
                }
                if let pauses = ins.avgPausesPerSession, pauses > 0 {
                    insightChip(icon: "pause.circle", label: "Avg pauses", value: String(format: "%.1f", pauses))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.background)
    }

    @ViewBuilder
    private func insightChip(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            VStack(alignment: .leading, spacing: 1) {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)
                Text(value)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.primary)
            }
        }
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
            insights = await SessionHistory.shared.insights()
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
