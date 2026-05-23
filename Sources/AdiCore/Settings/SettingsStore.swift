import Foundation
import Security

/// Persistent app settings. API key lives in Keychain; the rest in UserDefaults.
@MainActor
public final class SettingsStore: ObservableObject {
    public static let shared = SettingsStore()

    private let defaults = UserDefaults.standard
    private let keychainService = "app.adia.keys"
    private let keychainAccount = "anthropic_api_key"

    // UserDefaults keys for domain lists
    private static let customDomainsKey  = "adia.customBlockedDomains"
    private static let disabledDomainsKey = "adia.disabledDefaultDomains"

    @Published public private(set) var anthropicAPIKey: String?
    @Published public var crashReportsEnabled: Bool {
        didSet { defaults.set(crashReportsEnabled, forKey: "crashReportsEnabled") }
    }
    @Published public var usageAnalyticsEnabled: Bool {
        didSet { defaults.set(usageAnalyticsEnabled, forKey: "usageAnalyticsEnabled") }
    }

    /// Domains the user added on top of the default list.
    @Published public private(set) var customBlockedDomains: [String] {
        didSet { Self.saveDomainList(customBlockedDomains, key: Self.customDomainsKey, to: defaults) }
    }

    /// Subset of `Session.defaultBlockedDomains` the user has disabled.
    @Published public private(set) var disabledDefaultDomains: Set<String> {
        didSet { Self.saveDomainList(Array(disabledDefaultDomains), key: Self.disabledDomainsKey, to: defaults) }
    }

    /// Active block list for new sessions: enabled defaults + custom additions.
    public var effectiveBlockedDomains: [String] {
        let enabled = Session.defaultBlockedDomains.filter { !disabledDefaultDomains.contains($0) }
        let extra = customBlockedDomains.filter { !enabled.contains($0) }
        return enabled + extra
    }

    private init() {
        crashReportsEnabled  = defaults.object(forKey: "crashReportsEnabled")  as? Bool ?? true
        usageAnalyticsEnabled = defaults.object(forKey: "usageAnalyticsEnabled") as? Bool ?? true
        anthropicAPIKey = Self.readKey(service: keychainService, account: keychainAccount)
            ?? ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]
            ?? Self.readKeyFromHomeFile()
        customBlockedDomains  = Self.loadDomainList(key: Self.customDomainsKey,  from: defaults)
        disabledDefaultDomains = Set(Self.loadDomainList(key: Self.disabledDomainsKey, from: defaults))
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

    // MARK: - Domain management

    /// Add a domain to the custom block list. Normalizes the input (strips https://, www.).
    public func addCustomDomain(_ raw: String) {
        let domain = Self.normalizeDomain(raw)
        guard !domain.isEmpty,
              !customBlockedDomains.contains(domain),
              !Session.defaultBlockedDomains.contains(domain)
        else { return }
        customBlockedDomains.append(domain)
    }

    public func removeCustomDomain(_ domain: String) {
        customBlockedDomains.removeAll { $0 == domain }
    }

    /// Enable or disable a domain from the built-in default list.
    public func setDefaultDomain(_ domain: String, enabled: Bool) {
        if enabled {
            disabledDefaultDomains.remove(domain)
        } else {
            disabledDefaultDomains.insert(domain)
        }
    }

    /// Whether a built-in default domain is currently enabled.
    public func isDefaultDomainEnabled(_ domain: String) -> Bool {
        !disabledDefaultDomains.contains(domain)
    }

    // MARK: - Domain persistence helpers

    private static func saveDomainList(_ list: [String], key: String, to defaults: UserDefaults) {
        guard let data = try? JSONEncoder().encode(list) else { return }
        defaults.set(data, forKey: key)
    }

    private static func loadDomainList(key: String, from defaults: UserDefaults) -> [String] {
        guard let data = defaults.data(forKey: key),
              let list = try? JSONDecoder().decode([String].self, from: data)
        else { return [] }
        return list
    }

    /// Strips protocol, www, path, query, and port: "https://www.example.com:8080/foo?q=1" → "example.com"
    static func normalizeDomain(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        for prefix in ["https://", "http://"] {
            if s.hasPrefix(prefix) { s = String(s.dropFirst(prefix.count)) }
        }
        if s.hasPrefix("www.") { s = String(s.dropFirst(4)) }
        s = s.components(separatedBy: "/").first ?? s
        s = s.components(separatedBy: "?").first ?? s
        // Strip optional port ("example.com:8080" → "example.com"). Without this,
        // the /etc/hosts entry "127.0.0.1 example.com:8080" is syntactically invalid
        // and the domain would not be blocked.
        s = s.components(separatedBy: ":").first ?? s
        return s
    }

    // MARK: - Home-file fallback
    //
    // Single-line text file at ~/.adia/anthropic_key. Lets you keep a dev key out
    // of the repo without exporting an env var before every launch. Lives outside
    // the repo by design.

    private static func readKeyFromHomeFile() -> String? {
        let home = NSHomeDirectory()
        for filename in ["anthropic_key", "api_key"] {
            let path = "\(home)/.adia/\(filename)"
            guard let raw = try? String(contentsOfFile: path, encoding: .utf8) else { continue }
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty { return trimmed }
        }
        return nil
    }

    // MARK: - Keychain helpers

    private static func readKey(service: String, account: String) -> String? {
        let query: [String: Any] = [
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
