import Foundation
#if canImport(AppKit)
import AppKit
#endif

/// Watches consecutive off-task frames and fires friend-like callouts after a threshold.
/// Messages escalate in intensity across three tiers as the session callout count grows.
@MainActor
public final class CalloutManager {
    public static let shared = CalloutManager()

    private var consecutiveOffTask = 0
    private var hasFiredForStreak = false
    private var hasEscalatedForStreak = false
    private let threshold = 2  // frames before the notch callout fires (~4-6s at 0.5fps)
    // If the callout is ignored and the streak continues, escalate to a full-screen
    // takeover. Two more off-task frames past the callout (~another 4-6s).
    private let escalateThreshold = 4

    /// Total callouts fired in the current session. Only zeroed by reset() (session start/end),
    /// not by on-task recovery — used for tier escalation across the session.
    public private(set) var calloutCount: Int = 0

    /// Keyword extracted from the current session task (e.g. "essay", "code", "presentation").
    /// When set, task-specific messages are blended into the tier-1–3 callout pools.
    private var taskKeyword: String? = nil

    /// Exposed for unit tests — production code mutates this via setTask().
    internal var currentTaskKeyword: String? { taskKeyword }

    // Stored reference so a new streak or reset() cancels a pending auto-dismiss.
    // Without this, two consecutive streaks produce two tasks; the first task's
    // dismiss timer fires mid-second-streak and clears the wrong callout.
    private var autoDismissTask: Task<Void, Never>?
    // Tracks the last fired callout so consecutive streaks never repeat the same message.
    private var lastFiredMessage: String?
    // The AI's classification reason for the current off-task detection, shown as a subtitle.
    private var currentReason: String?

    private init() {}

    // MARK: - Public interface

    /// Call this with each new on-task classification.
    /// `reason` is the AI's explanation of what it sees on screen (e.g. "Reddit is open").
    public func evaluate(_ status: OnTaskStatus, reason: String = "") {
        switch status {
        case .offTask:
            if !reason.isEmpty { currentReason = reason }
            consecutiveOffTask += 1
            if consecutiveOffTask >= threshold && !hasFiredForStreak {
                hasFiredForStreak = true
                fire()
            }
            if consecutiveOffTask >= escalateThreshold && !hasEscalatedForStreak {
                hasEscalatedForStreak = true
                escalate()
            }
        case .onTask:
            resetStreak()
        case .ambiguous:
            break
        }
    }

    /// Fires an immediate callout for a blocked app becoming frontmost (no threshold needed).
    public func fireAppCallout(_ message: String) {
        display(message, tier: currentTier())
    }

    // MARK: - Task context

    /// Extracts a focus keyword from the session task and stores it for message blending.
    /// Call from SessionManager.activate() after reset() so tier escalation is already restored.
    public func setTask(_ task: String) {
        taskKeyword = Self.extractTaskKeyword(from: task)
    }

    /// Derives a one-word subject from a free-text task description.
    /// Returns nil when no recognizable subject keyword is found — generic pool is used instead.
    public nonisolated static func extractTaskKeyword(from task: String) -> String? {
        let lower = task.lowercased()
        // Match whole words only — prevents false positives like "threading" → "reading",
        // "industry" → "study", "facebook" → "book", "contest" → "test".
        func word(_ w: String) -> Bool {
            lower.range(of: "\\b\(w)\\b", options: .regularExpression) != nil
        }
        if word("essay") || word("essays") { return "essay" }
        if word("paper") || word("papers") { return "paper" }
        if word("thesis") || word("theses") || word("dissertation") || word("dissertations") { return "thesis" }
        if word("presentation") || word("presentations") || word("slides") || word("deck") || word("powerpoint") || word("keynote") {
            return "presentation"
        }
        if word("code") || word("coding") || word("programming") || word("bug") || word("feature") || word("function")
            || word("leetcode") || word("hackerrank") || word("codeforces") || word("codewars")
            || word("algorithm") || word("algorithms") || lower.contains("data structure")
            // Programming languages — matched before "studying" so "python homework" → code
            || word("python") || word("javascript") || word("typescript") || word("java")
            || word("kotlin") || word("rust") || word("swift") || word("cpp")
            || word("react") || word("vue") || word("angular") || word("html") || word("css")
            || word("sql") || word("bash") || word("shell")
            // Dev-workflow terms
            || word("debug") || word("debugging") || word("refactor") || word("refactoring")
            || lower.contains("pull request") || lower.contains("unit test") {
            return "code"
        }
        if word("report") || word("reports") || word("document") || word("documents") || word("doc") || word("docs") {
            return "report"
        }
        if word("study") || word("studying") || word("exam") || word("quiz") || word("test")
            || word("midterm") || word("midterms") || word("finals") || word("notes")
            || word("flashcard") || word("flashcards") || word("lecture")
            // Academic subject names — "study calculus", "chemistry test", etc.
            || word("calculus") || word("statistics") || word("stats") || word("algebra")
            || word("geometry") || word("probability") || word("physics") || word("chemistry")
            || word("biology") || word("economics") || word("econ") || word("psychology")
            || word("psych") || word("sociology") {
            return "studying"
        }
        if word("reading") || word("book") || word("chapter") || word("article")
            || word("annotate") || word("annotating") || word("annotation") || word("annotations") || word("annotated")
            || word("audiobook") || word("audiobooks") {
            return "reading"
        }
        if word("homework") || word("assignment") || lower.contains("problem set") || word("pset")
            || word("worksheet") || word("worksheets") {
            return "homework"
        }
        if word("research") || word("lab")
            || lower.contains("case study") || lower.contains("case studies")
            || lower.contains("data analysis") || lower.contains("data collection")
            || lower.contains("data science") || lower.contains("data scientist")
            || word("dataset") || word("datasets") || lower.contains("qualitative") || lower.contains("quantitative") {
            return "research"
        }
        if word("drawing") || word("painting") || word("sketching")
            || word("illustration") || word("illustrations") || word("illustrate") || word("illustrating")
            || word("procreate") || word("sculpting")
            || lower.contains("digital art") || lower.contains("digital painting")
            || lower.contains("concept art") || lower.contains("adobe illustrator") {
            return "art"
        }
        if word("design") || word("designing") || word("mockup") || word("wireframe")
            || word("prototype") || word("figma") || word("sketch")
            || lower.contains("design brief") {
            return "design"
        }
        if word("email") || word("emails") || word("inbox") {
            return "email"
        }
        if word("project") || word("projects") || word("capstone") {
            return "project"
        }
        if word("proposal") || word("proposals") {
            return "proposal"
        }
        if word("interview") || word("interviews") {
            return "interview"
        }
        if word("meeting") || word("meetings") || word("agenda") || word("agendas")
            || lower.contains("meeting notes") || lower.contains("meeting prep") {
            return "meeting"
        }
        if word("video") || word("editing") || word("footage") || word("film") || word("filming") {
            return "video"
        }
        if word("cv") || lower.contains("résumé") || lower.contains("resumé") || word("resume") {
            return "resume"
        }
        if word("application") || word("applications") || lower.contains("cover letter")
            || word("applying") || word("apply")
            || lower.contains("job application")
            || lower.contains("internship application") || lower.contains("college application")
            || word("internship") || word("internships")
            || word("fellowship") || word("fellowships")
            || word("scholarship") || word("scholarships") {
            return "application"
        }
        if word("blog") || word("blogs") || word("newsletter") || word("newsletters")
            || word("draft") || word("drafts") || word("outline") || word("outlines")
            || word("revision") || word("revisions") || word("revise")
            || word("proofread") || word("proofreading")
            || word("grant") || word("grants")
            || word("abstract") || word("abstracts")
            || lower.contains("literature review") || lower.contains("lit review")
            || lower.contains("peer review") || lower.contains("peer-review") || word("peerreview")
            // Non-legal "brief" contexts — must fire before the legal branch to prevent false positives
            || lower.contains("creative brief") || lower.contains("marketing brief") {
            return "writing"
        }
        if word("budget") || word("budgeting") || word("budgets")
            || word("spreadsheet") || word("spreadsheets")
            || word("finances") || word("financial") || word("accounting") || word("bookkeeping")
            || word("taxes") || lower.contains("tax return") || word("invoice") || word("invoices") {
            return "budget"
        }
        if word("tutor") || word("tutoring") || word("tutors")
            || word("teach") || word("teaching")
            || word("coach") || word("coaching")
            || word("instructor") || word("instruction") || word("instructing") {
            return "tutor"
        }
        if word("practice") || word("practicing") || word("practise") || word("practising")
            || word("rehearse") || word("rehearsing") || word("rehearsal") {
            return "practice"
        }
        if word("workout") || word("workouts") || word("gym")
            || word("exercise") || word("exercises") || word("exercising")
            || word("lifting") || word("weightlifting") || word("bodybuilding")
            || word("running") || word("cardio") || word("jogging") || word("cycling")
            || word("yoga") || word("pilates") || word("stretching") || word("swimming")
            || lower.contains("strength training") || lower.contains("weight training")
            || lower.contains("cross training") || lower.contains("endurance training")
            || lower.contains("training session") || lower.contains("training plan")
            || lower.contains("meal prep") || lower.contains("nutrition plan")
            || word("calories") {
            return "fitness"
        }
        if word("podcast") || word("podcasting")
            || lower.contains("podcast episode") || lower.contains("record an episode")
            || lower.contains("edit an episode") || lower.contains("edit the episode")
            || lower.contains("show notes") {
            return "podcast"
        }
        if word("plan") || word("planning") || word("planner") {
            return "planning"
        }
        if word("compose") || word("composing") || word("composition") || word("compositions")
            || word("lyric") || word("lyrics") || word("songwriter") || word("songwriting")
            || word("melody") || word("melodies") || word("harmony") || word("harmonies")
            || word("chord") || word("chords") || lower.contains("write a song") || lower.contains("write songs")
            || lower.contains("write music") || lower.contains("music production")
            || lower.contains("beat making") || lower.contains("beatmaking")
            || word("beatmaker") || word("mixing") || word("mastering")
            || lower.contains("record a song") || lower.contains("record music")
            || lower.contains("music theory") {
            return "music"
        }
        if word("spanish") || word("french") || word("japanese") || word("mandarin")
            || word("german") || word("italian") || word("portuguese") || word("korean")
            || word("arabic") || word("hindi") || word("cantonese") || word("russian")
            || word("hebrew") || word("duolingo")
            || word("vocabulary") || word("conjugation")
            || word("translate") || word("translating") || word("translation")
            || lower.contains("foreign language") || lower.contains("language learning")
            || lower.contains("language exchange") || lower.contains("language class") {
            return "language"
        }
        if word("journal") || word("journaling") || word("journalled") || word("journalling")
            || lower.contains("journal entry") || lower.contains("journal entries")
            || lower.contains("morning pages") || lower.contains("daily log")
            || lower.contains("diary entry") || word("diary") {
            return "journaling"
        }
        if word("anatomy") || word("physiology") || word("biochemistry")
            || word("pharmacology") || word("pathology") || word("histology")
            || word("microbiology") || word("immunology") || word("embryology")
            || lower.contains("mcat") || lower.contains("nclex") || lower.contains("usmle")
            || lower.contains("med school") || lower.contains("medical school")
            || lower.contains("pre-med") || word("premed")
            || word("dissection") || word("cadaver")
            || lower.contains("clinical rotation") || lower.contains("clinical skills")
            || lower.contains("anatomy lab") || lower.contains("anatomy notes")
            || lower.contains("step 1") || lower.contains("step 2") || lower.contains("step 3") {
            return "premed"
        }
        if word("brief") || word("briefs") || word("pleading") || word("pleadings")
            || word("deposition") || word("depositions") || word("statute") || word("statutes")
            || word("contract") || word("contracts")
            || lower.contains("case brief") || lower.contains("legal brief") || lower.contains("legal memo")
            || lower.contains("legal memorandum") || lower.contains("law review")
            || lower.contains("legal research") || lower.contains("legal writing")
            || lower.contains("moot court") || lower.contains("bar exam") || lower.contains("bar prep")
            || word("litigation") || word("motions") {
            return "legal"
        }
        if word("deadline") || word("deadlines") || lower.contains("due by") || lower.contains("due tonight")
            || lower.contains("due tomorrow") || lower.contains("due at midnight")
            || lower.contains("due at noon") || lower.contains("due at end of")
            || lower.contains("due in") || lower.contains("due before")
            || lower.range(of: #"\bdue at \d"#, options: .regularExpression) != nil {
            return "deadline"
        }
        return nil
    }

    // MARK: - Escalation logic

    /// Returns 1, 2, or 3 based on callouts already fired this session.
    /// Called before calloutCount is incremented, so 0 = first callout.
    internal func currentTier() -> Int {
        if calloutCount < 2 { return 1 }
        if calloutCount < 4 { return 2 }
        return 3
    }

    /// Auto-dismiss delay: longer at higher tiers so the user can't easily ignore it.
    nonisolated internal static func dismissDelay(for tier: Int) -> Duration {
        switch tier {
        case 1: return .seconds(8)
        case 2: return .seconds(12)
        default: return .seconds(20)
        }
    }

    /// Escalates an ignored callout into the full-screen takeover.
    private func escalate() {
        let message = lastFiredMessage ?? "back to work."
        NotchState.shared.showBlocker(message)
        #if canImport(AppKit)
        NSSound(named: "Sosumi")?.play()
        #endif
    }

    /// Called by the takeover UI when the user dismisses it. We intentionally do NOT
    /// clear `hasEscalatedForStreak`, so dismissing doesn't immediately re-throw the
    /// takeover while they're still on the same off-task streak — it re-arms only
    /// after they go back on task (which calls reset()).
    public func dismissBlocker() {
        NotchState.shared.clearBlocker()
    }

    /// Resets the current off-task streak without touching the session-level calloutCount.
    /// Called on on-task recovery so a new streak can fire again, but tier escalation
    /// persists because calloutCount is preserved.
    private func resetStreak() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
        consecutiveOffTask = 0
        hasFiredForStreak = false
        hasEscalatedForStreak = false
        currentReason = nil
        NotchState.shared.clearCallout()
        NotchState.shared.clearBlocker()
        // lastFiredMessage intentionally preserved: dedup works across streaks within a session.
    }

    /// Restores the session-level callout count after a crash/relaunch.
    /// Must be called after reset() so the tier escalation continues from where it left off
    /// instead of restarting at tier 1. For new sessions calloutCount is 0 so this is a no-op.
    public func restore(count: Int) {
        calloutCount = count
    }

    /// Full session reset — zeroes calloutCount and clears all state including task context.
    /// Called by SessionManager.activate() at session start and by tests between sessions.
    public func reset() {
        autoDismissTask?.cancel()
        autoDismissTask = nil
        consecutiveOffTask = 0
        hasFiredForStreak = false
        hasEscalatedForStreak = false
        lastFiredMessage = nil
        currentReason = nil
        calloutCount = 0
        taskKeyword = nil
        NotchState.shared.clearCallout()
        NotchState.shared.clearBlocker()
    }

    // MARK: - Private

    private func fire() {
        let tier = currentTier()
        var pool: [String]
        switch tier {
        case 1: pool = Self.tier1Callouts
        case 2: pool = Self.tier2Callouts
        default: pool = Self.tier3Callouts
        }
        // Blend in task-specific messages when session context is available.
        // They're added to — not replacing — the generic pool so generic messages
        // still fire proportionally. Task-aware messages appear ~(k / n+k) of the time.
        if let keyword = taskKeyword {
            pool += taskAwareCallouts(keyword: keyword, tier: tier)
        }
        let candidates = pool.filter { $0 != lastFiredMessage }
        let message = (candidates.isEmpty ? pool : candidates).randomElement() ?? "focus."
        display(message, tier: tier)
    }

    private func display(_ message: String, tier: Int = 1) {
        calloutCount += 1
        lastFiredMessage = message
        NotchState.shared.showCallout(message, tier: tier, reason: currentReason)
        // Cancel any pending auto-dismiss from a prior callout before starting a new one.
        autoDismissTask?.cancel()
        autoDismissTask = Task { @MainActor in
            do {
                try await Task.sleep(for: Self.dismissDelay(for: tier))
                NotchState.shared.clearCallout()
            } catch {
                // Task was cancelled — resetStreak()/reset() was called or a new callout fired.
            }
        }
        #if canImport(AppKit)
        switch tier {
        case 2: NSSound(named: "Basso")?.play()   // deeper thud — unmistakably escalated
        case 3: NSSound(named: "Funk")?.play()    // most alarming — can't be ignored
        default: NSSound(named: "Sosumi")?.play()
        }
        #endif
    }
}
