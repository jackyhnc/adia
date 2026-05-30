import Foundation

@MainActor
public final class NotchState: ObservableObject {
    public static let shared = NotchState()

    @Published public private(set) var isExpanded: Bool = false
    @Published public private(set) var isCreating: Bool = false
    /// Task text to pre-populate the session creation form. Set by startCreating(prefill:), cleared by stopCreating() and collapse().
    @Published public private(set) var sessionCreationPrefill: String? = nil

    // Callout
    @Published public private(set) var calloutMessage: String? = nil

    // Conversation (reasoning or early-exit)
    @Published public private(set) var showingConversation: Bool = false

    // Verification
    @Published public private(set) var isVerifying: Bool = false
    @Published public private(set) var verificationResult: VerificationResult? = nil

    private init() {}

    // MARK: - Expand / collapse

    public func expand() { isExpanded = true }

    public func collapse() {
        isExpanded = false
        isCreating = false
        sessionCreationPrefill = nil
        showingConversation = false
        calloutMessage = nil
        verificationResult = nil
        isVerifying = false
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

    public func showCallout(_ message: String) {
        calloutMessage = message
        isExpanded = true
    }

    public func clearCallout() { calloutMessage = nil }

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
    }
}
