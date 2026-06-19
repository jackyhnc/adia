import SwiftUI

public struct PaywallView: View {
    @ObservedObject private var license = LicenseManager.shared
    @State private var licenseKey: String = ""
    @State private var email: String = ""
    @State private var error: String?
    @State private var activating = false

    public var onActivated: () -> Void
    public init(onActivated: @escaping () -> Void) { self.onActivated = onActivated }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Your trial has ended", systemImage: "hourglass")
                .font(.title3).bold()

            Text("Adia Pro keeps you focused — $7/mo, $59/year, or $149 lifetime.")
                .foregroundStyle(.secondary)

            // Force unwraps below are safe: constant, well-formed URL strings.
            HStack(spacing: 10) {
                Link(destination: URL(string: "https://adia.app/pricing")!) {
                    Label("See pricing", systemImage: "tag")
                }
                .buttonStyle(.borderedProminent)
                Link(destination: URL(string: "https://adia.app/checkout?plan=yearly")!) {
                    Text("Buy yearly →")
                }
            }

            Divider()

            Text("Already bought one?").font(.headline)
            TextField("Email", text: $email).textFieldStyle(.roundedBorder)
            TextField("License key", text: $licenseKey).textFieldStyle(.roundedBorder)

            HStack {
                Button(activating ? "Activating…" : "Activate") {
                    Task { await activate() }
                }
                .disabled(activating || licenseKey.isEmpty || email.isEmpty)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }
            if let err = error {
                Text(err).foregroundStyle(.red).font(.callout)
            }
        }
        .padding(20)
        .frame(width: 380)
    }

    private func activate() async {
        activating = true
        error = nil
        let e = await license.activate(key: licenseKey, email: email)
        activating = false
        if e == nil { onActivated() } else { error = e }
    }
}
