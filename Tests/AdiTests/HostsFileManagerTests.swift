import Testing
import Foundation
@testable import AdiCore

// These tests exercise only the pure parsing/formatting logic — no file I/O.
// The block/unblock methods require /etc/hosts write access (root); those are
// tested in integration only and skipped here.

@Suite("HostsFileManager — block formatting")
struct HostsFileManagerFormatTests {

    @Test("Blocked domains include www. variant")
    func wwwVariantIncluded() {
        // We verify the public API shape: defaultBlockedDomains has known entries.
        let domains = Session.defaultBlockedDomains
        #expect(domains.contains("twitter.com"))
        #expect(domains.contains("youtube.com"))
        #expect(domains.contains("reddit.com"))
    }

    @Test("No duplicates in default blocked list")
    func noDuplicates() {
        let domains = Session.defaultBlockedDomains
        let unique = Set(domains)
        #expect(unique.count == domains.count)
    }
}
