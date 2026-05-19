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
}
