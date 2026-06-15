import Foundation

// MARK: - SessionTemplate

public struct SessionTemplate: Identifiable, Sendable {
    public let id: UUID
    public var task: String
    public var successCriteria: String
    public var useCount: Int
    public var lastUsedAt: Date?
    public let createdAt: Date
    /// Remembered work duration from when this template was last created/updated.
    /// nil = no goal. Applied automatically when launching the template.
    public var preferredDuration: TimeInterval?

    public init(
        id: UUID = UUID(),
        task: String,
        successCriteria: String,
        useCount: Int = 0,
        lastUsedAt: Date? = nil,
        createdAt: Date = Date(),
        preferredDuration: TimeInterval? = nil
    ) {
        self.id = id
        self.task = task
        self.successCriteria = successCriteria
        self.useCount = useCount
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
        self.preferredDuration = preferredDuration
    }
}

// MARK: - Codable (manual for backward-compatible preferredDuration decode)

extension SessionTemplate: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, task, successCriteria, useCount, lastUsedAt, createdAt, preferredDuration
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decode(UUID.self,    forKey: .id)
        task             = try c.decode(String.self,  forKey: .task)
        successCriteria  = try c.decode(String.self,  forKey: .successCriteria)
        useCount         = try c.decode(Int.self,     forKey: .useCount)
        lastUsedAt       = try? c.decode(Date.self,   forKey: .lastUsedAt)
        createdAt        = try c.decode(Date.self,    forKey: .createdAt)
        preferredDuration = try? c.decode(TimeInterval.self, forKey: .preferredDuration)
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,              forKey: .id)
        try c.encode(task,            forKey: .task)
        try c.encode(successCriteria, forKey: .successCriteria)
        try c.encode(useCount,        forKey: .useCount)
        try c.encodeIfPresent(lastUsedAt,        forKey: .lastUsedAt)
        try c.encode(createdAt,       forKey: .createdAt)
        try c.encodeIfPresent(preferredDuration, forKey: .preferredDuration)
    }
}

// MARK: - SessionTemplateStore

public actor SessionTemplateStore {
    public static let shared = SessionTemplateStore()

    private let fileURL: URL
    static let maxTemplates = 10

    private init() {
        // Force unwrap is safe: `.userDomainMask` always resolves to exactly one
        // directory (~/Library/Application Support) on macOS — `urls(for:in:)`
        // never returns an empty array for this combination.
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
    /// with the same task already exists, updates its criteria and preferred duration.
    /// Trims to maxTemplates by removing the least-recently-used entry.
    public func add(task: String, successCriteria: String, preferredDuration: TimeInterval? = nil) {
        var templates = _load()
        let key = normalized(task)
        if let idx = templates.firstIndex(where: { normalized($0.task) == key }) {
            templates[idx].successCriteria = successCriteria
            templates[idx].preferredDuration = preferredDuration
        } else {
            let t = SessionTemplate(
                task: task,
                successCriteria: successCriteria,
                preferredDuration: preferredDuration
            )
            templates.insert(t, at: 0)  // newest template appears first in display order
            if templates.count > Self.maxTemplates {
                // Drop the one used least recently to stay under the cap.
                templates = Array(_sorted(templates).prefix(Self.maxTemplates))
            }
        }
        _save(templates)
    }

    /// Moves templates within the display order and persists the new order.
    /// `fromOffsets` and `toOffset` follow `Array.move(fromOffsets:toOffset:)` semantics
    /// (same as SwiftUI's `.onMove` callback).
    public func reorder(fromOffsets: IndexSet, toOffset: Int) {
        var templates = _load()
        templates.move(fromOffsets: fromOffsets, toOffset: toOffset)
        _save(templates)
    }

    public func delete(id: UUID) {
        var templates = _load()
        templates.removeAll { $0.id == id }
        _save(templates)
    }

    /// Updates the task text, success criteria, and preferred duration for an existing template by ID.
    /// No-op if the ID is not found.
    public func update(id: UUID, task: String, successCriteria: String, preferredDuration: TimeInterval? = nil) {
        var templates = _load()
        guard let idx = templates.firstIndex(where: { $0.id == id }) else { return }
        templates[idx].task = task
        templates[idx].successCriteria = successCriteria
        templates[idx].preferredDuration = preferredDuration
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
        // Use lastUsedAt when available, falling back to createdAt so a newly
        // created template (lastUsedAt == nil) is treated as "used right now"
        // and is never evicted in favour of older templates that happened to
        // have a prior lastUsedAt recorded.
        templates.sorted { a, b in
            let aDate = a.lastUsedAt ?? a.createdAt
            let bDate = b.lastUsedAt ?? b.createdAt
            return aDate > bDate
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
