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
        verificationHistory: [VerificationAttempt] = []
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
    }

    public var elapsed: TimeInterval { Date().timeIntervalSince(startTime) }

    public static let defaultBlockedDomains: [String] = [
        "twitter.com", "x.com",
        "reddit.com",
        "youtube.com",
        "instagram.com",
        "tiktok.com",
        "facebook.com",
        "netflix.com",
        "twitch.tv",
        "discord.com",
        "slack.com",
        "pinterest.com",
        "snapchat.com",
        "threads.net",
        "tumblr.com",
        "9gag.com",
        "hacker-news.firebaseapp.com",
        "news.ycombinator.com",
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
        case verificationHistory
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
    }
}
