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
        // interpreting — positioned BEFORE signlanguage so RID certification, court/medical/legal
        // interpreting, and professional ASL/spoken-language interpretation route here rather
        // than signlanguage coursework. Bare word("interpreter") alone is NOT matched (too
        // ambiguous with code "interpreter pattern").
        if lower.contains("sign language interpreting") || lower.contains("asl interpreting")
            || lower.contains("asl interpreter") && (lower.contains("cert") || lower.contains("class") || lower.contains("exam") || lower.contains("program") || lower.contains("professional"))
            || lower.contains("rid exam") || lower.contains("rid certification") || lower.contains("rid credential")
            || lower.contains("court interpreting") || lower.contains("court interpreter")
            || lower.contains("medical interpreting") || lower.contains("medical interpreter")
            || lower.contains("community interpreting") || lower.contains("community interpreter")
            || lower.contains("spoken language interpreter") || lower.contains("spoken language interpreting")
            || lower.contains("simultaneous interpreting") || lower.contains("consecutive interpreting")
            || lower.contains("conference interpreting") || lower.contains("conference interpreter")
            || lower.contains("interpreter certification") || lower.contains("interpreter training") && lower.contains("lang")
            || lower.contains("interpreting program") || lower.contains("interpreting class") || lower.contains("interpreting exam")
            || lower.contains("language interpreting") || lower.contains("legal interpreting") {
            return "interpreting"
        }
        // signlanguage — positioned BEFORE linguistics so "sign language", "ASL", and
        // "deaf education" route here rather than the general language-science pool.
        if lower.contains("sign language") || lower.contains("american sign language")
            || lower.contains("asl class") || lower.contains("asl course")
            || lower.contains("asl exam") || lower.contains("asl assignment")
            || lower.contains("asl program") || lower.contains("asl linguistics")
            || lower.contains("asl study") || lower.contains("learning asl")
            || lower.contains("studying asl")
            || lower.contains("deaf education") || lower.contains("deaf culture")
            || lower.contains("deaf studies") || lower.contains("deaf community")
            || word("fingerspelling") || lower.contains("hand shape") || lower.contains("handshape")
            || lower.contains("signed english") || lower.contains("sign language linguistics")
            || lower.contains("asl interpreter") || lower.contains("sign language interpreter")
            || (lower.contains("interpreter training") && (lower.contains("sign") || lower.contains("asl") || lower.contains("deaf"))) {
            return "signlanguage"
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
        // geospatial — positioned BEFORE geology so GIS/remote sensing/spatial analysis tasks
        // route here. "gis analysis" and "gis mapping" removed from geology and owned here.
        // Bare word("geography") alone does NOT fire (stays in studying/socialscience).
        if word("gis") || word("arcgis") || word("qgis") || word("postgis")
            || lower.contains("geographic information system") || lower.contains("geographic information systems")
            || lower.contains("geospatial analysis") || lower.contains("geospatial science")
            || lower.contains("geospatial data") || lower.contains("geospatial technology")
            || lower.contains("spatial analysis") || lower.contains("spatial data")
            || lower.contains("spatial statistics") || lower.contains("geographic analysis")
            || lower.contains("gis mapping") || lower.contains("gis analysis")
            || lower.contains("gis lab") || lower.contains("gis class")
            || lower.contains("gis course") || lower.contains("gis project")
            || lower.contains("gis software") || lower.contains("gis exam")
            || lower.contains("remote sensing") || lower.contains("satellite imagery")
            || lower.contains("aerial mapping") || lower.contains("aerial imagery")
            || lower.contains("lidar data") || lower.contains("lidar analysis")
            || word("cartography") || word("cartographer") || word("cartographic")
            || lower.contains("map projection") || lower.contains("map projections")
            || lower.contains("geospatial exam") || lower.contains("geospatial course")
            || lower.contains("gisp exam") || word("gisp") {
            return "geospatial"
        }
        // geology — positioned before engineering so "geology lab" and earth-science field tasks
        // don't fall through to engineering or research via word("lab").
        // "geography" alone does NOT fire here (stays in studying/socialscience).
        // "gis mapping" / "gis analysis" now owned by geospatial branch above.
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
            || lower.contains("soil science") || lower.contains("soil mechanics")
            || lower.contains("hydrology") {
            return "geology"
        }
        // aviation — positioned before engineering so flight-school, FAA exam, and piloting
        // tasks don't fall through to the engineering pool (which owns "aerospace engineering").
        if word("aviation") || word("aviator") || word("aviators")
            || lower.contains("pilot training") || lower.contains("student pilot")
            || lower.contains("flight training") || lower.contains("flight school")
            || lower.contains("flight lesson") || lower.contains("flight lessons")
            || lower.contains("ground school") || lower.contains("ground training")
            || lower.contains("faa exam") || lower.contains("faa written") || lower.contains("faa test")
            || lower.contains("faa knowledge") || lower.contains("faa checkride") || word("checkride")
            || lower.contains("private pilot") || lower.contains("commercial pilot")
            || lower.contains("instrument rating") || lower.contains("instrument pilot")
            || lower.contains("multi-engine rating") || lower.contains("multi engine rating")
            || word("ppl") && lower.contains("pilot")
            || word("cpl") && lower.contains("pilot")
            || lower.contains("atp certificate") || lower.contains("atp cert") || lower.contains("atp exam")
            || lower.contains("solo flight") || lower.contains("cross-country flight")
            || lower.contains("ifr training") || lower.contains("vfr training")
            || lower.contains("airspace") && lower.contains("study")
            || word("aopa") || lower.contains("flight simulator") && lower.contains("training")
            || lower.contains("aviation class") || lower.contains("aviation course")
            || lower.contains("aviation exam") || lower.contains("aviation program") {
            return "aviation"
        }
        // humanfactors — positioned BEFORE engineering so ergonomics, human-factors engineering,
        // and BCPE exam tasks get their own pool. Bare "ergonomic" alone is NOT matched (too common
        // in marketing copy for chairs and keyboards).
        if lower.contains("human factors") || lower.contains("human factor engineering")
            || word("ergonomics") || word("ergonomist") || word("hfe") || word("hfes")
            || lower.contains("occupational ergonomics") || lower.contains("cognitive ergonomics")
            || lower.contains("physical ergonomics") || lower.contains("workplace ergonomics")
            || lower.contains("workstation assessment") || lower.contains("workstation design")
            || lower.contains("usability engineering") || word("bcpe")
            || lower.contains("anthropometry") || word("anthropometric")
            || lower.contains("work physiology") || lower.contains("occupational health ergonomics")
            || lower.contains("human factors exam") || lower.contains("human factors class")
            || lower.contains("human factors course") || lower.contains("ergonomics class")
            || lower.contains("ergonomics course") || lower.contains("ergonomics exam")
            || lower.contains("human-systems integration") || lower.contains("human systems integration") {
            return "humanfactors"
        }
        // landsurveyingtech — positioned BEFORE engineering so surveying programs, FS exam prep,
        // and GPS/boundary survey tasks route here. Bare word("survey") stays in research/studying.
        if lower.contains("land surveying") || lower.contains("land surveyor") || lower.contains("land surveyors")
            || lower.contains("survey technology") || lower.contains("survey tech program")
            || lower.contains("survey tech class") || lower.contains("survey tech exam")
            || lower.contains("surveying program") || lower.contains("surveying class")
            || lower.contains("surveying course") || lower.contains("surveying exam")
            || lower.contains("surveying school") || lower.contains("surveying lab")
            || lower.contains("fs exam") && (lower.contains("surveying") || lower.contains("surveyor"))
            || lower.contains("fundamentals of surveying") || lower.contains("ps exam") && lower.contains("survey")
            || lower.contains("boundary survey") || lower.contains("cadastral survey")
            || lower.contains("topographic survey") || lower.contains("geomatics")
            || lower.contains("gps surveying") || lower.contains("gnss survey")
            || lower.contains("total station") && lower.contains("survey")
            || lower.contains("property survey") && lower.contains("class")
            || lower.contains("surveying technology") || lower.contains("surveying degree")
            || lower.contains("ncees surveying") || lower.contains("surveying certification")
            || lower.contains("plss survey") || lower.contains("legal description") && lower.contains("surveying") {
            return "landsurveyingtech"
        }
        // environmentalengineering — positioned BEFORE engineering so wastewater treatment, water/air
        // quality control, and remediation tasks route here. Generic word("engineering") falls through.
        if lower.contains("environmental engineering") || lower.contains("environmental engineer")
            || lower.contains("wastewater treatment") || lower.contains("wastewater plant")
            || lower.contains("water quality") && (lower.contains("engineer") || lower.contains("class") || lower.contains("lab") || lower.contains("course"))
            || lower.contains("air quality") && (lower.contains("engineer") || lower.contains("class") || lower.contains("control"))
            || lower.contains("environmental remediation") || lower.contains("site remediation")
            || lower.contains("groundwater contamination") || lower.contains("groundwater remediation")
            || lower.contains("hazardous waste") && (lower.contains("class") || lower.contains("management") || lower.contains("engineer"))
            || lower.contains("stormwater") && (lower.contains("engineer") || lower.contains("management") || lower.contains("design"))
            || lower.contains("environmental impact assessment") && lower.contains("engineer")
            || lower.contains("env eng") || lower.contains("environ eng") {
            return "environmentalengineering"
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
        // computationalscience — positioned after datascience and before bioinformatics so
        // HPC, parallel computing, and scientific simulation tasks route here.
        // "computational biology" stays in bioinformatics (fires later);
        // "numerical analysis" stays in mathematics (fires earlier).
        // Bare word("matlab") alone can be numerical/engineering — requires compound guard.
        if lower.contains("high performance computing") || lower.contains("hpc cluster")
            || lower.contains("parallel computing") || lower.contains("distributed computing")
            || lower.contains("scientific computing") || lower.contains("supercomputer")
            || lower.contains("computational physics") || lower.contains("computational chemistry")
            || lower.contains("computational neuroscience")
            || lower.contains("monte carlo simulation") || lower.contains("monte carlo method")
            || lower.contains("finite element simulation") || lower.contains("finite difference simulation")
            || lower.contains("numerical simulation") || lower.contains("simulation model")
            || lower.contains("mpi programming") || lower.contains("openmp programming")
            || lower.contains("cuda programming") || lower.contains("gpu computing")
            || lower.contains("computational modeling") || lower.contains("scientific simulation")
            || lower.contains("cluster computing") || lower.contains("job scheduler")
            || lower.contains("slurm job") || lower.contains("pbs job")
            || lower.contains("matlab simulation") || lower.contains("matlab model")
            || lower.contains("scipy simulation") || lower.contains("numpy simulation")
            || lower.contains("computational science") || lower.contains("computational scientist")
            || lower.contains("computational problem") || lower.contains("computational assignment")
            || lower.contains("computational class") || lower.contains("computational course") {
            return "computationalscience"
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
        // hospitality — positioned before business so hotel management, tourism, and event-planning
        // coursework routes here rather than the generic business pool.
        if lower.contains("hotel management") || lower.contains("hotel operations")
            || lower.contains("hotel industry") || lower.contains("hotel school")
            || lower.contains("hotel class") || lower.contains("hotel course")
            || lower.contains("hospitality management") || lower.contains("hospitality industry")
            || lower.contains("hospitality school") || lower.contains("hospitality class")
            || lower.contains("hospitality course") || lower.contains("hospitality program")
            || lower.contains("hospitality major") || lower.contains("hospitality exam")
            || lower.contains("food and beverage") || lower.contains("food & beverage")
            || lower.contains("front of house") || lower.contains("back of house")
            || lower.contains("housekeeping operations") || lower.contains("room division")
            || lower.contains("hotel revenue management") || lower.contains("hotel front desk")
            || lower.contains("event planning class") || lower.contains("event planning course")
            || lower.contains("event management class") || lower.contains("event management course")
            || lower.contains("tourism management") || lower.contains("tourism marketing")
            || lower.contains("tourism class") || lower.contains("tourism course")
            || lower.contains("hospitality marketing")
            || word("concierge") || lower.contains("resort management")
            || lower.contains("che exam") || lower.contains("cha exam") {
            return "hospitality"
        }
        // supplychain — positioned BEFORE business so SCM-exam prep, logistics coursework, and
        // procurement/operations-research classes get their own callout pool. Bare "supply chain"
        // stays in the business branch below for general MBA/business-context use.
        if lower.contains("cpim") || lower.contains("cscp") || word("apics")
            || lower.contains("supply chain management class") || lower.contains("supply chain management course")
            || lower.contains("supply chain management exam") || lower.contains("supply chain management program")
            || lower.contains("supply chain management degree") || lower.contains("supply chain management major")
            || lower.contains("logistics management class") || lower.contains("logistics management course")
            || lower.contains("logistics management exam") || lower.contains("logistics management program")
            || lower.contains("logistics class") || lower.contains("logistics course")
            || lower.contains("logistics exam") || lower.contains("logistics assignment")
            || lower.contains("procurement class") || lower.contains("procurement course")
            || lower.contains("procurement exam") || lower.contains("procurement assignment")
            || lower.contains("demand planning class") || lower.contains("demand forecasting class")
            || lower.contains("inventory management class") || lower.contains("inventory management course")
            || lower.contains("warehouse management class") || lower.contains("warehouse management course")
            || lower.contains("six sigma class") || lower.contains("six sigma course") || lower.contains("lean six sigma")
            || lower.contains("operations research class") || lower.contains("operations research course")
            || lower.contains("operations research exam") || lower.contains("operations research assignment")
            || lower.contains("supply chain analytics") || lower.contains("global supply chain class") {
            return "supplychain"
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
        // translationalresearch — positioned BEFORE research so "translational research" and
        // "bench to bedside" route here before word("research") catches them first.
        if lower.contains("translational research") || lower.contains("translational medicine")
            || lower.contains("bench to bedside") || lower.contains("bench-to-bedside")
            || lower.contains("t1 research") || lower.contains("t2 research")
            || lower.contains("t3 research") || lower.contains("t4 research")
            || lower.contains("clinical translation") || lower.contains("biomedical translation")
            || lower.contains("translational science") || lower.contains("translational biology")
            || lower.contains("ctsa program") || lower.contains("tl1 program")
            || lower.contains("clinical translational") || lower.contains("translational pharmacology") {
            return "translationalresearch"
        }
        if word("research") || word("lab")
            || lower.contains("case study") || lower.contains("case studies")
            || lower.contains("data analysis") || lower.contains("data collection")
            || word("dataset") || word("datasets") || lower.contains("qualitative") || lower.contains("quantitative") {
            return "research"
        }
        // communicationstudies — positioned after research/business and before journalism so
        // interpersonal communication, mass communication, and comm-theory courses route here.
        // bare word("communication") is NOT matched (too broad: software systems communicate too).
        // "public relations"/"press release" stay in journalism/publicrelations above.
        if lower.contains("communication studies") || lower.contains("communications studies")
            || lower.contains("communication theory") || lower.contains("communications theory")
            || lower.contains("interpersonal communication class") || lower.contains("interpersonal communication course")
            || lower.contains("interpersonal communication exam") || lower.contains("interpersonal communication paper")
            || lower.contains("mass communication") || lower.contains("media theory")
            || lower.contains("communication major") || lower.contains("communications major")
            || lower.contains("comm major") || lower.contains("comm class") || lower.contains("comm course")
            || lower.contains("comm exam") || lower.contains("comm paper") || lower.contains("comm research")
            || lower.contains("rhetoric class") || lower.contains("rhetoric course")
            || lower.contains("persuasion theory") || lower.contains("persuasion class")
            || lower.contains("organizational communication") || lower.contains("intercultural communication")
            || lower.contains("communication research methods") || lower.contains("comm research methods")
            || lower.contains("communication degree") || lower.contains("communications degree") {
            return "communicationstudies"
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
        // fashiondesign — positioned BEFORE graphicdesign (both use Adobe tools) and before art
        // so fashion illustration, garment construction, and fashion school tasks route here.
        if lower.contains("fashion design") || lower.contains("fashion designer")
            || lower.contains("fashion designers") || lower.contains("fashion illustration")
            || lower.contains("fashion school") || lower.contains("fashion program")
            || lower.contains("fashion class") || lower.contains("fashion course")
            || lower.contains("fashion major") || lower.contains("fashion exam")
            || lower.contains("fashion merchandising") || lower.contains("fashion buyer")
            || lower.contains("fashion marketing") || lower.contains("fashion business")
            || lower.contains("fashion show") || lower.contains("fashion portfolio")
            || lower.contains("garment construction") || lower.contains("garment design")
            || lower.contains("pattern making") || lower.contains("pattern drafting")
            || lower.contains("sewing pattern") || lower.contains("draping technique")
            || lower.contains("fashion sketching") || lower.contains("fashion drawing")
            || lower.contains("textile design") || lower.contains("fabric selection")
            || lower.contains("fashion collection") || lower.contains("fashion lookbook")
            || lower.contains("fashion tech pack") || lower.contains("tech pack")
            || word("couture") || lower.contains("haute couture")
            || lower.contains("fashion history") || lower.contains("fashion theory")
            || word("colorway") || word("colorways") {
            return "fashiondesign"
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
        // artrestoration — positioned after arthistory and BEFORE art so conservation/restoration
        // tasks route here rather than the generic art-making pool.
        // "painting conservation" is a compound, so word("painting") alone still goes to art.
        if lower.contains("art conservation") || lower.contains("art conservator")
            || lower.contains("art conservators") || lower.contains("art restoration")
            || lower.contains("art restorer") || lower.contains("art restorers")
            || lower.contains("painting conservation") || lower.contains("painting restoration")
            || lower.contains("paper conservation") || lower.contains("paper restoration")
            || lower.contains("object conservation") || lower.contains("textile conservation")
            || lower.contains("textile restoration") || lower.contains("sculpture conservation")
            || lower.contains("museum conservation") || lower.contains("conservation science")
            || lower.contains("preventive conservation") || lower.contains("conservation lab")
            || lower.contains("conservation studio") || lower.contains("conservation treatment")
            || lower.contains("varnish removal") || lower.contains("inpainting")
            || lower.contains("consolidation treatment") || lower.contains("surface cleaning")
            || lower.contains("conservation ethics") || lower.contains("conservation materials")
            || lower.contains("archival materials") || lower.contains("archival preservation")
            || lower.contains("conservation class") || lower.contains("conservation course")
            || lower.contains("conservation exam") || lower.contains("conservation program")
            || lower.contains("conservation major") || lower.contains("conservation degree") {
            return "artrestoration"
        }
        // productdesign — positioned before the generic art and design branches so "industrial design",
        // "product design", and "design for manufacturing" don't fall to the wireframe/figma design pool.
        // "design brief" stays in the design branch; "prototyping" here requires a compound term.
        if lower.contains("industrial design") || lower.contains("industrial designer")
            || lower.contains("product design") || lower.contains("product designer")
            || lower.contains("product designers")
            || word("idsa") || lower.contains("design for manufacturing") || lower.contains("dfm")
            || lower.contains("product development") && (lower.contains("design") || lower.contains("prototype"))
            || lower.contains("human factors") && !lower.contains("computer")
            || word("ergonomics") || word("ergonomic")
            || lower.contains("model making") || lower.contains("physical prototype")
            || lower.contains("concept model") || lower.contains("foam model")
            || lower.contains("product lifecycle") || lower.contains("product launch")
            || lower.contains("id sketching") || lower.contains("industrial design class")
            || lower.contains("industrial design course") || lower.contains("industrial design exam")
            || lower.contains("product design class") || lower.contains("product design course")
            || lower.contains("product design exam") || lower.contains("design portfolio")
            && (lower.contains("industrial") || lower.contains("product")) {
            return "productdesign"
        }
        // glassblowing — positioned BEFORE art so glass arts, flameworking, and kiln-formed
        // glass studio work route to dedicated glass-artist callouts rather than generic art.
        // Bare word("glass") is NOT matched (too generic: drinking glass, glass ceiling).
        if lower.contains("glassblowing") || lower.contains("glass blowing")
            || lower.contains("glass art") || lower.contains("glass arts")
            || lower.contains("glasswork") || lower.contains("glassworks")
            || lower.contains("glass artist") || lower.contains("glass artists")
            || lower.contains("flameworking") || lower.contains("flame working")
            || lower.contains("glass studio") || lower.contains("hot glass")
            || lower.contains("kiln-formed glass") || lower.contains("kiln formed glass")
            || lower.contains("glass casting") || lower.contains("fused glass") || lower.contains("glass fusing")
            || lower.contains("borosilicate") || lower.contains("torch work") && lower.contains("glass")
            || lower.contains("gaffer") && lower.contains("glass")
            || lower.contains("stained glass") && (lower.contains("class") || lower.contains("studio") || lower.contains("project") || lower.contains("art") || lower.contains("technique"))
            || lower.contains("glass class") || lower.contains("glass course") || lower.contains("glass program")
            || lower.contains("glass school") || lower.contains("glass exam") || lower.contains("glass techniques")
            || lower.contains("glass making") || lower.contains("glass fabrication")
            || lower.contains("cold glass") || lower.contains("warm glass") {
            return "glassblowing"
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
        // playwriting — positioned BEFORE performingarts so crafting a stage play, one-act,
        // or full-length play script routes here rather than the acting/dancing/theatre class pool.
        // "playwriting class/course/workshop" is caught earlier by dramaeducation; this branch
        // covers standalone creative playwriting work. Bare word("play") is NOT matched (too ambiguous).
        if lower.contains("stage play") || lower.contains("one-act play") || lower.contains("one act play")
            || lower.contains("two-act play") || lower.contains("two act play")
            || lower.contains("full-length play") || lower.contains("full length play")
            || lower.contains("play script") || lower.contains("play draft")
            || lower.contains("writing a play") || lower.contains("write a play")
            || lower.contains("writing my play") || lower.contains("write my play")
            || lower.contains("working on my play") || lower.contains("work on my play")
            || lower.contains("play i'm writing") || lower.contains("play i am writing")
            || lower.contains("original play") || lower.contains("new play")
            || lower.contains("play development") || lower.contains("new play development")
            || lower.contains("ten-minute play") || lower.contains("ten minute play")
            || lower.contains("10-minute play") || lower.contains("10 minute play")
            || lower.contains("play revision") || lower.contains("revising my play")
            || lower.contains("dramatic writing") && !lower.contains("class") && !lower.contains("course")
            || lower.contains("theatrical writing") || lower.contains("theatre writing") {
            return "playwriting"
        }
        // dancescience — positioned BEFORE performingarts so dance kinesiology, dance anatomy,
        // and somatic movement analysis route here rather than to general performing arts.
        // Bare word("dance") alone stays in performingarts; this branch needs dance + science context.
        if lower.contains("dance kinesiology") || lower.contains("dance anatomy")
            || lower.contains("dance science") || lower.contains("laban movement analysis")
            || word("lma") && lower.contains("dance")
            || lower.contains("somatic movement") && lower.contains("dance")
            || lower.contains("bartenieff fundamentals")
            || lower.contains("dance medicine") || lower.contains("dance injury")
            || lower.contains("dance biomechanics") || lower.contains("dance physiology")
            || lower.contains("movement analysis") && (lower.contains("dance") || lower.contains("laban"))
            || lower.contains("dance research") && lower.contains("science")
            || lower.contains("dance for pd") || lower.contains("dance wellness") {
            return "dancescience"
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
        // techwriting — positioned after writing so blog/draft/outline stay in writing, but
        // specific technical writing, API docs, and user manual tasks route here.
        // Bare word("technical") alone is not matched — requires a compound phrase.
        if lower.contains("technical writing") || lower.contains("technical writer")
            || lower.contains("user manual") || lower.contains("user manuals")
            || lower.contains("api documentation") || lower.contains("api docs")
            || lower.contains("technical documentation") || lower.contains("developer documentation")
            || lower.contains("developer docs") || lower.contains("software documentation")
            || lower.contains("release notes") && (lower.contains("write") || lower.contains("draft") || lower.contains("documentation"))
            || lower.contains("user guide") && (lower.contains("write") || lower.contains("draft") || lower.contains("technical"))
            || word("cptc") || lower.contains("cptc certification")
            || lower.contains("technical communication") || lower.contains("tech comm")
            || lower.contains("docs-as-code") || lower.contains("docs as code")
            || lower.contains("knowledge base") && lower.contains("write") {
            return "techwriting"
        }
        // taxprep — positioned before accounting and finance so tax return filing, TurboTax,
        // H&R Block, IRS forms, and EA exam prep route here rather than the accounting/budget pools.
        // "tax accounting class/course" stays in the accounting branch (student coursework context).
        if lower.contains("tax preparation") || lower.contains("tax preparer")
            || lower.contains("tax return") || lower.contains("tax returns")
            || lower.contains("tax filing") || lower.contains("file my taxes")
            || lower.contains("filing taxes") || lower.contains("file taxes")
            || word("turbotax") || lower.contains("h&r block") || lower.contains("h and r block")
            || lower.contains("irs form") || lower.contains("irs forms")
            || lower.contains("income tax") && !lower.contains("income tax class")
            && !lower.contains("income tax course")
            || lower.contains("1040 form") || lower.contains("form 1040")
            || lower.contains("w-2") && lower.contains("tax")
            || lower.contains("1099") && lower.contains("tax")
            || lower.contains("tax deduction") || lower.contains("tax deductions")
            || lower.contains("tax credit") || lower.contains("tax credits")
            || lower.contains("ea exam") || lower.contains("enrolled agent")
            || lower.contains("enrolled agent exam") || lower.contains("enrolled agent exam prep")
            || word("vita") && lower.contains("tax")
            || lower.contains("tax software") || lower.contains("tax season")
            || lower.contains("self-employment tax") || lower.contains("quarterly taxes")
            || lower.contains("small business tax") || lower.contains("business tax return") {
            return "taxprep"
        }
        // accounting — positioned before forensicaccounting and finance so general accounting
        // coursework, CMA prep, QuickBooks/Xero, and accounting-student tasks route here
        // rather than the finance or budget pools.
        // Bare word("accounting") and word("bookkeeping") stay in budget for non-student use.
        if lower.contains("accounting class") || lower.contains("accounting course")
            || lower.contains("accounting exam") || lower.contains("accounting homework")
            || lower.contains("accounting assignment") || lower.contains("accounting textbook")
            || lower.contains("accounting major") || lower.contains("accounting degree")
            || lower.contains("accounting program") || lower.contains("accounting principles")
            || lower.contains("accounting theory") || lower.contains("accounting lab")
            || lower.contains("accounting study") || lower.contains("accounting notes")
            || lower.contains("cma exam") || lower.contains("cma prep") || word("cma")
            || lower.contains("cma certification") || lower.contains("cma study")
            || word("quickbooks") || lower.contains("quickbooks certification")
            || lower.contains("quickbooks class") || lower.contains("quickbooks exam")
            || word("xero") || lower.contains("xero accounting") || lower.contains("xero class")
            || word("aicpa") || lower.contains("accounting certification")
            || lower.contains("audit class") || lower.contains("audit course")
            || lower.contains("audit textbook") || lower.contains("audit exam")
            || lower.contains("managerial accounting class") || lower.contains("managerial accounting course")
            || lower.contains("managerial accounting textbook") || lower.contains("managerial accounting exam")
            || lower.contains("cost accounting class") || lower.contains("cost accounting course")
            || lower.contains("cost accounting textbook") || lower.contains("cost accounting exam")
            || lower.contains("tax accounting class") || lower.contains("tax accounting course")
            || lower.contains("intermediate accounting") || lower.contains("advanced accounting")
            || lower.contains("accounting software") || lower.contains("bookkeeping class")
            || lower.contains("bookkeeping course") || lower.contains("bookkeeping exam") {
            return "accounting"
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
        // behavioraleconomics — positioned AFTER finance and BEFORE budget so behavioral-finance
        // and cognitive-bias coursework gets its own pool. Bare "economics" stays in
        // studying/business; bare "behavioral" alone is NOT matched.
        if lower.contains("behavioral economics") || lower.contains("behavioural economics")
            || lower.contains("behavioral economist") || lower.contains("behavioural economist")
            || lower.contains("nudge theory") || lower.contains("nudge unit")
            || lower.contains("cognitive bias") || lower.contains("cognitive biases")
            || lower.contains("loss aversion") || lower.contains("prospect theory")
            || lower.contains("anchoring bias") || lower.contains("anchoring effect")
            || lower.contains("choice architecture") || lower.contains("decision architecture")
            || word("thaler") || word("sunstein") || word("ariely")
            || lower.contains("bounded rationality") || lower.contains("satisficing")
            || lower.contains("mental accounting") || lower.contains("status quo bias")
            || lower.contains("present bias") || lower.contains("hyperbolic discounting")
            || lower.contains("default effects") || lower.contains("framing effects")
            || lower.contains("heuristics and biases") || lower.contains("dual process theory")
            || lower.contains("behavioral public policy")
            || lower.contains("behavioral science class") || lower.contains("behavioral science course")
            || lower.contains("behavioral science exam") {
            return "behavioraleconomics"
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
        // musiceducation — positioned BEFORE physed so marching band director, choral director,
        // and music methods coursework route here rather than the generic education pool.
        // Bare word("music") stays in musicproduction/musictheory; compound music+education terms fire here.
        if lower.contains("music education") || lower.contains("music educator")
            || lower.contains("music teacher") || lower.contains("music teaching")
            || lower.contains("music education class") || lower.contains("music education course")
            || lower.contains("music education exam") || lower.contains("music education degree")
            || lower.contains("music education major") || lower.contains("music education program")
            || lower.contains("music education school") || lower.contains("music methods class")
            || lower.contains("music methods course") || lower.contains("music pedagogy")
            || lower.contains("praxis music")
            || lower.contains("marching band director") || lower.contains("marching band teacher")
            || lower.contains("choral director") || lower.contains("choral education")
            || lower.contains("orchestra director") || lower.contains("orchestra teacher")
            || lower.contains("band director") || lower.contains("band teacher")
            || lower.contains("instrumental music teacher") || lower.contains("instrumental music class")
            || lower.contains("instrumental music program")
            || lower.contains("vocal music teacher") || lower.contains("vocal music class")
            || lower.contains("vocal music program") {
            return "musiceducation"
        }
        // arteducation — positioned AFTER musiceducation and BEFORE physed so art teacher
        // certification, visual arts education assignments, and NAEA / Praxis art prep route
        // here rather than the generic art or education pools.
        // Bare "art class" or "taking an art class" stays in studying/art; compound art+teaching/education terms fire here.
        if lower.contains("art education") || lower.contains("art educator")
            || lower.contains("art teacher") || lower.contains("art teaching")
            || lower.contains("visual art teacher") || lower.contains("visual arts education")
            || lower.contains("visual art teaching") || lower.contains("visual arts teacher")
            || lower.contains("studio art teacher") || lower.contains("elementary art teacher")
            || lower.contains("high school art teacher")
            || lower.contains("art curriculum") || lower.contains("art lesson plan")
            || lower.contains("art methods class") || lower.contains("art methods course")
            || lower.contains("art pedagogy") || lower.contains("art ed class")
            || lower.contains("art ed course") || lower.contains("art ed program")
            || lower.contains("praxis art") || lower.contains("national art education")
            || word("naea")
            || lower.contains("teaching art") || lower.contains("art certification")
                && lower.contains("teach") {
            return "arteducation"
        }
        // dramaeducation — positioned after arteducation and before physed so theatre/drama
        // teaching, playwriting class, and Praxis drama don't fall through to performingarts or education.
        // Bare "watching a play" / "going to the theatre" never fires (needs teaching or coursework context).
        if lower.contains("theatre education") || lower.contains("theater education")
            || lower.contains("theatre educator") || lower.contains("theater educator")
            || lower.contains("drama teacher") || lower.contains("drama teaching")
            || lower.contains("drama education") || lower.contains("drama educator")
            || lower.contains("drama classroom") || lower.contains("drama curriculum")
            || lower.contains("drama lesson plan") || lower.contains("drama pedagogy")
            || lower.contains("drama methods class") || lower.contains("drama methods course")
            || lower.contains("theatre methods class") || lower.contains("theatre methods course")
            || lower.contains("praxis drama") || lower.contains("praxis theatre")
            || lower.contains("praxis theater")
            || lower.contains("theatre arts education") || lower.contains("theater arts education")
            || lower.contains("tya") && lower.contains("theatre")
            || lower.contains("theatre for young audiences")
            || lower.contains("theater for young audiences")
            || lower.contains("playwriting class") || lower.contains("playwriting course")
            || lower.contains("playwriting workshop") || lower.contains("playwriting program")
            || lower.contains("dramatic literature class") || lower.contains("dramatic literature course")
            || lower.contains("theatre history class") || lower.contains("theatre history course")
            || lower.contains("theater history class") || lower.contains("theater history course")
            || lower.contains("stage design class") || lower.contains("stage design course")
            || lower.contains("theatre design class") || lower.contains("theatre design course")
            || lower.contains("directing class") && lower.contains("theatre")
            || lower.contains("directing class") && lower.contains("drama")
            || lower.contains("directing workshop") && lower.contains("theatre")
            || lower.contains("dramaturgy class") || lower.contains("dramaturgy course")
            || word("dramaturg") && (lower.contains("class") || lower.contains("course") || lower.contains("assignment"))
            || lower.contains("acting pedagogy") || lower.contains("drama school assignment")
            || lower.contains("theatre school assignment") {
            return "dramaeducation"
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
        // sportsanalytics — positioned before sportsmanagement so R/Python for sports data,
        // sabermetrics, player tracking, and sports data science route here (not the management pool).
        // "sports analytics" / "sport analytics" removed from sportsmanagement and owned here.
        if lower.contains("sports analytics") || lower.contains("sport analytics")
            || lower.contains("sports data science") || lower.contains("sport data science")
            || lower.contains("sports data analysis") || lower.contains("sport data analysis")
            || lower.contains("player tracking") || lower.contains("athlete tracking")
            || lower.contains("sabermetrics") || lower.contains("moneyball")
            || lower.contains("sports statistics class") || lower.contains("sports statistics course")
            || lower.contains("sports performance analytics") || lower.contains("game analytics")
            || lower.contains("expected goals") || lower.contains("advanced stats sports")
            || lower.contains("sports modeling") || lower.contains("predictive modeling sports")
            || lower.contains("sports analytics class") || lower.contains("sports analytics course")
            || lower.contains("sports analytics program") || lower.contains("sports analytics exam") {
            return "sportsanalytics"
        }
        // sportsmanagement — "sports analytics" is now owned by the sportsanalytics branch above.
        // Bare word("sports") alone does NOT fire (too ambiguous).
        if lower.contains("sports management") || lower.contains("sport management")
            || lower.contains("sports administration") || lower.contains("sport administration")
            || lower.contains("sports marketing") || lower.contains("sport marketing")
            || lower.contains("sports finance") || lower.contains("sports law")
            || lower.contains("sports business") || lower.contains("sport business")
            || lower.contains("athletic director") || lower.contains("athletic administration")
            || lower.contains("stadium management") || lower.contains("arena management")
            || lower.contains("sports event management") || lower.contains("sport event management")
            || lower.contains("sports industry") || lower.contains("sports organization")
            || lower.contains("sports agency") || lower.contains("player agent")
            || lower.contains("sports revenue") || lower.contains("sports sponsorship")
            || lower.contains("sports communications") || lower.contains("sport communications")
            || lower.contains("sports management class") || lower.contains("sports management course")
            || lower.contains("sports management program") || lower.contains("sports management major")
            || lower.contains("sports management exam") || lower.contains("sports management assignment") {
            return "sportsmanagement"
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
        // occupationalmedicine — positioned BEFORE kinesiology so physician-specialty terms
        // (ACOEM boards, industrial hygiene, occupational disease, work-related illness)
        // route here rather than the sport-science/physical-therapy pool.
        // "occupational health" (bare) stays in publicheath; "occupational therapy" fires
        // in its own dedicated branch after the therapy block further below.
        if lower.contains("occupational medicine") || lower.contains("occupational physician")
            || lower.contains("occupational medicine physician")
            || lower.contains("industrial medicine")
            || word("acoem") || lower.contains("acoem boards") || lower.contains("acoem exam")
            || lower.contains("occupational disease class") || lower.contains("occupational disease course")
            || lower.contains("occupational disease exam") || lower.contains("occupational disease assignment")
            || lower.contains("work-related illness") || lower.contains("work related illness")
            || lower.contains("workplace health assessment") && (lower.contains("class") || lower.contains("course"))
            || lower.contains("occupational medicine residency") || lower.contains("occupational medicine clerkship")
            || lower.contains("occupational and environmental medicine")
            || lower.contains("occupational medicine class") || lower.contains("occupational medicine course")
            || lower.contains("occupational medicine exam") || lower.contains("occupational medicine rotation")
            || lower.contains("industrial hygiene class") || lower.contains("industrial hygiene course")
            || lower.contains("industrial hygiene exam") || lower.contains("industrial hygiene certification")
            || lower.contains("industrial hygiene program") || lower.contains("industrial hygiene training")
            || word("cih") && (lower.contains("exam") || lower.contains("certification") || lower.contains("board") || lower.contains("prep"))
            || lower.contains("certified industrial hygienist") {
            return "occupationalmedicine"
        }
        // sportsmedicine — positioned BEFORE kinesiology so BOC exam prep, CAATE accreditation
        // coursework, and sports medicine physician rotation notes route to a dedicated pool.
        // "athletic training" stays in kinesiology for generic use; compound clinical-certification
        // terms like BOC, CAATE, sports medicine rotation/clinical hours fire here first.
        if lower.contains("sports medicine") || lower.contains("sport medicine")
            || lower.contains("sports medicine physician") || lower.contains("sports medicine doctor")
            || lower.contains("sports medicine class") || lower.contains("sports medicine course")
            || lower.contains("sports medicine exam") || lower.contains("sports medicine rotation")
            || lower.contains("sports medicine program") || lower.contains("sports medicine clerkship")
            || lower.contains("sports medicine clinical") || lower.contains("sports medicine internship")
            || word("boc") && (lower.contains("exam") || lower.contains("certification") || lower.contains("athletic") || lower.contains("training"))
            || lower.contains("boc exam") || lower.contains("boc certification") || lower.contains("boc athletic")
            || word("caate") || lower.contains("caate accreditation")
            || lower.contains("athletic training clinical") || lower.contains("clinical athletic training")
            || lower.contains("athletic training hours") || lower.contains("clinical hours athletic")
            || lower.contains("sports injury assessment") || lower.contains("sports injury documentation")
            || lower.contains("sideline assessment") || lower.contains("field assessment")
            || lower.contains("injury evaluation") && (lower.contains("athlete") || lower.contains("sport") || lower.contains("clinical"))
            || lower.contains("taping technique") || lower.contains("athletic taping")
            || lower.contains("concussion protocol") || lower.contains("concussion evaluation")
            || lower.contains("return to play protocol") || lower.contains("return to sport protocol")
            || lower.contains("sports medicine notes") || lower.contains("athletic training notes")
            || lower.contains("sports medicine team") && lower.contains("note") {
            return "sportsmedicine"
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
        // personaltraining — positioned BEFORE fitness so "NASM personal trainer exam" and
        // "ACE/NSCA certification" route here rather than the generic workout/gym fitness pool.
        if lower.contains("personal trainer") || lower.contains("personal training")
            || lower.contains("personal training certification") || lower.contains("personal training exam")
            || word("nasm") || lower.contains("nasm exam") || lower.contains("nasm certification")
            || lower.contains("ace certification") && lower.contains("personal")
            || lower.contains("ace fitness") || lower.contains("ace cpt")
            || lower.contains("nsca cpt") || lower.contains("nsca certification") && lower.contains("trainer")
            || lower.contains("client program") && lower.contains("train")
            || lower.contains("training program design") || lower.contains("client program design")
            || lower.contains("fitness coaching") || lower.contains("fitness coach")
            || lower.contains("corrective exercise") || lower.contains("periodization plan")
            || lower.contains("personal training class") || lower.contains("personal training course") {
            return "personaltraining"
        }
        // healthcoaching — positioned BEFORE fitness so NBC-HWC/NBHWC cert prep and wellness
        // coaching tasks route here rather than the generic workout/gym fitness pool.
        if lower.contains("health coach") || lower.contains("health coaching")
            || lower.contains("wellness coach") || lower.contains("wellness coaching")
            || word("nbhwc") || lower.contains("nbc-hwc") || lower.contains("nbc hwc")
            || lower.contains("health coaching certification") || lower.contains("wellness coaching certification")
            || lower.contains("health and wellness coaching") || lower.contains("health behavior coaching")
            || lower.contains("behavior change coaching") || lower.contains("health behavior change")
            || lower.contains("lifestyle coaching") && (lower.contains("certif") || lower.contains("exam") || lower.contains("class") || lower.contains("program")) {
            return "healthcoaching"
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
        // dietetictechnology — positioned AFTER nutrition so dietetic-technician-specific terms (DTR, NDTR,
        // dietetic technician program) route here rather than to the general dietitian/nutritionist pool.
        if lower.contains("dietetic technician") || lower.contains("dietetic tech")
            || word("dtr") && (lower.contains("dietetic") || lower.contains("nutrition") || lower.contains("exam") || lower.contains("class") || lower.contains("certification"))
            || word("ndtr") || lower.contains("dietetic technician registered")
            || lower.contains("dietetic technician class") || lower.contains("dietetic technician course")
            || lower.contains("dietetic technician program") || lower.contains("dietetic technician school")
            || lower.contains("dietetic technician exam") || lower.contains("dietetic technician assignment")
            || lower.contains("dietetic technician certification") || lower.contains("dietetic technician registration")
            || lower.contains("dietetic tech program") || lower.contains("dietetic tech class")
            || lower.contains("dietetic aide") && (lower.contains("class") || lower.contains("exam") || lower.contains("certification")) {
            return "dietetictechnology"
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
        // winesommelier — positioned after culinary (shared hospitality/food context) and before
        // cosmetology. Catches wine education, sommelier certification, and viticulture/enology coursework.
        // Bare "drinking wine" or "wine with dinner" never fires (needs educational/professional context).
        if word("sommelier") || lower.contains("sommeliers")
            || word("wset") && (lower.contains("exam") || lower.contains("level") || lower.contains("certification") || lower.contains("certificate") || lower.contains("course") || lower.contains("study"))
            || lower.contains("court of master sommeliers")
            || lower.contains("certified sommelier") || lower.contains("certified wine educator")
            || lower.contains("wine studies") || lower.contains("wine tasting class")
            || lower.contains("wine tasting course") || lower.contains("wine education")
            || lower.contains("wine class") || lower.contains("wine course")
            || lower.contains("wine exam") || lower.contains("wine pairing class")
            || lower.contains("wine pairing course") || lower.contains("wine certification")
            || lower.contains("wine program") && (lower.contains("class") || lower.contains("school") || lower.contains("course") || lower.contains("study"))
            || lower.contains("wine region") && (lower.contains("study") || lower.contains("class") || lower.contains("exam"))
            || word("viticulture") || lower.contains("viticulture class") || lower.contains("viticulture course")
            || word("enology") || word("oenology")
            || lower.contains("enology class") || lower.contains("enology course")
            || lower.contains("oenology class") || lower.contains("oenology course")
            || lower.contains("blind tasting") && (lower.contains("wine") || lower.contains("sommelier"))
            || lower.contains("wine blind tasting") || lower.contains("wine sensory") {
            return "winesommelier"
        }
        // cosmetology — positioned after culinary (both involve hands-on technique training);
        // catches cosmetology school, esthetics, nail tech, barbering, and state board prep.
        if lower.contains("cosmetology school") || lower.contains("cosmetology program")
            || lower.contains("cosmetology class") || lower.contains("cosmetology exam")
            || lower.contains("cosmetology certification") || lower.contains("cosmetology state board")
            || lower.contains("cosmetology board") || lower.contains("cosmetology license")
            || word("cosmetologist") || word("cosmetology")
            || lower.contains("esthetics school") || lower.contains("esthetics program")
            || lower.contains("esthetics class") || lower.contains("esthetics exam")
            || lower.contains("esthetics certification") || lower.contains("esthetics license")
            || word("esthetician") || word("esthetics")
            || lower.contains("nail tech") || lower.contains("nail technician")
            || lower.contains("nail school") || lower.contains("nail program") || lower.contains("nail exam")
            || lower.contains("hair coloring technique") || lower.contains("hair cutting technique")
            || lower.contains("hair styling technique") || lower.contains("hair color class")
            || lower.contains("waxing technique") || lower.contains("waxing class")
            || lower.contains("barbering school") || lower.contains("barbering class")
            || lower.contains("barbering exam") || lower.contains("barber school")
            || lower.contains("barber exam") || lower.contains("barber license")
            || word("nbbi") || lower.contains("nbbi exam")
            || lower.contains("milady textbook") || lower.contains("milady cosmetology") {
            return "cosmetology"
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
        // theatresound — positioned BEFORE musicproduction so FOH mixing, stage sound, live audio,
        // and audio tech program work route here rather than to the DAW/studio recording pool.
        // Bare word("audio") alone is NOT matched (too ambiguous). "mixing" must be qualified.
        if lower.contains("front of house") || lower.contains("foh mixing") || lower.contains("foh engineer")
            || lower.contains("stage sound") || lower.contains("live sound") || lower.contains("live audio")
            || lower.contains("sound design") && (lower.contains("theatre") || lower.contains("theater") || lower.contains("stage") || lower.contains("live") || lower.contains("event"))
            || lower.contains("theatre sound") || lower.contains("theater sound")
            || lower.contains("audio tech") && (lower.contains("degree") || lower.contains("program") || lower.contains("class") || lower.contains("course") || lower.contains("school") || lower.contains("exam"))
            || lower.contains("audio engineering") && (lower.contains("live") || lower.contains("stage") || lower.contains("theatre") || lower.contains("theater") || lower.contains("event"))
            || lower.contains("monitor mix") || lower.contains("monitor engineer")
            || lower.contains("pa system") && lower.contains("sound")
            || lower.contains("sound reinforcement")
            || lower.contains("live event audio") || lower.contains("concert sound")
            || lower.contains("theatrical sound") {
            return "theatresound"
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
        // horsemanship — positioned BEFORE veterinary so equestrian sports, horse training,
        // and FEI/farriery coursework route here rather than to animal-science callouts.
        // Bare word("horse") alone is NOT matched (too short); needs equestrian/riding/training context.
        if lower.contains("equestrian") || lower.contains("equestrian science")
            || lower.contains("equestrian management") || lower.contains("equestrian studies")
            || lower.contains("equestrian program") || lower.contains("equestrian class")
            || lower.contains("equestrian exam") || lower.contains("equestrian assignment")
            || lower.contains("horse training") || lower.contains("horse trainer")
            || lower.contains("horse management") || lower.contains("horsemanship")
            || lower.contains("equine science") || lower.contains("equine management")
            || lower.contains("equine studies") || lower.contains("equine program")
            || lower.contains("equine class") || lower.contains("equine exam")
            || lower.contains("equine nutrition") || lower.contains("equine health") && !lower.contains("vet")
            || word("dressage") || lower.contains("dressage class") || lower.contains("dressage training")
            || lower.contains("show jumping") || lower.contains("showjumping")
            || lower.contains("reining class") || lower.contains("barrel racing") && lower.contains("class")
            || lower.contains("eventing") && lower.contains("horse")
            || word("fei") && (lower.contains("horse") || lower.contains("equestrian") || lower.contains("riding"))
            || lower.contains("horse riding class") || lower.contains("riding lesson")
            || lower.contains("riding program") || lower.contains("riding school")
            || lower.contains("farriery") || lower.contains("farrier") && (lower.contains("class") || lower.contains("exam") || lower.contains("certification") || lower.contains("program"))
            || lower.contains("horseback riding class") || lower.contains("horse care class")
            || lower.contains("stable management") || lower.contains("barn management")
            || lower.contains("horse science class") || lower.contains("horse handling class") {
            return "horsemanship"
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
        // acupuncture — positioned after chiropractic (both are complementary/alternative medicine)
        // and before dentallab/premed so TCM, NCCAOM board prep, and acupuncture school assignments
        // don't fall through to generic premed callouts.
        if word("acupuncture") || word("acupuncturist") || word("acupuncturists")
            || lower.contains("traditional chinese medicine") || lower.contains("tcm medicine")
            || lower.contains("tcm class") || lower.contains("tcm course") || lower.contains("tcm exam")
            || lower.contains("tcm program") || lower.contains("tcm school")
            || lower.contains("acupuncture school") || lower.contains("acupuncture program")
            || lower.contains("acupuncture class") || lower.contains("acupuncture exam")
            || lower.contains("acupuncture certification") || lower.contains("acupuncture license")
            || lower.contains("acupuncture board") || lower.contains("acupuncture rotation")
            || word("nccaom") || lower.contains("nccaom exam") || lower.contains("nccaom board")
            || lower.contains("oriental medicine") || lower.contains("oriental medicine school")
            || lower.contains("acupuncture points") || lower.contains("acupoints")
            || lower.contains("meridian theory") || lower.contains("meridian system")
            || lower.contains("herbal formula") || lower.contains("herbal medicine class")
            || lower.contains("chinese herbal") || lower.contains("chinese medicine")
            || word("moxibustion") || lower.contains("tuina") {
            return "acupuncture"
        }
        // podiatry — positioned after acupuncture and before dentallab so DPM programs,
        // APMLE board prep, and foot/ankle surgery coursework route here.
        if word("podiatry") || word("podiatrist") || word("podiatrists")
            || lower.contains("podiatric medicine") || lower.contains("podiatric surgery")
            || lower.contains("podiatric school") || lower.contains("podiatric program")
            || lower.contains("podiatric class") || lower.contains("podiatric exam")
            || lower.contains("podiatry school") || lower.contains("podiatry program")
            || lower.contains("podiatry class") || lower.contains("podiatry exam")
            || lower.contains("dpm program") || lower.contains("dpm degree")
            || word("apmle") || lower.contains("apmle exam") || lower.contains("apmle board")
            || lower.contains("foot and ankle") && (lower.contains("surgery") || lower.contains("class") || lower.contains("clinic"))
            || lower.contains("podiatric surgery class") || lower.contains("cpme")
            || word("apma") && lower.contains("podiat") {
            return "podiatry"
        }
        // dentallab — positioned BEFORE dentalassisting so dental lab tech, ceramist, and
        // crown-and-bridge fabrication tasks don't fall through to the dental assistant pool.
        if lower.contains("dental lab") || lower.contains("dental laboratory")
            || lower.contains("dental lab tech") || lower.contains("dental laboratory technician")
            || word("nbdale") || lower.contains("nbdale exam")
            || word("ceramist") || lower.contains("dental ceramics") || lower.contains("dental ceramic")
            || lower.contains("crown and bridge") || lower.contains("crown & bridge")
            || lower.contains("denture technology") || lower.contains("denture tech")
            || lower.contains("prosthodontic lab") || lower.contains("prosthodontics lab")
            || lower.contains("removable prosthodontics") && lower.contains("lab")
            || lower.contains("dental prosthetics lab") || lower.contains("dental prosthetics program")
            || lower.contains("dental wax up") || lower.contains("wax up") && lower.contains("dental")
            || word("nadl") || lower.contains("dental lab program") || lower.contains("dental lab class")
            || lower.contains("dental lab exam") || lower.contains("dental lab notes") {
            return "dentallab"
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
        // dentalpublichealth — positioned AFTER dentalassisting and BEFORE dentalhygiene so
        // oral-health-policy, community-dentistry, and dental-epidemiology coursework routes
        // here rather than to the clinical hygiene pool. "dental" terms without a public-
        // health context still fall through to dentalhygiene or dental below.
        if lower.contains("dental public health") || lower.contains("public health dentistry")
            || lower.contains("community dentistry") || lower.contains("community dental") && (lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("clinic") || lower.contains("assignment"))
            || lower.contains("oral health policy") || lower.contains("oral health disparities")
            || lower.contains("oral health advocacy") || lower.contains("oral health equity")
            || lower.contains("dental epidemiology") || lower.contains("population oral health")
            || lower.contains("community oral health") && (lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("assignment"))
            || lower.contains("oral health program") && (lower.contains("class") || lower.contains("course") || lower.contains("planning") || lower.contains("exam"))
            || lower.contains("dental public health class") || lower.contains("dental public health course")
            || lower.contains("dental public health exam") || lower.contains("dental public health specialty")
            || lower.contains("dental public health residency")
            || word("aaphd") || lower.contains("aaphd exam") || lower.contains("aaphd certification") {
            return "dentalpublichealth"
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
        // oralsurgery — positioned BEFORE dental so OMFS residency, orthognathic surgery,
        // and impacted-teeth/jaw-surgery study tasks get a dedicated pool.
        // "oral surgery" and "oral surgeon" removed from the dental branch below.
        if lower.contains("oral surgery") || lower.contains("oral surgeon")
            || lower.contains("oral surgeons")
            || lower.contains("oral and maxillofacial") || lower.contains("oral & maxillofacial")
            || word("omfs")
            || lower.contains("orthognathic surgery") || lower.contains("jaw surgery")
            || lower.contains("dental surgery") || lower.contains("dental surgeon")
            || lower.contains("surgical dentistry") || lower.contains("dentoalveolar surgery")
            || lower.contains("impacted wisdom") || lower.contains("wisdom tooth surgery")
            || lower.contains("wisdom teeth removal") || lower.contains("tooth extraction class")
            || lower.contains("implant surgery class") || lower.contains("dental implant surgery")
            || lower.contains("oral surgery class") || lower.contains("oral surgery course")
            || lower.contains("oral surgery exam") || lower.contains("oral surgery program")
            || lower.contains("oral surgery residency") || lower.contains("oral surgery rotation")
            || lower.contains("maxillofacial") {
            return "oralsurgery"
        }
        // dental — positioned before premed so dental-school-specific terms (NBDE, DDS/DMD,
        // perio, ortho, endodontics, dental boards) don't fall through to generic premed callouts.
        // "dental hygiene"/"dental hygienist" now owned by the dentalhygiene branch above.
        // "oral surgery"/"oral surgeon" now owned by the oralsurgery branch above.
        if word("dds") || word("dmd") || lower.contains("dental school")
            || lower.contains("dental board") || lower.contains("dental boards")
            || lower.contains("nbde") || lower.contains("inbde")
            || word("periodontology") || word("periodontics") || word("periodontal")
            || word("orthodontics") || word("orthodontist")
            || word("endodontics") || word("endodontist") || word("root canal")
            || word("prosthodontics") || word("prosthodontist")
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
        // naturopathicmedicine — positioned BEFORE integrativemedicine so ND programs,
        // NPLEX exam prep, and botanical/herbal medicine coursework route to a dedicated pool
        // rather than the broader integrative-medicine messages.
        if lower.contains("naturopathic medicine") || lower.contains("naturopathic doctor")
            || lower.contains("naturopathic physician") || lower.contains("naturopathic school")
            || lower.contains("naturopathic program") || lower.contains("naturopathic class")
            || lower.contains("naturopathic course") || lower.contains("naturopathic exam")
            || lower.contains("naturopathic rotation") || lower.contains("naturopathic clinical")
            || lower.contains("naturopathic internship") || lower.contains("naturopathic residency")
            || lower.contains("naturopathic notes") || lower.contains("naturopathic assignment")
            || word("nd") && (lower.contains("naturo") || lower.contains("naturopathic"))
            || word("nplex") || lower.contains("nplex exam") || lower.contains("nplex prep")
            || lower.contains("botanical medicine") || lower.contains("botanical medicine class")
            || lower.contains("botanical medicine course") || lower.contains("botanical medicine exam")
            || lower.contains("naturopathic botany") || lower.contains("medicinal herbs class")
            || lower.contains("herbal medicine class") || lower.contains("herbal medicine course")
            || lower.contains("herbal medicine exam") || lower.contains("homeopathy class")
            || lower.contains("homeopathy course") || lower.contains("homeopathy exam")
            || lower.contains("hydrotherapy class") || lower.contains("physical medicine naturo")
            || lower.contains("counseling naturo") && lower.contains("class")
            || lower.contains("naturopathic oncology") || lower.contains("naturopathic cardiology")
            || lower.contains("bastyr") || lower.contains("national university natural medicine")
            || lower.contains("scnm") || lower.contains("ncnm")
            || lower.contains("cnm naturo") || word("aanp") && lower.contains("naturo") {
            return "naturopathicmedicine"
        }
        // integrativemedicine — positioned AFTER pharmacy (shared pharmacology/therapeutics
        // context) and BEFORE medicalbilling. Catches integrative/functional medicine specialty
        // coursework, CAM therapies, and mind-body medicine.
        // Bare word("holistic") is NOT matched (too generic in non-clinical contexts).
        if lower.contains("integrative medicine") || lower.contains("integrative health")
            || lower.contains("functional medicine")
            || lower.contains("holistic medicine")
            || lower.contains("complementary and alternative medicine")
            || lower.contains("complementary medicine") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("program"))
            || lower.contains("alternative medicine") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("program"))
            || lower.contains("cam therapies") || lower.contains("cam course") || lower.contains("cam class")
            || lower.contains("cam program") || lower.contains("cam exam") || lower.contains("cam module")
            || lower.contains("naturopathic medicine") || lower.contains("naturopathic doctor")
            || lower.contains("naturopath") && (lower.contains("class") || lower.contains("course") || lower.contains("school") || lower.contains("program") || lower.contains("exam") || lower.contains("board") || lower.contains("nd "))
            || lower.contains("mind-body medicine") || lower.contains("mind body medicine")
            || word("abihm") || lower.contains("abihm board") || lower.contains("abihm certification")
            || lower.contains("integrative medicine class") || lower.contains("integrative medicine course")
            || lower.contains("integrative medicine exam") || lower.contains("integrative medicine program")
            || lower.contains("integrative health class") || lower.contains("integrative health course")
            || lower.contains("integrative health program") || lower.contains("integrative health certification")
            || lower.contains("functional medicine class") || lower.contains("functional medicine course")
            || lower.contains("functional medicine exam") || lower.contains("functional medicine program")
            || lower.contains("holistic health class") || lower.contains("holistic health program")
            || lower.contains("holistic health course") || lower.contains("holistic health certification") {
            return "integrativemedicine"
        }
        // medicalbilling — positioned after pharmacy and before molecularbiology/premed so
        // CPT codes, ICD-10, CPC exam, and medical coding tasks route here, not to premed/nursing pools.
        if lower.contains("medical billing") || lower.contains("medical coding")
            || lower.contains("medical biller") || lower.contains("medical coder")
            || lower.contains("medical billers") || lower.contains("medical coders")
            || lower.contains("cpt code") || lower.contains("cpt codes") || lower.contains("cpt coding")
            || lower.contains("icd-10") || lower.contains("icd 10") || lower.contains("icd-11")
            || lower.contains("cpc exam") || lower.contains("cpc certification") || lower.contains("cpc prep")
            || word("aapc") || lower.contains("aapc exam") || lower.contains("aapc certification")
            || lower.contains("hcpcs code") || lower.contains("hcpcs codes")
            || lower.contains("revenue cycle management") || lower.contains("revenue cycle")
            && lower.contains("billing")
            || lower.contains("healthcare billing") || lower.contains("health insurance billing")
            || lower.contains("medical claim") || lower.contains("medical claims")
            || lower.contains("claim submission") || lower.contains("claims submission")
            || lower.contains("ehr coding") || lower.contains("electronic health record coding")
            || lower.contains("health information management")
            || lower.contains("him program") || lower.contains("him class") || lower.contains("him exam")
            || lower.contains("medical terminology coding")
            || lower.contains("billing and coding") || lower.contains("coding and billing") {
            return "medicalbilling"
        }
        // medicallabscience — positioned AFTER medicalbilling and BEFORE molecularbiology so
        // ASCP board prep, blood bank, hematology lab, and clinical laboratory science route here.
        // "medical billing/coding" stays in medicalbilling above; medicallabscience claims bench-lab terms.
        if lower.contains("medical laboratory science") || lower.contains("medical laboratory scientist")
            || lower.contains("medical lab scientist") || lower.contains("clinical laboratory science")
            || lower.contains("clinical lab science") || lower.contains("clinical laboratory scientist")
            || word("mls") && (lower.contains("exam") || lower.contains("certification") || lower.contains("program") || lower.contains("class") || lower.contains("degree") || lower.contains("lab"))
            || word("mlt") && (lower.contains("exam") || lower.contains("certification") || lower.contains("program") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("ascp board") || lower.contains("ascp exam") || lower.contains("ascp certification")
            || lower.contains("blood bank") && (lower.contains("class") || lower.contains("exam") || lower.contains("lab") || lower.contains("course"))
            || lower.contains("hematology lab") || lower.contains("hematology class") || lower.contains("hematology course")
            || lower.contains("microbiology lab") && lower.contains("clinical")
            || lower.contains("urinalysis lab") || lower.contains("urinalysis course") || lower.contains("urinalysis class")
            || lower.contains("complete blood count") || lower.contains("differential count")
            || lower.contains("clinical chemistry lab") || lower.contains("clinical chemistry course")
            || lower.contains("cls exam") || lower.contains("medical lab tech")
            || lower.contains("clinical lab tech") || lower.contains("medical lab program")
            || lower.contains("medical lab class") || lower.contains("clinical laboratory tech") {
            return "medicallabscience"
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
        // geneticcounseling — positioned AFTER molecularbiology (shares genomics vocabulary) and
        // BEFORE radiologictechnology. Catches ABGC/CGC board prep, prenatal genetics,
        // hereditary cancer counseling, and genomic counseling coursework.
        // Bare "genetics" stays in studying for generic academic use.
        if lower.contains("genetic counseling") || lower.contains("genetic counselor")
            || lower.contains("genetic counselors")
            || word("abgc") || lower.contains("abgc exam") || lower.contains("abgc board")
            || lower.contains("cgc exam") || lower.contains("cgc certification") || lower.contains("cgc board")
            || lower.contains("certified genetic counselor")
            || lower.contains("prenatal genetic counseling") || lower.contains("prenatal genetics")
            || lower.contains("hereditary cancer counseling") || lower.contains("hereditary cancer genetics")
            || lower.contains("hereditary cancer risk") && (lower.contains("counseling") || lower.contains("class") || lower.contains("course"))
            || lower.contains("genomic counseling") || lower.contains("genomic counselor")
            || lower.contains("genetics clinic") && (lower.contains("class") || lower.contains("rotation") || lower.contains("course") || lower.contains("assignment"))
            || lower.contains("genetic counseling program") || lower.contains("genetic counseling class")
            || lower.contains("genetic counseling school") || lower.contains("genetic counseling exam")
            || lower.contains("genetic counseling rotation") || lower.contains("genetic counseling clerkship")
            || lower.contains("variant of uncertain significance") && (lower.contains("class") || lower.contains("assignment") || lower.contains("report"))
            || lower.contains("brca counseling") || lower.contains("cancer genetics counseling")
            || lower.contains("genetic risk assessment") && (lower.contains("class") || lower.contains("course") || lower.contains("counseling")) {
            return "geneticcounseling"
        }
        // radiologictechnology — positioned AFTER molecularbiology and BEFORE healthcareadmin so
        // ARRT exam prep, radiographic positioning, and diagnostic imaging coursework route here.
        // Bare "radiology" or "x-ray" stays in studying for generic mentions; compound program terms fire here.
        if lower.contains("radiologic technology") || lower.contains("radiologic technologist")
            || lower.contains("radiologic technologists") || lower.contains("radiographer")
            || lower.contains("radiographers") || lower.contains("radiology tech")
            || lower.contains("radiology technician") || lower.contains("x-ray tech")
            || lower.contains("x-ray technician") || lower.contains("xray tech")
            || lower.contains("ct tech") || lower.contains("ct technician")
            || lower.contains("mri tech") || lower.contains("mri technician")
            || word("arrt") || lower.contains("arrt exam") || lower.contains("arrt certification")
            || lower.contains("radiographic positioning") || lower.contains("fluoroscopy")
            || lower.contains("computed tomography lab") || lower.contains("computed tomography class")
            || lower.contains("computed tomography course")
            || lower.contains("diagnostic imaging class") || lower.contains("diagnostic imaging course")
            || lower.contains("diagnostic imaging exam") || lower.contains("diagnostic imaging program")
            || lower.contains("radiologic science") || lower.contains("radiography class")
            || lower.contains("radiography program") || lower.contains("radiography school")
            || lower.contains("radiography exam") || lower.contains("radiography certification")
            || lower.contains("medical imaging class") || lower.contains("medical imaging course")
            || lower.contains("interventional radiology") && (lower.contains("class") || lower.contains("rotation") || lower.contains("exam")) {
            return "radiologictechnology"
        }
        // nuclearmedtech — positioned AFTER radiologictechnology and BEFORE healthcareadmin so
        // nuclear medicine technologist boards, PET/SPECT imaging, and radiopharmaceuticals
        // coursework routes here rather than to the general imaging pool.
        if lower.contains("nuclear medicine technology") || lower.contains("nuclear medicine technologist")
            || lower.contains("nuclear medicine tech") || lower.contains("nuclear medicine school")
            || lower.contains("nuclear medicine program") || lower.contains("nuclear medicine class")
            || lower.contains("nuclear medicine exam") || lower.contains("nuclear medicine certification")
            || lower.contains("nuclear medicine rotation") || lower.contains("nuclear medicine course")
            || word("cnmt") || word("nmt")
            || lower.contains("arrt nuclear") || lower.contains("nuclear medicine board")
            || lower.contains("pet scan tech") || lower.contains("pet technologist")
            || lower.contains("pet imaging class") || lower.contains("pet imaging course")
            || lower.contains("spect scan technologist") || lower.contains("spect imaging class")
            || lower.contains("radiopharmaceuticals class") || lower.contains("radiopharmaceuticals course")
            || lower.contains("radiopharmacy class") || lower.contains("radiopharmacy course")
            || lower.contains("nuclear cardiology class") || lower.contains("nuclear cardiology course")
            || lower.contains("gamma camera") && (lower.contains("class") || lower.contains("exam") || lower.contains("study"))
            || lower.contains("radiation dosimetry class") || lower.contains("radiation dosimetry course")
            || lower.contains("radioisotope therapy") || lower.contains("radionuclide therapy") {
            return "nuclearmedtech"
        }
        // sonography — positioned AFTER nuclearmedtech and BEFORE healthcareadmin so
        // diagnostic medical sonography, ARDMS registry prep, and ultrasound technology
        // coursework routes here rather than to the general imaging pool.
        if lower.contains("diagnostic medical sonography") || lower.contains("diagnostic sonography")
            || lower.contains("sonography school") || lower.contains("sonography program")
            || lower.contains("sonography class") || lower.contains("sonography exam")
            || lower.contains("sonography certification") || lower.contains("sonography rotation")
            || lower.contains("sonography course") || word("sonographer") || word("sonographers")
            || word("ardms") || lower.contains("ardms registry") || lower.contains("ardms exam")
            || lower.contains("ultrasound technologist") || lower.contains("ultrasound technology class")
            || lower.contains("ultrasound technology course") || lower.contains("ultrasound technology exam")
            || lower.contains("abdominal sonography") || lower.contains("obstetric sonography")
            || lower.contains("ob sonography") || lower.contains("vascular sonography")
            || lower.contains("ultrasound physics class") || lower.contains("ultrasound physics course")
            || lower.contains("sonography scanning") || lower.contains("scanning technique class") {
            return "sonography"
        }
        // cardiovasculartech — positioned AFTER sonography and BEFORE healthcareadmin so
        // cardiac cath lab, echocardiography, and CCI/RCIS board prep routes here.
        if lower.contains("cardiovascular technology") || lower.contains("cardiovascular technologist")
            || lower.contains("cardiovascular tech school") || lower.contains("cardiovascular tech program")
            || lower.contains("cardiovascular tech class") || lower.contains("cardiovascular tech exam")
            || lower.contains("cardiovascular tech course") || lower.contains("cardiovascular tech rotation")
            || word("rcis") || word("rces") || lower.contains("cci board") || lower.contains("cci exam")
            || lower.contains("cardiac catheterization class") || lower.contains("cardiac catheterization course")
            || lower.contains("cardiac cath lab class") || lower.contains("cardiac cath lab course")
            || lower.contains("echocardiography class") || lower.contains("echocardiography course")
            || lower.contains("echocardiography exam") || lower.contains("echocardiography program")
            || lower.contains("ekg technician class") || lower.contains("ekg technician course")
            || lower.contains("ekg technician exam") || lower.contains("ekg certification class")
            || lower.contains("holter monitor class") || lower.contains("cardiac monitoring class")
            || lower.contains("stress test technologist") || lower.contains("vascular technology class")
            || lower.contains("vascular technology course") || lower.contains("vascular technology exam") {
            return "cardiovasculartech"
        }
        // surgicaltech — positioned AFTER cardiovasculartech and BEFORE healthcareadmin so
        // surgical technology, CST exam, and sterile field technique routes here.
        if lower.contains("surgical technology") || lower.contains("surgical technologist")
            || lower.contains("surgical technician") || lower.contains("surgical tech school")
            || lower.contains("surgical tech program") || lower.contains("surgical tech class")
            || lower.contains("surgical tech exam") || lower.contains("surgical tech course")
            || lower.contains("surgical tech certification") || lower.contains("surgical tech rotation")
            || word("nbstsa") || lower.contains("cst exam") || lower.contains("cst certification")
            || lower.contains("scrub tech") || lower.contains("scrub technician")
            || lower.contains("surgical instrumentation class") || lower.contains("surgical instrumentation course")
            || lower.contains("surgical instrumentation exam") || lower.contains("sterile field technique")
            || lower.contains("sterile technique class") || lower.contains("surgical case study class")
            || lower.contains("perioperative class") || lower.contains("perioperative course")
            || lower.contains("perioperative exam") {
            return "surgicaltech"
        }
        // polysomnography — positioned after surgicaltech and before healthcareadmin so sleep
        // technology, RPSGT board prep, and PSG lab coursework route here.
        // "sleep study" without educational context never fires (bare study = studying branch).
        if lower.contains("polysomnography") || lower.contains("polysomnographer")
            || word("rpsgt") || word("ccsh")
            || lower.contains("sleep tech") && (lower.contains("class") || lower.contains("program") || lower.contains("school") || lower.contains("exam") || lower.contains("certification"))
            || lower.contains("sleep technologist") || lower.contains("sleep technology class")
            || lower.contains("sleep technology program") || lower.contains("sleep technology exam")
            || lower.contains("psg lab") || lower.contains("sleep scoring")
            || lower.contains("sleep study") && (lower.contains("class") || lower.contains("program") || lower.contains("technologist") || lower.contains("scoring") || lower.contains("polysomnography"))
            || lower.contains("sleep disorders class") || lower.contains("sleep medicine class")
            || lower.contains("sleep medicine course") || lower.contains("sleep medicine program")
            || lower.contains("actigraphy class") || lower.contains("actigraphy course")
            || lower.contains("polysomnography school") || lower.contains("polysomnography program")
            || lower.contains("polysomnography class") || lower.contains("polysomnography exam") {
            return "polysomnography"
        }
        // diagnosticphysics — positioned after polysomnography and before healthcareadmin so
        // diagnostic medical physics, health physics, and ABR board prep route here.
        // "radiation safety" without educational context never fires; bare "physics" alone never fires.
        if lower.contains("diagnostic medical physics") || lower.contains("health physicist")
            || lower.contains("health physics class") || lower.contains("health physics course")
            || lower.contains("health physics program") || lower.contains("health physics exam")
            || lower.contains("health physics certification") || lower.contains("health physics board")
            || lower.contains("medical physics class") || lower.contains("medical physics course")
            || lower.contains("medical physics program") || lower.contains("medical physics exam")
            || lower.contains("medical physics assignment") || lower.contains("medical physics board")
            || lower.contains("medical physicist") || lower.contains("therapeutic medical physics")
            || lower.contains("radiation physics class") || lower.contains("radiation physics course")
            || lower.contains("dosimetry class") || lower.contains("dosimetry course")
            || lower.contains("dosimetry exam") || lower.contains("medical dosimetry")
            || lower.contains("abr physics") || lower.contains("abr exam") && lower.contains("physics")
            || lower.contains("radiation protection class") || lower.contains("radiation protection course")
            || lower.contains("radiation safety class") || lower.contains("radiation safety certification")
            || lower.contains("diagnostic imaging physics") || lower.contains("nuclear physics class") && lower.contains("medical") {
            return "diagnosticphysics"
        }
        // perfusiontechnology — positioned after diagnosticphysics and before healthcareadmin so
        // cardiovascular perfusion, CCP board, and bypass circuit coursework route here.
        // "CCP" alone never fires (too ambiguous); requires perfusion context.
        if lower.contains("perfusion technology") || lower.contains("perfusion technologist")
            || lower.contains("cardiovascular perfusionist") || lower.contains("cardiovascular perfusion")
            || word("perfusionist") || lower.contains("perfusion class") || lower.contains("perfusion course")
            || lower.contains("perfusion school") || lower.contains("perfusion program")
            || lower.contains("perfusion exam") || lower.contains("perfusion certification")
            || lower.contains("perfusion assignment") || lower.contains("perfusion notes")
            || word("amsect") || lower.contains("pbse exam") || lower.contains("pbse board")
            || lower.contains("heart-lung machine") || lower.contains("heart lung machine")
            || lower.contains("cardiopulmonary bypass class") || lower.contains("cardiopulmonary bypass course")
            || lower.contains("cardiopulmonary bypass program") || lower.contains("cardiopulmonary bypass exam")
            || lower.contains("extracorporeal circulation class") || lower.contains("extracorporeal bypass class")
            || lower.contains("bypass pump class") || lower.contains("bypass circuit class")
            || lower.contains("ccp board") && lower.contains("perfusion") {
            return "perfusiontechnology"
        }
        // ophthalmic — positioned after perfusiontechnology and before healthcareadmin so
        // ophthalmic medical technology, JCAHPO/COMT/COT/COA board prep route here.
        // "COT" / "COA" alone never fire; require ophthalmic context.
        if lower.contains("ophthalmic medical technology") || lower.contains("ophthalmic medical technologist")
            || lower.contains("ophthalmic technician") || lower.contains("ophthalmic technologist")
            || lower.contains("ophthalmic assistant") || lower.contains("ophthalmic class")
            || lower.contains("ophthalmic course") || lower.contains("ophthalmic program")
            || lower.contains("ophthalmic exam") || lower.contains("ophthalmic assignment")
            || lower.contains("ophthalmic school") || word("jcahpo")
            || word("comt") && lower.contains("ophthalmic")
            || lower.contains("cot exam") && lower.contains("ophthalmic")
            || lower.contains("coa exam") && lower.contains("ophthalmic")
            || lower.contains("ocular motility") && lower.contains("class")
            || lower.contains("slit lamp class") || lower.contains("slit lamp exam")
            || lower.contains("visual field testing class") || lower.contains("tonometry class")
            || lower.contains("refractometry class") || lower.contains("ophthalmology technician class")
            || lower.contains("ophthalmology technician program") || lower.contains("ophthalmology tech class") {
            return "ophthalmic"
        }
        // centralsterile — positioned after ophthalmic and before healthcareadmin so
        // central sterile processing, CBSPD, CRCST, and IAHCSMM board prep route here.
        // "sterile field" stays in surgicaltech (fires earlier); "infection control" alone never fires.
        if lower.contains("central sterile processing") || lower.contains("sterile processing class")
            || lower.contains("sterile processing course") || lower.contains("sterile processing program")
            || lower.contains("sterile processing school") || lower.contains("sterile processing exam")
            || lower.contains("sterile processing certification") || lower.contains("sterile processing assignment")
            || lower.contains("sterile processing technician") || lower.contains("sterile processing tech")
            || word("cbspd") || word("crcst") || word("iahcsmm")
            || lower.contains("instrument decontamination class") || lower.contains("instrument decontamination course")
            || lower.contains("autoclave class") || lower.contains("autoclave exam")
            || lower.contains("sterilization class") || lower.contains("sterilization course")
            || lower.contains("sterilization exam") || lower.contains("sterilization certification")
            || lower.contains("central supply class") || lower.contains("central supply certification")
            || lower.contains("decontamination class") && lower.contains("sterile")
            || lower.contains("tray assembly class") || lower.contains("instrument tray class") {
            return "centralsterile"
        }
        // healthcareadmin — positioned after molecularbiology and before premed so healthcare
        // administration, health informatics, and HIM certification prep route here.
        // "health policy" stays in the policy branch; "public health" stays in publicheath.
        if lower.contains("healthcare administration") || lower.contains("hospital administration")
            || lower.contains("health administration") || lower.contains("healthcare management")
            || lower.contains("health information management") || lower.contains("health information technology")
            || lower.contains("health informatics") || lower.contains("clinical informatics")
            || word("rhia") || word("rhit") || word("cahims") || word("cahiim")
            || lower.contains("electronic health record") || lower.contains("ehr implementation")
            || lower.contains("ehr training") || lower.contains("ehr certification")
            || lower.contains("health it class") || lower.contains("health it course")
            || lower.contains("health information system") || lower.contains("health information systems")
            || lower.contains("mha degree") || lower.contains("mha program") || lower.contains("mha class")
            || lower.contains("healthcare finance") || lower.contains("healthcare operations")
            || lower.contains("hospital management") || lower.contains("clinic management")
            || lower.contains("revenue cycle management class") || lower.contains("revenue cycle management course")
            || lower.contains("medical records management") || lower.contains("medical records class")
            || lower.contains("hipaa compliance class") || lower.contains("hipaa certification") {
            return "healthcareadmin"
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
        // opticianry — positioned after optometry so dispensing-optician-specific terms (ABO/NCLE exam,
        // NOCE, optical dispensing, spectacle lens fitting) route here. "slit lamp" and "contact lens"
        // alone stay in optometry (fires earlier); opticianry requires school/exam/program context.
        if lower.contains("dispensing optician") || lower.contains("dispensing opticians")
            || word("opticianry") || lower.contains("opticianry school") || lower.contains("opticianry program")
            || lower.contains("opticianry class") || lower.contains("opticianry exam")
            || lower.contains("opticianry assignment") || lower.contains("opticianry certification")
            || lower.contains("abo certification") || lower.contains("abo exam") || lower.contains("abo-ncle")
            || lower.contains("ncle exam") || lower.contains("ncle certification")
            || lower.contains("noce exam") || lower.contains("noce certification")
            || lower.contains("optical dispensing") || lower.contains("spectacle lens dispensing")
            || lower.contains("eyeglass dispensing") || lower.contains("frame selection class")
            || lower.contains("optician school") || lower.contains("optician program")
            || lower.contains("optician class") || lower.contains("optician exam")
            || lower.contains("optician certification") || lower.contains("optician license")
            || lower.contains("contact lens fitting") && lower.contains("optician") {
            return "opticianry"
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
        // nursinginformatics — positioned BEFORE nursing so "nursing informatics", CNIO, and
        // clinical informatics nursing context route here instead of the general nursing pool.
        // "health informatics" alone is caught by healthcareadmin above; this branch requires
        // explicit nursing/clinical nursing informatics context.
        if lower.contains("nursing informatics")
            || lower.contains("nursing information systems")
            || lower.contains("nursing health informatics")
            || word("cnio")
            || lower.contains("nursing ehr") || lower.contains("nursing electronic health record")
            || lower.contains("nursing clinical informatics")
            || lower.contains("clinical informatics") && lower.contains("nurs")
            || lower.contains("health informatics") && lower.contains("nurs")
            || lower.contains("nursing information technology")
            || lower.contains("nursing informatics class") || lower.contains("nursing informatics course")
            || lower.contains("nursing informatics program") || lower.contains("nursing informatics exam")
            || lower.contains("nursing technology class") || lower.contains("nursing technology course")
            || lower.contains("nursing informatics assignment") || lower.contains("nursing informatics certification") {
            return "nursinginformatics"
        }
        // midwiferyassisting — positioned BEFORE midwifery so doula certifications (DONA, CAPPA)
        // and birth/postpartum doula coursework route here, separate from CNM degree work.
        if lower.contains("doula") || lower.contains("birth doula") || lower.contains("postpartum doula")
            || lower.contains("labor doula") || lower.contains("antepartum doula")
            || lower.contains("dona certification") || lower.contains("dona exam") || lower.contains("dona training")
            || lower.contains("cappa certification") || lower.contains("cappa exam")
            || lower.contains("badt exam") || lower.contains("doula training")
            || lower.contains("doula certification") || lower.contains("doula program")
            || lower.contains("doula class") || lower.contains("doula course") || lower.contains("doula exam")
            || lower.contains("doula school") || lower.contains("doula assignment")
            || lower.contains("childbirth educator") && (lower.contains("cert") || lower.contains("class") || lower.contains("exam"))
            || lower.contains("birth support") && (lower.contains("cert") || lower.contains("class")) {
            return "midwiferyassisting"
        }
        // midwifery — positioned BEFORE nursing so CNM school, AMCB exam prep, birth plan
        // writing, and prenatal/postpartum charting route to a dedicated midwifery pool rather
        // than the broader nursing callouts. Bare word("birth") is NOT matched (too generic).
        if lower.contains("midwifery") || lower.contains("midwife") || lower.contains("midwives")
            || word("cnm") && (lower.contains("school") || lower.contains("program") || lower.contains("exam") || lower.contains("class") || lower.contains("course") || lower.contains("certification") || lower.contains("credential") || lower.contains("clinical") || lower.contains("rotation") || lower.contains("midwif"))
            || word("amcb") || lower.contains("amcb exam") || lower.contains("amcb certification")
            || lower.contains("certified nurse midwife") || lower.contains("certified nurse-midwife")
            || lower.contains("licensed midwife") || lower.contains("direct-entry midwife")
            || lower.contains("midwifery school") || lower.contains("midwifery program")
            || lower.contains("midwifery class") || lower.contains("midwifery course")
            || lower.contains("midwifery exam") || lower.contains("midwifery rotation")
            || lower.contains("midwifery clinical") || lower.contains("midwifery internship")
            || lower.contains("midwifery notes") || lower.contains("midwifery assignment")
            || lower.contains("birth plan") || lower.contains("birth plans")
            || lower.contains("prenatal charting") || lower.contains("postpartum charting")
            || lower.contains("prenatal notes") || lower.contains("postpartum notes")
            || lower.contains("labor and delivery notes") || lower.contains("l&d notes")
            || lower.contains("antepartum notes") || lower.contains("intrapartum notes")
            || lower.contains("newborn assessment notes") || lower.contains("newborn notes")
            || lower.contains("home birth documentation") || lower.contains("birth center notes")
            || lower.contains("obstetric notes") && lower.contains("midwif")
            || lower.contains("midwifery care") && lower.contains("plan") {
            return "midwifery"
        }
        // forensicnursing — positioned BEFORE nursing so SANE exam, sexual assault nurse examiner
        // credentials, and forensic nursing notes don't match word("nursing") in the nursing branch.
        if lower.contains("forensic nursing") || lower.contains("forensic nurse")
            || lower.contains("sane exam") || lower.contains("sane certification") || lower.contains("sane program")
            || lower.contains("sexual assault nurse") || lower.contains("sexual assault examiner")
            || lower.contains("forensic nursing notes") || lower.contains("forensic nursing school")
            || lower.contains("forensic nursing program") || lower.contains("forensic nursing class")
            || lower.contains("forensic nursing course") || lower.contains("forensic nursing exam")
            || lower.contains("afn credential") || lower.contains("anes certification")
            || lower.contains("nurse examiner") && (lower.contains("forensic") || lower.contains("assault"))
            || lower.contains("strangulation documentation") && lower.contains("nurse")
            || lower.contains("injury documentation") && lower.contains("forensic") {
            return "forensicnursing"
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
        // musictherapy — positioned BEFORE arttherapy, socialwork, and therapy so music therapy,
        // MT-BC board prep, and neurologic music therapy route here rather than to musictheory or
        // generic therapy callouts. "music theory class" fires musictheory much earlier.
        if lower.contains("music therapy") || lower.contains("music therapist")
            || lower.contains("music therapists")
            || word("mtbc") || lower.contains("mt-bc")
                && (lower.contains("board") || lower.contains("exam") || lower.contains("certification") || lower.contains("credential"))
            || word("amta") && (lower.contains("music") || lower.contains("therapy"))
            || lower.contains("music therapy class") || lower.contains("music therapy course")
            || lower.contains("music therapy program") || lower.contains("music therapy school")
            || lower.contains("music therapy exam") || lower.contains("music therapy assignment")
            || lower.contains("music therapy session") || lower.contains("music therapy notes")
            || lower.contains("music therapy treatment plan") || lower.contains("music therapy internship")
            || lower.contains("neurologic music therapy") || lower.contains("nordoff-robbins")
            || lower.contains("receptive music therapy") || lower.contains("active music therapy")
            || lower.contains("music therapy clinical") || lower.contains("music therapy certification")
            || lower.contains("board-certified music therapist") {
            return "musictherapy"
        }
        // dancetherapy — positioned AFTER musictherapy and BEFORE arttherapy so dance/movement therapy,
        // DMT credential, and ADTA board prep route here. Bare "dance class"/"dance performance" fires
        // the performingarts branch much earlier; this branch requires explicit therapy/clinical context.
        if lower.contains("dance therapy") || lower.contains("dance therapist")
            || lower.contains("dance therapists")
            || lower.contains("dance/movement therapy") || lower.contains("dance movement therapy")
            || lower.contains("movement therapy") && lower.contains("dance")
            || word("rdmt") || word("admt")
            || word("adta") && (lower.contains("dance") || lower.contains("therapy"))
            || lower.contains("dmt credential") || lower.contains("dmt board") || lower.contains("dmt exam")
            || lower.contains("dance therapy class") || lower.contains("dance therapy course")
            || lower.contains("dance therapy program") || lower.contains("dance therapy school")
            || lower.contains("dance therapy exam") || lower.contains("dance therapy assignment")
            || lower.contains("dance therapy session") || lower.contains("dance therapy notes")
            || lower.contains("dance therapy treatment plan") || lower.contains("dance therapy internship")
            || lower.contains("movement psychotherapy") || lower.contains("choreotherapy") {
            return "dancetherapy"
        }
        // dramatherapy — positioned BEFORE arttherapy so psychodrama, NADT exam prep,
        // and drama therapy session notes route here instead of to generic art-therapy callouts.
        // "drama class" / "drama performance" stays in performingarts/dramaeducation (both fire earlier).
        if lower.contains("drama therapy") || lower.contains("drama therapist")
            || lower.contains("drama therapists")
            || lower.contains("psychodrama") || lower.contains("psychodramatist")
            || lower.contains("psychodrama session") || lower.contains("psychodrama class")
            || lower.contains("sociodrama") || lower.contains("sociodramatist")
            || word("nadt") || lower.contains("nadt exam") || lower.contains("nadt certification")
            || lower.contains("drama therapy class") || lower.contains("drama therapy course")
            || lower.contains("drama therapy program") || lower.contains("drama therapy school")
            || lower.contains("drama therapy exam") || lower.contains("drama therapy assignment")
            || lower.contains("drama therapy session") || lower.contains("drama therapy notes")
            || lower.contains("drama therapy treatment plan") || lower.contains("drama therapy internship")
            || lower.contains("drama-based therapy") || lower.contains("drama based therapy")
            || lower.contains("therapeutic drama") && (lower.contains("class") || lower.contains("session") || lower.contains("therapy") || lower.contains("notes"))
            || lower.contains("playback theatre") && lower.contains("therapy")
            || lower.contains("therapeutic enactment") {
            return "dramatherapy"
        }
        // arttherapy — positioned BEFORE socialwork and therapy so "art therapy", "art therapist",
        // and ATR/ATCB board prep routes here rather than to generic therapy callouts.
        // Bare "art class" / "taking an art class" fires the art/studying branch much earlier.
        if lower.contains("art therapy") || lower.contains("art therapist")
            || lower.contains("art therapists")
            || word("atr") && (lower.contains("board") || lower.contains("credential") || lower.contains("exam") || lower.contains("certification"))
            || word("atcb") || lower.contains("atcb exam") || lower.contains("atcb certification")
            || lower.contains("art therapy class") || lower.contains("art therapy course")
            || lower.contains("art therapy program") || lower.contains("art therapy school")
            || lower.contains("art therapy exam") || lower.contains("art therapy assignment")
            || lower.contains("art therapy session") || lower.contains("art therapy notes")
            || lower.contains("art therapy treatment plan") || lower.contains("art therapy internship")
            || lower.contains("expressive arts therapy") || lower.contains("expressive arts therapist")
            || lower.contains("creative arts therapy") || lower.contains("creative arts therapist")
            || lower.contains("therapeutic art making") || lower.contains("therapeutic art class") {
            return "arttherapy"
        }
        // recreationtherapy — positioned AFTER arttherapy and BEFORE addictioncounseling so therapeutic
        // recreation, CTRS exam prep, and leisure education route here. Bare "recreation class" stays in
        // studying; this branch requires explicit therapeutic/CTRS certification context.
        if lower.contains("recreational therapy") || lower.contains("recreation therapy")
            || lower.contains("recreational therapist") || lower.contains("recreation therapist")
            || lower.contains("therapeutic recreation")
            || word("ctrs") || lower.contains("ctrs exam") || lower.contains("ctrs certification")
            || lower.contains("ctrs board") || lower.contains("nctrc exam")
            || word("atra") && (lower.contains("recreation") || lower.contains("therapy"))
            || lower.contains("recreation therapy class") || lower.contains("recreation therapy course")
            || lower.contains("recreation therapy program") || lower.contains("recreation therapy school")
            || lower.contains("recreation therapy exam") || lower.contains("recreation therapy assignment")
            || lower.contains("recreation therapy notes") || lower.contains("recreation therapy internship")
            || lower.contains("leisure education") || lower.contains("leisure counseling")
            || lower.contains("adaptive recreation") || lower.contains("activity therapy")
            || lower.contains("recreational therapy class") || lower.contains("recreational therapy course")
            || lower.contains("recreational therapy exam") || lower.contains("recreational therapy assignment") {
            return "recreationtherapy"
        }
        // horticulturetherapy — positioned AFTER recreationtherapy and BEFORE addictioncounseling so
        // horticultural therapy, HTR certification, and therapeutic horticulture route here.
        // Bare "gardening" stays in fitness; this branch requires therapeutic/certification context.
        if lower.contains("horticultural therapy") || lower.contains("horticultural therapist")
            || lower.contains("horticulture therapy") || lower.contains("horticulture therapist")
            || lower.contains("therapeutic horticulture")
            || word("htr") && (lower.contains("horticul") || lower.contains("therapy") || lower.contains("certification"))
            || word("ahta") && (lower.contains("horticul") || lower.contains("therapy"))
            || lower.contains("horticultural therapy class") || lower.contains("horticultural therapy course")
            || lower.contains("horticultural therapy program") || lower.contains("horticultural therapy school")
            || lower.contains("horticultural therapy exam") || lower.contains("horticultural therapy assignment")
            || lower.contains("therapeutic gardening") && (lower.contains("class") || lower.contains("course") || lower.contains("therapy") || lower.contains("certification"))
            || lower.contains("horticultural therapy certification") || lower.contains("horticultural therapy notes")
            || lower.contains("plant therapy class") || lower.contains("garden therapy class") {
            return "horticulturetherapy"
        }
        // addictioncounseling — positioned BEFORE socialwork and therapy so substance-use-disorder
        // counseling coursework, CADC/NAADAC certification prep, and dual-diagnosis study route
        // to a dedicated pool. Bare word("counseling") stays in therapy.
        if lower.contains("addiction counseling") || lower.contains("addiction counselor")
            || lower.contains("addiction counselors")
            || lower.contains("substance use disorder") || lower.contains("substance use disorders")
            || lower.contains("sud counseling") || lower.contains("sud counselor")
            || lower.contains("substance abuse counseling") || lower.contains("substance abuse counselor")
            || lower.contains("dual diagnosis") || lower.contains("co-occurring disorders")
            || lower.contains("drug and alcohol counseling") || lower.contains("drug and alcohol counselor")
            || lower.contains("drug counseling") || lower.contains("alcohol counseling")
            || word("cadc") || word("naadac") || word("lcadc") || word("caadc")
            || lower.contains("behavioral health counseling") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("assignment"))
            || lower.contains("addiction class") || lower.contains("addiction course")
            || lower.contains("addiction program") || lower.contains("addiction certification")
            || lower.contains("addiction exam") || lower.contains("addiction studies")
            || lower.contains("recovery coaching class") || lower.contains("recovery coaching certification")
            || lower.contains("motivational interviewing class") || lower.contains("motivational interviewing course")
            || lower.contains("relapse prevention class") || lower.contains("relapse prevention assignment")
            || lower.contains("substance use class") || lower.contains("substance use course")
            || lower.contains("substance use exam") || lower.contains("addiction treatment class") {
            return "addictioncounseling"
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
        // massagetherapy — positioned AFTER occupationaltherapy and BEFORE speecharts.
        // Catches LMT coursework, MBLEx exam prep, and hands-on technique study.
        // "therapy notes" stays in the therapy branch above; massage claims hands-on technique terms.
        if lower.contains("massage therapy") || lower.contains("massage therapist")
            || lower.contains("massage therapists") || word("lmt")
            || word("mblex") || lower.contains("ncbtmb")
            || lower.contains("swedish massage") || lower.contains("deep tissue massage")
            || lower.contains("sports massage") || lower.contains("trigger point therapy")
            || lower.contains("trigger point massage") || lower.contains("myofascial release")
            || lower.contains("neuromuscular therapy") || lower.contains("therapeutic massage")
            || lower.contains("massage school") || lower.contains("massage program")
            || lower.contains("massage class") || lower.contains("massage exam")
            || lower.contains("massage certification") || lower.contains("massage license")
            || lower.contains("massage technique") || lower.contains("massage client notes") {
            return "massagetherapy"
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
        // gerontology — positioned BEFORE publicheath so aging-science coursework, geriatrics,
        // and eldercare study tasks get a dedicated pool instead of falling to publicheath.
        // Bare "aging" is NOT matched (too generic: "aging wine", "aging process" in biology).
        if word("gerontology") || word("gerontologist") || word("gerontological")
            || word("geriatrics") || word("geriatrician") || word("geriatric")
            || lower.contains("aging studies") || lower.contains("aging science")
            || lower.contains("social gerontology") || lower.contains("biological aging")
            || lower.contains("cognitive aging") || lower.contains("aging population")
            || lower.contains("aging policy") || lower.contains("aging research")
            || lower.contains("age-related disease") || lower.contains("age related disease")
            || lower.contains("aging and society") || lower.contains("aging in place")
            || lower.contains("dementia class") || lower.contains("dementia course")
            || lower.contains("dementia assignment") || lower.contains("dementia care class")
            || lower.contains("alzheimer's class") || lower.contains("alzheimer class")
            || lower.contains("alzheimer's research class") || lower.contains("alzheimer's course")
            || lower.contains("eldercare class") || lower.contains("elder care class")
            || lower.contains("long-term care class") || lower.contains("long term care class")
            || lower.contains("long-term care planning") || lower.contains("nursing home class")
            || lower.contains("gerontology class") || lower.contains("gerontology course")
            || lower.contains("gerontology exam") || lower.contains("gerontology program")
            || lower.contains("gerontology major") || lower.contains("gerontology assignment")
            || lower.contains("geriatric care") && lower.contains("class")
            || lower.contains("geriatric medicine") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("retirement planning class") || lower.contains("retirement planning course") {
            return "gerontology"
        }
        // behavioralhealthpromotion — positioned AFTER gerontology and BEFORE publicheath.
        // Catches CHES/MCHES certification prep, health education specialist coursework,
        // community health worker training, mental health promotion classes, and wellness
        // programming courses. Bare "health promotion" (without class/cert context) stays
        // in publicheath; "mental health" alone stays in therapy/psychology above.
        if lower.contains("behavioral health promotion") || lower.contains("mental health promotion") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("assignment") || lower.contains("program") || lower.contains("certification"))
            || lower.contains("health behavior theory") || lower.contains("health behavior change")
            || lower.contains("health education specialist")
            || lower.contains("health educator") && (lower.contains("class") || lower.contains("course") || lower.contains("certification") || lower.contains("program") || lower.contains("major") || lower.contains("exam") || lower.contains("school"))
            || word("ches") && (lower.contains("exam") || lower.contains("certification") || lower.contains("prep") || lower.contains("board") || lower.contains("study") || lower.contains("practice"))
            || word("mches") || lower.contains("mches exam") || lower.contains("mches certification")
            || lower.contains("community health worker") && (lower.contains("class") || lower.contains("course") || lower.contains("certification") || lower.contains("exam") || lower.contains("program") || lower.contains("training") || lower.contains("assignment"))
            || lower.contains("wellness programming") && (lower.contains("class") || lower.contains("course") || lower.contains("design") || lower.contains("program") || lower.contains("assignment"))
            || lower.contains("wellness coaching") && (lower.contains("class") || lower.contains("course") || lower.contains("certification") || lower.contains("exam") || lower.contains("program"))
            || lower.contains("mental health first aid") && (lower.contains("class") || lower.contains("certification") || lower.contains("training") || lower.contains("course"))
            || lower.contains("behavioral wellness class") || lower.contains("behavioral wellness course")
            || lower.contains("behavioral wellness assignment")
            || lower.contains("health promotion") && (lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("certification") || lower.contains("degree") || lower.contains("major")) && !lower.contains("public health") {
            return "behavioralhealthpromotion"
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
        // emergencymanagement — positioned after publicheath and before psychology.
        // Catches FEMA cert prep, disaster response, incident command, and crisis management.
        if lower.contains("emergency management") || lower.contains("emergency manager")
            || lower.contains("emergency planning") || lower.contains("emergency preparedness")
            || lower.contains("disaster response") || lower.contains("disaster management")
            || lower.contains("disaster preparedness") || lower.contains("disaster recovery")
            || word("fema") || lower.contains("fema exam") || lower.contains("fema course")
            || lower.contains("fema certification") || lower.contains("fema training")
            || lower.contains("hazard mitigation") || lower.contains("hazardous materials response")
            || lower.contains("incident command") || lower.contains("ics training")
            || lower.contains("crisis management") || lower.contains("crisis response")
            || lower.contains("emergency operations") || lower.contains("continuity of operations")
            || lower.contains("mass casualty") || lower.contains("search and rescue training")
            || lower.contains("public safety planning")
            || lower.contains("emergency management class") || lower.contains("emergency management course")
            || lower.contains("emergency management program") || lower.contains("emergency management major")
            || lower.contains("emergency management exam") || lower.contains("homeland security class")
            || lower.contains("homeland security course") || lower.contains("homeland security program") {
            return "emergencymanagement"
        }
        // neuroscience — positioned BEFORE psychology so brain/neuron-biology terms get a
        // dedicated pool. "neural network" (ML) stays in datascience (fires much earlier).
        if word("neuroscience") || word("neuroscientist") || word("neurobiology") || word("neurobiologist")
            || word("neuroanatomy") || word("neuropathology") || word("neuropharmacology")
            || lower.contains("cognitive neuroscience") || lower.contains("behavioral neuroscience")
            || lower.contains("computational neuroscience") || lower.contains("systems neuroscience")
            || lower.contains("action potential") || lower.contains("synaptic transmission")
            || word("neurotransmitter") || word("synapse") || word("synaptic")
            || word("neuroplasticity") || word("neuroimaging")
            || lower.contains("brain anatomy") || lower.contains("brain structure")
            || lower.contains("neural circuit") || lower.contains("nervous system anatomy")
            || lower.contains("brain and behavior") || lower.contains("brain and behaviour")
            || lower.contains("neuroscience class") || lower.contains("neuroscience course")
            || lower.contains("neuroscience exam") || lower.contains("neuroscience paper")
            || lower.contains("neuroscience major") || lower.contains("neuroscience research")
            || lower.contains("neuro class") || lower.contains("neuro exam") || lower.contains("neuro notes")
            || word("hippocampus") || word("cortex") || word("cortical") || word("subcortical")
            || word("hypothalamus") || word("amygdala") || word("cerebellum") {
            return "neuroscience"
        }
        // clinicalpsychology — positioned BEFORE psychology so doctoral-level clinical training
        // (APPIC internship match, neuropsychological assessment, psychotherapy practicum) routes
        // to a dedicated pool. EPPP is in forensicpsychology; this covers broader clinical training.
        if lower.contains("clinical psychology") || lower.contains("clinical psychologist")
            || lower.contains("clinical psychologists")
            || lower.contains("clinical psych") && !lower.contains("class") && !lower.contains("course") && !lower.contains("exam") && !lower.contains("paper") && !lower.contains("major")
            || word("appic") || lower.contains("appic match") || lower.contains("internship match") && lower.contains("psych")
            || lower.contains("psych internship") && !lower.contains("class") && !lower.contains("course")
            || lower.contains("psychology internship") || lower.contains("psychology practicum")
            || lower.contains("psych practicum") || lower.contains("clinical practicum") && lower.contains("psych")
            || lower.contains("neuropsychological testing") || lower.contains("neuropsychological assessment")
            || lower.contains("neuropsychological evaluation") || lower.contains("neuropsychological report")
            || lower.contains("psychological assessment") && !lower.contains("forensic") && !lower.contains("class") && !lower.contains("course")
            || lower.contains("psychological evaluation") && !lower.contains("forensic")
            || lower.contains("psychological testing") && !lower.contains("forensic")
            || lower.contains("psychological report") && !lower.contains("forensic")
            || lower.contains("psych assessment report") || lower.contains("assessment report") && lower.contains("psych")
            || lower.contains("psy.d") || lower.contains("psyd program") || lower.contains("clinical psyd")
            || lower.contains("doctoral psychology") || lower.contains("psychology doctoral")
            || lower.contains("clinical psychology program") || lower.contains("clinical psychology school")
            || lower.contains("clinical psychology dissertation") || lower.contains("clinical psychology thesis")
            || lower.contains("clinical psychology rotation") || lower.contains("clinical psychology clerkship")
            || lower.contains("psychotherapy notes") || lower.contains("psychotherapy session notes")
            || lower.contains("therapy notes") && lower.contains("doctoral") {
            return "clinicalpsychology"
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
        // forensicpsychology — positioned after psychology and BEFORE forensicscience so
        // criminal profiling, competency evaluation, and psycholegal tasks route here.
        // Bare word("forensics") is NOT matched (ambiguous with speech forensics).
        if lower.contains("forensic psychology") || lower.contains("forensic psychologist")
            || lower.contains("forensic psychologists") || lower.contains("criminal psychology")
            || lower.contains("criminal profiling") || lower.contains("criminal profile")
            || lower.contains("competency evaluation") || lower.contains("competency assessment")
            || lower.contains("competency to stand trial") || lower.contains("sanity evaluation")
            || lower.contains("sanity hearing") || lower.contains("insanity defense")
            || lower.contains("psycholegal") || lower.contains("forensic mental health")
            || lower.contains("forensic assessment") || lower.contains("forensic evaluation")
            || lower.contains("forensic interview") || lower.contains("forensic interviews")
            || lower.contains("psychological profiling") || lower.contains("psychological autopsy")
            || lower.contains("risk assessment forensic") || lower.contains("violence risk assessment")
            || lower.contains("expert witness psychology") || lower.contains("expert witness psychiatry")
            || lower.contains("malingering assessment") || lower.contains("competency restoration")
            || lower.contains("eppp exam") || lower.contains("eppp prep") || word("eppp")
            || lower.contains("forensic psych") || lower.contains("forensic psychology class")
            || lower.contains("forensic psychology course") || lower.contains("forensic psychology exam")
            || lower.contains("forensic psychology program") || lower.contains("forensic psychology major") {
            return "forensicpsychology"
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
        // militarystudies — positioned after criminaljustice and before socialscience so military
        // history, ROTC, and defense-studies tasks don't fall through to socialscience or history pools.
        // Bare word("history") stays in the studying branch; "military" requires a compound term.
        if lower.contains("military history") || lower.contains("military science")
            || lower.contains("military studies") || lower.contains("military strategy")
            || lower.contains("military tactics") || lower.contains("military operations")
            || lower.contains("military leadership") || lower.contains("military theory")
            || word("rotc") || lower.contains("rotc class") || lower.contains("rotc training")
            || lower.contains("officer training") || lower.contains("officer candidate")
            || lower.contains("officer candidate school") || lower.contains("ocs prep")
            || lower.contains("veterans studies") || lower.contains("veteran studies")
            || lower.contains("defense studies") || lower.contains("national security studies")
            || lower.contains("armed forces") && lower.contains("study")
            || lower.contains("military class") || lower.contains("military course")
            || lower.contains("military exam") || lower.contains("military program")
            || word("asvab") || lower.contains("asvab prep") || lower.contains("asvab exam")
            || lower.contains("asvab study") || lower.contains("military entrance")
            || lower.contains("counterinsurgency") || lower.contains("counterterrorism")
            || lower.contains("war studies") || lower.contains("conflict studies") {
            return "militarystudies"
        }
        // ethnicstudies — positioned BEFORE socialscience so ethnic/gender/women's studies tasks
        // get a dedicated callout pool. Bare "gender" or "culture" are NOT matched (too broad).
        if lower.contains("ethnic studies") || lower.contains("ethnicity studies")
            || lower.contains("african american studies") || lower.contains("black studies")
            || lower.contains("african diaspora studies")
            || lower.contains("latino studies") || lower.contains("latinx studies")
            || lower.contains("hispanic studies") || lower.contains("chicano studies") || lower.contains("chicanx studies")
            || lower.contains("asian american studies")
            || lower.contains("native american studies") || lower.contains("indigenous studies")
            || lower.contains("women's studies") || lower.contains("womens studies") || lower.contains("women studies")
            || lower.contains("gender studies") || lower.contains("feminist theory") || lower.contains("feminist studies")
            || lower.contains("queer theory") || lower.contains("lgbtq+ studies") || lower.contains("lgbtq studies")
            || word("intersectionality") || word("intersectional")
            || lower.contains("critical race theory") || lower.contains("postcolonial studies")
            || lower.contains("postcolonial theory") || lower.contains("decolonization class")
            || lower.contains("diaspora studies") || lower.contains("cultural studies class")
            || lower.contains("cultural studies course") || lower.contains("cultural studies exam") {
            return "ethnicstudies"
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
        // classicalstudies — positioned BEFORE philosophy so Latin translation, ancient Greek,
        // and classical archaeology tasks route here. Plato/Aristotle stay in philosophy too.
        // Bare word("latin") is guarded against "latin america"/"latino"/"latin music" etc.
        if lower.contains("classical studies") || lower.contains("classics major")
            || (word("classics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("paper") || lower.contains("major")))
            || lower.contains("latin translation") || lower.contains("translate latin")
            || lower.contains("latin grammar") || lower.contains("latin text")
            || lower.contains("latin prose") || lower.contains("latin poetry")
            || (word("latin") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("assignment"))
                && !lower.contains("latin america") && !lower.contains("latino") && !lower.contains("latina")
                && !lower.contains("latin music") && !lower.contains("latin dance"))
            || lower.contains("ancient greek") || lower.contains("attic greek")
            || lower.contains("koine greek") || lower.contains("greek translation") || lower.contains("translate greek")
            || lower.contains("classical archaeology") || lower.contains("ancient history")
            || lower.contains("classical literature") || lower.contains("ancient literature")
            || lower.contains("ancient rome") || lower.contains("ancient greece")
            || lower.contains("homer") && (lower.contains("iliad") || lower.contains("odyssey") || lower.contains("class") || lower.contains("course"))
            || lower.contains("virgil") && (lower.contains("aeneid") || lower.contains("class") || lower.contains("course") || lower.contains("translation"))
            || lower.contains("cicero") && (lower.contains("class") || lower.contains("course") || lower.contains("translation"))
            || lower.contains("greco-roman") || lower.contains("greco roman")
            || lower.contains("classical antiquity") || lower.contains("roman history")
            || lower.contains("hellenistic") && lower.contains("class") {
            return "classicalstudies"
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
        // publichealthlaw — positioned BEFORE healthcarelaw so public-health-specific legal topics
        // (quarantine law, vaccine mandates, FDA regulation courses, food/drug law) get a dedicated
        // pool. "health policy" / "public health policy" stay in the policy branch (fires earlier).
        if lower.contains("public health law") || lower.contains("public health law class")
            || lower.contains("public health law course") || lower.contains("public health law exam")
            || lower.contains("public health law assignment") || lower.contains("public health law paper")
            || lower.contains("public health law and policy") || lower.contains("health law and policy")
            || lower.contains("global health law") || lower.contains("global health law class")
            || lower.contains("food and drug law") || lower.contains("food and drug law class")
            || lower.contains("fda regulation class") || lower.contains("fda regulation course")
            || lower.contains("fda law class") || lower.contains("fda law course")
            || lower.contains("quarantine law") || lower.contains("quarantine regulation class")
            || lower.contains("vaccination law") || lower.contains("vaccination mandate law")
            || lower.contains("vaccine mandate law") || lower.contains("infectious disease law")
            || lower.contains("public health statute") || lower.contains("public health regulation class")
            || lower.contains("public health regulation course")
            || lower.contains("public health legislation") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("population health law") {
            return "publichealthlaw"
        }
        // healthcarelaw — positioned BEFORE legal so health-law courses, HIPAA-as-law, bioethics
        // law, and medical malpractice tasks route here. "health policy" stays in the policy branch.
        if lower.contains("health law") || lower.contains("healthcare law") || lower.contains("medical law")
            || lower.contains("health care law") || lower.contains("healthcare regulation class")
            || lower.contains("healthcare regulation course") || lower.contains("healthcare regulation exam")
            || lower.contains("hipaa law") || lower.contains("hipaa class") || lower.contains("hipaa course")
            || lower.contains("hipaa exam") || lower.contains("hipaa certification")
            || lower.contains("bioethics class") || lower.contains("bioethics course") || lower.contains("bioethics exam")
            || lower.contains("medical ethics class") || lower.contains("medical ethics course")
            || lower.contains("medical liability") || lower.contains("medical malpractice")
            || lower.contains("healthcare reform law") || lower.contains("health care reform law")
            || lower.contains("patient rights law") || lower.contains("informed consent law")
            || lower.contains("health law class") || lower.contains("health law course")
            || lower.contains("health law exam") || lower.contains("health law paper") {
            return "healthcarelaw"
        }
        // tradelaw — positioned BEFORE legal so international trade, WTO law, and customs-
        // compliance coursework routes here. Bare "trade" is NOT matched (too common in business).
        if lower.contains("trade law") || lower.contains("international trade law")
            || lower.contains("import export law") || lower.contains("import/export law")
            || lower.contains("wto law") || lower.contains("wto dispute")
            || lower.contains("trade regulation class") || lower.contains("trade regulation course")
            || lower.contains("trade compliance class") || lower.contains("trade compliance course")
            || lower.contains("customs law") || lower.contains("customs regulation class")
            || lower.contains("international law class") || lower.contains("international law course")
            || lower.contains("international law exam") || lower.contains("international law paper")
            || lower.contains("international business law")
            || lower.contains("international arbitration class") || lower.contains("international arbitration course")
            || lower.contains("comparative law class") || lower.contains("comparative law course")
            || lower.contains("treaty law") || lower.contains("transnational law")
            || lower.contains("conflict of laws") {
            return "tradelaw"
        }
        // immigrationlaw — positioned BEFORE the general legal branch so visa petitions,
        // asylum claims, USCIS filings, and removal proceedings don't fall through to
        // generic legal/bar-exam callouts.
        if lower.contains("immigration law") || lower.contains("immigration lawyer")
            || lower.contains("immigration attorney") || lower.contains("immigration legal")
            || lower.contains("visa petition") || lower.contains("visa application")
            || lower.contains("visa renewal") || lower.contains("visa interview")
            || lower.contains("i-130") || lower.contains("i-485") || lower.contains("i-765")
            || word("uscis") || lower.contains("uscis form")
            || lower.contains("asylum claim") || lower.contains("asylum application")
            || lower.contains("deportation defense") || lower.contains("deportation case")
            || lower.contains("removal proceedings") || lower.contains("removal defense")
            || lower.contains("naturalization exam") || lower.contains("citizenship application")
            || lower.contains("citizenship test") || word("daca")
            || lower.contains("green card") && lower.contains("applic")
            || lower.contains("immigration status") || lower.contains("immigration class")
            || lower.contains("immigration course") || lower.contains("immigration exam")
            || lower.contains("immigration program") {
            return "immigrationlaw"
        }
        // intellectualproperty — positioned BEFORE the general legal branch so patent prosecution,
        // trademark registration, and patent bar prep don't fall through to generic legal callouts.
        if lower.contains("intellectual property") || lower.contains("ip law")
            || lower.contains("ip lawyer") || lower.contains("ip attorney")
            || lower.contains("ip litigation") || lower.contains("ip class")
            || lower.contains("ip course") || lower.contains("ip exam")
            || lower.contains("patent law") || lower.contains("patent lawyer")
            || lower.contains("patent attorney") || lower.contains("patent litigation")
            || lower.contains("patent prosecution") || lower.contains("patent application")
            || lower.contains("patent filing") || lower.contains("patent claims")
            || lower.contains("patent agent") || lower.contains("patent bar")
            || word("uspto") || lower.contains("patent office")
            || lower.contains("trademark law") || lower.contains("trademark infringement")
            || lower.contains("trademark registration") || lower.contains("trademark application")
            || lower.contains("copyright law") || lower.contains("copyright infringement")
            || lower.contains("copyright registration") || lower.contains("trade secret")
            || word("ptab") || lower.contains("patent licensing")
            || lower.contains("ip portfolio") || lower.contains("ip policy") {
            return "intellectualproperty"
        }
        // environmentallaw — positioned BEFORE the general legal branch so NEPA compliance,
        // environmental litigation, Clean Air/Water Act assignments, and Superfund research
        // don't fall through to generic bar-exam / brief callouts.
        // Bare "environmental science"/"environmental studies" fires the enviro branch earlier.
        if lower.contains("environmental law") || lower.contains("environmental regulation class")
            || lower.contains("environmental regulation course") || lower.contains("environmental regulation exam")
            || lower.contains("environmental litigation") || lower.contains("environmental compliance class")
            || lower.contains("environmental compliance course")
            || lower.contains("environmental attorney") || lower.contains("environmental lawyer")
            || lower.contains("environmental law class") || lower.contains("environmental law course")
            || lower.contains("environmental law exam") || lower.contains("environmental law assignment")
            || word("nepa") || lower.contains("national environmental policy act")
            || lower.contains("clean air act") || lower.contains("clean water act")
            || lower.contains("endangered species act")
            || word("cercla") || lower.contains("superfund law") || lower.contains("superfund class")
            || lower.contains("natural resources law") || lower.contains("land use law")
            || lower.contains("climate change law") || lower.contains("climate litigation")
            || lower.contains("epa regulation class") || lower.contains("epa law") {
            return "environmentallaw"
        }
        // familylaw — positioned BEFORE the general legal branch so divorce, custody, adoption,
        // and domestic-relations coursework routes here rather than generic bar-exam callouts.
        if lower.contains("family law") || lower.contains("family lawyer")
            || lower.contains("family attorney") || lower.contains("family law class")
            || lower.contains("family law course") || lower.contains("family law exam")
            || lower.contains("family law assignment") || lower.contains("family law clinic")
            || lower.contains("divorce law") || lower.contains("divorce proceeding")
            || lower.contains("child custody") || lower.contains("custody agreement")
            || lower.contains("custody battle") || lower.contains("parental rights")
            || lower.contains("adoption law") || lower.contains("adoption proceeding")
            || lower.contains("domestic relations") || lower.contains("domestic violence law")
            || lower.contains("alimony") || lower.contains("spousal support law")
            || lower.contains("child support law") || lower.contains("marital property")
            || lower.contains("prenuptial agreement") || lower.contains("postnuptial agreement")
            || lower.contains("guardianship law") || lower.contains("termination of parental rights") {
            return "familylaw"
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
        // landscapearchitecture — positioned BEFORE the building-architecture branch because
        // "landscape architect" would otherwise match word("architect") and "site plan" is in both.
        if lower.contains("landscape architecture") || lower.contains("landscape architect")
            || lower.contains("landscape architects") || lower.contains("landscape design")
            || lower.contains("landscape designer")
            || word("clarb") || lower.contains("clarb exam")
            || lower.contains("planting plan") || lower.contains("planting design")
            || lower.contains("planting scheme") || lower.contains("plant palette")
            || lower.contains("hardscape") || lower.contains("softscape")
            || lower.contains("la studio") || lower.contains("landscape studio")
            || lower.contains("grading plan") || lower.contains("site grading")
            || lower.contains("stormwater management") && lower.contains("design")
            || lower.contains("constructed wetland") || lower.contains("rain garden")
            || lower.contains("landscape plan") || lower.contains("site inventory")
            || lower.contains("landscape class") || lower.contains("landscape exam")
            || lower.contains("landscape program") || lower.contains("landscape school")
            || lower.contains("landscape architecture class") || lower.contains("landscape architecture exam")
            || lower.contains("landscape architecture program") {
            return "landscapearchitecture"
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
