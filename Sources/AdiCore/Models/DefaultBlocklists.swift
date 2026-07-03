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
        // Southeast Asian e-commerce time sinks
        "lazada.com",
        "shopee.com",
        "tokopedia.com",
        "bukalapak.com",
        // Southeast Asian food/lifestyle rabbit holes
        "grab.com",
        "shopback.com",
        "carousell.com",
        "daraz.pk",         // Pakistani e-commerce — major time sink in South Asia
        "11street.my",      // Malaysian marketplace
        "11street.com.my",  // alternate domain for 11street Malaysia
        // North American / global classifieds — browsed "quickly" and never quickly
        "kijiji.ca",        // Canadian classifieds (Craigslist equivalent)
        "gumtree.com",      // UK/AU secondhand marketplace
        "craigslist.org",   // US/CA classifieds — same rabbit-hole pattern as kijiji
        "vinted.com",       // EU/NA secondhand clothing marketplace
        // Dating apps — habitual loop-openers that pull students/workers out of deep work
        "tinder.com",
        "bumble.com",
        "hinge.co",
        "match.com",
        "okcupid.com",
        "plentyoffish.com",
        "eharmony.com",
        // Travel daydreaming — research for trips that aren't happening yet
        "booking.com",
        "tripadvisor.com",
        "airbnb.com",
        "expedia.com",
        "hotels.com",
        "kayak.com",
        // Food delivery browsing — menu-scrolling instead of working
        "doordash.com",
        "ubereats.com",
        "grubhub.com",
        "deliveroo.com",
        "just-eat.com",
        "just-eat.co.uk",
        // Crypto / finance rabbit holes — charts and portfolios during deep work
        "robinhood.com",
        "coinbase.com",
        "binance.com",
        "etoro.com",
        "coinmarketcap.com",
        "coingecko.com",
        "kraken.com",
        "crypto.com",
        // Job boards — popular procrastination sink for students and knowledge workers
        // ("I'll just check salaries for five minutes" → 40 minutes later)
        "glassdoor.com",
        "indeed.com",
        "seek.com.au",     // Australian job board
        "monster.com",
        "levels.fyi",      // TC/comp browsing, extremely popular with CS students & engineers
        "simplyhired.com",
        // Property browsing — house/apartment daydreaming kills deep work sessions
        "zillow.com",
        "redfin.com",
        "realtor.com",
        "rightmove.co.uk",
        "zoopla.co.uk",
        "domain.com.au",   // Australian property listings
        // Newer short-form social platforms
        "bereal.com",            // BeReal — habit-openers that pull users out of deep work
        "lemon8-app.com",        // ByteDance Lemon8
        // News aggregators — procrastination disguised as staying informed
        "flipboard.com",
        // Image boards and meme archives — notorious deep time sinks
        "4chan.org",
        "4channel.org",      // SFW-branded 4chan alias, same server
        "8kun.top",          // 4chan successor board
        // Remaining browser gaming portals
        "newgrounds.com",    // large flash/game/animation archive
        "gamejolt.com",      // indie game portal (separate from itch.io)
        "itch.io",           // indie game hosting / storefront
        "lagged.com",        // browser games portal
        // Short video clip sharing (fragments of longer YouTube content)
        "streamable.com",
        // European classifieds — same rabbit-hole pattern as kijiji/gumtree
        "leboncoin.fr",      // French classifieds (largest in France)
        "marktplaats.nl",    // Dutch secondhand marketplace
        "tradera.com",       // Swedish marketplace
        "subito.it",         // Italian classifieds
        // Anime / manga streaming (growing student distraction)
        "9anime.to",
        "zoro.to",
        "aniwatch.to",
        // Campus recruiting / homework-help — popular student procrastination sinks
        "handshake.com",     // campus recruiting platform
        "wayup.com",         // entry-level & internship job board
        "internships.com",   // internship aggregator
        "chegg.com",         // homework help / tutoring (often used to cheat rather than learn)
        "coursehero.com",    // uploaded homework solutions — major academic integrity risk
        // Additional sports scores — passive distraction during study sessions
        "theScore.com",
        "cricbuzz.com",      // cricket live scores (popular in South Asia / global)
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
