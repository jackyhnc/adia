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

// MARK: - Session

public struct Session: Codable, Sendable, Identifiable {
    public let id: UUID
    public var task: String
    public var successCriteria: String
    public var startTime: Date
    public var phase: SessionPhase
    public var whitelistedDomains: [String]
    public var blockedDomains: [String]

    public init(
        id: UUID = UUID(),
        task: String,
        successCriteria: String,
        startTime: Date = Date(),
        phase: SessionPhase = .idle,
        whitelistedDomains: [String] = [],
        blockedDomains: [String] = Session.defaultBlockedDomains
    ) {
        self.id = id
        self.task = task
        self.successCriteria = successCriteria
        self.startTime = startTime
        self.phase = phase
        self.whitelistedDomains = whitelistedDomains
        self.blockedDomains = blockedDomains
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
        "hacker-news.firebaseapp.com",
        "news.ycombinator.com",
    ]
}
