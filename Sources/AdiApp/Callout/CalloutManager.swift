import Foundation
import AdiCore

/// Selects a callout message based on detection context.
enum CalloutManager {
    private static let firstOffense: [String] = [
        "hey. that's not your essay.",
        "yo, get back to it.",
        "this isn't what you said you'd do.",
        "stop.",
        "that's not your essay.",
    ]

    private static let repeatOffense: [String] = [
        "again?",
        "seriously.",
        "you're wasting your own time.",
        "we talked about this.",
        "come on.",
        "nope.",
    ]

    static func message(for classification: OnTaskClassification) -> String {
        if classification.reason.count < 60 && !classification.reason.isEmpty {
            return classification.reason
        }
        return firstOffense.randomElement() ?? "hey."
    }

    static func repeatMessage() -> String {
        repeatOffense.randomElement() ?? "again?"
    }

    static func message(offTaskCount: Int) -> String {
        if offTaskCount <= 1 {
            return firstOffense.randomElement() ?? "hey."
        }
        return repeatOffense.randomElement() ?? "again?"
    }
}
