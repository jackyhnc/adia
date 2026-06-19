import SwiftUI

// MARK: - Top-attached island shape

struct NotchIslandShape: Shape {
    let radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r = min(radius, rect.width / 2, rect.height / 2)
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - r, y: rect.maxY),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        path.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.maxY - r),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Progress dot (collapsed notch indicator)

struct ProgressDot: View {
    let color: Color
    let progress: Double?

    var body: some View {
        if let p = progress {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 1.5)
                Circle()
                    .trim(from: 0, to: CGFloat(p))
                    .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Circle()
                    .fill(color)
                    .frame(width: 5, height: 5)
            }
            .frame(width: 13, height: 13)
        } else {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
        }
    }
}

// MARK: - Progress bar (expanded active session)

struct ProgressBar: View {
    let progress: CGFloat

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                    .fill(Color.white.opacity(0.5))
                    .frame(width: geo.size.width * max(0, min(1, progress)))
            }
        }
        .frame(height: 3)
    }
}

// MARK: - AdiButton

enum AdiButtonStyle { case primary, secondary, destructive }

struct AdiButton: View {
    let label: String
    let style: AdiButtonStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(foreground)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .padding(.horizontal, 13)
                .padding(.vertical, 6)
                .frame(minWidth: 42)
                .background(background)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var foreground: Color {
        switch style {
        case .primary:     return .black
        case .secondary:   return .white
        case .destructive: return Color(red: 1, green: 0.3, blue: 0.3)
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .primary:     Color.white
        case .secondary:   Color.white.opacity(0.10)
        case .destructive: Color.red.opacity(0.13)
        }
    }
}

// MARK: - StatusBadge

struct StatusBadge: View {
    let status: OnTaskStatus

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 5, height: 5)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.14))
        .clipShape(Capsule())
    }

    private var color: Color {
        switch status {
        case .onTask:    return .green
        case .offTask:   return Color(red: 1, green: 0.3, blue: 0.3)
        case .ambiguous: return .orange
        }
    }

    private var label: String {
        switch status {
        case .onTask:    return "On Task"
        case .offTask:   return "Off Task"
        case .ambiguous: return "Check In"
        }
    }
}

// MARK: - Offline badge

struct OfflineBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 8, weight: .semibold))
            Text("Offline")
                .font(.system(size: 10, weight: .semibold))
        }
        .foregroundStyle(.gray)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.gray.opacity(0.14))
        .clipShape(Capsule())
    }
}

// MARK: - Whitelisted domains row

struct WhitelistedDomainsRow: View {
    let domains: [String]

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "lock.open.fill")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.green.opacity(0.7))
            Text(whitelistedDomainsLabel(domains))
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(1)
                .truncationMode(.tail)
        }
    }
}

// MARK: - Verification Attempt Row

struct VerificationAttemptRow: View {
    let attempt: VerificationAttempt

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: attempt.result.verified ? "checkmark.circle.fill" : "xmark.circle")
                .font(.system(size: 10))
                .foregroundStyle(attempt.result.verified ? .green.opacity(0.7) : Color(red: 1, green: 0.3, blue: 0.3).opacity(0.6))
                .frame(width: 14)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Attempt \(attempt.attemptNumber)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.45))
                    Text(relativeTime(attempt.timestamp))
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.25))
                }
                Text(attempt.result.explanation)
                    .font(.system(size: 11))
                    .foregroundStyle(.white.opacity(0.35))
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private func relativeTime(_ date: Date) -> String {
        verificationRelativeTime(date)
    }
}

// MARK: - Callout Banner

struct CalloutBanner: View {
    let message: String
    let tier: Int
    let reason: String?
    let onChat: () -> Void

    @State private var shakeTrigger: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: tier >= 3 ? "exclamationmark.3" : "exclamationmark.triangle.fill")
                    .font(.system(size: tier >= 3 ? 18 : 16, weight: .bold))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.system(size: tier >= 3 ? 19 : 17, weight: .heavy))
                    .foregroundStyle(.white)
            }
            if let reason, !reason.isEmpty {
                Text(reason)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Button(action: onChat) {
                Text("actually, I need this →")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, tier >= 3 ? 16 : 12)
        .background(bannerBackground)
        .keyframeAnimator(initialValue: CGFloat(0), trigger: shakeTrigger) { content, offsetX in
            content.offset(x: offsetX)
        } keyframes: { _ in
            LinearKeyframe(CGFloat(0),  duration: 0.01)
            LinearKeyframe(CGFloat(-9), duration: 0.05)
            LinearKeyframe(CGFloat(9),  duration: 0.05)
            LinearKeyframe(CGFloat(-7), duration: 0.05)
            LinearKeyframe(CGFloat(7),  duration: 0.05)
            LinearKeyframe(CGFloat(-4), duration: 0.04)
            LinearKeyframe(CGFloat(4),  duration: 0.04)
            LinearKeyframe(CGFloat(0),  duration: 0.04)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
        .onChange(of: message, initial: true) {
            if tier >= 3 { shakeTrigger.toggle() }
        }
    }

    private var bannerBackground: Color {
        switch tier {
        case 1: return Color(red: 0.85, green: 0.15, blue: 0.15)
        case 2: return Color(red: 0.70, green: 0.05, blue: 0.05)
        default: return Color(red: 0.50, green: 0.00, blue: 0.00)
        }
    }
}

// MARK: - TimerExpiredBanner

struct TimerExpiredBanner: View {
    let onVerify: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "timer")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                Text("time's up — how'd it go?")
                    .font(.system(size: 17, weight: .heavy))
                    .foregroundStyle(.white)
            }
            Button(action: onVerify) {
                Text("verify now →")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.60, green: 0.42, blue: 0.0))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Daily Goal Progress Row

struct DailyGoalProgressRow: View {
    let todayMinutes: Int
    let goalMinutes: Int

    private var fraction: CGFloat {
        guard goalMinutes > 0 else { return 0 }
        return min(1.0, CGFloat(todayMinutes) / CGFloat(goalMinutes))
    }

    private var isComplete: Bool { todayMinutes >= goalMinutes }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: isComplete ? "checkmark.circle.fill" : "target")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(isComplete ? .green.opacity(0.8) : .white.opacity(0.35))
                Text(dailyGoalProgressLabel(todayMinutes: todayMinutes, goalMinutes: goalMinutes))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(isComplete ? .green.opacity(0.8) : .white.opacity(0.5))
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(isComplete ? Color.green.opacity(0.6) : Color.white.opacity(0.35))
                        .frame(width: geo.size.width * fraction)
                }
            }
            .frame(height: 3)
        }
    }
}

// MARK: - Notch Heatmap

struct NotchHeatmapView: View {
    let days: [DayActivity]

    private var maxMinutes: Int { max(1, days.map(\.minutes).max() ?? 1) }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(days.indices, id: \.self) { i in
                notchHeatmapCell(days[i])
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func notchHeatmapCell(_ day: DayActivity) -> some View {
        let isToday = Calendar.current.isDateInToday(day.date)
        let fraction = day.minutes > 0
            ? Double(day.minutes) / Double(maxMinutes)
            : 0
        let fillOpacity = day.minutes > 0 ? 0.15 + fraction * 0.55 : 0.04

        return VStack(spacing: 3) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(isToday ? Color.white.opacity(fillOpacity + 0.1) : Color.white.opacity(fillOpacity))
                .frame(height: 18)
                .overlay(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(isToday ? Color.white.opacity(0.25) : Color.clear, lineWidth: 0.5)
                )
            Text(notchHeatmapDayAbbrev(day.date))
                .font(.system(size: 8, weight: isToday ? .bold : .regular))
                .foregroundStyle(isToday ? .white.opacity(0.6) : .white.opacity(0.25))
        }
        .frame(maxWidth: .infinity)
        .help(notchHeatmapTooltip(day))
    }
}
