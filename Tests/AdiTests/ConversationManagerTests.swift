import Testing
import Foundation
@testable import AdiCore

/// Tests run serially: ConversationManager.shared is a @MainActor singleton.
/// Without .serialized, concurrent tests can interleave between MainActor.run calls and race.
@Suite("ConversationManager", .serialized)
struct ConversationManagerTests {

    private func reset() async {
        await MainActor.run {
            ConversationManager.shared.reset()
        }
    }

    // MARK: - start(mode:)

    @Test func startReasoningSeedsOpeningMessage() async {
        await reset()
        await MainActor.run {
            ConversationManager.shared.start(mode: .reasoning(domain: "youtube.com"))
        }
        let messages = await MainActor.run { ConversationManager.shared.messages }
        #expect(messages.count == 1)
        #expect(messages[0].role == .assistant)
        #expect(messages[0].content.contains("youtube.com"))
    }

    @Test func startReasoningNilDomainUsesGenericOpening() async {
        await reset()
        await MainActor.run {
            ConversationManager.shared.start(mode: .reasoning(domain: nil))
        }
        let messages = await MainActor.run { ConversationManager.shared.messages }
        #expect(messages.count == 1)
        // nil domain should say "what's up?" not ask about a specific site
        #expect(messages[0].content == "what's up?")
    }

    @Test func startReasoningEmptyDomainUsesGenericOpening() async {
        await reset()
        await MainActor.run {
            ConversationManager.shared.start(mode: .reasoning(domain: ""))
        }
        let messages = await MainActor.run { ConversationManager.shared.messages }
        #expect(messages.count == 1)
        #expect(messages[0].content == "what's up?")
    }

    @Test func startReasoningWithDomainMentionsDomainInOpening() async {
        await reset()
        await MainActor.run {
            ConversationManager.shared.start(mode: .reasoning(domain: "twitter.com"))
        }
        let messages = await MainActor.run { ConversationManager.shared.messages }
        #expect(messages.count == 1)
        #expect(messages[0].content.contains("twitter.com"))
    }

    @Test func startEarlyExitSeedsOpeningMessage() async {
        await reset()
        await MainActor.run {
            ConversationManager.shared.start(mode: .earlyExit)
        }
        let messages = await MainActor.run { ConversationManager.shared.messages }
        #expect(messages.count == 1)
        #expect(messages[0].role == .assistant)
        #expect(!messages[0].content.isEmpty)
    }

    // MARK: - reset()

    @Test func resetClearsMessages() async {
        await MainActor.run {
            ConversationManager.shared.start(mode: .earlyExit)
        }
        await reset()
        let messages = await MainActor.run { ConversationManager.shared.messages }
        #expect(messages.isEmpty)
    }

    @Test func resetClearsMode() async {
        await MainActor.run {
            ConversationManager.shared.start(mode: .earlyExit)
        }
        await reset()
        let mode = await MainActor.run { ConversationManager.shared.mode }
        #expect(mode == nil)
    }

    @Test func resetClearsAccessGranted() async {
        await MainActor.run {
            ConversationManager.shared.start(mode: .reasoning(domain: "test.com"))
        }
        await reset()
        let granted = await MainActor.run { ConversationManager.shared.accessGranted }
        #expect(granted == nil)
    }

    @Test func resetClearsIsLoading() async {
        await reset()
        let loading = await MainActor.run { ConversationManager.shared.isLoading }
        #expect(loading == false)
    }

    // MARK: - parseAccessDecision (static pure helper)

    @Test func parseGrantedReturnsTrue() {
        #expect(ConversationManager.parseAccessDecision(in: "Sure thing! [ACCESS GRANTED]") == true)
    }

    @Test func parseDeniedReturnsFalse() {
        #expect(ConversationManager.parseAccessDecision(in: "Not today. [ACCESS DENIED]") == false)
    }

    @Test func parseNeitherReturnsNil() {
        #expect(ConversationManager.parseAccessDecision(in: "Let me think about that...") == nil)
    }

    @Test func parseEmptyStringReturnsNil() {
        #expect(ConversationManager.parseAccessDecision(in: "") == nil)
    }

    @Test func parseGrantedMidSentence() {
        let reply = "This is clearly task-relevant. [ACCESS GRANTED] Good luck!"
        #expect(ConversationManager.parseAccessDecision(in: reply) == true)
    }

    @Test func parseDeniedAtStart() {
        let reply = "[ACCESS DENIED] Focus on your work."
        #expect(ConversationManager.parseAccessDecision(in: reply) == false)
    }

    // MARK: - summarize (static pure helper)

    @Test func summarizeStripsDecisionTags() {
        let messages = [ChatMessage(role: .assistant, content: "this is genuinely relevant. [ACCESS GRANTED]")]
        let summary = ConversationManager.summarize(messages: messages)
        #expect(!summary.contains("[ACCESS GRANTED]"))
        #expect(summary == "this is genuinely relevant.")
    }

    @Test func summarizeTruncatesLongReplies() {
        let long = String(repeating: "a", count: 300)
        let messages = [ChatMessage(role: .assistant, content: long)]
        let summary = ConversationManager.summarize(messages: messages, maxLength: 50)
        #expect(summary.count <= 51) // 50 chars + ellipsis
        #expect(summary.hasSuffix("…"))
    }

    @Test func summarizeUsesLastAssistantMessage() {
        let messages = [
            ChatMessage(role: .assistant, content: "first take. [ACCESS DENIED]"),
            ChatMessage(role: .user, content: "but it's for research!"),
            ChatMessage(role: .assistant, content: "still no. [ACCESS DENIED]"),
        ]
        let summary = ConversationManager.summarize(messages: messages)
        #expect(summary == "still no.")
    }

    @Test func summarizeEmptyMessagesReturnsEmptyString() {
        #expect(ConversationManager.summarize(messages: []) == "")
    }

    @Test func summarizeIgnoresUserOnlyMessages() {
        let messages = [ChatMessage(role: .user, content: "hello")]
        #expect(ConversationManager.summarize(messages: messages) == "")
    }

    // MARK: - memoryFragment (static pure helper)

    @Test func memoryFragmentEmptyForNoHistory() {
        #expect(ConversationManager.memoryFragment(for: "youtube.com", history: []) == "")
    }

    @Test func memoryFragmentEmptyForUnrelatedDomain() {
        let history = [ReasoningAttempt(domain: "reddit.com", granted: false, summary: "not relevant")]
        #expect(ConversationManager.memoryFragment(for: "youtube.com", history: history) == "")
    }

    @Test func memoryFragmentEmptyForBlankDomain() {
        let history = [ReasoningAttempt(domain: "reddit.com", granted: false, summary: "not relevant")]
        #expect(ConversationManager.memoryFragment(for: "  ", history: history) == "")
    }

    @Test func memoryFragmentIncludesPriorVerdictAndReason() {
        let history = [ReasoningAttempt(domain: "youtube.com", granted: false, summary: "no academic justification")]
        let fragment = ConversationManager.memoryFragment(for: "youtube.com", history: history)
        #expect(fragment.contains("DENIED"))
        #expect(fragment.contains("no academic justification"))
        #expect(fragment.contains("once"))
    }

    @Test func memoryFragmentIsCaseInsensitiveOnDomain() {
        let history = [ReasoningAttempt(domain: "YouTube.com", granted: true, summary: "needed for lecture video")]
        let fragment = ConversationManager.memoryFragment(for: "youtube.com", history: history)
        #expect(fragment.contains("GRANTED"))
    }

    @Test func memoryFragmentCountsMultiplePriorAttempts() {
        let history = [
            ReasoningAttempt(domain: "reddit.com", granted: false, summary: "weak excuse #1"),
            ReasoningAttempt(domain: "reddit.com", granted: false, summary: "weak excuse #2"),
        ]
        let fragment = ConversationManager.memoryFragment(for: "reddit.com", history: history)
        #expect(fragment.contains("2 times"))
        #expect(fragment.contains("weak excuse #1"))
        #expect(fragment.contains("weak excuse #2"))
    }

    @Test func memoryFragmentFallsBackWhenSummaryMissing() {
        let history = [ReasoningAttempt(domain: "x.com", granted: false, summary: "")]
        let fragment = ConversationManager.memoryFragment(for: "x.com", history: history)
        #expect(fragment.contains("no reason recorded"))
    }

    // MARK: - crossDomainSignal (static pure helper)

    @Test func crossDomainSignalEmptyForNoHistory() {
        #expect(ConversationManager.crossDomainSignal(for: "youtube.com", history: []) == "")
    }

    @Test func crossDomainSignalEmptyForBlankDomain() {
        let history = [ReasoningAttempt(domain: "reddit.com", granted: false, summary: "no")]
        #expect(ConversationManager.crossDomainSignal(for: "  ", history: history) == "")
    }

    @Test func crossDomainSignalEmptyWhenOnlyOneOtherDomain() {
        let history = [
            ReasoningAttempt(domain: "reddit.com", granted: false, summary: "weak"),
            ReasoningAttempt(domain: "reddit.com", granted: false, summary: "weaker"),
        ]
        #expect(ConversationManager.crossDomainSignal(for: "youtube.com", history: history) == "")
    }

    @Test func crossDomainSignalEmptyWhenOthersWereMostlyGranted() {
        let history = [
            ReasoningAttempt(domain: "reddit.com", granted: true, summary: "lecture thread"),
            ReasoningAttempt(domain: "x.com", granted: true, summary: "professor's announcement"),
            ReasoningAttempt(domain: "tumblr.com", granted: false, summary: "weak excuse"),
        ]
        #expect(ConversationManager.crossDomainSignal(for: "youtube.com", history: history) == "")
    }

    @Test func crossDomainSignalFiresWhenMultipleDistinctDomainsMostlyDenied() {
        let history = [
            ReasoningAttempt(domain: "reddit.com", granted: false, summary: "no"),
            ReasoningAttempt(domain: "x.com", granted: false, summary: "no"),
            ReasoningAttempt(domain: "tumblr.com", granted: true, summary: "ok fine"),
        ]
        let signal = ConversationManager.crossDomainSignal(for: "youtube.com", history: history)
        #expect(signal.contains("3 other sites"))
        #expect(signal.contains("2 of those asks were denied"))
        #expect(signal.contains("1 granted"))
        #expect(signal.contains("testing your limits"))
    }

    @Test func crossDomainSignalExcludesCurrentDomainFromCount() {
        let history = [
            ReasoningAttempt(domain: "youtube.com", granted: false, summary: "earlier ask"),
            ReasoningAttempt(domain: "reddit.com", granted: false, summary: "no"),
            ReasoningAttempt(domain: "x.com", granted: false, summary: "no"),
        ]
        let signal = ConversationManager.crossDomainSignal(for: "youtube.com", history: history)
        #expect(signal.contains("2 other sites"))
        #expect(!signal.contains("youtube.com has asked"))
    }

    @Test func crossDomainSignalIsCaseInsensitiveOnCurrentDomain() {
        let history = [
            ReasoningAttempt(domain: "YouTube.com", granted: false, summary: "earlier ask"),
            ReasoningAttempt(domain: "reddit.com", granted: false, summary: "no"),
            ReasoningAttempt(domain: "x.com", granted: false, summary: "no"),
        ]
        let signal = ConversationManager.crossDomainSignal(for: "youtube.com", history: history)
        #expect(signal.contains("2 other sites"))
    }

    @Test func crossDomainSignalDedupesRepeatedAsksToSameOtherDomain() {
        let history = [
            ReasoningAttempt(domain: "reddit.com", granted: false, summary: "weak excuse #1"),
            ReasoningAttempt(domain: "reddit.com", granted: false, summary: "weak excuse #2"),
            ReasoningAttempt(domain: "x.com", granted: false, summary: "no"),
        ]
        let signal = ConversationManager.crossDomainSignal(for: "youtube.com", history: history)
        #expect(signal.contains("2 other sites"))
        #expect(signal.contains("3 of those asks were denied"))
    }

    // MARK: - send(_:) — exercised end-to-end via the injected mock agent client

    /// `send` previously could only be exercised against the real `AgentAIClient`
    /// (a live network round-trip requiring `ANTHROPIC_API_KEY`). The
    /// `_injectAIClientForTesting` seam lets it run deterministically in CI: the
    /// mock returns a canned reply containing `[ACCESS GRANTED]`, and this asserts
    /// the full pipeline — message append, decision parsing, `accessGranted`,
    /// `isLoading` toggling — runs correctly off of it.
    @Test func sendAppendsReplyAndParsesGrantedDecisionFromMockChat() async {
        await reset()
        let mock = MockAgentAIClient()
        await mock.setChatResult(.success("That's clearly relevant to your essay. [ACCESS GRANTED]"))
        let realClient = await MainActor.run { ConversationManager.shared._aiClient }
        await MainActor.run {
            ConversationManager.shared._injectAIClientForTesting(mock)
            ConversationManager.shared.start(mode: .reasoning(domain: "docs.google.com"))
            ConversationManager.shared.send("I need this to cite a source in my essay")
        }

        // Poll for completion instead of a fixed sleep — `send` resolves as soon as
        // the (synchronous, in-memory) mock's `chat` returns.
        for _ in 0..<200 {
            let stillLoading = await MainActor.run { ConversationManager.shared.isLoading }
            if !stillLoading { break }
            try? await Task.sleep(for: .milliseconds(10))
        }

        let messages = await MainActor.run { ConversationManager.shared.messages }
        let granted = await MainActor.run { ConversationManager.shared.accessGranted }
        #expect(messages.count == 3, "opening + user + assistant reply")
        #expect(messages[1].role == .user)
        #expect(messages[1].content == "I need this to cite a source in my essay")
        #expect(messages[2].role == .assistant)
        #expect(messages[2].content.contains("[ACCESS GRANTED]"))
        #expect(granted == true)
        #expect(await mock.chatCallCount == 1)

        await MainActor.run { ConversationManager.shared._injectAIClientForTesting(realClient) }
        await reset()
    }

    @Test func sendSurfacesFallbackMessageWhenChatThrows() async {
        await reset()
        let mock = MockAgentAIClient()
        await mock.setChatResult(.failure(MockAgentAIError(message: "network down")))
        let realClient = await MainActor.run { ConversationManager.shared._aiClient }
        await MainActor.run {
            ConversationManager.shared._injectAIClientForTesting(mock)
            ConversationManager.shared.start(mode: .earlyExit)
            ConversationManager.shared.send("never mind, I'll keep going")
        }

        for _ in 0..<200 {
            let stillLoading = await MainActor.run { ConversationManager.shared.isLoading }
            if !stillLoading { break }
            try? await Task.sleep(for: .milliseconds(10))
        }

        let messages = await MainActor.run { ConversationManager.shared.messages }
        #expect(messages.count == 3)
        #expect(messages[2].role == .assistant)
        #expect(messages[2].content == "something went wrong. try again.")
        // earlyExit mode never sets accessGranted, regardless of chat outcome
        let granted = await MainActor.run { ConversationManager.shared.accessGranted }
        #expect(granted == nil)

        await MainActor.run { ConversationManager.shared._injectAIClientForTesting(realClient) }
        await reset()
    }

    /// After streaming completes (success or failure), `streamingContent` must be nil
    /// so the streaming bubble is removed from the UI and replaced by the final message.
    @Test func streamingContentIsNilAfterSuccessfulChat() async {
        await reset()
        let mock = MockAgentAIClient()
        await mock.setChatResult(.success("you're doing great, keep it up"))
        let realClient = await MainActor.run { ConversationManager.shared._aiClient }
        await MainActor.run {
            ConversationManager.shared._injectAIClientForTesting(mock)
            ConversationManager.shared.start(mode: .earlyExit)
            ConversationManager.shared.send("I'll keep going")
        }

        for _ in 0..<200 {
            let stillLoading = await MainActor.run { ConversationManager.shared.isLoading }
            if !stillLoading { break }
            try? await Task.sleep(for: .milliseconds(10))
        }

        let streaming = await MainActor.run { ConversationManager.shared.streamingContent }
        #expect(streaming == nil, "streamingContent must be nil after chat completes")
        let messages = await MainActor.run { ConversationManager.shared.messages }
        #expect(messages.last?.content == "you're doing great, keep it up")

        await MainActor.run { ConversationManager.shared._injectAIClientForTesting(realClient) }
        await reset()
    }

    @Test func streamingContentIsNilAfterFailedChat() async {
        await reset()
        let mock = MockAgentAIClient()
        await mock.setChatResult(.failure(MockAgentAIError(message: "timeout")))
        let realClient = await MainActor.run { ConversationManager.shared._aiClient }
        await MainActor.run {
            ConversationManager.shared._injectAIClientForTesting(mock)
            ConversationManager.shared.start(mode: .earlyExit)
            ConversationManager.shared.send("let me out")
        }

        for _ in 0..<200 {
            let stillLoading = await MainActor.run { ConversationManager.shared.isLoading }
            if !stillLoading { break }
            try? await Task.sleep(for: .milliseconds(10))
        }

        let streaming = await MainActor.run { ConversationManager.shared.streamingContent }
        #expect(streaming == nil, "streamingContent must be nil even after error")

        await MainActor.run { ConversationManager.shared._injectAIClientForTesting(realClient) }
        await reset()
    }

    @Test func resetClearsStreamingContent() async {
        await reset()
        let streaming = await MainActor.run { ConversationManager.shared.streamingContent }
        #expect(streaming == nil)
    }

    // MARK: - Strong model routing

    /// Every conversation mode (reasoning + early-exit) should use the strong model so
    /// the AI is more persuasive / nuanced for high-stakes human-facing interactions.
    @Test func sendUsesStrongModelForReasoningConversation() async {
        await reset()
        let mock = MockAgentAIClient()
        await mock.setChatResult(.success("ok sure [ACCESS GRANTED]"))
        let realClient = await MainActor.run { ConversationManager.shared._aiClient }
        await MainActor.run {
            ConversationManager.shared._injectAIClientForTesting(mock)
            ConversationManager.shared.start(mode: .reasoning(domain: "docs.google.com"))
            ConversationManager.shared.send("I need this for citations")
        }
        for _ in 0..<200 {
            let still = await MainActor.run { ConversationManager.shared.isLoading }
            if !still { break }
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(await mock.lastUseStrongModel == true, "reasoning conversation must use strong model")
        await MainActor.run { ConversationManager.shared._injectAIClientForTesting(realClient) }
        await reset()
    }

    @Test func sendUsesStrongModelForEarlyExitConversation() async {
        await reset()
        let mock = MockAgentAIClient()
        await mock.setChatResult(.success("you've got this, keep going"))
        let realClient = await MainActor.run { ConversationManager.shared._aiClient }
        await MainActor.run {
            ConversationManager.shared._injectAIClientForTesting(mock)
            ConversationManager.shared.start(mode: .earlyExit)
            ConversationManager.shared.send("I'm tired")
        }
        for _ in 0..<200 {
            let still = await MainActor.run { ConversationManager.shared.isLoading }
            if !still { break }
            try? await Task.sleep(for: .milliseconds(10))
        }
        #expect(await mock.lastUseStrongModel == true, "early-exit conversation must use strong model")
        await MainActor.run { ConversationManager.shared._injectAIClientForTesting(realClient) }
        await reset()
    }
}
