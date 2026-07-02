import Foundation

// MARK: - Default blocked domains & apps

extension Session {
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
        "theverge.com",
        "techcrunch.com",
        "wired.com",
        "arstechnica.com",
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
        "youtu.be",
        "discord.gg",
        "t.co",
        // Games (serious procrastination trap for students and knowledge workers)
        "chess.com",
        "lichess.org",
        // Reading & creative procrastination (popular with students)
        "webtoons.com",
        "wattpad.com",
        "archiveofourown.org",
        "mangadex.org",
        // Book / film social tracking (rabbit holes disguised as productivity)
        "goodreads.com",
        "letterboxd.com",
        // Lyrics / music knowledge (time sink for music fans)
        "genius.com",
        // Bluesky — growing Twitter alternative (separate domain from bsky.social)
        "bsky.app",
        "bluesky.social",
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
        "redd.it",
        "instagr.am",
        "fb.me",
        // Reddit CDN / media domains
        "i.redd.it",
        "v.redd.it",
        "preview.redd.it",
        "external-preview.redd.it",
        // Twitch legacy CDN domain
        "jtvnw.net",
        "static-cdn.jtvnw.net",
        // Live-streaming platforms (direct Twitch competitors and global alternatives)
        "kick.com",
        "trovo.live",
        // Video platforms (alternative/niche video hosts)
        "rumble.com",
        "dailymotion.com",
        "bilibili.com",
        "odysee.com",
        // Image-hosting platforms
        "imgur.com",
        "giphy.com",
        "tenor.com",
        // Art portfolio / creative procrastination
        "deviantart.com",
        "artstation.com",
        "behance.net",
        "dribbble.com",
        // Video sharing
        "vimeo.com",
        // Photography & stock-media platforms
        "500px.com",
        "unsplash.com",
        "flickr.com",
        "pexels.com",
        "pixabay.com",
        // Social media proxy frontends
        "nitter.net",
        // Gaming platforms
        "roblox.com",
        "itch.io",
        "gog.com",
        "humblebundle.com",
        // Streaming services (beyond core Netflix/Hulu/Disney+)
        "paramountplus.com",
        "discoveryplus.com",
        "mubi.com",
        "tubi.tv",
        "pluto.tv",
        // Regional social networks
        "vk.com",
        // Short-form video platforms
        "triller.co",
        "likee.com",
        // Game key reseller marketplaces
        "g2a.com",
        "kinguin.net",
        // E-commerce expansion
        "bestbuy.com",
        "target.com",
        "wish.com",
        "shein.com",
        "wayfair.com",
        "zalando.com",
        "asos.com",
        // Short-form video (additional)
        "clapper.tv",
        // Regional social networks (Asia-Pacific)
        "weibo.com",
        "line.me",
        "kakaotalk.com",
        // Sports betting and gambling
        "draftkings.com",
        "fanduel.com",
        "bet365.com",
        "pokerstars.com",
        "betway.com",
        "bovada.lv",
        "betmgm.com",
        // Browser-based gaming portals
        "crazygames.com",
        "poki.com",
        "miniclip.com",
        "kongregate.com",
        // Additional online gambling and poker
        "888casino.com",
        "888poker.com",
        "partypoker.com",
        "unibet.com",
        "williamhill.com",
        // Regional social networks (additional)
        "band.us",
        "taringa.net",
        // Additional browser-based gaming portals
        "addictinggames.com",
        "armorgames.com",
        "y8.com",
        // More sports betting / gambling operators
        "ladbrokes.com",
        "paddypower.com",
        "coral.co.uk",
        // Latin American e-commerce
        "mercadolibre.com",
        // Live TV streaming services
        "sling.com",
        "fubo.tv",
        "philo.com",
        // Gambling operators (additional)
        "betfred.com",
        "bwin.com",
        "sky.bet",
        // Browser gaming portals (additional)
        "silvergames.com",
        "friv.com",
        // Global classifieds and marketplaces
        "olx.com",
        // Additional gambling operators
        "betfair.com",
        "888sport.com",
        "sportingbet.com",
        // Additional browser gaming portals
        "kizi.com",
        "agame.com",
        "coolmathgames.com",
        // Free ad-supported streaming
        "crackle.com",
        "fawesome.tv",
        // Streaming aliases and additional
        "peacock.com",
        "plex.tv",
        // International gambling operators
        "1xbet.com",
        "melbet.com",
        "betway.be",
        // Remaining browser gaming portals
        "gameflare.com",
        "iogames.space",
        "spele.lv",
        // Sneaker / streetwear culture time sinks
        "stockx.com",
        "hypebeast.com",
        // Restaurant browsing rabbit holes
        "yelp.com",
        "opentable.com",
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
        BlockedApp(id: "com.twitter.twitter-mac",        name: "Twitter (legacy)"),
        BlockedApp(id: "com.atebits.Tweetie2",           name: "X / Twitter"),
        BlockedApp(id: "com.epicgames.EpicGamesLauncher", name: "Epic Games Launcher"),
        BlockedApp(id: "net.battle.net.client",                 name: "Battle.net"),
        // Signal Desktop — messaging is a focus killer regardless of privacy tier
        BlockedApp(id: "org.whispersystems.signal-desktop",     name: "Signal"),
        // Viber Desktop — messaging app popular outside North America
        BlockedApp(id: "com.viber.osx",                         name: "Viber"),
        // Remote-desktop apps — commonly used for off-task browsing on a second machine
        BlockedApp(id: "com.anydesk.AnyDesk",                   name: "AnyDesk"),
        BlockedApp(id: "com.teamviewer.TeamViewer",              name: "TeamViewer"),
    ]

    public static var defaultBlockedAppBundleIDs: [String] {
        defaultBlockedApps.map(\.id)
    }
}
