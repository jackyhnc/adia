import SwiftUI
import AdiCore

struct SessionCreationView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss

    @State private var taskDescription = ""
    @State private var successCriteria = ""
    @FocusState private var focusedField: Field?

    enum Field { case description, criteria }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header

            VStack(alignment: .leading, spacing: 12) {
                fieldLabel("What are you working on?")
                TextField("e.g. Write my ENGL 101 essay", text: $taskDescription, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
                    .focused($focusedField, equals: .description)

                fieldLabel("How will you know you're done?")
                TextField("e.g. Submit to Canvas and see the confirmation screen", text: $successCriteria, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
                    .focused($focusedField, equals: .criteria)
                    .font(.system(size: 13))

                Text("Be specific — Adia uses this to verify completion.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack {
                Button("Cancel") { dismiss() }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                Spacer()
                Button {
                    let task = SessionTask(
                        description: taskDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                        successCriteria: successCriteria.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                    appState.startSession(task: task)
                    dismiss()
                } label: {
                    Label("Go", systemImage: "bolt.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(isValid ? Color.accentColor : Color.gray)
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .disabled(!isValid)
            }
        }
        .padding(24)
        .frame(width: 420, height: 300)
        .onAppear { focusedField = .description }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("New Session")
                .font(.system(size: 18, weight: .bold))
            Text("Everything else gets blocked until you're done.")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
    }

    private func fieldLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.primary)
    }

    private var isValid: Bool {
        taskDescription.count > 3 && successCriteria.count > 5
    }
}
