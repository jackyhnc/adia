import Foundation

/// Build-time embedded secrets.
///
/// `apiKey` ships *inside* the app so end users never have to think about API
/// keys — they open Adia and it just works. The value here is intentionally
/// empty in source control; the real production key is injected locally at
/// build time and this file is marked `--skip-worktree` so the secret is never
/// committed.
///
/// ⚠️ A key compiled into a distributed client binary can be extracted by a
/// determined user. For a public launch, route model calls through a backend
/// proxy that holds the key server-side instead of shipping it in the app.
public enum EmbeddedSecrets {
    /// Production Anthropic API key, injected at build time. Empty = not embedded.
    public static let apiKey = ""

    /// Non-empty embedded key, or nil.
    public static var resolvedKey: String? {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
