import Testing
@testable import AdiCore

@Suite("HostsFileManager")
struct HostsFileManagerTests {

    @Test func defaultBlockedDomainsContainsExpectedSites() {
        let domains = Session.defaultBlockedDomains
        #expect(domains.contains("twitter.com"))
        #expect(domains.contains("youtube.com"))
        #expect(domains.contains("reddit.com"))
    }

    @Test func noDuplicatesInDefaultBlockedList() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count)
    }

    // MARK: - stripped

    @Test func strippedRemovesAdiaBoundsAndContent() {
        let raw = "127.0.0.1 localhost\n# adia-block-begin\n127.0.0.1 youtube.com\n# adia-block-end\n"
        let result = HostsFileManager.stripped(raw)
        #expect(result.contains("127.0.0.1 localhost"))
        #expect(!result.contains("adia-block"))
        #expect(!result.contains("youtube.com"))
    }

    @Test func strippedPassesThroughContentWithNoBlock() {
        let original = "127.0.0.1 localhost\n255.255.255.255 broadcasthost\n"
        let result = HostsFileManager.stripped(original)
        #expect(result.contains("localhost"))
        #expect(result.contains("broadcasthost"))
    }

    @Test func strippedOnEmptyStringReturnsNewline() {
        let result = HostsFileManager.stripped("")
        #expect(result == "\n")
    }

    @Test func strippedHandlesMultipleDomainsInBlock() {
        let raw = """
        127.0.0.1 localhost
        # adia-block-begin
        127.0.0.1 youtube.com
        127.0.0.1 www.youtube.com
        127.0.0.1 reddit.com
        127.0.0.1 www.reddit.com
        # adia-block-end
        """
        let result = HostsFileManager.stripped(raw)
        #expect(result.contains("127.0.0.1 localhost"))
        #expect(!result.contains("youtube.com"))
        #expect(!result.contains("reddit.com"))
        #expect(!result.contains("adia-block"))
    }

    // MARK: - buildBlock

    @Test func buildBlockContainsBothWWWAndBareDomains() {
        let block = HostsFileManager.buildBlock(domains: ["youtube.com"])
        #expect(block.contains("127.0.0.1 youtube.com"))
        #expect(block.contains("127.0.0.1 www.youtube.com"))
    }

    @Test func buildBlockIncludesMobileSubdomains() {
        let block = HostsFileManager.buildBlock(domains: ["reddit.com"])
        for prefix in HostsFileManager.additionalBlockedSubdomainPrefixes {
            #expect(block.contains("127.0.0.1 \(prefix).reddit.com"),
                    "expected \(prefix).reddit.com in block")
        }
    }

    @Test func buildBlockMobileSubdomainsForMultipleDomains() {
        let block = HostsFileManager.buildBlock(domains: ["reddit.com", "twitter.com"])
        #expect(block.contains("127.0.0.1 m.reddit.com"))
        #expect(block.contains("127.0.0.1 m.twitter.com"))
        #expect(block.contains("127.0.0.1 old.reddit.com"))
    }

    @Test func buildBlockWrapsWithMarkers() {
        let block = HostsFileManager.buildBlock(domains: ["reddit.com"])
        #expect(block.contains("# adia-block-begin"))
        #expect(block.contains("# adia-block-end"))
    }

    @Test func buildBlockEmptyDomainsProducesEmptySection() {
        let block = HostsFileManager.buildBlock(domains: [])
        #expect(block.contains("# adia-block-begin"))
        #expect(block.contains("# adia-block-end"))
        #expect(!block.contains("127.0.0.1"))
    }

    @Test func buildBlockMultipleDomains() {
        let block = HostsFileManager.buildBlock(domains: ["a.com", "b.com"])
        #expect(block.contains("127.0.0.1 a.com"))
        #expect(block.contains("127.0.0.1 www.a.com"))
        #expect(block.contains("127.0.0.1 b.com"))
        #expect(block.contains("127.0.0.1 www.b.com"))
    }

    // MARK: - parseBlocked

    @Test func parseBlockedExtractsBareDomains() {
        let content = """
        127.0.0.1 localhost
        # adia-block-begin
        127.0.0.1 youtube.com
        127.0.0.1 www.youtube.com
        127.0.0.1 reddit.com
        127.0.0.1 www.reddit.com
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains.contains("youtube.com"))
        #expect(domains.contains("reddit.com"))
        #expect(!domains.contains("www.youtube.com"))
        #expect(!domains.contains("www.reddit.com"))
        #expect(domains.count == 2)
    }

    @Test func parseBlockedSkipsMobileSubdomainVariants() {
        // Content manually crafted with m./mobile./old. entries — all should be filtered.
        let content = """
        # adia-block-begin
        127.0.0.1 reddit.com
        127.0.0.1 www.reddit.com
        127.0.0.1 m.reddit.com
        127.0.0.1 mobile.reddit.com
        127.0.0.1 old.reddit.com
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["reddit.com"])
        #expect(!domains.contains("www.reddit.com"))
        #expect(!domains.contains("m.reddit.com"))
        #expect(!domains.contains("mobile.reddit.com"))
        #expect(!domains.contains("old.reddit.com"))
    }

    @Test func buildThenParseRoundTripIncludesMobileEntries() {
        // buildBlock now emits m./mobile./old. rows; parseBlocked must still return bare domains only.
        let input = ["reddit.com", "twitter.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        // Sanity-check that the block actually has mobile entries before testing the filter.
        #expect(block.contains("127.0.0.1 m.reddit.com"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input))
    }

    @Test func parseBlockedReturnsEmptyWhenNoMarkers() {
        let content = "127.0.0.1 localhost\n"
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains.isEmpty)
    }

    @Test func parseBlockedReturnsEmptyWhenBlockIsEmpty() {
        let content = "127.0.0.1 localhost\n# adia-block-begin\n# adia-block-end\n"
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains.isEmpty)
    }

    // MARK: - Round-trip

    @Test func buildThenParseRoundTrip() {
        let domains = ["twitter.com", "reddit.com", "youtube.com"]
        let block = HostsFileManager.buildBlock(domains: domains)
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(domains))
    }

    @Test func strippedThenBuildRoundTrip() {
        let original = "127.0.0.1 localhost\n"
        let withBlock = original + HostsFileManager.buildBlock(domains: ["youtube.com"])
        let stripped = HostsFileManager.stripped(withBlock)
        #expect(stripped.contains("localhost"))
        #expect(!stripped.contains("youtube.com"))
        // Re-blocking with a different domain should replace cleanly
        let reBlocked = stripped + HostsFileManager.buildBlock(domains: ["reddit.com"])
        #expect(!reBlocked.contains("youtube.com"))
        #expect(reBlocked.contains("reddit.com"))
    }

    // MARK: - AMP subdomain blocking

    @Test func buildBlockIncludesAmpSubdomain() {
        let block = HostsFileManager.buildBlock(domains: ["reddit.com"])
        #expect(block.contains("127.0.0.1 amp.reddit.com"),
                "amp.reddit.com must be blocked to prevent Google AMP bypass")
    }

    @Test func ampSubdomainPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("amp"))
    }

    @Test func parseBlockedFiltersAmpSubdomain() {
        let content = """
        # adia-block-begin
        127.0.0.1 reddit.com
        127.0.0.1 www.reddit.com
        127.0.0.1 m.reddit.com
        127.0.0.1 mobile.reddit.com
        127.0.0.1 old.reddit.com
        127.0.0.1 amp.reddit.com
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["reddit.com"])
        #expect(!domains.contains("amp.reddit.com"))
    }

    @Test func buildThenParseRoundTripWithAmp() {
        let input = ["reddit.com", "theguardian.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        #expect(block.contains("127.0.0.1 amp.reddit.com"))
        #expect(block.contains("127.0.0.1 amp.theguardian.com"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input))
    }
}
