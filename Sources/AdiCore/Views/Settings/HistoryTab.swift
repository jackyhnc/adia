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

enum HistoryCompletionFilter: String, CaseIterable {
    case all = "All", completed = "Done", exitedEarly = "Exited"
    var boolValue: Bool? {
        switch self {
        case .all: nil
        case .completed: true
        case .exitedEarly: false
        }
    }
}

struct HistoryTab: View {
    @State private var records: [SessionRecord] = []
    @State private var stats: SessionStats? = nil
    @State private var heatmapDays: [DayActivity] = []
    @State private var insights: FocusInsights? = nil
    @State private var showingClearAlert: Bool = false
    @State private var expandedRecordID: UUID? = nil
    @State private var searchText: String = ""
    @AppStorage("historyCompletionFilter") private var completionFilter: HistoryCompletionFilter = .all
    @State private var isSelectMode: Bool = false
    @State private var selectedIDs: Set<UUID> = []

    private var filteredRecords: [SessionRecord] {
        filterRecords(records, query: searchText, completed: completionFilter.boolValue)
    }

    var body: some View {
        Group {
            if records.isEmpty {
                emptyState
            } else {
                VStack(spacing: 0) {
                    if heatmapDays.count == 7 {
                        HistoryWeeklySection(stats: stats, heatmapDays: heatmapDays)
                    }
                    if let ins = insights, ins.sessionCount >= insightsMinSessions {
                        HistoryInsightsSection(insights: ins)
                    }
                    HistorySearchFilterBar(searchText: $searchText, completionFilter: $completionFilter)
                    if filteredRecords.isEmpty {
                        noMatchState
                    } else {
                        sessionList
                    }
                    HistoryToolbar(
                        isSelectMode: isSelectMode,
                        selectedCount: selectedIDs.count,
                        allFilteredSelected: allFilteredSelected,
                        records: records,
                        selectedIDs: selectedIDs,
                        onDeleteSelected: deleteSelected,
                        onExportCSV: { presentExportPanel(records: $0, filename: "adia-history.csv") },
                        onExportJSON: { presentExportPanelJSON(records: $0, filename: "adia-history.json") },
                        onToggleSelectAll: toggleSelectAll,
                        onDoneSelectMode: {
                            isSelectMode = false
                            selectedIDs = []
                        },
                        onClearAll: { showingClearAlert = true },
                        onEnterSelectMode: {
                            isSelectMode = true
                            expandedRecordID = nil
                            selectedIDs = []
                        }
                    )
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

    private var emptyState: some View {
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
    }

    private var noMatchState: some View {
        VStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 24))
                .foregroundStyle(.tertiary)
            Text("No matching sessions")
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var sessionList: some View {
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
