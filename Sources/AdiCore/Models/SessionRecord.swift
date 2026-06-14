import Foundation

public struct SessionRecord: Sendable, Identifiable {
    public let id: UUID
    public let task: String
    public let successCriteria: String
    public let startTime: Date
    public let endTime: Date
    public let completedSuccessfully: Bool
    public let calloutCount: Int
    /// Optional user annotation added after the session ends. nil when not set.
    /// Decoded as nil for records persisted before this field was introduced.
    public var note: String?
    /// Number of screen-capture frames classified as "on-task" by the AI.
    /// Zero for sessions recorded before this field was introduced.
    public let onTaskChecks: Int
    /// Total screen-capture frames classified (on-task + off-task + ambiguous).
    /// Zero for sessions recorded before this field was introduced.
    public let totalChecks: Int
    /// Number of times the user asked the reasoning AI for access to a blocked
    /// site during this session. Zero for sessions recorded before this field
    /// was introduced (and for sessions where the user never asked).
    public let reasoningAttempts: Int
    /// Of `reasoningAttempts`, how many were granted by the AI.
    /// Zero for sessions recorded before this field was introduced.
    public let reasoningGranted: Int
    /// Domains that were blocked during this session (snapshot at session end).
    /// Empty array for sessions recorded before this field was introduced.
    public let blockedDomains: [String]

    public init(
        id: UUID = UUID(),
        task: String,
        successCriteria: String,
        startTime: Date,
        endTime: Date,
        completedSuccessfully: Bool,
        calloutCount: Int,
        note: String? = nil,
        onTaskChecks: Int = 0,
        totalChecks: Int = 0,
        reasoningAttempts: Int = 0,
        reasoningGranted: Int = 0,
        blockedDomains: [String] = []
    ) {
        self.id = id
        self.task = task
        self.successCriteria = successCriteria
        self.startTime = startTime
        self.endTime = endTime
        self.completedSuccessfully = completedSuccessfully
        self.calloutCount = calloutCount
        self.note = note
        self.onTaskChecks = onTaskChecks
        self.totalChecks = totalChecks
        self.reasoningAttempts = reasoningAttempts
        self.reasoningGranted = reasoningGranted
        self.blockedDomains = blockedDomains
    }

    public var duration: TimeInterval { endTime.timeIntervalSince(startTime) }

    /// Fraction of classified frames that were on-task (0.0–1.0).
    /// nil when no frames were classified (e.g. session too short or pre-feature record).
    public var focusScore: Double? {
        guard totalChecks > 0 else { return nil }
        return Double(onTaskChecks) / Double(totalChecks)
    }
}

// MARK: - Codable

extension SessionRecord: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, task, successCriteria, startTime, endTime
        case completedSuccessfully, calloutCount, note
        case onTaskChecks, totalChecks
        case reasoningAttempts, reasoningGranted
        case blockedDomains
        // Computed convenience fields — encoded for external consumers, never decoded
        // (they are derived from stored fields above on decode).
        case focusScore, durationSeconds
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                   = try c.decode(UUID.self,   forKey: .id)
        task                 = try c.decode(String.self, forKey: .task)
        successCriteria      = try c.decode(String.self, forKey: .successCriteria)
        startTime            = try c.decode(Date.self,   forKey: .startTime)
        endTime              = try c.decode(Date.self,   forKey: .endTime)
        completedSuccessfully = try c.decode(Bool.self,  forKey: .completedSuccessfully)
        calloutCount         = try c.decode(Int.self,    forKey: .calloutCount)
        note                 = try c.decodeIfPresent(String.self, forKey: .note)
        onTaskChecks         = try c.decodeIfPresent(Int.self,    forKey: .onTaskChecks) ?? 0
        totalChecks          = try c.decodeIfPresent(Int.self,    forKey: .totalChecks)  ?? 0
        reasoningAttempts    = try c.decodeIfPresent(Int.self,    forKey: .reasoningAttempts) ?? 0
        reasoningGranted     = try c.decodeIfPresent(Int.self,    forKey: .reasoningGranted)  ?? 0
        blockedDomains       = try c.decodeIfPresent([String].self, forKey: .blockedDomains)  ?? []
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,                    forKey: .id)
        try c.encode(task,                  forKey: .task)
        try c.encode(successCriteria,       forKey: .successCriteria)
        try c.encode(startTime,             forKey: .startTime)
        try c.encode(endTime,               forKey: .endTime)
        try c.encode(completedSuccessfully, forKey: .completedSuccessfully)
        try c.encode(calloutCount,          forKey: .calloutCount)
        try c.encodeIfPresent(note,         forKey: .note)
        try c.encode(onTaskChecks,          forKey: .onTaskChecks)
        try c.encode(totalChecks,           forKey: .totalChecks)
        try c.encode(reasoningAttempts,     forKey: .reasoningAttempts)
        try c.encode(reasoningGranted,      forKey: .reasoningGranted)
        try c.encode(blockedDomains,        forKey: .blockedDomains)
        // Convenience computed fields for external consumers (e.g. JSON export tools).
        // Not decoded — derived from onTaskChecks/totalChecks and startTime/endTime above.
        try c.encodeIfPresent(focusScore,   forKey: .focusScore)
        try c.encode(Int(duration),         forKey: .durationSeconds)
    }
}
