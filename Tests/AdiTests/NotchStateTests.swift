import Testing
import Foundation
@testable import AdiCore

/// Tests run serially because NotchState.shared is a @MainActor singleton —
/// concurrent access from parallel tests would race on the same published properties.
@Suite("NotchState", .serialized)
struct NotchStateTests {

    private func reset() async {
        await MainActor.run { NotchState.shared.collapse() }
    }

    // MARK: - Expand / collapse / toggle

    @Test func collapseDefaultsToNotExpanded() async {
        await reset()
        let expanded = await MainActor.run { NotchState.shared.isExpanded }
        #expect(expanded == false)
    }

    @Test func expandSetsIsExpanded() async {
        await reset()
        await MainActor.run { NotchState.shared.expand() }
        let expanded = await MainActor.run { NotchState.shared.isExpanded }
        #expect(expanded == true)
    }

    @Test func toggleFlipsExpanded() async {
        await reset()
        await MainActor.run { NotchState.shared.toggle() }
        #expect(await MainActor.run { NotchState.shared.isExpanded } == true)
        await MainActor.run { NotchState.shared.toggle() }
        #expect(await MainActor.run { NotchState.shared.isExpanded } == false)
    }

    @Test func collapseResetsAllUIFlags() async {
        await MainActor.run {
            NotchState.shared.expand()
            NotchState.shared.startCreating(prefill: "my task")
            NotchState.shared.showCallout("yo!")
            NotchState.shared.setVerifying(true)
        }
        await MainActor.run { NotchState.shared.collapse() }
        await MainActor.run {
            #expect(NotchState.shared.isExpanded == false)
            #expect(NotchState.shared.isCreating == false)
            #expect(NotchState.shared.sessionCreationPrefill == nil)
            #expect(NotchState.shared.calloutMessage == nil)
            #expect(NotchState.shared.isVerifying == false)
            #expect(NotchState.shared.verificationResult == nil)
            #expect(NotchState.shared.showingConversation == false)
        }
    }

    // MARK: - Session creation

    @Test func startCreatingSetsIsCreatingAndExpands() async {
        await reset()
        await MainActor.run { NotchState.shared.startCreating() }
        await MainActor.run {
            #expect(NotchState.shared.isCreating == true)
            #expect(NotchState.shared.isExpanded == true)
            #expect(NotchState.shared.sessionCreationPrefill == nil)
        }
    }

    @Test func startCreatingWithPrefillStoresPrefill() async {
        await reset()
        await MainActor.run { NotchState.shared.startCreating(prefill: "finish my essay") }
        await MainActor.run {
            #expect(NotchState.shared.isCreating == true)
            #expect(NotchState.shared.isExpanded == true)
            #expect(NotchState.shared.sessionCreationPrefill == "finish my essay")
        }
    }

    @Test func stopCreatingClearsIsCreatingAndPrefill() async {
        await reset()
        await MainActor.run {
            NotchState.shared.startCreating(prefill: "finish my essay")
            NotchState.shared.stopCreating()
        }
        await MainActor.run {
            #expect(NotchState.shared.isCreating == false)
            #expect(NotchState.shared.sessionCreationPrefill == nil)
        }
    }

    // MARK: - Callout

    @Test func showCalloutSetsMessageAndExpands() async {
        await reset()
        await MainActor.run { NotchState.shared.showCallout("focus.") }
        await MainActor.run {
            #expect(NotchState.shared.calloutMessage == "focus.")
            #expect(NotchState.shared.isExpanded == true)
        }
    }

    @Test func clearCalloutRemovesMessage() async {
        await MainActor.run {
            NotchState.shared.showCallout("stop.")
            NotchState.shared.clearCallout()
        }
        let msg = await MainActor.run { NotchState.shared.calloutMessage }
        #expect(msg == nil)
    }

    // MARK: - Callout tier

    @Test func showCalloutDefaultsTierToOne() async {
        await reset()
        await MainActor.run { NotchState.shared.showCallout("focus.") }
        let tier = await MainActor.run { NotchState.shared.calloutTier }
        #expect(tier == 1)
    }

    @Test func showCalloutWithTierSetsCalloutTier() async {
        await reset()
        await MainActor.run { NotchState.shared.showCallout("STOP.", tier: 3) }
        await MainActor.run {
            #expect(NotchState.shared.calloutTier == 3)
            #expect(NotchState.shared.calloutMessage == "STOP.")
        }
    }

    @Test func clearCalloutResetsTierToOne() async {
        await reset()
        await MainActor.run {
            NotchState.shared.showCallout("STOP.", tier: 3)
            NotchState.shared.clearCallout()
        }
        let tier = await MainActor.run { NotchState.shared.calloutTier }
        #expect(tier == 1)
    }

    @Test func collapseResetsTierToOne() async {
        await MainActor.run {
            NotchState.shared.showCallout("STOP.", tier: 3)
            NotchState.shared.collapse()
        }
        let tier = await MainActor.run { NotchState.shared.calloutTier }
        #expect(tier == 1)
    }

    // MARK: - Verification

    @Test func setVerifyingTrueExpandsAndClearsResult() async {
        await reset()
        await MainActor.run {
            // Pre-seed a result to confirm it gets cleared when verifying starts.
            NotchState.shared.setVerificationResult(VerificationResult(verified: true, explanation: "done"))
            NotchState.shared.setVerifying(true)
        }
        await MainActor.run {
            #expect(NotchState.shared.isVerifying == true)
            #expect(NotchState.shared.isExpanded == true)
            #expect(NotchState.shared.verificationResult == nil)
        }
    }

    @Test func setVerifyingFalseDoesNotExpand() async {
        await reset()
        await MainActor.run { NotchState.shared.setVerifying(false) }
        #expect(await MainActor.run { NotchState.shared.isExpanded } == false)
    }

    @Test func setVerificationResultClearsVerifying() async {
        await reset()
        await MainActor.run {
            NotchState.shared.setVerifying(true)
            NotchState.shared.setVerificationResult(VerificationResult(verified: false, explanation: "not yet"))
        }
        await MainActor.run {
            #expect(NotchState.shared.isVerifying == false)
            #expect(NotchState.shared.verificationResult?.verified == false)
            #expect(NotchState.shared.verificationResult?.explanation == "not yet")
        }
    }

    @Test func setVerificationResultNilClearsResult() async {
        await reset()
        await MainActor.run {
            NotchState.shared.setVerificationResult(VerificationResult(verified: true, explanation: "good"))
            NotchState.shared.setVerificationResult(nil)
        }
        let result = await MainActor.run { NotchState.shared.verificationResult }
        #expect(result == nil)
    }

    // MARK: - Conversation

    @Test func exitConversationClearsShowingConversation() async {
        await reset()
        await MainActor.run {
            // startConversation also calls ConversationManager — just verify the flag.
            NotchState.shared.startConversation(.earlyExit)
        }
        await MainActor.run {
            #expect(NotchState.shared.showingConversation == true)
            #expect(NotchState.shared.isExpanded == true)
        }
        await MainActor.run { NotchState.shared.exitConversation() }
        let showing = await MainActor.run { NotchState.shared.showingConversation }
        #expect(showing == false)
    }

    @Test func startConversationClearsVerificationResult() async {
        await reset()
        await MainActor.run {
            NotchState.shared.setVerificationResult(VerificationResult(verified: true, explanation: "done"))
            NotchState.shared.startConversation(.reasoning(domain: nil))
        }
        let result = await MainActor.run { NotchState.shared.verificationResult }
        #expect(result == nil)
    }
}
