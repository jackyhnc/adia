import Foundation

public enum SessionStatus: String, Codable, Sendable, Equatable {
    case idle
    case active
    case paused
    case completed
    case abandoned
}

public enum OnTaskStatus: String, Codable, Sendable, Equatable {
    case onTask
    case offTask
    case ambiguous
    case unknown
}

public struct SessionTask: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public var description: String
    public var successCriteria: String

    public init(id: UUID = UUID(), description: String, successCriteria: String) {
        self.id = id
        self.description = description
        self.successCriteria = successCriteria
    }
}

public struct Session: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public var task: SessionTask
    public var status: SessionStatus
    public var startTime: Date
    public var endTime: Date?
    public var whitelist: [String]
    public var lastOnTaskStatus: OnTaskStatus
    public var offTaskCount: Int

    public init(
        id: UUID = UUID(),
        task: SessionTask,
        status: SessionStatus = .idle,
        startTime: Date = Date(),
        endTime: Date? = nil,
        whitelist: [String] = [],
        lastOnTaskStatus: OnTaskStatus = .unknown,
        offTaskCount: Int = 0
    ) {
        self.id = id
        self.task = task
        self.status = status
        self.startTime = startTime
        self.endTime = endTime
        self.whitelist = whitelist
        self.lastOnTaskStatus = lastOnTaskStatus
        self.offTaskCount = offTaskCount
    }

    public var elapsedTime: TimeInterval {
        (endTime ?? Date()).timeIntervalSince(startTime)
    }

    public func elapsedFormatted() -> String {
        let seconds = Int(elapsedTime)
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        }
        return String(format: "%d:%02d", m, s)
    }
}
