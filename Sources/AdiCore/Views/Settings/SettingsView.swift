import SwiftUI

public struct SettingsView: View {
    @AppStorage("settingsSelectedTab") private var selectedTab: Int = 0

    nonisolated static let tabHeights: [Int: CGFloat] = [
        0: 500,   // Account  — API key, license, shortcuts, reminders, daily goal
        1: 560,   // Blocking — many toggles, benefits from tall viewport
        2: 490,   // Templates — list + footer row (two toggles)
        3: 600,   // History  — heatmap + insights + session list
    ]

    var currentHeight: CGFloat { Self.tabHeights[selectedTab] ?? 500 }

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            AccountSettingsTab()
                .tabItem { Label("Account", systemImage: "person.circle") }
                .tag(0)
            BlockingSettingsTab()
                .tabItem { Label("Blocking", systemImage: "hand.raised.fill") }
                .tag(1)
            TemplatesSettingsTab()
                .tabItem { Label("Templates", systemImage: "pin.fill") }
                .tag(2)
            HistoryTab()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(3)
        }
        .padding(20)
        .frame(width: 480, height: currentHeight)
        .animation(.easeOut(duration: 0.18), value: selectedTab)
    }
}
