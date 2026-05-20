import Foundation
import Security

/// Persistent app settings. API key lives in Keychain; the rest in UserDefaults.
@MainActor
public final class SettingsStore: ObservableObject {
    public static let shared = SettingsStore()

    private let defaults = UserDefaults.standard
    private let keychainService = "app.adia.keys"
    private let keychainAccount = "anthropic_api_key"

    @Published public private(set) var anthropicAPIKey: String?
    @Published public var crashReportsEnabled: Bool {
        didSet { defaults.set(crashReportsEnabled, forKey: "crashReportsEnabled") }
    }
    @Published public var usageAnalyticsEnabled: Bool {
        didSet { defaults.set(usageAnalyticsEnabled, forKey: "usageAnalyticsEnabled") }
    }

    private init() {
        crashReportsEnabled = defaults.object(forKey: "crashReportsEnabled") as? Bool ?? true
        usageAnalyticsEnabled = defaults.object(forKey: "usageAnalyticsEnabled") as? Bool ?? true
        anthropicAPIKey = Self.readKey(service: keychainService, account: keychainAccount)
            ?? ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
    }

    public var hasAPIKey: Bool {
        guard let k = anthropicAPIKey else { return false }
        return !k.trimmingCharacters(in: .whitespaces).isEmpty
    }

    public func setAPIKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            Self.deleteKey(service: keychainService, account: keychainAccount)
            anthropicAPIKey = nil
        } else {
            Self.writeKey(trimmed, service: keychainService, account: keychainAccount)
            anthropicAPIKey = trimmed
        }
    }

    // MARK: - Keychain helpers

    private static func readKey(service: String, account: String) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func writeKey(_ value: String, service: String, account: String) {
        let data = value.data(using: .utf8)!  // .utf8 encoding never fails for Swift String
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
        var attrs = query
        attrs[kSecValueData as String] = data
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attrs as CFDictionary, nil)
    }

    private static func deleteKey(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
