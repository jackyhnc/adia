import Foundation

/// Persists the active Session to UserDefaults so a crash or relaunch can restore it.
public final class SessionPersistence: Sendable {
    public static let shared = SessionPersistence()
    private let key = "adia.activeSession"
    private init() {}

    public func save(_ session: Session) {
        do {
            let data = try JSONEncoder().encode(session)
            UserDefaults.standard.set(data, forKey: key)
        } catch {
            AppLogger.error("session_persistence.save_failed", ["error": String(describing: error)])
        }
    }

    public func load() -> Session? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        let session: Session
        do {
            session = try JSONDecoder().decode(Session.self, from: data)
        } catch {
            AppLogger.error("session_persistence.load_decode_failed", ["error": String(describing: error)])
            return nil
        }
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
