import Foundation

public struct SessionRecord: Codable, Sendable, Identifiable {
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

    public init(
        id: UUID = UUID(),
        task: String,
        successCriteria: String,
        startTime: Date,
        endTime: Date,
        completedSuccessfully: Bool,
        calloutCount: Int,
        note: String? = nil
    ) {
        self.id = id
        self.task = task
        self.successCriteria = successCriteria
        self.startTime = startTime
        self.endTime = endTime
        self.completedSuccessfully = completedSuccessfully
        self.calloutCount = calloutCount
        self.note = note
    }

    public var duration: TimeInterval { endTime.timeIntervalSince(startTime) }
}
