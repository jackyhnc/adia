import Foundation

// MARK: - Tiered generic callout pools

extension CalloutManager {
    // Tier 1 (callouts 1–2): friendly but direct
    static let tier1Callouts: [String] = [
        "yo, what are you doing?",
        "stop.",
        "back to work.",
        "that's not why you're here.",
        "focus.",
        "you literally just started.",
        "seriously?",
        "get off that.",
        "c'mon.",
    ]

    // Tier 2 (callouts 3–4): noticeably stronger
    static let tier2Callouts: [String] = [
        "this is the third time.",
        "stop procrastinating.",
        "you keep getting distracted.",
        "get back to work. now.",
        "we're not playing around.",
        "close that. open your work.",
        "still?",
        "what are you doing to yourself.",
    ]

    // Tier 3 (callout 5+): harshest, no-nonsense
    static let tier3Callouts: [String] = [
        "STOP.",
        "you're wasting your own time.",
        "every minute here hurts you.",
        "you asked me to hold you accountable.",
        "the work is not going to do itself.",
        "put it down. right now.",
        "I am not letting this slide.",
    ]
}

// MARK: - Task-aware callout pools

extension CalloutManager {
    /// Returns task-specific callout strings for the given keyword and tier.
    /// Exposed `internal` so unit tests can inspect message content directly.
    internal func taskAwareCallouts(keyword: String, tier: Int) -> [String] {
        switch keyword {
        case "studying":  return studyingCallouts(tier: tier)
        case "reading":   return readingCallouts(tier: tier)
        case "email":     return emailCallouts(tier: tier)
        case "writing":   return writingCallouts(tier: tier)
        case "code":      return codeCallouts(tier: tier)
        case "presentation": return presentationCallouts(tier: tier)
        case "homework":  return homeworkCallouts(tier: tier)
        case "research":  return researchCallouts(tier: tier)
        case "project":   return projectCallouts(tier: tier)
        case "proposal":  return proposalCallouts(tier: tier)
        case "interview": return interviewCallouts(tier: tier)
        case "resume":    return resumeCallouts(tier: tier)
        case "application": return applicationCallouts(tier: tier)
        case "deadline":  return deadlineCallouts(tier: tier)
        case "video":     return videoCallouts(tier: tier)
        case "design":    return designCallouts(tier: tier)
        case "report":    return reportCallouts(tier: tier)
        default:          return genericKeywordCallouts(keyword: keyword, tier: tier)
        }
    }

    // MARK: - Per-keyword message pools

    private func studyingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to studying.",
            "you're not studying right now.",
            "studying won't do itself.",
        ]
        case 2: return [
            "stop putting off studying.",
            "you need to be studying, not doing this.",
        ]
        default: return [
            "CLOSE THIS. Start studying.",
            "your study session is ticking away.",
        ]
        }
    }

    private func readingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to reading.",
            "you're not reading right now.",
            "that reading won't do itself.",
        ]
        case 2: return [
            "stop putting off your reading.",
            "you need to be reading, not doing this.",
        ]
        default: return [
            "CLOSE THIS. Get back to reading.",
            "the reading deadline isn't moving.",
        ]
        }
    }

    private func emailCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those emails aren't going to write themselves.",
            "get back to your email.",
            "close this and go handle that email.",
        ]
        case 2: return [
            "stop avoiding your inbox.",
            "you have emails waiting — not this.",
        ]
        default: return [
            "CLOSE THIS. Go handle your email.",
            "your inbox isn't going to clear itself.",
        ]
        }
    }

    private func writingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your writing.",
            "that post isn't going to write itself.",
            "close this and start writing.",
        ]
        case 2: return [
            "stop putting off your writing.",
            "you need to write, not browse.",
        ]
        default: return [
            "CLOSE THIS. Open your draft.",
            "your writing isn't getting done.",
        ]
        }
    }

    private func codeCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your code.",
            "this isn't your code.",
            "that code isn't going to ship itself.",
        ]
        case 2: return [
            "stop procrastinating on your code.",
            "you need to be writing code, not browsing.",
        ]
        default: return [
            "CLOSE THIS. Commit the code.",
            "your code won't write itself.",
        ]
        }
    }

    private func presentationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your presentation.",
            "this isn't your presentation.",
            "your presentation isn't going to build itself.",
        ]
        case 2: return [
            "stop avoiding your presentation.",
            "you need to be working on your presentation, not this.",
        ]
        default: return [
            "CLOSE THIS. Finish the presentation.",
            "your presentation won't finish itself.",
        ]
        }
    }

    private func homeworkCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your homework.",
            "this isn't your homework.",
            "your homework isn't going to do itself.",
        ]
        case 2: return [
            "stop putting off your homework.",
            "you need to do your homework, not this.",
        ]
        default: return [
            "CLOSE THIS. Go finish your homework.",
            "your homework deadline isn't moving.",
        ]
        }
    }

    private func researchCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your research.",
            "this isn't your research.",
            "your research isn't going to do itself.",
        ]
        case 2: return [
            "stop avoiding your research.",
            "you need to be doing your research, not this.",
        ]
        default: return [
            "CLOSE THIS. Get back to your research.",
            "your research deadline isn't moving.",
        ]
        }
    }

    private func projectCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your project.",
            "this isn't your project.",
            "your project isn't going to finish itself.",
        ]
        case 2: return [
            "stop avoiding your project.",
            "you need to work on your project, not this.",
        ]
        default: return [
            "CLOSE THIS. Go finish your project.",
            "your project deadline is real.",
        ]
        }
    }

    private func proposalCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your proposal.",
            "this isn't your proposal.",
            "your proposal won't write itself.",
        ]
        case 2: return [
            "stop putting off your proposal.",
            "you need to write your proposal, not browse.",
        ]
        default: return [
            "CLOSE THIS. Go finish your proposal.",
            "your proposal deadline isn't moving.",
        ]
        }
    }

    private func interviewCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to interview prep.",
            "your interview isn't going to prep itself.",
            "close this and practice.",
        ]
        case 2: return [
            "stop putting off interview prep.",
            "you need to be practicing, not browsing.",
        ]
        default: return [
            "CLOSE THIS. Go prep for that interview.",
            "your interview is coming — this isn't helping.",
        ]
        }
    }

    private func resumeCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your résumé.",
            "that résumé isn't going to write itself.",
            "close this and keep writing.",
        ]
        case 2: return [
            "stop putting off your résumé.",
            "you need to be writing your résumé, not browsing.",
        ]
        default: return [
            "CLOSE THIS. Finish your résumé.",
            "your résumé deadline isn't moving.",
        ]
        }
    }

    private func applicationCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your application.",
            "that application isn't going to submit itself.",
            "close this and keep writing.",
        ]
        case 2: return [
            "stop putting off your application.",
            "you need to finish your application, not browse.",
        ]
        default: return [
            "CLOSE THIS. Submit the application.",
            "your application deadline isn't moving.",
        ]
        }
    }

    private func deadlineCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "you have a deadline. act like it.",
            "the clock is ticking. get back to work.",
            "deadline incoming — stop.",
        ]
        case 2: return [
            "you're burning deadline time.",
            "you set this deadline. honor it.",
        ]
        default: return [
            "CLOSE THIS. Your deadline is real.",
            "your deadline doesn't care that you're here.",
        ]
        }
    }

    private func videoCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your video.",
            "that video isn't going to edit itself.",
            "close this and keep editing.",
        ]
        case 2: return [
            "stop putting off your video.",
            "you need to be editing, not watching.",
        ]
        default: return [
            "CLOSE THIS. Finish the video.",
            "your video deadline isn't moving.",
        ]
        }
    }

    private func designCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your design.",
            "that design isn't going to finish itself.",
            "close this and keep designing.",
        ]
        case 2: return [
            "stop avoiding your design.",
            "you need to be designing, not browsing.",
        ]
        default: return [
            "CLOSE THIS. Go finish the design.",
            "your design won't complete itself.",
        ]
        }
    }

    private func reportCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your report.",
            "that report isn't going to write itself.",
            "this isn't your report.",
        ]
        case 2: return [
            "stop avoiding your report.",
            "you need to be writing your report, not browsing.",
        ]
        default: return [
            "CLOSE THIS. Go finish the report.",
            "your report deadline isn't moving.",
        ]
        }
    }

    private func genericKeywordCallouts(keyword: String, tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your \(keyword).",
            "this isn't your \(keyword).",
            "your \(keyword) isn't going to finish itself.",
        ]
        case 2: return [
            "stop putting off your \(keyword).",
            "you need to work on your \(keyword), not this.",
        ]
        default: return [
            "CLOSE THIS. open your \(keyword).",
            "your \(keyword) deadline isn't moving.",
        ]
        }
    }
}
