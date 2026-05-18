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
}
