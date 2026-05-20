import Testing
import Foundation
@testable import AdiCore

@Suite("SettingsStore")
struct SettingsStoreTests {

    private func reset() async {
        await MainActor.run {
            SettingsStore.shared.setAPIKey("")
        }
    }

    @Test func setAndRetrieveAPIKey() async {
        await reset()
        await MainActor.run {
            SettingsStore.shared.setAPIKey("sk-ant-test-key-12345")
        }
        let key = await MainActor.run { SettingsStore.shared.anthropicAPIKey }
        #expect(key == "sk-ant-test-key-12345")
    }

    @Test func setEmptyKeyClearsAPIKey() async {
        await MainActor.run {
            SettingsStore.shared.setAPIKey("sk-ant-initial")
        }
        await MainActor.run {
            SettingsStore.shared.setAPIKey("")
        }
        let key = await MainActor.run { SettingsStore.shared.anthropicAPIKey }
        #expect(key == nil)
    }

    @Test func setWhitespaceOnlyKeyClearsAPIKey() async {
        await MainActor.run {
            SettingsStore.shared.setAPIKey("sk-ant-initial")
        }
        await MainActor.run {
            SettingsStore.shared.setAPIKey("   \n\t  ")
        }
        let key = await MainActor.run { SettingsStore.shared.anthropicAPIKey }
        #expect(key == nil)
    }

    @Test func hasAPIKeyTrueWhenKeySet() async {
        await MainActor.run {
            SettingsStore.shared.setAPIKey("sk-ant-valid-key")
        }
        let has = await MainActor.run { SettingsStore.shared.hasAPIKey }
        #expect(has == true)
    }

    @Test func hasAPIKeyFalseWhenCleared() async {
        await MainActor.run {
            SettingsStore.shared.setAPIKey("sk-ant-temp")
            SettingsStore.shared.setAPIKey("")
        }
        let has = await MainActor.run { SettingsStore.shared.hasAPIKey }
        #expect(has == false)
    }

    @Test func keyTrimmedOnWrite() async {
        await MainActor.run {
            SettingsStore.shared.setAPIKey("  sk-ant-padded  \n")
        }
        let key = await MainActor.run { SettingsStore.shared.anthropicAPIKey }
        #expect(key == "sk-ant-padded")
    }

    // MARK: - normalizeDomain (static, pure)

    @Test func normalizeDomainStripsHttps() {
        #expect(SettingsStore.normalizeDomain("https://example.com/path") == "example.com")
    }

    @Test func normalizeDomainStripsHttp() {
        #expect(SettingsStore.normalizeDomain("http://example.com") == "example.com")
    }

    @Test func normalizeDomainStripsWww() {
        #expect(SettingsStore.normalizeDomain("www.example.com") == "example.com")
    }

    @Test func normalizeDomainStripsHttpsAndWww() {
        #expect(SettingsStore.normalizeDomain("https://www.example.com/foo?bar=1") == "example.com")
    }

    @Test func normalizeDomainAlreadyNormalized() {
        #expect(SettingsStore.normalizeDomain("reddit.com") == "reddit.com")
    }

    @Test func normalizeDomainLowercases() {
        #expect(SettingsStore.normalizeDomain("Reddit.COM") == "reddit.com")
    }

    // MARK: - Custom domain management

    private func resetDomains() async {
        await MainActor.run {
            // Clear custom and re-enable all defaults by rebuilding via known methods.
            for d in SettingsStore.shared.customBlockedDomains {
                SettingsStore.shared.removeCustomDomain(d)
            }
            for d in Session.defaultBlockedDomains {
                SettingsStore.shared.setDefaultDomain(d, enabled: true)
            }
        }
    }

    @Test func addCustomDomainAppearsInList() async {
        await resetDomains()
        await MainActor.run {
            SettingsStore.shared.addCustomDomain("chess.com")
        }
        let list = await MainActor.run { SettingsStore.shared.customBlockedDomains }
        #expect(list.contains("chess.com"))
        await resetDomains()
    }

    @Test func addCustomDomainNormalizesURL() async {
        await resetDomains()
        await MainActor.run {
            SettingsStore.shared.addCustomDomain("https://www.Chess.com/games")
        }
        let list = await MainActor.run { SettingsStore.shared.customBlockedDomains }
        #expect(list.contains("chess.com"))
        await resetDomains()
    }

    @Test func addCustomDomainDeduplicates() async {
        await resetDomains()
        await MainActor.run {
            SettingsStore.shared.addCustomDomain("chess.com")
            SettingsStore.shared.addCustomDomain("chess.com")
        }
        let list = await MainActor.run { SettingsStore.shared.customBlockedDomains }
        #expect(list.filter { $0 == "chess.com" }.count == 1)
        await resetDomains()
    }

    @Test func addCustomDomainIgnoresDefaultDomain() async {
        await resetDomains()
        await MainActor.run {
            SettingsStore.shared.addCustomDomain("reddit.com")
        }
        let list = await MainActor.run { SettingsStore.shared.customBlockedDomains }
        #expect(!list.contains("reddit.com"))
        await resetDomains()
    }

    @Test func removeCustomDomainRemovesIt() async {
        await resetDomains()
        await MainActor.run {
            SettingsStore.shared.addCustomDomain("chess.com")
            SettingsStore.shared.removeCustomDomain("chess.com")
        }
        let list = await MainActor.run { SettingsStore.shared.customBlockedDomains }
        #expect(!list.contains("chess.com"))
    }

    // MARK: - Default domain toggle

    @Test func disablingDefaultDomainRemovesFromEffective() async {
        await resetDomains()
        await MainActor.run {
            SettingsStore.shared.setDefaultDomain("reddit.com", enabled: false)
        }
        let effective = await MainActor.run { SettingsStore.shared.effectiveBlockedDomains }
        #expect(!effective.contains("reddit.com"))
        await resetDomains()
    }

    @Test func reenablingDefaultDomainRestoresInEffective() async {
        await resetDomains()
        await MainActor.run {
            SettingsStore.shared.setDefaultDomain("reddit.com", enabled: false)
            SettingsStore.shared.setDefaultDomain("reddit.com", enabled: true)
        }
        let effective = await MainActor.run { SettingsStore.shared.effectiveBlockedDomains }
        #expect(effective.contains("reddit.com"))
        await resetDomains()
    }

    @Test func isDefaultDomainEnabledReflectsToggle() async {
        await resetDomains()
        await MainActor.run {
            SettingsStore.shared.setDefaultDomain("youtube.com", enabled: false)
        }
        let enabled = await MainActor.run { SettingsStore.shared.isDefaultDomainEnabled("youtube.com") }
        #expect(enabled == false)
        await resetDomains()
    }

    // MARK: - effectiveBlockedDomains

    @Test func effectiveIncludesCustomAndDefaultsByDefault() async {
        await resetDomains()
        await MainActor.run {
            SettingsStore.shared.addCustomDomain("chess.com")
        }
        let effective = await MainActor.run { SettingsStore.shared.effectiveBlockedDomains }
        #expect(effective.contains("reddit.com"))
        #expect(effective.contains("chess.com"))
        await resetDomains()
    }

    @Test func effectiveDoesNotDuplicateCustomIfAlreadyDefault() async {
        await resetDomains()
        let effective = await MainActor.run { SettingsStore.shared.effectiveBlockedDomains }
        let counts = Dictionary(grouping: effective, by: { $0 }).mapValues(\.count)
        let hasDuplicate = counts.values.contains { $0 > 1 }
        #expect(!hasDuplicate)
    }
}
