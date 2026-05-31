import Foundation

public enum AppLogger {
    private static let lock = NSLock()
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }()

    public static var logFileURL: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        return base.appendingPathComponent("Adia", isDirectory: true)
            .appendingPathComponent("adia.log")
    }

    public static func info(_ event: String, _ fields: [String: String] = [:]) {
        write(level: "info", event: event, fields: fields)
    }

    public static func warning(_ event: String, _ fields: [String: String] = [:]) {
        write(level: "warning", event: event, fields: fields)
    }

    public static func error(_ event: String, _ fields: [String: String] = [:]) {
        write(level: "error", event: event, fields: fields)
    }

    private static func write(level: String, event: String, fields: [String: String]) {
        let entry = LogEntry(timestamp: Date(), level: level, event: event, fields: fields)
        guard let data = try? encoder.encode(entry), let line = String(data: data, encoding: .utf8) else {
            return
        }

        lock.withLock {
            let url = logFileURL
            try? FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            if let handle = try? FileHandle(forWritingTo: url) {
                handle.seekToEndOfFile()
                handle.write(Data((line + "\n").utf8))
                try? handle.close()
            } else {
                try? (line + "\n").write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}

private struct LogEntry: Encodable {
    let timestamp: Date
    let level: String
    let event: String
    let fields: [String: String]
}
