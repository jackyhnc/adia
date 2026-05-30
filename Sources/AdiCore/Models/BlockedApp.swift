import Foundation

/// A named macOS app that Adia monitors during focus sessions.
/// When the app becomes frontmost, an immediate callout fires.
public struct BlockedApp: Codable, Sendable, Identifiable {
    public let id: String    // bundle identifier e.g. "com.hnc.Discord"
    public let name: String  // human-readable display name shown in Settings

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}
