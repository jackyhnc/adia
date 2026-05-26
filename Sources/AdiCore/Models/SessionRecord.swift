import Foundation

public struct SessionRecord: Codable, Sendable, Identifiable {
    public let id: UUID
    public let task: String
    public let successCriteria: String
    public let startTime: Date
    public let endTime: Date
    public let completedSuccessfully: Bool
    public let calloutCount: Int

    public init(
        id: UUID = UUID(),
        task: String,
        successCriteria: String,
        startTime: Date,
        endTime: Date,
        completedSuccessfully: Bool,
        calloutCount: Int
    ) {
        self.id = id
        self.task = task
        self.successCriteria = successCriteria
        self.startTime = startTime
        self.endTime = endTime
        self.completedSuccessfully = completedSuccessfully
        self.calloutCount = calloutCount
    }

    public var duration: TimeInterval { endTime.timeIntervalSince(startTime) }
}
