import Foundation

// MARK: - Session Phase

public enum SessionPhase: String, Codable, Sendable {
    case idle
    case active
    case verifying
    case complete
    case earlyExitPending
}

// MARK: - On-task classification

public enum OnTaskStatus: String, Codable, Sendable {
    case onTask
    case offTask
    case ambiguous
}

// MARK: - Verification result

public struct VerificationResult: Codable, Sendable {
    public let verified: Bool
    public let explanation: String

    public init(verified: Bool, explanation: String) {
        self.verified = verified
        self.explanation = explanation
    }
}

// MARK: - Verification attempt (one entry in the within-session history)

public struct VerificationAttempt: Codable, Sendable {
    public let timestamp: Date
    public let result: VerificationResult
    /// 1-based index: first attempt = 1.
    public let attemptNumber: Int

    public init(timestamp: Date = Date(), result: VerificationResult, attemptNumber: Int) {
        self.timestamp = timestamp
        self.result = result
        self.attemptNumber = attemptNumber
    }
}

// MARK: - Reasoning attempt (one entry in the within-session reasoning-conversation memory)

/// Records the outcome of a single "argue for site access" conversation so the AI can
/// reference it if the user comes back asking about the same domain again — the PRD
/// calls for the AI to "carry context across attempts within a session."
public struct ReasoningAttempt: Codable, Sendable {
    public let timestamp: Date
    public let domain: String
    public let granted: Bool
    /// Short justification — the AI's final reasoning, truncated for prompt-injection use.
    public let summary: String

    public init(timestamp: Date = Date(), domain: String, granted: Bool, summary: String) {
        self.timestamp = timestamp
        self.domain = domain
        self.granted = granted
        self.summary = summary
    }
}

// MARK: - Session

public struct Session: Sendable, Identifiable {
    public let id: UUID
    public var task: String
    public var successCriteria: String
    public var startTime: Date
    public var phase: SessionPhase
    public var whitelistedDomains: [String]
    public var blockedDomains: [String]
    /// Bundle IDs of apps that trigger an immediate callout when opened.
    public var blockedApps: [String]
    /// Cumulative callouts fired this session. Persisted so tier escalation survives a crash/relaunch.
    public var calloutCount: Int
    /// Verification attempts made this session. Persisted so attempt numbering survives a crash/relaunch.
    public var verificationHistory: [VerificationAttempt]
    /// Optional target work duration in seconds. nil = no goal. Shown as a progress arc in the collapsed notch.
    public var targetDuration: TimeInterval?
    /// Reasoning ("argue for access") conversation outcomes, keyed implicitly by domain.
    /// Lets the AI recall — and call out — repeat asks for the same site within a session.
    public var reasoningHistory: [ReasoningAttempt]
    /// On-task AI classification frames this session. Persisted so focus score survives a crash/relaunch.
    public var onTaskChecks: Int
    /// Total AI classification frames this session. Persisted so focus score survives a crash/relaunch.
    public var totalChecks: Int

    public init(
        id: UUID = UUID(),
        task: String,
        successCriteria: String,
        startTime: Date = Date(),
        phase: SessionPhase = .idle,
        whitelistedDomains: [String] = [],
        blockedDomains: [String] = Session.defaultBlockedDomains,
        blockedApps: [String] = Session.defaultBlockedAppBundleIDs,
        calloutCount: Int = 0,
        verificationHistory: [VerificationAttempt] = [],
        targetDuration: TimeInterval? = nil,
        reasoningHistory: [ReasoningAttempt] = [],
        onTaskChecks: Int = 0,
        totalChecks: Int = 0
    ) {
        self.id = id
        self.task = task
        self.successCriteria = successCriteria
        self.startTime = startTime
        self.phase = phase
        self.whitelistedDomains = whitelistedDomains
        self.blockedDomains = blockedDomains
        self.blockedApps = blockedApps
        self.calloutCount = calloutCount
        self.verificationHistory = verificationHistory
        self.targetDuration = targetDuration
        self.reasoningHistory = reasoningHistory
        self.onTaskChecks = onTaskChecks
        self.totalChecks = totalChecks
    }

    public var elapsed: TimeInterval { Date().timeIntervalSince(startTime) }

    public static let defaultBlockedDomains: [String] = [
        // Social media
        "twitter.com", "x.com",
        "reddit.com",
        "youtube.com",
        "instagram.com",
        "tiktok.com",
        "facebook.com",
        "threads.net",
        "snapchat.com",
        "tumblr.com",
        "pinterest.com",
        // Streaming & gaming
        "netflix.com",
        "twitch.tv",
        "hulu.com",
        "disneyplus.com",
        "primevideo.com",
        "max.com",
        "crunchyroll.com",
        "peacocktv.com",
        "steampowered.com",
        "epicgames.com",
        // Music streaming (passive-listening distraction during deep work)
        "soundcloud.com",
        "bandcamp.com",
        // Messaging & community
        "discord.com",
        // discordapp.com is Discord's infrastructure/CDN domain — separate from discord.com.
        // cdn.discordapp.com serves avatars, images, and file attachments; users can access
        // Discord media via direct CDN links even when discord.com itself is blocked in the browser.
        // The "cdn" subdomain prefix auto-generates cdn.discordapp.com alongside every domain entry.
        // media.discordapp.com (covered by the "media" prefix) serves embedded GIF/video previews.
        "discordapp.com",
        // discordapp.net is Discord's WebRTC and gateway infrastructure domain (separate from discordapp.com).
        // Discord's voice channels and the real-time gateway connect through *.discordapp.net endpoints;
        // blocking discord.com and discordapp.com leaves this infrastructure domain open for direct access.
        "discordapp.net",
        // discordapp.io is Discord's worker / edge-function domain used for Cloudflare Workers,
        // status-page polling, and experimental API endpoints. It is a distinct TLD from discordapp.com
        // and discordapp.net; blocking those two leaves discordapp.io accessible for direct requests.
        "discordapp.io",
        "slack.com",
        "9gag.com",
        // Messaging web clients (web.X bypasses native app blocks when apps are not running)
        // WhatsApp Web (web.whatsapp.com) and Telegram Web (web.telegram.org) are full-featured
        // browser clients — blocking only the native app bundle IDs leaves the web route open.
        "whatsapp.com",
        "telegram.org",
        // Sports
        "espn.com",
        "nba.com",
        "nfl.com",
        "mlb.com",
        "nhl.com",
        "bleacherreport.com",
        "cbssports.com",
        // News & click-bait
        "buzzfeed.com",
        "huffpost.com",
        "msn.com",
        "dailymail.co.uk",
        // Tech news (procrastination in disguise)
        "hacker-news.firebaseapp.com",
        "news.ycombinator.com",
        "theverge.com",              // tech/culture publication: high-engagement, easy "just one article" trap
        "techcrunch.com",            // startup news: intellectually justifiable but rarely task-relevant
        "wired.com",                 // long-form tech culture: same "productive-feeling" trap as medium.com
        "arstechnica.com",           // in-depth tech journalism: reads like research but is rarely task-relevant
        // Professional procrastination
        "linkedin.com",
        // Shopping
        "amazon.com",
        "ebay.com",
        "etsy.com",
        "aliexpress.com",
        "walmart.com",
        // News (procrastination disguised as staying informed)
        "cnn.com",
        "foxnews.com",
        "bbc.com",
        "theguardian.com",
        // Other time sinks
        "quora.com",
        "fandom.com",
        // Bypass short-link domains (circumvent parent domain blocks if not listed separately)
        "youtu.be",              // YouTube's short URL — bypasses the youtube.com block
        "discord.gg",            // Discord invite links — separate domain from discord.com
        "t.co",                  // Twitter's link shortener — follows the twitter.com block
        // Games (serious procrastination trap for students and knowledge workers)
        "chess.com",
        "lichess.org",
        // Reading & creative procrastination (popular with students)
        "webtoons.com",
        "wattpad.com",
        "archiveofourown.org",   // fanfiction — extremely time-consuming
        "mangadex.org",
        // Professional procrastination
        "producthunt.com",
        // Music streaming — web player bypasses the app block (com.spotify.client)
        "spotify.com",
        // Long-form reading rabbit holes (knowledge workers & students)
        "medium.com",
        "substack.com",
        // Major news sites (procrastination disguised as staying informed)
        "nytimes.com",
        "washingtonpost.com",
        "npr.org",
        "apnews.com",
        // Social platform short-link bypass domains (completely separate DNS names from parent)
        "redd.it",               // Reddit's own short URL (redd.it/abc123) — bypasses reddit.com block
        "instagr.am",            // Instagram's short URL — bypasses instagram.com block
        "fb.me",                 // Facebook's short URL — bypasses facebook.com block
        // Reddit CDN / media domains — served from completely separate hostnames; blocking
        // reddit.com alone does NOT prevent access to these image/video CDN endpoints.
        "i.redd.it",                  // Reddit's image CDN: inline images in posts/comments
        "v.redd.it",                  // Reddit's video CDN: hosted video player embeds
        "preview.redd.it",            // Reddit's preview CDN: link/image previews in feeds
        "external-preview.redd.it",   // Reddit's external-link preview CDN: thumbnails for links posted to reddit
        // Twitch legacy CDN domain (Justin.tv origin, still used by Twitch for thumbnails and media).
        // jtvnw.net is a completely separate TLD from twitch.tv — blocking twitch.tv does NOT cover
        // jtvnw.net. Twitch continues to serve profile images, game box art, stream thumbnails, and
        // clip preview frames from *.jtvnw.net CDN endpoints. External links (Reddit, Discord) often
        // embed these thumbnails directly, providing a visual Twitch experience even when twitch.tv is
        // blocked. The "static" prefix rule generates static.jtvnw.net; the "cdn" prefix generates
        // cdn.jtvnw.net. Both are auto-blocked alongside jtvnw.net.
        "jtvnw.net",
        // static-cdn.jtvnw.net is Twitch's primary image/thumbnail CDN endpoint and the single
        // most-used *.jtvnw.net hostname. The subdomain uses a hyphen ("static-cdn"), not a dot, so
        // the prefix mechanism — which generates "prefix.domain" entries — does NOT cover it.
        // static-cdn.jtvnw.net must be listed as an explicit literal entry here.
        // Twitch serves nearly all profile images, game box art, and stream preview thumbnails from
        // this hostname; Reddit and Discord frequently embed these URLs directly in posts and messages.
        "static-cdn.jtvnw.net",
        // Live-streaming platforms (direct Twitch competitors and global alternatives)
        // kick.com — major live-streaming platform that has overtaken Twitch for some audiences;
        //   popular for gaming, IRL streaming, and often recommended as a "Twitch alternative"
        //   that users switch to mid-session when twitch.tv is blocked.
        "kick.com",
        // trovo.live — Tencent's live-streaming platform (direct Twitch competitor in Asia and
        //   globally); separate TLD from any other blocked domain, not covered by any existing rule.
        "trovo.live",
        // Video platforms (alternative/niche video hosts that are standalone time sinks)
        // rumble.com — video platform popular for news, commentary, and entertainment; users
        //   may pivot to it mid-session when youtube.com is blocked.
        "rumble.com",
        // dailymotion.com — long-form video platform; one of the oldest YouTube alternatives
        //   and a common landing page for embedded video content from news and entertainment sites.
        "dailymotion.com",
        // bilibili.com — dominant video/anime/streaming platform in China and popular globally
        //   for anime, gaming content, and long-form video essays; separate domain from any
        //   existing blocked entry.
        "bilibili.com",
        // odysee.com — decentralized video platform (formerly LBRY); hosts news, gaming, and
        //   entertainment content; commonly linked from Reddit and Discord as a YouTube alternative.
        "odysee.com",
        // Image-hosting platforms (major standalone procrastination vectors)
        // imgur.com — the primary image host used throughout Reddit, Discord, and social media.
        //   Even with reddit.com blocked, users navigate directly to imgur.com to browse meme
        //   galleries, viral posts, and the Imgur front page — which is a full discovery feed.
        //   Among the highest-engagement "one more scroll" time sinks outside of mainstream
        //   social media. cdn.imgur.com and i.imgur.com (image CDN) are auto-generated by the
        //   "cdn" and "i" subdomain prefix rules.
        "imgur.com",
        // giphy.com — GIF discovery platform; heavily linked from Slack, Discord, and Twitter.
        //   Users browse Giphy directly for entertainment; also a distraction entry point when
        //   someone follows a GIF link from a messaging app.
        "giphy.com",
        // tenor.com — Google-owned GIF platform, the primary GIF source in many messaging apps
        //   (including Android messages). Direct navigation to tenor.com leads to browse mode.
        "tenor.com",
    ]

    public static let defaultBlockedApps: [BlockedApp] = [
        BlockedApp(id: "com.hnc.Discord",               name: "Discord"),
        BlockedApp(id: "com.valvesoftware.steam",        name: "Steam"),
        BlockedApp(id: "tv.twitch.twitch-client",        name: "Twitch"),
        BlockedApp(id: "net.whatsapp.WhatsApp",          name: "WhatsApp"),
        BlockedApp(id: "ru.keepcoder.Telegram",          name: "Telegram"),
        BlockedApp(id: "com.apple.TV",                   name: "Apple TV"),
        BlockedApp(id: "com.burbn.instagram",            name: "Instagram"),
        BlockedApp(id: "com.facebook.Facebook",          name: "Facebook"),
        BlockedApp(id: "com.spotify.client",             name: "Spotify"),
        BlockedApp(id: "com.tencent.xinWeChat",          name: "WeChat"),
        BlockedApp(id: "com.apple.Music",                name: "Apple Music"),
        BlockedApp(id: "com.apple.podcasts",             name: "Podcasts"),
        BlockedApp(id: "com.netflix.Netflix",            name: "Netflix"),
        BlockedApp(id: "com.reddit.Reddit",              name: "Reddit"),
        BlockedApp(id: "com.mojang.minecraftlauncher",   name: "Minecraft"),
        // Twitter/X ships two distinct bundle IDs on macOS:
        // - com.twitter.twitter-mac: the legacy native Mac app (pre-2022)
        // - com.atebits.Tweetie2: the Mac Catalyst port of the iOS app (current X app)
        // Both must be listed to catch whichever variant is installed.
        BlockedApp(id: "com.twitter.twitter-mac",        name: "Twitter (legacy)"),
        BlockedApp(id: "com.atebits.Tweetie2",           name: "X / Twitter"),
    ]

    public static var defaultBlockedAppBundleIDs: [String] {
        defaultBlockedApps.map(\.id)
    }
}

// MARK: - Codable (manual for backward-compatible field decode)

extension Session: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, task, successCriteria, startTime, phase
        case whitelistedDomains, blockedDomains, blockedApps, calloutCount
        case verificationHistory, targetDuration, reasoningHistory
        case onTaskChecks, totalChecks
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                 = try c.decode(UUID.self,          forKey: .id)
        task               = try c.decode(String.self,        forKey: .task)
        successCriteria    = try c.decode(String.self,        forKey: .successCriteria)
        startTime          = try c.decode(Date.self,          forKey: .startTime)
        phase              = try c.decode(SessionPhase.self,  forKey: .phase)
        whitelistedDomains = try c.decode([String].self,      forKey: .whitelistedDomains)
        blockedDomains     = try c.decode([String].self,      forKey: .blockedDomains)
        // Gracefully decode missing key (old sessions pre-app-blocking).
        blockedApps = (try? c.decode([String].self, forKey: .blockedApps))
            ?? Session.defaultBlockedAppBundleIDs
        // Gracefully decode missing key (old sessions pre-callout-persistence).
        calloutCount = (try? c.decode(Int.self, forKey: .calloutCount)) ?? 0
        // Gracefully decode missing key (old sessions pre-verification-history).
        verificationHistory = (try? c.decode([VerificationAttempt].self, forKey: .verificationHistory)) ?? []
        // Gracefully decode missing key (old sessions without duration goal).
        targetDuration = try? c.decode(TimeInterval.self, forKey: .targetDuration)
        // Gracefully decode missing key (old sessions pre-reasoning-memory).
        reasoningHistory = (try? c.decode([ReasoningAttempt].self, forKey: .reasoningHistory)) ?? []
        // Gracefully decode missing key (old sessions pre-focus-score-persistence).
        onTaskChecks = (try? c.decode(Int.self, forKey: .onTaskChecks)) ?? 0
        totalChecks  = (try? c.decode(Int.self, forKey: .totalChecks))  ?? 0
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,                  forKey: .id)
        try c.encode(task,                forKey: .task)
        try c.encode(successCriteria,     forKey: .successCriteria)
        try c.encode(startTime,           forKey: .startTime)
        try c.encode(phase,               forKey: .phase)
        try c.encode(whitelistedDomains,  forKey: .whitelistedDomains)
        try c.encode(blockedDomains,      forKey: .blockedDomains)
        try c.encode(blockedApps,         forKey: .blockedApps)
        try c.encode(calloutCount,        forKey: .calloutCount)
        try c.encode(verificationHistory, forKey: .verificationHistory)
        try c.encodeIfPresent(targetDuration, forKey: .targetDuration)
        try c.encode(reasoningHistory,    forKey: .reasoningHistory)
        try c.encode(onTaskChecks,        forKey: .onTaskChecks)
        try c.encode(totalChecks,         forKey: .totalChecks)
    }
}
