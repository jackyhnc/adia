import Testing
import Foundation
@testable import AdiCore

@Suite("Session model")
struct SessionModelTests {

    @Test func defaultPhaseIsIdle() {
        let s = Session(task: "Write essay", successCriteria: "Submit to Canvas")
        #expect(s.phase == .idle)
    }

    @Test func defaultBlockedDomainsPopulated() {
        #expect(!Session.defaultBlockedDomains.isEmpty)
    }

    @Test func defaultBlockedDomainsIncludeCoreDistractors() {
        let domains = Session.defaultBlockedDomains
        for expected in ["twitter.com", "reddit.com", "youtube.com", "instagram.com",
                         "tiktok.com", "facebook.com", "netflix.com", "linkedin.com",
                         "amazon.com"] {
            #expect(domains.contains(expected), "expected \(expected) in default blocked domains")
        }
    }

    @Test func whitelistedDomainsEmpty() {
        let s = Session(task: "t", successCriteria: "c")
        #expect(s.whitelistedDomains.isEmpty)
    }

    @Test func elapsedNonNegative() {
        let s = Session(task: "t", successCriteria: "c")
        #expect(s.elapsed >= 0)
    }

    @Test func elapsedReflectsStartTime() {
        let startTime = Date(timeIntervalSinceNow: -60)
        let s = Session(task: "t", successCriteria: "c", startTime: startTime)
        // Allow ±2s of test-execution jitter around the expected 60s
        #expect(s.elapsed >= 58 && s.elapsed <= 62)
    }

    @Test func codableRoundTrip() throws {
        let original = Session(
            task: "Write essay",
            successCriteria: "Submit",
            phase: .active,
            whitelistedDomains: ["example.com"]
        )
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Session.self, from: data)
        #expect(decoded.id == original.id)
        #expect(decoded.task == original.task)
        #expect(decoded.phase == original.phase)
        #expect(decoded.whitelistedDomains == original.whitelistedDomains)
    }
}

@Suite("Session duration goal")
struct SessionDurationTests {

    @Test func targetDurationDefaultsToNil() {
        let s = Session(task: "t", successCriteria: "c")
        #expect(s.targetDuration == nil)
    }

    @Test func targetDurationStoredInInit() {
        let s = Session(task: "t", successCriteria: "c", targetDuration: 5400)
        #expect(s.targetDuration == 5400)
    }

    @Test func targetDurationPreservedInCodableRoundTrip() throws {
        let s = Session(task: "t", successCriteria: "c", targetDuration: 5400)
        let data = try JSONEncoder().encode(s)
        let decoded = try JSONDecoder().decode(Session.self, from: data)
        #expect(decoded.targetDuration == 5400)
    }

    @Test func nilTargetDurationPreservedInCodableRoundTrip() throws {
        let s = Session(task: "t", successCriteria: "c", targetDuration: nil)
        let data = try JSONEncoder().encode(s)
        let decoded = try JSONDecoder().decode(Session.self, from: data)
        #expect(decoded.targetDuration == nil)
    }

    @Test func legacySessionWithoutTargetDurationDecodesAsNil() throws {
        let s = Session(task: "old task", successCriteria: "c", phase: .active, targetDuration: 3600)
        let encoded = try JSONEncoder().encode(s)
        var dict = try #require((try JSONSerialization.jsonObject(with: encoded)) as? [String: Any])
        dict.removeValue(forKey: "targetDuration")
        let stripped = try JSONSerialization.data(withJSONObject: dict)
        let decoded = try JSONDecoder().decode(Session.self, from: stripped)
        #expect(decoded.targetDuration == nil)
    }

    @Test func targetDurationNotEncodedWhenNil() throws {
        let s = Session(task: "t", successCriteria: "c", targetDuration: nil)
        let data = try JSONEncoder().encode(s)
        let dict = try #require((try JSONSerialization.jsonObject(with: data)) as? [String: Any])
        #expect(dict["targetDuration"] == nil)
    }

    // MARK: - reasoningHistory

    @Test func reasoningHistoryDefaultsToEmpty() {
        let s = Session(task: "t", successCriteria: "c")
        #expect(s.reasoningHistory.isEmpty)
    }

    @Test func reasoningHistoryPreservedInCodableRoundTrip() throws {
        let attempt = ReasoningAttempt(domain: "youtube.com", granted: false, summary: "no academic reason given")
        let s = Session(task: "t", successCriteria: "c", reasoningHistory: [attempt])
        let data = try JSONEncoder().encode(s)
        let decoded = try JSONDecoder().decode(Session.self, from: data)
        #expect(decoded.reasoningHistory.count == 1)
        #expect(decoded.reasoningHistory[0].domain == "youtube.com")
        #expect(decoded.reasoningHistory[0].granted == false)
        #expect(decoded.reasoningHistory[0].summary == "no academic reason given")
    }

    @Test func legacySessionWithoutReasoningHistoryDecodesAsEmpty() throws {
        let s = Session(task: "old task", successCriteria: "c", phase: .active)
        let encoded = try JSONEncoder().encode(s)
        var dict = try #require((try JSONSerialization.jsonObject(with: encoded)) as? [String: Any])
        dict.removeValue(forKey: "reasoningHistory")
        let stripped = try JSONSerialization.data(withJSONObject: dict)
        let decoded = try JSONDecoder().decode(Session.self, from: stripped)
        #expect(decoded.reasoningHistory.isEmpty)
    }
}

@Suite("Session — focus score persistence")
struct SessionFocusCheckTests {

    @Test func onTaskChecksDefaultsToZero() {
        let s = Session(task: "t", successCriteria: "c")
        #expect(s.onTaskChecks == 0)
    }

    @Test func totalChecksDefaultsToZero() {
        let s = Session(task: "t", successCriteria: "c")
        #expect(s.totalChecks == 0)
    }

    @Test func checkCountsPreservedInCodableRoundTrip() throws {
        let s = Session(task: "Essay", successCriteria: "Submit", onTaskChecks: 42, totalChecks: 50)
        let data = try JSONEncoder().encode(s)
        let decoded = try JSONDecoder().decode(Session.self, from: data)
        #expect(decoded.onTaskChecks == 42)
        #expect(decoded.totalChecks == 50)
    }

    @Test func legacySessionWithoutCheckCountsDecodesAsZero() throws {
        let s = Session(task: "old task", successCriteria: "c", phase: .active)
        let encoded = try JSONEncoder().encode(s)
        var dict = try #require((try JSONSerialization.jsonObject(with: encoded)) as? [String: Any])
        dict.removeValue(forKey: "onTaskChecks")
        dict.removeValue(forKey: "totalChecks")
        let stripped = try JSONSerialization.data(withJSONObject: dict)
        let decoded = try JSONDecoder().decode(Session.self, from: stripped)
        #expect(decoded.onTaskChecks == 0)
        #expect(decoded.totalChecks == 0)
    }

    @Test func partialLegacySessionWithOnlyOnTaskChecksDecodesGracefully() throws {
        let s = Session(task: "t", successCriteria: "c", onTaskChecks: 10, totalChecks: 15)
        let encoded = try JSONEncoder().encode(s)
        var dict = try #require((try JSONSerialization.jsonObject(with: encoded)) as? [String: Any])
        dict.removeValue(forKey: "totalChecks")
        let stripped = try JSONSerialization.data(withJSONObject: dict)
        let decoded = try JSONDecoder().decode(Session.self, from: stripped)
        #expect(decoded.onTaskChecks == 10)
        #expect(decoded.totalChecks == 0)
    }

    @Test func checkCountsAreIndependentlyMutable() {
        var s = Session(task: "t", successCriteria: "c")
        s.onTaskChecks = 7
        s.totalChecks = 10
        #expect(s.onTaskChecks == 7)
        #expect(s.totalChecks == 10)
    }
}

@Suite("ChatMessage")
struct ChatMessageTests {

    @Test func roleRoundTrip() throws {
        let msg = ChatMessage(role: .assistant, content: "yo, focus up")
        let data = try JSONEncoder().encode(msg)
        let decoded = try JSONDecoder().decode(ChatMessage.self, from: data)
        #expect(decoded.role == ChatMessage.Role.assistant)
        #expect(decoded.content == msg.content)
    }
}

@Suite("VerificationResult")
struct VerificationResultTests {

    @Test func verifiedResultEncodesCorrectly() throws {
        let r = VerificationResult(verified: true, explanation: "Canvas shows submitted.")
        let data = try JSONEncoder().encode(r)
        let decoded = try JSONDecoder().decode(VerificationResult.self, from: data)
        #expect(decoded.verified)
        #expect(decoded.explanation == r.explanation)
    }
}

@Suite("SessionRecord — blockedDomains")
struct SessionRecordBlockedDomainsTests {

    @Test func blockedDomainsDefaultsToEmpty() {
        let now = Date()
        let record = SessionRecord(
            task: "Write essay", successCriteria: "Submit",
            startTime: now, endTime: now.addingTimeInterval(3600),
            completedSuccessfully: true, calloutCount: 0
        )
        #expect(record.blockedDomains.isEmpty)
    }

    @Test func blockedDomainsStoredInInit() {
        let now = Date()
        let domains = ["reddit.com", "youtube.com"]
        let record = SessionRecord(
            task: "Write essay", successCriteria: "Submit",
            startTime: now, endTime: now.addingTimeInterval(3600),
            completedSuccessfully: true, calloutCount: 0,
            blockedDomains: domains
        )
        #expect(record.blockedDomains == domains)
    }

    @Test func blockedDomainsPreservedInCodableRoundTrip() throws {
        let now = Date()
        let domains = ["twitter.com", "facebook.com", "tiktok.com"]
        let record = SessionRecord(
            task: "Study", successCriteria: "Done",
            startTime: now, endTime: now.addingTimeInterval(7200),
            completedSuccessfully: false, calloutCount: 3,
            blockedDomains: domains
        )
        let data = try JSONEncoder().encode(record)
        let decoded = try JSONDecoder().decode(SessionRecord.self, from: data)
        #expect(decoded.blockedDomains == domains)
    }

    @Test func legacyRecordWithoutBlockedDomainsDecodesAsEmpty() throws {
        let now = Date()
        let record = SessionRecord(
            task: "Old session", successCriteria: "Done",
            startTime: now, endTime: now.addingTimeInterval(1800),
            completedSuccessfully: true, calloutCount: 1,
            blockedDomains: ["youtube.com"]
        )
        let encoded = try JSONEncoder().encode(record)
        var dict = try #require((try JSONSerialization.jsonObject(with: encoded)) as? [String: Any])
        dict.removeValue(forKey: "blockedDomains")
        let stripped = try JSONSerialization.data(withJSONObject: dict)
        let decoded = try JSONDecoder().decode(SessionRecord.self, from: stripped)
        #expect(decoded.blockedDomains.isEmpty)
    }
}

@Suite("Session defaultBlockedDomains — sports & news")
struct DefaultBlockedDomainsCoverageTests {

    @Test func defaultBlockedDomainsIncludeSportsSites() {
        let domains = Session.defaultBlockedDomains
        for site in ["espn.com", "nba.com", "nfl.com", "bleacherreport.com", "cbssports.com"] {
            #expect(domains.contains(site), "expected \(site) in default blocked domains")
        }
    }

    @Test func defaultBlockedDomainsIncludeNewsAndClickbait() {
        let domains = Session.defaultBlockedDomains
        for site in ["buzzfeed.com", "huffpost.com", "msn.com"] {
            #expect(domains.contains(site), "expected \(site) in default blocked domains")
        }
    }

    @Test func defaultBlockedDomainsIncludeShoppingSites() {
        let domains = Session.defaultBlockedDomains
        for site in ["amazon.com", "ebay.com", "etsy.com", "aliexpress.com", "walmart.com"] {
            #expect(domains.contains(site), "expected \(site) in default blocked domains")
        }
    }

    @Test func defaultBlockedDomainsIncludeTimeSinks() {
        let domains = Session.defaultBlockedDomains
        for site in ["quora.com", "fandom.com"] {
            #expect(domains.contains(site), "expected \(site) in default blocked domains")
        }
    }

    @Test func defaultBlockedDomainsNoDuplicates() {
        let domains = Session.defaultBlockedDomains
        let unique = Set(domains)
        #expect(unique.count == domains.count, "duplicate entries in defaultBlockedDomains")
    }

    @Test func defaultBlockedDomainsCountExceedsTwenty() {
        #expect(Session.defaultBlockedDomains.count > 20, "expected a broad blocklist")
    }

    @Test func defaultBlockedDomainsIncludeNewsSites() {
        let domains = Session.defaultBlockedDomains
        for site in ["cnn.com", "foxnews.com", "bbc.com", "theguardian.com"] {
            #expect(domains.contains(site), "expected \(site) in default blocked domains")
        }
    }

    @Test func defaultBlockedDomainsIncludeGamingPlatforms() {
        let domains = Session.defaultBlockedDomains
        for site in ["steampowered.com", "epicgames.com"] {
            #expect(domains.contains(site), "expected \(site) in default blocked domains")
        }
    }

    @Test func defaultBlockedDomainsIncludeAdditionalStreamingServices() {
        let domains = Session.defaultBlockedDomains
        for site in ["max.com", "crunchyroll.com", "peacocktv.com"] {
            #expect(domains.contains(site), "expected \(site) in default blocked domains")
        }
    }

    @Test func defaultBlockedDomainsIncludeMusicStreamingSites() {
        let domains = Session.defaultBlockedDomains
        for site in ["soundcloud.com", "bandcamp.com"] {
            #expect(domains.contains(site), "expected \(site) in default blocked domains (passive-listening distraction)")
        }
    }
}

@Suite("Session defaultBlockedDomains — bypass & student time sinks")
struct DefaultBlockedDomainsBypassTests {

    @Test func defaultBlockedDomainsIncludeYouTubeBypassDomain() {
        // youtu.be is a separate domain — youtube.com block does NOT cover it.
        #expect(Session.defaultBlockedDomains.contains("youtu.be"),
                "youtu.be must be blocked: YouTube short-links bypass the youtube.com /etc/hosts entry")
    }

    @Test func defaultBlockedDomainsIncludeDiscordGG() {
        // discord.gg hosts invite links and is a completely separate domain from discord.com.
        #expect(Session.defaultBlockedDomains.contains("discord.gg"),
                "discord.gg must be blocked: Discord invite links bypass the discord.com entry")
    }

    @Test func defaultBlockedDomainsIncludeTwitterLinkShortener() {
        // t.co is Twitter's link shortener — follows users out of the twitter.com block.
        #expect(Session.defaultBlockedDomains.contains("t.co"),
                "t.co must be blocked: Twitter short-links bypass the twitter.com entry")
    }

    @Test func defaultBlockedDomainsIncludeGamingTimeSinks() {
        let domains = Session.defaultBlockedDomains
        for site in ["chess.com", "lichess.org"] {
            #expect(domains.contains(site),
                    "expected \(site) in default blocked domains (addictive game for students/workers)")
        }
    }

    @Test func defaultBlockedDomainsIncludeStudentReadingTimeSinks() {
        let domains = Session.defaultBlockedDomains
        for site in ["webtoons.com", "wattpad.com", "archiveofourown.org", "mangadex.org"] {
            #expect(domains.contains(site),
                    "expected \(site) in default blocked domains (high-consumption reading procrastination)")
        }
    }

    @Test func defaultBlockedDomainsIncludeProductHunt() {
        #expect(Session.defaultBlockedDomains.contains("producthunt.com"),
                "producthunt.com must be blocked: professional procrastination disguised as research")
    }

    @Test func bypassDomainsAreSeparateFromParentDomains() {
        // Guard: the short-link domains must not also have their parent in the list
        // at a subdomain level — they are genuinely independent entries.
        let domains = Set(Session.defaultBlockedDomains)
        #expect(domains.contains("youtu.be") && domains.contains("youtube.com"),
                "both youtu.be and youtube.com must be present as independent entries")
        #expect(domains.contains("discord.gg") && domains.contains("discord.com"),
                "both discord.gg and discord.com must be present as independent entries")
    }
}

@Suite("Session defaultBlockedApps")
struct DefaultBlockedAppsTests {

    @Test func defaultBlockedAppsContainsCoreDistractors() {
        let ids = Session.defaultBlockedAppBundleIDs
        for bundleID in ["com.hnc.Discord", "com.valvesoftware.steam", "com.apple.TV"] {
            #expect(ids.contains(bundleID), "expected \(bundleID) in defaultBlockedAppBundleIDs")
        }
    }

    @Test func defaultBlockedAppsContainsSpotify() {
        #expect(Session.defaultBlockedAppBundleIDs.contains("com.spotify.client"),
                "Spotify must be blocked by default")
    }

    @Test func defaultBlockedAppsContainsWeChat() {
        #expect(Session.defaultBlockedAppBundleIDs.contains("com.tencent.xinWeChat"),
                "WeChat must be blocked by default")
    }

    @Test func defaultBlockedAppsContainsAppleMusic() {
        #expect(Session.defaultBlockedAppBundleIDs.contains("com.apple.Music"),
                "Apple Music must be blocked by default (passive-listening distraction)")
    }

    @Test func defaultBlockedAppsContainsPodcasts() {
        #expect(Session.defaultBlockedAppBundleIDs.contains("com.apple.podcasts"),
                "Podcasts must be blocked by default (passive-listening distraction)")
    }

    @Test func defaultBlockedAppsNoDuplicates() {
        let ids = Session.defaultBlockedAppBundleIDs
        let unique = Set(ids)
        #expect(unique.count == ids.count, "duplicate bundle IDs in defaultBlockedApps")
    }

    @Test func defaultBlockedAppsHaveNonEmptyNames() {
        #expect(Session.defaultBlockedApps.allSatisfy { !$0.name.isEmpty },
                "every BlockedApp must have a non-empty display name")
    }

    @Test func defaultBlockedAppsHaveNonEmptyIDs() {
        #expect(Session.defaultBlockedApps.allSatisfy { !$0.id.isEmpty },
                "every BlockedApp must have a non-empty bundle identifier")
    }
}

// MARK: - streakDisplayLabel (settings weekly-section consistency)

/// These tests verify that the shared `streakDisplayLabel` function — now used by
/// both the notch stats line and the SettingsView History weekly section — produces
/// the correct output for the key edge cases that the old `> 1` guard used to hide.
@Suite("SettingsView streak display (streakDisplayLabel)")
struct SettingsViewStreakDisplayTests {

    @Test func oneDayStreakIsNotEmpty() {
        // Before the fix, streak == 1 was hidden. After fix, it must produce a label.
        let label = streakDisplayLabel(current: 1, best: 1)
        #expect(!label.isEmpty)
        #expect(label.contains("1d streak"))
    }

    @Test func zeroDayStreakProducesLabel() {
        // Caller gates on streak > 0 so this never renders, but the function
        // itself should not crash or return garbage.
        let label = streakDisplayLabel(current: 0, best: 0)
        #expect(label.contains("0d streak"))
    }

    @Test func streakBelowBestIncludesBestAnnotation() {
        // SettingsView now shows the best-streak annotation just like the notch.
        let label = streakDisplayLabel(current: 3, best: 7)
        #expect(label == "🔥 3d streak (best: 7d)")
    }

    @Test func streakAtBestOmitsBestAnnotation() {
        let label = streakDisplayLabel(current: 5, best: 5)
        #expect(label == "🔥 5d streak")
        #expect(!label.contains("best:"))
    }
}
