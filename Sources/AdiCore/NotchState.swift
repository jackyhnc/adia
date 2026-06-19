import Foundation

@MainActor
public final class NotchState: ObservableObject {
    public static let shared = NotchState()

    @Published public private(set) var isExpanded: Bool = false
    @Published public private(set) var isCreating: Bool = false
    /// Task text to pre-populate the session creation form. Set by startCreating(prefill:), cleared by stopCreating() and collapse().
    @Published public private(set) var sessionCreationPrefill: String? = nil
    /// Number of pinned templates currently shown in the idle notch. Updated by IdleBody when it loads templates.
    /// Used by NotchWindowController to pick the correct idle panel height.
    @Published public internal(set) var idleTemplateCount: Int = 0
    /// True when the most recent session record has a note. Updated by IdleBody alongside idleTemplateCount.
    /// Used by NotchWindowController to add extra height for the note row.
    @Published public internal(set) var idleHasNote: Bool = false
    /// True when the weekly heatmap has at least one day with sessions. Updated by IdleBody.
    /// Used by NotchWindowController to add extra height for the heatmap row.
    @Published public internal(set) var idleHasHeatmap: Bool = false
    /// True when a daily focus goal is set and there is progress to show. Updated by IdleBody.
    /// Used by NotchWindowController to add extra height for the goal progress row.
    @Published public internal(set) var idleHasDailyGoal: Bool = false

    // Callout
    @Published public private(set) var calloutMessage: String? = nil
    /// Escalation tier for the current callout: 1 = mild, 2 = stronger, 3 = harshest.
    /// Resets to 1 when the callout is cleared.
    @Published public private(set) var calloutTier: Int = 1
    /// The AI's classification reason shown as a subtitle under the callout message
    /// (e.g. "Reddit is open", "YouTube video playing"). nil when not available.
    @Published public private(set) var calloutReason: String? = nil

    // Blocker (escalated, full-screen intervention when a callout is ignored)
    @Published public private(set) var isBlocking: Bool = false
    @Published public private(set) var blockerMessage: String? = nil

    // Conversation (reasoning or early-exit)
    @Published public private(set) var showingConversation: Bool = false

    // Verification
    @Published public private(set) var isVerifying: Bool = false
    @Published public private(set) var verificationResult: VerificationResult? = nil
    /// Ordered list of all verification attempts this session, oldest first.
    /// Appended each time setVerificationResult is called with a non-nil result.
    /// Cleared on collapse() so each session starts fresh.
    @Published public private(set) var verificationHistory: [VerificationAttempt] = []

    private init() {}

    // MARK: - Expand / collapse

    public func expand() { isExpanded = true }

    public func collapse() {
        isExpanded = false
        isCreating = false
        sessionCreationPrefill = nil
        showingConversation = false
        calloutMessage = nil
        calloutTier = 1
        calloutReason = nil
        verificationResult = nil
        isVerifying = false
        isBlocking = false
        blockerMessage = nil
        verificationHistory = []
    }

    public func toggle() { isExpanded.toggle() }

    // MARK: - Session creation

    public func startCreating(prefill: String? = nil) {
        if !isExpanded { isExpanded = true }
        sessionCreationPrefill = prefill
        isCreating = true
    }

    public func stopCreating() {
        isCreating = false
        sessionCreationPrefill = nil
    }

    // MARK: - Callout

    public func showCallout(_ message: String, tier: Int = 1, reason: String? = nil) {
        calloutMessage = message
        calloutTier = tier
        calloutReason = reason
        isExpanded = true
    }

    public func clearCallout() {
        calloutMessage = nil
        calloutTier = 1
        calloutReason = nil
    }

    // MARK: - Blocker

    /// Escalates to the full-screen takeover. Keeps the notch expanded too so the
    /// callout context remains coherent if the takeover is dismissed.
    public func showBlocker(_ message: String) {
        blockerMessage = message
        isBlocking = true
    }

    public func clearBlocker() {
        isBlocking = false
        blockerMessage = nil
    }

    // MARK: - Conversation

    public func startConversation(_ mode: ConversationMode) {
        ConversationManager.shared.start(mode: mode)
        showingConversation = true
        verificationResult = nil
        isVerifying = false
        isExpanded = true
    }

    public func exitConversation() {
        showingConversation = false
        ConversationManager.shared.reset()
    }

    // MARK: - Verification

    public func setVerifying(_ value: Bool) {
        isVerifying = value
        if value {
            verificationResult = nil
            isExpanded = true
        }
    }

    public func setVerificationResult(_ result: VerificationResult?) {
        verificationResult = result
        isVerifying = false
        if let result {
            let attempt = VerificationAttempt(
                result: result,
                attemptNumber: verificationHistory.count + 1
            )
            verificationHistory.append(attempt)
        }
    }

    /// Restores persisted verification history into the live state (called after session restore on launch).
    /// Does not expand or modify any other state — the user resumes in active mode and can retry verification.
    public func restoreVerificationHistory(_ history: [VerificationAttempt]) {
        verificationHistory = history
    }
}
