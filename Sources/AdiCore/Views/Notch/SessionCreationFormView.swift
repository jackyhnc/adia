import SwiftUI

struct SessionCreationFormView: View {
    @ObservedObject var state: NotchState
    @ObservedObject var session: SessionManager

    @State private var inputText: String = ""
    @State private var clarifyingQuestion: String?
    @State private var isThinking: Bool = false
    @State private var pinAsTemplate: Bool = false
    @State private var targetMinutes: Int? = nil
    @State private var customDurationText: String = ""
    @FocusState private var inputFocused: Bool

    private let durationPresets: [(Int, String)] = [(25, "25m"), (45, "45m"), (60, "1h"), (90, "90m")]
    private var parsedCustomMinutes: Int? { parseCustomDuration(customDurationText) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("WHAT ARE YOU DOING?")
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.35))
                .tracking(1.5)
                .padding(.bottom, 4)

            ZStack(alignment: .topLeading) {
                if inputText.isEmpty {
                    Text("e.g. finish my history essay and submit it on Canvas")
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.22))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 7)
                        .allowsHitTesting(false)
                }
                TextField("", text: $inputText, axis: .vertical)
                    .lineLimit(2...3)
                    .font(.system(size: 12))
                    .foregroundStyle(.white)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 7)
                    .focused($inputFocused)
                    .onSubmit { submit() }
            }
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(clarifyingQuestion != nil
                            ? Color.orange.opacity(0.5)
                            : Color.white.opacity(0.10), lineWidth: 0.5)
            )

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 0) {
                    Text("DURATION")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white.opacity(0.3))
                        .tracking(1.5)
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(durationPresets, id: \.0) { minutes, label in
                            Button {
                                withAnimation(.easeOut(duration: 0.1)) {
                                    targetMinutes = (targetMinutes == minutes) ? nil : minutes
                                    customDurationText = ""
                                }
                            } label: {
                                Text(label)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundStyle(targetMinutes == minutes ? .black : .white.opacity(0.5))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(targetMinutes == minutes ? Color.white : Color.white.opacity(0.08))
                                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                HStack(spacing: 6) {
                    ZStack(alignment: .leading) {
                        if customDurationText.isEmpty {
                            Text("or type \u{201C}2h\u{201D}, \u{201C}90m\u{201D}, \u{201C}1h30m\u{201D}…")
                                .font(.system(size: 10))
                                .foregroundStyle(.white.opacity(0.2))
                                .allowsHitTesting(false)
                        }
                        TextField("", text: $customDurationText)
                            .font(.system(size: 10))
                            .foregroundStyle(.white)
                            .textFieldStyle(.plain)
                            .onChange(of: customDurationText) { _, _ in
                                if !customDurationText.trimmingCharacters(in: .whitespaces).isEmpty {
                                    withAnimation(.easeOut(duration: 0.1)) { targetMinutes = nil }
                                }
                            }
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                    Group {
                        if let parsed = parsedCustomMinutes {
                            Text("= \(heatmapFormatMinutes(parsed))")
                                .foregroundStyle(.green.opacity(0.8))
                        } else if !customDurationText.trimmingCharacters(in: .whitespaces).isEmpty {
                            Text("?")
                                .foregroundStyle(.orange.opacity(0.7))
                        }
                    }
                    .font(.system(size: 10))
                    .animation(.easeOut(duration: 0.15), value: parsedCustomMinutes)
                }
            }
            .padding(.top, 8)

            if let q = clarifyingQuestion {
                Text(q)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.orange.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .transition(.opacity)
            }

            HStack(spacing: 8) {
                AdiButton(label: isThinking ? "Checking..." : "Go", style: .primary) {
                    submit()
                }
                .opacity(canSubmit ? 1 : 0.45)
                .allowsHitTesting(canSubmit && !isThinking)

                Button("Cancel") {
                    withAnimation(.easeOut(duration: 0.18)) { state.stopCreating() }
                }
                .buttonStyle(.plain)
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.4))

                Spacer()

                if canSubmit {
                    Button {
                        withAnimation(.easeOut(duration: 0.15)) { pinAsTemplate.toggle() }
                    } label: {
                        Image(systemName: pinAsTemplate ? "pin.fill" : "pin")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(pinAsTemplate ? .white.opacity(0.85) : .white.opacity(0.3))
                    }
                    .buttonStyle(.plain)
                    .help(pinAsTemplate ? "Will save as pinned template" : "Pin as template")
                    .transition(.opacity)
                }
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 14)
        .animation(.easeOut(duration: 0.2), value: clarifyingQuestion)
        .onAppear {
            if let prefill = state.sessionCreationPrefill, !prefill.isEmpty {
                inputText = prefill
            }
            if let prefillSecs = state.sessionCreationPrefillDuration {
                let mins = Int(prefillSecs / 60)
                if durationPresets.contains(where: { $0.0 == mins }) {
                    targetMinutes = mins
                } else {
                    let h = mins / 60, m = mins % 60
                    if h > 0 && m > 0 {
                        customDurationText = "\(h)h\(m)m"
                    } else if h > 0 {
                        customDurationText = "\(h)h"
                    } else {
                        customDurationText = "\(mins)m"
                    }
                }
            }
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(300))
                inputFocused = true
            }
        }
    }

    private var canSubmit: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func submit() {
        let text = inputText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, !isThinking else { return }
        if let reason = AgentAIClient.localGoalRejectionReason(text) {
            withAnimation { clarifyingQuestion = reason }
            AppLogger.warning("goal.rejected_locally", ["reason": reason])
            return
        }
        isThinking = true
        clarifyingQuestion = nil
        let shouldPin = pinAsTemplate
        let durationSeconds: TimeInterval? = targetMinutes.map { TimeInterval($0 * 60) }
            ?? parsedCustomMinutes.map { TimeInterval($0 * 60) }
        Task { @MainActor in
            defer { isThinking = false }
            do {
                let parsed = try await AgentAIClient.shared.parseGoal(text)
                switch parsed.resolveSubmission() {
                case .needsClarification(let question):
                    AppLogger.warning("goal.rejected_by_model", ["question": question])
                    withAnimation { clarifyingQuestion = question }
                case .accepted(let task, let criteria):
                    AppLogger.info("goal.accepted", [
                        "taskLength": String(task.count),
                        "criteriaLength": String(criteria.count)
                    ])
                    try await session.start(task: task, successCriteria: criteria, targetDuration: durationSeconds)
                    if shouldPin {
                        Task { await SessionTemplateStore.shared.add(task: task, successCriteria: criteria, preferredDuration: durationSeconds) }
                    }
                    state.stopCreating()
                }
            } catch CaptureError.permissionDenied {
                withAnimation {
                    clarifyingQuestion = "Screen Recording permission required. Grant it in System Settings, then try again."
                }
            } catch AgentAIError.missingAPIKey {
                AppLogger.error("goal.validation_unavailable", ["reason": "missing_api_key"])
                withAnimation {
                    clarifyingQuestion = "Adia is not configured for monitoring yet. Add a Claude API key in Settings, then try again."
                }
            } catch {
                AppLogger.error("goal.start_failed", ["error": String(describing: error)])
                withAnimation { clarifyingQuestion = "Couldn't start — try again." }
            }
        }
    }
}
