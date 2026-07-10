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
        // startup — must fire before presentation to catch "pitch deck" before word("deck") does.
        if lower.contains("pitch deck") || lower.contains("investor deck")
            || lower.contains("go-to-market") || lower.contains("gtm strategy")
            || lower.contains("business plan") || lower.contains("business model")
            || lower.contains("lean canvas")
            || lower.contains("value proposition")
            || lower.contains("seed round") || lower.contains("series a") || lower.contains("series b")
            || lower.contains("angel investor")
            || lower.contains("unit economics") || lower.contains("customer discovery")
            || lower.contains("product-market fit") || lower.contains("product market fit")
            || lower.contains("growth strategy") || lower.contains("growth hacking")
            || lower.contains("minimum viable product")
            || word("fundraising") || word("fundraise")
            || word("startup") || word("startups")
            || word("cofounder") || lower.contains("co-founder")
            || word("saas") || word("b2b") || word("b2c") {
            return "startup"
        }
        if word("presentation") || word("presentations") || word("slides") || word("deck") || word("powerpoint") || word("keynote") {
            return "presentation"
        }
        // gamedev — positioned before code so Unity/Godot/engine terms don't fall through to code.
        // "game plan" is not matched because no specific tool name or game-dev phrase fires.
        if word("unity") || word("godot") || lower.contains("unreal engine")
            || lower.contains("game dev") || lower.contains("game development")
            || lower.contains("game design document") || word("gdd")
            || lower.contains("game jam")
            || lower.contains("game engine")
            || lower.contains("level design") || lower.contains("level editor")
            || lower.contains("game mechanic") || lower.contains("game mechanics")
            || word("pygame") || word("phaser") || word("libgdx") || word("gdevelop") {
            return "gamedev"
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
        // statistics — positioned before studying so professional stats tools/methods (R, SPSS,
        // STATA, regression analysis, ANOVA) route here. Bare word("statistics") and word("stats")
        // stay in studying so "study statistics for my exam" still routes to studying.
        if lower.contains("rstudio") || lower.contains("r studio") || word("spss") || word("stata")
            || lower.contains("hypothesis testing") || lower.contains("hypothesis test")
            || lower.contains("linear regression") || lower.contains("logistic regression")
            || lower.contains("multiple regression") || lower.contains("multivariate analysis")
            || lower.contains("regression analysis")
            || word("anova") || lower.contains("t-test") || lower.contains("chi-square")
            || lower.contains("confidence interval") || lower.contains("statistical analysis")
            || lower.contains("statistical modeling") || lower.contains("statistical model")
            || lower.contains("descriptive statistics") || lower.contains("inferential statistics")
            || lower.contains("p-value") || lower.contains("p value")
            || lower.contains("effect size") || lower.contains("sample size calculation") {
            return "statistics"
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
        // engineering — positioned before datascience and research so tool/hardware-specific terms
        // (solidworks, arduino, pcb) don't fall through to generic research via word("lab").
        if word("solidworks") || lower.contains("fusion 360") || word("ansys")
            || word("microcontroller") || word("arduino") || lower.contains("raspberry pi")
            || word("pcb") || lower.contains("circuit board") || lower.contains("circuit diagram")
            || lower.contains("circuit design")
            || lower.contains("mechanical engineering") || lower.contains("electrical engineering")
            || lower.contains("civil engineering") || lower.contains("chemical engineering")
            || lower.contains("biomedical engineering") || lower.contains("aerospace engineering")
            || lower.contains("computer engineering")
            || lower.contains("finite element") || word("fea")
            || lower.contains("heat transfer") || lower.contains("fluid dynamics")
            || lower.contains("fluid mechanics") || lower.contains("thermodynamics")
            || lower.contains("structural analysis") || lower.contains("strength of materials")
            || lower.contains("machine design") || lower.contains("statics lab")
            || lower.contains("engineering lab") || lower.contains("engineering report") {
            return "engineering"
        }
        // datascience — positioned before research so "data science" and ML terms route here
        // instead of the generic research branch. "data science"/"data scientist" removed from research.
        if lower.contains("machine learning") || lower.contains("deep learning")
            || lower.contains("neural network") || lower.contains("neural networks")
            || word("pytorch") || word("tensorflow") || word("keras")
            || lower.contains("scikit-learn") || word("sklearn") || word("xgboost")
            || word("jupyter") || lower.contains("jupyter notebook")
            || word("kaggle")
            || lower.contains("data science") || lower.contains("data scientist")
            || lower.contains("natural language processing")
            || lower.contains("computer vision")
            || lower.contains("reinforcement learning")
            || lower.contains("model training") || lower.contains("model accuracy")
            || lower.contains("hyperparameter") || lower.contains("training loss")
            || lower.contains("gradient descent") || lower.contains("gradient boosting")
            || lower.contains("random forest") || lower.contains("decision tree") {
            return "datascience"
        }
        // ux — positioned before research so "user research" routes here rather than to the
        // generic research pool. "information architecture" is also caught here (not building arch).
        if lower.contains("user research") || lower.contains("usability testing")
            || lower.contains("usability test")
            || lower.contains("user flow") || lower.contains("user flows")
            || lower.contains("user journey") || lower.contains("user journeys")
            || lower.contains("journey map") || lower.contains("journey mapping")
            || lower.contains("affinity map") || lower.contains("affinity mapping")
            || lower.contains("affinity diagram") || lower.contains("affinity diagrams")
            || lower.contains("user persona") || lower.contains("user personas")
            || lower.contains("design thinking")
            || word("hci") || lower.contains("human-computer interaction")
            || lower.contains("user testing")
            || lower.contains("ux research") || lower.contains("ux writing")
            || lower.contains("ux design") || word("ux")
            || lower.contains("information architecture")
            || lower.contains("interaction design")
            || lower.contains("accessibility audit")
            || word("wireframing") || lower.contains("user story") || lower.contains("user stories") {
            return "ux"
        }
        // business/management — positioned before research so "marketing research" and "market analysis"
        // route here rather than the generic research pool. Startup branch above already catches
        // "business plan", "pitch deck", and "business model" before this point.
        if word("mba") || word("gmat")
            || lower.contains("case analysis") || lower.contains("business case")
            || lower.contains("operations management")
            || lower.contains("supply chain")
            || lower.contains("organizational behavior") || lower.contains("organisational behaviour")
            || lower.contains("strategic management") || lower.contains("business strategy")
            || lower.contains("marketing research") || lower.contains("market research")
            || lower.contains("market analysis") || lower.contains("market segmentation")
            || lower.contains("human resources") || lower.contains("hr management")
            || lower.contains("management consulting") || lower.contains("consulting case")
            || lower.contains("competitive analysis") || lower.contains("competitor analysis")
            || lower.contains("consumer behavior") || lower.contains("consumer behaviour")
            || lower.contains("brand management") || lower.contains("brand strategy")
            || lower.contains("corporate strategy")
            || lower.contains("business administration")
            || lower.contains("swot analysis") || word("swot")
            || lower.contains("value chain")
            || lower.contains("business school")
            || lower.contains("management class") || lower.contains("management course") {
            return "business"
        }
        if word("research") || word("lab")
            || lower.contains("case study") || lower.contains("case studies")
            || lower.contains("data analysis") || lower.contains("data collection")
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
        // Photography must fire before video — "photo editing", "editing photos", "raw editing"
        // all contain word("editing") which video catches via `word("editing")`.
        if word("lightroom") || word("photography") || word("photographer")
            || word("photoshoot") || lower.contains("photo shoot")
            || lower.contains("photo editing") || lower.contains("edit photos")
            || lower.contains("edit my photos") || lower.contains("editing photos")
            || lower.contains("capture one")
            || lower.contains("portrait photography") || lower.contains("landscape photography")
            || lower.contains("street photography") || lower.contains("product photography")
            || word("darkroom") || word("headshots") || word("headshot")
            || lower.contains("photo series") || lower.contains("photo project")
            || lower.contains("raw files") || lower.contains("raw editing") {
            return "photography"
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
        // finance — positioned before budget so professional exam/analysis terms (CPA, financial modeling,
        // balance sheet) route here instead of the generic budget/financial branch.
        if lower.contains("financial statements") || lower.contains("financial statement")
            || lower.contains("balance sheet") || lower.contains("balance sheets")
            || lower.contains("income statement") || lower.contains("income statements")
            || lower.contains("cpa exam") || lower.contains("cpa prep") || word("cpa")
            || word("cfa") || word("gaap") || word("ifrs")
            || lower.contains("financial modeling") || lower.contains("financial model")
            || lower.contains("financial analysis")
            || lower.contains("cost accounting") || lower.contains("managerial accounting")
            || lower.contains("financial accounting") || lower.contains("tax accounting")
            || word("audit") || word("auditing")
            || lower.contains("corporate finance") || lower.contains("investment analysis")
            || lower.contains("cash flow statement") || lower.contains("cash flow analysis")
            || word("accrual")
            || lower.contains("accounts payable") || lower.contains("accounts receivable")
            || lower.contains("trial balance")
            || lower.contains("equity analysis")
            || lower.contains("financial ratios") || lower.contains("financial ratio") {
            return "finance"
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
        // kinesiology — positioned before fitness so biomechanics, exercise physiology,
        // and physical therapy professional terms route here rather than the generic fitness pool.
        if word("kinesiology") || word("biomechanics") || word("kinesiologist")
            || lower.contains("exercise physiology") || lower.contains("sports science")
            || lower.contains("sport science") || lower.contains("cscs exam")
            || lower.contains("nsca exam") || lower.contains("motor control")
            || lower.contains("gait analysis") || lower.contains("movement analysis")
            || lower.contains("physical therapy") || lower.contains("physiotherapy")
            || lower.contains("athletic training") || lower.contains("strength and conditioning")
            || lower.contains("sport psychology") || lower.contains("sports psychology")
            || lower.contains("human movement") || lower.contains("musculoskeletal") {
            return "kinesiology"
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
        // nutrition/dietetics — positioned after fitness so "nutrition plan" and "meal prep"
        // stay in fitness; catches professional/clinical dietetics terms not covered there.
        if word("dietitian") || word("dietician") || word("nutritionist")
            || word("macronutrients")
            || lower.contains("food science")
            || lower.contains("food journal")
            || lower.contains("dietary analysis") || lower.contains("dietary intake")
            || lower.contains("nutritional science") || lower.contains("clinical nutrition")
            || lower.contains("nutrition assessment") || lower.contains("nutrient analysis")
            || lower.contains("calorie tracking") || lower.contains("calorie counting") {
            return "nutrition"
        }
        // culinary — positioned after nutrition (nutrition owns "food science", "meal prep", "nutrition plan");
        // catches culinary school, recipe work, pastry, baking, plating, and chef technique.
        if word("culinary") || lower.contains("culinary school") || lower.contains("culinary program")
            || lower.contains("culinary arts") || lower.contains("culinary class")
            || lower.contains("culinary technique") || lower.contains("culinary final")
            || lower.contains("recipe development") || lower.contains("recipe testing")
            || lower.contains("recipe creation") || lower.contains("recipe writing")
            || word("baking") || word("pastry") || lower.contains("pastry arts")
            || lower.contains("pastry school") || lower.contains("pastry class")
            || lower.contains("mise en place") || lower.contains("knife skills")
            || lower.contains("plating technique") || lower.contains("flavor profile")
            || lower.contains("sauce development") || lower.contains("menu development")
            || lower.contains("menu planning") || lower.contains("cooking class")
            || lower.contains("cooking technique") || word("gastronomy") {
            return "culinary"
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
        // musicproduction — positioned before musictheory so DAW/production tasks fire first.
        if lower.contains("music production") || lower.contains("beat making") || lower.contains("beatmaking")
            || word("beatmaker") || word("mixing") || word("mastering") || word("daw")
            || lower.contains("record a song") || lower.contains("record music")
            || lower.contains("write a song") || lower.contains("write songs")
            || lower.contains("write music") || lower.contains("produce a track")
            || lower.contains("produce music") || lower.contains("ableton")
            || lower.contains("logic pro") || lower.contains("fl studio")
            || lower.contains("pro tools") || lower.contains("garageband")
            || word("producing") || word("songwriter") || word("songwriting")
            || word("compose") || word("composing") || word("composition") || word("compositions")
            || word("lyric") || word("lyrics") || word("melody") || word("melodies") {
            return "musicproduction"
        }
        // musictheory — catches theory study, ear training, sight reading.
        if lower.contains("music theory") || lower.contains("ear training")
            || lower.contains("sight reading") || lower.contains("sight-reading")
            || lower.contains("music notation")
            || (lower.contains("scale") && lower.contains("music"))
            || word("counterpoint") || word("solfege") || word("solfège")
            || lower.contains("chord progression") || word("chord") || word("chords")
            || (lower.contains("harmony") && lower.contains("music"))
            || (lower.contains("harmonic") && lower.contains("music"))
            || lower.contains("music history") || lower.contains("aural skills")
            || lower.contains("theory class") || lower.contains("theory exam")
            || lower.contains("music class") || lower.contains("music course") {
            return "musictheory"
        }
        // enviro — environmental science, ecology, sustainability; positioned after fitness/nutrition.
        if lower.contains("environmental science") || lower.contains("environmental studies")
            || lower.contains("environmental policy") || lower.contains("environmental impact")
            || lower.contains("environmental chemistry") || lower.contains("environmental biology")
            || word("ecology") || word("ecologist") || lower.contains("field ecology")
            || word("ecosystem") || word("ecosystems") || lower.contains("conservation biology")
            || lower.contains("climate change") || lower.contains("climate science")
            || lower.contains("climate policy") || lower.contains("climate model")
            || word("sustainability") || word("sustainable")
            || lower.contains("carbon footprint") || lower.contains("greenhouse gas")
            || lower.contains("biodiversity") || lower.contains("species diversity")
            || lower.contains("habitat loss") || lower.contains("deforestation")
            || lower.contains("field report") && (lower.contains("ecology") || lower.contains("environment"))
            || lower.contains("env sci") || lower.contains("envi sci") {
            return "enviro"
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
        // veterinary — positioned before premed so "veterinary clinical rotation", "dissection"
        // in a vet-school context, and animal anatomy tasks route here, not to premed.
        if word("veterinary") || word("veterinarian") || lower.contains("vet school")
            || lower.contains("vet medicine") || lower.contains("veterinary medicine")
            || lower.contains("animal science") || word("navle")
            || lower.contains("animal behavior") || word("zoology")
            || lower.contains("comparative anatomy") || lower.contains("large animal")
            || lower.contains("small animal") || lower.contains("veterinary pathology")
            || lower.contains("animal physiology") || lower.contains("veterinary surgery")
            || lower.contains("vet tech") || lower.contains("veterinary technician")
            || lower.contains("veterinary clinic") || lower.contains("animal hospital") {
            return "veterinary"
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
        if word("nursing") || lower.contains("care plan") || lower.contains("care plans")
            || lower.contains("nursing notes") || lower.contains("nursing assessment")
            || lower.contains("nursing theory") || lower.contains("nursing diagnosis")
            || lower.contains("nursing diagnoses") || lower.contains("clinical documentation")
            || lower.contains("nurse charting") || lower.contains("shift notes") || lower.contains("shift report")
            || lower.contains("dosage calculation") || lower.contains("dosage calculations")
            || lower.contains("med calc") || lower.contains("medication calculation")
            || lower.contains("medication calculations")
            || lower.contains("nursing school") || lower.contains("nursing program")
            || lower.contains("nursing class") || lower.contains("nursing course")
            || lower.contains("vital signs") || word("vitals")
            || lower.contains("patient assessment") || lower.contains("patient care plan")
            || lower.contains("wound care") || lower.contains("iv insertion") {
            return "nursing"
        }
        // therapy — positioned after nursing (shared healthcare context) and before tutor
        // so "counseling" doesn't route to tutor via word("coaching").
        if lower.contains("therapy notes") || lower.contains("session notes")
            || lower.contains("progress notes") || lower.contains("treatment plan")
            || lower.contains("case conceptualization") || lower.contains("case formulation")
            || lower.contains("intake notes") || lower.contains("clinical notes")
            || word("therapist") || word("counseling") || word("counselor")
            || word("lcsw") || word("lmft") || word("lpc") || word("mft")
            || lower.contains("cbt worksheets") || lower.contains("dbt skills")
            || lower.contains("exposure therapy") || lower.contains("cognitive behavioral")
            || lower.contains("social work") || lower.contains("clinical hours")
            || lower.contains("supervision notes") || lower.contains("client notes")
            || lower.contains("case notes") || lower.contains("mental health notes") {
            return "therapy"
        }
        // socialscience — positioned after therapy (therapy catches "social work" first)
        // and before legal (LSAT is pre-law, not a bar-exam term).
        // Note: word("sociology") is already in the studying branch — not repeated here.
        if lower.contains("political science") || lower.contains("poli sci")
            || word("anthropology") || word("anthropological")
            || lower.contains("ethnography") || lower.contains("ethnographic")
            || word("criminology") || lower.contains("criminal justice")
            || word("lsat")
            || lower.contains("pre-law") || word("prelaw")
            || lower.contains("public policy") || lower.contains("public administration")
            || lower.contains("comparative politics") || lower.contains("international relations") {
            return "socialscience"
        }
        // philosophy — positioned after socialscience (shared "political philosophy" territory)
        // and before legal so "ethics paper" and "philosophical argument" don't fall to legal.
        if word("philosophy") || word("philosophical") || word("philosopher")
            || word("kant") || word("plato") || word("socrates") || word("aristotle")
            || word("nietzsche") || word("descartes") || word("hume") || word("locke")
            || word("hegel") || word("hegelian")
            || word("metaphysics") || word("epistemology") || word("ontology")
            || lower.contains("moral philosophy") || lower.contains("political philosophy")
            || lower.contains("philosophy of mind") || lower.contains("philosophy of science")
            || lower.contains("ethics paper") || lower.contains("ethics essay")
            || lower.contains("thought experiment") || lower.contains("thought experiments")
            || lower.contains("argument analysis") || lower.contains("philosophical argument")
            || lower.contains("logic problem") || lower.contains("logic problems")
            || word("dialectic") || word("dialectics") || lower.contains("dialectical method")
            || lower.contains("philosophical inquiry") || lower.contains("philosophy class")
            || lower.contains("philosophy course") || lower.contains("philosophy paper")
            || word("utilitarianism") || word("deontology") || word("consequentialism") {
            return "philosophy"
        }
        // policy — positioned after socialscience (which owns "public policy"/"public administration")
        // and before legal (which catches bare `word("brief")`). This intercepts "policy brief" and
        // "legislative brief" before legal's `word("brief")` fires.
        if lower.contains("policy memo") || lower.contains("policy memos")
            || lower.contains("policy brief") || lower.contains("policy briefs")
            || lower.contains("regulatory analysis")
            || lower.contains("legislative brief") || lower.contains("legislative briefs")
            || lower.contains("legislative memo") || lower.contains("legislative memos")
            || lower.contains("policy analysis")
            || lower.contains("policy recommendation") || lower.contains("policy recommendations")
            || lower.contains("regulatory framework")
            || lower.contains("policy implementation")
            || lower.contains("health policy") || lower.contains("public health policy")
            || lower.contains("fiscal policy") || lower.contains("monetary policy") {
            return "policy"
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
        // Guard common software-domain and UX false positives before checking architecture keywords.
        // "information architecture" routes to the ux branch above; also guarded here so that
        // if the ux branch is ever reordered the building-architecture messages don't fire.
        let isSoftwareArchitecture = lower.contains("software architecture")
            || lower.contains("system architecture") || lower.contains("application architecture")
            || lower.contains("cloud architecture") || lower.contains("data architecture")
            || lower.contains("information architecture")
        if !isSoftwareArchitecture
            && (word("architect") || word("architecture") || word("architectural")
                || word("autocad") || word("revit") || word("rhino") || word("grasshopper") || word("archicad")
                || word("sketchup") || word("blueprint") || word("blueprints")
                || lower.contains("floor plan") || lower.contains("floor plans")
                || lower.contains("site plan") || lower.contains("site plans")
                || word("elevation") || word("elevations")
                || word("rendering") || word("renderings")
                || lower.contains("3d model") || lower.contains("3d models")
                || lower.contains("construction document") || lower.contains("construction documents")
                || lower.contains("design studio") || lower.contains("studio crit") || lower.contains("pin-up")
                || lower.contains("architectural drawing") || lower.contains("architectural drawings")
                || lower.contains("are exam") || lower.contains("architecture exam")) {
            return "architecture"
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
