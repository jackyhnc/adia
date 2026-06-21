import SwiftUI

struct HistoryWeeklySection: View {
    let stats: SessionStats?
    let heatmapDays: [DayActivity]

    var body: some View {
        VStack(spacing: 0) {
            if let s = stats, s.weekCount > 0 || s.allTimeCount > 0 {
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
                .padding(.top, (stats == nil || ((stats?.weekCount ?? 0) == 0 && (stats?.allTimeCount ?? 0) == 0)) ? 9.0 : 0.0)
                .padding(.bottom, 9)
        }
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
}

struct HistoryInsightsSection: View {
    let insights: FocusInsights

    var body: some View {
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
                if let avg = insights.avgSessionMinutes {
                    insightChip(icon: "timer", label: "Avg session", value: heatmapFormatMinutes(avg))
                }
                if let rate = insights.completionRate {
                    insightChip(icon: "checkmark.circle", label: "Completed", value: "\(Int(rate * 100))%")
                }
                if let score = insights.avgFocusScore {
                    insightChip(icon: "eye", label: "Focus", value: "\(Int(score * 100))%")
                }
            }
            HStack(spacing: 16) {
                if let hour = insights.bestHour {
                    insightChip(icon: "clock", label: "Peak hour", value: formatHourRange(hour))
                }
                if let wd = insights.bestWeekday {
                    insightChip(icon: "calendar", label: "Best day", value: formatWeekday(wd))
                }
                if insights.trend != .insufficient {
                    let t = trendLabel(insights.trend)
                    insightChip(icon: t.symbol, label: "Trend", value: t.text)
                }
            }
            HStack(spacing: 16) {
                if let reliability = insights.captureReliabilityRate, reliability < 1.0 {
                    insightChip(icon: "antenna.radiowaves.left.and.right", label: "Capture reliability", value: "\(Int(reliability * 100))%")
                }
                if let pauses = insights.avgPausesPerSession, pauses > 0 {
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
}

struct HistorySearchFilterBar: View {
    @Binding var searchText: String
    @Binding var completionFilter: HistoryCompletionFilter

    var body: some View {
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
                ForEach(HistoryCompletionFilter.allCases, id: \.self) {
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
}

struct HistoryToolbar: View {
    let isSelectMode: Bool
    let selectedCount: Int
    let allFilteredSelected: Bool
    let records: [SessionRecord]
    let selectedIDs: Set<UUID>
    var onDeleteSelected: () -> Void
    var onExportCSV: ([SessionRecord]) -> Void
    var onExportJSON: ([SessionRecord]) -> Void
    var onToggleSelectAll: () -> Void
    var onDoneSelectMode: () -> Void
    var onClearAll: () -> Void
    var onEnterSelectMode: () -> Void

    var body: some View {
        HStack {
            if isSelectMode {
                selectModeContent
            } else {
                normalModeContent
            }
        }
        .background(.background)
    }

    @ViewBuilder
    private var selectModeContent: some View {
        Button("Delete \(selectedCount) selected") { onDeleteSelected() }
            .buttonStyle(.borderless)
            .font(.callout)
            .foregroundStyle(.red.opacity(0.7))
            .padding(.leading, 12)
            .padding(.vertical, 8)
            .opacity(selectedCount == 0 ? 0 : 1)
            .disabled(selectedCount == 0)
        Spacer()
        Menu("Export \(selectedCount)…") {
            Button("CSV…") {
                let selected = records.filter { selectedIDs.contains($0.id) }
                onExportCSV(selected)
            }
            Button("JSON…") {
                let selected = records.filter { selectedIDs.contains($0.id) }
                onExportJSON(selected)
            }
        }
        .menuStyle(.borderlessButton)
        .font(.callout)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .opacity(selectedCount == 0 ? 0 : 1)
        .disabled(selectedCount == 0)
        Button(allFilteredSelected ? "Deselect All" : "Select All") {
            onToggleSelectAll()
        }
        .keyboardShortcut("a", modifiers: .command)
        .buttonStyle(.borderless)
        .font(.callout)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        Button("Done") { onDoneSelectMode() }
            .buttonStyle(.borderless)
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.trailing, 12)
            .padding(.vertical, 8)
    }

    @ViewBuilder
    private var normalModeContent: some View {
        Button("Clear All") { onClearAll() }
            .buttonStyle(.borderless)
            .font(.callout)
            .foregroundStyle(.red.opacity(0.7))
            .padding(.leading, 12)
            .padding(.vertical, 8)
        Spacer()
        Button("Select") { onEnterSelectMode() }
            .buttonStyle(.borderless)
            .font(.callout)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)
        Menu("Export…") {
            Button("CSV…") { onExportCSV(records) }
            Button("JSON…") { onExportJSON(records) }
        }
        .menuStyle(.borderlessButton)
        .font(.callout)
        .foregroundStyle(.secondary)
        .padding(.trailing, 12)
        .padding(.vertical, 8)
    }
}
