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
    // "media"  blocks media.discordapp.com (Discord's embedded video/GIF preview CDN): separate from
    //          cdn.discordapp.com — Discord serves embedded GIF previews and video thumbnails through
    //          media.discordapp.com; direct links to these assets bypass the discord.com and cdn. blocks.
    // "lite"   blocks lite.tiktok.com: TikTok's stripped-down regional version available in some markets.
    //          "lite" is not a common legitimate subdomain for productivity tools, so the false-positive
    //          risk is negligible; closing the lite.tiktok.com escape hatch is the main motivation.
    // "player" blocks player.twitch.tv: Twitch's embeddable player iframe used on third-party sites
    //          (news articles, gaming wikis, Reddit embeds). A user whose Twitch app and twitch.tv are
    //          both blocked can still watch a live stream via an embedded player.twitch.tv iframe on an
    //          otherwise-accessible page. "player" is not a common subdomain for productivity tools
    //          (no player.github.com, player.notion.so, etc.) so false-positive risk is negligible.
    // "assets" blocks assets.twitch.tv and similar static-asset CDN subdomains: sprite sheets, fonts,
    //          and UI bundle files served from assets.X that can be independently loaded by cached or
    //          service-worker-backed pages even when the main domain is blocked. Also covers
    //          assets.discord.com and similar patterns on other blocked platforms.
    // "embed"  blocks embed.twitch.tv: the outer embed container page that wraps player.twitch.tv.
    //          Third-party sites load the embed page at embed.twitch.tv/embed/... and player.twitch.tv
    //          as a nested iframe. Blocking player. stops the stream itself; blocking embed. stops the
    //          wrapper page that initialises it. Together they close the full embedded-stream vector.
    //          "embed" is not a common subdomain for productivity tools so the false-positive risk is low.
    // "vod"    blocks vod.twitch.tv: Twitch's video-on-demand archive/clip delivery subdomain.
    //          External links to recorded Twitch content (VODs, highlights, clips published before
    //          the clips.twitch.tv era) can still resolve through vod.twitch.tv even when the main
    //          domain and clips. subdomain are both blocked. Low false-positive risk: no common
    //          productivity tool exposes a vod. subdomain.
    // "static" blocks static.twitch.tv and similar static-resource subdomains. Twitch's service
    //          worker pre-caches static assets under static.twitch.tv; a cached Twitch shell can
    //          continue rendering from static. even when twitch.tv is blocked. Also covers
    //          static.xx.fbcdn.net patterns generated alongside facebook.com. False-positive risk
    //          is low: no common productivity tool (Notion, GitHub, Linear) exposes a static. subdomain.
    // "images" blocks images.google.com (Google's image search — separately routable from google.com
    //          and a significant standalone distraction vector). Also covers images.fandom.com,
    //          images.tmdb.org (movie/TV database thumbnails), and similar entertainment image CDN
    //          subdomains. Low false-positive risk: no common productivity tool exposes an "images."
    //          subdomain. Note: static-cdn.jtvnw.net uses a hyphen ("static-cdn.") and is NOT covered
    //          by this prefix — it must be listed explicitly in defaultBlockedDomains.
    // "auth"   blocks auth.twitch.tv, auth.discord.com, auth.reddit.com, auth.spotify.com, and
    //          similar authentication subdomains on blocked entertainment/social sites. A user whose
    //          top-level domain is blocked can still reach the auth flow via auth.X to log back in or
    //          switch accounts — blocking auth. closes this re-entry vector.
    //          False-positive risk: productivity tools (GitHub, Notion, Linear) are NOT in the default
    //          blocked list, so their auth. subdomains are never generated by this prefix. If a user
    //          manually adds a productivity tool to their block list, auth.X for that tool would also
    //          be blocked — which is correct since the whole tool is blocked.
    // "live"   blocks live.youtube.com (YouTube Live), live.bilibili.com (Bilibili live streaming),
    //          live.kick.com, and similar live-stream page subdomains. YouTube Live is a distinct
    //          subdomain from youtube.com — a user whose youtube.com is blocked can still navigate
    //          directly to live.youtube.com to watch live streams (sports, gaming, concerts) without
    //          touching the main YouTube domain. False-positive risk: no major productivity tool
    //          (GitHub, Notion, Linear, Figma) exposes a "live." subdomain as a primary URL.
    // "gaming" blocks gaming.youtube.com (the legacy YouTube Gaming hub — a directly routable
    //          subdomain that survived the YouTube Gaming → YouTube migration and is still
    //          accessible even when youtube.com itself is blocked). Also covers gaming.amazon.com
    //          (Amazon Prime Gaming portal for free game claims). The "live" prefix already closes
    //          live.youtube.com for streams; "gaming" closes the gaming-hub discovery page
    //          independently. False-positive risk is low: no common productivity tool
    //          (GitHub, Notion, Linear, Figma) exposes a "gaming." subdomain as a navigation target.
    // "watch"  blocks watch.twitch.tv (Twitch's standalone watch page URL scheme, reachable
    //          without touching the twitch.tv homepage — embedded or shared "watch" links use
    //          this subdomain as the canonical destination). Also covers watch.plex.tv
    //          (Plex's web player entry point) and similar direct-watch subdomains on blocked
    //          entertainment platforms. False-positive risk is low: no major productivity tool
    //          (GitHub, Notion, Linear, Figma) exposes a "watch." subdomain as a UI entry point.
    internal nonisolated static let additionalBlockedSubdomainPrefixes: [String] = [
        "m", "mobile", "old", "amp", "en", "music", "tv", "i", "api", "clips",
        "web",    // WhatsApp Web (web.whatsapp.com), Telegram Web (web.telegram.org)
        "app",    // Slack Web App (app.slack.com)
        "go",     // tracking-redirect subdomains (go.twitch.tv etc.)
        "cdn",    // media/attachment CDN subdomains (cdn.discordapp.com etc.)
        "store",  // game store pages (store.steampowered.com, store.epicgames.com)
        "media",  // embedded video/GIF preview CDN (media.discordapp.com etc.)
        "lite",   // stripped-down regional variants (lite.tiktok.com etc.)
        "player", // embeddable player iframes (player.twitch.tv etc.)
        "assets", // static-asset CDN subdomains (assets.twitch.tv etc.)
        "embed",  // embed wrapper pages (embed.twitch.tv etc.)
        "vod",    // video-on-demand delivery subdomains (vod.twitch.tv etc.)
        "static", // pre-cached static resources (static.twitch.tv etc.)
        "images", // image search / image CDN subdomains (images.google.com, images.fandom.com etc.)
        "auth",   // authentication subdomains (auth.twitch.tv, auth.discord.com, auth.reddit.com etc.)
        "live",   // live-stream page subdomains (live.youtube.com, live.bilibili.com, live.kick.com etc.)
        "gaming", // gaming-hub subdomains (gaming.youtube.com, gaming.amazon.com etc.)
        "watch",  // direct-watch subdomains (watch.twitch.tv, watch.plex.tv etc.)
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
