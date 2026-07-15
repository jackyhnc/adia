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
        // networkengineering — positioned AFTER cybersecurity (which owns network security/forensics)
        // and BEFORE gamedev. Catches CCNA/CCNP/CCIE cert prep, CompTIA Network+, IBEW networking
        // coursework, and networking class/course/exam terms. Bare "network" alone NOT matched.
        if word("ccna") || word("ccnp") || word("ccie")
            || lower.contains("network+") || lower.contains("network plus") || lower.contains("comptia network")
            || lower.contains("cisco networking") || lower.contains("cisco ios")
            && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("cisco class") || lower.contains("cisco course") || lower.contains("cisco exam")
            || lower.contains("cisco certification")
            || (lower.contains("cisco router") || lower.contains("cisco switch")) && (lower.contains("class") || lower.contains("lab"))
            || lower.contains("network protocols class") || lower.contains("network protocols course") || lower.contains("network protocols exam")
            || lower.contains("subnetting class") || lower.contains("subnetting exam")
            || lower.contains("routing and switching")
            || lower.contains("network engineering class") || lower.contains("network engineering course") || lower.contains("network engineering exam")
            || lower.contains("network administration class") || lower.contains("network administration course") || lower.contains("network administration exam")
            || lower.contains("wan class") || lower.contains("lan class") || lower.contains("wan course") || lower.contains("lan course")
            || lower.contains("networking class") || lower.contains("networking course") || lower.contains("networking exam")
            || lower.contains("networking program") || lower.contains("networking certification") || lower.contains("networking lab")
            || (word("ospf") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || (word("bgp") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || (word("eigrp") && (lower.contains("class") || lower.contains("course")))
            || lower.contains("ip addressing class") || lower.contains("ip addressing course")
            || lower.contains("firewall class") || lower.contains("firewall configuration class")
            || lower.contains("network infrastructure class") {
            return "networkengineering"
        }
        // quantumcomputing — positioned AFTER networkengineering and BEFORE gamedev.
        // Catches quantum computing coursework, quantum algorithm classes, Qiskit, IBM Quantum, and
        // quantum cryptography/error-correction courses. Bare word("quantum") NOT matched here —
        // quantum physics or quantum chemistry stays in studying/research.
        if lower.contains("quantum computing") || lower.contains("quantum computer")
            || lower.contains("quantum algorithm") || lower.contains("quantum algorithms")
            || word("qiskit")
            || lower.contains("quantum circuit") || lower.contains("quantum circuits")
            || lower.contains("quantum gate") || lower.contains("quantum gates")
            || lower.contains("ibm quantum") || lower.contains("ibm q ")
            || lower.contains("quantum programming") || lower.contains("quantum program")
            || lower.contains("quantum error correction")
            || lower.contains("quantum cryptography") || lower.contains("quantum key distribution")
            || (lower.contains("quantum information") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || (lower.contains("quantum mechanics") && (lower.contains("computing") || lower.contains("programming") || lower.contains("algorithm"))) {
            return "quantumcomputing"
        }
        // cloudcomputing — positioned AFTER quantumcomputing and BEFORE gamedev.
        // Catches AWS/Azure/GCP certification prep, cloud architecture/DevOps coursework, and
        // Terraform/Kubernetes class. "aws" alone NOT matched — requires cloud/cert/class context
        // to avoid false positives with "AWS" (American Welding Society) in weldingtech tasks.
        if (lower.contains("aws") && (lower.contains("certification") || lower.contains("cloud") || lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("training") || lower.contains("architect") || lower.contains("devops") || lower.contains("solutions")))
            || (lower.contains("azure") && (lower.contains("certification") || lower.contains("cloud") || lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("architect") || lower.contains("devops")))
            || (lower.contains("gcp") && (lower.contains("certification") || lower.contains("cloud") || lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || (lower.contains("google cloud") && (lower.contains("certification") || lower.contains("class") || lower.contains("exam") || lower.contains("architect")))
            || lower.contains("cloud computing") || lower.contains("cloud architecture class")
            || lower.contains("cloud engineer") || lower.contains("cloud architect")
            || lower.contains("devops class") || lower.contains("devops course") || lower.contains("devops exam")
            || lower.contains("devops certification") || lower.contains("devops engineer")
            || lower.contains("terraform class") || lower.contains("terraform course") || lower.contains("terraform exam")
            || lower.contains("kubernetes class") || lower.contains("kubernetes course") || lower.contains("kubernetes exam")
            || lower.contains("kubernetes certification") || word("cka") || word("ckad")
            || lower.contains("docker class") || lower.contains("docker course") || lower.contains("docker exam")
            || lower.contains("cloud deployment") || lower.contains("cloud infrastructure class")
            || lower.contains("serverless class") || lower.contains("serverless course")
            || lower.contains("cloud security class") || lower.contains("cloud migration class") {
            return "cloudcomputing"
        }
        // softwaretesting — positioned AFTER cloudcomputing and BEFORE gamedev.
        // Catches QA engineering, ISTQB exam prep, test automation frameworks in educational context,
        // and software quality assurance coursework. Bare "testing" or "test" NOT matched alone.
        // "penetration testing" stays in cybersecurity (fires earlier).
        if lower.contains("software testing") || lower.contains("software quality assurance")
            || lower.contains("qa engineering")
            || (word("qa") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("engineer") || lower.contains("testing") || lower.contains("program")))
            || word("istqb") || lower.contains("ctfl exam") || lower.contains("ctal exam")
            || lower.contains("test automation") || lower.contains("automated testing")
            || lower.contains("selenium class") || lower.contains("selenium course") || lower.contains("selenium testing")
            || (word("pytest") && (lower.contains("class") || lower.contains("course") || lower.contains("testing")))
            || (word("junit") && (lower.contains("class") || lower.contains("course") || lower.contains("testing")))
            || (lower.contains("software quality") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("engineering")))
            || lower.contains("quality assurance testing") || lower.contains("qa testing")
            || (lower.contains("regression testing") && (lower.contains("class") || lower.contains("course")))
            || (lower.contains("performance testing") && (lower.contains("class") || lower.contains("course")))
            || lower.contains("load testing class") || lower.contains("load testing course")
            || lower.contains("unit testing class") || lower.contains("unit testing course")
            || lower.contains("integration testing class") || lower.contains("integration testing course")
            || lower.contains("acceptance testing class") || lower.contains("acceptance testing course") {
            return "softwaretesting"
        }
        // robotics — positioned AFTER softwaretesting and BEFORE gamedev so ROS/ROS2, robot
        // programming, and autonomous-systems coursework route here first. Unity is used in
        // robotics but is caught by gamedev next if no robot-specific term fires.
        // Bare "robot" or "automation" alone NOT matched (too common in other contexts).
        if lower.contains("robotics class") || lower.contains("robotics course")
            || lower.contains("robotics exam") || lower.contains("robotics program")
            || lower.contains("robotics lab") || lower.contains("robotics project")
            || lower.contains("robotics assignment") || lower.contains("robotics engineering")
            || lower.contains("robotics competition") || lower.contains("robotics design")
            || word("ros") && (lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("project") || lower.contains("robotics") || lower.contains("robot"))
            || lower.contains("ros2") || lower.contains("ros 2")
            || lower.contains("robot programming") || lower.contains("robot software")
            || lower.contains("autonomous robot") || lower.contains("autonomous systems class")
            || lower.contains("autonomous systems course") || lower.contains("autonomous vehicle class")
            || lower.contains("autonomous driving class") || lower.contains("autonomous driving course")
            || lower.contains("mobile robot") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("project"))
            || lower.contains("robot kinematics") || lower.contains("robot dynamics")
            || lower.contains("robot perception") || lower.contains("robot planning")
            || lower.contains("robot control") && (lower.contains("class") || lower.contains("course") || lower.contains("lab"))
            || lower.contains("first robotics") || lower.contains("vex robotics") || lower.contains("lego robotics")
            || lower.contains("industrial robot") && (lower.contains("class") || lower.contains("course") || lower.contains("program"))
            || lower.contains("embedded robotics") || lower.contains("robotics algorithm")
            || lower.contains("path planning") && (lower.contains("robot") || lower.contains("class") || lower.contains("course"))
            || lower.contains("slam") && (lower.contains("robot") || lower.contains("class") || lower.contains("course"))
            || lower.contains("inverse kinematics") && (lower.contains("robot") || lower.contains("class") || lower.contains("arm")) {
            return "robotics"
        }
        // artificialintelligence — positioned AFTER robotics and BEFORE gamedev so AI class/course
        // work, prompt engineering study, LLM concepts, and AI ethics coursework route here.
        // "machine learning"/"deep learning" already fires in datascience (much earlier).
        // Bare "ai" alone NOT matched — requires compound context to avoid false positives.
        if lower.contains("artificial intelligence class") || lower.contains("artificial intelligence course")
            || lower.contains("artificial intelligence exam") || lower.contains("artificial intelligence program")
            || lower.contains("artificial intelligence assignment") || lower.contains("artificial intelligence project")
            || lower.contains("artificial intelligence lecture") || lower.contains("artificial intelligence notes")
            || lower.contains("ai class") || lower.contains("ai course") || lower.contains("ai exam")
            || lower.contains("ai ethics class") || lower.contains("ai ethics course") || lower.contains("ai ethics exam")
            || lower.contains("ai ethics paper") || lower.contains("ai ethics essay")
            || lower.contains("prompt engineering class") || lower.contains("prompt engineering course")
            || lower.contains("prompt engineering exam") || lower.contains("prompt engineering assignment")
            || lower.contains("large language model class") || lower.contains("large language model course")
            || lower.contains("llm class") || lower.contains("llm course") || lower.contains("llm assignment")
            || lower.contains("natural language understanding class") || lower.contains("natural language understanding course")
            || lower.contains("ai product management") || lower.contains("ai product manager")
            || lower.contains("responsible ai") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("paper"))
            || lower.contains("explainable ai") && (lower.contains("class") || lower.contains("course") || lower.contains("project"))
            || lower.contains("ai safety class") || lower.contains("ai safety course") || lower.contains("ai safety research")
            || lower.contains("ai alignment") && (lower.contains("class") || lower.contains("course") || lower.contains("research") || lower.contains("paper"))
            || lower.contains("ai regulation") && (lower.contains("class") || lower.contains("course") || lower.contains("paper"))
            || lower.contains("ai policy") && (lower.contains("class") || lower.contains("course") || lower.contains("paper"))
            || lower.contains("knowledge representation") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("expert system") && (lower.contains("class") || lower.contains("course") || lower.contains("ai"))
            || lower.contains("search algorithm") && (lower.contains("ai") || lower.contains("class") || lower.contains("course"))
            || lower.contains("planning algorithm") && (lower.contains("ai") || lower.contains("class") || lower.contains("course"))
            || lower.contains("ai textbook") || lower.contains("ai lecture") || lower.contains("ai notes") && lower.contains("class") {
            return "artificialintelligence"
        }
        // blockchain — positioned AFTER artificialintelligence and BEFORE gamedev so blockchain class/course,
        // smart contract development, Solidity programming, and crypto/DeFi coursework routes here.
        // Bare "crypto" or "bitcoin" alone NOT matched — compound context required.
        if lower.contains("blockchain class") || lower.contains("blockchain course")
            || lower.contains("blockchain exam") || lower.contains("blockchain program")
            || lower.contains("blockchain assignment") || lower.contains("blockchain project")
            || lower.contains("blockchain development") || lower.contains("blockchain developer")
            || lower.contains("blockchain technology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("blockchain programming") || lower.contains("blockchain lab")
            || lower.contains("smart contract") || lower.contains("smart contracts")
            || word("solidity") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("programming") || lower.contains("project"))
            || lower.contains("solidity programming") || lower.contains("solidity class") || lower.contains("solidity course")
            || lower.contains("ethereum class") || lower.contains("ethereum course") || lower.contains("ethereum development")
            || lower.contains("web3 class") || lower.contains("web3 course") || lower.contains("web3 development")
            || lower.contains("web3 project") || lower.contains("decentralized application") || lower.contains("dapp development")
            || lower.contains("defi class") || lower.contains("defi course") || lower.contains("defi project")
            || lower.contains("nft development") || lower.contains("nft class") || lower.contains("nft course")
            || lower.contains("cryptocurrency class") || lower.contains("cryptocurrency course") || lower.contains("cryptocurrency exam")
            || lower.contains("crypto class") && (lower.contains("exam") || lower.contains("course") || lower.contains("assignment"))
            || lower.contains("distributed ledger") && (lower.contains("class") || lower.contains("course") || lower.contains("technology"))
            || lower.contains("hyperledger") || lower.contains("hyperledger fabric")
            || lower.contains("consensus algorithm") && (lower.contains("blockchain") || lower.contains("class") || lower.contains("course"))
            || lower.contains("proof of work") && (lower.contains("class") || lower.contains("course") || lower.contains("blockchain"))
            || lower.contains("proof of stake") && (lower.contains("class") || lower.contains("course") || lower.contains("blockchain")) {
            return "blockchain"
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
        // certifiedfinancialplanner — positioned AFTER actuarial and BEFORE statistics.
        // Catches CFP exam prep, financial planning coursework, and wealth/retirement/estate
        // planning classes. Bare "financial planning" alone NOT matched — requires CFP context
        // or class/course/exam qualifier. Generic finance terms (CPA, CFA, DCF) stay in finance.
        if lower.contains("certified financial planner") || lower.contains("cfp exam")
            || lower.contains("cfp certification") || lower.contains("cfp board")
            || lower.contains("cfp class") || lower.contains("cfp course")
            || lower.contains("cfp program") || lower.contains("cfp notes")
            || lower.contains("cfp study") || lower.contains("cfp prep")
            || lower.contains("financial planning class") || lower.contains("financial planning course")
            || lower.contains("financial planning program") || lower.contains("financial planning exam")
            || lower.contains("financial planning certification") || lower.contains("personal financial planning")
            || lower.contains("wealth management class") || lower.contains("wealth management course")
            || lower.contains("wealth management certification")
            || lower.contains("retirement planning class") || lower.contains("retirement planning course")
            || lower.contains("estate planning class") || lower.contains("estate planning course")
            || lower.contains("investment planning class") || lower.contains("investment planning course")
            || lower.contains("tax planning class") || lower.contains("tax planning course")
            || lower.contains("insurance planning class") || lower.contains("insurance planning course")
            || lower.contains("financial plan class") || lower.contains("financial plan exam")
            || lower.contains("series 65") || lower.contains("series 66") {
            return "certifiedfinancialplanner"
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
        // soilscience — positioned BEFORE geology so dedicated soil-science and pedology
        // coursework gets its own pool. "soil mechanics" stays in geology (construction context).
        // Bare "soil" alone is NOT matched.
        if lower.contains("soil science") || lower.contains("soil scientist")
            || word("pedology") || word("pedologist")
            || lower.contains("soil taxonomy") || lower.contains("soil classification")
            || (lower.contains("munsell") && lower.contains("soil"))
            || word("pedon") || word("pedons")
            || lower.contains("soil horizon") || lower.contains("soil profile")
            || lower.contains("soil mapping") || lower.contains("soil survey")
            || lower.contains("soil genesis") || lower.contains("soil formation")
            || (lower.contains("soil chemistry") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam")))
            || (lower.contains("soil physics") && (lower.contains("class") || lower.contains("course") || lower.contains("lab")))
            || (lower.contains("soil biology") && (lower.contains("class") || lower.contains("course") || lower.contains("lab")))
            || (lower.contains("soil fertility") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || lower.contains("soil judging") || lower.contains("soil characterization")
            || lower.contains("soil morphology") || lower.contains("nrcs soil")
            || lower.contains("soil science class") || lower.contains("soil science course")
            || lower.contains("soil science exam") || lower.contains("soil science program")
            || lower.contains("soil science notes") || lower.contains("soil science major")
            || lower.contains("soil science degree") {
            return "soilscience"
        }
        // agriculturalscience — positioned AFTER soilscience (soil-science-specific pedology terms fire
        // first) and BEFORE geology so agronomy, crop science, and precision agriculture coursework
        // routes here. Bare "agriculture" alone NOT matched; educational/professional context required.
        if word("agronomy") || word("agronomist") || word("agronomists")
            || lower.contains("crop science") || lower.contains("crop production class")
            || lower.contains("crop production course") || lower.contains("crop production exam")
            || lower.contains("crop management class") || lower.contains("crop management course")
            || lower.contains("crop physiology") || lower.contains("plant breeding class")
            || lower.contains("plant breeding course") || lower.contains("plant breeding program")
            || lower.contains("precision agriculture") || lower.contains("precision farming")
            || lower.contains("agricultural science class") || lower.contains("agricultural science course")
            || lower.contains("agricultural science exam") || lower.contains("agricultural science program")
            || lower.contains("agricultural science major") || lower.contains("agricultural science degree")
            || lower.contains("agri-science class") || lower.contains("agri-science course")
            || lower.contains("agriculture class") && (lower.contains("exam") || lower.contains("lab") || lower.contains("assignment") || lower.contains("program"))
            || lower.contains("agriculture exam") || lower.contains("agriculture lab")
            || lower.contains("agronomy class") || lower.contains("agronomy course")
            || lower.contains("agronomy exam") || lower.contains("agronomy program")
            || lower.contains("soil fertility class") || lower.contains("soil fertility course")
            || lower.contains("soil fertility exam")
            || lower.contains("field crop") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("grain crop") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("oilseed crop") || lower.contains("forage crop") && (lower.contains("class") || lower.contains("course"))
            || lower.contains("cover crop management class") || lower.contains("cover crop management course")
            || lower.contains("farm management class") || lower.contains("farm management course")
            || lower.contains("farm management exam") || lower.contains("farm management program")
            || lower.contains("agricultural extension") && (lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("exam"))
            || lower.contains("cooperative extension class") || lower.contains("extension agriculture") {
            return "agriculturalscience"
        }
        // geographyearthed — positioned BEFORE geology so AP Human/Physical Geography and world
        // geography coursework gets a dedicated pool. GIS tools stay in geospatial (fires earlier).
        // Bare word("geography") alone NOT matched; educational context required.
        if lower.contains("human geography") || lower.contains("physical geography")
            || lower.contains("cultural geography") || lower.contains("political geography")
            || lower.contains("economic geography") || lower.contains("regional geography")
            || lower.contains("world geography class") || lower.contains("world geography course")
            || lower.contains("world geography exam") || lower.contains("world geography program")
            || lower.contains("world geography notes") || lower.contains("world geography assignment")
            || lower.contains("ap geography") || lower.contains("ap human geography")
            || lower.contains("ap physical geography")
            || lower.contains("geography class") || lower.contains("geography course")
            || lower.contains("geography exam") || lower.contains("geography assignment")
            || lower.contains("geography major") || lower.contains("geography degree")
            || lower.contains("geography program") || lower.contains("geography notes")
            || lower.contains("urban geography") || lower.contains("rural geography")
            || lower.contains("population geography") || lower.contains("biogeography class")
            || lower.contains("biogeography course") || lower.contains("biogeography exam")
            || lower.contains("climate geography") || lower.contains("place-based geography")
            || lower.contains("geographic fieldwork") || lower.contains("geography field trip")
            || lower.contains("geo class") && !lower.contains("geoscience") && !lower.contains("geology") {
            return "geographyearthed"
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
            || lower.contains("soil mechanics")
            || lower.contains("hydrology") {
            return "geology"
        }
        // maritimestudies — positioned BEFORE aviation so USCG licensing, merchant marine
        // programs, and nautical science coursework get a dedicated pool. "maritime engineering"
        // NOT matched here (stays in engineering). "maritime law" with class/course fires here;
        // standalone "trade law" and "international law" stay in their own branches.
        if lower.contains("maritime studies") || lower.contains("maritime program")
            || lower.contains("maritime class") || lower.contains("maritime course")
            || lower.contains("maritime exam") || lower.contains("maritime major")
            || lower.contains("maritime school") || lower.contains("maritime academy")
            || lower.contains("maritime law") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("paper") || lower.contains("assignment"))
            || lower.contains("maritime transportation") && (lower.contains("class") || lower.contains("course") || lower.contains("program"))
            || lower.contains("maritime management") && (lower.contains("class") || lower.contains("course") || lower.contains("program"))
            || lower.contains("merchant marine") || lower.contains("merchant mariner")
            || lower.contains("uscg license") || lower.contains("uscg certification")
            || lower.contains("uscg exam") || lower.contains("uscg test") || lower.contains("uscg written")
            || lower.contains("coast guard license") || lower.contains("coast guard exam")
            || lower.contains("nautical science") || lower.contains("nautical studies")
            || lower.contains("nautical class") || lower.contains("nautical course")
            || lower.contains("marine transportation class") || lower.contains("marine transportation course")
            || lower.contains("port management class") || lower.contains("port management course")
            || lower.contains("stcw training") || lower.contains("stcw certification")
            || lower.contains("seafarer certification") || lower.contains("seafarers exam")
            || lower.contains("ship navigation class") || lower.contains("ship navigation course")
            || word("mmba") && lower.contains("maritime")
            || lower.contains("marine navigation class") || lower.contains("marine navigation course") {
            return "maritimestudies"
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
        // plumbingtech — positioned BEFORE automotivetech so journeyman/master plumber exam prep,
        // NCCER plumbing coursework, plumbing code classes, and plumbing apprenticeship route here.
        // Bare "plumbing" alone NOT matched — requires program/certification/class/exam context.
        if lower.contains("plumbing technology") || lower.contains("plumbing tech")
            || lower.contains("journeyman plumber") || lower.contains("master plumber exam") || lower.contains("master plumber class")
            || lower.contains("nccer plumbing")
            || lower.contains("plumbing code class") || lower.contains("plumbing code exam")
            || lower.contains("plumber exam") || lower.contains("plumber license")
            || lower.contains("plumbing apprentice") || lower.contains("plumber apprentice")
            || (lower.contains("plumbing program") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("notes") || lower.contains("lab")))
            || lower.contains("plumbing school") || lower.contains("plumbing certification") || lower.contains("plumbing license")
            || lower.contains("plumbing notes") || lower.contains("plumbing class") || lower.contains("plumbing course")
            || lower.contains("plumbing lab") {
            return "plumbingtech"
        }
        // electricaltechnology — positioned AFTER plumbingtech and BEFORE automotivetech.
        // Catches journeyman/master electrician exam prep, NEC code classes, IBEW/NJATC training,
        // and electrician apprenticeship programs. "electrical engineering" and "computer engineering"
        // are NOT matched here — those fire in the engineering branch later.
        if lower.contains("journeyman electrician") || lower.contains("master electrician exam") || lower.contains("master electrician class")
            || lower.contains("electrician exam") || lower.contains("electrician apprentice") || lower.contains("electrician apprenticeship")
            || lower.contains("electrical apprentice") || lower.contains("electrical apprenticeship")
            || lower.contains("ibew training") || word("ibew")
            || lower.contains("njatc training") || word("njatc")
            || (lower.contains("nec code") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("study")))
            || (lower.contains("national electrical code") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || lower.contains("electrical code class") || lower.contains("electrical code exam") || lower.contains("electrical code study")
            || lower.contains("electrician class") || lower.contains("electrician course") || lower.contains("electrician program")
            || lower.contains("electrician school") || lower.contains("electrician certification") || lower.contains("electrician license")
            || lower.contains("electrical theory class") || lower.contains("electrical theory course") {
            return "electricaltechnology"
        }
        // automotivetech — positioned BEFORE hvactechnology so ASE certification, engine diagnostics,
        // and automotive service programs route here. "automotive engineering" and "automotive design"
        // already caught by engineering/design branches that fire earlier.
        if lower.contains("automotive technology") || lower.contains("automotive service")
            || lower.contains("automotive technician") || lower.contains("auto mechanic")
            || lower.contains("auto mechanics") || lower.contains("auto tech program")
            || lower.contains("auto technology") || lower.contains("auto service")
            || lower.contains("ase certification") || lower.contains("ase exam")
            || lower.contains("ase test") || lower.contains("ase prep") || lower.contains("ase cert")
            || (lower.contains("ase") && (lower.contains("automotive") || lower.contains("auto tech") || lower.contains("technician")))
            || lower.contains("automotive class") || lower.contains("automotive course")
            || lower.contains("automotive program") || lower.contains("automotive school")
            || lower.contains("automotive exam") || lower.contains("automotive notes")
            || lower.contains("automotive lab") || lower.contains("auto tech class")
            || lower.contains("auto tech course") || lower.contains("auto tech notes")
            || lower.contains("engine diagnostics") || lower.contains("engine repair class")
            || lower.contains("engine rebuild") && lower.contains("class")
            || lower.contains("transmission class") || lower.contains("transmission course")
            || lower.contains("brake service class") || lower.contains("brake systems class")
            || lower.contains("auto body class") || lower.contains("auto body program")
            || lower.contains("collision repair class") || lower.contains("collision repair program")
            || (lower.contains("automotive electrical") || lower.contains("automotive electronics"))
            && (lower.contains("class") || lower.contains("course") || lower.contains("exam")) {
            return "automotivetech"
        }
        // weldingtechnology — positioned AFTER automotivetech, BEFORE hvactechnology.
        // Bare word("welding") is NOT matched — requires educational/certification context.
        if lower.contains("welding technology") || lower.contains("welding technician")
            || lower.contains("welding certification") || lower.contains("welding certificate")
            || lower.contains("welding program") || lower.contains("welding class")
            || lower.contains("welding course") || lower.contains("welding exam")
            || lower.contains("welding school") || lower.contains("welding notes")
            || lower.contains("welding lab")
            || lower.contains("aws welding") || lower.contains("american welding society")
            || lower.contains("cwi exam") || lower.contains("cwi certification")
            || lower.contains("certified welding inspector")
            || (lower.contains("aws certification") && lower.contains("weld"))
            || lower.contains("mig welding") || lower.contains("tig welding")
            || lower.contains("arc welding") || lower.contains("flux core welding")
            || lower.contains("structural welding") || lower.contains("pipe welding")
            || lower.contains("welding inspection") || lower.contains("weld testing") {
            return "weldingtechnology"
        }
        // hvactechnology — positioned BEFORE engineering so HVAC trade programs, EPA 608 exam
        // prep, and refrigeration coursework route here rather than generic engineering pool.
        // "air conditioning" alone not matched; requires class/course/tech/exam context.
        if lower.contains("hvac") && (lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("exam") || lower.contains("school") || lower.contains("tech") || lower.contains("certification") || lower.contains("training") || lower.contains("install") || lower.contains("service") || lower.contains("system"))
            || lower.contains("hvac technology") || lower.contains("hvac technician")
            || lower.contains("epa 608") || lower.contains("epa608") || lower.contains("epa section 608")
            || lower.contains("refrigeration class") || lower.contains("refrigeration course")
            || lower.contains("refrigeration exam") || lower.contains("refrigeration tech")
            || lower.contains("refrigeration certification") || lower.contains("refrigerant certification")
            || lower.contains("air conditioning class") || lower.contains("air conditioning course")
            || lower.contains("air conditioning exam") || lower.contains("air conditioning tech")
            || lower.contains("heating ventilation and air conditioning")
            || lower.contains("mechanical systems class") && lower.contains("hvac")
            || lower.contains("heat pump class") || lower.contains("heat pump course")
            || lower.contains("boiler operation class") || lower.contains("boiler course")
            || lower.contains("hvac school") || lower.contains("hvac program")
            || lower.contains("hvac apprentice") || lower.contains("hvac lab")
            || lower.contains("cooling systems class") || lower.contains("heating systems class") {
            return "hvactechnology"
        }
        // mechanicaldrafting — positioned AFTER hvactechnology and BEFORE industrialsafety.
        // Catches drafting technology programs, technical drawing classes, blueprint reading,
        // and mechanical/architectural drafting coursework. Bare word("drafting") NOT matched
        // (avoids false positives with "drafting a paper/plan/email"). "CAD" alone stays in
        // engineering; "architectural drawing" with design context stays in architecture.
        if lower.contains("mechanical drafting") || lower.contains("technical drafting")
            || lower.contains("drafting technology") || lower.contains("drafting technician")
            || lower.contains("drafting class") || lower.contains("drafting course")
            || lower.contains("drafting program") || lower.contains("drafting exam")
            || lower.contains("drafting lab") || lower.contains("drafting school")
            || lower.contains("drafting certification") || lower.contains("drafting notes")
            || lower.contains("technical drawing") || lower.contains("technical drawing class")
            || lower.contains("engineering drawing") || lower.contains("engineering drawing class")
            || lower.contains("engineering graphics") || lower.contains("engineering graphics class")
            || lower.contains("blueprint reading") || lower.contains("blueprint reading class")
            || lower.contains("blueprint reading course") || lower.contains("blueprint reading exam")
            || lower.contains("drafting and design") || lower.contains("autocad class")
            || lower.contains("autocad course") || lower.contains("autocad exam") {
            return "mechanicaldrafting"
        }
        // industrialsafety — positioned AFTER hvactechnology, BEFORE engineering.
        // Catches industrial hygiene, CIH exam, OSHA compliance, and occupational-safety coursework.
        // Bare "OSHA" or "safety" alone NOT matched — requires industrial/class/course/exam context.
        if lower.contains("industrial hygiene") || lower.contains("industrial hygienist")
            || (word("cih") && (lower.contains("industrial") || lower.contains("hygiene") || lower.contains("exam") || lower.contains("certification")))
            || lower.contains("cih exam") || lower.contains("cih certification")
            || lower.contains("industrial safety") || lower.contains("occupational safety and health")
            || (lower.contains("occupational safety") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("program")))
            || (lower.contains("osha compliance") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("certification")))
            || (lower.contains("osha 30") && (lower.contains("industrial") || lower.contains("manufacturing") || lower.contains("class") || lower.contains("course")))
            || (lower.contains("osha 10") && (lower.contains("industrial") || lower.contains("manufacturing") || lower.contains("class") || lower.contains("course")))
            || lower.contains("osha 300a") || lower.contains("osha 300") && lower.contains("log")
            || (lower.contains("osha certification") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || lower.contains("safety program design") || lower.contains("safety management class")
            || (lower.contains("hazard analysis") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("industrial")))
            || lower.contains("job safety analysis") || lower.contains("job hazard analysis")
            || (word("jsa") && lower.contains("safety")) || (word("jha") && lower.contains("safety"))
            || (word("niosh") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("industrial")))
            || lower.contains("industrial safety class") || lower.contains("industrial safety course")
            || lower.contains("industrial safety exam") || lower.contains("industrial safety program") {
            return "industrialsafety"
        }
        // materialscience — positioned AFTER industrialsafety and BEFORE engineering.
        // Catches MSE coursework, metallurgy, polymer science, ceramics (in engineering context),
        // composite materials, nanomaterials, and phase diagram labs. "ceramics" alone (art context)
        // NOT matched — requires class/course/exam/lab/engineering qualifier.
        if lower.contains("materials science") || lower.contains("materials engineering")
            || lower.contains("material science") || lower.contains("material engineering")
            || lower.contains("materials science and engineering")
            || lower.contains("metallurgy") || lower.contains("metallurgical engineering")
            || (lower.contains("ceramics") && !lower.contains("art") && !lower.contains("studio") && !lower.contains("pottery") && !lower.contains("wheel") && !lower.contains("glaze") && !lower.contains("raku") && !lower.contains("kiln firing") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("engineering")))
            || (lower.contains("polymer science") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || lower.contains("polymer chemistry") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("polymer engineering")
            || (lower.contains("composite materials") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab")))
            || (lower.contains("nanomaterials") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || (lower.contains("nanotechnology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || (lower.contains("crystallography") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || (lower.contains("crystal structure") && (lower.contains("class") || lower.contains("course") || lower.contains("lab")))
            || (lower.contains("phase diagram") && (lower.contains("class") || lower.contains("course") || lower.contains("lab")))
            || (lower.contains("corrosion engineering") && (lower.contains("class") || lower.contains("course")))
            || lower.contains("thermodynamics of materials")
            || (lower.contains("electronic materials") || lower.contains("magnetic materials")) && (lower.contains("class") || lower.contains("course"))
            || (word("mems") && (lower.contains("class") || lower.contains("course") || lower.contains("lab")))
            || (lower.contains("thin film") && lower.contains("lab") && lower.contains("material"))
            || (word("mse") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))) {
            return "materialscience"
        }
        // healthphysics — positioned BEFORE engineering so medical/health physics, radiation
        // protection coursework, and CHP/ABHP board prep route here rather than to the
        // engineering pool. Bare "physics" alone is NOT matched.
        if lower.contains("health physics") || lower.contains("medical physics")
            || word("chp") && (lower.contains("exam") || lower.contains("board") || lower.contains("certification") || lower.contains("prep") || lower.contains("study"))
            || word("abhp") || lower.contains("health physicist") || lower.contains("medical physicist")
            || lower.contains("health physics class") || lower.contains("health physics course")
            || lower.contains("health physics exam") || lower.contains("health physics program")
            || lower.contains("health physics school") || lower.contains("health physics notes")
            || lower.contains("medical physics class") || lower.contains("medical physics course")
            || lower.contains("medical physics exam") || lower.contains("medical physics program")
            || lower.contains("medical physics residency") || lower.contains("medical physics notes")
            || lower.contains("radiation protection class") || lower.contains("radiation protection course")
            || lower.contains("radiation safety class") || lower.contains("radiation safety course")
            || lower.contains("radiation safety officer class") || lower.contains("radiation safety officer program")
            || lower.contains("radiation safety exam") || lower.contains("radiation safety certification")
            || lower.contains("shielding calculation") && (lower.contains("class") || lower.contains("exam") || lower.contains("lab") || lower.contains("course"))
            || lower.contains("radiation monitoring class") || lower.contains("radiation monitoring course")
            || lower.contains("dosimetry class") && !(lower.contains("radiation therapy") || lower.contains("nuclear medicine"))
            || lower.contains("mpse exam") || lower.contains("medical physics board")
            || lower.contains("radiation physics class") || lower.contains("radiation physics course")
            || lower.contains("diagnostic medical physics") || lower.contains("nuclear physics class") && lower.contains("radiation")
            || lower.contains("environmental radiation class") || lower.contains("environmental radiation course") {
            return "healthphysics"
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
        // dataengineering — positioned AFTER datascience and BEFORE computationalscience.
        // Catches data engineering coursework, ETL pipeline class, Apache Spark/Kafka/Airflow
        // class, dbt class, and data warehouse coursework. "data analysis" alone stays in
        // datascience; bare word("data") NOT matched.
        if lower.contains("data engineering") || lower.contains("data engineer")
            || (lower.contains("apache spark") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("project")))
            || (lower.contains("apache kafka") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab")))
            || (lower.contains("apache airflow") && (lower.contains("class") || lower.contains("course") || lower.contains("project") || lower.contains("pipeline")))
            || lower.contains("etl pipeline") || lower.contains("etl class") || lower.contains("etl course")
            || lower.contains("data pipeline") && (lower.contains("class") || lower.contains("course") || lower.contains("build") || lower.contains("design") || lower.contains("project"))
            || lower.contains("dbt class") || lower.contains("dbt course") || lower.contains("dbt project") || lower.contains("dbt pipeline")
            || lower.contains("data warehouse class") || lower.contains("data warehouse course")
            || lower.contains("data warehouse design") || lower.contains("data warehousing")
            || lower.contains("data lake") && (lower.contains("class") || lower.contains("course") || lower.contains("design") || lower.contains("build"))
            || lower.contains("spark streaming") || lower.contains("real-time data pipeline")
            || lower.contains("stream processing class") || lower.contains("batch processing class")
            || lower.contains("databricks class") || lower.contains("databricks course") || lower.contains("databricks certification")
            || lower.contains("snowflake class") || lower.contains("snowflake course") || lower.contains("snowflake certification")
            || lower.contains("data integration class") || lower.contains("data modeling class") {
            return "dataengineering"
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
        // constructionmanagement — positioned BEFORE urbanplanning so CM-degree coursework,
        // CCM/CMAA exam prep, estimating, and scheduling tasks route here rather than architecture
        // (which owns blueprints/design) or engineering. "construction documents" NOT matched
        // (belongs to architecture). "garment construction" NOT matched (in fashiondesign branch).
        if lower.contains("construction management") || lower.contains("construction manager")
            || lower.contains("construction project management")
            || lower.contains("cm degree") || lower.contains("cm program") || lower.contains("cm major")
            || word("ccm") && (lower.contains("construction") || lower.contains("certif") || lower.contains("exam"))
            || lower.contains("cmaa") && (lower.contains("exam") || lower.contains("certif") || lower.contains("construction"))
            || lower.contains("construction estimating") || lower.contains("cost estimating") && lower.contains("construction")
            || lower.contains("construction budget") && lower.contains("class")
            || lower.contains("construction budgeting")
            || lower.contains("construction scheduling") || lower.contains("cpm scheduling") && lower.contains("construction")
            || lower.contains("construction bidding") || lower.contains("bid estimate")
            || lower.contains("construction law class") || lower.contains("construction law course")
            || lower.contains("construction safety class") || lower.contains("osha 30") && lower.contains("construction")
            || lower.contains("subcontractor management") || lower.contains("construction quality management")
            || lower.contains("green building class") || lower.contains("leed exam") && !lower.contains("architect")
            || lower.contains("bim class") || lower.contains("bim course") && !lower.contains("architect")
            || lower.contains("construction class") && (lower.contains("management") || lower.contains("estimat"))
            || lower.contains("construction course") && (lower.contains("management") || lower.contains("estimat"))
            || lower.contains("construction program") && lower.contains("management")
            || lower.contains("construction exam") && lower.contains("management") {
            return "constructionmanagement"
        }
        // constructiontech — positioned AFTER constructionmanagement so trade-school carpentry,
        // masonry, concrete technology, and contractor license exam prep route here.
        // "construction management" and CCM/CMAA terms fire constructionmanagement first.
        if lower.contains("construction technology") || lower.contains("construction tech")
            || lower.contains("carpentry class") || lower.contains("carpentry course")
            || lower.contains("carpentry program") || lower.contains("carpentry exam")
            || lower.contains("wood framing") && (lower.contains("class") || lower.contains("course") || lower.contains("lab"))
            || lower.contains("concrete class") || lower.contains("concrete course")
            || lower.contains("concrete lab") || lower.contains("concrete technology")
            || lower.contains("masonry class") || lower.contains("masonry course")
            || lower.contains("masonry program") || lower.contains("masonry exam")
            || lower.contains("building trades") && (lower.contains("class") || lower.contains("program") || lower.contains("school"))
            || lower.contains("contractor license exam") || lower.contains("contractor licensing exam")
            || lower.contains("construction inspection class") || lower.contains("construction inspection course")
            || lower.contains("construction inspection exam")
            || lower.contains("trades school") && lower.contains("construction")
            || lower.contains("construction apprentice") && !lower.contains("management") {
            return "constructiontech"
        }
        // urbandesign — positioned BEFORE urbanplanning so streetscape design, placemaking,
        // and public space design route to a dedicated design-focused pool.
        // "urban design" caught here; urbanplanning retains planning/policy terms.
        if lower.contains("urban design") || lower.contains("placemaking")
            || lower.contains("place-making") || lower.contains("place making")
            || lower.contains("streetscape design") || lower.contains("public space design")
            || lower.contains("public realm design") || lower.contains("civic design")
            || lower.contains("urban furniture") || lower.contains("street furniture")
            || lower.contains("complete streets") && lower.contains("design")
            || lower.contains("pedestrian realm") || lower.contains("pedestrian design")
            || lower.contains("urban form analysis") || lower.contains("urban form study")
            || lower.contains("urban park design") || lower.contains("pocket park design")
            || lower.contains("urban design studio") || lower.contains("urban design project")
            || lower.contains("urban design class") || lower.contains("urban design course")
            || lower.contains("urban design program") || lower.contains("urban design exam") {
            return "urbandesign"
        }
        // urbanplanning — positioned before realestate (which catches bare word("zoning")) so
        // "urban planning", "zoning ordinance", and AICP exam prep route to the planning pool.
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
        // floristryweddingplanning — positioned AFTER hospitality (which owns generic "event
        // planning" classes) so floral design programs, AIFD certification prep, and wedding
        // planning certification tasks route to a dedicated pool. "event planning" alone stays
        // in hospitality; requires wedding/floral context to fire here.
        if lower.contains("floral design") || lower.contains("floral designer")
            || word("floristry") || lower.contains("florist") && (lower.contains("class") || lower.contains("program") || lower.contains("exam") || lower.contains("school") || lower.contains("certif"))
            || word("aifd") || lower.contains("aifd certification") || lower.contains("aifd exam")
            || lower.contains("american institute of floral designers")
            || lower.contains("flower arrangement class") || lower.contains("flower arranging class")
            || lower.contains("floral arrangement class") || lower.contains("floral arrangement course")
            || lower.contains("floral arrangement exam") || lower.contains("floral arrangement program")
            || lower.contains("floristry program") || lower.contains("floristry class")
            || lower.contains("floristry exam") || lower.contains("floristry school")
            || lower.contains("floristry certification") || lower.contains("floristry course")
            || lower.contains("wedding planning") || lower.contains("wedding planner")
            || lower.contains("wedding coordinator") || lower.contains("wedding planning certification")
            || lower.contains("wedding planning program") || lower.contains("wedding planning class")
            || lower.contains("wedding planning course") || lower.contains("wedding planning exam")
            || lower.contains("event florals") || lower.contains("wedding florals")
            || lower.contains("floral design school") || lower.contains("floral design program")
            || lower.contains("floral design class") || lower.contains("floral design course")
            || lower.contains("floral design exam") || lower.contains("floral design certification") {
            return "floristryweddingplanning"
        }
        // qualitymanagement — positioned BEFORE supplychain (which owns six sigma/lean) and BEFORE
        // business so ISO auditing, CQE exam prep, and quality systems coursework gets a dedicated
        // pool. "six sigma class" and "lean six sigma" remain in supplychain. Bare "quality" NOT matched.
        if word("cqe") && (lower.contains("exam") || lower.contains("certification") || lower.contains("board") || lower.contains("asq") || lower.contains("prep") || lower.contains("study") || lower.contains("quality"))
            || word("asq") && (lower.contains("quality") || lower.contains("certification") || lower.contains("exam") || lower.contains("cqe") || lower.contains("audit"))
            || lower.contains("iso 9001") || lower.contains("iso9001")
            || lower.contains("iso 14001") || lower.contains("iso 45001")
            || lower.contains("quality management system") || lower.contains("quality management systems")
            || lower.contains("qms audit") || lower.contains("qms class") || lower.contains("qms course")
            || lower.contains("quality assurance class") || lower.contains("quality assurance course")
            || lower.contains("quality assurance exam") || lower.contains("quality assurance program")
            || lower.contains("quality control class") || lower.contains("quality control course")
            || lower.contains("quality control exam") || lower.contains("quality control lab")
            || lower.contains("quality engineering class") || lower.contains("quality engineering course")
            || lower.contains("quality engineering exam") || lower.contains("quality engineering program")
            || lower.contains("statistical process control class") || lower.contains("statistical process control course")
            || lower.contains("spc class") || lower.contains("spc course") || lower.contains("spc lab")
            || lower.contains("process improvement class") || lower.contains("process improvement course")
            || lower.contains("fmea analysis") && (lower.contains("class") || lower.contains("course") || lower.contains("assignment"))
            || lower.contains("design of experiments class") || lower.contains("doe class")
            || lower.contains("design of experiments course") || lower.contains("doe course")
            || lower.contains("total quality management") || lower.contains("tqm class") || lower.contains("tqm course")
            || lower.contains("quality audit class") || lower.contains("quality audit course")
            || lower.contains("internal audit class") || lower.contains("internal audit course")
            || lower.contains("cmq/oe") || lower.contains("cmq exam")
            || lower.contains("quality management class") || lower.contains("quality management course")
            || lower.contains("quality management exam") || lower.contains("quality management program") {
            return "qualitymanagement"
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
        // projectmanagement — positioned AFTER supplychain and BEFORE riskmanagement/business so PMP exam
        // prep, agile/scrum certification, and project management courses route here.
        // Generic "project" tasks stay in the general pool (bare word("project") NOT matched here).
        if lower.contains("pmp exam") || lower.contains("pmp certification") || lower.contains("pmp class")
            || word("pmp") && (lower.contains("exam") || lower.contains("cert") || lower.contains("study") || lower.contains("prep") || lower.contains("class"))
            || lower.contains("pmi-acp") || word("capm") && (lower.contains("exam") || lower.contains("cert") || lower.contains("class"))
            || lower.contains("project management class") || lower.contains("project management course")
            || lower.contains("project management exam") || lower.contains("project management certification")
            || lower.contains("project management professional") || lower.contains("project management program")
            || lower.contains("project management degree") || lower.contains("project management assignment")
            || lower.contains("agile certification") || lower.contains("agile class") || lower.contains("agile course")
            || lower.contains("agile exam") || lower.contains("agile training")
            || lower.contains("scrum master") || lower.contains("scrum certification")
            || lower.contains("scrum class") || lower.contains("scrum course") || lower.contains("scrum exam")
            || lower.contains("kanban class") || lower.contains("kanban course") || lower.contains("kanban certification")
            || lower.contains("project charter") && (lower.contains("class") || lower.contains("assignment") || lower.contains("course"))
            || lower.contains("work breakdown structure") && (lower.contains("class") || lower.contains("assignment"))
            || lower.contains("wbs") && (lower.contains("class") || lower.contains("assignment") || lower.contains("course"))
            || word("pmbok") || lower.contains("prince2") && (lower.contains("class") || lower.contains("exam") || lower.contains("cert"))
            || lower.contains("agile project management") || lower.contains("sprint planning class") {
            return "projectmanagement"
        }
        // riskmanagement — positioned AFTER projectmanagement and BEFORE business so ERM, risk assessment,
        // and risk management certification courses route here (distinct from actuarial exam prep which fires earlier).
        // Bare "risk" alone NOT matched — compound context required.
        if lower.contains("risk management class") || lower.contains("risk management course")
            || lower.contains("risk management exam") || lower.contains("risk management certification")
            || lower.contains("risk management program") || lower.contains("risk management degree")
            || lower.contains("risk management assignment") || lower.contains("risk management professional")
            || lower.contains("enterprise risk management") || lower.contains("enterprise risk")
            || lower.contains("erm class") || lower.contains("erm certification") || lower.contains("erm framework")
            || lower.contains("risk assessment class") || lower.contains("risk assessment course")
            || lower.contains("risk analysis class") || lower.contains("risk analysis course")
            || lower.contains("risk modeling class") || lower.contains("risk modeling course")
            || word("rims") && (lower.contains("certification") || lower.contains("exam") || lower.contains("class"))
            || lower.contains("crm certification") && lower.contains("risk")
            || lower.contains("risk framework") && (lower.contains("class") || lower.contains("assignment"))
            || lower.contains("risk register") && (lower.contains("class") || lower.contains("assignment") || lower.contains("project"))
            || lower.contains("governance risk compliance") || lower.contains("grc class") || lower.contains("grc course")
            || lower.contains("operational risk class") || lower.contains("operational risk course")
            || lower.contains("financial risk management class") || lower.contains("financial risk class")
            || lower.contains("cyber risk class") || lower.contains("it risk class") || lower.contains("it risk management")
            || lower.contains("iso 31000") && (lower.contains("class") || lower.contains("assignment") || lower.contains("exam")) {
            return "riskmanagement"
        }
        // informationsystems — positioned AFTER riskmanagement and BEFORE business so MIS programs,
        // SAP ERP class, systems analysis and design, and enterprise systems courses route here.
        // Distinct from pure coding (handled far earlier) and generic business management.
        // Bare word("is") alone NOT matched — compound context required.
        if lower.contains("management information systems")
            || lower.contains("mis program") || lower.contains("mis class") || lower.contains("mis course")
            || lower.contains("mis degree") || lower.contains("mis major") || lower.contains("mis exam")
            || lower.contains("mis assignment")
            || lower.contains("information systems class") || lower.contains("information systems course")
            || lower.contains("information systems exam") || lower.contains("information systems program")
            || lower.contains("information systems major") || lower.contains("information systems degree")
            || lower.contains("information systems assignment") || lower.contains("information systems project")
            || lower.contains("sap erp class") || lower.contains("sap erp course") || lower.contains("sap erp certification")
            || lower.contains("enterprise systems class") || lower.contains("enterprise systems course")
            || lower.contains("enterprise resource planning class") || lower.contains("enterprise resource planning course")
            || lower.contains("systems analysis and design class") || lower.contains("systems analysis and design course")
            || lower.contains("systems analysis class") || lower.contains("systems analysis course")
            || lower.contains("systems analysis exam") || lower.contains("systems design class")
            || lower.contains("it governance class") || lower.contains("it governance course")
            || lower.contains("it management class") || lower.contains("it management course")
            || lower.contains("misa degree") || lower.contains("mise degree")
            || word("mis") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("program") || lower.contains("assignment")) {
            return "informationsystems"
        }
        // businessintelligence — positioned AFTER informationsystems and BEFORE business so Tableau,
        // Power BI, and BI certification programs route here. Distinct from datascience (ML/Python/Jupyter)
        // and dataengineering (ETL/Spark/Airflow). Bare "data visualization" stays in datascience
        // unless explicitly combined with a BI tool or BI program context.
        if lower.contains("tableau class") || lower.contains("tableau course") || lower.contains("tableau exam")
            || lower.contains("tableau certification")
            || lower.contains("power bi class") || lower.contains("power bi course")
            || lower.contains("power bi certification") || lower.contains("power bi exam")
            || lower.contains("business intelligence class") || lower.contains("business intelligence course")
            || lower.contains("business intelligence program") || lower.contains("business intelligence certification")
            || lower.contains("business intelligence exam") || lower.contains("business intelligence degree")
            || lower.contains("looker class") || lower.contains("looker certification")
            || lower.contains("qlik class") || lower.contains("qlikview class") || lower.contains("qlik certification")
            || lower.contains("domo class") || lower.contains("domo certification")
            || lower.contains("bi certification") || lower.contains("bi tools class") || lower.contains("bi tools course")
            || lower.contains("data visualization class") && (lower.contains("bi") || lower.contains("tableau") || lower.contains("power bi") || lower.contains("business intelligence"))
            || lower.contains("reporting and analytics class") || lower.contains("reporting and analytics course")
            || lower.contains("microsoft power bi")
            || lower.contains("bi dashboard class") || lower.contains("bi reporting class") {
            return "businessintelligence"
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
        // speechcommunication — positioned AFTER communicationstudies and BEFORE journalism so
        // public speaking class, debate class, and oral communication courses route here.
        // Distinct from speechpathology (clinical therapy) and communicationstudies (theory/mass comm).
        // Bare "speech" alone NOT matched — compound context required.
        if lower.contains("public speaking class") || lower.contains("public speaking course")
            || lower.contains("public speaking exam") || lower.contains("public speaking assignment")
            || lower.contains("speech class") && !lower.contains("speech therapy") && !lower.contains("speech-language")
            || lower.contains("speech course") && !lower.contains("speech therapy") && !lower.contains("speech-language")
            || lower.contains("speech exam") && !lower.contains("speech-language")
            || lower.contains("debate class") || lower.contains("debate course") || lower.contains("debate exam")
            || lower.contains("debate assignment") || lower.contains("debate team") || lower.contains("debate preparation")
            || lower.contains("oral communication class") || lower.contains("oral communication course")
            || lower.contains("oral communication exam") || lower.contains("oral communication assignment")
            || lower.contains("speech and debate") || lower.contains("competitive debate")
            || lower.contains("parliamentary debate") || lower.contains("parliamentary procedure class")
            || lower.contains("forensics speech") || lower.contains("speech forensics")
            || lower.contains("lincoln-douglas debate") || lower.contains("policy debate class")
            || lower.contains("model un speech") || lower.contains("model united nations speech")
            || lower.contains("toastmasters class") || lower.contains("toastmasters course")
            || lower.contains("speech writing") && (lower.contains("class") || lower.contains("course") || lower.contains("assignment"))
            || lower.contains("oratory class") || lower.contains("oratory course")
            || lower.contains("elocution class") || lower.contains("public address class")
            || lower.contains("persuasive speech class") || lower.contains("persuasive speech course")
            || lower.contains("informative speech class") || lower.contains("informative speech course")
            || lower.contains("impromptu speaking class") || lower.contains("impromptu speaking course")
            || lower.contains("speech preparation") && (lower.contains("class") || lower.contains("course") || lower.contains("assignment")) {
            return "speechcommunication"
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
        // digitalmarketing — positioned AFTER publicrelations and BEFORE textilesfashion so SEO class/course,
        // Google Analytics, social media marketing, and digital marketing certificate programs route here.
        // "brand strategy"/"brand management" stay in startup branch (fires much earlier).
        if lower.contains("digital marketing class") || lower.contains("digital marketing course")
            || lower.contains("digital marketing exam") || lower.contains("digital marketing certificate")
            || lower.contains("digital marketing program") || lower.contains("digital marketing degree")
            || lower.contains("digital marketing assignment")
            || lower.contains("seo class") || lower.contains("seo course") || lower.contains("seo certification")
            || lower.contains("search engine optimization class") || lower.contains("search engine optimization course")
            || lower.contains("google analytics class") || lower.contains("google analytics certification") || lower.contains("google analytics exam")
            || lower.contains("social media marketing class") || lower.contains("social media marketing course")
            || lower.contains("social media marketing exam") || lower.contains("social media marketing certification")
            || lower.contains("content marketing class") || lower.contains("content marketing course")
            || lower.contains("email marketing class") || lower.contains("email marketing course")
            || lower.contains("ppc class") || lower.contains("ppc course") || lower.contains("ppc certification")
            || lower.contains("sem class") || lower.contains("sem course")
            || lower.contains("pay-per-click class") || lower.contains("pay per click class")
            || lower.contains("marketing analytics class") || lower.contains("marketing analytics course")
            || lower.contains("google ads class") || lower.contains("google ads certification")
            || lower.contains("meta ads class") || lower.contains("facebook ads class")
            || lower.contains("affiliate marketing class") || lower.contains("affiliate marketing course")
            || lower.contains("conversion rate optimization") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("influencer marketing class") || lower.contains("influencer marketing course")
            || lower.contains("growth marketing class") || lower.contains("growth marketing course")
            || lower.contains("digital advertising class") || lower.contains("digital advertising course")
            || lower.contains("inbound marketing class") || lower.contains("hubspot certification")
            || lower.contains("marketing automation class") || lower.contains("marketing funnel class") {
            return "digitalmarketing"
        }
        // textilesfashion — positioned BEFORE fashiondesign so fiber arts, hand weaving, natural
        // dyeing, textile engineering, and spinning coursework routes here. "textile design" in a
        // fashion-school context still goes to fashiondesign (fires next). Bare "sewing" NOT matched.
        if lower.contains("fiber arts") || lower.contains("fibre arts")
            || lower.contains("hand weaving") || lower.contains("hand-weaving")
            || lower.contains("loom weaving") || lower.contains("tapestry weaving")
            || lower.contains("weaving class") || lower.contains("weaving course")
            || lower.contains("weaving program") || lower.contains("weaving exam")
            || lower.contains("weaving studio") || lower.contains("weaving assignment")
            || lower.contains("natural dyeing") || lower.contains("natural dye class")
            || lower.contains("natural dye course") || lower.contains("fabric dyeing class")
            || lower.contains("fabric dyeing course") || lower.contains("textile dyeing")
            || lower.contains("fiber dyeing") || lower.contains("indigo dyeing")
            || lower.contains("fiber spinning") || lower.contains("spinning wheel")
            || lower.contains("yarn spinning") || lower.contains("wool spinning")
            || lower.contains("drop spindle") || lower.contains("spinning class")
            || lower.contains("spinning course") || lower.contains("spinning program")
            || lower.contains("textile engineering") || lower.contains("textile science")
            || lower.contains("textile technology class") || lower.contains("textile technology course")
            || lower.contains("textile technology program") || lower.contains("textile technology exam")
            || lower.contains("textile chemistry class") || lower.contains("textile chemistry course")
            || lower.contains("textile manufacturing class") || lower.contains("textile manufacturing course")
            || lower.contains("textile structure") && (lower.contains("class") || lower.contains("course") || lower.contains("lab"))
            || lower.contains("knitting class") && (lower.contains("program") || lower.contains("course") || lower.contains("studio") || lower.contains("exam"))
            || lower.contains("crochet class") && (lower.contains("program") || lower.contains("course") || lower.contains("studio") || lower.contains("exam"))
            || lower.contains("macramé class") || lower.contains("macrame class")
            || lower.contains("surface design class") || lower.contains("surface design course") {
            return "textilesfashion"
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
        // ceramicsandsculpture — positioned BEFORE glassblowing and art so pottery, wheel throwing,
        // and ceramics arts program work routes here. "ceramics" in engineering/dental context stays
        // in materialscience/dentallab (fires earlier). word("sculpting") stays in art.
        if word("pottery") || word("ceramicist") || word("ceramicists")
            || lower.contains("ceramics") && (lower.contains("class") || lower.contains("studio")
                || lower.contains("program") || lower.contains("wheel") || lower.contains("kiln")
                || lower.contains("art") || lower.contains("course") || lower.contains("glaze"))
            || lower.contains("wheel throwing") || lower.contains("wheel-throwing")
            || lower.contains("kiln firing") && !lower.contains("glass")
            || lower.contains("ceramic arts") || lower.contains("ceramic art") && !lower.contains("dental")
            || lower.contains("pottery class") || lower.contains("pottery wheel")
            || lower.contains("pottery studio") || lower.contains("pottery course")
            || lower.contains("hand building") && (lower.contains("clay") || lower.contains("ceramic"))
            || lower.contains("hand-building") && (lower.contains("clay") || lower.contains("ceramic"))
            || lower.contains("slip casting") && !lower.contains("concrete")
            || lower.contains("coil building") && (lower.contains("clay") || lower.contains("ceramic"))
            || lower.contains("slab building") && (lower.contains("clay") || lower.contains("ceramic"))
            || lower.contains("raku firing") || lower.contains("raku pottery") || lower.contains("raku kiln")
            || lower.contains("ceramic glaze") || lower.contains("glazing") && lower.contains("ceramic")
            || lower.contains("sculpture class") || lower.contains("sculpture course")
            || lower.contains("sculpture program") || lower.contains("sculpture studio")
            || lower.contains("sculpture major") || lower.contains("sculpture school") {
            return "ceramicsandsculpture"
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
        // grantwriting — positioned BEFORE writing so NIH/NSF proposals, specific aims, and
        // grant narratives route here. Only compound terms matched — bare word("grant") stays in
        // the writing branch below for generic academic writing tasks.
        if lower.contains("grant proposal") || lower.contains("grant proposals")
            || lower.contains("grant application") || lower.contains("grant applications")
            || lower.contains("grant writing") || lower.contains("grant writer")
            || lower.contains("writing a grant") || lower.contains("write a grant")
            || lower.contains("research grant") && (lower.contains("writing") || lower.contains("application") || lower.contains("proposal") || lower.contains("narrative"))
            || lower.contains("nih grant") || lower.contains("nsf grant")
            || lower.contains("nih application") || lower.contains("nsf application")
            || (lower.contains("r01") || lower.contains("r21") || lower.contains("r03") || lower.contains("k99") || lower.contains("f31") || lower.contains("f32"))
            && (lower.contains("grant") || lower.contains("aim") || lower.contains("application") || lower.contains("narrative"))
            || lower.contains("sbir grant") || lower.contains("sttr grant")
            || lower.contains("sbir application") || lower.contains("sttr application")
            || lower.contains("specific aims") || lower.contains("grant narrative")
            || lower.contains("grant budget") || lower.contains("grant submission")
            || lower.contains("grant deadline") || lower.contains("grant funding")
            || lower.contains("foundation grant") || lower.contains("grant-writing")
            || lower.contains("grant review") && lower.contains("writing") {
            return "grantwriting"
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
        // exercisescience — positioned BEFORE kinesiology so exercise science degree/major
        // and ACSM exam prep route to a dedicated pool. "exercise physiology" stays in kinesiology.
        // Bare word("exercise") stays in fitness.
        if lower.contains("exercise science") || lower.contains("exercise scientist")
            || word("acsm") || lower.contains("acsm exam") || lower.contains("acsm certification")
            || lower.contains("acsm cep") || lower.contains("certified exercise physiologist")
            || lower.contains("exercise testing") && (lower.contains("class") || lower.contains("lab") || lower.contains("course"))
            || lower.contains("graded exercise test")
            || word("gxt") && (lower.contains("class") || lower.contains("lab") || lower.contains("test"))
            || lower.contains("metabolic cart") && (lower.contains("class") || lower.contains("lab") || lower.contains("test"))
            || lower.contains("metabolic testing") && (lower.contains("class") || lower.contains("lab"))
            || lower.contains("exercise science class") || lower.contains("exercise science course")
            || lower.contains("exercise science exam") || lower.contains("exercise science program")
            || lower.contains("exercise science major") || lower.contains("exercise science degree")
            || lower.contains("exercise science school") || lower.contains("exercise science notes") {
            return "exercisescience"
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
        // orthotics — positioned AFTER kinesiology and BEFORE pmrehabilitation so orthotics/prosthetics
        // credentialing, O&P fabrication/fitting, and CPO/CPT board prep route here.
        // "physical therapy" stays in kinesiology (fires earlier).
        if lower.contains("orthotics and prosthetics") || lower.contains("prosthetics and orthotics")
            || lower.contains("orthotics program") || lower.contains("orthotics class") || lower.contains("orthotics course")
            || lower.contains("orthotics exam") || lower.contains("orthotics school") || lower.contains("orthotics lab")
            || lower.contains("prosthetics program") || lower.contains("prosthetics class") || lower.contains("prosthetics course")
            || lower.contains("prosthetics exam") || lower.contains("prosthetics school") || lower.contains("prosthetics lab")
            || lower.contains("cpo exam") || lower.contains("cpo board") || lower.contains("cpo certification")
            || lower.contains("cpt exam") && (lower.contains("orthotics") || lower.contains("prosthetics") || lower.contains("o&p"))
            || lower.contains("cfo exam") || lower.contains("cfo certification") && (lower.contains("orthotics") || lower.contains("fitter"))
            || lower.contains("abc board") && (lower.contains("orthotics") || lower.contains("prosthetics"))
            || lower.contains("ncope") || lower.contains("caahep orthotics") || lower.contains("jrc-ep")
            || word("orthotist") || word("prosthetist") || word("prosthetists") || word("orthotists")
            || lower.contains("o&p class") || lower.contains("o&p course") || lower.contains("o&p exam")
            || lower.contains("o&p program") || lower.contains("o&p school") || lower.contains("o&p notes")
            || lower.contains("orthotic device") && (lower.contains("class") || lower.contains("course") || lower.contains("design") || lower.contains("fabrication"))
            || lower.contains("orthotic lab") || lower.contains("prosthetic fitting") || lower.contains("prosthetic design")
            || lower.contains("prosthetic fabrication") || lower.contains("limb prosthesis class")
            || lower.contains("upper extremity prosthetics") || lower.contains("lower extremity prosthetics")
            || lower.contains("lower limb orthotics") || lower.contains("upper limb orthotics") {
            return "orthotics"
        }
        // pmrehabilitation — positioned AFTER kinesiology and BEFORE personaltraining so
        // physiatry, PM&R residency/clerkship, and ABPMR board prep get a dedicated pool.
        // "physical therapy" stays in kinesiology (fires earlier); PM&R catches physician-level terms.
        if lower.contains("physical medicine and rehabilitation") || lower.contains("physical medicine & rehabilitation")
            || lower.contains("pm&r") || lower.contains("pm & r")
            || lower.contains("physiatry") || word("physiatrist") || word("physiatrists")
            || lower.contains("abpmr") || lower.contains("abpmr board") || lower.contains("abpmr exam")
            || lower.contains("abpmr certification") || lower.contains("abpmr prep")
            || lower.contains("rehabilitation medicine") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("residency") || lower.contains("clerkship") || lower.contains("rotation") || lower.contains("notes") || lower.contains("assignment"))
            || lower.contains("pm&r residency") || lower.contains("pm&r clerkship")
            || lower.contains("pm&r rotation") || lower.contains("pm&r notes")
            || lower.contains("pm&r class") || lower.contains("pm&r course") || lower.contains("pm&r exam")
            || lower.contains("pm&r school") || lower.contains("pm&r program")
            || lower.contains("spinal cord injury rehabilitation") && lower.contains("class")
            || lower.contains("traumatic brain injury rehabilitation") && lower.contains("class")
            || lower.contains("musculoskeletal rehabilitation") && (lower.contains("class") || lower.contains("course") || lower.contains("physician")) {
            return "pmrehabilitation"
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
        // performancenutrition — positioned BEFORE healthcoaching and fitness so sports-dietitian
        // certification prep, CSSD exam, and athlete-fueling tasks route here rather than to the
        // generic nutrition or fitness pools. "nutrition plan"/"meal prep" stay in fitness (fire later).
        if lower.contains("sports dietitian") || lower.contains("sport dietitian")
            || lower.contains("sports dietetics") || lower.contains("sport dietetics")
            || lower.contains("cssd exam") || lower.contains("cssd certification") || word("cssd")
            || lower.contains("board certified specialist in sports dietetics")
            || lower.contains("performance nutrition") || lower.contains("performance nutritionist")
            || lower.contains("performance dietitian") || lower.contains("athlete nutrition")
            || lower.contains("athlete fueling") || lower.contains("sports fueling")
            || lower.contains("sports nutrition certification") || lower.contains("sports nutrition exam")
            || lower.contains("sports nutrition class") || lower.contains("sports nutrition course")
            || lower.contains("sports nutrition program") || lower.contains("sports nutrition school")
            || lower.contains("sport nutrition certification") || lower.contains("sport nutrition exam")
            || lower.contains("sport nutrition class") || lower.contains("sport nutrition course")
            || lower.contains("fueling strategy") && (lower.contains("athlete") || lower.contains("sport") || lower.contains("perform"))
            || lower.contains("competition nutrition") || lower.contains("race day nutrition")
            || lower.contains("endurance athlete fueling") || lower.contains("team fueling") {
            return "performancenutrition"
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
        // foodsafety — positioned AFTER culinary (culinary owns general recipe/kitchen technique),
        // BEFORE winesommelier. Catches ServSafe prep, HACCP certification, and food-safety
        // coursework. Bare "food" alone NOT matched; "food journal" stays in nutrition (fires earlier);
        // "food science" stays in nutrition (fires earlier).
        if lower.contains("food safety") || lower.contains("servsafe")
            || lower.contains("haccp plan") || lower.contains("haccp certification")
            || lower.contains("haccp training") || lower.contains("haccp class")
            || lower.contains("food handler") || lower.contains("food handling certification")
            || lower.contains("food sanitation") || lower.contains("food safety certification")
            || lower.contains("food safety exam") || lower.contains("food safety class")
            || lower.contains("food safety course") || lower.contains("food safety program")
            || lower.contains("food safety training") || lower.contains("food safety manager")
            || lower.contains("food safety audit")
            || (lower.contains("food microbiology") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam")))
            || (lower.contains("food contamination") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || lower.contains("foodborne illness") || lower.contains("foodborne pathogen")
            || (lower.contains("food inspection") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || lower.contains("fda food safety") || (lower.contains("fsma") && lower.contains("food"))
            || lower.contains("food protection manager") || lower.contains("food protection certification") {
            return "foodsafety"
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
        // winemaking — positioned AFTER winesommelier (which captures sommelier study/certification,
        // viticulture class, and enology class) so production-side terms — winery operations,
        // cellar management, wine fermentation, barrel aging — get a dedicated winemaking pool.
        // Bare "wine" alone is NOT matched; needs operational/production context.
        if lower.contains("winemaking") || lower.contains("wine making")
            || lower.contains("wine production") || lower.contains("wine fermentation")
            || lower.contains("wine blending") || lower.contains("wine bottling")
            || lower.contains("barrel aging") || lower.contains("wine barrel") || lower.contains("oak aging")
            || lower.contains("winery operations") || lower.contains("winery management")
            || word("winery") && (lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("lab") || lower.contains("intern"))
            || lower.contains("cellar management") || lower.contains("cellar operations")
            || lower.contains("vineyard management") || lower.contains("vineyard operations")
            || lower.contains("grape crush") || lower.contains("grape harvest") && lower.contains("wine")
            || lower.contains("wine chemistry lab") || lower.contains("wine chemistry class")
            || lower.contains("wine chemistry course") || lower.contains("wine lab")
            || lower.contains("wine analysis") || lower.contains("wine microbiology")
            || lower.contains("wine production class") || lower.contains("wine production course")
            || lower.contains("wine production lab") || lower.contains("wine production program") {
            return "winemaking"
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
        // appliedmusic — positioned AFTER musictheory so instrument-specific practice, audition
        // prep, and recital performance route here. Bare instrument names alone NOT matched —
        // requires practice/lesson/audition/recital context. "music production" (DAW/beatmaking)
        // and "music theory" (ear training/harmony) already caught by earlier branches.
        if lower.contains("instrument practice") || lower.contains("practice instrument")
            || lower.contains("audition prep") || lower.contains("audition preparation")
            || lower.contains("music audition") || lower.contains("recital preparation")
            || lower.contains("recital performance") || lower.contains("recital program")
            || lower.contains("applied music") || lower.contains("music jury")
            || (lower.contains("jury exam") && (lower.contains("music") || lower.contains("instrument") || lower.contains("piano") || lower.contains("violin") || lower.contains("cello") || lower.contains("guitar") || lower.contains("flute") || lower.contains("trumpet") || lower.contains("saxophone") || lower.contains("clarinet")))
            || lower.contains("orchestral excerpt") || lower.contains("solo repertoire")
            || lower.contains("practicing scales") || (lower.contains("scale practice") && lower.contains("instrument"))
            || word("etude") || word("etudes") || word("étude") || word("études")
            || lower.contains("piano lesson") || lower.contains("piano practice") || lower.contains("piano recital")
            || lower.contains("violin lesson") || lower.contains("violin practice") || lower.contains("violin recital")
            || lower.contains("cello lesson") || lower.contains("cello practice") || lower.contains("cello recital")
            || lower.contains("guitar lesson") || lower.contains("guitar practice") || lower.contains("guitar recital")
            || lower.contains("flute lesson") || lower.contains("flute practice") || lower.contains("flute recital")
            || lower.contains("trumpet lesson") || lower.contains("trumpet practice")
            || lower.contains("clarinet lesson") || lower.contains("clarinet practice")
            || lower.contains("oboe lesson") || lower.contains("oboe practice")
            || lower.contains("trombone lesson") || lower.contains("trombone practice")
            || lower.contains("viola lesson") || lower.contains("viola practice")
            || lower.contains("saxophone lesson") || lower.contains("saxophone practice")
            || lower.contains("drum lesson") || lower.contains("drum practice")
            || lower.contains("bass lesson") || lower.contains("bass practice")
            || lower.contains("harp lesson") || lower.contains("harp practice")
            || lower.contains("voice lesson") || lower.contains("vocal lesson")
            || lower.contains("singing lesson") || lower.contains("singing practice")
            || (lower.contains("music lesson") && !lower.contains("music theory") && !lower.contains("music class") && !lower.contains("music course")) {
            return "appliedmusic"
        }
        // forestry — positioned BEFORE enviro so silviculture, dendrology, timber cruising,
        // and forest-management coursework route to a dedicated pool rather than generic eco/enviro.
        // Bare "tree" or "logging" alone NOT matched (computing log / too generic).
        if word("forestry") || word("silviculture") || word("silvicultural")
            || word("dendrology") || word("dendrologist")
            || lower.contains("timber cruising") || lower.contains("timber sale")
            || lower.contains("forest management") || lower.contains("forest inventory")
            || lower.contains("forest ecology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("assignment") || lower.contains("lab"))
            || lower.contains("urban forestry") || lower.contains("reforestation") || lower.contains("afforestation")
            || lower.contains("forest fire") && lower.contains("management")
            || lower.contains("wildfire management") && (lower.contains("forestry") || lower.contains("class") || lower.contains("course"))
            || lower.contains("forest resources") || lower.contains("forest policy")
            || lower.contains("forest science") || lower.contains("forest ranger") && (lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("exam"))
            || lower.contains("forestry class") || lower.contains("forestry course")
            || lower.contains("forestry program") || lower.contains("forestry exam")
            || lower.contains("forestry degree") || lower.contains("forestry major")
            || lower.contains("forestry school") || lower.contains("forestry lab")
            || lower.contains("log scaling") || lower.contains("timber harvesting") && (lower.contains("class") || lower.contains("course") || lower.contains("plan") || lower.contains("exam"))
            || lower.contains("forest carbon") || lower.contains("carbon sequestration") && lower.contains("forest")
            || lower.contains("watershed management") && lower.contains("forestry")
            || lower.contains("national forest") && (lower.contains("class") || lower.contains("internship") || lower.contains("assignment")) {
            return "forestry"
        }
        // aquaticscience — positioned BEFORE enviro so aquaculture, fisheries biology, and
        // limnology route here rather than to generic ecology/enviro callouts.
        // Bare "aquatic" alone NOT matched without educational/management context.
        if word("aquaculture") || lower.contains("aquaculture science")
            || lower.contains("aquaculture management") || lower.contains("aquaculture program")
            || lower.contains("aquaculture class") || lower.contains("aquaculture course")
            || lower.contains("aquaculture lab") || lower.contains("aquaculture exam")
            || lower.contains("fisheries biology") || lower.contains("fisheries science")
            || lower.contains("fisheries management") || lower.contains("fisheries ecology")
            || lower.contains("fisheries resource") || lower.contains("marine fisheries")
            || lower.contains("freshwater fisheries") || lower.contains("fisheries class")
            || lower.contains("fisheries course") || lower.contains("fisheries program")
            || lower.contains("fisheries exam") || lower.contains("fisheries lab")
            || word("limnology") || lower.contains("limnology class") || lower.contains("limnology course")
            || lower.contains("limnology lab") || lower.contains("limnology exam")
            || lower.contains("marine resource management") || lower.contains("aquatic resource management")
            || lower.contains("fish hatchery") || lower.contains("fish biology")
            || lower.contains("fish population") && (lower.contains("class") || lower.contains("study") || lower.contains("management") || lower.contains("ecology"))
            || lower.contains("aquatic science") || lower.contains("aquatic ecology")
            || lower.contains("aquatic biology") || lower.contains("aquatic toxicology")
            || lower.contains("aquatic invasive species") || lower.contains("aquatic systems")
            || lower.contains("fisheries and wildlife") || lower.contains("wildlife and fisheries") {
            return "aquaticscience"
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
        // animalhusbandry — positioned AFTER horsemanship, BEFORE veterinary so livestock
        // production, swine/poultry/beef/dairy science, and farm animal management tasks route
        // here rather than the veterinary medicine pool. Bare "animal science" stays in veterinary.
        if lower.contains("animal husbandry")
            || lower.contains("livestock management") || lower.contains("livestock production")
            || lower.contains("livestock class") || lower.contains("livestock course")
            || lower.contains("livestock exam") || lower.contains("livestock notes")
            || lower.contains("swine production") || lower.contains("swine management")
            || lower.contains("swine science") || lower.contains("swine class") || lower.contains("swine course")
            || lower.contains("poultry science") || lower.contains("poultry production")
            || lower.contains("poultry management") || lower.contains("poultry class") || lower.contains("poultry course")
            || lower.contains("beef cattle production") || lower.contains("beef cattle management")
            || lower.contains("beef production class") || lower.contains("beef cattle class")
            || lower.contains("dairy science") || lower.contains("dairy cattle") || lower.contains("dairy production class")
            || lower.contains("sheep production") || lower.contains("sheep management") || lower.contains("sheep science")
            || lower.contains("goat production") || lower.contains("goat management") || lower.contains("goat science")
            || lower.contains("animal production class") || lower.contains("animal production course")
            || lower.contains("animal production exam") || lower.contains("animal production program")
            || lower.contains("animal agriculture") || lower.contains("ag animal")
            || lower.contains("feedlot management") || lower.contains("feed formulation class")
            || (lower.contains("farm management") && (lower.contains("livestock") || lower.contains("animal") || lower.contains("production"))) {
            return "animalhusbandry"
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
        // cosmeticchemistry — positioned BEFORE pharmacy so cosmetic science programs,
        // personal-care formulation coursework, and SCC certification prep route here.
        // "pharmacology" and "compounding" stay in pharmacy. "skincare" alone NOT matched
        // (too broad); requires chemistry/formulation/science context.
        if lower.contains("cosmetic chemistry") || lower.contains("cosmetic chemist")
            || lower.contains("cosmetic science") || lower.contains("cosmetic formulation")
            || lower.contains("cosmetic scientist") || lower.contains("cosmetic ingredients")
            || lower.contains("cosmetic ingredient") || lower.contains("cosmetics class") && lower.contains("chemist")
            || lower.contains("personal care formulation") || lower.contains("personal care chemistry")
            || lower.contains("beauty chemistry") || lower.contains("beauty science") && lower.contains("degree")
            || lower.contains("beauty science program") || lower.contains("beauty science class")
            || lower.contains("cosmetic science degree") || lower.contains("cosmetic science program")
            || lower.contains("cosmetic science class") || lower.contains("cosmetic science course")
            || lower.contains("cosmetic science exam") || lower.contains("cosmetic science school")
            || word("pcpc") && (lower.contains("cosmetic") || lower.contains("formul"))
            || word("scc") && (lower.contains("cosmetic") || lower.contains("formul") || lower.contains("chemist"))
            || lower.contains("society of cosmetic chemists")
            || lower.contains("emulsion formulation") && (lower.contains("cosmetic") || lower.contains("skincare") || lower.contains("personal care"))
            || lower.contains("skincare formulation") || lower.contains("skincare chemistry")
            || lower.contains("haircare formulation") || lower.contains("hair care formulation")
            || lower.contains("surfactant chemistry") && (lower.contains("cosmetic") || lower.contains("personal care"))
            || lower.contains("formulation lab") && (lower.contains("cosmetic") || lower.contains("beauty") || lower.contains("personal care"))
            || lower.contains("cosmetic lab") && lower.contains("formul")
            || lower.contains("preservative system") && (lower.contains("cosmetic") || lower.contains("formul") || lower.contains("personal care")) {
            return "cosmeticchemistry"
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
        // biochemistry — positioned AFTER molecularbiology and BEFORE geneticcounseling.
        // Catches biochemistry lab/course work with specific enzyme-kinetics and assay terms.
        // Bare word("biochemistry") alone stays in premed (MCAT context); compound lab terms fire here.
        if lower.contains("biochemistry lab") || lower.contains("biochemistry class")
            || lower.contains("biochemistry course") || lower.contains("biochemistry exam")
            || lower.contains("biochemistry report") || lower.contains("biochemistry program")
            || lower.contains("biochemistry major") || lower.contains("biochemistry degree")
            || lower.contains("biochemistry notes") && lower.contains("class")
            || lower.contains("enzyme kinetics") || lower.contains("michaelis-menten")
            || lower.contains("michaelis menten") || lower.contains("km and vmax")
            || lower.contains("bradford assay") || lower.contains("biuret assay")
            || lower.contains("spectrophotometry") && (lower.contains("biochem") || lower.contains("class"))
            || lower.contains("protein assay") && !lower.contains("molecular biology")
            || lower.contains("enzyme assay") || lower.contains("substrate concentration") && lower.contains("biochem")
            || lower.contains("metabolic pathway analysis") && !lower.contains("bioinformatics")
            || lower.contains("biochemistry textbook") || lower.contains("lehninger") {
            return "biochemistry"
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
        // radiationtherapy — positioned AFTER radiologictechnology and BEFORE nuclearmedtech so
        // radiation therapy tech/oncology coursework, ARRT-T prep, and dosimetry classes route here.
        if lower.contains("radiation therapy") || lower.contains("radiation therapist")
            || lower.contains("radiation technologist") && (lower.contains("therapy") || lower.contains("oncology") || lower.contains("treatment"))
            || word("rtt") && (lower.contains("exam") || lower.contains("certification") || lower.contains("program") || lower.contains("class") || lower.contains("board") || lower.contains("notes") || lower.contains("course"))
            || lower.contains("arrt-t") || lower.contains("arrt radiation therapy")
            || lower.contains("radiation oncology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("rotation") || lower.contains("notes") || lower.contains("program"))
            || lower.contains("radiation dosimetrist") || lower.contains("dosimetrist")
            || lower.contains("dosimetry class") || lower.contains("dosimetry course") || lower.contains("dosimetry exam")
            || lower.contains("treatment planning class") || lower.contains("treatment planning course")
            || lower.contains("radiation treatment planning") || lower.contains("imrt class") || lower.contains("vmat class")
            || lower.contains("linear accelerator class") || lower.contains("linear accelerator course")
            || word("linac") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("brachytherapy class") || lower.contains("brachytherapy course")
            || lower.contains("cbct class") || lower.contains("image guided radiation")
            || lower.contains("radiation therapy school") || lower.contains("radiation therapy program")
            || lower.contains("radiation therapy class") || lower.contains("radiation therapy exam")
            || lower.contains("radiation therapy certification") || lower.contains("radiation therapy notes")
            || lower.contains("therapeutic radiology class") || lower.contains("therapeutic radiation class") {
            return "radiationtherapy"
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
        // osteopathicmedicine — positioned AFTER physicianassistant and BEFORE paramedicine so
        // DO student coursework, COMLEX exam prep, and osteopathic manipulative medicine (OMM)
        // sessions route here. "osteopathic" alone fires only when combined with medicine/school
        // terms to avoid false positives in general anatomy or biomechanics contexts.
        if lower.contains("osteopathic medicine") || lower.contains("osteopathic medical")
            || lower.contains("osteopathic physician") || lower.contains("osteopathic doctor")
            || lower.contains("osteopathic school") || lower.contains("osteopathic program")
            || lower.contains("osteopathic class") || lower.contains("osteopathic course")
            || lower.contains("osteopathic exam") || lower.contains("osteopathic rotation")
            || lower.contains("osteopathic clerkship") || lower.contains("osteopathic clinical")
            || lower.contains("osteopathic notes") || lower.contains("osteopathic internship")
            || lower.contains("osteopathic residency") || lower.contains("osteopathic assignment")
            || lower.contains("do school") && lower.contains("osteo")
            || lower.contains("do program") && lower.contains("osteo")
            || word("comlex") || lower.contains("comlex exam") || lower.contains("comlex level")
            || lower.contains("comlex-usa") || lower.contains("comlex board")
            || word("omm") && (lower.contains("osteo") || lower.contains("manipulat") || lower.contains("technique") || lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("session"))
            || lower.contains("osteopathic manipulative") || lower.contains("osteopathic manipulation")
            || lower.contains("cranial osteopathy") || lower.contains("counterstrain technique")
            || lower.contains("muscle energy technique") && (lower.contains("osteo") || lower.contains("omm"))
            || lower.contains("high velocity low amplitude") || lower.contains("hvla technique")
            || lower.contains("myofascial release") && (lower.contains("osteo") || lower.contains("omm"))
            || lower.contains("somatic dysfunction") || lower.contains("somatic dysfunctions")
            || lower.contains("doctor of osteopathic") || lower.contains("osteopathic medical school")
            || lower.contains("com1") || lower.contains("com2") || lower.contains("com3") || lower.contains("com4") {
            return "osteopathicmedicine"
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
        // emergencynursing — positioned BEFORE nursing so CEN exam, ENPC/TNCC, trauma nursing,
        // and ER-nurse-specific tasks route here rather than to the broader nursing callout pool.
        if lower.contains("emergency nursing") || lower.contains("emergency nurse")
            || lower.contains("emergency department nurse") || lower.contains("emergency room nurse")
            || lower.contains("emergency room nursing") || lower.contains("er nurse") && !lower.contains("er nursing informatics")
            || lower.contains("er nursing") && !lower.contains("er nursing informatics")
            || word("cen") && (lower.contains("exam") || lower.contains("certification") || lower.contains("board") || lower.contains("credential") || lower.contains("prep") || lower.contains("study"))
            || word("enpc") || lower.contains("enpc exam") || lower.contains("enpc certification")
            || word("tncc") || lower.contains("tncc exam") || lower.contains("tncc certification")
            || lower.contains("trauma nursing") || lower.contains("trauma nurse")
            || lower.contains("emergency nursing program") || lower.contains("emergency nursing class")
            || lower.contains("emergency nursing course") || lower.contains("emergency nursing certification")
            || lower.contains("emergency nursing exam") || lower.contains("emergency nursing assignment")
            || lower.contains("mass casualty") && lower.contains("nursing")
            || lower.contains("triage nursing") || lower.contains("triage nurse")
            || lower.contains("code blue") && lower.contains("nursing")
            || lower.contains("resuscitation nursing") || lower.contains("rapid assessment nurse") {
            return "emergencynursing"
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
        // childlife — positioned BEFORE musictherapy and other creative-therapy branches so
        // child life specialist, CCLS board exam, and pediatric hospital child life tasks route here.
        // "pediatric nursing" stays in nursing (fires earlier). Bare "pediatric" NOT matched alone.
        if lower.contains("child life specialist") || lower.contains("child life therapy")
            || lower.contains("child life program") || lower.contains("child life class")
            || lower.contains("child life course") || lower.contains("child life exam")
            || lower.contains("child life internship") || lower.contains("child life clinical")
            || lower.contains("child life certification") || lower.contains("child life notes")
            || lower.contains("child life assignment") || lower.contains("child life school")
            || word("ccls") && (lower.contains("exam") || lower.contains("board") || lower.contains("certification") || lower.contains("prep") || lower.contains("credential") || lower.contains("study"))
            || word("aclp") && (lower.contains("child") || lower.contains("life") || lower.contains("certification"))
            || lower.contains("therapeutic play") && (lower.contains("child") || lower.contains("hospital") || lower.contains("pediatric") || lower.contains("specialist"))
            || lower.contains("hospital child life") || lower.contains("pediatric child life")
            || lower.contains("child life internship notes") || lower.contains("child life session notes")
            || lower.contains("child life treatment plan") || lower.contains("child life case study") {
            return "childlife"
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
        // horticulturescience — positioned AFTER horticulturetherapy (fires first if therapy context
        // present) and BEFORE addictioncounseling so plant science, floriculture, arboriculture, and
        // PCA/ISA exam prep route to a dedicated horticulture-science callout pool.
        // Bare word("garden") stays in studying; compound educational/professional terms fire here.
        if lower.contains("horticulture science") || lower.contains("horticultural science")
            || lower.contains("horticulture degree") || lower.contains("horticulture major")
            || lower.contains("horticulture class") || lower.contains("horticulture course")
            || lower.contains("horticulture exam") || lower.contains("horticulture program")
            || lower.contains("horticulture school") || lower.contains("horticulture assignment")
            || lower.contains("horticulture notes") || lower.contains("horticulture certification")
            || lower.contains("horticulture license") || word("horticulturist") || word("horticulturists")
            || lower.contains("plant science class") || lower.contains("plant science course")
            || lower.contains("plant science exam") || lower.contains("plant science program")
            || lower.contains("plant science degree") || lower.contains("plant science major")
            || lower.contains("ornamental horticulture") || lower.contains("nursery management class")
            || lower.contains("turf management class") || lower.contains("turfgrass science")
            || lower.contains("floriculture class") || lower.contains("floriculture course")
            || lower.contains("pomology class") || lower.contains("olericulture class")
            || lower.contains("arboriculture class") || lower.contains("arboriculture course")
            || lower.contains("arboriculture exam") || word("arborist") && (lower.contains("class") || lower.contains("exam") || lower.contains("certification") || lower.contains("isa") || lower.contains("program"))
            || lower.contains("isa arborist") || lower.contains("isa certification") && lower.contains("arb")
            || lower.contains("pca exam") && !lower.contains("physician assistant") && !lower.contains("pa class")
            || lower.contains("pest control adviser") || lower.contains("pest management class")
            || lower.contains("integrated pest management class") || lower.contains("ipm class")
            || lower.contains("landscape horticulture") || lower.contains("urban horticulture") {
            return "horticulturescience"
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
        // behavioranalysis — positioned AFTER addictioncounseling and BEFORE socialwork so ABA,
        // BCBA, and behavior-analysis coursework route here. "behavior" alone is NOT matched.
        if word("bcba") || word("bcba-d") || lower.contains("bcba exam") || lower.contains("bcba certification")
            || lower.contains("bcba board") || lower.contains("bcba program") || lower.contains("bcba prep")
            || word("rbt") && (lower.contains("training") || lower.contains("exam") || lower.contains("certification") || lower.contains("program") || lower.contains("course") || lower.contains("notes"))
            || lower.contains("applied behavior analysis") || lower.contains("applied behaviour analysis")
            || lower.contains("behavior analysis class") || lower.contains("behavior analysis course")
            || lower.contains("behavior analysis exam") || lower.contains("behavior analysis program")
            || lower.contains("behaviour analysis class") || lower.contains("behaviour analysis course")
            || lower.contains("aba therapy") || lower.contains("aba program") || lower.contains("aba class")
            || lower.contains("aba course") || lower.contains("aba practicum") || lower.contains("aba notes")
            || lower.contains("aba training") || lower.contains("aba supervisor") || lower.contains("aba session")
            || word("bacb") || lower.contains("bacb exam") || lower.contains("bacb board")
            || lower.contains("verbal behavior class") || lower.contains("verbal behavior course")
            || lower.contains("behavior intervention plan") || lower.contains("behaviour intervention plan")
            || lower.contains("behavior support plan") || lower.contains("positive behavior support")
            || lower.contains("functional behavior assessment") || word("fba") && (lower.contains("behavior") || lower.contains("aba"))
            || lower.contains("discrete trial training") || lower.contains("discrete trial teaching") || word("dtt") && lower.contains("behavior")
            || lower.contains("behavior therapy class") || lower.contains("behavior therapy course")
            || lower.contains("behavior tech") || lower.contains("behaviour tech") {
            return "behavioranalysis"
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
        // audiology — positioned BEFORE speechpathology so AuD school, audiometric testing,
        // hearing science coursework, and PRAXIS audiology prep route here rather than to
        // speechpathology. "hearing" alone is NOT matched (too generic).
        if word("audiology") || word("audiologist") || word("audiologists") || word("audiometric")
            || lower.contains("aud degree") || lower.contains("au.d.") || lower.contains("au.d program")
            || lower.contains("audiology school") || lower.contains("audiology program")
            || lower.contains("audiology class") || lower.contains("audiology course")
            || lower.contains("audiology exam") || lower.contains("audiology clinic")
            || lower.contains("audiology externship") || lower.contains("audiology rotation")
            || lower.contains("audiology certification") || lower.contains("audiology board")
            || lower.contains("praxis audiology") || lower.contains("aud program")
            || lower.contains("hearing science") || lower.contains("hearing assessment")
            || lower.contains("audiometric testing") || lower.contains("audiogram")
            || lower.contains("hearing aids fitting") || lower.contains("hearing aid fitting")
            || lower.contains("cochlear implant class") || lower.contains("cochlear implant course")
            || lower.contains("hearing disorder") || lower.contains("balance disorder class")
            || lower.contains("pure tone audiometry") || lower.contains("speech audiometry")
            || lower.contains("auditory processing") || lower.contains("central auditory")
            || lower.contains("tinnitus class") || lower.contains("tinnitus management class")
            || lower.contains("vestibular class") || lower.contains("vestibular course")
            || lower.contains("newborn hearing screening") || lower.contains("pediatric audiology") {
            return "audiology"
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
        // publichealthnutrition — positioned AFTER behavioralhealthpromotion and BEFORE publicheath.
        // Catches community nutrition class/program, WIC counseling/education, maternal and infant
        // nutrition courses, and public health nutrition degree programs. Bare "nutrition" alone
        // fires the nutrition branch much earlier; this catches the public-health intersection.
        if lower.contains("community nutrition") && (lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("exam") || lower.contains("assignment") || lower.contains("major") || lower.contains("degree"))
            || lower.contains("public health nutrition") || lower.contains("public health dietitian")
            || lower.contains("public health dietetics") || lower.contains("public health registered dietitian")
            || lower.contains("wic counseling") || lower.contains("wic nutrition") || lower.contains("wic education")
            || lower.contains("wic class") || lower.contains("wic course") || lower.contains("wic program") && (lower.contains("nutrition") || lower.contains("class") || lower.contains("internship") || lower.contains("rotation"))
            || lower.contains("nutrition education program") || lower.contains("nutrition education class")
            || lower.contains("nutrition education course") || lower.contains("nutrition policy")
            || lower.contains("nutrition surveillance") || lower.contains("dietary surveillance")
            || lower.contains("maternal nutrition") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("program"))
            || lower.contains("infant nutrition") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("program"))
            || lower.contains("food security") && (lower.contains("nutrition") || lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("policy"))
            || lower.contains("community dietitian") || lower.contains("community dietetics")
            || lower.contains("population nutrition") || lower.contains("global nutrition") {
            return "publichealthnutrition"
        }
        // environmentalhealth — positioned AFTER publichealthnutrition and BEFORE publicheath.
        // Catches REHS exam prep, sanitarian certification, food inspection class, environmental
        // toxicology/epidemiology coursework, and occupational/environmental health programs.
        // "environmental health" terms here intercept before publicheath's bare catch-all.
        if (lower.contains("environmental health") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("program") || lower.contains("science") || lower.contains("major") || lower.contains("degree") || lower.contains("certification")))
            || word("rehs") || lower.contains("rehs exam") || lower.contains("rehs certification")
            || lower.contains("registered environmental health specialist")
            || word("sanitarian") || lower.contains("sanitarian exam") || lower.contains("sanitarian certification")
            || lower.contains("environmental health science") || lower.contains("environmental health officer")
            || lower.contains("food inspection class") || lower.contains("food inspection course")
            || lower.contains("food inspector class") || lower.contains("food safety inspector class")
            || lower.contains("food safety inspector exam")
            || lower.contains("environmental toxicology class") || lower.contains("environmental toxicology course") || lower.contains("environmental toxicology exam")
            || lower.contains("environmental epidemiology class") || lower.contains("environmental epidemiology course")
            || lower.contains("water quality testing class") || lower.contains("water quality testing course")
            || lower.contains("environmental health law") || lower.contains("environmental health policy class")
            || (lower.contains("occupational and environmental health") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || lower.contains("community environmental health") {
            return "environmentalhealth"
        }
        // epidemiology — positioned BEFORE publicheath so graduate-level epidemiology research,
        // outbreak investigation coursework, disease surveillance assignments, and epi methods
        // classes get a dedicated pool. "environmental epidemiology" stays in environmentalhealth
        // (fires earlier). Bare "epidemic" or "disease" NOT matched alone.
        if word("epidemiology") || word("epidemiologist") || word("epidemiological")
            || lower.contains("epi methods") || lower.contains("epi research")
            || lower.contains("outbreak investigation") || lower.contains("outbreak analysis")
            || lower.contains("disease surveillance") || lower.contains("surveillance data")
            || lower.contains("case-control study") || lower.contains("case control study")
            || lower.contains("cohort study") && (lower.contains("class") || lower.contains("course") || lower.contains("epi") || lower.contains("assignment") || lower.contains("exam"))
            || lower.contains("cross-sectional study") && (lower.contains("class") || lower.contains("course") || lower.contains("epi") || lower.contains("assignment"))
            || lower.contains("incidence rate") && (lower.contains("class") || lower.contains("course") || lower.contains("epi") || lower.contains("assignment"))
            || lower.contains("prevalence study") || lower.contains("epi curve")
            || lower.contains("contact tracing") && (lower.contains("class") || lower.contains("course") || lower.contains("epi") || lower.contains("assignment"))
            || lower.contains("attributable risk") || lower.contains("relative risk") && (lower.contains("class") || lower.contains("course") || lower.contains("epi"))
            || lower.contains("odds ratio") && (lower.contains("class") || lower.contains("course") || lower.contains("epi") || lower.contains("assignment"))
            || lower.contains("epidemiology class") || lower.contains("epidemiology course")
            || lower.contains("epidemiology exam") || lower.contains("epidemiology lab")
            || lower.contains("epidemiology assignment") || lower.contains("epidemiology paper")
            || lower.contains("epidemiology project") || lower.contains("epidemiology notes")
            || lower.contains("epi class") || lower.contains("epi course") || lower.contains("epi exam")
            || lower.contains("epi assignment") || lower.contains("epi project") || lower.contains("epi notes")
            || word("biostatistics") || lower.contains("biostatistics class") || lower.contains("biostatistics course")
            || lower.contains("biostatistics exam") || lower.contains("biostatistics assignment") {
            return "epidemiology"
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
        // globalhealthdev — positioned AFTER publicheath (which owns bare "global health") and BEFORE
        // emergencymanagement so international-development policy, NGO program management, USAID,
        // and development-economics coursework route to a dedicated pool rather than publicheath.
        // "global health" alone stays in publicheath; compound development/NGO terms fire here.
        if lower.contains("international development") || lower.contains("development economics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("program") || lower.contains("policy"))
            || lower.contains("global development") || lower.contains("development policy")
            || lower.contains("development cooperation") || lower.contains("aid effectiveness")
            || word("usaid") || lower.contains("usaid program") || lower.contains("usaid project")
            || lower.contains("world bank development") || lower.contains("development finance")
            || lower.contains("ngo management") || lower.contains("ngo program")
            || lower.contains("ngo project") || lower.contains("humanitarian program")
            || lower.contains("international aid") || lower.contains("foreign aid program")
            || lower.contains("global health governance") || lower.contains("global health financing")
            || lower.contains("global health policy") && lower.contains("development")
            || lower.contains("sustainable development goals") || lower.contains("sdg")
            || lower.contains("poverty alleviation") || lower.contains("international development class")
            || lower.contains("international development course") || lower.contains("international development exam")
            || lower.contains("international development program") || lower.contains("international development major")
            || lower.contains("development studies class") || lower.contains("development studies course")
            || lower.contains("development studies exam") || lower.contains("development studies program")
            || lower.contains("global health development class") || lower.contains("global health development course")
            || lower.contains("humanitarian logistics") || lower.contains("humanitarian coordination")
            || lower.contains("global south") && (lower.contains("class") || lower.contains("development") || lower.contains("policy"))
            || lower.contains("monitoring and evaluation") && (lower.contains("development") || lower.contains("ngo") || lower.contains("program"))
            || lower.contains("m&e") && (lower.contains("development") || lower.contains("ngo")) {
            return "globalhealthdev"
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
        // internationalrelations — positioned BEFORE socialscience (which caught "international relations"
        // generically) so IR theory, foreign policy, diplomatic studies, and global governance courses
        // get their own pool. Bare "international relations" without educational context still falls
        // through to socialscience; compound educational phrases route here.
        if lower.contains("international relations class") || lower.contains("international relations course")
            || lower.contains("international relations exam") || lower.contains("international relations program")
            || lower.contains("international relations major") || lower.contains("international relations degree")
            || lower.contains("international relations assignment") || lower.contains("international relations paper")
            || lower.contains("ir theory") || lower.contains("ir class") || lower.contains("ir course")
            || lower.contains("ir exam") || lower.contains("ir major") || lower.contains("ir program")
            || lower.contains("foreign policy class") || lower.contains("foreign policy course")
            || lower.contains("foreign policy exam") || lower.contains("foreign policy analysis")
            || lower.contains("diplomatic studies") || lower.contains("diplomacy class") || lower.contains("diplomacy course")
            || lower.contains("area studies class") || lower.contains("area studies course") || lower.contains("area studies program")
            || lower.contains("international organizations class") || lower.contains("international organizations course")
            || lower.contains("global governance class") || lower.contains("global governance course")
            || lower.contains("world politics class") || lower.contains("world politics course") || lower.contains("world politics exam")
            || lower.contains("international security class") || lower.contains("international security course")
            || lower.contains("geopolitics class") || lower.contains("geopolitics course") || lower.contains("geopolitics exam")
            || lower.contains("international affairs class") || lower.contains("international affairs course")
            || lower.contains("international studies class") || lower.contains("international studies program")
            || lower.contains("international politics class") || lower.contains("international politics course")
            || lower.contains("realism") && (lower.contains("ir") || lower.contains("international relations") || lower.contains("class") || lower.contains("course"))
            || lower.contains("liberalism") && (lower.contains("ir") || lower.contains("international relations") || lower.contains("class") || lower.contains("course"))
            || lower.contains("constructivism") && (lower.contains("ir") || lower.contains("international relations") || lower.contains("class") || lower.contains("course")) {
            return "internationalrelations"
        }
        // socialscience — positioned after criminaljustice (which now owns criminology/criminal justice)
        // and before legal (LSAT is pre-law, not a bar-exam term). "social work" routes to socialwork.
        // "public administration" now has its own branch below (fires between theology and policy).
        // Note: word("sociology") is already in the studying branch — not repeated here.
        if lower.contains("political science") || lower.contains("poli sci")
            || word("anthropology") || word("anthropological")
            || lower.contains("ethnography") || lower.contains("ethnographic")
            || word("lsat")
            || lower.contains("pre-law") || word("prelaw")
            || lower.contains("public policy")
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
        // publicadministration — positioned AFTER theology and BEFORE policy so MPA programs,
        // local government courses, and nonprofit management classes route here. Distinct from
        // "public policy" (which stays in the policy branch) and the former "public administration"
        // catch in socialscience (now removed from that branch).
        if lower.contains("public administration class") || lower.contains("public administration course")
            || lower.contains("public administration exam") || lower.contains("public administration program")
            || lower.contains("public administration degree") || lower.contains("public administration major")
            || lower.contains("public administration assignment") || lower.contains("public administration paper")
            || word("mpa") && (lower.contains("program") || lower.contains("degree") || lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("mpa program") || lower.contains("mpa degree") || lower.contains("mpa class")
            || lower.contains("local government class") || lower.contains("local government course") || lower.contains("local government exam")
            || lower.contains("municipal government class") || lower.contains("city government class")
            || lower.contains("nonprofit management class") || lower.contains("nonprofit management course") || lower.contains("nonprofit management exam")
            || lower.contains("nonprofit administration class") || lower.contains("nonprofit administration course")
            || lower.contains("public sector management class") || lower.contains("public sector management course")
            || lower.contains("administrative law class") || lower.contains("administrative law course") || lower.contains("administrative law exam")
            || lower.contains("civil service exam") || lower.contains("civil service test") || lower.contains("civil service prep")
            || lower.contains("government administration class") || lower.contains("government administration course")
            || lower.contains("public management class") || lower.contains("public management course")
            || lower.contains("public budgeting class") || lower.contains("public finance class") || lower.contains("public finance course") {
            return "publicadministration"
        }
        // policy — positioned after socialscience and publicadministration, before legal. This
        // intercepts "policy brief" and "legislative brief" before legal's `word("brief")` fires.
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
        // bioethics — positioned AFTER publichealthlaw and BEFORE healthcarelaw so bioethics
        // research papers, IRB protocol work, clinical ethics consultations, and research-ethics
        // coursework get a dedicated pool. "bioethics class/course/exam" is intercepted here
        // (removing those from healthcarelaw below). Bare "ethics" alone NOT matched.
        if lower.contains("bioethics") || lower.contains("bio-ethics")
            || lower.contains("research ethics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("paper") || lower.contains("committee") || lower.contains("irb") || lower.contains("board") || lower.contains("research"))
            || lower.contains("irb protocol") || lower.contains("irb submission") || lower.contains("irb application")
            || lower.contains("irb approval") || lower.contains("irb review") || lower.contains("irb proposal")
            || lower.contains("institutional review board") || lower.contains("human subjects research")
            || lower.contains("human subjects protection") || lower.contains("human subjects committee")
            || lower.contains("clinical ethics") && (lower.contains("class") || lower.contains("course") || lower.contains("consultation") || lower.contains("committee") || lower.contains("case") || lower.contains("paper"))
            || lower.contains("ethics consultation") && (lower.contains("clinical") || lower.contains("hospital") || lower.contains("medical"))
            || lower.contains("medical ethics paper") || lower.contains("medical ethics essay")
            || lower.contains("medical ethics seminar") || lower.contains("medical ethics assignment")
            || lower.contains("ethics in medicine") || lower.contains("ethics in healthcare") || lower.contains("ethics in health care")
            || lower.contains("informed consent research") || lower.contains("research consent")
            || lower.contains("beneficence") && (lower.contains("class") || lower.contains("course") || lower.contains("paper") || lower.contains("bioethics") || lower.contains("ethics"))
            || lower.contains("nonmaleficence") && (lower.contains("class") || lower.contains("course") || lower.contains("paper") || lower.contains("ethics"))
            || lower.contains("justice in healthcare") || lower.contains("healthcare ethics")
            || lower.contains("patient autonomy") && (lower.contains("class") || lower.contains("course") || lower.contains("paper") || lower.contains("ethics"))
            || lower.contains("end-of-life ethics") || lower.contains("end of life ethics")
            || lower.contains("euthanasia ethics") || lower.contains("assisted dying ethics")
            || lower.contains("stem cell ethics") || lower.contains("genetic ethics") || lower.contains("genomic ethics")
            || lower.contains("principlism") || lower.contains("four principles") && lower.contains("bioethics")
            || lower.contains("belmont report") || lower.contains("declaration of helsinki")
            || lower.contains("tuskegee") && (lower.contains("class") || lower.contains("ethics") || lower.contains("paper") || lower.contains("research"))
            || lower.contains("research integrity") || lower.contains("responsible conduct of research") || lower.contains("rcr training") {
            return "bioethics"
        }
        // healthcarelaw — positioned BEFORE legal so health-law courses, HIPAA-as-law,
        // and medical malpractice tasks route here. "health policy" stays in the policy branch.
        if lower.contains("health law") || lower.contains("healthcare law") || lower.contains("medical law")
            || lower.contains("health care law") || lower.contains("healthcare regulation class")
            || lower.contains("healthcare regulation course") || lower.contains("healthcare regulation exam")
            || lower.contains("hipaa law") || lower.contains("hipaa class") || lower.contains("hipaa course")
            || lower.contains("hipaa exam") || lower.contains("hipaa certification")
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
        // paralegal — positioned BEFORE legal so ABA-accredited paralegal programs, CLA/CP
        // exam prep, and legal-assistant coursework route here rather than the law-school pool.
        if word("paralegal") || word("paralegals")
            || lower.contains("legal assistant") && (lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("certificate") || lower.contains("exam") || lower.contains("school") || lower.contains("notes") || lower.contains("certification"))
            || lower.contains("aba paralegal") || lower.contains("paralegal certificate")
            || lower.contains("paralegal certification") || lower.contains("paralegal program")
            || lower.contains("paralegal class") || lower.contains("paralegal course")
            || lower.contains("paralegal school") || lower.contains("paralegal exam")
            || lower.contains("paralegal studies") || lower.contains("paralegal notes")
            || lower.contains("paralegal degree") || lower.contains("paralegal major")
            || lower.contains("cla exam") && !lower.contains("clinical")
            || lower.contains("cp exam") && lower.contains("paralegal")
            || lower.contains("nala cert") && lower.contains("paralegal")
            || lower.contains("pace exam") && lower.contains("paralegal")
            || lower.contains("litigation support class") || lower.contains("e-discovery class")
            || lower.contains("legal technology class") && lower.contains("paralegal") {
            return "paralegal"
        }
        // laborlaw — positioned AFTER paralegal and BEFORE legal so employment law class, labor law
        // class, and HR law courses route here. "OSHA" in an engineering/safety context stays in
        // industrialsafety (fires much earlier). Bare "labor" or "employment" alone NOT matched.
        if lower.contains("employment law class") || lower.contains("employment law course")
            || lower.contains("employment law exam") || lower.contains("employment law assignment")
            || lower.contains("employment law paper") || lower.contains("employment law analysis")
            || lower.contains("labor law class") || lower.contains("labour law class")
            || lower.contains("labor law course") || lower.contains("labour law course")
            || lower.contains("labor law exam") || lower.contains("labour law exam")
            || lower.contains("labor law assignment") || lower.contains("labor law paper")
            || lower.contains("nlra class") || lower.contains("national labor relations act")
            || lower.contains("collective bargaining class") || lower.contains("collective bargaining course")
            || lower.contains("collective bargaining law") || lower.contains("collective bargaining agreement class")
            || lower.contains("fmla class") || lower.contains("fmla law") || lower.contains("fmla course")
            || lower.contains("osha regulation class") || lower.contains("osha law class") || lower.contains("osha compliance class")
            || lower.contains("workers compensation law") || lower.contains("workers' compensation law") || lower.contains("workers comp law class")
            || lower.contains("hr law class") || lower.contains("hr law course") || lower.contains("human resources law class")
            || lower.contains("employment discrimination law") || lower.contains("employment discrimination class")
            || lower.contains("employment discrimination course")
            || lower.contains("title vii class") || lower.contains("title vii course") || lower.contains("title vii law")
            || lower.contains("americans with disabilities act class") || lower.contains("ada employment class")
            || lower.contains("flsa class") || lower.contains("fair labor standards act class") || lower.contains("fair labor standards act course")
            || lower.contains("labor relations class") || lower.contains("labor relations course") || lower.contains("labor relations exam")
            || lower.contains("workplace law class") || lower.contains("employee rights law") || lower.contains("wage and hour law class") {
            return "laborlaw"
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
