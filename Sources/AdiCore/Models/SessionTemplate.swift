import Foundation

// MARK: - SessionTemplate

public struct SessionTemplate: Identifiable, Codable, Sendable {
    public let id: UUID
    public var task: String
    public var successCriteria: String
    public var useCount: Int
    public var lastUsedAt: Date?
    public let createdAt: Date

    public init(
        id: UUID = UUID(),
        task: String,
        successCriteria: String,
        useCount: Int = 0,
        lastUsedAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.task = task
        self.successCriteria = successCriteria
        self.useCount = useCount
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
    }
}

// MARK: - SessionTemplateStore

public actor SessionTemplateStore {
    public static let shared = SessionTemplateStore()

    private let fileURL: URL
    static let maxTemplates = 10

    private init() {
        let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first!
        let dir = support.appendingPathComponent("Adia", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("templates.json")
    }

    internal init(fileURL: URL) {
        self.fileURL = fileURL
    }

    // MARK: - Public API

    /// All stored templates, newest-first (by lastUsedAt, then createdAt).
    public func load() -> [SessionTemplate] { _load() }

    /// Sorted by lastUsedAt desc, then useCount desc, then createdAt desc.
    public func sorted() -> [SessionTemplate] { _sorted(_load()) }

    /// Saves a new template. Deduplicates on normalized task text — if a template
    /// with the same task already exists, updates its criteria instead. Trims to
    /// maxTemplates by removing the least-recently-used entry.
    public func add(task: String, successCriteria: String) {
        var templates = _load()
        let key = normalized(task)
        if let idx = templates.firstIndex(where: { normalized($0.task) == key }) {
            templates[idx].successCriteria = successCriteria
        } else {
            let t = SessionTemplate(task: task, successCriteria: successCriteria)
            templates.append(t)
            if templates.count > Self.maxTemplates {
                // Drop the one used least recently.
                templates = Array(_sorted(templates).prefix(Self.maxTemplates))
            }
        }
        _save(templates)
    }

    public func delete(id: UUID) {
        var templates = _load()
        templates.removeAll { $0.id == id }
        _save(templates)
    }

    /// Increments useCount and sets lastUsedAt to now for the given id.
    public func recordUse(id: UUID) {
        var templates = _load()
        guard let idx = templates.firstIndex(where: { $0.id == id }) else { return }
        templates[idx].useCount += 1
        templates[idx].lastUsedAt = Date()
        _save(templates)
    }

    // MARK: - Private helpers

    private func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func _sorted(_ templates: [SessionTemplate]) -> [SessionTemplate] {
        templates.sorted { a, b in
            switch (a.lastUsedAt, b.lastUsedAt) {
            case let (al?, bl?): return al > bl
            case (nil, _?):      return false
            case (_?, nil):      return true
            case (nil, nil):     return a.createdAt > b.createdAt
            }
        }
    }

    private func _load() -> [SessionTemplate] {
        guard
            let data = try? Data(contentsOf: fileURL),
            let decoded = try? JSONDecoder().decode([SessionTemplate].self, from: data)
        else { return [] }
        return decoded
    }

    private func _save(_ templates: [SessionTemplate]) {
        guard let data = try? JSONEncoder().encode(templates) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
