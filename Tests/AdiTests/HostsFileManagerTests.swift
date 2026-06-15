import Testing
@testable import AdiCore

@Suite("HostsFileManager")
struct HostsFileManagerTests {

    @Test func defaultBlockedDomainsContainsExpectedSites() {
        let domains = Session.defaultBlockedDomains
        #expect(domains.contains("twitter.com"))
        #expect(domains.contains("youtube.com"))
        #expect(domains.contains("reddit.com"))
    }

    @Test func noDuplicatesInDefaultBlockedList() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count)
    }

    // MARK: - stripped

    @Test func strippedRemovesAdiaBoundsAndContent() {
        let raw = "127.0.0.1 localhost\n# adia-block-begin\n127.0.0.1 youtube.com\n# adia-block-end\n"
        let result = HostsFileManager.stripped(raw)
        #expect(result.contains("127.0.0.1 localhost"))
        #expect(!result.contains("adia-block"))
        #expect(!result.contains("youtube.com"))
    }

    @Test func strippedPassesThroughContentWithNoBlock() {
        let original = "127.0.0.1 localhost\n255.255.255.255 broadcasthost\n"
        let result = HostsFileManager.stripped(original)
        #expect(result.contains("localhost"))
        #expect(result.contains("broadcasthost"))
    }

    @Test func strippedOnEmptyStringReturnsNewline() {
        let result = HostsFileManager.stripped("")
        #expect(result == "\n")
    }

    @Test func strippedHandlesMultipleDomainsInBlock() {
        let raw = """
        127.0.0.1 localhost
        # adia-block-begin
        127.0.0.1 youtube.com
        127.0.0.1 www.youtube.com
        127.0.0.1 reddit.com
        127.0.0.1 www.reddit.com
        # adia-block-end
        """
        let result = HostsFileManager.stripped(raw)
        #expect(result.contains("127.0.0.1 localhost"))
        #expect(!result.contains("youtube.com"))
        #expect(!result.contains("reddit.com"))
        #expect(!result.contains("adia-block"))
    }

    // MARK: - buildBlock

    @Test func buildBlockContainsBothWWWAndBareDomains() {
        let block = HostsFileManager.buildBlock(domains: ["youtube.com"])
        #expect(block.contains("127.0.0.1 youtube.com"))
        #expect(block.contains("127.0.0.1 www.youtube.com"))
    }

    @Test func buildBlockIncludesMobileSubdomains() {
        let block = HostsFileManager.buildBlock(domains: ["reddit.com"])
        for prefix in HostsFileManager.additionalBlockedSubdomainPrefixes {
            #expect(block.contains("127.0.0.1 \(prefix).reddit.com"),
                    "expected \(prefix).reddit.com in block")
        }
    }

    @Test func buildBlockMobileSubdomainsForMultipleDomains() {
        let block = HostsFileManager.buildBlock(domains: ["reddit.com", "twitter.com"])
        #expect(block.contains("127.0.0.1 m.reddit.com"))
        #expect(block.contains("127.0.0.1 m.twitter.com"))
        #expect(block.contains("127.0.0.1 old.reddit.com"))
    }

    @Test func buildBlockIncludesEnSubdomain() {
        // "en" prefix blocks en.wikipedia.org when Wikipedia is on a custom blocked list.
        let block = HostsFileManager.buildBlock(domains: ["wikipedia.org"])
        #expect(block.contains("127.0.0.1 en.wikipedia.org"),
                "en.wikipedia.org must be blocked to prevent bypass via language subdomain")
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("en"))
    }

    @Test func buildBlockWrapsWithMarkers() {
        let block = HostsFileManager.buildBlock(domains: ["reddit.com"])
        #expect(block.contains("# adia-block-begin"))
        #expect(block.contains("# adia-block-end"))
    }

    @Test func buildBlockEmptyDomainsProducesEmptySection() {
        let block = HostsFileManager.buildBlock(domains: [])
        #expect(block.contains("# adia-block-begin"))
        #expect(block.contains("# adia-block-end"))
        #expect(!block.contains("127.0.0.1"))
    }

    @Test func buildBlockMultipleDomains() {
        let block = HostsFileManager.buildBlock(domains: ["a.com", "b.com"])
        #expect(block.contains("127.0.0.1 a.com"))
        #expect(block.contains("127.0.0.1 www.a.com"))
        #expect(block.contains("127.0.0.1 b.com"))
        #expect(block.contains("127.0.0.1 www.b.com"))
    }

    // MARK: - parseBlocked

    @Test func parseBlockedExtractsBareDomains() {
        let content = """
        127.0.0.1 localhost
        # adia-block-begin
        127.0.0.1 youtube.com
        127.0.0.1 www.youtube.com
        127.0.0.1 reddit.com
        127.0.0.1 www.reddit.com
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains.contains("youtube.com"))
        #expect(domains.contains("reddit.com"))
        #expect(!domains.contains("www.youtube.com"))
        #expect(!domains.contains("www.reddit.com"))
        #expect(domains.count == 2)
    }

    @Test func parseBlockedSkipsMobileSubdomainVariants() {
        // Content manually crafted with m./mobile./old. entries — all should be filtered.
        let content = """
        # adia-block-begin
        127.0.0.1 reddit.com
        127.0.0.1 www.reddit.com
        127.0.0.1 m.reddit.com
        127.0.0.1 mobile.reddit.com
        127.0.0.1 old.reddit.com
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["reddit.com"])
        #expect(!domains.contains("www.reddit.com"))
        #expect(!domains.contains("m.reddit.com"))
        #expect(!domains.contains("mobile.reddit.com"))
        #expect(!domains.contains("old.reddit.com"))
    }

    @Test func buildThenParseRoundTripIncludesMobileEntries() {
        // buildBlock now emits m./mobile./old. rows; parseBlocked must still return bare domains only.
        let input = ["reddit.com", "twitter.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        // Sanity-check that the block actually has mobile entries before testing the filter.
        #expect(block.contains("127.0.0.1 m.reddit.com"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input))
    }

    @Test func parseBlockedReturnsEmptyWhenNoMarkers() {
        let content = "127.0.0.1 localhost\n"
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains.isEmpty)
    }

    @Test func parseBlockedReturnsEmptyWhenBlockIsEmpty() {
        let content = "127.0.0.1 localhost\n# adia-block-begin\n# adia-block-end\n"
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains.isEmpty)
    }

    // MARK: - Round-trip

    @Test func buildThenParseRoundTrip() {
        let domains = ["twitter.com", "reddit.com", "youtube.com"]
        let block = HostsFileManager.buildBlock(domains: domains)
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(domains))
    }

    @Test func strippedThenBuildRoundTrip() {
        let original = "127.0.0.1 localhost\n"
        let withBlock = original + HostsFileManager.buildBlock(domains: ["youtube.com"])
        let stripped = HostsFileManager.stripped(withBlock)
        #expect(stripped.contains("localhost"))
        #expect(!stripped.contains("youtube.com"))
        // Re-blocking with a different domain should replace cleanly
        let reBlocked = stripped + HostsFileManager.buildBlock(domains: ["reddit.com"])
        #expect(!reBlocked.contains("youtube.com"))
        #expect(reBlocked.contains("reddit.com"))
    }

    // MARK: - AMP subdomain blocking

    @Test func buildBlockIncludesAmpSubdomain() {
        let block = HostsFileManager.buildBlock(domains: ["reddit.com"])
        #expect(block.contains("127.0.0.1 amp.reddit.com"),
                "amp.reddit.com must be blocked to prevent Google AMP bypass")
    }

    @Test func ampSubdomainPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("amp"))
    }

    @Test func parseBlockedFiltersAmpSubdomain() {
        let content = """
        # adia-block-begin
        127.0.0.1 reddit.com
        127.0.0.1 www.reddit.com
        127.0.0.1 m.reddit.com
        127.0.0.1 mobile.reddit.com
        127.0.0.1 old.reddit.com
        127.0.0.1 amp.reddit.com
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["reddit.com"])
        #expect(!domains.contains("amp.reddit.com"))
    }

    @Test func buildThenParseRoundTripWithAmp() {
        let input = ["reddit.com", "theguardian.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        #expect(block.contains("127.0.0.1 amp.reddit.com"))
        #expect(block.contains("127.0.0.1 amp.theguardian.com"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input))
    }

    // MARK: - music / tv subdomain blocking (YouTube sub-services)

    @Test func buildBlockIncludesMusicSubdomain() {
        // music.youtube.com (YouTube Music) lives on a distinct subdomain not covered
        // by blocking youtube.com alone — the "music" prefix closes this bypass.
        let block = HostsFileManager.buildBlock(domains: ["youtube.com"])
        #expect(block.contains("127.0.0.1 music.youtube.com"),
                "music.youtube.com must be blocked to prevent YouTube Music bypass")
    }

    @Test func musicPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("music"),
                "\"music\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func buildBlockIncludesTVSubdomain() {
        // tv.youtube.com (YouTube TV) is another live YouTube subdomain that bypasses
        // the youtube.com block without an explicit "tv" prefix entry.
        let block = HostsFileManager.buildBlock(domains: ["youtube.com"])
        #expect(block.contains("127.0.0.1 tv.youtube.com"),
                "tv.youtube.com must be blocked to prevent YouTube TV bypass")
    }

    @Test func tvPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("tv"),
                "\"tv\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func buildThenParseRoundTripWithMusicAndTVPrefixes() {
        // Verify that the extra subdomain rows don't corrupt parseBlocked's output.
        let input = ["youtube.com", "discord.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        #expect(block.contains("127.0.0.1 music.youtube.com"))
        #expect(block.contains("127.0.0.1 tv.youtube.com"))
        #expect(block.contains("127.0.0.1 music.discord.com"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input), "parseBlocked must still return only bare domains after music/tv rows are present")
    }

    @Test func parseBlockedFiltersMusicAndTVSubdomainVariants() {
        let content = """
        # adia-block-begin
        127.0.0.1 youtube.com
        127.0.0.1 www.youtube.com
        127.0.0.1 m.youtube.com
        127.0.0.1 music.youtube.com
        127.0.0.1 tv.youtube.com
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["youtube.com"])
        #expect(!domains.contains("music.youtube.com"))
        #expect(!domains.contains("tv.youtube.com"))
    }

    // MARK: - i. subdomain blocking (image-CDN bypass prevention)

    @Test func buildBlockIncludesImageSubdomain() {
        // i.reddit.com serves images and media independently of reddit.com.
        // Without the "i" prefix, blocking reddit.com leaves i.reddit.com open.
        let block = HostsFileManager.buildBlock(domains: ["reddit.com"])
        #expect(block.contains("127.0.0.1 i.reddit.com"),
                "i.reddit.com must be blocked to prevent image-CDN bypass")
    }

    @Test func imagePrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("i"),
                "\"i\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func parseBlockedFiltersImageSubdomainVariant() {
        let content = """
        # adia-block-begin
        127.0.0.1 reddit.com
        127.0.0.1 www.reddit.com
        127.0.0.1 i.reddit.com
        127.0.0.1 m.reddit.com
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["reddit.com"])
        #expect(!domains.contains("i.reddit.com"),
                "parseBlocked must filter out synthetic i. entries")
    }

    @Test func buildThenParseRoundTripWithImagePrefix() {
        let input = ["reddit.com", "instagram.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        #expect(block.contains("127.0.0.1 i.reddit.com"))
        #expect(block.contains("127.0.0.1 i.instagram.com"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "parseBlocked must return only bare canonical domains after i. rows are present")
    }

    // MARK: - api. subdomain blocking (third-party client bypass prevention)

    @Test func buildBlockIncludesApiSubdomain() {
        // api.twitter.com is used by third-party clients to load Twitter content even when
        // twitter.com is blocked in the browser. The "api" prefix closes this bypass.
        let block = HostsFileManager.buildBlock(domains: ["twitter.com"])
        #expect(block.contains("127.0.0.1 api.twitter.com"),
                "api.twitter.com must be blocked to prevent third-party-client bypass")
    }

    @Test func apiPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("api"),
                "\"api\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func parseBlockedFiltersApiSubdomainVariant() {
        let content = """
        # adia-block-begin
        127.0.0.1 twitter.com
        127.0.0.1 www.twitter.com
        127.0.0.1 api.twitter.com
        127.0.0.1 m.twitter.com
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["twitter.com"])
        #expect(!domains.contains("api.twitter.com"),
                "parseBlocked must filter out synthetic api. entries")
    }

    @Test func buildThenParseRoundTripWithApiPrefix() {
        let input = ["twitter.com", "reddit.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        #expect(block.contains("127.0.0.1 api.twitter.com"))
        #expect(block.contains("127.0.0.1 api.reddit.com"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "parseBlocked must return only bare canonical domains after api. rows are present")
    }

    // MARK: - No duplicates guard (additionalBlockedSubdomainPrefixes integrity)

    @Test func noDuplicatesInAdditionalPrefixesList() {
        // Duplicate prefixes would bloat /etc/hosts with repeated entries for every domain.
        let prefixes = HostsFileManager.additionalBlockedSubdomainPrefixes
        #expect(Set(prefixes).count == prefixes.count,
                "additionalBlockedSubdomainPrefixes must not contain duplicate entries")
    }

    // MARK: - clips. subdomain blocking (Twitch clip bypass prevention)

    @Test func buildBlockIncludesClipsSubdomain() {
        // clips.twitch.tv URLs are widely shared and bypass the top-level twitch.tv block
        // because "clips" is a distinct subdomain not covered by m./mobile./etc.
        let block = HostsFileManager.buildBlock(domains: ["twitch.tv"])
        #expect(block.contains("127.0.0.1 clips.twitch.tv"),
                "clips.twitch.tv must be blocked to prevent Twitch-clip bypass")
    }

    @Test func clipsPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("clips"),
                "\"clips\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func parseBlockedFiltersClipsSubdomainVariant() {
        let content = """
        # adia-block-begin
        127.0.0.1 twitch.tv
        127.0.0.1 www.twitch.tv
        127.0.0.1 clips.twitch.tv
        127.0.0.1 m.twitch.tv
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["twitch.tv"])
        #expect(!domains.contains("clips.twitch.tv"),
                "parseBlocked must filter out synthetic clips. entries")
    }

    @Test func buildThenParseRoundTripWithClipsPrefix() {
        let input = ["twitch.tv", "youtube.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        #expect(block.contains("127.0.0.1 clips.twitch.tv"))
        #expect(block.contains("127.0.0.1 clips.youtube.com"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "parseBlocked must return only bare canonical domains after clips. rows are present")
    }

    // MARK: - web. subdomain blocking (WhatsApp Web / Telegram Web bypass prevention)

    @Test func buildBlockIncludesWebSubdomain() {
        // web.whatsapp.com is WhatsApp's full browser client. Users whose native WhatsApp app
        // is blocked can trivially switch to the web client without this prefix.
        let block = HostsFileManager.buildBlock(domains: ["whatsapp.com"])
        #expect(block.contains("127.0.0.1 web.whatsapp.com"),
                "web.whatsapp.com must be blocked to prevent WhatsApp Web bypass")
    }

    @Test func webPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("web"),
                "\"web\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func buildBlockIncludesTelegramWebSubdomain() {
        // web.telegram.org is Telegram's browser client, separate from the native app.
        let block = HostsFileManager.buildBlock(domains: ["telegram.org"])
        #expect(block.contains("127.0.0.1 web.telegram.org"),
                "web.telegram.org must be blocked to prevent Telegram Web bypass")
    }

    @Test func parseBlockedFiltersWebSubdomainVariant() {
        let content = """
        # adia-block-begin
        127.0.0.1 whatsapp.com
        127.0.0.1 www.whatsapp.com
        127.0.0.1 web.whatsapp.com
        127.0.0.1 m.whatsapp.com
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["whatsapp.com"])
        #expect(!domains.contains("web.whatsapp.com"),
                "parseBlocked must filter out synthetic web. entries")
    }

    @Test func buildThenParseRoundTripWithWebPrefix() {
        let input = ["whatsapp.com", "telegram.org"]
        let block = HostsFileManager.buildBlock(domains: input)
        #expect(block.contains("127.0.0.1 web.whatsapp.com"))
        #expect(block.contains("127.0.0.1 web.telegram.org"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "parseBlocked must return only bare canonical domains after web. rows are present")
    }

    // MARK: - app. subdomain blocking (Slack Web App bypass prevention)

    @Test func buildBlockIncludesAppSubdomain() {
        // app.slack.com is the URL of Slack's browser-based web app. Blocking slack.com alone
        // leaves app.slack.com open — users can access the full Slack interface via the web.
        let block = HostsFileManager.buildBlock(domains: ["slack.com"])
        #expect(block.contains("127.0.0.1 app.slack.com"),
                "app.slack.com must be blocked to prevent Slack Web App bypass")
    }

    @Test func appPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("app"),
                "\"app\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func parseBlockedFiltersAppSubdomainVariant() {
        let content = """
        # adia-block-begin
        127.0.0.1 slack.com
        127.0.0.1 www.slack.com
        127.0.0.1 app.slack.com
        127.0.0.1 m.slack.com
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["slack.com"])
        #expect(!domains.contains("app.slack.com"),
                "parseBlocked must filter out synthetic app. entries")
    }

    @Test func buildThenParseRoundTripWithAppPrefix() {
        let input = ["slack.com", "discord.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        #expect(block.contains("127.0.0.1 app.slack.com"))
        #expect(block.contains("127.0.0.1 app.discord.com"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "parseBlocked must return only bare canonical domains after app. rows are present")
    }

    // MARK: - go. subdomain blocking (tracking-redirect bypass prevention)

    @Test func buildBlockIncludesGoSubdomain() {
        // go.twitch.tv is used for campaign tracking redirects; links shared via Discord/Twitter
        // may resolve through this subdomain even when twitch.tv itself is blocked.
        let block = HostsFileManager.buildBlock(domains: ["twitch.tv"])
        #expect(block.contains("127.0.0.1 go.twitch.tv"),
                "go.twitch.tv must be blocked to prevent tracking-redirect bypass")
    }

    @Test func goPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("go"),
                "\"go\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func parseBlockedFiltersGoSubdomainVariant() {
        let content = """
        # adia-block-begin
        127.0.0.1 twitch.tv
        127.0.0.1 www.twitch.tv
        127.0.0.1 go.twitch.tv
        127.0.0.1 m.twitch.tv
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["twitch.tv"])
        #expect(!domains.contains("go.twitch.tv"),
                "parseBlocked must filter out synthetic go. entries")
    }

    @Test func buildThenParseRoundTripWithGoPrefix() {
        let input = ["twitch.tv", "twitter.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        #expect(block.contains("127.0.0.1 go.twitch.tv"))
        #expect(block.contains("127.0.0.1 go.twitter.com"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "parseBlocked must return only bare canonical domains after go. rows are present")
    }

    // MARK: - cdn. subdomain blocking (Discord CDN / media-CDN bypass prevention)

    @Test func buildBlockIncludesCdnSubdomain() {
        // cdn.discordapp.com serves Discord avatars, images, and file attachments independently
        // of discord.com — blocking discord.com alone leaves the CDN open for direct-link access.
        let block = HostsFileManager.buildBlock(domains: ["discordapp.com"])
        #expect(block.contains("127.0.0.1 cdn.discordapp.com"),
                "cdn.discordapp.com must be blocked to prevent Discord CDN bypass")
    }

    @Test func cdnPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("cdn"),
                "\"cdn\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func buildBlockIncludesDiscordAppCdnAlongsideDiscordCom() {
        // Both discord.com (main site) and discordapp.com (CDN) must be blocked together.
        // cdn.discordapp.com is the concrete bypass vector closed by this combination.
        let block = HostsFileManager.buildBlock(domains: ["discord.com", "discordapp.com"])
        #expect(block.contains("127.0.0.1 discord.com"))
        #expect(block.contains("127.0.0.1 discordapp.com"))
        #expect(block.contains("127.0.0.1 cdn.discordapp.com"))
    }

    @Test func parseBlockedFiltersCdnSubdomainVariant() {
        let content = """
        # adia-block-begin
        127.0.0.1 discordapp.com
        127.0.0.1 www.discordapp.com
        127.0.0.1 cdn.discordapp.com
        127.0.0.1 m.discordapp.com
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["discordapp.com"])
        #expect(!domains.contains("cdn.discordapp.com"),
                "parseBlocked must filter out synthetic cdn. entries")
    }

    @Test func buildThenParseRoundTripWithCdnPrefix() {
        let input = ["discordapp.com", "discord.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        #expect(block.contains("127.0.0.1 cdn.discordapp.com"))
        #expect(block.contains("127.0.0.1 cdn.discord.com"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "parseBlocked must return only bare canonical domains after cdn. rows are present")
    }

    // MARK: - store. subdomain blocking (Steam / Epic Games store bypass prevention)

    @Test func buildBlockIncludesStoreSubdomainForSteam() {
        // store.steampowered.com is the direct URL users navigate to for Steam's game catalog.
        // Blocking steampowered.com alone redirects the root, but store. is a distinct subdomain
        // that external links (Reddit, Discord) often target directly.
        let block = HostsFileManager.buildBlock(domains: ["steampowered.com"])
        #expect(block.contains("127.0.0.1 store.steampowered.com"),
                "store.steampowered.com must be blocked to prevent Steam store bypass")
    }

    @Test func buildBlockIncludesStoreSubdomainForEpic() {
        // store.epicgames.com is the Epic Games Store's storefront; external links point here directly.
        let block = HostsFileManager.buildBlock(domains: ["epicgames.com"])
        #expect(block.contains("127.0.0.1 store.epicgames.com"),
                "store.epicgames.com must be blocked to prevent Epic Games store bypass")
    }

    @Test func storePrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("store"),
                "\"store\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func parseBlockedFiltersStoreSubdomainVariant() {
        let content = """
        # adia-block-begin
        127.0.0.1 steampowered.com
        127.0.0.1 www.steampowered.com
        127.0.0.1 store.steampowered.com
        127.0.0.1 m.steampowered.com
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["steampowered.com"])
        #expect(!domains.contains("store.steampowered.com"),
                "parseBlocked must filter out synthetic store. entries")
    }

    @Test func buildThenParseRoundTripWithStorePrefix() {
        let input = ["steampowered.com", "epicgames.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        #expect(block.contains("127.0.0.1 store.steampowered.com"))
        #expect(block.contains("127.0.0.1 store.epicgames.com"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "parseBlocked must return only bare canonical domains after store. rows are present")
    }
}
