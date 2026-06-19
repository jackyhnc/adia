import Foundation
import IOKit

public enum LicenseStatus: Equatable, Sendable {
    case unknown
    case trial(daysRemaining: Int)
    case trialExpired
    case licensed(email: String, plan: String)
    case invalid(reason: String)
}

public struct LicenseInfo: Codable, Equatable, Sendable {
    public let key: String
    public let email: String
    public let plan: String              // "monthly" | "yearly" | "lifetime"
    public let issuedAt: Date
    public let expiresAt: Date?          // nil = lifetime
    public let lastValidatedAt: Date
}

/// Owns license + trial state. Stores license in Keychain, trial start in UserDefaults.
/// Validates with the Adia license server (`https://adia.app/api/license/validate`) on
/// app launch and once per 24h. Allows 14 days offline grace.
@MainActor
public final class LicenseManager: ObservableObject {
    public static let shared = LicenseManager()

    @Published public private(set) var status: LicenseStatus = .unknown

    private let defaults = UserDefaults.standard
    private let trialStartKey = "trial.startedAt"
    private let lastValidatedKey = "license.lastValidatedAt"
    private let keychainService = "app.adia.license"
    private let keychainAccount = "license_info"
    private let trialDays = 7
    private let offlineGraceDays = 14

    /// Test-only stand-in for the Keychain. `nil` = not in test mode (use the real
    /// Keychain). `.some(nil)` = test mode, no stored license. `.some(info)` = test
    /// mode, license present. CI's headless macOS runner can't reliably read/write
    /// the login Keychain (locked, no interactive session), so `SecItemAdd`/
    /// `SecItemCopyMatching` silently no-op there — license-state tests inject
    /// through this in-memory seam instead so they exercise real status-machine
    /// logic without depending on OS Keychain availability.
    private var testLicenseOverride: LicenseInfo??

    // Force unwrap is safe: constant, well-formed URL string — `URL(string:)` cannot fail for it.
    public var serverBaseURL: URL = URL(string: "https://adia.app")!

    private init() {
        refreshLocalStatus()
    }

    // MARK: - Public API

    public func bootstrap() async {
        refreshLocalStatus()
        await validateIfNeeded()
    }

    public var isUsable: Bool {
        switch status {
        case .licensed, .trial: return true
        case .unknown, .trialExpired, .invalid: return false
        }
    }

    public func startTrialIfNeeded() {
        if defaults.object(forKey: trialStartKey) == nil {
            defaults.set(Date(), forKey: trialStartKey)
        }
        refreshLocalStatus()
    }

    public func currentLicense() -> LicenseInfo? {
        if let override = testLicenseOverride { return override }
        guard let data = Keychain.read(service: keychainService, account: keychainAccount),
              let info = try? JSONDecoder().decode(LicenseInfo.self, from: data)
        else { return nil }
        return info
    }

    /// Activate a license key. Returns nil on success, or an error message.
    public func activate(key: String, email: String) async -> String? {
        let cleanKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanKey.isEmpty else { return "License key is empty." }

        do {
            let info = try await serverActivate(key: cleanKey, email: cleanEmail)
            store(info)
            refreshLocalStatus()
            return nil
        } catch {
            return "Could not activate: \(error.localizedDescription)"
        }
    }

    public func deactivate() {
        if testLicenseOverride != nil { testLicenseOverride = .some(nil) }
        Keychain.delete(service: keychainService, account: keychainAccount)
        defaults.removeObject(forKey: lastValidatedKey)
        refreshLocalStatus()
    }

    /// Test-only: clears all license + trial state so tests start from a clean slate.
    /// Marked internal so it doesn't appear in the public API surface. Also arms the
    /// in-memory Keychain stand-in (see `testLicenseOverride`) for the rest of the test.
    internal func resetForTesting() {
        testLicenseOverride = .some(nil)
        Keychain.delete(service: keychainService, account: keychainAccount)
        defaults.removeObject(forKey: lastValidatedKey)
        defaults.removeObject(forKey: trialStartKey)
        refreshLocalStatus()
    }

    /// Test-only: forces the trial-start date to a specific time so the status
    /// machine can be exercised across trial windows without waiting wall-clock days.
    internal func _setTrialStartDateForTesting(_ date: Date) {
        defaults.set(date, forKey: trialStartKey)
        refreshLocalStatus()
    }

    internal func _injectLicenseForTesting(_ info: LicenseInfo) {
        testLicenseOverride = info
        defaults.set(Date(), forKey: lastValidatedKey)
        refreshLocalStatus()
    }

    // MARK: - Status computation

    private func refreshLocalStatus() {
        if let info = currentLicense() {
            if let exp = info.expiresAt, exp < Date() {
                // Subscription expired; check offline grace
                let lastValid = defaults.object(forKey: lastValidatedKey) as? Date ?? info.lastValidatedAt
                if Date().timeIntervalSince(lastValid) < TimeInterval(offlineGraceDays * 86400) {
                    status = .licensed(email: info.email, plan: info.plan)
                } else {
                    status = .invalid(reason: "Subscription expired. Please renew.")
                }
            } else {
                status = .licensed(email: info.email, plan: info.plan)
            }
            return
        }

        if let start = defaults.object(forKey: trialStartKey) as? Date {
            let elapsed = Date().timeIntervalSince(start)
            let remaining = trialDays - Int(elapsed / 86400)
            if remaining > 0 {
                status = .trial(daysRemaining: remaining)
            } else {
                status = .trialExpired
            }
        } else {
            status = .unknown
        }
    }

    // MARK: - Server communication

    private func validateIfNeeded() async {
        guard let info = currentLicense() else { return }
        let last = defaults.object(forKey: lastValidatedKey) as? Date ?? .distantPast
        if Date().timeIntervalSince(last) < 86400 { return }
        do {
            let fresh = try await serverValidate(key: info.key)
            store(fresh)
            defaults.set(Date(), forKey: lastValidatedKey)
            refreshLocalStatus()
        } catch {
            // Network failure: keep current status, fall through to offline grace.
            AppLogger.warning("license.validation_failed", ["error": "\(error)"])
        }
    }

    private func serverActivate(key: String, email: String) async throws -> LicenseInfo {
        let url = serverBaseURL.appendingPathComponent("api/license/activate")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "key": key,
            "email": email,
            "machine": Self.machineFingerprint(),
        ]
        req.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            let msg = (try? JSONDecoder().decode(ServerError.self, from: data))?.error
                ?? "Server error"
            throw NSError(domain: "Adia.License", code: 1, userInfo: [NSLocalizedDescriptionKey: msg])
        }
        return try JSONDecoder.iso.decode(LicenseInfo.self, from: data)
    }

    private func serverValidate(key: String) async throws -> LicenseInfo {
        let url = serverBaseURL.appendingPathComponent("api/license/validate")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONSerialization.data(withJSONObject: [
            "key": key,
            "machine": Self.machineFingerprint(),
        ])
        let (data, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse, http.statusCode == 200 else {
            throw NSError(domain: "Adia.License", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: "Validation failed"])
        }
        return try JSONDecoder.iso.decode(LicenseInfo.self, from: data)
    }

    private func store(_ info: LicenseInfo) {
        if testLicenseOverride != nil { testLicenseOverride = info; return }
        guard let data = try? JSONEncoder.iso.encode(info) else { return }
        Keychain.write(data, service: keychainService, account: keychainAccount)
    }

    // MARK: - Machine fingerprint (hashed)

    private static func machineFingerprint() -> String {
        let platformExpert = IOServiceGetMatchingService(
            kIOMainPortDefault,
            IOServiceMatching("IOPlatformExpertDevice"))
        defer { IOObjectRelease(platformExpert) }
        let serial = IORegistryEntryCreateCFProperty(
            platformExpert,
            kIOPlatformUUIDKey as CFString,
            kCFAllocatorDefault, 0
        )?.takeRetainedValue() as? String ?? "unknown"
        // Hash to avoid leaking the raw UUID.
        var hasher = Hasher()
        hasher.combine(serial)
        hasher.combine("adia.v1")
        return String(format: "%016x", UInt(bitPattern: hasher.finalize()))
    }
}

private struct ServerError: Decodable { let error: String }

private enum Keychain {
    static func read(service: String, account: String) -> Data? {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var item: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &item) == errSecSuccess
        else { return nil }
        return item as? Data
    }
    static func write(_ data: Data, service: String, account: String) {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(q as CFDictionary)
        var attrs = q
        attrs[kSecValueData as String] = data
        attrs[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        SecItemAdd(attrs as CFDictionary, nil)
    }
    static func delete(service: String, account: String) {
        let q: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(q as CFDictionary)
    }
}

private extension JSONEncoder {
    static let iso: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
}
private extension JSONDecoder {
    static let iso: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}
