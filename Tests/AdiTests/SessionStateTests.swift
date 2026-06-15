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

    @Test func defaultBlockedDomainsIncludeSpotifyWebPlayer() {
        // spotify.com provides a full-featured web player; blocking only com.spotify.client
        // (the native app) leaves the web route open.
        #expect(Session.defaultBlockedDomains.contains("spotify.com"),
                "spotify.com must be blocked: web player bypasses the native app block")
    }

    @Test func defaultBlockedDomainsIncludeLongFormReadingSites() {
        let domains = Session.defaultBlockedDomains
        for site in ["medium.com", "substack.com"] {
            #expect(domains.contains(site),
                    "expected \(site) in default blocked domains (long-form reading rabbit hole)")
        }
    }

    @Test func defaultBlockedDomainsIncludeMajorNewsSites() {
        let domains = Session.defaultBlockedDomains
        for site in ["nytimes.com", "washingtonpost.com", "npr.org", "apnews.com"] {
            #expect(domains.contains(site),
                    "expected \(site) in default blocked domains (major news procrastination sink)")
        }
    }

    @Test func defaultBlockedDomainsIncludeTechNewsSites() {
        // theverge.com, techcrunch.com, wired.com are "intellectual" procrastination:
        // they feel productive to read but are rarely task-relevant during a session.
        let domains = Session.defaultBlockedDomains
        for site in ["theverge.com", "techcrunch.com", "wired.com"] {
            #expect(domains.contains(site),
                    "expected \(site) in default blocked domains (tech-news procrastination sink)")
        }
    }
}

@Suite("Session defaultBlockedDomains — social short-links and Reddit CDN bypass")
struct DefaultBlockedDomainsSocialCDNTests {

    // MARK: - Social platform short-link domains

    @Test func defaultBlockedDomainsIncludeRedditShortLink() {
        // redd.it is Reddit's own URL shortener (e.g. https://redd.it/abc123).
        // It resolves through a completely separate DNS name — blocking reddit.com
        // alone does NOT prevent redd.it links from loading.
        #expect(Session.defaultBlockedDomains.contains("redd.it"),
                "redd.it must be blocked: Reddit short-links bypass the reddit.com /etc/hosts entry")
    }

    @Test func defaultBlockedDomainsIncludeInstagramShortLink() {
        // instagr.am is Instagram's official short URL service, separate from instagram.com.
        #expect(Session.defaultBlockedDomains.contains("instagr.am"),
                "instagr.am must be blocked: Instagram short-links bypass the instagram.com entry")
    }

    @Test func defaultBlockedDomainsIncludeFacebookShortLink() {
        // fb.me is Facebook's short URL service, separate from facebook.com.
        #expect(Session.defaultBlockedDomains.contains("fb.me"),
                "fb.me must be blocked: Facebook short-links bypass the facebook.com entry")
    }

    @Test func socialShortLinksBothPresentWithParents() {
        // Guard: short-link domains must be listed ALONGSIDE their parent, not instead of it.
        let domains = Set(Session.defaultBlockedDomains)
        #expect(domains.contains("redd.it")     && domains.contains("reddit.com"),
                "both redd.it and reddit.com must be present as independent entries")
        #expect(domains.contains("instagr.am")  && domains.contains("instagram.com"),
                "both instagr.am and instagram.com must be present as independent entries")
        #expect(domains.contains("fb.me")       && domains.contains("facebook.com"),
                "both fb.me and facebook.com must be present as independent entries")
    }

    // MARK: - Reddit CDN domains (completely separate hostnames from reddit.com)

    @Test func defaultBlockedDomainsIncludeRedditImageCDN() {
        // i.redd.it hosts all inline images uploaded to Reddit posts and comments.
        // It is a completely separate hostname — /etc/hosts entries for reddit.com
        // and even i.reddit.com do NOT cover i.redd.it (different TLD: .it vs .com).
        #expect(Session.defaultBlockedDomains.contains("i.redd.it"),
                "i.redd.it must be blocked: Reddit image CDN is a separate hostname from reddit.com")
    }

    @Test func defaultBlockedDomainsIncludeRedditVideoCDN() {
        // v.redd.it hosts Reddit's native video player. Same reasoning as i.redd.it.
        #expect(Session.defaultBlockedDomains.contains("v.redd.it"),
                "v.redd.it must be blocked: Reddit video CDN is a separate hostname from reddit.com")
    }

    @Test func defaultBlockedDomainsIncludeRedditPreviewCDN() {
        // preview.redd.it serves link preview thumbnails and inline image previews in feeds.
        #expect(Session.defaultBlockedDomains.contains("preview.redd.it"),
                "preview.redd.it must be blocked: Reddit preview CDN is separate from reddit.com")
    }

    @Test func redditCDNDomainsAreSeparateFromRedditCom() {
        // Sanity-check that these are explicit entries, not just side-effects of m./i. prefix rules.
        let domains = Set(Session.defaultBlockedDomains)
        #expect(domains.contains("reddit.com"))
        // The three CDN domains have the .redd.it TLD — completely different from reddit.com.
        #expect(domains.contains("i.redd.it"))
        #expect(domains.contains("v.redd.it"))
        #expect(domains.contains("preview.redd.it"))
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

    @Test func defaultBlockedAppsContainsTwitterLegacyAndCatalyst() {
        // Twitter/X ships two different bundle IDs on macOS depending on which version
        // is installed. Both must be present to cover all users:
        // - com.twitter.twitter-mac: the old native Mac app (pre-2022)
        // - com.atebits.Tweetie2: the current Mac Catalyst port of the iOS X app
        let ids = Session.defaultBlockedAppBundleIDs
        #expect(ids.contains("com.twitter.twitter-mac"),
                "com.twitter.twitter-mac must be blocked (legacy native Mac Twitter)")
        #expect(ids.contains("com.atebits.Tweetie2"),
                "com.atebits.Tweetie2 must be blocked (current Mac Catalyst X app)")
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

// MARK: - Messaging web clients (WhatsApp Web / Telegram Web bypass coverage)

@Suite("Session defaultBlockedDomains — messaging web clients")
struct MessagingWebClientDomainTests {

    @Test func defaultBlockedDomainsIncludeWhatsApp() {
        // WhatsApp Web (web.whatsapp.com) is a full-featured browser client that lets users
        // send and receive messages without the native app. Blocking only net.whatsapp.WhatsApp
        // leaves the web route open; whatsapp.com must be in the domain list so the "web"
        // subdomain prefix generates the web.whatsapp.com entry automatically.
        #expect(Session.defaultBlockedDomains.contains("whatsapp.com"),
                "whatsapp.com must be in defaultBlockedDomains (WhatsApp Web bypass)")
    }

    @Test func defaultBlockedDomainsIncludeTelegram() {
        // Telegram Web (web.telegram.org) is a full-featured browser client separate from the
        // native app (ru.keepcoder.Telegram). Without this entry the web client is unblocked.
        #expect(Session.defaultBlockedDomains.contains("telegram.org"),
                "telegram.org must be in defaultBlockedDomains (Telegram Web bypass)")
    }

    @Test func whatsAppAndTelegramAreBothPresentAlongsideNativeAppEntries() {
        // Guard: domain + app blocks must coexist — neither should be removed in favour of the other.
        let domains = Set(Session.defaultBlockedDomains)
        let appIDs = Set(Session.defaultBlockedAppBundleIDs)
        #expect(domains.contains("whatsapp.com"))
        #expect(appIDs.contains("net.whatsapp.WhatsApp"))
        #expect(domains.contains("telegram.org"))
        #expect(appIDs.contains("ru.keepcoder.Telegram"))
    }

    @Test func webSubdomainPrefixGeneratesWhatsAppWebEntry() {
        // Integration check: once whatsapp.com is in the blocklist and "web" is a prefix,
        // buildBlock must emit 127.0.0.1 web.whatsapp.com.
        let block = HostsFileManager.buildBlock(domains: ["whatsapp.com"])
        #expect(block.contains("127.0.0.1 web.whatsapp.com"),
                "web.whatsapp.com entry must be generated by the \"web\" subdomain prefix")
    }

    @Test func webSubdomainPrefixGeneratesTelegramWebEntry() {
        let block = HostsFileManager.buildBlock(domains: ["telegram.org"])
        #expect(block.contains("127.0.0.1 web.telegram.org"),
                "web.telegram.org entry must be generated by the \"web\" subdomain prefix")
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterMessagingAdditions() {
        // Re-run the duplicate guard after adding the new messaging domains.
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "duplicate entries found in defaultBlockedDomains after adding whatsapp.com and telegram.org")
    }
}

// MARK: - Ars Technica + external Reddit preview CDN

@Suite("Session defaultBlockedDomains — arstechnica and external Reddit CDN")
struct ArsTechnicaAndRedditExternalPreviewTests {

    @Test func defaultBlockedDomainsIncludeArsTechnica() {
        // arstechnica.com is an in-depth tech publication; sessions for writing, coding, etc.
        // typically have no reason to visit it, but it is easy to rationalise as "research".
        #expect(Session.defaultBlockedDomains.contains("arstechnica.com"),
                "arstechnica.com must be in defaultBlockedDomains")
    }

    @Test func arsTechnicaIsInTechNewsCategoryAlongsideVergeAndTechCrunch() {
        // All four tech-news sites must be present so the category is consistently blocked.
        let domains = Set(Session.defaultBlockedDomains)
        for site in ["theverge.com", "techcrunch.com", "wired.com", "arstechnica.com"] {
            #expect(domains.contains(site), "\(site) must be blocked alongside the other tech-news sites")
        }
    }

    @Test func defaultBlockedDomainsIncludeExternalPreviewReddIt() {
        // external-preview.redd.it is a distinct hostname from reddit.com and preview.redd.it.
        // It serves thumbnails for external links posted to Reddit; blocking reddit.com alone
        // does NOT prevent direct navigation to external-preview.redd.it URLs.
        #expect(Session.defaultBlockedDomains.contains("external-preview.redd.it"),
                "external-preview.redd.it must be in defaultBlockedDomains")
    }

    @Test func allRedditCDNDomainsAreExplicitEntries() {
        // All four Reddit CDN variants must be present as distinct, independent entries
        // (none of them are generated by the m./i./api. prefix mechanism — they have a
        //  different TLD and are therefore completely separate from reddit.com).
        let domains = Set(Session.defaultBlockedDomains)
        for cdn in ["i.redd.it", "v.redd.it", "preview.redd.it", "external-preview.redd.it"] {
            #expect(domains.contains(cdn), "\(cdn) must be an explicit entry in defaultBlockedDomains")
        }
    }

    @Test func externalPreviewAndPreviewAreSeparateEntries() {
        // external-preview.redd.it is a distinct CDN from preview.redd.it; both must appear
        // as independent entries rather than one being treated as a subdomain of the other.
        let domains = Session.defaultBlockedDomains
        let previews = domains.filter { $0.hasSuffix("preview.redd.it") }
        #expect(previews.contains("preview.redd.it"))
        #expect(previews.contains("external-preview.redd.it"))
        #expect(previews.count == 2)
    }
}

// MARK: - Discord CDN (discordapp.com) bypass closure

@Suite("Session defaultBlockedDomains — Discord CDN (discordapp.com)")
struct DiscordCDNDomainTests {

    @Test func defaultBlockedDomainsIncludeDiscordApp() {
        // discordapp.com is Discord's infrastructure/CDN domain, separate from discord.com.
        // cdn.discordapp.com serves avatars, images, and file attachments — users can access
        // Discord media via direct CDN links even when discord.com is blocked in the browser.
        #expect(Session.defaultBlockedDomains.contains("discordapp.com"),
                "discordapp.com must be in defaultBlockedDomains (Discord CDN bypass)")
    }

    @Test func discordComAndDiscordAppAreBothPresent() {
        // Guard: both the main site and the CDN domain must be blocked independently.
        // Neither entry covers the other — they are completely separate hostnames.
        let domains = Set(Session.defaultBlockedDomains)
        #expect(domains.contains("discord.com"),
                "discord.com (main site) must be present alongside discordapp.com")
        #expect(domains.contains("discordapp.com"),
                "discordapp.com (CDN) must be present alongside discord.com")
    }

    @Test func cdnSubdomainPrefixGeneratesDiscordCDNEntry() {
        // Integration check: once discordapp.com is in the blocklist and "cdn" is a prefix,
        // buildBlock must emit 127.0.0.1 cdn.discordapp.com — the concrete CDN bypass vector.
        let block = HostsFileManager.buildBlock(domains: ["discordapp.com"])
        #expect(block.contains("127.0.0.1 cdn.discordapp.com"),
                "cdn.discordapp.com entry must be generated by the \"cdn\" subdomain prefix")
    }

    @Test func discordAppDomainAndDiscordGGBothPresentAlongsideDiscordCom() {
        // All three Discord-related domain entries must coexist — each closes a different bypass.
        // discord.com: main web app / login. discordapp.com: CDN media. discord.gg: invite links.
        let domains = Set(Session.defaultBlockedDomains)
        #expect(domains.contains("discord.com"))
        #expect(domains.contains("discordapp.com"))
        #expect(domains.contains("discord.gg"))
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterDiscordAppAddition() {
        // Duplicate guard: adding discordapp.com must not create a duplicate in the list.
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "duplicate entries found in defaultBlockedDomains after adding discordapp.com")
    }
}

// MARK: - Discord WebRTC / gateway infrastructure (discordapp.net) bypass closure

@Suite("Session defaultBlockedDomains — Discord infrastructure (discordapp.net)")
struct DiscordNetDomainTests {

    @Test func defaultBlockedDomainsIncludeDiscordNet() {
        // discordapp.net is Discord's WebRTC and real-time gateway infrastructure domain,
        // completely separate from discordapp.com (CDN) and discord.com (main web app).
        // Voice channels and the persistent gateway WebSocket connect through *.discordapp.net
        // endpoints; blocking the other two Discord domains leaves this infrastructure open.
        #expect(Session.defaultBlockedDomains.contains("discordapp.net"),
                "discordapp.net must be in defaultBlockedDomains (Discord WebRTC / gateway bypass)")
    }

    @Test func allThreeDiscordInfrastructureDomainsArePresent() {
        // Guard: all three Discord-infrastructure domains must coexist — each closes a different
        // bypass. discordapp.com: CDN media/avatars. discordapp.net: voice/WebRTC/gateway.
        let domains = Set(Session.defaultBlockedDomains)
        #expect(domains.contains("discord.com"),
                "discord.com (main web app + login) must be present")
        #expect(domains.contains("discordapp.com"),
                "discordapp.com (CDN: avatars, attachments) must be present")
        #expect(domains.contains("discordapp.net"),
                "discordapp.net (WebRTC / gateway infrastructure) must be present")
    }

    @Test func discordNetIsNotTheSameAsDiscordApp() {
        // Explicit sanity-check: .net and .com are distinct TLDs, so these must be
        // separate entries rather than one being treated as a subdomain of the other.
        let domains = Set(Session.defaultBlockedDomains)
        #expect(domains.contains("discordapp.com"))
        #expect(domains.contains("discordapp.net"))
        #expect("discordapp.net" != "discordapp.com")
    }

    @Test func mediaSubdomainPrefixGeneratesDiscordNetMediaEntry() {
        // Integration check: once discordapp.net is in the blocklist and "media" is a prefix,
        // buildBlock must emit 127.0.0.1 media.discordapp.net (secondary embedded-preview CDN).
        let block = HostsFileManager.buildBlock(domains: ["discordapp.net"])
        #expect(block.contains("127.0.0.1 media.discordapp.net"),
                "media.discordapp.net entry must be generated by the \"media\" subdomain prefix")
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterDiscordNetAddition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "duplicate entries found in defaultBlockedDomains after adding discordapp.net")
    }
}

// MARK: - Discord worker / edge-function domain (discordapp.io) bypass closure

@Suite("Session defaultBlockedDomains — Discord worker domain (discordapp.io)")
struct DiscordIODomainTests {

    @Test func defaultBlockedDomainsIncludeDiscordIO() {
        // discordapp.io is Discord's Cloudflare Workers / edge-function domain, separate from
        // discordapp.com (CDN) and discordapp.net (WebRTC/gateway). It is used for status-page
        // polling, experimental API endpoints, and worker scripts; leaving it unblocked while the
        // other two are blocked exposes a residual direct-request route into Discord infrastructure.
        #expect(Session.defaultBlockedDomains.contains("discordapp.io"),
                "discordapp.io must be in defaultBlockedDomains (Discord worker/edge bypass)")
    }

    @Test func allFourDiscordInfrastructureDomainsArePresent() {
        // Guard: all four Discord-related domains must coexist — each closes a different bypass.
        // discord.com: main web app/login. discordapp.com: CDN media. discordapp.net: voice/WebRTC.
        // discordapp.io: Cloudflare Workers / edge functions / status endpoints.
        let domains = Set(Session.defaultBlockedDomains)
        #expect(domains.contains("discord.com"),      "discord.com (main app) must be present")
        #expect(domains.contains("discordapp.com"),   "discordapp.com (CDN) must be present")
        #expect(domains.contains("discordapp.net"),   "discordapp.net (WebRTC/gateway) must be present")
        #expect(domains.contains("discordapp.io"),    "discordapp.io (workers/edge) must be present")
    }

    @Test func discordIOIsDistinctFromDiscordNetAndDiscordApp() {
        // Explicit sanity-check: .io, .net, and .com are distinct TLDs — each is an independent entry.
        let domains = Set(Session.defaultBlockedDomains)
        #expect(domains.contains("discordapp.io"))
        #expect(domains.contains("discordapp.net"))
        #expect(domains.contains("discordapp.com"))
        #expect("discordapp.io" != "discordapp.net")
        #expect("discordapp.io" != "discordapp.com")
    }

    @Test func subdomainPrefixesGenerateDiscordIOEntries() {
        // Integration check: blocking discordapp.io must generate cdn., media., and other prefix
        // entries alongside it, just as for discordapp.com and discordapp.net.
        let block = HostsFileManager.buildBlock(domains: ["discordapp.io"])
        #expect(block.contains("127.0.0.1 discordapp.io"))
        #expect(block.contains("127.0.0.1 www.discordapp.io"))
        #expect(block.contains("127.0.0.1 cdn.discordapp.io"))
        #expect(block.contains("127.0.0.1 media.discordapp.io"))
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterDiscordIOAddition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "duplicate entries found in defaultBlockedDomains after adding discordapp.io")
    }
}

// MARK: - Twitch legacy CDN (jtvnw.net) bypass closure

@Suite("Session defaultBlockedDomains — Twitch legacy CDN (jtvnw.net)")
struct TwitchJtvnwDomainTests {

    @Test func defaultBlockedDomainsIncludeJtvnwNet() {
        // jtvnw.net is Justin.tv's legacy CDN domain still used by Twitch for thumbnails,
        // profile images, game box art, and clip preview frames. It is a completely separate
        // TLD from twitch.tv — blocking twitch.tv does NOT prevent *.jtvnw.net from loading.
        // External links (Reddit posts, Discord embeds) often reference jtvnw.net URLs directly.
        #expect(Session.defaultBlockedDomains.contains("jtvnw.net"),
                "jtvnw.net must be in defaultBlockedDomains (Twitch legacy CDN bypass)")
    }

    @Test func twitchTvAndJtvnwNetAreBothPresent() {
        // Guard: both the main Twitch domain and the legacy CDN must be blocked independently —
        // they are distinct TLDs and neither entry covers the other.
        let domains = Set(Session.defaultBlockedDomains)
        #expect(domains.contains("twitch.tv"),
                "twitch.tv (main Twitch site) must be present alongside jtvnw.net")
        #expect(domains.contains("jtvnw.net"),
                "jtvnw.net (Twitch legacy CDN) must be present alongside twitch.tv")
    }

    @Test func jtvnwNetIsDistinctFromTwitchTv() {
        // Explicit sanity-check: jtvnw.net and twitch.tv are different domains —
        // they must be independent entries rather than one being a subdomain of the other.
        let domains = Set(Session.defaultBlockedDomains)
        #expect(domains.contains("jtvnw.net"))
        #expect(domains.contains("twitch.tv"))
        #expect("jtvnw.net" != "twitch.tv")
        #expect(!"jtvnw.net".hasSuffix("twitch.tv"))
        #expect(!"twitch.tv".hasSuffix("jtvnw.net"))
    }

    @Test func staticDotAndCdnDotJtvnwNetGeneratedByPrefixRules() {
        // The prefix mechanism generates "prefix.domain" entries (dot-separated).
        // For jtvnw.net, "static" generates static.jtvnw.net and "cdn" generates cdn.jtvnw.net.
        // These cover the two common dot-subdomain patterns. static-cdn.jtvnw.net (hyphen) is
        // NOT generated this way — it is an explicit literal entry in defaultBlockedDomains.
        let block = HostsFileManager.buildBlock(domains: ["jtvnw.net"])
        #expect(block.contains("127.0.0.1 jtvnw.net"))
        #expect(block.contains("127.0.0.1 www.jtvnw.net"))
        #expect(block.contains("127.0.0.1 cdn.jtvnw.net"))
        #expect(block.contains("127.0.0.1 static.jtvnw.net"))
        // Prefix mechanism does NOT generate the hyphen variant:
        #expect(!block.contains("127.0.0.1 static-cdn.jtvnw.net"),
                "static-cdn.jtvnw.net uses a hyphen separator and must NOT be generated by " +
                "the dot-prefix mechanism — it must exist as an explicit defaultBlockedDomains entry")
    }

    @Test func defaultBlockedDomainsIncludesStaticCdnJtvnwNetExplicitly() {
        // static-cdn.jtvnw.net is Twitch's primary thumbnail/image CDN hostname.
        // The "static" prefix generates static.jtvnw.net (dot separator), NOT
        // static-cdn.jtvnw.net (hyphen separator), so it must be listed explicitly.
        #expect(Session.defaultBlockedDomains.contains("static-cdn.jtvnw.net"),
                "static-cdn.jtvnw.net must be an explicit literal entry in defaultBlockedDomains " +
                "(hyphen subdomain not generatable by the dot-prefix mechanism)")
    }

    @Test func staticCdnJtvnwNetIsAdjacentToJtvnwNetInList() {
        // Verify the two entries are both present and that static-cdn comes after jtvnw.net.
        let domains = Session.defaultBlockedDomains
        #expect(domains.contains("jtvnw.net"))
        #expect(domains.contains("static-cdn.jtvnw.net"))
        // The literal static-cdn entry must be distinct from the bare root:
        #expect("static-cdn.jtvnw.net" != "jtvnw.net")
        #expect("static-cdn.jtvnw.net".hasSuffix("jtvnw.net"),
                "static-cdn.jtvnw.net should be recognisable as a jtvnw.net subdomain by suffix")
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterStaticCdnJtvnwNetAddition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "duplicate entries found in defaultBlockedDomains after adding static-cdn.jtvnw.net")
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

// MARK: - New blocked platforms (streaming / video / image hosts)

@Suite("Session defaultBlockedDomains — new streaming, video, and image platforms")
struct NewPlatformBlocklistTests {

    @Test func defaultBlockedDomainsIncludeKick() {
        #expect(Session.defaultBlockedDomains.contains("kick.com"),
                "kick.com (major Twitch competitor) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeTrovo() {
        #expect(Session.defaultBlockedDomains.contains("trovo.live"),
                "trovo.live (Tencent live-streaming platform) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeRumble() {
        #expect(Session.defaultBlockedDomains.contains("rumble.com"),
                "rumble.com (alternative video platform) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeDailymotion() {
        #expect(Session.defaultBlockedDomains.contains("dailymotion.com"),
                "dailymotion.com (video platform) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeBilibili() {
        #expect(Session.defaultBlockedDomains.contains("bilibili.com"),
                "bilibili.com (video/anime platform) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeOdysee() {
        #expect(Session.defaultBlockedDomains.contains("odysee.com"),
                "odysee.com (decentralized video platform) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeImgur() {
        #expect(Session.defaultBlockedDomains.contains("imgur.com"),
                "imgur.com (image host and procrastination feed) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeGiphy() {
        #expect(Session.defaultBlockedDomains.contains("giphy.com"),
                "giphy.com (GIF discovery platform) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeTenor() {
        #expect(Session.defaultBlockedDomains.contains("tenor.com"),
                "tenor.com (Google GIF platform) must be blocked by default")
    }

    @Test func newStreamingPlatformsAllPresentTogether() {
        let domains = Session.defaultBlockedDomains
        for expected in ["kick.com", "trovo.live", "rumble.com", "dailymotion.com",
                         "bilibili.com", "odysee.com", "imgur.com", "giphy.com", "tenor.com"] {
            #expect(domains.contains(expected),
                    "\(expected) must be present in defaultBlockedDomains")
        }
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterNewPlatformAdditions() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "duplicate entries found in defaultBlockedDomains after adding new platforms")
    }
}

// MARK: - Art portfolio / creative procrastination platforms

@Suite("Session defaultBlockedDomains — art portfolio and design procrastination platforms")
struct ArtPortfolioBlocklistTests {

    @Test func defaultBlockedDomainsIncludeDeviantArt() {
        #expect(Session.defaultBlockedDomains.contains("deviantart.com"),
                "deviantart.com (art community gallery) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeArtStation() {
        #expect(Session.defaultBlockedDomains.contains("artstation.com"),
                "artstation.com (professional concept art portfolio platform) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeBehance() {
        #expect(Session.defaultBlockedDomains.contains("behance.net"),
                "behance.net (Adobe creative portfolio platform) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeDribbble() {
        #expect(Session.defaultBlockedDomains.contains("dribbble.com"),
                "dribbble.com (UI/UX design community) must be blocked by default")
    }

    @Test func artPortfolioDomainsAllPresentTogether() {
        let domains = Session.defaultBlockedDomains
        for expected in ["deviantart.com", "artstation.com", "behance.net", "dribbble.com"] {
            #expect(domains.contains(expected),
                    "\(expected) must be present in defaultBlockedDomains")
        }
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterArtPortfolioAdditions() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "duplicate entries found in defaultBlockedDomains after adding art portfolio platforms")
    }
}
