import Testing
import Foundation
@testable import AdiCore

@Suite("EmbeddedSecrets")
struct EmbeddedSecretsTests {

    @Test func resolvedKeyIsNilWhenEmpty() {
        #expect(EmbeddedSecrets.resolvedKey == nil)
    }

    @Test func apiKeyIsEmptyInSource() {
        #expect(EmbeddedSecrets.apiKey.isEmpty)
    }
}
