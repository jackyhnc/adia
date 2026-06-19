import Foundation
import Security

/// Persistent app settings. API key lives in Keychain; the rest in UserDefaults.
@MainActor
public final class SettingsStore: ObservableObject {
    public static let shared = SettingsStore()

    private let defaults = UserDefaults.standard
    private let keychainService = "app.adia.keys"
    private let keychainAccount = "agent_ai_key"
    private let legacyKeychainAccount = "anthropic_api_key"

    // UserDefaults keys for domain lists
    private static let customDomainsKey   = "adia.customBlockedDomains"
    private static let disabledDomainsKey = "adia.disabledDefaultDomains"

    // UserDefaults keys for app lists
    private static let customAppsKey     = "adia.customBlockedApps"
    private static let disabledAppsKey   = "adia.disabledDefaultApps"

    @Published public private(set) var agentAIKey: String?
    @Published public var crashReportsEnabled: Bool {
        didSet { defaults.set(crashReportsEnabled, forKey: "crashReportsEnabled") }
    }
    @Published public var usageAnalyticsEnabled: Bool {
        didSet { defaults.set(usageAnalyticsEnabled, forKey: "usageAnalyticsEnabled") }
    }
    @Published public var showMenuBarItem: Bool {
        didSet { defaults.set(showMenuBarItem, forKey: "adia.showMenuBarItem") }
    }
    /// When true the idle notch quick-launch row shows templates in the user's manually
    /// reordered file order; when false (default) it shows the two most-recently-used.
    @Published public var idleTemplatesFollowManualOrder: Bool {
        didSet { defaults.set(idleTemplatesFollowManualOrder, forKey: "adia.idleTemplatesFollowManualOrder") }
    }
    /// How often (in minutes) the notch re-opens to remind the user to verify after
    /// their session's target duration has elapsed. Clamped to `Self.timerExpiredRearmMinuteOptions`
    /// so a corrupted default can't silently disable the reminder (e.g. by storing 0).
    @Published public var timerExpiredRearmMinutes: Int {
        didSet { defaults.set(timerExpiredRearmMinutes, forKey: "adia.timerExpiredRearmMinutes") }
    }

    /// Daily focus goal in minutes. nil = no goal set. When set, the idle notch shows
    /// a progress bar toward the target and the collapsed pill shows "45m / 2h" format.
    @Published public var dailyFocusGoalMinutes: Int? {
        didSet {
            if let m = dailyFocusGoalMinutes {
                defaults.set(m, forKey: "adia.dailyFocusGoalMinutes")
            } else {
                defaults.removeObject(forKey: "adia.dailyFocusGoalMinutes")
            }
        }
    }

    /// Allowed presets for the daily focus goal picker in Settings.
    public nonisolated static let dailyGoalPresets: [(Int, String)] = [
        (30, "30m"), (60, "1h"), (90, "90m"), (120, "2h"), (180, "3h"), (240, "4h")
    ]

    /// Domains the user added on top of the default list.
    @Published public private(set) var customBlockedDomains: [String] {
        didSet { Self.saveDomainList(customBlockedDomains, key: Self.customDomainsKey, to: defaults) }
    }

    /// Subset of `Session.defaultBlockedDomains` the user has disabled.
    @Published public private(set) var disabledDefaultDomains: Set<String> {
        didSet { Self.saveDomainList(Array(disabledDefaultDomains), key: Self.disabledDomainsKey, to: defaults) }
    }

    /// Active domain block list for new sessions: enabled defaults + custom additions.
    public var effectiveBlockedDomains: [String] {
        let enabled = Session.defaultBlockedDomains.filter { !disabledDefaultDomains.contains($0) }
        let extra = customBlockedDomains.filter { !enabled.contains($0) }
        return enabled + extra
    }

    // MARK: - App blocking

    /// Bundle IDs the user added on top of the default app block list.
    @Published public private(set) var customBlockedApps: [String] {
        didSet { Self.saveDomainList(customBlockedApps, key: Self.customAppsKey, to: defaults) }
    }

    /// Subset of `Session.defaultBlockedAppBundleIDs` the user has disabled.
    @Published public private(set) var disabledDefaultApps: Set<String> {
        didSet { Self.saveDomainList(Array(disabledDefaultApps), key: Self.disabledAppsKey, to: defaults) }
    }

    /// Allowed values for `timerExpiredRearmMinutes`, shown as a picker in Settings.
    /// 10 is the historical default — fast enough to keep nudging, slow enough not to nag.
    public nonisolated static let timerExpiredRearmMinuteOptions: [Int] = [5, 10, 15, 30]

    /// `timerExpiredRearmMinutes` converted to seconds for `Task.sleep`.
    public var timerExpiredRearmInterval: TimeInterval {
        TimeInterval(timerExpiredRearmMinutes * 60)
    }

    /// Active app block list for new sessions: enabled defaults + custom additions.
    public var effectiveBlockedApps: [String] {
        let enabled = Session.defaultBlockedAppBundleIDs.filter { !disabledDefaultApps.contains($0) }
        let extra = customBlockedApps.filter { !enabled.contains($0) }
        return enabled + extra
    }

    private init() {
        crashReportsEnabled              = defaults.object(forKey: "crashReportsEnabled")                       as? Bool ?? true
        usageAnalyticsEnabled            = defaults.object(forKey: "usageAnalyticsEnabled")                    as? Bool ?? true
        showMenuBarItem                  = defaults.object(forKey: "adia.showMenuBarItem")                     as? Bool ?? true
        idleTemplatesFollowManualOrder   = defaults.object(forKey: "adia.idleTemplatesFollowManualOrder")      as? Bool ?? false
        let storedRearmMinutes = defaults.object(forKey: "adia.timerExpiredRearmMinutes") as? Int ?? 10
        timerExpiredRearmMinutes = Self.timerExpiredRearmMinuteOptions.contains(storedRearmMinutes) ? storedRearmMinutes : 10
        let storedGoal = defaults.object(forKey: "adia.dailyFocusGoalMinutes") as? Int
        dailyFocusGoalMinutes = storedGoal.flatMap { $0 > 0 ? $0 : nil }
        // Resolve the agent AI key from the first source that yields a non-empty
        // value. Legacy names are still accepted so existing local installs keep
        // working after the user-facing naming moved away from provider branding.
        let env = ProcessInfo.processInfo.environment
        agentAIKey = Self.anthropicCompatibleKey(Self.readKey(service: keychainService, account: keychainAccount))
            ?? Self.anthropicCompatibleKey(Self.readKey(service: keychainService, account: legacyKeychainAccount))
            ?? Self.anthropicCompatibleKey(env["ANTHROPIC_API_KEY"])
            ?? Self.anthropicCompatibleKey(env["ADIA_AGENT_AI_KEY"])
            ?? Self.anthropicCompatibleKey(Self.readKeyFromHomeFile())
            ?? Self.anthropicCompatibleKey(EmbeddedSecrets.resolvedKey)
        customBlockedDomains   = Self.loadDomainList(key: Self.customDomainsKey,   from: defaults)
        disabledDefaultDomains = Set(Self.loadDomainList(key: Self.disabledDomainsKey, from: defaults))
        customBlockedApps      = Self.loadDomainList(key: Self.customAppsKey,      from: defaults)
        disabledDefaultApps    = Set(Self.loadDomainList(key: Self.disabledAppsKey,    from: defaults))
    }

    /// Returns the trimmed string, or nil if it is nil/empty/whitespace-only.
    private nonisolated static func nonEmpty(_ s: String?) -> String? {
        guard let s, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        return s
    }

    public nonisolated static func anthropicCompatibleKey(_ s: String?) -> String? {
        guard let value = nonEmpty(s) else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("sk-ant-") else { return nil }
        return trimmed
    }

    public nonisolated static func isAnthropicCompatibleKey(_ s: String) -> Bool {
        anthropicCompatibleKey(s) != nil
    }

    public var hasAPIKey: Bool {
        guard let k = agentAIKey else { return false }
        return !k.trimmingCharacters(in: .whitespaces).isEmpty
    }

    @discardableResult
    public func setAPIKey(_ key: String) -> Bool {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            Self.deleteKey(service: keychainService, account: keychainAccount)
            Self.deleteKey(service: keychainService, account: legacyKeychainAccount)
            agentAIKey = nil
            return true
        } else {
            guard Self.isAnthropicCompatibleKey(trimmed) else { return false }
            Self.writeKey(trimmed, service: keychainService, account: keychainAccount)
            agentAIKey = trimmed
            return true
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

    // MARK: - App management

    /// Add a bundle ID to the custom app block list.
    public func addCustomApp(_ bundleID: String) {
        let id = bundleID.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !id.isEmpty,
              !customBlockedApps.contains(id),
              !Session.defaultBlockedAppBundleIDs.contains(id)
        else { return }
        customBlockedApps.append(id)
    }

    public func removeCustomApp(_ bundleID: String) {
        customBlockedApps.removeAll { $0 == bundleID }
    }

    /// Enable or disable a bundle ID from the built-in default app list.
    public func setDefaultApp(_ bundleID: String, enabled: Bool) {
        if enabled {
            disabledDefaultApps.remove(bundleID)
        } else {
            disabledDefaultApps.insert(bundleID)
        }
    }

    /// Whether a built-in default app is currently enabled.
    public func isDefaultAppEnabled(_ bundleID: String) -> Bool {
        !disabledDefaultApps.contains(bundleID)
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

    /// Strips protocol, www, path, query, fragment, and port: "https://www.example.com:8080/foo?q=1#sec" → "example.com"
    nonisolated static func normalizeDomain(_ raw: String) -> String {
        var s = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        for prefix in ["https://", "http://"] {
            if s.hasPrefix(prefix) { s = String(s.dropFirst(prefix.count)) }
        }
        if s.hasPrefix("www.") { s = String(s.dropFirst(4)) }
        s = s.components(separatedBy: "/").first ?? s
        s = s.components(separatedBy: "?").first ?? s
        // Strip fragment (#section) — bare fragments like "example.com#intro" aren't
        // stripped by the path split above and produce invalid /etc/hosts entries.
        s = s.components(separatedBy: "#").first ?? s
        // Strip optional port ("example.com:8080" → "example.com"). Without this,
        // the /etc/hosts entry "127.0.0.1 example.com:8080" is syntactically invalid
        // and the domain would not be blocked.
        s = s.components(separatedBy: ":").first ?? s
        return s
    }

    // MARK: - Home-file fallback
    //
    // Single-line text file at ~/.adia/anthropic_key or ~/.adia/agent_key.
    // Legacy filenames are still checked for smooth migration.

    private static func readKeyFromHomeFile() -> String? {
        let home = NSHomeDirectory()
        for filename in ["anthropic_key", "agent_key", "api_key", "openai_key"] {
            let path = "\(home)/.adia/\(filename)"
            guard let raw = try? String(contentsOfFile: path, encoding: .utf8) else { continue }
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if let key = anthropicCompatibleKey(trimmed) { return key }
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
        // Treat an empty/whitespace-only stored value as "no key" so a stale or
        // blank Keychain entry doesn't short-circuit the resolution chain and
        // suppress the env / home-file / embedded fallbacks.
        guard let s = String(data: data, encoding: .utf8) else { return nil }
        return s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : s
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
