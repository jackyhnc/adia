import SwiftUI

// MARK: - Heatmap Helpers

internal func heatmapFormatMinutes(_ minutes: Int) -> String {
    let h = minutes / 60
    let m = minutes % 60
    if h > 0 && m > 0 { return "\(h)h \(m)m" }
    if h > 0 { return "\(h)h" }
    return "\(m)m"
}

internal func parseCustomDuration(_ raw: String) -> Int? {
    let s = raw.trimmingCharacters(in: .whitespaces).lowercased()
    guard !s.isEmpty else { return nil }
    let scanner = Scanner(string: s)
    scanner.charactersToBeSkipped = nil
    guard let first = scanner.scanInt() else { return nil }
    // Decimal hours: "1.5h" → 90, "0.5h" → 30, "2.5h" → 150.
    // Must appear before the whitespace-then-"h" branch so "1.5h" doesn't fall
    // through to the non-decimal path and produce a wrong result.
    if scanner.scanString(".") != nil {
        guard let fracDigits = scanner.scanCharacters(from: .decimalDigits), !fracDigits.isEmpty else {
            return nil  // "1." with no fractional digits — reject
        }
        _ = scanner.scanCharacters(from: .whitespaces)
        guard scanner.scanString("h") != nil, scanner.isAtEnd else { return nil }
        let frac = Double("0.\(fracDigits)") ?? 0.0
        let total = Int((Double(first) + frac) * 60.0)
        return total > 0 ? total : nil
    }
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

internal func heatmapTooltipText(for day: DayActivity) -> String {
    if day.sessionCount == 0 { return "no sessions" }
    let sessions = day.sessionCount == 1 ? "1 session" : "\(day.sessionCount) sessions"
    return "\(sessions) · \(heatmapFormatMinutes(day.minutes))"
}

// MARK: - Week Heatmap

struct WeekHeatmapView: View {
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
        let filledH: CGFloat = fraction > 0 ? max(4, fraction * 40) : 0

        return VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.secondary.opacity(day.minutes > 0 ? 0.1 : 0.05))
                    .frame(height: 40)
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

struct SessionRecordRow: View {
    let record: SessionRecord
    let isExpanded: Bool
    let onTap: () -> Void
    var onNoteChange: ((String) -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    @State private var noteDraft: String = ""
    @FocusState private var noteFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                .padding(.leading, 26)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeOut(duration: 0.18), value: isExpanded)
        .onAppear { noteDraft = record.note ?? "" }
        .onChange(of: record.note) { _, newNote in noteDraft = newNote ?? "" }
    }

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

struct SelectableRecordRow: View {
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
