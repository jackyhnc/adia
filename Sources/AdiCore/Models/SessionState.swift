import Foundation

// MARK: - Session Phase

public enum SessionPhase: String, Codable, Sendable {
    case idle
    case active
    case verifying
    case complete
    case earlyExitPending
}

// MARK: - On-task classification

public enum OnTaskStatus: String, Codable, Sendable {
    case onTask
    case offTask
    case ambiguous
}

// MARK: - Verification result

public struct VerificationResult: Codable, Sendable {
    public let verified: Bool
    public let explanation: String

    public init(verified: Bool, explanation: String) {
        self.verified = verified
        self.explanation = explanation
    }
}

// MARK: - Verification attempt (one entry in the within-session history)

public struct VerificationAttempt: Codable, Sendable {
    public let timestamp: Date
    public let result: VerificationResult
    /// 1-based index: first attempt = 1.
    public let attemptNumber: Int

    public init(timestamp: Date = Date(), result: VerificationResult, attemptNumber: Int) {
        self.timestamp = timestamp
        self.result = result
        self.attemptNumber = attemptNumber
    }
}

// MARK: - Reasoning attempt (one entry in the within-session reasoning-conversation memory)

/// Records the outcome of a single "argue for site access" conversation so the AI can
/// reference it if the user comes back asking about the same domain again — the PRD
/// calls for the AI to "carry context across attempts within a session."
public struct ReasoningAttempt: Codable, Sendable {
    public let timestamp: Date
    public let domain: String
    public let granted: Bool
    /// Short justification — the AI's final reasoning, truncated for prompt-injection use.
    public let summary: String

    public init(timestamp: Date = Date(), domain: String, granted: Bool, summary: String) {
        self.timestamp = timestamp
        self.domain = domain
        self.granted = granted
        self.summary = summary
    }
}

// MARK: - Session

public struct Session: Sendable, Identifiable {
    public let id: UUID
    public var task: String
    public var successCriteria: String
    public var startTime: Date
    public var phase: SessionPhase
    public var whitelistedDomains: [String]
    public var blockedDomains: [String]
    /// Bundle IDs of apps that trigger an immediate callout when opened.
    public var blockedApps: [String]
    /// Cumulative callouts fired this session. Persisted so tier escalation survives a crash/relaunch.
    public var calloutCount: Int
    /// Verification attempts made this session. Persisted so attempt numbering survives a crash/relaunch.
    public var verificationHistory: [VerificationAttempt]
    /// Optional target work duration in seconds. nil = no goal. Shown as a progress arc in the collapsed notch.
    public var targetDuration: TimeInterval?
    /// Reasoning ("argue for access") conversation outcomes, keyed implicitly by domain.
    /// Lets the AI recall — and call out — repeat asks for the same site within a session.
    public var reasoningHistory: [ReasoningAttempt]
    /// On-task AI classification frames this session. Persisted so focus score survives a crash/relaunch.
    public var onTaskChecks: Int
    /// Total AI classification frames this session. Persisted so focus score survives a crash/relaunch.
    public var totalChecks: Int

    public init(
        id: UUID = UUID(),
        task: String,
        successCriteria: String,
        startTime: Date = Date(),
        phase: SessionPhase = .idle,
        whitelistedDomains: [String] = [],
        blockedDomains: [String] = Session.defaultBlockedDomains,
        blockedApps: [String] = Session.defaultBlockedAppBundleIDs,
        calloutCount: Int = 0,
        verificationHistory: [VerificationAttempt] = [],
        targetDuration: TimeInterval? = nil,
        reasoningHistory: [ReasoningAttempt] = [],
        onTaskChecks: Int = 0,
        totalChecks: Int = 0
    ) {
        self.id = id
        self.task = task
        self.successCriteria = successCriteria
        self.startTime = startTime
        self.phase = phase
        self.whitelistedDomains = whitelistedDomains
        self.blockedDomains = blockedDomains
        self.blockedApps = blockedApps
        self.calloutCount = calloutCount
        self.verificationHistory = verificationHistory
        self.targetDuration = targetDuration
        self.reasoningHistory = reasoningHistory
        self.onTaskChecks = onTaskChecks
        self.totalChecks = totalChecks
    }

    public var elapsed: TimeInterval { Date().timeIntervalSince(startTime) }

    public static let defaultBlockedDomains: [String] = [
        // Social media
        "twitter.com", "x.com",
        "reddit.com",
        "youtube.com",
        "instagram.com",
        "tiktok.com",
        "facebook.com",
        "threads.net",
        "snapchat.com",
        "tumblr.com",
        "pinterest.com",
        // Streaming & gaming
        "netflix.com",
        "twitch.tv",
        "hulu.com",
        "disneyplus.com",
        "primevideo.com",
        "max.com",
        "crunchyroll.com",
        "peacocktv.com",
        "steampowered.com",
        "epicgames.com",
        // Music streaming (passive-listening distraction during deep work)
        "soundcloud.com",
        "bandcamp.com",
        // Messaging & community
        "discord.com",
        // discordapp.com is Discord's infrastructure/CDN domain — separate from discord.com.
        // cdn.discordapp.com serves avatars, images, and file attachments; users can access
        // Discord media via direct CDN links even when discord.com itself is blocked in the browser.
        // The "cdn" subdomain prefix auto-generates cdn.discordapp.com alongside every domain entry.
        // media.discordapp.com (covered by the "media" prefix) serves embedded GIF/video previews.
        "discordapp.com",
        // discordapp.net is Discord's WebRTC and gateway infrastructure domain (separate from discordapp.com).
        // Discord's voice channels and the real-time gateway connect through *.discordapp.net endpoints;
        // blocking discord.com and discordapp.com leaves this infrastructure domain open for direct access.
        "discordapp.net",
        // discordapp.io is Discord's worker / edge-function domain used for Cloudflare Workers,
        // status-page polling, and experimental API endpoints. It is a distinct TLD from discordapp.com
        // and discordapp.net; blocking those two leaves discordapp.io accessible for direct requests.
        "discordapp.io",
        "slack.com",
        "9gag.com",
        // Messaging web clients (web.X bypasses native app blocks when apps are not running)
        // WhatsApp Web (web.whatsapp.com) and Telegram Web (web.telegram.org) are full-featured
        // browser clients — blocking only the native app bundle IDs leaves the web route open.
        "whatsapp.com",
        "telegram.org",
        // Sports
        "espn.com",
        "nba.com",
        "nfl.com",
        "mlb.com",
        "nhl.com",
        "bleacherreport.com",
        "cbssports.com",
        // News & click-bait
        "buzzfeed.com",
        "huffpost.com",
        "msn.com",
        "dailymail.co.uk",
        // Tech news (procrastination in disguise)
        "hacker-news.firebaseapp.com",
        "news.ycombinator.com",
        "theverge.com",              // tech/culture publication: high-engagement, easy "just one article" trap
        "techcrunch.com",            // startup news: intellectually justifiable but rarely task-relevant
        "wired.com",                 // long-form tech culture: same "productive-feeling" trap as medium.com
        "arstechnica.com",           // in-depth tech journalism: reads like research but is rarely task-relevant
        // Professional procrastination
        "linkedin.com",
        // Shopping
        "amazon.com",
        "ebay.com",
        "etsy.com",
        "aliexpress.com",
        "walmart.com",
        // News (procrastination disguised as staying informed)
        "cnn.com",
        "foxnews.com",
        "bbc.com",
        "theguardian.com",
        // Other time sinks
        "quora.com",
        "fandom.com",
        // Bypass short-link domains (circumvent parent domain blocks if not listed separately)
        "youtu.be",              // YouTube's short URL — bypasses the youtube.com block
        "discord.gg",            // Discord invite links — separate domain from discord.com
        "t.co",                  // Twitter's link shortener — follows the twitter.com block
        // Games (serious procrastination trap for students and knowledge workers)
        "chess.com",
        "lichess.org",
        // Reading & creative procrastination (popular with students)
        "webtoons.com",
        "wattpad.com",
        "archiveofourown.org",   // fanfiction — extremely time-consuming
        "mangadex.org",
        // Professional procrastination
        "producthunt.com",
        // Music streaming — web player bypasses the app block (com.spotify.client)
        "spotify.com",
        // Long-form reading rabbit holes (knowledge workers & students)
        "medium.com",
        "substack.com",
        // Major news sites (procrastination disguised as staying informed)
        "nytimes.com",
        "washingtonpost.com",
        "npr.org",
        "apnews.com",
        // Social platform short-link bypass domains (completely separate DNS names from parent)
        "redd.it",               // Reddit's own short URL (redd.it/abc123) — bypasses reddit.com block
        "instagr.am",            // Instagram's short URL — bypasses instagram.com block
        "fb.me",                 // Facebook's short URL — bypasses facebook.com block
        // Reddit CDN / media domains — served from completely separate hostnames; blocking
        // reddit.com alone does NOT prevent access to these image/video CDN endpoints.
        "i.redd.it",                  // Reddit's image CDN: inline images in posts/comments
        "v.redd.it",                  // Reddit's video CDN: hosted video player embeds
        "preview.redd.it",            // Reddit's preview CDN: link/image previews in feeds
        "external-preview.redd.it",   // Reddit's external-link preview CDN: thumbnails for links posted to reddit
        // Twitch legacy CDN domain (Justin.tv origin, still used by Twitch for thumbnails and media).
        // jtvnw.net is a completely separate TLD from twitch.tv — blocking twitch.tv does NOT cover
        // jtvnw.net. Twitch continues to serve profile images, game box art, stream thumbnails, and
        // clip preview frames from *.jtvnw.net CDN endpoints. External links (Reddit, Discord) often
        // embed these thumbnails directly, providing a visual Twitch experience even when twitch.tv is
        // blocked. The "static" prefix rule generates static.jtvnw.net; the "cdn" prefix generates
        // cdn.jtvnw.net. Both are auto-blocked alongside jtvnw.net.
        "jtvnw.net",
        // static-cdn.jtvnw.net is Twitch's primary image/thumbnail CDN endpoint and the single
        // most-used *.jtvnw.net hostname. The subdomain uses a hyphen ("static-cdn"), not a dot, so
        // the prefix mechanism — which generates "prefix.domain" entries — does NOT cover it.
        // static-cdn.jtvnw.net must be listed as an explicit literal entry here.
        // Twitch serves nearly all profile images, game box art, and stream preview thumbnails from
        // this hostname; Reddit and Discord frequently embed these URLs directly in posts and messages.
        "static-cdn.jtvnw.net",
        // Live-streaming platforms (direct Twitch competitors and global alternatives)
        // kick.com — major live-streaming platform that has overtaken Twitch for some audiences;
        //   popular for gaming, IRL streaming, and often recommended as a "Twitch alternative"
        //   that users switch to mid-session when twitch.tv is blocked.
        "kick.com",
        // trovo.live — Tencent's live-streaming platform (direct Twitch competitor in Asia and
        //   globally); separate TLD from any other blocked domain, not covered by any existing rule.
        "trovo.live",
        // Video platforms (alternative/niche video hosts that are standalone time sinks)
        // rumble.com — video platform popular for news, commentary, and entertainment; users
        //   may pivot to it mid-session when youtube.com is blocked.
        "rumble.com",
        // dailymotion.com — long-form video platform; one of the oldest YouTube alternatives
        //   and a common landing page for embedded video content from news and entertainment sites.
        "dailymotion.com",
        // bilibili.com — dominant video/anime/streaming platform in China and popular globally
        //   for anime, gaming content, and long-form video essays; separate domain from any
        //   existing blocked entry.
        "bilibili.com",
        // odysee.com — decentralized video platform (formerly LBRY); hosts news, gaming, and
        //   entertainment content; commonly linked from Reddit and Discord as a YouTube alternative.
        "odysee.com",
        // Image-hosting platforms (major standalone procrastination vectors)
        // imgur.com — the primary image host used throughout Reddit, Discord, and social media.
        //   Even with reddit.com blocked, users navigate directly to imgur.com to browse meme
        //   galleries, viral posts, and the Imgur front page — which is a full discovery feed.
        //   Among the highest-engagement "one more scroll" time sinks outside of mainstream
        //   social media. cdn.imgur.com and i.imgur.com (image CDN) are auto-generated by the
        //   "cdn" and "i" subdomain prefix rules.
        "imgur.com",
        // giphy.com — GIF discovery platform; heavily linked from Slack, Discord, and Twitter.
        //   Users browse Giphy directly for entertainment; also a distraction entry point when
        //   someone follows a GIF link from a messaging app.
        "giphy.com",
        // tenor.com — Google-owned GIF platform, the primary GIF source in many messaging apps
        //   (including Android messages). Direct navigation to tenor.com leads to browse mode.
        "tenor.com",
        // Art portfolio / creative procrastination (design students and knowledge workers)
        // deviantart.com — longstanding art community with a high-engagement gallery feed.
        //   Browsing the "Popular" and "Newest" sections is passive and deeply habitual.
        //   The "looking for reference or inspiration" justification is among the most common
        //   self-deceptions that bring design/art students to gallery sites during work.
        "deviantart.com",
        // artstation.com — professional concept art / game art portfolio platform.
        //   "Trending" and "New" feeds function identically to social media discovery feeds.
        //   Especially distracting for design, game-development, and animation students, who
        //   visit under the guise of "studying professional work" during their own project time.
        "artstation.com",
        // behance.net — Adobe's creative portfolio and discovery platform. High-engagement
        //   curated-gallery browse feed (categories, "Moodboards", project showcases).
        //   Students — especially graphic design and UX students — fall into "what does good
        //   design look like?" browsing loops that are almost always displacement activity.
        "behance.net",
        // dribbble.com — UI/UX and graphic design community. "Shots" (polished design
        //   screenshots) are engineered for rapid visual consumption and share well via link.
        //   Algorithmically ranked and infinitely scrollable; a very common trap for CS and
        //   design students who rationalise time on Dribbble as professional development.
        "dribbble.com",
        // Video sharing (non-streaming, but significant discovery-feed distraction)
        // vimeo.com — premium/professional video hosting with curated "Staff Picks" and a
        //   high-quality discovery browse page. More engaging than its professional reputation
        //   implies: algorithmically promoted short films, animations, and creative work.
        //   "Looking for video examples / reference for my presentation" is the primary
        //   rationalization students and knowledge workers use to justify extended Vimeo browsing.
        "vimeo.com",
        // Photography & stock-media platforms (discovery-feed time sinks)
        // 500px.com — dedicated photography community with an infinitely scrollable gallery
        //   ("Discover" and "Popular" grids). Presents as a portfolio tool but the
        //   browse/discover surface is the primary UX entry point. Same engagement pattern as
        //   DeviantArt but for photography students and photographers specifically.
        "500px.com",
        // unsplash.com — free stock photo platform with a prominent "Editorial" and "Trending"
        //   discover feed on the homepage and /explore route. "Finding images for my project /
        //   presentation" is the most common rationalization; the discover section is high-quality,
        //   scroll-optimised, and leads deep into visual rabbit holes.
        "unsplash.com",
        // flickr.com — long-form photography sharing with high-engagement "Explore" and group
        //   gallery feeds. Similar engagement profile to 500px but with social/community layers
        //   (groups, contacts, comments) that extend browse session length further.
        "flickr.com",
        // pexels.com — free stock photo and video platform with a "Trending" discover feed and
        //   curated editorial collections. The video discover section (trending short clips) is
        //   particularly habit-forming alongside the photo discovery grid.
        "pexels.com",
        // pixabay.com — free stock image and video library with discovery browse
        //   ("Latest", "Popular", "Editors' Choice"). Same engage-to-browse pattern as
        //   unsplash and pexels; technically-minded users often pivot between all three.
        "pixabay.com",
        // Social media proxy frontends (privacy-preserving mirrors that serve blocked platforms'
        // content at a different domain, bypassing the parent-domain block)
        // nitter.net — the most widely deployed public Nitter instance: a lightweight
        //   Twitter/X frontend that renders the full tweet timeline, profile pages, search,
        //   and media without requiring a Twitter account. Technically-aware users navigate
        //   here directly when twitter.com and x.com are blocked to access the same content.
        //   The proxy-frontend ecosystem is dynamic, but nitter.net is the canonical single
        //   well-known domain that warrants an explicit block entry.
        "nitter.net",
        // Gaming platforms (dedicated distraction vectors for the student demographic)
        // roblox.com — the Roblox platform website (game browser, Roblox Studio launcher,
        //   account/avatar management). Particularly high-engagement for teen and young-adult
        //   students; blocking the website also intercepts the web-based game launcher flow.
        "roblox.com",
        // itch.io — indie game marketplace with a high-engagement "Popular" and "On Sale"
        //   browse feed. Popular with CS, game-development, and design students who rationalise
        //   browsing as "looking for project inspiration". The time-limited-sale urgency pattern
        //   significantly extends dwell time.
        "itch.io",
        // gog.com — DRM-free PC game store (CD Projekt). Distinct "Discover" and "Sale"
        //   sections with curated deals. Game-store browsing during study is a common
        //   displacement activity; the "wait, that's a good deal" pattern is hard to escape.
        "gog.com",
        // humblebundle.com — game bundle store with countdown-timer FOMO UX and a monthly
        //   subscription tier. Students visit "just to check what's on sale" and stay far
        //   longer than intended due to the time-pressure mechanics.
        "humblebundle.com",
        // Additional streaming services (beyond the core Netflix/Hulu/Disney+/etc. already blocked)
        // paramountplus.com — Paramount+ (CBS library, Paramount releases, originals).
        //   A student who can't load Netflix or Hulu may open Paramount+ without thinking twice.
        "paramountplus.com",
        // discoveryplus.com — Discovery+ (nature documentaries, reality TV, cooking, home shows).
        //   Students frequently rationalise this as "educational" (Planet Earth, MythBusters);
        //   the "just one episode" pattern is especially strong for documentary formats.
        "discoveryplus.com",
        // mubi.com — curated art-house and independent film streaming.
        //   Popular with film studies, media arts, and humanities students who frame it as
        //   "cultural enrichment". The platform's prestige ("real cinema") makes it feel more
        //   legitimate than Netflix — same outcome, harder to self-interrupt.
        "mubi.com",
        // tubi.tv — free ad-supported streaming with a broad genre library (AVOD).
        //   No subscription barrier means zero friction: "it's free, just a quick break."
        //   The label "free" lowers the self-interruption threshold significantly.
        "tubi.tv",
        // pluto.tv — free live-channel and on-demand streaming (Paramount-owned AVOD).
        //   The live-channel / "channel surfing" UX auto-plays continuously, replicating
        //   broadcast TV's low-cognitive-effort consumption pattern — hard to consciously stop.
        "pluto.tv",
        // Regional social networks (significant distraction for non-Western-market students)
        // vk.com — VKontakte, Russia's largest social network (~100M monthly active users).
        //   Functionally equivalent to Facebook: news feed, messaging, video, groups.
        //   A significant distraction vector for Eastern European students in particular.
        "vk.com",
        // Short-form video platforms (TikTok competitors — separate domains, not covered by tiktok.com)
        // triller.co — music-centric short-form video app; replicates TikTok's infinite-scroll
        //   autoplay-next format. Gained traction during TikTok regulatory uncertainty and
        //   retains a dedicated user base. A student whose tiktok.com is blocked may switch here.
        "triller.co",
        // likee.com — Kwai-owned short-form video platform popular in emerging markets and
        //   among teen demographics globally. The "For You" discovery feed is algorithmically
        //   optimised for maximum engagement; same format as TikTok.
        "likee.com",
        // Game key reseller marketplaces (impulse purchase and "just checking prices" time sinks)
        // g2a.com — the largest grey-market game key reseller. Students browse for cheap game
        //   keys; the deal-discovery and compare-prices UX drives long dwell time.
        //   "Just checking prices" is among the most common student rationalisations.
        "g2a.com",
        // kinguin.net — second-largest game key reseller (direct G2A competitor). Same
        //   engagement pattern: browse discounts, compare prices, flash sales.
        "kinguin.net",
        // E-commerce expansion (impulse shopping during study sessions)
        // bestbuy.com — consumer electronics retailer with prominent "Deals" sections,
        //   top-seller feeds, and flash sales. "Checking hardware/software prices for my project"
        //   is the standard rationalization; browse sessions run long regardless.
        "bestbuy.com",
        // target.com — general merchandise retailer with a highly polished browse UX
        //   ("Trending", "Deals", category exploration). Students visit for dorm/lifestyle
        //   items and stay in the product-discovery loop far longer than intended.
        "target.com",
        // wish.com — discount marketplace with an extremely addictive infinite-scroll product
        //   feed. Among the highest engagement-per-visit metrics in e-commerce; "just browsing
        //   deals" reliably extends into 30+ minute sessions.
        "wish.com",
        // shein.com — ultra-fast-fashion e-commerce with infinite-scroll discovery, flash
        //   discounts, and gamified daily check-in rewards. Highly optimised for maximum browse
        //   session length; one of the most engagement-addictive shopping UX patterns among
        //   student demographics.
        "shein.com",
        // Additional e-commerce (home, fashion, furniture — high-dwell browse sessions)
        // wayfair.com — online home furniture and décor megastore. "Daily Sales" and trending
        //   product feeds combined with room-inspiration galleries create very long dwell times.
        //   Students with their own apartments particularly rationalise Wayfair browsing as
        //   "necessary research" for furnishing decisions that are not urgent.
        "wayfair.com",
        // zalando.com — Europe's leading fashion e-commerce platform. Strong "New In" and "Trends"
        //   discovery UX; widely used by European students; high infinite-scroll engagement.
        "zalando.com",
        // asos.com — UK-based global fast-fashion retailer with "New In" (hundreds of daily new
        //   items), flash sales, and a "Trending" discovery surface. Among the most scroll-
        //   optimised fashion browse experiences; commonly used by student demographics worldwide.
        "asos.com",
        // Short-form video (additional platform)
        // clapper.tv — US-market short-form video app positioned as a TikTok alternative for
        //   adult/creator demographics; gained traction during TikTok regulatory uncertainty.
        //   Same autoplay-next infinite scroll format as TikTok; separate TLD.
        "clapper.tv",
        // Regional social networks (Asia-Pacific)
        // weibo.com — China's dominant microblogging platform (~600 M MAU). Functionally combines
        //   Twitter's trending/hashtag discovery with Instagram's image/video feed and fan community
        //   groups. A significant distraction for Chinese international students who have the app
        //   as their primary social network; the algorithmically ranked feed is highly engaging.
        "weibo.com",
        // line.me — LINE's web portal; LINE is the dominant messaging and social platform in Japan,
        //   Taiwan, Thailand, and Indonesia. The web interface exposes chat, the NEWS feed (curated
        //   trending articles and video clips), and OpenChat community rooms — all accessible via
        //   browser without the native app. International students from these markets check LINE
        //   frequently throughout the day; the news/video feed extends sessions far beyond messaging.
        "line.me",
        // kakaotalk.com — KakaoTalk's web interface; dominant messaging platform in South Korea with
        //   ~47 M monthly active users domestically and a large diaspora abroad. The KakaoStory social
        //   feed (photo posts, comments, reactions) is accessible through the web client alongside
        //   messaging — a full social browsing session is possible without opening the native app.
        "kakaotalk.com",
        // Sports betting and gambling (high-impulse distraction, major for male student demographic)
        // draftkings.com — leading US daily fantasy sports and sports betting platform. Push
        //   notifications for line movements, in-play live betting UI, and contest lobbies with
        //   countdown timers are designed for maximum re-engagement. The FOMO mechanics are
        //   especially effective during live games (NFL Sundays, NBA nights).
        "draftkings.com",
        // fanduel.com — DraftKings' primary US competitor; full sportsbook + daily fantasy + online
        //   casino. Same live-betting and contest-lobby engagement patterns. The two platforms
        //   split the DFS market and have the highest US sports-betting ad spend per impression.
        "fanduel.com",
        // bet365.com — dominant global online sportsbook (UK/international). All major sports,
        //   real-time in-play betting with sub-second odds updates, streaming of live events within
        //   the platform. One of the highest-engagement betting UIs globally — the in-play section
        //   alone is designed to hold attention for hours across concurrent matches.
        "bet365.com",
        // pokerstars.com — world's largest online poker platform by player traffic. Poker sessions
        //   are among the longest deep-engagement time sinks in the gambling category: 30-90 minute
        //   tournament structures make it extremely hard to stop mid-session. "Just one more hand"
        //   is a well-documented cognitive trap. Particularly prevalent in computer science and
        //   mathematics student communities where card-game strategy is intellectually rationalised.
        "pokerstars.com",
        // betway.com — major global sports betting operator (UK-licensed, European/African markets).
        //   Prominent sponsorships (esports, Premier League) make it highly visible to young male
        //   demographics; the in-play betting UI mirrors bet365 in engagement design.
        "betway.com",
        // bovada.lv — leading US-facing online sportsbook and casino operating under a .lv (Latvian)
        //   TLD. Most well-known US-accessible book; combined sportsbook, casino, and poker lobby.
        //   A .lv TLD is not covered by any existing block rule — must be listed explicitly.
        "bovada.lv",
        // betmgm.com — MGM Resorts' digital sportsbook and online casino. Major US market presence
        //   with aggressive TV ad spend targeting sports viewers. The casino tab (slots, live tables)
        //   adjacent to the sportsbook extends sessions well beyond the original sports-check intent.
        "betmgm.com",
    ]

    public static let defaultBlockedApps: [BlockedApp] = [
        BlockedApp(id: "com.hnc.Discord",               name: "Discord"),
        BlockedApp(id: "com.valvesoftware.steam",        name: "Steam"),
        BlockedApp(id: "tv.twitch.twitch-client",        name: "Twitch"),
        BlockedApp(id: "net.whatsapp.WhatsApp",          name: "WhatsApp"),
        BlockedApp(id: "ru.keepcoder.Telegram",          name: "Telegram"),
        BlockedApp(id: "com.apple.TV",                   name: "Apple TV"),
        BlockedApp(id: "com.burbn.instagram",            name: "Instagram"),
        BlockedApp(id: "com.facebook.Facebook",          name: "Facebook"),
        BlockedApp(id: "com.spotify.client",             name: "Spotify"),
        BlockedApp(id: "com.tencent.xinWeChat",          name: "WeChat"),
        BlockedApp(id: "com.apple.Music",                name: "Apple Music"),
        BlockedApp(id: "com.apple.podcasts",             name: "Podcasts"),
        BlockedApp(id: "com.netflix.Netflix",            name: "Netflix"),
        BlockedApp(id: "com.reddit.Reddit",              name: "Reddit"),
        BlockedApp(id: "com.mojang.minecraftlauncher",   name: "Minecraft"),
        // Twitter/X ships two distinct bundle IDs on macOS:
        // - com.twitter.twitter-mac: the legacy native Mac app (pre-2022)
        // - com.atebits.Tweetie2: the Mac Catalyst port of the iOS app (current X app)
        // Both must be listed to catch whichever variant is installed.
        BlockedApp(id: "com.twitter.twitter-mac",        name: "Twitter (legacy)"),
        BlockedApp(id: "com.atebits.Tweetie2",           name: "X / Twitter"),
        // epicgames.com is already blocked via /etc/hosts, but the Epic Games Launcher
        // is a standalone macOS app (distinct bundle ID) that shows the full store browse
        // interface locally without requiring a live connection to epicgames.com. Opening
        // the launcher to "check what's free this week" is a classic student time sink.
        BlockedApp(id: "com.epicgames.EpicGamesLauncher", name: "Epic Games Launcher"),
        // Battle.net is Blizzard's game client and storefront. Opening it to "check patch
        // notes" or browse the shop is a classic gamer procrastination pattern. The launcher
        // shows the full store/news UI locally — blocking battle.net via /etc/hosts alone
        // does not prevent the app from launching and displaying cached content.
        BlockedApp(id: "net.battle.net.client", name: "Battle.net"),
    ]

    public static var defaultBlockedAppBundleIDs: [String] {
        defaultBlockedApps.map(\.id)
    }
}

// MARK: - Codable (manual for backward-compatible field decode)

extension Session: Codable {
    private enum CodingKeys: String, CodingKey {
        case id, task, successCriteria, startTime, phase
        case whitelistedDomains, blockedDomains, blockedApps, calloutCount
        case verificationHistory, targetDuration, reasoningHistory
        case onTaskChecks, totalChecks
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id                 = try c.decode(UUID.self,          forKey: .id)
        task               = try c.decode(String.self,        forKey: .task)
        successCriteria    = try c.decode(String.self,        forKey: .successCriteria)
        startTime          = try c.decode(Date.self,          forKey: .startTime)
        phase              = try c.decode(SessionPhase.self,  forKey: .phase)
        whitelistedDomains = try c.decode([String].self,      forKey: .whitelistedDomains)
        blockedDomains     = try c.decode([String].self,      forKey: .blockedDomains)
        // Gracefully decode missing key (old sessions pre-app-blocking).
        blockedApps = (try? c.decode([String].self, forKey: .blockedApps))
            ?? Session.defaultBlockedAppBundleIDs
        // Gracefully decode missing key (old sessions pre-callout-persistence).
        calloutCount = (try? c.decode(Int.self, forKey: .calloutCount)) ?? 0
        // Gracefully decode missing key (old sessions pre-verification-history).
        verificationHistory = (try? c.decode([VerificationAttempt].self, forKey: .verificationHistory)) ?? []
        // Gracefully decode missing key (old sessions without duration goal).
        targetDuration = try? c.decode(TimeInterval.self, forKey: .targetDuration)
        // Gracefully decode missing key (old sessions pre-reasoning-memory).
        reasoningHistory = (try? c.decode([ReasoningAttempt].self, forKey: .reasoningHistory)) ?? []
        // Gracefully decode missing key (old sessions pre-focus-score-persistence).
        onTaskChecks = (try? c.decode(Int.self, forKey: .onTaskChecks)) ?? 0
        totalChecks  = (try? c.decode(Int.self, forKey: .totalChecks))  ?? 0
    }

    public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,                  forKey: .id)
        try c.encode(task,                forKey: .task)
        try c.encode(successCriteria,     forKey: .successCriteria)
        try c.encode(startTime,           forKey: .startTime)
        try c.encode(phase,               forKey: .phase)
        try c.encode(whitelistedDomains,  forKey: .whitelistedDomains)
        try c.encode(blockedDomains,      forKey: .blockedDomains)
        try c.encode(blockedApps,         forKey: .blockedApps)
        try c.encode(calloutCount,        forKey: .calloutCount)
        try c.encode(verificationHistory, forKey: .verificationHistory)
        try c.encodeIfPresent(targetDuration, forKey: .targetDuration)
        try c.encode(reasoningHistory,    forKey: .reasoningHistory)
        try c.encode(onTaskChecks,        forKey: .onTaskChecks)
        try c.encode(totalChecks,         forKey: .totalChecks)
    }
}
