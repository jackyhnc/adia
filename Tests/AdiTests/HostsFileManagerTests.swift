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

    // MARK: - media. subdomain blocking (Discord embedded-video/GIF preview CDN bypass prevention)

    @Test func buildBlockIncludesMediaSubdomain() {
        // media.discordapp.com serves Discord's embedded GIF and video previews — a secondary
        // CDN separate from cdn.discordapp.com. Direct links to GIF embeds bypass both the
        // discord.com block and the cdn. prefix without this entry.
        let block = HostsFileManager.buildBlock(domains: ["discordapp.com"])
        #expect(block.contains("127.0.0.1 media.discordapp.com"),
                "media.discordapp.com must be blocked to prevent Discord embedded-preview CDN bypass")
    }

    @Test func mediaPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("media"),
                "\"media\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func buildBlockIncludesDiscordMediaAlongsideDiscordCdn() {
        // Both media. and cdn. subdomain entries must be generated for discordapp.com together.
        let block = HostsFileManager.buildBlock(domains: ["discordapp.com"])
        #expect(block.contains("127.0.0.1 cdn.discordapp.com"))
        #expect(block.contains("127.0.0.1 media.discordapp.com"))
    }

    @Test func parseBlockedFiltersMediaSubdomainVariant() {
        let content = """
        # adia-block-begin
        127.0.0.1 discordapp.com
        127.0.0.1 www.discordapp.com
        127.0.0.1 cdn.discordapp.com
        127.0.0.1 media.discordapp.com
        127.0.0.1 m.discordapp.com
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["discordapp.com"])
        #expect(!domains.contains("media.discordapp.com"),
                "parseBlocked must filter out synthetic media. entries")
    }

    @Test func buildThenParseRoundTripWithMediaPrefix() {
        let input = ["discordapp.com", "discordapp.net"]
        let block = HostsFileManager.buildBlock(domains: input)
        #expect(block.contains("127.0.0.1 media.discordapp.com"))
        #expect(block.contains("127.0.0.1 media.discordapp.net"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "parseBlocked must return only bare canonical domains after media. rows are present")
    }

    // MARK: - lite. subdomain blocking (TikTok Lite regional variant bypass prevention)

    @Test func buildBlockIncludesLiteSubdomainForTikTok() {
        // lite.tiktok.com is TikTok's stripped-down browser app available in some regions.
        // Blocking tiktok.com alone leaves the lite subdomain accessible as a bypass route.
        let block = HostsFileManager.buildBlock(domains: ["tiktok.com"])
        #expect(block.contains("127.0.0.1 lite.tiktok.com"),
                "lite.tiktok.com must be blocked to prevent TikTok Lite bypass")
    }

    @Test func litePrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("lite"),
                "\"lite\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func parseBlockedFiltersLiteSubdomainVariant() {
        let content = """
        # adia-block-begin
        127.0.0.1 tiktok.com
        127.0.0.1 www.tiktok.com
        127.0.0.1 lite.tiktok.com
        127.0.0.1 m.tiktok.com
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["tiktok.com"])
        #expect(!domains.contains("lite.tiktok.com"),
                "parseBlocked must filter out synthetic lite. entries")
    }

    @Test func buildThenParseRoundTripWithLitePrefix() {
        let input = ["tiktok.com", "reddit.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        #expect(block.contains("127.0.0.1 lite.tiktok.com"))
        #expect(block.contains("127.0.0.1 lite.reddit.com"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "parseBlocked must return only bare canonical domains after lite. rows are present")
    }

    @Test func litePrefixDoesNotAffectProductivityToolsInRoundTrip() {
        // "lite" is safe to add broadly — legitimate productivity subdomains like
        // docs.google.com, notion.so, etc. don't use a "lite." variant.
        let input = ["notion.so", "github.com", "google.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "lite. prefix must not corrupt parseBlocked output for productivity domains")
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

    // MARK: - player. subdomain blocking (embedded Twitch player bypass prevention)

    @Test func buildBlockIncludesPlayerSubdomainForTwitch() {
        // player.twitch.tv is Twitch's embeddable player iframe used on third-party sites.
        // A user whose twitch.tv is blocked can still watch a live stream via an embedded
        // player.twitch.tv iframe on another page without this prefix.
        let block = HostsFileManager.buildBlock(domains: ["twitch.tv"])
        #expect(block.contains("127.0.0.1 player.twitch.tv"),
                "player.twitch.tv must be blocked to prevent embedded-player bypass")
    }

    @Test func playerPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("player"),
                "\"player\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func parseBlockedFiltersPlayerSubdomainVariant() {
        let content = """
        # adia-block-begin
        127.0.0.1 twitch.tv
        127.0.0.1 www.twitch.tv
        127.0.0.1 player.twitch.tv
        127.0.0.1 clips.twitch.tv
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["twitch.tv"])
        #expect(!domains.contains("player.twitch.tv"),
                "parseBlocked must filter out synthetic player. entries")
    }

    @Test func buildThenParseRoundTripWithPlayerPrefix() {
        let input = ["twitch.tv", "youtube.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        #expect(block.contains("127.0.0.1 player.twitch.tv"))
        #expect(block.contains("127.0.0.1 player.youtube.com"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "parseBlocked must return only bare canonical domains after player. rows are present")
    }

    @Test func playerPrefixDoesNotAffectProductivityToolsInRoundTrip() {
        // "player" is safe to add — productivity tools don't expose a player. subdomain.
        let input = ["notion.so", "github.com", "linear.app"]
        let block = HostsFileManager.buildBlock(domains: input)
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "player. prefix must not corrupt parseBlocked output for productivity domains")
    }

    // MARK: - assets. subdomain blocking (static-asset CDN bypass prevention)

    @Test func buildBlockIncludesAssetsSubdomainForTwitch() {
        // assets.twitch.tv serves sprite sheets, fonts, and UI bundle files — a service-worker-
        // backed page could load these independently even when twitch.tv itself is blocked.
        let block = HostsFileManager.buildBlock(domains: ["twitch.tv"])
        #expect(block.contains("127.0.0.1 assets.twitch.tv"),
                "assets.twitch.tv must be blocked to prevent static-asset CDN bypass")
    }

    @Test func assetsPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("assets"),
                "\"assets\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func parseBlockedFiltersAssetsSubdomainVariant() {
        let content = """
        # adia-block-begin
        127.0.0.1 twitch.tv
        127.0.0.1 www.twitch.tv
        127.0.0.1 assets.twitch.tv
        127.0.0.1 player.twitch.tv
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["twitch.tv"])
        #expect(!domains.contains("assets.twitch.tv"),
                "parseBlocked must filter out synthetic assets. entries")
    }

    @Test func buildThenParseRoundTripWithAssetsPrefix() {
        let input = ["twitch.tv", "discord.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        #expect(block.contains("127.0.0.1 assets.twitch.tv"))
        #expect(block.contains("127.0.0.1 assets.discord.com"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "parseBlocked must return only bare canonical domains after assets. rows are present")
    }

    @Test func playerAndAssetsGeneratedTogetherForTwitch() {
        // Both player. and assets. must be generated for twitch.tv simultaneously —
        // they close independent bypass vectors and must coexist in the same block.
        let block = HostsFileManager.buildBlock(domains: ["twitch.tv"])
        #expect(block.contains("127.0.0.1 player.twitch.tv"))
        #expect(block.contains("127.0.0.1 assets.twitch.tv"))
        #expect(block.contains("127.0.0.1 clips.twitch.tv"))
        #expect(block.contains("127.0.0.1 go.twitch.tv"))
    }

    // MARK: - embed. subdomain blocking (Twitch embed-wrapper page bypass prevention)

    @Test func buildBlockIncludesEmbedSubdomainForTwitch() {
        // embed.twitch.tv is the outer container page that wraps the player.twitch.tv iframe.
        // Third-party sites initialise Twitch embeds by loading embed.twitch.tv/embed/...; blocking
        // player. closes the stream iframe, but embed. closes the wrapper page that boots it.
        let block = HostsFileManager.buildBlock(domains: ["twitch.tv"])
        #expect(block.contains("127.0.0.1 embed.twitch.tv"),
                "embed.twitch.tv must be blocked to prevent Twitch embed-wrapper bypass")
    }

    @Test func embedPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("embed"),
                "\"embed\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func parseBlockedFiltersEmbedSubdomainVariant() {
        let content = """
        # adia-block-begin
        127.0.0.1 twitch.tv
        127.0.0.1 www.twitch.tv
        127.0.0.1 embed.twitch.tv
        127.0.0.1 player.twitch.tv
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["twitch.tv"])
        #expect(!domains.contains("embed.twitch.tv"),
                "parseBlocked must filter out synthetic embed. entries")
    }

    @Test func buildThenParseRoundTripWithEmbedPrefix() {
        let input = ["twitch.tv", "youtube.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        #expect(block.contains("127.0.0.1 embed.twitch.tv"))
        #expect(block.contains("127.0.0.1 embed.youtube.com"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "parseBlocked must return only bare canonical domains after embed. rows are present")
    }

    @Test func embedPlayerAndAssetsAllGeneratedTogetherForTwitch() {
        // embed., player., assets., clips., and go. must all be generated for twitch.tv —
        // each closes an independent bypass route and they must coexist.
        let block = HostsFileManager.buildBlock(domains: ["twitch.tv"])
        #expect(block.contains("127.0.0.1 embed.twitch.tv"))
        #expect(block.contains("127.0.0.1 player.twitch.tv"))
        #expect(block.contains("127.0.0.1 assets.twitch.tv"))
        #expect(block.contains("127.0.0.1 clips.twitch.tv"))
    }

    // MARK: - vod. subdomain blocking (Twitch VOD / video-on-demand bypass prevention)

    @Test func buildBlockIncludesVodSubdomainForTwitch() {
        // vod.twitch.tv serves Twitch's video-on-demand archive and highlight delivery.
        // External links (Reddit, Discord) to recorded Twitch content can resolve through
        // vod.twitch.tv even when twitch.tv and clips.twitch.tv are both blocked.
        let block = HostsFileManager.buildBlock(domains: ["twitch.tv"])
        #expect(block.contains("127.0.0.1 vod.twitch.tv"),
                "vod.twitch.tv must be blocked to prevent VOD bypass")
    }

    @Test func vodPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("vod"),
                "\"vod\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func parseBlockedFiltersVodSubdomainVariant() {
        let content = """
        # adia-block-begin
        127.0.0.1 twitch.tv
        127.0.0.1 www.twitch.tv
        127.0.0.1 vod.twitch.tv
        127.0.0.1 clips.twitch.tv
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["twitch.tv"])
        #expect(!domains.contains("vod.twitch.tv"),
                "parseBlocked must filter out synthetic vod. entries")
    }

    @Test func buildThenParseRoundTripWithVodPrefix() {
        let input = ["twitch.tv", "youtube.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        #expect(block.contains("127.0.0.1 vod.twitch.tv"))
        #expect(block.contains("127.0.0.1 vod.youtube.com"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "parseBlocked must return only bare canonical domains after vod. rows are present")
    }

    // MARK: - static. subdomain blocking (Twitch service-worker cache bypass prevention)

    @Test func buildBlockIncludesStaticSubdomainForTwitch() {
        // static.twitch.tv is Twitch's service-worker pre-cache target for static resources.
        // A cached Twitch shell can render from static. even when twitch.tv is blocked in /etc/hosts.
        let block = HostsFileManager.buildBlock(domains: ["twitch.tv"])
        #expect(block.contains("127.0.0.1 static.twitch.tv"),
                "static.twitch.tv must be blocked to prevent service-worker cache bypass")
    }

    @Test func staticPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("static"),
                "\"static\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func parseBlockedFiltersStaticSubdomainVariant() {
        let content = """
        # adia-block-begin
        127.0.0.1 twitch.tv
        127.0.0.1 www.twitch.tv
        127.0.0.1 static.twitch.tv
        127.0.0.1 assets.twitch.tv
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["twitch.tv"])
        #expect(!domains.contains("static.twitch.tv"),
                "parseBlocked must filter out synthetic static. entries")
    }

    @Test func buildThenParseRoundTripWithStaticPrefix() {
        let input = ["twitch.tv", "facebook.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        #expect(block.contains("127.0.0.1 static.twitch.tv"))
        #expect(block.contains("127.0.0.1 static.facebook.com"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "parseBlocked must return only bare canonical domains after static. rows are present")
    }

    @Test func staticPrefixDoesNotAffectProductivityToolsInRoundTrip() {
        // Verify "static" doesn't corrupt round-trips for productivity domains like github.com,
        // notion.so, etc. None of these expose a meaningful static. subdomain used by users.
        let input = ["notion.so", "github.com", "linear.app"]
        let block = HostsFileManager.buildBlock(domains: input)
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "static. prefix must not corrupt parseBlocked output for productivity domains")
    }
}

// MARK: - images. prefix

@Suite("HostsFileManager — images. subdomain prefix")
struct ImagesPrefixTests {

    @Test func imagesPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("images"),
                "\"images\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func buildBlockIncludesImagesSubdomainForGoogle() {
        // Google Image Search lives at images.google.com — a standalone distraction vector
        // that resolves separately from google.com.
        let block = HostsFileManager.buildBlock(domains: ["google.com"])
        #expect(block.contains("127.0.0.1 images.google.com"),
                "buildBlock must emit images.google.com when google.com is in the domain list")
    }

    @Test func buildBlockIncludesImagesSubdomainForFandom() {
        // images.fandom.com is the Fandom wiki image CDN — separate from fandom.com itself.
        let block = HostsFileManager.buildBlock(domains: ["fandom.com"])
        #expect(block.contains("127.0.0.1 images.fandom.com"),
                "buildBlock must emit images.fandom.com when fandom.com is in the domain list")
    }

    @Test func parseBlockedFiltersImagesSubdomainVariant() {
        let content = """
        # adia-block-begin
        127.0.0.1 google.com
        127.0.0.1 www.google.com
        127.0.0.1 images.google.com
        # adia-block-end
        """
        let domains = HostsFileManager.parseBlocked(content)
        #expect(domains == ["google.com"])
        #expect(!domains.contains("images.google.com"),
                "parseBlocked must filter out synthetic images. entries")
    }

    @Test func buildThenParseRoundTripWithImagesPrefix() {
        let input = ["google.com", "fandom.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        #expect(block.contains("127.0.0.1 images.google.com"))
        #expect(block.contains("127.0.0.1 images.fandom.com"))
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "parseBlocked must return only bare canonical domains after images. rows are present")
    }

    @Test func imagesPrefixDoesNotAffectProductivityToolsInRoundTrip() {
        // No common productivity tool (Notion, GitHub, Linear) exposes an images. subdomain.
        let input = ["notion.so", "github.com", "linear.app"]
        let block = HostsFileManager.buildBlock(domains: input)
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "images. prefix must not corrupt parseBlocked output for productivity domains")
    }

    // MARK: - HostsFileManager — auth. subdomain prefix

    @Test func authPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("auth"),
                "\"auth\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func buildBlockIncludesAuthSubdomainForTwitch() {
        let block = HostsFileManager.buildBlock(domains: ["twitch.tv"])
        #expect(block.contains("127.0.0.1 auth.twitch.tv"),
                "auth.twitch.tv must appear in the block so the Twitch auth flow is blocked")
    }

    @Test func buildBlockIncludesAuthSubdomainForDiscord() {
        let block = HostsFileManager.buildBlock(domains: ["discord.com"])
        #expect(block.contains("127.0.0.1 auth.discord.com"),
                "auth.discord.com must appear in the block so the Discord OAuth flow is blocked")
    }

    @Test func buildBlockIncludesAuthSubdomainForReddit() {
        let block = HostsFileManager.buildBlock(domains: ["reddit.com"])
        #expect(block.contains("127.0.0.1 auth.reddit.com"),
                "auth.reddit.com must appear in the block so the Reddit auth endpoint is blocked")
    }

    @Test func parseBlockedFiltersAuthSubdomainVariant() {
        // auth.X is a synthetic prefix entry — parseBlocked must strip it and return
        // only the bare canonical domain so callers don't see doubled entries.
        let block = HostsFileManager.buildBlock(domains: ["discord.com"])
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(parsed == ["discord.com"],
                "parseBlocked must return only bare canonical domains after auth. rows are present")
    }

    @Test func buildThenParseRoundTripWithAuthPrefix() {
        let input = ["twitch.tv", "discord.com", "reddit.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "build → parse round-trip must be lossless with auth. prefix present")
    }

    @Test func authPrefixDoesNotAffectProductivityToolsInRoundTrip() {
        // Productivity tools (GitHub, Notion, Linear) are not in the default blocked list,
        // so auth. entries are never generated for them — but even if they were added
        // manually, the round-trip must remain correct.
        let input = ["notion.so", "github.com", "linear.app"]
        let block = HostsFileManager.buildBlock(domains: input)
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "auth. prefix must not corrupt parseBlocked output for productivity domains")
    }
}

// MARK: - live. subdomain prefix

@Suite("HostsFileManager — live. subdomain prefix (live-stream page subdomains)")
struct LiveSubdomainPrefixTests {

    @Test func livePrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("live"),
                "\"live\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func buildBlockIncludesLiveSubdomainForYouTube() {
        let block = HostsFileManager.buildBlock(domains: ["youtube.com"])
        #expect(block.contains("127.0.0.1 live.youtube.com"),
                "live.youtube.com (YouTube Live page) must appear in the block")
    }

    @Test func buildBlockIncludesLiveSubdomainForBilibili() {
        let block = HostsFileManager.buildBlock(domains: ["bilibili.com"])
        #expect(block.contains("127.0.0.1 live.bilibili.com"),
                "live.bilibili.com (Bilibili live streaming) must appear in the block")
    }

    @Test func buildBlockIncludesLiveSubdomainForKick() {
        let block = HostsFileManager.buildBlock(domains: ["kick.com"])
        #expect(block.contains("127.0.0.1 live.kick.com"),
                "live.kick.com must appear in the block alongside kick.com")
    }

    @Test func parseBlockedFiltersLiveSubdomainVariant() {
        // live.X is a synthetic prefix entry — parseBlocked must strip it and return
        // only the bare canonical domain so callers don't see doubled entries.
        let block = HostsFileManager.buildBlock(domains: ["youtube.com"])
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(parsed == ["youtube.com"],
                "parseBlocked must return only bare canonical domains when live. rows are present")
    }

    @Test func buildThenParseRoundTripWithLivePrefix() {
        let input = ["youtube.com", "bilibili.com", "kick.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "build → parse round-trip must be lossless with live. prefix present")
    }

    @Test func noDuplicatesInAdditionalPrefixesListAfterLiveAddition() {
        let prefixes = HostsFileManager.additionalBlockedSubdomainPrefixes
        #expect(Set(prefixes).count == prefixes.count,
                "no duplicate entries in additionalBlockedSubdomainPrefixes after live. was added")
    }
}

// MARK: - gaming. subdomain prefix

@Suite("HostsFileManager — gaming. subdomain prefix (gaming-hub page subdomains)")
struct GamingSubdomainPrefixTests {

    @Test func gamingPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("gaming"),
                "\"gaming\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func buildBlockIncludesGamingSubdomainForYouTube() {
        let block = HostsFileManager.buildBlock(domains: ["youtube.com"])
        #expect(block.contains("127.0.0.1 gaming.youtube.com"),
                "gaming.youtube.com (legacy YouTube Gaming hub) must appear in the block")
    }

    @Test func buildBlockIncludesGamingSubdomainForAmazon() {
        let block = HostsFileManager.buildBlock(domains: ["amazon.com"])
        #expect(block.contains("127.0.0.1 gaming.amazon.com"),
                "gaming.amazon.com (Amazon Prime Gaming portal) must appear in the block")
    }

    @Test func parseBlockedFiltersGamingSubdomainVariant() {
        // gaming.X is a synthetic prefix entry — parseBlocked must strip it and return
        // only the bare canonical domain so callers don't see doubled entries.
        let block = HostsFileManager.buildBlock(domains: ["youtube.com"])
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(parsed == ["youtube.com"],
                "parseBlocked must return only bare canonical domains when gaming. rows are present")
    }

    @Test func buildThenParseRoundTripWithGamingPrefix() {
        let input = ["youtube.com", "amazon.com", "facebook.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "build → parse round-trip must be lossless with gaming. prefix present")
    }

    @Test func gamingPrefixDoesNotAffectProductivityToolsInRoundTrip() {
        // Productivity tools are NOT in the default blocked list, so gaming.X entries
        // are never generated for them. Confirm that a custom block containing only a
        // productivity-style domain round-trips cleanly with the gaming prefix present.
        let input = ["example-productivity.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(parsed == input,
                "gaming. prefix must not corrupt round-trip for non-blocked productivity tools")
    }

    @Test func noDuplicatesInAdditionalPrefixesListAfterGamingAddition() {
        let prefixes = HostsFileManager.additionalBlockedSubdomainPrefixes
        #expect(Set(prefixes).count == prefixes.count,
                "no duplicate entries in additionalBlockedSubdomainPrefixes after gaming. was added")
    }
}

// MARK: - "watch" subdomain prefix (direct-watch subdomains on entertainment platforms)

@Suite("HostsFileManager — watch. subdomain prefix (direct-watch page subdomains)")
struct WatchSubdomainPrefixTests {

    @Test func watchPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("watch"),
                "\"watch\" must be present in additionalBlockedSubdomainPrefixes")
    }

    @Test func buildBlockIncludesWatchSubdomainForTwitch() {
        // watch.twitch.tv is Twitch's standalone watch-page subdomain —
        // embedded / shared links use this as the canonical watch destination.
        let block = HostsFileManager.buildBlock(domains: ["twitch.tv"])
        #expect(block.contains("127.0.0.1 watch.twitch.tv"),
                "watch.twitch.tv must appear in the block for twitch.tv")
    }

    @Test func parseBlockedFiltersWatchSubdomainVariant() {
        // watch.X is a synthetic prefix entry — parseBlocked must strip it and return
        // only the bare canonical domain so callers don't see doubled entries.
        let block = HostsFileManager.buildBlock(domains: ["twitch.tv"])
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(parsed == ["twitch.tv"],
                "parseBlocked must return only the bare canonical domain when watch. rows are present")
    }

    @Test func buildThenParseRoundTripWithWatchPrefix() {
        let input = ["twitch.tv", "vimeo.com", "pexels.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "build → parse round-trip must be lossless with watch. prefix present")
    }

    @Test func watchPrefixDoesNotAffectProductivityToolsInRoundTrip() {
        // Productivity tools are NOT in the default blocked list — confirm that a custom
        // block containing only a productivity-style domain round-trips cleanly with watch. present.
        let input = ["example-productivity.com"]
        let block = HostsFileManager.buildBlock(domains: input)
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(parsed == input,
                "watch. prefix must not corrupt round-trip for non-blocked productivity tools")
    }

    @Test func noDuplicatesInAdditionalPrefixesListAfterWatchAddition() {
        let prefixes = HostsFileManager.additionalBlockedSubdomainPrefixes
        #expect(Set(prefixes).count == prefixes.count,
                "no duplicate entries in additionalBlockedSubdomainPrefixes after watch. was added")
    }
}

// MARK: - Video & photography domain blocks

@Suite("HostsFileManager — video sharing and photography domain blocks")
struct VideoAndPhotographyBlockTests {

    @Test func buildBlockIncludesVimeo() {
        let block = HostsFileManager.buildBlock(domains: ["vimeo.com"])
        #expect(block.contains("127.0.0.1 vimeo.com"))
        #expect(block.contains("127.0.0.1 www.vimeo.com"))
    }

    @Test func buildBlockIncludesWatchSubdomainForVimeo() {
        // vimeo.com uses watch.vimeo.com for video playback links in some contexts.
        let block = HostsFileManager.buildBlock(domains: ["vimeo.com"])
        #expect(block.contains("127.0.0.1 watch.vimeo.com"),
                "watch.vimeo.com must appear in the block for vimeo.com")
    }

    @Test func buildBlockIncludesUnsplash() {
        let block = HostsFileManager.buildBlock(domains: ["unsplash.com"])
        #expect(block.contains("127.0.0.1 unsplash.com"))
        #expect(block.contains("127.0.0.1 www.unsplash.com"))
    }

    @Test func buildBlockIncludesNitter() {
        // nitter.net — the Twitter/X proxy frontend domain.
        let block = HostsFileManager.buildBlock(domains: ["nitter.net"])
        #expect(block.contains("127.0.0.1 nitter.net"))
        #expect(block.contains("127.0.0.1 www.nitter.net"))
    }

    @Test func buildThenParseRoundTripWithVideoAndPhotographyDomains() {
        let input = ["vimeo.com", "500px.com", "unsplash.com", "flickr.com", "pexels.com", "pixabay.com", "nitter.net"]
        let block = HostsFileManager.buildBlock(domains: input)
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "build → parse round-trip must be lossless for video/photography/proxy domains")
    }

    @Test func noDuplicatesInDefaultBlockedListAfterVideoAndPhotographyAdditions() {
        let domains = Session.defaultBlockedDomains
        #expect(Set(domains).count == domains.count,
                "no duplicate domain entries in defaultBlockedDomains after video/photography additions")
    }
}

// MARK: - video. subdomain prefix

@Suite("HostsFileManager — video. subdomain prefix")
struct VideoSubdomainPrefixTests {

    @Test func videoPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("video"),
                "\"video\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func buildBlockIncludesVideoSubdomainForTwitch() {
        // video.twitch.tv is Twitch's VOD/clip delivery subdomain; blocks that subdomain
        // alongside the main twitch.tv entry already present from the domain block.
        let block = HostsFileManager.buildBlock(domains: ["twitch.tv"])
        #expect(block.contains("127.0.0.1 video.twitch.tv"),
                "video.twitch.tv must be generated by the \"video\" subdomain prefix")
    }

    @Test func buildBlockIncludesVideoSubdomainForFacebook() {
        // video.facebook.com hosts the Facebook Watch browse UI — a distinct subdomain from
        // facebook.com. Without this prefix, users could reach Facebook's video feed via a
        // direct URL even when facebook.com is blocked.
        let block = HostsFileManager.buildBlock(domains: ["facebook.com"])
        #expect(block.contains("127.0.0.1 video.facebook.com"),
                "video.facebook.com must be generated by the \"video\" subdomain prefix")
    }

    @Test func buildBlockIncludesVideoSubdomainForDailymotion() {
        let block = HostsFileManager.buildBlock(domains: ["dailymotion.com"])
        #expect(block.contains("127.0.0.1 video.dailymotion.com"),
                "video.dailymotion.com must be generated by the \"video\" subdomain prefix")
    }

    @Test func parseBlockedFiltersVideoSubdomainVariant() {
        // parseBlocked must skip "video." entries so callers only see the bare domain.
        let block = HostsFileManager.buildBlock(domains: ["twitch.tv"])
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(parsed == ["twitch.tv"],
                "parseBlocked must return only the bare canonical domain when video. rows are present")
    }

    @Test func buildThenParseRoundTripWithVideoPrefix() {
        let input = ["twitch.tv", "facebook.com", "dailymotion.com"]
        let block  = HostsFileManager.buildBlock(domains: input)
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "build → parse round-trip must be lossless with video. prefix present")
    }

    @Test func noDuplicatesInAdditionalPrefixesListAfterVideoAddition() {
        let prefixes = HostsFileManager.additionalBlockedSubdomainPrefixes
        #expect(Set(prefixes).count == prefixes.count,
                "no duplicate entries in additionalBlockedSubdomainPrefixes after video. was added")
    }
}

@Suite("HostsFileManager — shop. subdomain prefix")
struct ShopSubdomainPrefixTests {

    @Test func shopPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("shop"),
                "\"shop\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func buildBlockIncludesShopSubdomainForSpotify() {
        // shop.spotify.com is Spotify's merchandise store — a distinct subdomain that
        // resolves independently from spotify.com.
        let block = HostsFileManager.buildBlock(domains: ["spotify.com"])
        #expect(block.contains("127.0.0.1 shop.spotify.com"),
                "shop.spotify.com must be generated by the \"shop\" subdomain prefix")
    }

    @Test func buildBlockIncludesShopSubdomainForTwitch() {
        // shop.twitch.tv is Twitch's merchandise subdomain — separate from the main twitch.tv
        // entry and from clips./player./embed. etc.
        let block = HostsFileManager.buildBlock(domains: ["twitch.tv"])
        #expect(block.contains("127.0.0.1 shop.twitch.tv"),
                "shop.twitch.tv must be generated by the \"shop\" subdomain prefix")
    }

    @Test func buildBlockIncludesShopSubdomainForEpicGames() {
        // shop.epicgames.com is Epic's merchandise page — a separate subdomain from the
        // store.epicgames.com game-store page (already covered by the "store" prefix).
        let block = HostsFileManager.buildBlock(domains: ["epicgames.com"])
        #expect(block.contains("127.0.0.1 shop.epicgames.com"),
                "shop.epicgames.com must be generated by the \"shop\" subdomain prefix")
    }

    @Test func parseBlockedFiltersShopSubdomainVariant() {
        // parseBlocked must skip "shop." entries so callers only see the bare domain.
        let block = HostsFileManager.buildBlock(domains: ["spotify.com"])
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(parsed == ["spotify.com"],
                "parseBlocked must return only the bare canonical domain when shop. rows are present")
    }

    @Test func buildThenParseRoundTripWithShopPrefix() {
        let input = ["spotify.com", "twitch.tv", "epicgames.com"]
        let block  = HostsFileManager.buildBlock(domains: input)
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "build → parse round-trip must be lossless with shop. prefix present")
    }

    @Test func shopPrefixIsDistinctFromStorePrefix() {
        // "shop" and "store" are both present and distinct — they cover different subdomains.
        let prefixes = HostsFileManager.additionalBlockedSubdomainPrefixes
        #expect(prefixes.contains("shop"), "\"shop\" must be present")
        #expect(prefixes.contains("store"), "\"store\" must still be present after \"shop\" addition")
        #expect(prefixes.filter { $0 == "shop" }.count == 1,
                "\"shop\" must appear exactly once in additionalBlockedSubdomainPrefixes")
    }

    @Test func noDuplicatesInAdditionalPrefixesListAfterShopAddition() {
        let prefixes = HostsFileManager.additionalBlockedSubdomainPrefixes
        #expect(Set(prefixes).count == prefixes.count,
                "no duplicate entries in additionalBlockedSubdomainPrefixes after shop. was added")
    }
}

// MARK: - play. subdomain prefix

@Suite("HostsFileManager — play. subdomain prefix")
struct PlaySubdomainPrefixTests {

    @Test func playPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("play"),
                "\"play\" must be in additionalBlockedSubdomainPrefixes")
    }

    @Test func buildBlockIncludesPlaySubdomainForTwitch() {
        // play.twitch.tv is Twitch's inline-stream URL scheme used in share links —
        // distinct from player.twitch.tv (the embed route) already covered by "player".
        let block = HostsFileManager.buildBlock(domains: ["twitch.tv"])
        #expect(block.contains("127.0.0.1 play.twitch.tv"),
                "play.twitch.tv must be generated by the \"play\" subdomain prefix")
    }

    @Test func buildBlockIncludesPlaySubdomainForSpotify() {
        // play.spotify.com is Spotify's legacy web-player URL — some browser extensions
        // and older share links resolve here instead of open.spotify.com.
        let block = HostsFileManager.buildBlock(domains: ["spotify.com"])
        #expect(block.contains("127.0.0.1 play.spotify.com"),
                "play.spotify.com must be generated by the \"play\" subdomain prefix")
    }

    @Test func buildBlockIncludesPlaySubdomainForKongregate() {
        // play.kongregate.com is Kongregate's legacy game-host subdomain for HTML5 titles.
        let block = HostsFileManager.buildBlock(domains: ["kongregate.com"])
        #expect(block.contains("127.0.0.1 play.kongregate.com"),
                "play.kongregate.com must be generated by the \"play\" subdomain prefix")
    }

    @Test func parseBlockedFiltersPlaySubdomainVariant() {
        // parseBlocked must skip "play." rows so callers only see bare canonical domains.
        let block = HostsFileManager.buildBlock(domains: ["twitch.tv"])
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(parsed == ["twitch.tv"],
                "parseBlocked must return only the bare canonical domain when play. rows are present")
    }

    @Test func buildThenParseRoundTripWithPlayPrefix() {
        let input = ["twitch.tv", "spotify.com", "kongregate.com"]
        let block  = HostsFileManager.buildBlock(domains: input)
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "build → parse round-trip must be lossless with play. prefix present")
    }

    @Test func playPrefixIsDistinctFromPlayerPrefix() {
        // "play" and "player" are separate prefixes serving different bypass vectors.
        let prefixes = HostsFileManager.additionalBlockedSubdomainPrefixes
        #expect(prefixes.contains("play"),   "\"play\" must be present")
        #expect(prefixes.contains("player"), "\"player\" must still be present after \"play\" addition")
        #expect(prefixes.filter { $0 == "play" }.count == 1,
                "\"play\" must appear exactly once in additionalBlockedSubdomainPrefixes")
        #expect(prefixes.filter { $0 == "player" }.count == 1,
                "\"player\" must appear exactly once in additionalBlockedSubdomainPrefixes")
    }

    @Test func noDuplicatesInAdditionalPrefixesListAfterPlayAddition() {
        let prefixes = HostsFileManager.additionalBlockedSubdomainPrefixes
        #expect(Set(prefixes).count == prefixes.count,
                "no duplicate entries in additionalBlockedSubdomainPrefixes after play. was added")
    }
}

// MARK: - news. subdomain prefix tests

@Suite("HostsFileManager — news. subdomain prefix")
struct NewsPrefixTests {

    @Test func newsPrefixIsInAdditionalPrefixesList() {
        #expect(HostsFileManager.additionalBlockedSubdomainPrefixes.contains("news"),
                "\"news\" must be present in additionalBlockedSubdomainPrefixes")
    }

    @Test func buildBlockIncludesNewsSubdomainForSpotify() {
        // news.spotify.com is Spotify's editorial/articles portal — accessible as a distinct subdomain.
        let block = HostsFileManager.buildBlock(domains: ["spotify.com"])
        #expect(block.contains("127.0.0.1 news.spotify.com"),
                "news.spotify.com must be generated by the \"news\" subdomain prefix")
    }

    @Test func buildBlockIncludesNewsSubdomainForReddit() {
        // news.reddit.com is a legacy news aggregation subdomain on Reddit.
        let block = HostsFileManager.buildBlock(domains: ["reddit.com"])
        #expect(block.contains("127.0.0.1 news.reddit.com"),
                "news.reddit.com must be generated by the \"news\" subdomain prefix")
    }

    @Test func buildBlockIncludesNewsSubdomainForGoogleIfBlocked() {
        // If a user manually blocks google.com (rare but valid), news.google.com must also be blocked.
        let block = HostsFileManager.buildBlock(domains: ["google.com"])
        #expect(block.contains("127.0.0.1 news.google.com"),
                "news.google.com must be generated by the \"news\" prefix when google.com is in the block list")
    }

    @Test func parseBlockedFiltersNewsSubdomainVariant() {
        // parseBlocked must skip "news." rows so callers only see bare canonical domains.
        let block = HostsFileManager.buildBlock(domains: ["reddit.com"])
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(parsed == ["reddit.com"],
                "parseBlocked must return only the bare canonical domain when news. rows are present")
    }

    @Test func buildThenParseRoundTripWithNewsPrefix() {
        let input = ["spotify.com", "reddit.com", "youtube.com"]
        let block  = HostsFileManager.buildBlock(domains: input)
        let parsed = HostsFileManager.parseBlocked(block)
        #expect(Set(parsed) == Set(input),
                "build → parse round-trip must be lossless with news. prefix present")
    }

    @Test func newsPrefixIsDistinctFromPlayPrefix() {
        // "news" and "play" are separate prefixes serving different bypass vectors.
        let prefixes = HostsFileManager.additionalBlockedSubdomainPrefixes
        #expect(prefixes.contains("news"), "\"news\" must be present")
        #expect(prefixes.contains("play"), "\"play\" must still be present after \"news\" addition")
        #expect(prefixes.filter { $0 == "news" }.count == 1,
                "\"news\" must appear exactly once in additionalBlockedSubdomainPrefixes")
    }

    @Test func noDuplicatesInAdditionalPrefixesListAfterNewsAddition() {
        let prefixes = HostsFileManager.additionalBlockedSubdomainPrefixes
        #expect(Set(prefixes).count == prefixes.count,
                "no duplicate entries in additionalBlockedSubdomainPrefixes after news. was added")
    }
}
