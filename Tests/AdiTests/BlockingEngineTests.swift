import Testing
import Foundation
@testable import AdiCore

@Suite("BlockingEngine")
struct BlockingEngineTests {

    func makeTempHosts(content: String = "127.0.0.1 localhost\n::1 localhost\n") throws -> (BlockingEngine, URL) {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("adia_test_hosts_\(UUID().uuidString)")
        try content.write(to: url, atomically: true, encoding: .utf8)
        return (BlockingEngine(hostsPath: url.path), url)
    }

    @Test("Block writes 127.0.0.1 entries for domain and www variant")
    func blockWritesEntries() throws {
        let (engine, url) = try makeTempHosts()
        defer { try? FileManager.default.removeItem(at: url) }

        try engine.block(domains: ["twitter.com"])

        let content = try String(contentsOf: url)
        #expect(content.contains("127.0.0.1 twitter.com"))
        #expect(content.contains("127.0.0.1 www.twitter.com"))
    }

    @Test("Block multiple domains all appear in hosts")
    func blockMultipleDomains() throws {
        let (engine, url) = try makeTempHosts()
        defer { try? FileManager.default.removeItem(at: url) }

        try engine.block(domains: ["twitter.com", "reddit.com", "youtube.com"])

        let content = try String(contentsOf: url)
        #expect(content.contains("127.0.0.1 twitter.com"))
        #expect(content.contains("127.0.0.1 reddit.com"))
        #expect(content.contains("127.0.0.1 youtube.com"))
    }

    @Test("Unblock removes Adia section entirely")
    func unblockAll() throws {
        let (engine, url) = try makeTempHosts()
        defer { try? FileManager.default.removeItem(at: url) }

        try engine.block(domains: ["twitter.com"])
        try engine.unblockAll()

        let content = try String(contentsOf: url)
        #expect(!content.contains("twitter.com"))
        #expect(!content.contains("# Adia Block"))
    }

    @Test("Unblock preserves original host entries")
    func unblockPreservesOriginal() throws {
        let original = "127.0.0.1 localhost\n::1 localhost\n255.255.255.255 broadcasthost\n"
        let (engine, url) = try makeTempHosts(content: original)
        defer { try? FileManager.default.removeItem(at: url) }

        try engine.block(domains: ["twitter.com"])
        try engine.unblockAll()

        let content = try String(contentsOf: url)
        #expect(content.contains("127.0.0.1 localhost"))
        #expect(content.contains("::1 localhost"))
        #expect(content.contains("broadcasthost"))
    }

    @Test("Calling block twice replaces previous entries")
    func doubleBlockReplaces() throws {
        let (engine, url) = try makeTempHosts()
        defer { try? FileManager.default.removeItem(at: url) }

        try engine.block(domains: ["twitter.com"])
        try engine.block(domains: ["reddit.com"])

        let domains = try engine.blockedDomains()
        #expect(domains.count == 1)
        #expect(domains.contains("reddit.com"))
        #expect(!domains.contains("twitter.com"))
    }

    @Test("blockedDomains returns only base domains, not www variants")
    func blockedDomainsNoDuplicates() throws {
        let (engine, url) = try makeTempHosts()
        defer { try? FileManager.default.removeItem(at: url) }

        try engine.block(domains: ["twitter.com", "reddit.com"])
        let domains = try engine.blockedDomains()

        #expect(domains.count == 2)
        #expect(!domains.contains(where: { $0.hasPrefix("www.") }))
    }

    @Test("Domain is lowercased when written")
    func lowercasesDomain() throws {
        let (engine, url) = try makeTempHosts()
        defer { try? FileManager.default.removeItem(at: url) }

        try engine.block(domains: ["Twitter.COM"])

        let content = try String(contentsOf: url)
        #expect(content.contains("127.0.0.1 twitter.com"))
        #expect(!content.contains("Twitter"))
    }
}
