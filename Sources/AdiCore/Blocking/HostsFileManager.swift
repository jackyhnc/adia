import Foundation

// Manages /etc/hosts entries for domain blocking.
// Writing /etc/hosts requires root. In production, a privileged XPC helper
// (SMJobBless / SMAppService) performs the write; the main app sends it requests.
// For now the read path is always available; the write path is gated on success.
public actor HostsFileManager {
    public static let shared = HostsFileManager()

    private let hostsPath = "/etc/hosts"
    private static let blockMarkerBegin = "# adia-block-begin"
    private static let blockMarkerEnd   = "# adia-block-end"

    private init() {}

    // MARK: - Public API

    public func block(domains: [String]) async throws {
        var content = try readHosts()
        content = Self.stripped(content)
        content += Self.buildBlock(domains: domains)
        try writeHosts(content)
    }

    public func unblockAll() async throws {
        var content = try readHosts()
        content = Self.stripped(content)
        try writeHosts(content)
    }

    public func currentlyBlocked() throws -> [String] {
        let content = try readHosts()
        return Self.parseBlocked(content)
    }

    // MARK: - Private helpers

    private func readHosts() throws -> String {
        try String(contentsOfFile: hostsPath, encoding: .utf8)
    }

    private func writeHosts(_ content: String) throws {
        try content.write(toFile: hostsPath, atomically: true, encoding: .utf8)
    }

    // MARK: - Pure string helpers (nonisolated static — testable without actor hop)

    // Subdomain prefixes added synthetically alongside every bare domain in the block.
    // Prevents bypass via mobile/alternative site variants (m.reddit.com, old.reddit.com, etc.).
    // parseBlocked skips these so round-trips only return canonical bare domains.
    // "amp"   prevents the Google AMP bypass: amp.reddit.com would otherwise bypass the reddit.com block.
    // "music" blocks music.youtube.com (YouTube Music) which lives on a distinct subdomain.
    // "tv"    blocks tv.youtube.com (YouTube TV) — another escape hatch from the youtube.com block.
    // "i"     blocks image-CDN subdomains: i.reddit.com serves images/media independently of reddit.com.
    // "api"   blocks api.twitter.com and similar endpoints used by third-party clients to load content
    //         through the API even when the main domain (twitter.com) is blocked in the browser.
    // "clips" blocks clips.twitch.tv: Twitch clip share URLs that bypass the top-level twitch.tv block.
    //         Clips are widely embedded/shared and would otherwise be viewable during a session.
    // "web"   blocks web.whatsapp.com (WhatsApp Web) and web.telegram.org (Telegram Web): both are
    //         full-featured messaging clients that run entirely in the browser, bypassing the native
    //         app block (net.whatsapp.WhatsApp / ru.keepcoder.Telegram) when those apps are closed.
    // "app"   blocks app.slack.com (Slack's browser-based web app): the Slack web client lives at
    //         app.slack.com, not slack.com, so blocking slack.com alone leaves the web app open.
    // "go"    blocks go.twitch.tv and similar tracking-redirect subdomains: link shorteners and
    //         campaign tracking use a "go." subdomain that resolves independently of the parent domain.
    // "cdn"   blocks cdn.discordapp.com (Discord's media/attachment CDN): avatars, images, and file
    //         attachments are served from cdn.discordapp.com independently of discord.com — users can
    //         access Discord media via direct CDN links even when discord.com is blocked in the browser.
    // "store" blocks store.steampowered.com and store.epicgames.com: the actual store pages that users
    //         navigate directly to for browsing and purchasing games; the root domains are already blocked
    //         but store.X is a common direct-link target that resolves as a distinct subdomain.
    internal nonisolated static let additionalBlockedSubdomainPrefixes: [String] = [
        "m", "mobile", "old", "amp", "en", "music", "tv", "i", "api", "clips",
        "web",   // WhatsApp Web (web.whatsapp.com), Telegram Web (web.telegram.org)
        "app",   // Slack Web App (app.slack.com)
        "go",    // tracking-redirect subdomains (go.twitch.tv etc.)
        "cdn",   // media/attachment CDN subdomains (cdn.discordapp.com etc.)
        "store", // game store pages (store.steampowered.com, store.epicgames.com)
    ]

    // Walks lines, discarding everything between the adia markers (inclusive).
    internal nonisolated static func stripped(_ content: String) -> String {
        let lines = content.components(separatedBy: "\n")
        var result: [String] = []
        var inBlock = false
        for line in lines {
            if line.hasPrefix(blockMarkerBegin) { inBlock = true; continue }
            if line.hasPrefix(blockMarkerEnd)   { inBlock = false; continue }
            if !inBlock { result.append(line) }
        }
        return result.joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
    }

    internal nonisolated static func buildBlock(domains: [String]) -> String {
        let lines = domains.flatMap { domain -> [String] in
            var entries = ["127.0.0.1 \(domain)", "127.0.0.1 www.\(domain)"]
            for prefix in additionalBlockedSubdomainPrefixes {
                entries.append("127.0.0.1 \(prefix).\(domain)")
            }
            return entries
        }.joined(separator: "\n")
        return "\n\(blockMarkerBegin)\n\(lines)\n\(blockMarkerEnd)\n"
    }

    internal nonisolated static func parseBlocked(_ content: String) -> [String] {
        // All synthetic subdomain prefixes we add — skip them so callers only see bare domains.
        let syntheticPrefixes = (["www"] + additionalBlockedSubdomainPrefixes).map { "\($0)." }
        guard let begin = content.range(of: blockMarkerBegin),
              let end   = content.range(of: blockMarkerEnd),
              begin.upperBound <= end.lowerBound  // malformed content guard
        else { return [] }
        let block = String(content[begin.upperBound..<end.lowerBound])
        return block.components(separatedBy: .newlines)
            .compactMap { line -> String? in
                let parts = line.split(separator: " ")
                guard parts.count == 2, parts[0] == "127.0.0.1" else { return nil }
                let domain = String(parts[1])
                guard !syntheticPrefixes.contains(where: { domain.hasPrefix($0) }) else { return nil }
                return domain
            }
    }
}
