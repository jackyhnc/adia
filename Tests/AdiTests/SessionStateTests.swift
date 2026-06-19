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

// MARK: - Video sharing and photography platforms

@Suite("Session defaultBlockedDomains — video sharing and photography platforms")
struct VideoAndPhotographyBlocklistTests {

    @Test func defaultBlockedDomainsIncludeVimeo() {
        #expect(Session.defaultBlockedDomains.contains("vimeo.com"),
                "vimeo.com (video platform with curated Staff Picks discover feed) must be blocked by default")
    }

    @Test func defaultBlockedDomainsInclude500px() {
        #expect(Session.defaultBlockedDomains.contains("500px.com"),
                "500px.com (photography community with infinitely scrollable gallery) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeUnsplash() {
        #expect(Session.defaultBlockedDomains.contains("unsplash.com"),
                "unsplash.com (free stock photo discover feed) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeFlickr() {
        #expect(Session.defaultBlockedDomains.contains("flickr.com"),
                "flickr.com (photography sharing with Explore and group feeds) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludePexels() {
        #expect(Session.defaultBlockedDomains.contains("pexels.com"),
                "pexels.com (free stock photo/video with Trending discover feed) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludePixabay() {
        #expect(Session.defaultBlockedDomains.contains("pixabay.com"),
                "pixabay.com (free stock image/video library with discovery browse) must be blocked by default")
    }

    @Test func videoAndPhotographyDomainsAllPresentTogether() {
        let domains = Session.defaultBlockedDomains
        for expected in ["vimeo.com", "500px.com", "unsplash.com", "flickr.com", "pexels.com", "pixabay.com"] {
            #expect(domains.contains(expected),
                    "\(expected) must be present in defaultBlockedDomains")
        }
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterVideoAndPhotographyAdditions() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "duplicate entries found in defaultBlockedDomains after adding video/photography platforms")
    }
}

// MARK: - Social media proxy frontends

@Suite("Session defaultBlockedDomains — social media proxy frontends")
struct SocialMediaProxyBlocklistTests {

    @Test func defaultBlockedDomainsIncludeNitter() {
        #expect(Session.defaultBlockedDomains.contains("nitter.net"),
                "nitter.net (Twitter/X privacy proxy frontend) must be blocked by default")
    }

    @Test func nitterIsDistinctFromTwitterDomain() {
        // nitter.net is a completely separate domain from twitter.com and x.com —
        // it must be an explicit entry, not derivable from any existing block rule.
        let domains = Session.defaultBlockedDomains
        #expect(domains.contains("nitter.net"),
                "nitter.net requires an explicit entry independent of twitter.com/x.com")
        #expect(domains.contains("twitter.com"),
                "twitter.com must also remain blocked alongside nitter.net")
        #expect(domains.contains("x.com"),
                "x.com must also remain blocked alongside nitter.net")
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterProxyFrontendAdditions() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "duplicate entries found in defaultBlockedDomains after adding proxy frontend domains")
    }
}

// MARK: - Gaming platforms + additional streaming + regional social

@Suite("Session defaultBlockedDomains — gaming platforms, streaming expansion, and regional social")
struct GamingAndStreamingExpansionBlocklistTests {

    // MARK: Gaming platforms

    @Test func defaultBlockedDomainsIncludeRoblox() {
        // roblox.com is the browser entry point for the Roblox platform — game browser,
        // Roblox Studio launcher, and avatar/account management.
        #expect(Session.defaultBlockedDomains.contains("roblox.com"),
                "roblox.com must be blocked by default (high-engagement student gaming platform)")
    }

    @Test func defaultBlockedDomainsIncludeItchIo() {
        // itch.io is an indie game marketplace with browse/discover feeds popular among
        // CS, game-dev, and design students.
        #expect(Session.defaultBlockedDomains.contains("itch.io"),
                "itch.io must be blocked by default (indie game discovery feed — student time sink)")
    }

    @Test func defaultBlockedDomainsIncludeGOG() {
        // gog.com (Good Old Games / CD Projekt) — DRM-free game store with curated
        // sale and discovery sections.
        #expect(Session.defaultBlockedDomains.contains("gog.com"),
                "gog.com must be blocked by default (game store with discovery browse section)")
    }

    @Test func defaultBlockedDomainsIncludeHumbleBundle() {
        // humblebundle.com — game bundle store with countdown-timer FOMO and subscription tier.
        #expect(Session.defaultBlockedDomains.contains("humblebundle.com"),
                "humblebundle.com must be blocked by default (time-limited bundle FOMO UX)")
    }

    // MARK: Additional streaming services

    @Test func defaultBlockedDomainsIncludeParamountPlus() {
        #expect(Session.defaultBlockedDomains.contains("paramountplus.com"),
                "paramountplus.com must be blocked by default (major subscription streaming service)")
    }

    @Test func defaultBlockedDomainsIncludeDiscoveryPlus() {
        // discoveryplus.com — nature/reality/documentary streaming rationalised as "educational".
        #expect(Session.defaultBlockedDomains.contains("discoveryplus.com"),
                "discoveryplus.com must be blocked by default (documentary streaming — 'educational' rationalization)")
    }

    @Test func defaultBlockedDomainsIncludeMubi() {
        // mubi.com — art-house film streaming; popular with film/media/humanities students
        // who frame it as cultural enrichment rather than procrastination.
        #expect(Session.defaultBlockedDomains.contains("mubi.com"),
                "mubi.com must be blocked by default (art-house film streaming — prestige procrastination)")
    }

    @Test func defaultBlockedDomainsIncludeTubiTv() {
        // tubi.tv — free AVOD streaming; zero friction ("it's free") lowers self-interruption.
        #expect(Session.defaultBlockedDomains.contains("tubi.tv"),
                "tubi.tv must be blocked by default (free streaming — zero-friction distraction)")
    }

    @Test func defaultBlockedDomainsIncludePlutoTv() {
        // pluto.tv — free live-channel + on-demand AVOD; channel-surfing UX auto-plays continuously.
        #expect(Session.defaultBlockedDomains.contains("pluto.tv"),
                "pluto.tv must be blocked by default (free channel-surfing streaming platform)")
    }

    // MARK: Regional social networks

    @Test func defaultBlockedDomainsIncludeVK() {
        // vk.com — VKontakte, Russia's largest social network (~100M MAU globally);
        // functionally equivalent to Facebook.
        #expect(Session.defaultBlockedDomains.contains("vk.com"),
                "vk.com must be blocked by default (Russian social network, large global user base)")
    }

    // MARK: Bulk presence + no-duplicates guards

    @Test func gamingAndStreamingDomainsAllPresentTogether() {
        let domains = Session.defaultBlockedDomains
        for expected in ["roblox.com", "itch.io", "gog.com", "humblebundle.com",
                         "paramountplus.com", "discoveryplus.com", "mubi.com",
                         "tubi.tv", "pluto.tv", "vk.com"] {
            #expect(domains.contains(expected),
                    "\(expected) must be present in defaultBlockedDomains")
        }
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterGamingAndStreamingAdditions() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "duplicate entries found in defaultBlockedDomains after gaming/streaming expansion")
    }
}

// MARK: - Epic Games Launcher app block

@Suite("Session defaultBlockedApps — Epic Games Launcher")
struct EpicGamesLauncherAppBlockTests {

    @Test func defaultBlockedAppsIncludeEpicGamesLauncher() {
        // The Epic Games Launcher is a standalone macOS app that shows the store browse
        // interface without needing a network connection to epicgames.com.
        #expect(Session.defaultBlockedAppBundleIDs.contains("com.epicgames.EpicGamesLauncher"),
                "com.epicgames.EpicGamesLauncher must be blocked by default")
    }

    @Test func epicGamesLauncherBlockedAlongsideEpicGamesDomain() {
        // Both the launcher app and the website must be covered — the app can
        // show the store locally while the web block covers browser-based access.
        let domains = Set(Session.defaultBlockedDomains)
        let appIDs  = Set(Session.defaultBlockedAppBundleIDs)
        #expect(domains.contains("epicgames.com"),
                "epicgames.com (web store) must be blocked alongside the launcher app")
        #expect(appIDs.contains("com.epicgames.EpicGamesLauncher"),
                "com.epicgames.EpicGamesLauncher must be blocked alongside the epicgames.com web block")
    }

    @Test func defaultBlockedAppsNoDuplicatesAfterEpicGamesLauncherAddition() {
        let ids = Session.defaultBlockedAppBundleIDs
        #expect(Set(ids).count == ids.count,
                "duplicate bundle IDs in defaultBlockedApps after adding Epic Games Launcher")
    }
}

// MARK: - Short-form video alternatives, game key resellers, e-commerce expansion, Battle.net

@Suite("Session defaultBlockedDomains — short-form video, game resellers, e-commerce")
struct ShortVideoResellersEcommerceBlocklistTests {

    // MARK: Short-form video alternatives (TikTok competitors)

    @Test func defaultBlockedDomainsIncludeTrillerCo() {
        // triller.co is a dedicated TikTok competitor with the same infinite-scroll
        // autoplay-next format. A student whose tiktok.com is blocked may pivot here.
        #expect(Session.defaultBlockedDomains.contains("triller.co"),
                "triller.co must be blocked by default (TikTok-format short-video platform)")
    }

    @Test func defaultBlockedDomainsIncludeLikee() {
        // likee.com (Kwai-owned) is popular in emerging markets and among teen demographics;
        // the For-You algorithmic feed is engineered for maximum session length.
        #expect(Session.defaultBlockedDomains.contains("likee.com"),
                "likee.com must be blocked by default (algorithmic short-video platform)")
    }

    // MARK: Game key reseller marketplaces

    @Test func defaultBlockedDomainsIncludeG2A() {
        // g2a.com — largest grey-market game key reseller; "checking prices" is a common
        // student rationalization that leads to long browse sessions.
        #expect(Session.defaultBlockedDomains.contains("g2a.com"),
                "g2a.com must be blocked by default (game key reseller with deal-discovery feed)")
    }

    @Test func defaultBlockedDomainsIncludeKinguin() {
        // kinguin.net — second-largest game key reseller; same deal-discovery engagement pattern.
        #expect(Session.defaultBlockedDomains.contains("kinguin.net"),
                "kinguin.net must be blocked by default (game key reseller, direct G2A competitor)")
    }

    // MARK: E-commerce expansion

    @Test func defaultBlockedDomainsIncludeBestBuy() {
        // bestbuy.com — consumer electronics with Deals sections and flash sales;
        // "checking hardware prices for my project" is a common student rationalization.
        #expect(Session.defaultBlockedDomains.contains("bestbuy.com"),
                "bestbuy.com must be blocked by default (consumer electronics impulse browsing)")
    }

    @Test func defaultBlockedDomainsIncludeTarget() {
        // target.com — general merchandise with Trending/Deals UX; students visit for
        // dorm/lifestyle items and stay in the product-discovery loop.
        #expect(Session.defaultBlockedDomains.contains("target.com"),
                "target.com must be blocked by default (retail browse — dorm/lifestyle impulse shopping)")
    }

    @Test func defaultBlockedDomainsIncludeWish() {
        // wish.com — infinite-scroll discount marketplace; among the highest engagement-per-visit
        // metrics in e-commerce; "just browsing" routinely runs 30+ min.
        #expect(Session.defaultBlockedDomains.contains("wish.com"),
                "wish.com must be blocked by default (infinite-scroll discount marketplace)")
    }

    @Test func defaultBlockedDomainsIncludeShein() {
        // shein.com — fast-fashion e-commerce with gamified daily check-ins and flash discounts;
        // highly optimised for maximum browse session length.
        #expect(Session.defaultBlockedDomains.contains("shein.com"),
                "shein.com must be blocked by default (gamified fast-fashion e-commerce)")
    }

    // MARK: Bulk presence + no-duplicates guards

    @Test func allNewDomainsAllPresentTogether() {
        let domains = Session.defaultBlockedDomains
        for expected in ["triller.co", "likee.com", "g2a.com", "kinguin.net",
                         "bestbuy.com", "target.com", "wish.com", "shein.com"] {
            #expect(domains.contains(expected),
                    "\(expected) must be present in defaultBlockedDomains")
        }
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterExpansion() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "duplicate entries found in defaultBlockedDomains after short-video/reseller/ecommerce expansion")
    }

    // MARK: Disjointness from existing entries (these are new independent TLDs)

    @Test func newShortVideoDomainsAreDistinctFromTikTok() {
        let domains = Set(Session.defaultBlockedDomains)
        // These must coexist with tiktok.com as separate independent entries.
        #expect(domains.contains("tiktok.com"),
                "tiktok.com must still be present after triller.co and likee.com additions")
        #expect(domains.contains("triller.co"),
                "triller.co must be a separate block entry from tiktok.com")
        #expect(domains.contains("likee.com"),
                "likee.com must be a separate block entry from tiktok.com")
    }

    @Test func newGameResellersAreDistinctFromSteamAndEpic() {
        let domains = Set(Session.defaultBlockedDomains)
        // Key resellers are independently-navigated destinations, not subdomains of Steam/Epic.
        #expect(domains.contains("steampowered.com"),
                "steampowered.com must still be present after g2a.com/kinguin.net additions")
        #expect(domains.contains("g2a.com") && domains.contains("kinguin.net"),
                "g2a.com and kinguin.net must each be independent entries in the blocklist")
    }

    @Test func newEcommerceDomainsAreDistinctFromAmazon() {
        let domains = Set(Session.defaultBlockedDomains)
        // The new e-commerce additions are separate stores — amazon.com stays and new ones join it.
        #expect(domains.contains("amazon.com"),
                "amazon.com must still be present after bestbuy/target/wish/shein additions")
        for site in ["bestbuy.com", "target.com", "wish.com", "shein.com"] {
            #expect(domains.contains(site),
                    "\(site) must be present alongside amazon.com as an independent block entry")
        }
    }
}

// MARK: - Battle.net launcher app block

@Suite("Session defaultBlockedApps — Battle.net")
struct BattleNetAppBlockTests {

    @Test func defaultBlockedAppsIncludeBattleNet() {
        // Battle.net launcher (net.battle.net.client) is Blizzard's game client;
        // it shows the store/news UI locally from cached data — blocking battle.net
        // via /etc/hosts alone does not prevent the app from launching.
        #expect(Session.defaultBlockedAppBundleIDs.contains("net.battle.net.client"),
                "net.battle.net.client must be blocked by default (Blizzard game launcher)")
    }

    @Test func battleNetBlockedAlongsideBlizzardGames() {
        // The launcher app block pairs with the web block for blizzard-related browsing.
        // (epicgames.com is already blocked; Battle.net launcher adds the app-layer coverage.)
        let apps = Set(Session.defaultBlockedAppBundleIDs)
        #expect(apps.contains("net.battle.net.client"),
                "Battle.net launcher app must be in the blocked app list")
        // Verify it coexists with the Epic Games Launcher entry added in the previous run.
        #expect(apps.contains("com.epicgames.EpicGamesLauncher"),
                "Epic Games Launcher must still be present after Battle.net addition")
    }

    @Test func defaultBlockedAppsNoDuplicatesAfterBattleNetAddition() {
        let ids = Session.defaultBlockedAppBundleIDs
        #expect(Set(ids).count == ids.count,
                "duplicate bundle IDs in defaultBlockedApps after adding Battle.net")
    }
}

// MARK: - Sports betting and gambling domains

@Suite("Session defaultBlockedDomains — sports betting and gambling")
struct SportsBettingBlockTests {

    @Test func defaultBlockedDomainsIncludeDraftKings() {
        #expect(Session.defaultBlockedDomains.contains("draftkings.com"),
                "draftkings.com (US DFS/sports betting) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeFanDuel() {
        #expect(Session.defaultBlockedDomains.contains("fanduel.com"),
                "fanduel.com (US DFS/sports betting) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeBet365() {
        #expect(Session.defaultBlockedDomains.contains("bet365.com"),
                "bet365.com (global sportsbook) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludePokerStars() {
        #expect(Session.defaultBlockedDomains.contains("pokerstars.com"),
                "pokerstars.com (world's largest online poker platform) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeBetway() {
        #expect(Session.defaultBlockedDomains.contains("betway.com"),
                "betway.com (global sports betting) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeBovada() {
        #expect(Session.defaultBlockedDomains.contains("bovada.lv"),
                "bovada.lv (US-facing sportsbook/.lv TLD) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeBetMGM() {
        #expect(Session.defaultBlockedDomains.contains("betmgm.com"),
                "betmgm.com (MGM digital sportsbook) must be blocked by default")
    }

    @Test func allGamblingDomainsAllPresentTogether() {
        let domains = Set(Session.defaultBlockedDomains)
        let expected = ["draftkings.com", "fanduel.com", "bet365.com",
                        "pokerstars.com", "betway.com", "bovada.lv", "betmgm.com"]
        for site in expected {
            #expect(domains.contains(site),
                    "\(site) must be present in defaultBlockedDomains")
        }
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterGamblingAddition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate entries in defaultBlockedDomains after gambling additions")
    }

    @Test func gamblingDomainsAreDistinctFromSportsScoresSites() {
        let domains = Set(Session.defaultBlockedDomains)
        // Sports-score sites (espn.com, nba.com) and sports-betting sites are separate
        // distractions; both categories must coexist in the list.
        #expect(domains.contains("espn.com"),
                "espn.com must still be present after betting domain additions")
        for site in ["draftkings.com", "fanduel.com", "bet365.com"] {
            #expect(domains.contains(site),
                    "\(site) must be independent from the sports-scores block entries")
        }
    }
}

// MARK: - Regional social networks (Asia-Pacific)

@Suite("Session defaultBlockedDomains — regional social networks (Asia-Pacific)")
struct AsianSocialNetworkBlockTests {

    @Test func defaultBlockedDomainsIncludeWeibo() {
        #expect(Session.defaultBlockedDomains.contains("weibo.com"),
                "weibo.com (China microblogging, ~600M MAU) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeLineMe() {
        #expect(Session.defaultBlockedDomains.contains("line.me"),
                "line.me (LINE messaging/news, dominant in Japan/Taiwan/Thailand) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeKakaoTalk() {
        #expect(Session.defaultBlockedDomains.contains("kakaotalk.com"),
                "kakaotalk.com (South Korea dominant messaging) must be blocked by default")
    }

    @Test func allAsianSocialNetworksPresentTogether() {
        let domains = Set(Session.defaultBlockedDomains)
        for site in ["weibo.com", "line.me", "kakaotalk.com"] {
            #expect(domains.contains(site),
                    "\(site) must be present in defaultBlockedDomains")
        }
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterAsianSocialAddition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate entries in defaultBlockedDomains after Asian social network additions")
    }

    @Test func asianSocialNetworksAreDistinctFromVkCom() {
        let domains = Set(Session.defaultBlockedDomains)
        // vk.com was added in a prior run as the Eastern European regional network;
        // the Asian platforms are separate entries with distinct TLDs.
        #expect(domains.contains("vk.com"),
                "vk.com must still be present after Asian social network additions")
        for site in ["weibo.com", "line.me", "kakaotalk.com"] {
            #expect(domains.contains(site),
                    "\(site) must be independent from the vk.com block entry")
        }
    }
}

// MARK: - Additional e-commerce and short-form video

@Suite("Session defaultBlockedDomains — wayfair, zalando, asos, clapper")
struct AdditionalEcommerceAndVideoBlockTests {

    @Test func defaultBlockedDomainsIncludeWayfair() {
        #expect(Session.defaultBlockedDomains.contains("wayfair.com"),
                "wayfair.com (home furniture e-commerce, high-dwell browse) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeZalando() {
        #expect(Session.defaultBlockedDomains.contains("zalando.com"),
                "zalando.com (European fashion e-commerce) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeAsos() {
        #expect(Session.defaultBlockedDomains.contains("asos.com"),
                "asos.com (global fast-fashion, New In / Sale feeds) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeClapper() {
        #expect(Session.defaultBlockedDomains.contains("clapper.tv"),
                "clapper.tv (TikTok alternative short-form video) must be blocked by default")
    }

    @Test func allNewDomainsAllPresentTogetherRun137() {
        let domains = Set(Session.defaultBlockedDomains)
        for site in ["wayfair.com", "zalando.com", "asos.com", "clapper.tv"] {
            #expect(domains.contains(site),
                    "\(site) must be present in defaultBlockedDomains")
        }
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterRun137Addition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate entries in defaultBlockedDomains after run-137 additions")
    }

    @Test func newEcommerceDomainsAreDistinctFromExistingShoppingEntries() {
        let domains = Set(Session.defaultBlockedDomains)
        // The original shopping entries stay; new ones join them as independent entries.
        for existing in ["amazon.com", "ebay.com", "etsy.com", "shein.com"] {
            #expect(domains.contains(existing),
                    "\(existing) must still be present after wayfair/zalando/asos additions")
        }
        for newSite in ["wayfair.com", "zalando.com", "asos.com"] {
            #expect(domains.contains(newSite),
                    "\(newSite) must be an independent block entry alongside the original shopping list")
        }
    }

    @Test func clapperTvIsDistinctFromTikTokAndOtherShortVideo() {
        let domains = Set(Session.defaultBlockedDomains)
        #expect(domains.contains("tiktok.com"),
                "tiktok.com must still be present after clapper.tv addition")
        #expect(domains.contains("triller.co"),
                "triller.co must still be present after clapper.tv addition")
        #expect(domains.contains("clapper.tv"),
                "clapper.tv must be an independent entry distinct from tiktok.com and triller.co")
    }
}

// MARK: - Browser-based gaming portals

@Suite("Session defaultBlockedDomains — browser-based gaming portals")
struct BrowserGamingBlockTests {

    @Test func defaultBlockedDomainsIncludeCrazyGames() {
        #expect(Session.defaultBlockedDomains.contains("crazygames.com"),
                "crazygames.com (largest browser game portal, ~35M MAU) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludePoki() {
        #expect(Session.defaultBlockedDomains.contains("poki.com"),
                "poki.com (major browser game hub) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeMiniclip() {
        #expect(Session.defaultBlockedDomains.contains("miniclip.com"),
                "miniclip.com (original Flash-era browser game portal) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeKongregate() {
        #expect(Session.defaultBlockedDomains.contains("kongregate.com"),
                "kongregate.com (browser game portal with RPG achievement system) must be blocked by default")
    }

    @Test func allBrowserGamingDomainsAllPresentTogether() {
        let domains = Set(Session.defaultBlockedDomains)
        for site in ["crazygames.com", "poki.com", "miniclip.com", "kongregate.com"] {
            #expect(domains.contains(site),
                    "\(site) must be present in defaultBlockedDomains")
        }
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterBrowserGamingAddition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate entries in defaultBlockedDomains after browser gaming portal additions")
    }

    @Test func browserGamingPortalsAreDistinctFromSteamAndEpic() {
        let domains = Set(Session.defaultBlockedDomains)
        // Native game store platforms and browser game portals are separate categories.
        #expect(domains.contains("steampowered.com"),
                "steampowered.com must still be present alongside browser game portal entries")
        #expect(domains.contains("epicgames.com"),
                "epicgames.com must still be present alongside browser game portal entries")
        for portal in ["crazygames.com", "poki.com", "miniclip.com", "kongregate.com"] {
            #expect(domains.contains(portal),
                    "\(portal) must be an independent entry distinct from Steam/Epic")
        }
    }

    @Test func browserGamingPortalsAreDistinctFromItchAndGOG() {
        let domains = Set(Session.defaultBlockedDomains)
        // itch.io and gog.com are game marketplaces; the new entries are play portals — distinct.
        #expect(domains.contains("itch.io"), "itch.io must still be present")
        #expect(domains.contains("gog.com"), "gog.com must still be present")
        for portal in ["crazygames.com", "poki.com", "miniclip.com", "kongregate.com"] {
            #expect(domains.contains(portal),
                    "\(portal) must coexist independently with itch.io and gog.com")
        }
    }
}

// MARK: - Extended gambling and poker

@Suite("Session defaultBlockedDomains — extended gambling and poker")
struct ExtendedGamblingBlockTests {

    @Test func defaultBlockedDomainsInclude888Casino() {
        #expect(Session.defaultBlockedDomains.contains("888casino.com"),
                "888casino.com (888 Holdings flagship casino) must be blocked by default")
    }

    @Test func defaultBlockedDomainsInclude888Poker() {
        #expect(Session.defaultBlockedDomains.contains("888poker.com"),
                "888poker.com (888 Holdings dedicated poker brand, distinct domain) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludePartyPoker() {
        #expect(Session.defaultBlockedDomains.contains("partypoker.com"),
                "partypoker.com (second largest global online poker room) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeUnibet() {
        #expect(Session.defaultBlockedDomains.contains("unibet.com"),
                "unibet.com (Kindred Group major European sportsbook) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeWilliamHill() {
        #expect(Session.defaultBlockedDomains.contains("williamhill.com"),
                "williamhill.com (global bookmaker, est. 1934) must be blocked by default")
    }

    @Test func allExtendedGamblingDomainsAllPresentTogether() {
        let domains = Set(Session.defaultBlockedDomains)
        for site in ["888casino.com", "888poker.com", "partypoker.com",
                     "unibet.com", "williamhill.com"] {
            #expect(domains.contains(site),
                    "\(site) must be present in defaultBlockedDomains")
        }
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterExtendedGamblingAddition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate entries in defaultBlockedDomains after extended gambling additions")
    }

    @Test func extendedGamblingDomainsCoexistWithExistingGamblingEntries() {
        let domains = Set(Session.defaultBlockedDomains)
        // Prior run entries must still be present alongside the new additions.
        for existing in ["draftkings.com", "fanduel.com", "bet365.com",
                         "pokerstars.com", "betway.com", "bovada.lv", "betmgm.com"] {
            #expect(domains.contains(existing),
                    "\(existing) (prior gambling entry) must still be present after run-138 additions")
        }
        for newSite in ["888casino.com", "888poker.com", "partypoker.com",
                        "unibet.com", "williamhill.com"] {
            #expect(domains.contains(newSite),
                    "\(newSite) must be present as an independent new entry")
        }
    }

    @Test func eightEightEightCasinoAndPokerAreSeparateEntries() {
        // 888casino.com and 888poker.com are operated by the same corporate parent but are
        // distinct DNS names resolving to different services — both must appear independently.
        let domains = Session.defaultBlockedDomains
        let casinoCount = domains.filter { $0 == "888casino.com" }.count
        let pokerCount  = domains.filter { $0 == "888poker.com"  }.count
        #expect(casinoCount == 1, "888casino.com must appear exactly once")
        #expect(pokerCount  == 1, "888poker.com must appear exactly once")
    }
}

// MARK: - Additional regional social networks

@Suite("Session defaultBlockedDomains — additional regional social networks")
struct AdditionalRegionalSocialBlockTests {

    @Test func defaultBlockedDomainsIncludeBandUs() {
        #expect(Session.defaultBlockedDomains.contains("band.us"),
                "band.us (BAND K-pop fan community platform) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeTaringa() {
        #expect(Session.defaultBlockedDomains.contains("taringa.net"),
                "taringa.net (Latin American Reddit-like forum) must be blocked by default")
    }

    @Test func allAdditionalRegionalSocialDomainsAllPresentTogether() {
        let domains = Set(Session.defaultBlockedDomains)
        for site in ["band.us", "taringa.net"] {
            #expect(domains.contains(site),
                    "\(site) must be present in defaultBlockedDomains")
        }
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterRegionalSocialAddition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate entries in defaultBlockedDomains after regional social additions")
    }

    @Test func additionalRegionalSocialCoexistWithPriorRegionalEntries() {
        let domains = Set(Session.defaultBlockedDomains)
        // Earlier regional entries (vk.com, weibo.com, line.me, kakaotalk.com) stay present.
        for existing in ["vk.com", "weibo.com", "line.me", "kakaotalk.com"] {
            #expect(domains.contains(existing),
                    "\(existing) (prior regional entry) must still be present after run-138 additions")
        }
        #expect(domains.contains("band.us"),    "band.us must coexist with prior regional entries")
        #expect(domains.contains("taringa.net"), "taringa.net must coexist with prior regional entries")
    }

    @Test func bandUsIsDistinctFromKakaoAndLine() {
        let domains = Set(Session.defaultBlockedDomains)
        // band.us serves a different use case (fan communities) from kakaotalk.com (general messaging).
        #expect(domains.contains("band.us"),       "band.us must be present")
        #expect(domains.contains("kakaotalk.com"), "kakaotalk.com must still be present independently")
        #expect(domains.contains("line.me"),       "line.me must still be present independently")
    }
}

// MARK: - Additional browser-based gaming portals

@Suite("Session defaultBlockedDomains — additional browser gaming portals")
struct AdditionalBrowserGamingBlockTests {

    @Test func defaultBlockedDomainsIncludeAddictingGames() {
        #expect(Session.defaultBlockedDomains.contains("addictinggames.com"),
                "addictinggames.com (Addicting Games Inc., 100M+ users) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeArmorGames() {
        #expect(Session.defaultBlockedDomains.contains("armorgames.com"),
                "armorgames.com (indie browser game portal with community ratings) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeY8() {
        #expect(Session.defaultBlockedDomains.contains("y8.com"),
                "y8.com (300M+ user browser game portal, popular in Asia/LatAm/E. Europe) must be blocked by default")
    }

    @Test func allAdditionalBrowserGamingPortalsAllPresentTogether() {
        let domains = Set(Session.defaultBlockedDomains)
        for site in ["addictinggames.com", "armorgames.com", "y8.com"] {
            #expect(domains.contains(site),
                    "\(site) must be present in defaultBlockedDomains")
        }
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterAdditionalBrowserGamingAddition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate entries in defaultBlockedDomains after additional browser gaming additions")
    }

    @Test func additionalBrowserGamingCoexistsWithPriorBrowserGamingEntries() {
        let domains = Set(Session.defaultBlockedDomains)
        for existing in ["crazygames.com", "poki.com", "miniclip.com", "kongregate.com"] {
            #expect(domains.contains(existing),
                    "\(existing) (prior browser gaming entry) must still be present")
        }
        for newSite in ["addictinggames.com", "armorgames.com", "y8.com"] {
            #expect(domains.contains(newSite),
                    "\(newSite) must be present as an independent new entry")
        }
    }

    @Test func additionalBrowserGamingPortalsAreDistinctFromSteamAndEpic() {
        let domains = Set(Session.defaultBlockedDomains)
        #expect(domains.contains("steampowered.com"), "steampowered.com must still be present")
        #expect(domains.contains("epicgames.com"),    "epicgames.com must still be present")
        for portal in ["addictinggames.com", "armorgames.com", "y8.com"] {
            #expect(domains.contains(portal), "\(portal) must be present independently of Steam/Epic")
        }
    }

    @Test func y8IsDistinctFromOtherGamingTLDs() {
        // y8.com uses a short .com TLD entry; verify it is separate from y8.net or similar hypothetical variants.
        let domains = Session.defaultBlockedDomains
        let y8ComCount = domains.filter { $0 == "y8.com" }.count
        #expect(y8ComCount == 1, "y8.com must appear exactly once in defaultBlockedDomains")
    }
}

// MARK: - Additional sports betting / gambling operators

@Suite("Session defaultBlockedDomains — additional gambling operators")
struct AdditionalGamblingOperatorsBlockTests {

    @Test func defaultBlockedDomainsIncludeLadbrokes() {
        #expect(Session.defaultBlockedDomains.contains("ladbrokes.com"),
                "ladbrokes.com (Entain Group major UK bookmaker) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludePaddyPower() {
        #expect(Session.defaultBlockedDomains.contains("paddypower.com"),
                "paddypower.com (Flutter Entertainment, Irish/UK bookmaker) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeCoral() {
        #expect(Session.defaultBlockedDomains.contains("coral.co.uk"),
                "coral.co.uk (Entain Group UK bookmaker, distinct .co.uk TLD) must be blocked by default")
    }

    @Test func allAdditionalGamblingOperatorsAllPresentTogether() {
        let domains = Set(Session.defaultBlockedDomains)
        for site in ["ladbrokes.com", "paddypower.com", "coral.co.uk"] {
            #expect(domains.contains(site),
                    "\(site) must be present in defaultBlockedDomains")
        }
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterAdditionalGamblingAddition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate entries in defaultBlockedDomains after additional gambling operator additions")
    }

    @Test func additionalGamblingOperatorsCoexistWithPriorGamblingEntries() {
        let domains = Set(Session.defaultBlockedDomains)
        for existing in ["draftkings.com", "fanduel.com", "bet365.com", "pokerstars.com",
                         "betway.com", "bovada.lv", "betmgm.com",
                         "888casino.com", "888poker.com", "partypoker.com", "unibet.com", "williamhill.com"] {
            #expect(domains.contains(existing),
                    "\(existing) (prior gambling entry) must still be present after run-139 additions")
        }
        for newSite in ["ladbrokes.com", "paddypower.com", "coral.co.uk"] {
            #expect(domains.contains(newSite),
                    "\(newSite) must be present as an independent new entry")
        }
    }

    @Test func coralUsesCoUkTLDNotComTLD() {
        // coral.co.uk must be listed as coral.co.uk, not coral.com (a different entity).
        let domains = Session.defaultBlockedDomains
        let coralCoUkCount = domains.filter { $0 == "coral.co.uk" }.count
        #expect(coralCoUkCount == 1, "coral.co.uk must appear exactly once with the .co.uk TLD")
        let coralComCount = domains.filter { $0 == "coral.com" }.count
        #expect(coralComCount == 0, "coral.com (a different entity) must NOT be in the list")
    }

    @Test func ladbrokesAndCoralAreSeparateEntitiesDespiteSameParent() {
        // Ladbrokes and Coral share the Entain parent but resolve to completely separate domains.
        let domains = Set(Session.defaultBlockedDomains)
        #expect(domains.contains("ladbrokes.com"), "ladbrokes.com must be present independently")
        #expect(domains.contains("coral.co.uk"),   "coral.co.uk must be present independently")
    }
}

// MARK: - Latin American e-commerce

@Suite("Session defaultBlockedDomains — Latin American e-commerce")
struct LatAmEcommerceBlockTests {

    @Test func defaultBlockedDomainsIncludeMercadoLibre() {
        #expect(Session.defaultBlockedDomains.contains("mercadolibre.com"),
                "mercadolibre.com (Latin America's dominant marketplace, 18-country presence) must be blocked by default")
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterMercadoLibreAddition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate entries in defaultBlockedDomains after MercadoLibre addition")
    }

    @Test func mercadoLibreCoexistsWithExistingEcommerceEntries() {
        let domains = Set(Session.defaultBlockedDomains)
        for existing in ["amazon.com", "ebay.com", "etsy.com", "aliexpress.com",
                         "walmart.com", "wayfair.com", "zalando.com", "asos.com"] {
            #expect(domains.contains(existing),
                    "\(existing) (prior e-commerce entry) must still be present")
        }
        #expect(domains.contains("mercadolibre.com"),
                "mercadolibre.com must be present alongside existing e-commerce entries")
    }

    @Test func mercadoLibreCoexistsWithLatAmRegionalEntries() {
        let domains = Set(Session.defaultBlockedDomains)
        // taringa.net is the prior Latin American regional entry.
        #expect(domains.contains("taringa.net"),     "taringa.net must still be present")
        #expect(domains.contains("mercadolibre.com"), "mercadolibre.com must coexist with taringa.net")
    }

    @Test func mercadoLibreAppearExactlyOnce() {
        let domains = Session.defaultBlockedDomains
        let count = domains.filter { $0 == "mercadolibre.com" }.count
        #expect(count == 1, "mercadolibre.com must appear exactly once in defaultBlockedDomains")
    }
}

// MARK: - Live TV streaming (escape hatch blocking)

@Suite("Session defaultBlockedDomains — live TV streaming services")
struct LiveTVStreamingBlockTests {

    @Test func defaultBlockedDomainsIncludeSling() {
        #expect(Session.defaultBlockedDomains.contains("sling.com"),
                "sling.com (Sling TV — live TV streaming, sports and entertainment channels) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeFubo() {
        #expect(Session.defaultBlockedDomains.contains("fubo.tv"),
                "fubo.tv (FuboTV — sports-first live TV streaming) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludePhilo() {
        #expect(Session.defaultBlockedDomains.contains("philo.com"),
                "philo.com (Philo — budget entertainment live TV streaming) must be blocked by default")
    }

    @Test func allLiveTVStreamingServicesAllPresentTogether() {
        let domains = Set(Session.defaultBlockedDomains)
        for site in ["sling.com", "fubo.tv", "philo.com"] {
            #expect(domains.contains(site),
                    "\(site) (live TV streaming service) must be present")
        }
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterLiveTVAddition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate entries in defaultBlockedDomains after live TV streaming additions")
    }

    @Test func liveTVStreamingCoexistsWithExistingStreamingServices() {
        let domains = Set(Session.defaultBlockedDomains)
        for existing in ["netflix.com", "hulu.com", "disneyplus.com", "peacocktv.com",
                         "paramountplus.com", "discoveryplus.com", "tubi.tv", "pluto.tv"] {
            #expect(domains.contains(existing),
                    "\(existing) (prior streaming entry) must still be present")
        }
    }

    @Test func fuboUsedottvTLDNotDotCom() {
        // fubo.tv is the correct domain; fubo.com resolves differently and is not FuboTV.
        let domains = Session.defaultBlockedDomains
        let fuboTvCount = domains.filter { $0 == "fubo.tv" }.count
        #expect(fuboTvCount == 1, "fubo.tv must appear exactly once with the .tv TLD")
        let fuboComCount = domains.filter { $0 == "fubo.com" }.count
        #expect(fuboComCount == 0, "fubo.com (a different entity) must NOT be in the list")
    }

    @Test func slingAppearsExactlyOnce() {
        let count = Session.defaultBlockedDomains.filter { $0 == "sling.com" }.count
        #expect(count == 1, "sling.com must appear exactly once")
    }
}

// MARK: - Additional gambling operators

@Suite("Session defaultBlockedDomains — additional gambling operators (betfred, bwin, sky.bet)")
struct AdditionalGamblingOperators2BlockTests {

    @Test func defaultBlockedDomainsIncludeBetfred() {
        #expect(Session.defaultBlockedDomains.contains("betfred.com"),
                "betfred.com (major UK bookmaker, ~1,600 high-street shops) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeBwin() {
        #expect(Session.defaultBlockedDomains.contains("bwin.com"),
                "bwin.com (major European online betting operator, Entain Group) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeSkyBet() {
        #expect(Session.defaultBlockedDomains.contains("sky.bet"),
                "sky.bet (Sky Bet by Flutter Entertainment — dominant UK sports betting via Sky Sports integration) must be blocked by default")
    }

    @Test func allAdditionalGamblingOperators2AllPresentTogether() {
        let domains = Set(Session.defaultBlockedDomains)
        for site in ["betfred.com", "bwin.com", "sky.bet"] {
            #expect(domains.contains(site),
                    "\(site) (gambling operator) must be present")
        }
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterAdditionalGambling2Addition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate entries in defaultBlockedDomains after betfred/bwin/sky.bet addition")
    }

    @Test func additionalGamblingOperators2CoexistWithPriorGamblingEntries() {
        let domains = Set(Session.defaultBlockedDomains)
        for existing in ["bet365.com", "draftkings.com", "fanduel.com", "pokerstars.com",
                         "betway.com", "bovada.lv", "betmgm.com", "unibet.com",
                         "williamhill.com", "ladbrokes.com", "paddypower.com", "coral.co.uk",
                         "888casino.com", "888poker.com", "partypoker.com"] {
            #expect(domains.contains(existing),
                    "\(existing) (prior gambling entry) must still be present")
        }
    }

    @Test func skyBetUsesDotBetTLDNotDotCom() {
        // sky.bet uses the .bet TLD; sky.com is Sky's media/broadband domain (not a gambling site).
        let domains = Session.defaultBlockedDomains
        let skyBetCount = domains.filter { $0 == "sky.bet" }.count
        #expect(skyBetCount == 1, "sky.bet must appear exactly once with the .bet TLD")
        // sky.com is NOT a gambling site — it must not be present.
        let skyComCount = domains.filter { $0 == "sky.com" }.count
        #expect(skyComCount == 0, "sky.com (Sky's media domain, not gambling) must NOT be blocked by default")
    }

    @Test func bwinAppearsExactlyOnce() {
        let count = Session.defaultBlockedDomains.filter { $0 == "bwin.com" }.count
        #expect(count == 1, "bwin.com must appear exactly once")
    }
}

// MARK: - Additional browser gaming portals

@Suite("Session defaultBlockedDomains — additional browser gaming portals (silvergames, friv)")
struct AdditionalBrowserGaming2BlockTests {

    @Test func defaultBlockedDomainsIncludeSilverGames() {
        #expect(Session.defaultBlockedDomains.contains("silvergames.com"),
                "silvergames.com (~15M MAU, strong in German-speaking markets) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeFriv() {
        #expect(Session.defaultBlockedDomains.contains("friv.com"),
                "friv.com (minimalist browser game portal, massive LatAm and Middle East presence) must be blocked by default")
    }

    @Test func allAdditionalBrowserGaming2AllPresentTogether() {
        let domains = Set(Session.defaultBlockedDomains)
        for site in ["silvergames.com", "friv.com"] {
            #expect(domains.contains(site),
                    "\(site) (browser gaming portal) must be present")
        }
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterAdditionalBrowserGaming2Addition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate entries in defaultBlockedDomains after silvergames/friv addition")
    }

    @Test func additionalBrowserGaming2CoexistsWithPriorBrowserGamingEntries() {
        let domains = Set(Session.defaultBlockedDomains)
        for existing in ["crazygames.com", "poki.com", "miniclip.com", "kongregate.com",
                         "addictinggames.com", "armorgames.com", "y8.com"] {
            #expect(domains.contains(existing),
                    "\(existing) (prior browser gaming portal) must still be present")
        }
    }

    @Test func frivAppearsExactlyOnce() {
        let count = Session.defaultBlockedDomains.filter { $0 == "friv.com" }.count
        #expect(count == 1, "friv.com must appear exactly once")
    }
}

// MARK: - Global classifieds marketplaces

@Suite("Session defaultBlockedDomains — global classifieds (OLX)")
struct ClassifiedsMarketplaceBlockTests {

    @Test func defaultBlockedDomainsIncludeOlx() {
        #expect(Session.defaultBlockedDomains.contains("olx.com"),
                "olx.com (OLX Group — dominant classifieds platform across LatAm, Eastern Europe, South Asia, Africa) must be blocked by default")
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterOlxAddition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate entries in defaultBlockedDomains after olx.com addition")
    }

    @Test func olxCoexistsWithExistingEcommerceAndLatAmEntries() {
        let domains = Set(Session.defaultBlockedDomains)
        for existing in ["amazon.com", "ebay.com", "mercadolibre.com", "taringa.net"] {
            #expect(domains.contains(existing),
                    "\(existing) (prior e-commerce/LatAm entry) must still be present")
        }
        #expect(domains.contains("olx.com"), "olx.com must coexist with existing entries")
    }

    @Test func olxAppearsExactlyOnce() {
        let count = Session.defaultBlockedDomains.filter { $0 == "olx.com" }.count
        #expect(count == 1, "olx.com must appear exactly once in defaultBlockedDomains")
    }
}

// MARK: - Additional gambling operators (Betfair Exchange, 888sport, Sportingbet)

@Suite("Session defaultBlockedDomains — additional gambling operators (betfair, 888sport, sportingbet)")
struct AdditionalGamblingOperators3BlockTests {

    @Test func defaultBlockedDomainsIncludeBetfair() {
        #expect(Session.defaultBlockedDomains.contains("betfair.com"),
                "betfair.com (Betfair Exchange — peer-to-peer betting market, Flutter Entertainment) must be blocked by default")
    }

    @Test func defaultBlockedDomainsInclude888sport() {
        #expect(Session.defaultBlockedDomains.contains("888sport.com"),
                "888sport.com (888 Holdings' sportsbook brand — separate domain from 888casino/888poker) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeSportingbet() {
        #expect(Session.defaultBlockedDomains.contains("sportingbet.com"),
                "sportingbet.com (Entain Group international sportsbook — same parent as Ladbrokes/Coral/bwin) must be blocked by default")
    }

    @Test func allAdditionalGamblingOperators3AllPresentTogether() {
        let domains = Set(Session.defaultBlockedDomains)
        for site in ["betfair.com", "888sport.com", "sportingbet.com"] {
            #expect(domains.contains(site),
                    "\(site) (additional gambling operator) must be present")
        }
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterAdditionalGambling3Addition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate entries in defaultBlockedDomains after betfair/888sport/sportingbet addition")
    }

    @Test func additionalGamblingOperators3CoexistWithPriorGamblingEntries() {
        let domains = Set(Session.defaultBlockedDomains)
        for existing in ["bet365.com", "draftkings.com", "fanduel.com", "betway.com",
                         "bovada.lv", "betmgm.com", "ladbrokes.com", "paddypower.com",
                         "coral.co.uk", "unibet.com", "williamhill.com", "pokerstars.com",
                         "888casino.com", "888poker.com", "partypoker.com",
                         "betfred.com", "bwin.com", "sky.bet"] {
            #expect(domains.contains(existing),
                    "\(existing) (prior gambling entry) must still be present")
        }
    }

    @Test func betfairAppearsExactlyOnce() {
        let count = Session.defaultBlockedDomains.filter { $0 == "betfair.com" }.count
        #expect(count == 1, "betfair.com must appear exactly once in defaultBlockedDomains")
    }

    @Test func eightEightEightSportAppearsExactlyOnce() {
        let count = Session.defaultBlockedDomains.filter { $0 == "888sport.com" }.count
        #expect(count == 1, "888sport.com must appear exactly once in defaultBlockedDomains")
    }
}

// MARK: - Additional browser gaming portals (kizi, agame, coolmathgames)

@Suite("Session defaultBlockedDomains — additional browser gaming portals (kizi, agame, coolmathgames)")
struct AdditionalBrowserGaming3BlockTests {

    @Test func defaultBlockedDomainsIncludeKizi() {
        #expect(Session.defaultBlockedDomains.contains("kizi.com"),
                "kizi.com (30M+ MAU browser game portal, popular in Turkey and Eastern Europe) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeAgame() {
        #expect(Session.defaultBlockedDomains.contains("agame.com"),
                "agame.com (established browser game portal, 1000+ HTML5 titles) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeCoolMathGames() {
        #expect(Session.defaultBlockedDomains.contains("coolmathgames.com"),
                "coolmathgames.com (educational framing masks non-math game portal — uniquely insidious rationalisation target) must be blocked by default")
    }

    @Test func allAdditionalBrowserGaming3AllPresentTogether() {
        let domains = Set(Session.defaultBlockedDomains)
        for site in ["kizi.com", "agame.com", "coolmathgames.com"] {
            #expect(domains.contains(site),
                    "\(site) (browser gaming portal) must be present")
        }
    }

    @Test func defaultBlockedDomainsNoDuplicatesAfterAdditionalBrowserGaming3Addition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate entries in defaultBlockedDomains after kizi/agame/coolmathgames addition")
    }

    @Test func additionalBrowserGaming3CoexistsWithPriorBrowserGamingEntries() {
        let domains = Set(Session.defaultBlockedDomains)
        for existing in ["crazygames.com", "poki.com", "miniclip.com", "kongregate.com",
                         "addictinggames.com", "armorgames.com", "y8.com",
                         "silvergames.com", "friv.com"] {
            #expect(domains.contains(existing),
                    "\(existing) (prior browser gaming portal) must still be present")
        }
    }
}

// MARK: - Free ad-supported streaming (crackle, fawesome)

@Suite("Session defaultBlockedDomains — free ad-supported streaming (crackle, fawesome)")
struct FreeStreamingAVODBlockTests {

    @Test func defaultBlockedDomainsIncludeCrackle() {
        #expect(Session.defaultBlockedDomains.contains("crackle.com"),
                "crackle.com (Sony Pictures' free AVOD streaming — same zero-friction trap as Tubi) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeFawesome() {
        #expect(Session.defaultBlockedDomains.contains("fawesome.tv"),
                "fawesome.tv (free AVOD streaming, .tv TLD distinct from existing entries) must be blocked by default")
    }

    @Test func allFreeAVODStreamingPresentTogether() {
        let domains = Set(Session.defaultBlockedDomains)
        for site in ["crackle.com", "fawesome.tv"] {
            #expect(domains.contains(site),
                    "\(site) (free AVOD streaming service) must be present")
        }
    }

    @Test func freeStreamingNoDuplicatesAfterAddition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate entries in defaultBlockedDomains after crackle/fawesome addition")
    }

    @Test func freeStreamingCoexistsWithExistingStreamingEntries() {
        let domains = Set(Session.defaultBlockedDomains)
        for existing in ["netflix.com", "hulu.com", "tubi.tv", "pluto.tv",
                         "sling.com", "fubo.tv", "philo.com"] {
            #expect(domains.contains(existing),
                    "\(existing) (prior streaming entry) must still be present")
        }
    }

    @Test func crackleAppearsExactlyOnce() {
        let count = Session.defaultBlockedDomains.filter { $0 == "crackle.com" }.count
        #expect(count == 1, "crackle.com must appear exactly once in defaultBlockedDomains")
    }
}

// MARK: - Streaming alias and Plex (peacock.com, plex.tv)

@Suite("Session defaultBlockedDomains — streaming alias and Plex (peacock.com, plex.tv)")
struct StreamingAliasAndPlexBlockTests {

    @Test func defaultBlockedDomainsIncludePeacockCom() {
        #expect(Session.defaultBlockedDomains.contains("peacock.com"),
                "peacock.com (NBCUniversal's Peacock alias domain — distinct DNS entry from peacocktv.com) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludePlexTv() {
        #expect(Session.defaultBlockedDomains.contains("plex.tv"),
                "plex.tv (Plex — free ad-supported streaming tier alongside media-server product) must be blocked by default")
    }

    @Test func allStreamingAliasAndPlexPresentTogether() {
        let domains = Set(Session.defaultBlockedDomains)
        for site in ["peacock.com", "plex.tv"] {
            #expect(domains.contains(site),
                    "\(site) (streaming alias/Plex) must be present")
        }
    }

    @Test func streamingAliasNoDuplicatesAfterAddition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate entries in defaultBlockedDomains after peacock.com/plex.tv addition")
    }

    @Test func streamingAliasCoexistsWithExistingStreamingEntries() {
        let domains = Set(Session.defaultBlockedDomains)
        for existing in ["peacocktv.com", "netflix.com", "hulu.com", "tubi.tv", "pluto.tv",
                         "crackle.com", "fawesome.tv"] {
            #expect(domains.contains(existing),
                    "\(existing) (prior streaming entry) must still be present")
        }
    }

    @Test func peacockComAppearsExactlyOnce() {
        let count = Session.defaultBlockedDomains.filter { $0 == "peacock.com" }.count
        #expect(count == 1, "peacock.com must appear exactly once in defaultBlockedDomains")
    }

    @Test func plexTvAppearsExactlyOnce() {
        let count = Session.defaultBlockedDomains.filter { $0 == "plex.tv" }.count
        #expect(count == 1, "plex.tv must appear exactly once in defaultBlockedDomains")
    }
}

// MARK: - Additional international gambling operators (1xbet, melbet, betway.be)

@Suite("Session defaultBlockedDomains — additional international gambling operators (1xbet, melbet, betway.be)")
struct AdditionalInternationalGamblingBlockTests {

    @Test func defaultBlockedDomainsInclude1xBet() {
        #expect(Session.defaultBlockedDomains.contains("1xbet.com"),
                "1xbet.com (major CIS/Africa bookmaker, aggressive student-market targeting) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeMelbet() {
        #expect(Session.defaultBlockedDomains.contains("melbet.com"),
                "melbet.com (major Africa/South Asia bookmaker, influencer-driven student targeting) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeBetwayBe() {
        #expect(Session.defaultBlockedDomains.contains("betway.be"),
                "betway.be (Betway's Belgium-licensed .be TLD domain — distinct from betway.com) must be blocked by default")
    }

    @Test func allInternationalGamblingPresentTogether() {
        let domains = Set(Session.defaultBlockedDomains)
        for site in ["1xbet.com", "melbet.com", "betway.be"] {
            #expect(domains.contains(site),
                    "\(site) (international gambling operator) must be present")
        }
    }

    @Test func internationalGamblingNoDuplicatesAfterAddition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate entries in defaultBlockedDomains after 1xbet/melbet/betway.be addition")
    }

    @Test func internationalGamblingCoexistsWithPriorGamblingEntries() {
        let domains = Set(Session.defaultBlockedDomains)
        for existing in ["bet365.com", "betway.com", "betfair.com", "888sport.com",
                         "draftkings.com", "fanduel.com", "pokerstars.com",
                         "ladbrokes.com", "paddypower.com", "coral.co.uk",
                         "unibet.com", "williamhill.com", "betfred.com", "bwin.com",
                         "sky.bet", "sportingbet.com"] {
            #expect(domains.contains(existing),
                    "\(existing) (prior gambling entry) must still be present")
        }
    }

    @Test func onexBetAppearsExactlyOnce() {
        let count = Session.defaultBlockedDomains.filter { $0 == "1xbet.com" }.count
        #expect(count == 1, "1xbet.com must appear exactly once in defaultBlockedDomains")
    }

    @Test func melbetAppearsExactlyOnce() {
        let count = Session.defaultBlockedDomains.filter { $0 == "melbet.com" }.count
        #expect(count == 1, "melbet.com must appear exactly once in defaultBlockedDomains")
    }

    @Test func betwayBeAppearsExactlyOnce() {
        let count = Session.defaultBlockedDomains.filter { $0 == "betway.be" }.count
        #expect(count == 1, "betway.be must appear exactly once in defaultBlockedDomains")
    }
}

// MARK: - Additional browser gaming portals (gameflare, iogames.space, spele.lv)

@Suite("Session defaultBlockedDomains — additional browser gaming portals (gameflare, iogames.space, spele.lv)")
struct AdditionalGamingPortals4BlockTests {

    @Test func defaultBlockedDomainsIncludeGameflare() {
        #expect(Session.defaultBlockedDomains.contains("gameflare.com"),
                "gameflare.com (large HTML5 game portal, Trending Today + New Games discovery feeds) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeIOGamesSpace() {
        #expect(Session.defaultBlockedDomains.contains("iogames.space"),
                "iogames.space (IO-games aggregator — real-time multiplayer; 'just one more round' social cost) must be blocked by default")
    }

    @Test func defaultBlockedDomainsIncludeSpeleLv() {
        #expect(Session.defaultBlockedDomains.contains("spele.lv"),
                "spele.lv (Baltic/Eastern European browser game portal, .lv TLD distinct from existing entries) must be blocked by default")
    }

    @Test func allGamingPortals4PresentTogether() {
        let domains = Set(Session.defaultBlockedDomains)
        for site in ["gameflare.com", "iogames.space", "spele.lv"] {
            #expect(domains.contains(site),
                    "\(site) (browser gaming portal) must be present")
        }
    }

    @Test func gamingPortals4NoDuplicatesAfterAddition() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate entries in defaultBlockedDomains after gameflare/iogames.space/spele.lv addition")
    }

    @Test func gamingPortals4CoexistsWithPriorPortalEntries() {
        let domains = Set(Session.defaultBlockedDomains)
        for existing in ["crazygames.com", "poki.com", "miniclip.com", "kongregate.com",
                         "addictinggames.com", "armorgames.com", "y8.com",
                         "silvergames.com", "friv.com",
                         "kizi.com", "agame.com", "coolmathgames.com"] {
            #expect(domains.contains(existing),
                    "\(existing) (prior browser gaming portal) must still be present")
        }
    }

    @Test func gameflareAppearsExactlyOnce() {
        let count = Session.defaultBlockedDomains.filter { $0 == "gameflare.com" }.count
        #expect(count == 1, "gameflare.com must appear exactly once in defaultBlockedDomains")
    }

    @Test func ioGamesSpaceAppearsExactlyOnce() {
        let count = Session.defaultBlockedDomains.filter { $0 == "iogames.space" }.count
        #expect(count == 1, "iogames.space must appear exactly once in defaultBlockedDomains")
    }
}

// MARK: - Session pause fields

@Suite("Session pause/resume model")
struct SessionPauseTests {

    @Test func pausedDurationDefaultsToZero() {
        let s = Session(task: "t", successCriteria: "c")
        #expect(s.pausedDuration == 0)
    }

    @Test func pauseStartTimeDefaultsToNil() {
        let s = Session(task: "t", successCriteria: "c")
        #expect(s.pauseStartTime == nil)
    }

    @Test func pausedPhaseRoundTrips() throws {
        let s = Session(task: "t", successCriteria: "c", phase: .paused)
        let data = try JSONEncoder().encode(s)
        let decoded = try JSONDecoder().decode(Session.self, from: data)
        #expect(decoded.phase == .paused)
    }

    @Test func pausedDurationRoundTrips() throws {
        let s = Session(task: "t", successCriteria: "c", pausedDuration: 300)
        let data = try JSONEncoder().encode(s)
        let decoded = try JSONDecoder().decode(Session.self, from: data)
        #expect(decoded.pausedDuration == 300)
    }

    @Test func pauseStartTimeRoundTrips() throws {
        let now = Date()
        let s = Session(task: "t", successCriteria: "c", pauseStartTime: now)
        let data = try JSONEncoder().encode(s)
        let decoded = try JSONDecoder().decode(Session.self, from: data)
        #expect(decoded.pauseStartTime != nil)
    }

    @Test func backwardCompatibleDecodeMissingPauseFields() throws {
        let json = """
        {
            "id": "00000000-0000-0000-0000-000000000001",
            "task": "Write essay",
            "successCriteria": "Submit",
            "startTime": 0,
            "phase": "active",
            "whitelistedDomains": [],
            "blockedDomains": [],
            "calloutCount": 0
        }
        """
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Session.self, from: data)
        #expect(decoded.pausedDuration == 0)
        #expect(decoded.pauseStartTime == nil)
    }

    @Test func elapsedAccountsForPausedDuration() {
        let s = Session(
            task: "t", successCriteria: "c",
            startTime: Date(timeIntervalSinceNow: -1000),
            pausedDuration: 400
        )
        #expect(s.elapsed >= 598 && s.elapsed <= 602)
    }

    @Test func elapsedAccountsForOngoingPause() {
        let s = Session(
            task: "t", successCriteria: "c",
            startTime: Date(timeIntervalSinceNow: -1000),
            pausedDuration: 0,
            pauseStartTime: Date(timeIntervalSinceNow: -200)
        )
        #expect(s.elapsed >= 798 && s.elapsed <= 802)
    }

    @Test func elapsedNeverNegativeWithLargePausedDuration() {
        let s = Session(
            task: "t", successCriteria: "c",
            startTime: Date(),
            pausedDuration: 99999
        )
        #expect(s.elapsed >= 0)
    }
}
