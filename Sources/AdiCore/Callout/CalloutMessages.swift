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
        case "essay":     return essayCallouts(tier: tier)
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
        case "meeting":   return meetingCallouts(tier: tier)
        case "resume":    return resumeCallouts(tier: tier)
        case "application": return applicationCallouts(tier: tier)
        case "paper":     return paperCallouts(tier: tier)
        case "thesis":    return thesisCallouts(tier: tier)
        case "deadline":  return deadlineCallouts(tier: tier)
        case "video":     return videoCallouts(tier: tier)
        case "design":    return designCallouts(tier: tier)
        case "report":    return reportCallouts(tier: tier)
        case "budget":    return budgetCallouts(tier: tier)
        case "tutor":     return tutorCallouts(tier: tier)
        case "practice":  return practiceCallouts(tier: tier)
        case "planning":  return planningCallouts(tier: tier)
        case "music":     return musicCallouts(tier: tier)
        case "language":  return languageCallouts(tier: tier)
        case "fitness":   return fitnessCallouts(tier: tier)
        case "podcast":   return podcastCallouts(tier: tier)
        case "art":       return artCallouts(tier: tier)
        case "journaling": return journalingCallouts(tier: tier)
        case "legal":        return legalCallouts(tier: tier)
        case "premed":       return premedCallouts(tier: tier)
        case "architecture": return architectureCallouts(tier: tier)
        case "startup":      return startupCallouts(tier: tier)
        case "nursing":      return nursingCallouts(tier: tier)
        case "photography":  return photographyCallouts(tier: tier)
        case "datascience":  return datascienceCallouts(tier: tier)
        case "gamedev":      return gamedevCallouts(tier: tier)
        case "engineering":  return engineeringCallouts(tier: tier)
        case "therapy":      return therapyCallouts(tier: tier)
        default:             return genericKeywordCallouts(keyword: keyword, tier: tier)
        }
    }

    // MARK: - Per-keyword message pools

    private func essayCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "this isn't your essay.",
            "get back to your essay.",
            "your essay won't write itself.",
            "close this and write your essay.",
        ]
        case 2: return [
            "stop avoiding your essay.",
            "you need to write your essay, not browse.",
            "your essay isn't going to write itself — get back to it.",
        ]
        default: return [
            "CLOSE THIS. your essay won't write itself.",
            "your essay deadline is real.",
            "put the phone down. your essay is waiting.",
        ]
        }
    }

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

    private func paperCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your paper.",
            "that paper won't write itself.",
            "close this. write the paper.",
            "this isn't your paper.",
        ]
        case 2: return [
            "stop avoiding your paper.",
            "you need to be writing your paper, not browsing.",
            "your paper won't finish itself.",
        ]
        default: return [
            "CLOSE THIS. Your paper is waiting.",
            "your paper deadline is real.",
            "put it down. your paper needs you.",
        ]
        }
    }

    private func thesisCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your thesis.",
            "your thesis won't write itself.",
            "close this and work on your thesis.",
        ]
        case 2: return [
            "stop avoiding your thesis.",
            "you need to be writing your thesis, not this.",
            "your thesis isn't going to write itself.",
        ]
        default: return [
            "CLOSE THIS. Your thesis needs you.",
            "your thesis deadline is not moving.",
            "years on this thesis. don't blow it now.",
        ]
        }
    }

    private func meetingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "you have a meeting to prep for.",
            "your agenda isn't going to write itself.",
            "get back to your meeting prep.",
            "close this and prep for your meeting.",
        ]
        case 2: return [
            "stop avoiding your meeting prep.",
            "the meeting is coming — prep, not this.",
            "your meeting won't go well if you're here.",
        ]
        default: return [
            "CLOSE THIS. You have a meeting to prepare for.",
            "you'll walk in unprepared. close it now.",
            "your meeting doesn't care that you got distracted.",
        ]
        }
    }

    private func budgetCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your budget.",
            "those numbers aren't going to enter themselves.",
            "close this and work on your finances.",
        ]
        case 2: return [
            "stop putting off your finances.",
            "your budget won't balance itself.",
            "you need to work on your finances, not browse.",
        ]
        default: return [
            "CLOSE THIS. Your finances need attention.",
            "your budget deadline isn't moving.",
            "the numbers won't add up while you're here.",
        ]
        }
    }

    private func planningCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your planning.",
            "that plan isn't going to make itself.",
            "close this and keep planning.",
        ]
        case 2: return [
            "stop putting off your planning.",
            "you need to be planning, not browsing.",
            "your plans won't make themselves.",
        ]
        default: return [
            "CLOSE THIS. Go finish your plan.",
            "your planning isn't done yet.",
            "put it down. the plan needs work.",
        ]
        }
    }

    private func tutorCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your students.",
            "your lesson plan isn't going to write itself.",
            "close this and prep for your class.",
            "your students are counting on you to be ready.",
        ]
        case 2: return [
            "stop browsing. your students need you prepared.",
            "you're supposed to be planning a lesson, not this.",
            "those students deserve your full attention.",
        ]
        default: return [
            "CLOSE THIS. Your students need this prep.",
            "your class starts and you're browsing. close it.",
            "put it down. they're counting on you.",
        ]
        }
    }

    private func practiceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to practicing.",
            "the reps don't count themselves.",
            "close this and keep practicing.",
            "you don't improve by stopping.",
        ]
        case 2: return [
            "you get better by doing, not browsing.",
            "close this and put in the reps.",
            "you need the practice, not this.",
        ]
        default: return [
            "CLOSE THIS. Put in the practice.",
            "you won't improve by being here.",
            "close it. go practice.",
        ]
        }
    }

    private func musicCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your music.",
            "those lyrics won't write themselves.",
            "close this and keep creating.",
            "the track isn't going to finish itself.",
        ]
        case 2: return [
            "stop browsing. finish the song.",
            "you can't produce if you're not in the DAW.",
            "close this and get back to the beat.",
        ]
        default: return [
            "CLOSE THIS. Go finish your track.",
            "the music won't make itself.",
            "put it down. the session needs you.",
        ]
        }
    }

    private func languageCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to practicing.",
            "fluency takes daily reps — close this.",
            "your vocab won't grow by browsing.",
            "close this and get back to your lesson.",
        ]
        case 2: return [
            "stop avoiding the hard part. keep going.",
            "you can't get fluent by being here.",
            "close this and do the next exercise.",
        ]
        default: return [
            "CLOSE THIS. Go practice your language.",
            "consistency is the only thing that works. close it.",
            "fluency is built rep by rep — go back.",
        ]
        }
    }

    private func fitnessCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your workout.",
            "the reps don't count themselves.",
            "close this and get moving.",
            "you won't make gains from here.",
        ]
        case 2: return [
            "stop delaying. put in the work.",
            "you're supposed to be working out, not browsing.",
            "close this and finish your session.",
        ]
        default: return [
            "CLOSE THIS. Go finish your workout.",
            "progress is made in the gym, not here.",
            "put it down. the work is waiting.",
        ]
        }
    }

    private func podcastCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your episode.",
            "those show notes won't write themselves.",
            "close this and keep recording.",
            "the episode isn't going to edit itself.",
        ]
        case 2: return [
            "stop browsing. finish the episode.",
            "you can't produce a podcast from here.",
            "close this and get back to the recording.",
        ]
        default: return [
            "CLOSE THIS. Go finish your episode.",
            "the podcast won't produce itself.",
            "put it down. your listeners are waiting.",
        ]
        }
    }

    private func artCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "get back to your drawing.",
            "the canvas won't fill itself.",
            "close this and keep creating.",
            "your work isn't going to make itself.",
        ]
        case 2: return [
            "stop browsing. pick up the pen.",
            "you can't make art from here.",
            "close this and get back to your piece.",
        ]
        default: return [
            "CLOSE THIS. Go finish your work.",
            "the piece won't paint itself.",
            "put it down. the canvas is waiting.",
        ]
        }
    }

    private func journalingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your journal's still empty.",
            "thoughts don't write themselves.",
            "go back to your journal.",
            "close this and write.",
        ]
        case 2: return [
            "stop. open your journal.",
            "this isn't your journal entry.",
            "you came here to write. so write.",
        ]
        default: return [
            "CLOSE THIS. your journal is waiting.",
            "you opened Adia to journal. that's not this.",
            "the entry won't write itself. get back.",
        ]
        }
    }

    private func legalCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your brief isn't going to write itself.",
            "get back to your legal work.",
            "close this and open your brief.",
            "the deadline won't move.",
        ]
        case 2: return [
            "stop. your brief is waiting.",
            "this isn't case prep.",
            "you're billing distraction time right now.",
        ]
        default: return [
            "CLOSE THIS. open your brief.",
            "you're not going to pass the bar by scrolling.",
            "the brief doesn't write itself. get back.",
        ]
        }
    }

    private func premedCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "the MCAT isn't going to prep itself.",
            "that's not your anatomy notes.",
            "get back to your med school work.",
            "your future patients are counting on you.",
        ]
        case 2: return [
            "stop. anatomy waits for no one.",
            "this isn't MCAT prep.",
            "you can't diagnose patients if you don't study.",
        ]
        default: return [
            "CLOSE THIS. open your anatomy notes.",
            "the boards don't care what you were scrolling. get back.",
            "med school doesn't pause. neither should you.",
        ]
        }
    }

    private func architectureCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your drawings won't finish themselves.",
            "get back to the studio work.",
            "that model isn't building itself.",
            "close this. keep designing.",
        ]
        case 2: return [
            "stop. the crit is coming.",
            "you can't get pinned up by scrolling.",
            "your design won't finish itself — get back.",
        ]
        default: return [
            "CLOSE THIS. open your drawings.",
            "the deadline doesn't move. your model does.",
            "your studio crit is coming — this isn't prep.",
        ]
        }
    }

    private func startupCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your pitch deck isn't going to write itself.",
            "get back to building your startup.",
            "your co-founder is working. you're not.",
            "close this and work on your business.",
        ]
        case 2: return [
            "stop. your pitch won't close itself.",
            "this isn't building your startup.",
            "investors don't fund distraction. get back.",
        ]
        default: return [
            "CLOSE THIS. your deck is waiting.",
            "no one funds a founder who's scrolling.",
            "the startup doesn't build itself. back to work.",
        ]
        }
    }

    private func nursingCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "that care plan isn't going to write itself.",
            "get back to your nursing notes.",
            "your patients need you focused. so does your care plan.",
            "close this and get back to charting.",
        ]
        case 2: return [
            "stop. your care plan is due.",
            "this isn't your clinical documentation.",
            "nurses stay focused. get back to work.",
        ]
        default: return [
            "CLOSE THIS. open your care plan.",
            "you can't care for patients by scrolling. get back.",
            "your clinical notes don't write themselves — back to work.",
        ]
        }
    }

    private func photographyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those photos aren't going to edit themselves.",
            "get back to Lightroom.",
            "close this and open your editing.",
            "your raw files are waiting for you.",
        ]
        case 2: return [
            "stop. your client wants these edits.",
            "this isn't your color grade.",
            "you can't ship photos by scrolling — get back.",
        ]
        default: return [
            "CLOSE THIS. open your RAW files.",
            "your client is waiting for these edits — get back.",
            "the photos don't grade themselves. back to Lightroom.",
        ]
        }
    }

    private func datascienceCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your model isn't going to train itself.",
            "get back to your notebook.",
            "the data won't analyze itself — close this.",
            "your jupyter notebook is waiting.",
        ]
        case 2: return [
            "stop. your model is waiting.",
            "this isn't your training run.",
            "your dataset doesn't clean itself — get back.",
        ]
        default: return [
            "CLOSE THIS. open your jupyter notebook.",
            "no one trains models by scrolling.",
            "your model won't converge while you're here — back to work.",
        ]
        }
    }

    private func gamedevCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your game isn't going to build itself.",
            "get back to your game project.",
            "close this and open your game engine.",
            "your levels aren't going to design themselves.",
        ]
        case 2: return [
            "stop. your game jam deadline is real.",
            "this isn't your game dev work.",
            "you can't ship a game from here.",
        ]
        default: return [
            "CLOSE THIS. open Unity.",
            "no one ships games by scrolling.",
            "your build won't compile itself — back to work.",
        ]
        }
    }

    private func engineeringCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "your design isn't going to solve itself.",
            "get back to your engineering work.",
            "close this and open your CAD file.",
            "that circuit isn't going to design itself.",
        ]
        case 2: return [
            "stop. your lab report won't write itself.",
            "this isn't your engineering homework.",
            "you can't solve a free-body diagram from here.",
        ]
        default: return [
            "CLOSE THIS. open SolidWorks.",
            "no one passes statics by scrolling.",
            "your simulation won't run itself — back to work.",
        ]
        }
    }

    private func therapyCallouts(tier: Int) -> [String] {
        switch tier {
        case 1: return [
            "those therapy notes aren't going to write themselves.",
            "get back to your case notes.",
            "your clients deserve your focus. close this.",
            "your progress notes are waiting.",
        ]
        case 2: return [
            "stop. your notes are due before supervision.",
            "this isn't your treatment plan.",
            "case conceptualization doesn't write itself.",
        ]
        default: return [
            "CLOSE THIS. open your case notes.",
            "your clinical hours matter. get back.",
            "your clients are counting on your focus — back to work.",
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
