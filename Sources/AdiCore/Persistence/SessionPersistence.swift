import Foundation

/// Persists the active Session to UserDefaults so a crash or relaunch can restore it.
public final class SessionPersistence: Sendable {
    public static let shared = SessionPersistence()
    private let key = "adia.activeSession"
    private init() {}

    public func save(_ session: Session) {
        guard let data = try? JSONEncoder().encode(session) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    public func load() -> Session? {
        guard let data = UserDefaults.standard.data(forKey: key),
              let session = try? JSONDecoder().decode(Session.self, from: data)
        else { return nil }
        // Discard sessions older than 24 hours — they're stale.
        guard session.elapsed < 86_400 else {
            clear()
            return nil
        }
        return session
    }

    public func clear() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}
