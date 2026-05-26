import Foundation

public actor SessionHistory {
    public static let shared = SessionHistory()

    internal static let maxRecords = 50

    private let fileURL: URL

    // Production init: writes to ~/Library/Application Support/Adia/history.json
    private init() {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let dir = support.appendingPathComponent("Adia", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("history.json")
    }

    // Test init: caller supplies an arbitrary path so production data is never touched.
    internal init(fileURL: URL) {
        self.fileURL = fileURL
    }

    // MARK: - Public API

    /// Prepend a new record and trim to maxRecords. Newest entry is always first.
    public func record(_ entry: SessionRecord) {
        var records = _load()
        records.insert(entry, at: 0)
        if records.count > Self.maxRecords {
            records = Array(records.prefix(Self.maxRecords))
        }
        _save(records)
    }

    /// Returns all records, newest first.
    public func load() -> [SessionRecord] { _load() }

    /// Deletes the history file.
    public func clear() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Private helpers

    private func _load() -> [SessionRecord] {
        guard let data = try? Data(contentsOf: fileURL),
              let records = try? JSONDecoder().decode([SessionRecord].self, from: data)
        else { return [] }
        return records
    }

    private func _save(_ records: [SessionRecord]) {
        guard let data = try? JSONEncoder().encode(records) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
