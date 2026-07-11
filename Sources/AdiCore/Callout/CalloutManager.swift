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
        // cybersecurity — positioned before code so pen-test/hacking tools (Metasploit, Kali,
        // Wireshark) and cert prep terms (Security+, CEH, OSCP) don't fall through to generic code.
        // "security" alone is NOT matched to avoid false positives like "social security paper".
        if lower.contains("penetration testing") || lower.contains("pen test") || lower.contains("pen-test")
            || lower.contains("penetration test")
            || lower.contains("ethical hacking") || lower.contains("ethical hacker")
            || lower.contains("bug bounty") || lower.contains("bug bounties")
            || lower.contains("capture the flag") || word("ctf")
            || lower.contains("vulnerability assessment") || lower.contains("vulnerability scan")
            || lower.contains("network security") || lower.contains("cybersecurity")
            || lower.contains("cyber security") || lower.contains("information security")
            || lower.contains("infosec")
            || lower.contains("security+") || lower.contains("comptia security")
            || word("ceh") || word("oscp") || lower.contains("certified ethical")
            || lower.contains("incident response") || lower.contains("malware analysis")
            || lower.contains("threat modeling") || lower.contains("threat model")
            || lower.contains("security audit") || lower.contains("security assessment")
            || word("wireshark") || word("metasploit") || lower.contains("kali linux")
            || lower.contains("soc analyst") || lower.contains("siem")
            || lower.contains("digital forensics") || lower.contains("forensic analysis")
            || lower.contains("reverse engineering") && (lower.contains("malware") || lower.contains("binary") || lower.contains("firmware"))
            || lower.contains("exploit development") || lower.contains("zero day")
            || lower.contains("nmap scan") || lower.contains("burp suite")
            || lower.contains("sql injection") || lower.contains("xss attack")
            || lower.contains("security certification") || lower.contains("security exam")
            || lower.contains("cybersecurity class") || lower.contains("cybersecurity course")
            || lower.contains("network forensics") || lower.contains("cryptography lab") {
            return "cybersecurity"
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
        // actuarial — positioned before statistics so exam prep (Exam P, FM, IFM, LTAM, STAM,
        // MAS-I/II) and credential pursuit (ASA, FSA, FCAS, ACAS via SOA/CAS) route here.
        if word("actuarial") || word("actuary") || word("actuaries")
            || lower.contains("soa exam") || lower.contains("cas exam")
            || lower.contains("exam p") || lower.contains("exam fm")
            || lower.contains("exam ifm") || lower.contains("exam ltam")
            || lower.contains("exam stam")
            || lower.contains("exam mas-i") || lower.contains("exam mas-ii")
            || lower.contains("actuarial science") || lower.contains("actuarial math")
            || lower.contains("actuarial models") || lower.contains("actuarial exam")
            || lower.contains("actuarial study") || lower.contains("actuarial prep")
            || lower.contains("fsa exam") || lower.contains("asa exam")
            || lower.contains("soa asa") || lower.contains("soa fsa")
            || lower.contains("fcas exam") || lower.contains("acas exam")
            || lower.contains("loss models") || lower.contains("loss reserving")
            || lower.contains("credibility theory") || lower.contains("mortality table")
            || lower.contains("life table") || lower.contains("actuarial reserve")
            || lower.contains("actuarial risk") || lower.contains("actuarial pricing") {
            return "actuarial"
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
        // astronomy — positioned before studying so "astrophysics homework" and "astronomy exam"
        // don't fall through to the generic studying pool via word("exam").
        // Bare word("physics") stays in studying; compound celestial/cosmological terms route here.
        if word("astronomy") || word("astronomer") || word("astronomers")
            || word("astrophysics") || word("astrophysicist") || word("astrophysicists")
            || lower.contains("celestial mechanics") || word("cosmology") || word("cosmologist")
            || lower.contains("observational astronomy") || lower.contains("stellar physics")
            || lower.contains("stellar evolution") || lower.contains("stellar structure")
            || lower.contains("planetary science") || lower.contains("planetary formation")
            || word("exoplanet") || word("exoplanets")
            || lower.contains("orbital mechanics") || lower.contains("orbital dynamics")
            || lower.contains("radio astronomy") || lower.contains("astronomical observation")
            || lower.contains("astronomical imaging") || lower.contains("astronomical data")
            || word("observatory") || word("planetarium")
            || word("astrobiology") || lower.contains("star formation")
            || lower.contains("galaxy formation") || lower.contains("galaxy evolution")
            || lower.contains("dark matter") || lower.contains("dark energy")
            || lower.contains("cosmological") || lower.contains("astr class")
            || lower.contains("astr course") || lower.contains("astr lab")
            || lower.contains("astr homework") || lower.contains("astronomy class")
            || lower.contains("astronomy course") || lower.contains("astronomy lab")
            || lower.contains("astronomy homework") || lower.contains("astronomy exam")
            || lower.contains("astrophysics class") || lower.contains("astrophysics course")
            || lower.contains("astrophysics homework") || lower.contains("astrophysics exam") {
            return "astronomy"
        }
        // mathematics — positioned before studying so number theory, proof writing, and
        // advanced topics (topology, abstract algebra) don't fall through to studying.
        // word("algebra") and word("calculus") are in studying for generic "algebra exam"
        // use; mathematics catches explicit pure-math terms and proof-writing tasks.
        if lower.contains("number theory") || lower.contains("abstract algebra")
            || lower.contains("real analysis") || lower.contains("complex analysis")
            || word("topology") || lower.contains("group theory") || lower.contains("ring theory")
            || lower.contains("vector calculus") || lower.contains("multivariable calculus")
            || lower.contains("differential equations") || lower.contains("partial differential")
            || lower.contains("discrete mathematics") || lower.contains("discrete math")
            || word("combinatorics") || lower.contains("mathematical proof")
            || lower.contains("proof writing") || lower.contains("write a proof")
            || lower.contains("writing a proof") || lower.contains("proof by induction")
            || lower.contains("proof by contradiction") || lower.contains("mathematical induction")
            || lower.contains("set theory") || lower.contains("mathematical logic")
            || lower.contains("functional analysis") || lower.contains("measure theory")
            || lower.contains("numerical analysis") || lower.contains("numerical methods")
            || lower.contains("linear algebra") || lower.contains("matrix algebra")
            || lower.contains("math competition") || lower.contains("math olympiad")
            || lower.contains("putnam exam") || lower.contains("amc exam") || lower.contains("aime exam")
            || lower.contains("mathematical modeling")
            || lower.contains("graph theory") || lower.contains("boolean algebra")
            || lower.contains("field theory") && !lower.contains("magnetic field")
            || lower.contains("galois theory") || lower.contains("category theory")
            || lower.contains("algebraic topology") || lower.contains("differential geometry") {
            return "mathematics"
        }
        // linguistics — positioned before studying so "linguistics exam", "phonetics class",
        // and language-science assignments don't fall through to studying.
        // Language learning (vocabulary, conjugation, Duolingo) stays in the language branch below.
        if word("linguistics") || word("linguist") || word("linguistic")
            || word("phonology") || word("phonetics") || word("phoneme") || word("phonemes")
            || lower.contains("sociolinguistics") || lower.contains("psycholinguistics")
            || lower.contains("computational linguistics") || lower.contains("corpus linguistics")
            || lower.contains("language acquisition") || lower.contains("second language acquisition")
            || lower.contains("applied linguistics") || lower.contains("historical linguistics")
            || lower.contains("discourse analysis") || lower.contains("language documentation")
            || lower.contains("language endangerment") || lower.contains("language typology")
            || lower.contains("linguistic analysis") || lower.contains("linguistic theory")
            || lower.contains("linguistics class") || lower.contains("linguistics course")
            || lower.contains("linguistics program") || lower.contains("linguistics major")
            || lower.contains("linguistics exam") || lower.contains("linguistic anthropology")
            || lower.contains("international phonetic alphabet") {
            return "linguistics"
        }
        // marinebiology — positioned before studying so "marine biology exam" and
        // "oceanography lab" don't fall through via word("exam") or word("lab").
        // Bare word("biology") stays in studying for generic "biology exam" tasks.
        if lower.contains("marine biology") || lower.contains("marine biologist")
            || lower.contains("marine biologists")
            || lower.contains("marine ecology") || lower.contains("marine ecologist")
            || lower.contains("marine science") || lower.contains("marine sciences")
            || lower.contains("marine life") || lower.contains("marine organisms")
            || lower.contains("marine mammal") || lower.contains("marine mammals")
            || word("oceanography") || word("oceanographer") || word("oceanographers")
            || lower.contains("ocean science") || lower.contains("ocean sciences")
            || lower.contains("coastal ecology") || lower.contains("aquatic ecology")
            || lower.contains("aquatic biology") || lower.contains("freshwater ecology")
            || lower.contains("coral reef") || lower.contains("coral reefs")
            || lower.contains("deep sea") || lower.contains("deep ocean")
            || lower.contains("marine conservation") || lower.contains("fisheries science")
            || word("ichthyology") || word("ichthyologist")
            || word("plankton") || word("phytoplankton") || word("zooplankton")
            || word("benthic") || word("pelagic") || word("littoral")
            || lower.contains("marine lab") || lower.contains("marine biology class")
            || lower.contains("marine biology course") || lower.contains("marine biology exam")
            || lower.contains("marine biology homework") || lower.contains("oceanography class")
            || lower.contains("oceanography course") || lower.contains("oceanography exam") {
            return "marinebiology"
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
        // geology — positioned before engineering so "geology lab", "gis mapping", and
        // earth-science field tasks don't fall through to engineering or research via word("lab").
        // "geography" alone does NOT fire here (stays in studying/socialscience).
        if word("geology") || word("geologist") || word("geological") || word("geologists")
            || word("mineralogy") || word("petrology") || word("sedimentology")
            || word("stratigraphy") || word("stratigraphic") || word("geomorphology")
            || word("hydrogeology") || word("seismology") || word("volcanology")
            || word("geophysics") || word("geochemistry")
            || lower.contains("earth science") || lower.contains("earth sciences")
            || word("geoscience") || word("geosciences")
            || lower.contains("plate tectonics") || lower.contains("tectonic plates")
            || lower.contains("rock cycle") || lower.contains("rock identification")
            || lower.contains("mineral identification") || lower.contains("mineral analysis")
            || lower.contains("geological survey") || lower.contains("geologic map")
            || lower.contains("geological map") || lower.contains("geologic cross section")
            || word("paleontology") || word("paleontologist") || lower.contains("fossil record")
            || word("asbog")
            || lower.contains("gis analysis") || lower.contains("gis mapping")
            || lower.contains("soil science") || lower.contains("soil mechanics")
            || lower.contains("hydrology") {
            return "geology"
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
        // bioinformatics — positioned after datascience (ML tools may co-occur) and before ux
        // so sequence analysis, genomics, and computational-biology pipelines route here.
        // Bare "biology" stays in studying; "biomedical engineering" stays in engineering above.
        if lower.contains("bioinformatics") || lower.contains("computational biology")
            || lower.contains("genomics") || lower.contains("proteomics")
            || lower.contains("transcriptomics") || lower.contains("metabolomics")
            || lower.contains("sequence analysis") || lower.contains("sequence alignment")
            || lower.contains("multiple sequence alignment")
            || lower.contains("blast search") || lower.contains("blast alignment")
            || lower.contains("rna-seq") || lower.contains("rnaseq") || lower.contains("rna seq")
            || lower.contains("metagenomics") || lower.contains("metagenomic")
            || lower.contains("genome assembly") || lower.contains("genome annotation")
            || lower.contains("variant calling") || lower.contains("variant annotation")
            || lower.contains("gene annotation") || lower.contains("genome analysis")
            || lower.contains("phylogenetics") || lower.contains("phylogenetic tree")
            || lower.contains("molecular docking") || lower.contains("structural bioinformatics")
            || word("ncbi") || lower.contains("ncbi blast")
            || lower.contains("bioinformatics pipeline") || lower.contains("bioinformatics tools") {
            return "bioinformatics"
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
        // urbanplanning — positioned before realestate (which catches bare word("zoning")) so
        // "urban planning", "zoning ordinance", and AICP exam prep route to the planning pool.
        // "urban design" placed here to not fall through to generic word("design") below.
        if lower.contains("urban planning") || lower.contains("urban planner")
            || lower.contains("urban planners") || lower.contains("city planning")
            || lower.contains("city planner") || lower.contains("town planning")
            || lower.contains("regional planning") || lower.contains("land use planning")
            || lower.contains("urban design")
            || lower.contains("zoning ordinance") || lower.contains("zoning code")
            || lower.contains("zoning regulations") || lower.contains("zoning law")
            || lower.contains("mixed-use development") || lower.contains("mixed use development")
            || lower.contains("transit-oriented") || lower.contains("transit oriented development")
            || lower.contains("transportation planning") || lower.contains("urban renewal")
            || word("aicp") || lower.contains("aicp exam")
            || lower.contains("comprehensive plan") || lower.contains("general plan")
            || lower.contains("urban sprawl") || lower.contains("urban policy")
            || lower.contains("municipal planning") || lower.contains("smart city")
            || lower.contains("smart cities") || lower.contains("sustainable urbanism")
            || lower.contains("urban infrastructure") || lower.contains("land use analysis") {
            return "urbanplanning"
        }
        // realestate — positioned before business so "real estate investment", property management,
        // and licensing/appraisal prep route here rather than the generic business pool.
        if lower.contains("real estate") || word("realtor") || word("realtors")
            || lower.contains("real estate agent") || lower.contains("real estate broker")
            || lower.contains("real estate license") || lower.contains("real estate exam")
            || lower.contains("real estate school") || lower.contains("real estate class")
            || lower.contains("real estate appraisal") || lower.contains("property appraisal")
            || lower.contains("property management") || lower.contains("property manager")
            || lower.contains("mls listing") || lower.contains("comparative market analysis")
            || lower.contains("cma report") || lower.contains("cma presentation")
            || lower.contains("property valuation")
            || lower.contains("home inspection") || lower.contains("title search")
            || lower.contains("title insurance") || lower.contains("closing documents")
            || lower.contains("closing costs") || lower.contains("listing agreement")
            || lower.contains("purchase agreement") || lower.contains("purchase contract")
            || word("escrow") || word("zoning")
            || lower.contains("fair housing") || lower.contains("real estate investing")
            || word("reit") || lower.contains("open house prep") {
            return "realestate"
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
        // journalism — positioned after research and business but before writing so "news article",
        // "press release", and journalism-school tasks route here. "newsletter"/"blog" stay in writing.
        if word("journalism") || word("journalist") || word("journalists")
            || word("reporter") || word("reporters") || word("reporting")
            || lower.contains("news article") || lower.contains("news story") || lower.contains("news stories")
            || lower.contains("news writing") || lower.contains("investigative journalism")
            || lower.contains("investigative reporting") || lower.contains("broadcast journalism")
            || lower.contains("media studies") || lower.contains("media analysis")
            || lower.contains("media literacy") || lower.contains("media law")
            || lower.contains("press release") || lower.contains("press releases")
            || lower.contains("editorial writing") || lower.contains("op-ed")
            || lower.contains("column writing")
            || word("photojournalism") || word("photojournalist")
            || lower.contains("journalism ethics") || lower.contains("journalism class")
            || lower.contains("journalism course") || lower.contains("journalism degree")
            || lower.contains("journalism program") || lower.contains("journalism school")
            || word("copyediting") || lower.contains("copy editing")
            || lower.contains("magazine article") {
            return "journalism"
        }
        // publicrelations — positioned after journalism and before graphicdesign.
        // "press release"/"press releases" stay in journalism above.
        if lower.contains("public relations") || lower.contains("pr strategy")
            || lower.contains("pr plan") || lower.contains("pr campaign")
            || lower.contains("pr pitch") || lower.contains("pr writing")
            || lower.contains("media relations") || lower.contains("press kit")
            || lower.contains("corporate communications") || lower.contains("internal communications")
            || lower.contains("crisis communications") || lower.contains("crisis communication")
            || lower.contains("brand communications") || lower.contains("communications strategy")
            || lower.contains("communications major") || lower.contains("communications degree")
            || lower.contains("communications class") || lower.contains("communications course")
            || lower.contains("communications program") || lower.contains("communications school")
            || lower.contains("communications exam") || lower.contains("media pitch")
            || lower.contains("pr firm") || lower.contains("pr agency")
            || lower.contains("spokesperson training") || lower.contains("public affairs") {
            return "publicrelations"
        }
        // graphicdesign — positioned BEFORE art (both use illustrator/photoshop terms) and before
        // the generic design branch (which catches bare word("design")).
        // "brand strategy" / "brand management" are owned by the startup branch above.
        if lower.contains("graphic design") || lower.contains("graphic designer")
            || lower.contains("graphic designing")
            || word("branding") || lower.contains("brand identity") || lower.contains("visual identity")
            || lower.contains("visual branding")
            || lower.contains("logo design") || lower.contains("designing a logo")
            || lower.contains("create a logo") || lower.contains("logo creation")
            || word("typography") || word("typeface") || word("typesetting")
            || lower.contains("color palette") || lower.contains("colour palette")
            || lower.contains("poster design") || lower.contains("flyer design")
            || word("infographic") || word("infographics")
            || lower.contains("packaging design") || lower.contains("product packaging")
            || lower.contains("editorial design") || lower.contains("magazine layout")
            || lower.contains("book layout") || lower.contains("book design")
            || word("indesign") || lower.contains("adobe indesign")
            || lower.contains("print design") || lower.contains("web graphics")
            || word("canva") {
            return "graphicdesign"
        }
        // arthistory — positioned BEFORE art so "art history essay", "art criticism", and
        // "museum studies" route here rather than the fine-art making branch.
        // "art theory" is common in art-history courses; "digital art" stays in art.
        if lower.contains("art history") || lower.contains("art historian")
            || lower.contains("art historians") || lower.contains("art historical")
            || lower.contains("art criticism") || lower.contains("art critic")
            || lower.contains("art critics") || lower.contains("museum studies")
            || lower.contains("art analysis") || lower.contains("visual culture")
            || lower.contains("art theory") || lower.contains("art appreciation")
            || lower.contains("aesthetic theory") || lower.contains("aesthetics class")
            || lower.contains("iconography") || lower.contains("iconology")
            || lower.contains("baroque art") || lower.contains("baroque period")
            || lower.contains("renaissance art") || lower.contains("impressionism")
            || lower.contains("expressionism in art") || lower.contains("art movement")
            || lower.contains("art movements") || lower.contains("curatorial")
            || lower.contains("museum curation") || lower.contains("art history class")
            || lower.contains("art history course") || lower.contains("art history exam")
            || lower.contains("art history essay") || lower.contains("art history paper")
            || lower.contains("art history major") || lower.contains("art history program") {
            return "arthistory"
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
        // filmstudies — positioned before video so "film history", "film criticism", and
        // "film essay" don't fall through to word("film") in the video branch.
        // Bare word("film") still routes to video for production tasks.
        if lower.contains("film studies") || lower.contains("film criticism")
            || lower.contains("film critic")
            || lower.contains("film analysis") || lower.contains("film theory")
            || lower.contains("film history") || lower.contains("film essay")
            || lower.contains("film class") || lower.contains("film course")
            || lower.contains("film program") || lower.contains("film school")
            || lower.contains("cinematic theory") || lower.contains("auteur theory")
            || lower.contains("mise-en-scène") || lower.contains("mise en scene")
            || lower.contains("mise-en-scene")
            || lower.contains("film genre") || lower.contains("genre analysis")
            || lower.contains("film noir") || lower.contains("documentary film studies")
            || lower.contains("film review essay") || lower.contains("film review writing")
            || lower.contains("movie analysis") || lower.contains("movie essay")
            || lower.contains("movie criticism") || lower.contains("film semiotics")
            || lower.contains("cinematography theory") || lower.contains("montage theory")
            || lower.contains("film studies class") || lower.contains("film studies course")
            || lower.contains("film studies exam") || lower.contains("film studies major") {
            return "filmstudies"
        }
        // performingarts — positioned before video so "filming" in a theater context and
        // word("film") don't override theater/acting/dance tasks.
        // word("sketch") stays in design; "sketch comedy" routes here via "improv".
        if word("theater") || word("theatre") || word("theatrical")
            || lower.contains("musical theater") || lower.contains("musical theatre")
            || lower.contains("stage production") || lower.contains("stage direction")
            || lower.contains("stage management") || lower.contains("stage manager")
            || word("improv") || lower.contains("improvisation")
            || word("monologue") || word("monologues") || word("audition") || word("auditions")
            || word("choreography") || word("choreographer") || word("choreographers")
            || lower.contains("dance choreography") || lower.contains("performing arts")
            || word("ballet") || lower.contains("contemporary dance") || lower.contains("tap dance")
            || lower.contains("modern dance") || lower.contains("dance class")
            || lower.contains("dance rehearsal") || lower.contains("dance studio")
            || lower.contains("dance performance") || lower.contains("dance technique")
            || lower.contains("dance exam") || lower.contains("dance notation")
            || lower.contains("drama class") || lower.contains("drama school")
            || lower.contains("drama program") || lower.contains("drama course")
            || lower.contains("theater class") || lower.contains("theatre class")
            || lower.contains("acting class") || lower.contains("acting coach")
            || lower.contains("acting program") || lower.contains("acting school")
            || lower.contains("acting technique") || word("dramaturgy") || word("dramaturg")
            || lower.contains("stanislavski") || lower.contains("meisner technique")
            || lower.contains("strasberg") || word("amda") {
            return "performingarts"
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
        // screenwriting — positioned before writing so "screenplay", "fiction", and "novel"
        // route here instead of generic writing. "script" alone is not matched to avoid false
        // positives like "shell script". "outline" alone stays in writing for general doc outlines.
        if word("screenplay") || word("screenwriter") || word("screenwriting")
            || lower.contains("script writing") || lower.contains("film script")
            || lower.contains("tv script") || lower.contains("spec script")
            || lower.contains("feature film") || lower.contains("short film script")
            || word("fiction") || lower.contains("fiction writing") || lower.contains("write fiction")
            || word("novel") || word("novels") || word("novella") || word("novellas")
            || lower.contains("short story") || lower.contains("short stories")
            || lower.contains("creative fiction") || lower.contains("creative nonfiction")
            || lower.contains("narrative writing") || lower.contains("narrative nonfiction")
            || lower.contains("story outline") || lower.contains("story structure")
            || lower.contains("plot outline") || lower.contains("story world")
            || word("worldbuilding") || lower.contains("world building")
            || (lower.contains("character") && (lower.contains("development") || lower.contains("arc") || lower.contains("sheet") || lower.contains("profile")))
            || lower.contains("scene writing") || lower.contains("write a scene")
            || lower.contains("write a chapter") || lower.contains("chapter draft") {
            return "screenwriting"
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
        // forensicaccounting — positioned before finance so fraud investigation, CFE exam,
        // and financial forensics tasks route here rather than the generic finance pool.
        if lower.contains("forensic accounting") || lower.contains("forensic accountant")
            || lower.contains("forensic accountants") || lower.contains("forensic audit")
            || lower.contains("forensic auditor") || lower.contains("forensic financial")
            || lower.contains("fraud investigation") || lower.contains("fraud investigator")
            || lower.contains("fraud audit") || lower.contains("fraud examination")
            || lower.contains("financial forensics")
            || lower.contains("cfe exam") || lower.contains("cfe certification")
            || lower.contains("certified fraud examiner") || word("acfe")
            || lower.contains("fraud detection") || lower.contains("fraud analysis")
            || lower.contains("financial crime") || lower.contains("anti-money laundering")
            || lower.contains("money laundering investigation")
            || lower.contains("embezzlement investigation") || lower.contains("embezzlement detection")
            || lower.contains("forensic cpa") || lower.contains("litigation support accounting") {
            return "forensicaccounting"
        }
        // finance — positioned before budget so professional exam/analysis terms (CPA, CFA, DCF, LBO,
        // financial modeling, balance sheet) route here instead of the generic budget/financial branch.
        if lower.contains("financial statements") || lower.contains("financial statement")
            || lower.contains("balance sheet") || lower.contains("balance sheets")
            || lower.contains("income statement") || lower.contains("income statements")
            || lower.contains("cpa exam") || lower.contains("cpa prep") || word("cpa")
            || word("cfa") || lower.contains("cfa level") || word("gaap") || word("ifrs")
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
            || lower.contains("equity analysis") || lower.contains("equity research")
            || lower.contains("financial ratios") || lower.contains("financial ratio")
            || lower.contains("discounted cash flow") || lower.contains("dcf model") || word("dcf")
            || lower.contains("leveraged buyout") || word("lbo")
            || lower.contains("bloomberg terminal")
            || lower.contains("comparable company") || lower.contains("comparable companies")
            || lower.contains("comp analysis") || lower.contains("comps analysis")
            || lower.contains("investment banking") || lower.contains("ib analyst")
            || lower.contains("valuation model") || lower.contains("company valuation")
            || lower.contains("series 7") || lower.contains("series 63")
            || word("finra") || word("acca") || word("cima")
            || lower.contains("financial due diligence")
            || lower.contains("mergers and acquisitions") || lower.contains("m&a analysis") {
            return "finance"
        }
        if word("budget") || word("budgeting") || word("budgets")
            || word("spreadsheet") || word("spreadsheets")
            || word("finances") || word("financial") || word("accounting") || word("bookkeeping")
            || word("taxes") || lower.contains("tax return") || word("invoice") || word("invoices") {
            return "budget"
        }
        // education — positioned before tutor so lesson planning, curriculum development, and
        // teaching certification tasks route here rather than the generic tutoring/coaching pool.
        if lower.contains("lesson plan") || word("curriculum")
            || word("pedagogy") || word("pedagogical") || word("pedagogist")
            || lower.contains("teaching certificate") || lower.contains("teaching credential")
            || lower.contains("teacher certification") || lower.contains("teacher credential")
            || lower.contains("classroom management")
            || lower.contains("instructional design") || lower.contains("instructional materials")
            || lower.contains("learning objectives") || lower.contains("learning outcomes")
            || lower.contains("student teaching")
            || lower.contains("assessment rubric") || lower.contains("grading rubric")
            || lower.contains("differentiated instruction")
            || lower.contains("educational psychology")
            || lower.contains("school of education") || lower.contains("college of education")
            || lower.contains("education class") || lower.contains("education course")
            || lower.contains("education program") || lower.contains("education degree")
            || word("edtpa") || lower.contains("ed tpa")
            || lower.contains("praxis core") || lower.contains("praxis ii") || lower.contains("praxis 2")
            || (lower.contains("praxis") && (lower.contains("teach") || lower.contains("education")))
            || lower.contains("teacher licensure") || lower.contains("teaching licensure")
            || lower.contains("individualized education plan")
            || lower.contains("individualized education program") {
            return "education"
        }
        // physed — positioned after education and before tutor so PE teaching and sport/athletic
        // coaching terms route here rather than the generic tutoring/coaching pool.
        // Bare word("coaching") alone stays in tutor; compound coaching terms fire here first.
        if lower.contains("physical education") || lower.contains("pe teacher")
            || lower.contains("pe teaching") || lower.contains("pe class")
            || lower.contains("pe curriculum") || lower.contains("pe program")
            || lower.contains("pe lesson") || lower.contains("physical education teacher")
            || lower.contains("physical education curriculum") || lower.contains("physical education class")
            || lower.contains("physical education program") || lower.contains("physical education certification")
            || lower.contains("adapted physical education") || lower.contains("adaptive pe")
            || lower.contains("sport coaching") || lower.contains("sports coaching")
            || lower.contains("athletic coaching") || lower.contains("athletic coach")
            || lower.contains("coaching theory") || lower.contains("coaching philosophy")
            || lower.contains("coaching certification") || lower.contains("coaching license")
            || lower.contains("coaching licensure") || lower.contains("youth coaching") {
            return "physed"
        }
        // libraryscience — positioned after physed and before tutor so LIS/MLIS programs,
        // cataloging, archival work, and reference services route here.
        if lower.contains("library science") || lower.contains("library and information science")
            || word("mlis") || lower.contains("mlis degree") || lower.contains("mlis program")
            || lower.contains("library program") || lower.contains("library school")
            || lower.contains("library class") || lower.contains("library degree")
            || lower.contains("library technician") || word("cataloging") || word("cataloguing")
            || word("cataloger") || lower.contains("reference services")
            || lower.contains("reference librarian") || lower.contains("archival science")
            || word("archivist") || lower.contains("special collections")
            || lower.contains("archival research") || lower.contains("library management")
            || lower.contains("library collection") || lower.contains("digital library")
            || lower.contains("library metadata") || lower.contains("knowledge organization") {
            return "libraryscience"
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
            || word("run") || word("running") || word("cardio") || word("jogging") || word("cycling")
            || word("yoga") || word("pilates") || word("stretching") || word("swimming")
            || word("training")
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
        // chiropractic — positioned after veterinary (shares anatomical vocabulary) and before
        // dental so DC-degree/NBCE board terms don't fall through to generic premed callouts.
        if word("chiropractor") || word("chiropractic") || word("chiropractors")
            || lower.contains("chiropractic school") || lower.contains("chiropractic program")
            || lower.contains("chiropractic class") || lower.contains("chiropractic exam")
            || lower.contains("chiropractic clinic") || lower.contains("chiropractic notes")
            || lower.contains("chiropractic adjustment") || lower.contains("spinal adjustment")
            || lower.contains("spinal manipulation") || word("subluxation")
            || word("nbce") || lower.contains("chiropractic board")
            || lower.contains("doctor of chiropractic")
            || lower.contains("dc degree") || lower.contains("dc program")
            || lower.contains("chiropractic rotation") || lower.contains("chiropractic technique") {
            return "chiropractic"
        }
        // dentalassisting — positioned BEFORE dentalhygiene so dental assistant school,
        // DANB exam, and chairside assisting tasks route here rather than the hygienist pool.
        if lower.contains("dental assisting") || lower.contains("dental assistant program")
            || lower.contains("dental assistant school") || lower.contains("dental assistant class")
            || lower.contains("dental assistant exam") || lower.contains("dental assistant certification")
            || lower.contains("dental assistant course") || lower.contains("dental assistant notes")
            || word("danb") || lower.contains("danb exam")
            || lower.contains("chairside assisting") || lower.contains("chairside assistant")
            || lower.contains("coronal polish") || lower.contains("dental assisting program")
            || lower.contains("dental assisting school") || lower.contains("dental assisting class")
            || lower.contains("dental assisting course") || lower.contains("dental assisting exam")
            || lower.contains("dental materials course")
            || lower.contains("infection control dental") {
            return "dentalassisting"
        }
        // dentalhygiene — positioned BEFORE dental so dental hygiene school, NBDHE board prep,
        // and oral-health-assessment tasks get the hygienist-specific callout pool.
        // "dental hygiene"/"dental hygienist" removed from the dental branch below.
        if lower.contains("dental hygiene") || lower.contains("dental hygienist")
            || lower.contains("dental hygienists")
            || word("nbdhe") || lower.contains("dlosce")
            || lower.contains("dental hygiene school") || lower.contains("dental hygiene program")
            || lower.contains("dental hygiene class") || lower.contains("dental hygiene exam")
            || lower.contains("dental hygiene certification") || lower.contains("dental hygiene board")
            || lower.contains("periodontal charting") || lower.contains("periodontal therapy")
            || lower.contains("oral health assessment") || lower.contains("oral health education")
            || lower.contains("scaling and root planing") || lower.contains("root planing")
            || lower.contains("fluoride application") || lower.contains("fluoride treatment")
            || lower.contains("sealant application") || lower.contains("dental sealant")
            || word("prophylaxis")
            || word("adha") {
            return "dentalhygiene"
        }
        // dental — positioned before premed so dental-school-specific terms (NBDE, DDS/DMD,
        // perio, ortho, endodontics, dental boards) don't fall through to generic premed callouts.
        // "dental hygiene"/"dental hygienist" now owned by the dentalhygiene branch above.
        if word("dds") || word("dmd") || lower.contains("dental school")
            || lower.contains("dental board") || lower.contains("dental boards")
            || lower.contains("nbde") || lower.contains("inbde")
            || word("periodontology") || word("periodontics") || word("periodontal")
            || word("orthodontics") || word("orthodontist")
            || word("endodontics") || word("endodontist") || word("root canal")
            || word("prosthodontics") || word("prosthodontist")
            || word("oral surgery") || lower.contains("oral surgeon")
            || word("pedodontics") || lower.contains("pediatric dentistry")
            || lower.contains("dental radiology") || lower.contains("dental x-ray")
            || lower.contains("dental anatomy") || lower.contains("dental clinic")
            || lower.contains("clinical dentistry") || lower.contains("dental notes")
            || lower.contains("dental chart") || lower.contains("soap note")
                && lower.contains("dental") {
            return "dental"
        }
        // pharmacy — positioned before premed so PharmD/NAPLEX terms don't fall to premed
        // via shared terms like "pharmacology" (premed catches bare word("pharmacology") for med
        // school; pharmacy catches pharmacy school and practice terms that don't fit med school).
        if word("pharmd") || lower.contains("pharm d")
            || lower.contains("pharmacy school") || lower.contains("pharmacy program")
            || lower.contains("pharmacy class") || lower.contains("pharmacy exam")
            || lower.contains("pharmacy board") || lower.contains("naplex")
            || lower.contains("mpje") || lower.contains("pharmacy practice")
            || lower.contains("drug interactions") || lower.contains("drug interaction")
            || lower.contains("clinical pharmacy") || lower.contains("pharmacy notes")
            || lower.contains("compounding") || lower.contains("dispensing")
            || lower.contains("pharmacokinetics") || lower.contains("pharmacodynamics")
            || lower.contains("medication therapy") || lower.contains("medication management")
            || lower.contains("medication reconciliation")
            || lower.contains("drug therapy") || lower.contains("therapeutics")
            || lower.contains("pharmacy rotation") || lower.contains("pharmacy clerkship")
            || lower.contains("mtm") {
            return "pharmacy"
        }
        // molecularbiology — positioned after pharmacy and before premed so lab-science terms
        // (PCR, Western blot, cloning, gene editing) route here rather than the MCAT/clinical pool.
        // Bare word("biochemistry") stays in premed (MCAT context); "molecular biology" is explicit.
        if lower.contains("molecular biology") || lower.contains("molecular biologist")
            || lower.contains("cell biology") || lower.contains("molecular genetics")
            || lower.contains("western blot") || lower.contains("western blotting")
            || lower.contains("gel electrophoresis") || lower.contains("gel analysis")
            || lower.contains("southern blot") || lower.contains("northern blot")
            || word("crispr") || lower.contains("crispr-cas9") || lower.contains("gene editing")
            || lower.contains("gene expression analysis") || lower.contains("gene expression study")
            || lower.contains("protein expression") || lower.contains("protein purification")
            || lower.contains("recombinant dna") || lower.contains("molecular cloning")
            || lower.contains("cloning vector") || word("plasmid") || word("plasmids")
            || lower.contains("restriction enzyme") || lower.contains("restriction digest")
            || word("transfection") || lower.contains("cell transfection")
            || lower.contains("cell culture") && (lower.contains("molecular") || lower.contains("biology") || lower.contains("lab"))
            || lower.contains("flow cytometry") || word("elisa")
            || lower.contains("dna sequencing") && !lower.contains("bioinformatics")
            || lower.contains("gene knockout") || lower.contains("gene knockdown")
            || lower.contains("molecular lab") || lower.contains("molecular techniques")
            || lower.contains("pcr protocol") || lower.contains("pcr result") || lower.contains("run pcr") {
            return "molecularbiology"
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
        // optometry — positioned after premed so OD-school-specific terms (NBEO, visual acuity,
        // refraction, optometry clinic) don't misfire for medical students rotating through ophthalmology.
        if word("optometry") || word("optometrist")
            || lower.contains("od degree") || lower.contains("od program")
            || lower.contains("optometry school") || lower.contains("optometry clinic")
            || lower.contains("optometry board") || lower.contains("nbeo")
            || lower.contains("visual acuity") || lower.contains("visual field")
            || lower.contains("refraction") || lower.contains("refractive error")
            || lower.contains("contact lens") || lower.contains("contact lenses")
            || word("phoropter") || lower.contains("slit lamp")
            || lower.contains("retinal exam") || lower.contains("ocular health")
            || lower.contains("ocular disease") || lower.contains("binocular vision")
            || lower.contains("low vision") || lower.contains("osce optometry")
            || lower.contains("optometry rotation") || lower.contains("optometry notes")
            || lower.contains("optometry chart") || lower.contains("clinical optometry") {
            return "optometry"
        }
        // physicianassistant — positioned after optometry (PA school shares broad clinical curriculum
        // with premed/med-school) and before paramedicine (separate emergency-medical track).
        // Catches PANCE/PANRE exam prep, PA school coursework, and clinical rotation work.
        if lower.contains("physician assistant") || lower.contains("physician's assistant")
            || lower.contains("pa school") || lower.contains("pa program")
            || lower.contains("pa class") || lower.contains("pa exam")
            || lower.contains("pa student") || lower.contains("pa coursework")
            || lower.contains("pa rotation") || lower.contains("pa clerkship")
            || lower.contains("pa notes") || lower.contains("pa clinical")
            || lower.contains("pance") || lower.contains("panre")
            || lower.contains("pa-c") {
            return "physicianassistant"
        }
        // paramedicine — positioned before nursing so EMT/paramedic-specific terms
        // (NREMT exam, pre-hospital care, BLS/ACLS certifications) don't fall through to nursing.
        if word("emt") || word("paramedic") || word("paramedics") || word("paramedicine")
            || lower.contains("nremt") || lower.contains("aemt")
            || lower.contains("emergency medical technician")
            || lower.contains("ems protocol") || lower.contains("ems training")
            || lower.contains("ems class") || lower.contains("ems certification")
            || lower.contains("ems exam") || lower.contains("ems program")
            || lower.contains("pre-hospital") || lower.contains("prehospital")
            || lower.contains("trauma assessment") || lower.contains("field triage")
            || lower.contains("basic life support") || lower.contains("advanced life support")
            || word("acls") || word("pals")
            || lower.contains("cpr certification") || lower.contains("airway management") {
            return "paramedicine"
        }
        // respiratorytherapy — positioned after paramedicine (which owns airway management in
        // the EMS context) and before nursing so RT-specific terms route here.
        if lower.contains("respiratory therapy") || lower.contains("respiratory therapist")
            || lower.contains("respiratory therapists")
            || word("rrt") || word("crt")
            || word("nbrc") || lower.contains("respiratory therapy board")
            || lower.contains("respiratory therapy school") || lower.contains("respiratory therapy program")
            || lower.contains("respiratory therapy class") || lower.contains("respiratory therapy exam")
            || lower.contains("respiratory therapy notes") || lower.contains("respiratory therapy rotation")
            || lower.contains("ventilator management") || lower.contains("mechanical ventilation")
            || lower.contains("pulmonary function test") || lower.contains("pulmonary function tests")
            || lower.contains("arterial blood gas") || word("abg")
            || lower.contains("nebulizer treatment") || word("bronchodilator")
            || lower.contains("respiratory care") || lower.contains("respiratory assessment") {
            return "respiratorytherapy"
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
        // socialwork — positioned before therapy so social-work-specific tasks (case management,
        // child welfare, community resources) route here instead of to therapist callouts.
        // "social work" is owned here; "social work" in the therapy branch is removed.
        if lower.contains("social work") || lower.contains("social worker")
            || lower.contains("social workers")
            || word("msw") || word("bsw") || word("lmsw")
            || lower.contains("case management") || word("casework")
            || lower.contains("child protective services") || lower.contains("child welfare")
            || lower.contains("community resources") || lower.contains("family services")
            || lower.contains("social services") || lower.contains("intake assessment")
            || lower.contains("social welfare") || lower.contains("welfare policy")
            || (lower.contains("field placement") && lower.contains("social")) {
            return "socialwork"
        }
        // therapy — positioned after nursing (shared healthcare context) and before tutor
        // so "counseling" doesn't route to tutor via word("coaching").
        // "social work" moved to the dedicated socialwork branch above.
        if lower.contains("therapy notes") || lower.contains("session notes")
            || lower.contains("progress notes") || lower.contains("treatment plan")
            || lower.contains("case conceptualization") || lower.contains("case formulation")
            || lower.contains("intake notes") || lower.contains("clinical notes")
            || word("therapist") || word("counseling") || word("counselor")
            || word("lcsw") || word("lmft") || word("lpc") || word("mft")
            || lower.contains("cbt worksheets") || lower.contains("dbt skills")
            || lower.contains("exposure therapy") || lower.contains("cognitive behavioral")
            || lower.contains("clinical hours")
            || lower.contains("supervision notes") || lower.contains("client notes")
            || lower.contains("case notes") || lower.contains("mental health notes") {
            return "therapy"
        }
        // occupationaltherapy — positioned after therapy so OT-specific terms
        // (NBCOT exam, ADLs, sensory integration, hand therapy) don't conflict with
        // generic therapy/counseling terms.
        if lower.contains("occupational therapy") || lower.contains("occupational therapist")
            || lower.contains("occupational therapists")
            || word("nbcot")
            || lower.contains("activities of daily living") || word("adls") || word("adl")
            || lower.contains("hand therapy") || lower.contains("pediatric ot")
            || lower.contains("sensory integration") || lower.contains("sensory processing")
            || lower.contains("fine motor skills") || lower.contains("adaptive equipment")
            || lower.contains("ot fieldwork") || lower.contains("ot placement")
            || lower.contains("ot school") || lower.contains("ot program")
            || lower.contains("ot class") || lower.contains("ot exam") {
            return "occupationaltherapy"
        }
        // speecharts — positioned BEFORE speechpathology so debate, Model UN, public speaking
        // competitions, and competitive speech tasks route here. "speech therapy"/"SLP" stay in
        // speechpathology. "forensics" as a bare word is NOT matched (too ambiguous with forensic science).
        if lower.contains("debate team") || lower.contains("competitive debate")
            || lower.contains("debate tournament") || lower.contains("debate competition")
            || lower.contains("speech team") || lower.contains("speech tournament")
            || lower.contains("speech competition") || lower.contains("speech and debate")
            || lower.contains("model un") || lower.contains("model united nations")
            || word("mun") && (lower.contains("conference") || lower.contains("committee") || lower.contains("resolution"))
            || lower.contains("lincoln-douglas") || lower.contains("ld debate")
            || lower.contains("policy debate") || lower.contains("parliamentary debate")
            || lower.contains("extemporaneous speech") || lower.contains("extemporaneous speaking")
            || lower.contains("public speaking class") || lower.contains("public speaking course")
            || lower.contains("public speaking competition") || lower.contains("public speaking exam")
            || lower.contains("oratory") || word("oratorical")
            || lower.contains("competitive speech") || lower.contains("forensics team")
            || lower.contains("forensics tournament") || lower.contains("speech tournament")
            || lower.contains("persuasive speech") || lower.contains("informative speech")
            || lower.contains("impromptu speech") || lower.contains("after dinner speech")
            || lower.contains("oral interpretation") || lower.contains("dramatic interpretation") {
            return "speecharts"
        }
        // speechpathology — positioned after occupationaltherapy, before publicheath.
        // Catches SLP clinical work, ASHA credentials, communication/swallowing disorders.
        // "therapy notes" stays in the therapy branch above; speechpathology claims disorder-specific terms.
        if lower.contains("speech therapy") || lower.contains("speech therapist")
            || lower.contains("speech-language") || lower.contains("speech language")
            || word("slp")
            || word("aphasia") || word("dysarthria") || word("dysphagia") || word("apraxia")
            || lower.contains("language disorder") || lower.contains("speech disorder")
            || lower.contains("communication disorder") || lower.contains("communication disorders")
            || word("stuttering")
            || lower.contains("voice therapy") || lower.contains("voice disorder")
            || lower.contains("augmentative communication") || lower.contains("aac device")
            || lower.contains("phonological awareness")
            || lower.contains("swallowing therapy") || lower.contains("feeding therapy")
            || word("asha")
            || lower.contains("praxis slp") || lower.contains("praxis exam speech")
            || lower.contains("slp school") || lower.contains("slp program") || lower.contains("slp exam")
            || lower.contains("clinical fellowship") && lower.contains("speech") {
            return "speechpathology"
        }
        // publicheath — positioned after therapy (clinical context) and before socialscience.
        // Catches MPH programs, epidemiology, community/global health, outbreak investigation,
        // and population health. "health policy" stays in the policy branch.
        if word("epidemiology") || word("epidemiologist") || word("epidemiological")
            || word("biostatistics") || word("biostatistician")
            || lower.contains("community health") || lower.contains("global health")
            || lower.contains("public health")
            || lower.contains("infectious disease") || lower.contains("infectious diseases")
            || word("outbreak") || lower.contains("outbreak investigation")
            || lower.contains("population health") || lower.contains("health equity")
            || lower.contains("social determinants of health") || word("sdoh")
            || lower.contains("health disparities") || lower.contains("health promotion")
            || lower.contains("occupational health") || lower.contains("environmental health")
            || lower.contains("disease surveillance") || lower.contains("contact tracing")
            || lower.contains("mph program") || lower.contains("mph degree")
            || lower.contains("mph student") || lower.contains("mph class")
            || lower.contains("mph exam") || lower.contains("mph capstone")
            || lower.contains("mph thesis") || lower.contains("master of public health") {
            return "publicheath"
        }
        // psychology — positioned after publicheath and all clinical health branches above.
        // "educational psychology" fires in the education branch first; clinical/counseling
        // terms fire in therapy/socialwork above. This catches academic and research psych.
        if word("psychology") || word("psychologist") || word("psychologists")
            || lower.contains("psych major") || lower.contains("psych class")
            || lower.contains("psych course") || lower.contains("psych exam")
            || lower.contains("psych paper") || lower.contains("psych research")
            || lower.contains("psych thesis") || lower.contains("psych homework")
            || lower.contains("psych assignment")
            || lower.contains("social psychology") || lower.contains("cognitive psychology")
            || lower.contains("developmental psychology") || lower.contains("behavioral psychology")
            || lower.contains("abnormal psychology") || lower.contains("neuropsychology")
            || lower.contains("positive psychology") || lower.contains("personality psychology")
            || lower.contains("experimental psychology") || lower.contains("applied psychology")
            || lower.contains("psychology research") || lower.contains("psychology paper")
            || lower.contains("psychology thesis") || lower.contains("psychology class")
            || lower.contains("psychology course") || lower.contains("psychology major")
            || lower.contains("psychology exam") || lower.contains("psychology assignment")
            || lower.contains("gre psychology") || lower.contains("gre psych")
            || word("freud") || word("skinner") || word("pavlov") || word("piaget") || word("bandura")
            || word("psychometrics") || lower.contains("personality theory")
            || lower.contains("attachment theory") || lower.contains("cognitive development")
            || lower.contains("psychological research") || lower.contains("psychology study") {
            return "psychology"
        }
        // forensicscience — positioned BEFORE criminaljustice so crime-lab, DNA analysis,
        // and forensic-science coursework route here. "forensic accounting" is owned by its own
        // earlier branch. Bare "forensics" is NOT matched (ambiguous: could be speech forensics).
        if lower.contains("forensic science") || lower.contains("forensic scientist")
            || lower.contains("forensic scientists")
            || lower.contains("forensic biology") || lower.contains("forensic chemistry")
            || lower.contains("forensic toxicology") || lower.contains("forensic pathology")
            || lower.contains("forensic entomology") || lower.contains("forensic anthropology")
            || lower.contains("forensic serology") || lower.contains("forensic genetics")
            || lower.contains("dna analysis") || lower.contains("dna profiling")
            || lower.contains("dna evidence") || lower.contains("dna typing")
            || lower.contains("trace evidence") || lower.contains("ballistics")
            || lower.contains("fingerprint analysis") || lower.contains("fingerprint identification")
            || lower.contains("fingerprint examination")
            || lower.contains("crime lab") || lower.contains("crime scene")
            || lower.contains("forensic lab") || lower.contains("evidence analysis")
            || word("fepac")
            || lower.contains("bloodstain pattern") || lower.contains("serology lab")
            || lower.contains("toxicology lab") || lower.contains("forensic class")
            || lower.contains("forensic course") || lower.contains("forensic exam")
            || lower.contains("forensic program") || lower.contains("forensic degree") {
            return "forensicscience"
        }
        // criminaljustice — split from socialscience so criminology and criminal justice tasks get
        // a dedicated callout pool. Positioned BEFORE socialscience. "criminal law" routed here
        // because it is a criminal-justice course, not a law-school litigation task.
        if word("criminology") || word("criminologist")
            || lower.contains("criminal justice")
            || lower.contains("criminal law")
            || lower.contains("criminal procedure") || lower.contains("criminal court")
            || word("penology") || lower.contains("prison reform")
            || lower.contains("juvenile justice") || lower.contains("juvenile delinquency")
            || lower.contains("law enforcement") || lower.contains("policing")
            || lower.contains("corrections") || lower.contains("correctional")
            || lower.contains("incarceration") || word("victimology")
            || lower.contains("crime prevention") || lower.contains("crime analysis") {
            return "criminaljustice"
        }
        // socialscience — positioned after criminaljustice (which now owns criminology/criminal justice)
        // and before legal (LSAT is pre-law, not a bar-exam term). "social work" routes to socialwork.
        // Note: word("sociology") is already in the studying branch — not repeated here.
        if lower.contains("political science") || lower.contains("poli sci")
            || word("anthropology") || word("anthropological")
            || lower.contains("ethnography") || lower.contains("ethnographic")
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
        // theology — positioned after philosophy (shares analytical/historical study methods) and
        // before policy/legal so scripture analysis and seminary work don't fall to other pools.
        if word("theology") || word("theological") || word("theologian")
            || lower.contains("biblical studies") || lower.contains("bible study")
            || lower.contains("new testament") || lower.contains("old testament")
            || word("seminary") || lower.contains("seminary class") || lower.contains("seminary school")
            || lower.contains("systematic theology") || lower.contains("church history")
            || lower.contains("christian theology")
            || word("divinity") || lower.contains("divinity school")
            || lower.contains("mdiv") || lower.contains("m.div")
            || word("exegesis") || word("hermeneutics") || word("eschatology")
            || word("christology") || word("soteriology") || word("ecclesiology")
            || lower.contains("religious studies") || lower.contains("world religions")
            || lower.contains("comparative religion")
            || lower.contains("islamic studies") || lower.contains("jewish studies")
            || lower.contains("philosophy of religion")
            || lower.contains("scripture analysis") || lower.contains("scripture study")
            || word("homiletics")
            || lower.contains("liturgy") || word("liturgical") {
            return "theology"
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
        // interiordesign — positioned BEFORE the architecture branch so "interior design",
        // "space planning", and NCIDQ don't fall through to the building-architecture messages.
        if lower.contains("interior design") || lower.contains("interior designer")
            || lower.contains("interior decorating") || lower.contains("interior decorator")
            || lower.contains("space planning")
            || lower.contains("mood board") || lower.contains("moodboard")
            || lower.contains("material board") || lower.contains("materials board")
            || lower.contains("furniture layout") || lower.contains("furniture plan")
            || lower.contains("furniture selection") || lower.contains("furniture specification")
            || word("ncidq")
            || lower.contains("kitchen design") || lower.contains("bathroom design")
            || lower.contains("interior rendering") || lower.contains("room rendering") {
            return "interiordesign"
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
