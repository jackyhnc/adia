import Foundation

public final class SessionPersistence: @unchecked Sendable {
    private let fileURL: URL

    public static let shared = SessionPersistence()

    public init(fileURL: URL? = nil) {
        if let url = fileURL {
            self.fileURL = url
        } else {
            let appSupport = FileManager.default
                .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            let dir = appSupport.appendingPathComponent("Adia", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            self.fileURL = dir.appendingPathComponent("current_session.json")
        }
    }

    public func save(_ session: Session) throws {
        let data = try JSONEncoder().encode(session)
        try data.write(to: fileURL, options: .atomic)
    }

    public func load() throws -> Session? {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(Session.self, from: data)
    }

    public func clear() throws {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
