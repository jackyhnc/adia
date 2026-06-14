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
        reasoningHistory: [ReasoningAttempt] = []
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
        // Messaging & community
        "discord.com",
        "slack.com",
        "9gag.com",
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
    ]

    public static var defaultBlockedAppBundleIDs: [String] {
        defaultBlockedApps.map(\.id)
    }
}

// MARK: - Codable (manual for backward-compatible blockedApps decode)

extension Session: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, task, successCriteria, startTime, phase
        case whitelistedDomains, blockedDomains, blockedApps, calloutCount
        case verificationHistory, targetDuration, reasoningHistory
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
        try c.encode(reasoningHistory, forKey: .reasoningHistory)
    }
}
