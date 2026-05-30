import Testing
@testable import AdiCore

@Suite("AppMonitor")
struct AppMonitorTests {

    // MARK: - callout(for:) — pure logic, no AppKit required

    @Test func calloutIsNonEmpty() {
        let msg = AppMonitor.callout(for: "Discord")
        #expect(!msg.isEmpty)
    }

    @Test func calloutHasNoFormatSpecifier() {
        // %@ must be substituted — raw format strings must never reach the user.
        for _ in 0..<30 {
            let msg = AppMonitor.callout(for: "Steam")
            #expect(!msg.contains("%@"))
        }
    }

    @Test func calloutWithAppNameEitherContainsNameOrIsGeneric() {
        // Over many calls, some will embed the name and some will use generic text.
        // Regardless, every result must be a known string (no garbage).
        let appName = "TestApp"
        let allStrings: [String] = AppMonitor.callouts.map { template in
            template.contains("%@") ? String(format: template, appName) : template
        }
        for _ in 0..<30 {
            let msg = AppMonitor.callout(for: appName)
            #expect(allStrings.contains(msg))
        }
    }

    @Test func calloutPoolCoversNamedAndGenericEntries() {
        // Sanity: the callout pool must have both %@-style and plain entries
        // so callout(for:) can sometimes embed the name, sometimes stay generic.
        let hasNamed  = AppMonitor.callouts.contains { $0.contains("%@") }
        let hasPlain  = AppMonitor.callouts.contains { !$0.contains("%@") }
        #expect(hasNamed)
        #expect(hasPlain)
    }

    @Test func calloutEmptyAppNameDoesNotCrash() {
        let msg = AppMonitor.callout(for: "")
        #expect(!msg.isEmpty)
        #expect(!msg.contains("%@"))
    }

    @Test func calloutSpecialCharAppNameDoesNotCrash() {
        let msg = AppMonitor.callout(for: "app %@ test")
        #expect(!msg.isEmpty)
        #expect(!msg.contains("%@"))
    }

    // MARK: - Session.defaultBlockedApps

    @Test func defaultBlockedAppsHaveNonEmptyIDs() {
        for app in Session.defaultBlockedApps {
            #expect(!app.id.isEmpty)
            #expect(!app.name.isEmpty)
        }
    }

    @Test func defaultBlockedAppBundleIDsMatchDefaultApps() {
        #expect(Session.defaultBlockedAppBundleIDs == Session.defaultBlockedApps.map(\.id))
    }

    @Test func defaultBlockedAppsAreUnique() {
        let ids = Session.defaultBlockedAppBundleIDs
        #expect(ids.count == Set(ids).count)
    }

    // MARK: - Session Codable round-trip with blockedApps

    @Test func sessionRoundTripPreservesBlockedApps() throws {
        let s = Session(task: "write essay", successCriteria: "submitted", blockedApps: ["com.hnc.Discord"])
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(s)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Session.self, from: data)
        #expect(decoded.blockedApps == ["com.hnc.Discord"])
    }

    @Test func sessionDecodesLegacyJsonWithoutBlockedApps() throws {
        // Simulate an old persisted session that has no blockedApps key.
        let legacyJSON = """
        {
          "id": "00000000-0000-0000-0000-000000000001",
          "task": "read chapter 3",
          "successCriteria": "finished notes",
          "startTime": "2025-01-01T00:00:00Z",
          "phase": "active",
          "whitelistedDomains": [],
          "blockedDomains": ["youtube.com"]
        }
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let s = try decoder.decode(Session.self, from: Data(legacyJSON.utf8))
        #expect(s.blockedApps == Session.defaultBlockedAppBundleIDs)
    }
}
