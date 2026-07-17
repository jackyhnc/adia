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
        // socialentrepreneurship — positioned AFTER startup so "pitch deck"/"business plan" stay in
        // startup; catches social enterprise and impact-investing coursework that startup doesn't cover.
        // Bare "social impact" alone NOT matched (too broad); requires a compound educational term.
        if lower.contains("social enterprise") || lower.contains("social entrepreneur")
            || lower.contains("social entrepreneurship")
            || lower.contains("b corp") || lower.contains("b-corp") || lower.contains("benefit corporation")
            || lower.contains("impact investing") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("program") || lower.contains("assignment"))
            || lower.contains("social innovation") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("program") || lower.contains("assignment"))
            || lower.contains("social impact investing") || lower.contains("social venture")
            || lower.contains("social impact measurement") && (lower.contains("class") || lower.contains("course") || lower.contains("assignment"))
            || lower.contains("esg investing") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("assignment"))
            || lower.contains("triple bottom line") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("assignment"))
            || lower.contains("corporate social responsibility") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("assignment"))
            || lower.contains("social change") && lower.contains("venture")
            || lower.contains("microfinance") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("assignment"))
            || lower.contains("mission-driven") && (lower.contains("business") || lower.contains("startup") || lower.contains("venture") || lower.contains("enterprise")) {
            return "socialentrepreneurship"
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
        // informationassurance — positioned AFTER networkengineering and BEFORE quantumcomputing.
        // Catches information assurance degree programs, IA certification prep (CISM, CASP+,
        // CRISC, CGEIT, CISA-audit, CC), DoD 8570/8140 compliance coursework, RMF/NIST framework
        // classes, and cybersecurity governance classes. Distinct from cybersecurity (which handles
        // pentesting, SOC analyst, CTF, and offensive security tools). Bare "security" NOT matched.
        if lower.contains("information assurance")
            || (word("cism") && (lower.contains("exam") || lower.contains("cert") || lower.contains("class") || lower.contains("course") || lower.contains("study") || lower.contains("prep")))
            || lower.contains("casp+") || lower.contains("casp plus") || lower.contains("comptia casp")
            || lower.contains("advanced security practitioner")
            || (word("crisc") && (lower.contains("exam") || lower.contains("cert") || lower.contains("class") || lower.contains("course") || lower.contains("prep") || lower.contains("study")))
            || (word("cgeit") && (lower.contains("exam") || lower.contains("cert") || lower.contains("class") || lower.contains("course") || lower.contains("prep")))
            || lower.contains("dod 8570") || lower.contains("dod 8140") || lower.contains("dodd 8570")
            || lower.contains("dodd 8140") || lower.contains("dod directive 8570")
            || lower.contains("rmf class") || lower.contains("rmf course") || lower.contains("rmf training")
            || lower.contains("risk management framework class") || lower.contains("risk management framework course")
            || lower.contains("risk management framework certification") || lower.contains("risk management framework training")
            || lower.contains("nist csf class") || lower.contains("nist csf course")
            || lower.contains("nist framework class") || lower.contains("nist cybersecurity framework class")
            || lower.contains("security governance class") || lower.contains("security governance course")
            || lower.contains("cybersecurity governance class") || lower.contains("cybersecurity governance course")
            || lower.contains("information security governance class") || lower.contains("information security governance course")
            || lower.contains("ia certification") || lower.contains("ia program") || lower.contains("ia degree")
            || (word("cisa") && (lower.contains("exam") || lower.contains("cert") || lower.contains("class") || lower.contains("prep") || lower.contains("study"))) {
            return "informationassurance"
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
        // cryptography — positioned AFTER quantumcomputing (which owns quantum cryptography) and
        // BEFORE cloudcomputing. Catches number-theory-based crypto, AES/RSA algorithm classes,
        // elliptic-curve and public-key coursework, and applied cryptography programs.
        // "cryptography lab" stays in cybersecurity (fires earlier); bare "cryptography" without
        // edu context NOT matched here.
        if lower.contains("cryptography class") || lower.contains("cryptography course")
            || lower.contains("cryptography exam") || lower.contains("cryptography program")
            || lower.contains("cryptography assignment") || lower.contains("cryptography textbook")
            || lower.contains("cryptography major") || lower.contains("cryptography degree")
            || lower.contains("applied cryptography") || lower.contains("introduction to cryptography")
            || lower.contains("cryptanalysis class") || lower.contains("cryptanalysis course") || lower.contains("cryptanalysis exam")
            || (lower.contains("number theory") && (lower.contains("crypto") || lower.contains("rsa") || lower.contains("encryption") || lower.contains("cipher")))
            || lower.contains("aes algorithm") || lower.contains("rsa algorithm") || lower.contains("rsa encryption")
            || lower.contains("diffie-hellman") || lower.contains("diffie hellman")
            || lower.contains("elliptic curve cryptography") || lower.contains("elliptic curve crypto")
            || lower.contains("public key cryptography") || lower.contains("public-key cryptography")
            || (lower.contains("symmetric encryption") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || (lower.contains("asymmetric encryption") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || (lower.contains("block cipher") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("crypto")))
            || (lower.contains("stream cipher") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("crypto")))
            || (lower.contains("hash function") && (lower.contains("crypto") || lower.contains("class") || lower.contains("course")))
            || (lower.contains("digital signature") && (lower.contains("class") || lower.contains("course") || lower.contains("crypto")))
            || (lower.contains("cryptographic protocol") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || lower.contains("one-time pad") || lower.contains("vigenere cipher") {
            return "cryptography"
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
        // virtualreality — positioned BEFORE gamedev so VR/AR/XR development tasks route here
        // rather than to the generic game-dev pool. Bare word("unity") alone stays in gamedev;
        // only fires when explicitly combined with VR/AR/XR context.
        if lower.contains("vr development") || lower.contains("ar development")
            || lower.contains("xr development") || lower.contains("vr project")
            || lower.contains("ar project") || lower.contains("xr project")
            || lower.contains("vr app") || lower.contains("ar app") || lower.contains("xr app")
            || lower.contains("virtual reality development") || lower.contains("virtual reality project")
            || lower.contains("virtual reality app") || lower.contains("virtual reality class")
            || lower.contains("virtual reality course") || lower.contains("virtual reality program")
            || lower.contains("augmented reality development") || lower.contains("augmented reality class")
            || lower.contains("augmented reality project") || lower.contains("augmented reality app")
            || lower.contains("mixed reality") && (lower.contains("class") || lower.contains("course") || lower.contains("project") || lower.contains("development") || lower.contains("app"))
            || lower.contains("openxr") || lower.contains("open xr")
            || lower.contains("oculus development") || lower.contains("meta quest development")
            || lower.contains("quest development") && lower.contains("vr")
            || lower.contains("hololens") || lower.contains("holo lens")
            || lower.contains("webxr") || lower.contains("web xr")
            || lower.contains("spatial computing") && (lower.contains("class") || lower.contains("course") || lower.contains("project") || lower.contains("development"))
            || lower.contains("immersive experience development") || lower.contains("immersive application")
            || lower.contains("unity vr") || lower.contains("unity xr") || lower.contains("unity ar")
            || lower.contains("unreal vr") || lower.contains("unreal ar") || lower.contains("unreal xr")
            || lower.contains("vr class") || lower.contains("vr course") || lower.contains("vr exam")
            || lower.contains("ar class") || lower.contains("ar course") || lower.contains("xr class")
            || lower.contains("vr scene") || lower.contains("ar scene") || lower.contains("vr game")
            || lower.contains("ar filter") || lower.contains("ar overlay")
            || lower.contains("metaverse development") || lower.contains("metaverse class")
            || lower.contains("metaverse project") || lower.contains("metaverse course") {
            return "virtualreality"
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
        // healtheconomics — positioned AFTER certifiedfinancialplanner and BEFORE statistics so
        // pharmacoeconomics, HTA, QALY, and ICER study tasks route to a dedicated pool rather than
        // the generic economics branch (which also lists "health economics" but fires later).
        if lower.contains("health economics") || lower.contains("health economist")
            || lower.contains("pharmacoeconomics") || lower.contains("pharmacoeconomist")
            || lower.contains("cost-effectiveness analysis") && (lower.contains("health") || lower.contains("drug") || lower.contains("clinical") || lower.contains("medical"))
            || lower.contains("cost effectiveness analysis") && (lower.contains("health") || lower.contains("drug") || lower.contains("clinical") || lower.contains("medical"))
            || lower.contains("health technology assessment") || word("hta") && (lower.contains("health") || lower.contains("technology assessment") || lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || word("qaly") || lower.contains("qualys") && lower.contains("health")
            || word("icer") && (lower.contains("health") || lower.contains("cost") || lower.contains("effectiveness") || lower.contains("ratio"))
            || lower.contains("economic evaluation") && (lower.contains("health") || lower.contains("healthcare") || lower.contains("drug") || lower.contains("clinical") || lower.contains("medical"))
            || lower.contains("cost-benefit analysis") && (lower.contains("health") || lower.contains("healthcare") || lower.contains("medical") || lower.contains("clinical"))
            || lower.contains("burden of disease") || lower.contains("disease burden") && (lower.contains("class") || lower.contains("research") || lower.contains("analysis"))
            || lower.contains("willingness to pay") && (lower.contains("health") || lower.contains("healthcare") || lower.contains("drug") || lower.contains("medical"))
            || lower.contains("medical cost-effectiveness") || lower.contains("drug cost-effectiveness") {
            return "healtheconomics"
        }
        // biostatistics — positioned BEFORE statistics so clinical/biological stats (survival
        // analysis, Kaplan-Meier, Cox regression, power analysis, clinical trial design, odds
        // ratio, relative risk, Fisher's exact test in biology/clinical context) route to a
        // dedicated pool. Generic stats tools (SPSS, STATA, linear regression alone) stay in
        // statistics (fires after).
        if lower.contains("survival analysis") && (lower.contains("biostat") || lower.contains("clinical") || lower.contains("class") || lower.contains("course") || lower.contains("biology") || lower.contains("exam"))
            || lower.contains("kaplan-meier") || lower.contains("kaplan meier")
            || lower.contains("cox regression") || lower.contains("cox proportional hazard") || lower.contains("cox model")
            || lower.contains("biostatistics") || lower.contains("biostatistician")
            || lower.contains("clinical trial design") || lower.contains("clinical trial analysis") || lower.contains("clinical trial class") || lower.contains("clinical trial course")
            || lower.contains("clinical trial statistics") || lower.contains("clinical trial data")
            || lower.contains("power analysis") && (lower.contains("clinical") || lower.contains("biology") || lower.contains("biostat") || lower.contains("class") || lower.contains("sample size"))
            || lower.contains("sample size calculation") && (lower.contains("clinical") || lower.contains("biology") || lower.contains("biostat") || lower.contains("trial"))
            || lower.contains("odds ratio") && (lower.contains("class") || lower.contains("biostat") || lower.contains("clinical") || lower.contains("epidemiology") || lower.contains("exam"))
            || lower.contains("relative risk") && (lower.contains("class") || lower.contains("biostat") || lower.contains("clinical") || lower.contains("epidemiology") || lower.contains("exam"))
            || lower.contains("number needed to treat") || lower.contains("nnt") && (lower.contains("clinical") || lower.contains("biostat") || lower.contains("class"))
            || lower.contains("fisher's exact") || lower.contains("fishers exact") && (lower.contains("biology") || lower.contains("biostat") || lower.contains("class"))
            || lower.contains("mann-whitney") && (lower.contains("biology") || lower.contains("biostat") || lower.contains("class") || lower.contains("clinical"))
            || lower.contains("wilcoxon") && (lower.contains("biology") || lower.contains("biostat") || lower.contains("class") || lower.contains("clinical"))
            || lower.contains("meta-analysis") && (lower.contains("clinical") || lower.contains("biostat") || lower.contains("class") || lower.contains("systematic review"))
            || lower.contains("systematic review") && (lower.contains("biostat") || lower.contains("clinical") || lower.contains("class") || lower.contains("meta"))
            || lower.contains("biostat class") || lower.contains("biostat course") || lower.contains("biostat exam")
            || lower.contains("biostat homework") || lower.contains("biostat problem set")
            || lower.contains("biostats class") || lower.contains("biostats course") || lower.contains("biostats exam") {
            return "biostatistics"
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
        // economics — positioned AFTER statistics and BEFORE astronomy so macroeconomics,
        // microeconomics, econometrics, and economics class/course terms route to a dedicated pool.
        // word("economics") catches the discipline name directly. Bare "economy" NOT matched.
        if word("economics") || word("economist") || word("econometrics")
            || lower.contains("macroeconomics") || lower.contains("microeconomics")
            || lower.contains("principles of economics") || lower.contains("intro to economics")
            || lower.contains("introductory economics") || lower.contains("intermediate microeconomics")
            || lower.contains("intermediate macroeconomics")
            || lower.contains("econ class") || lower.contains("econ course")
            || lower.contains("econ exam") || lower.contains("econ homework")
            || lower.contains("econ assignment") || lower.contains("econ paper")
            || lower.contains("econ major") || lower.contains("econ thesis")
            || lower.contains("economics class") || lower.contains("economics course")
            || lower.contains("economics exam") || lower.contains("economics assignment")
            || lower.contains("economics paper") || lower.contains("economics major")
            || lower.contains("economics degree") || lower.contains("economics program")
            || lower.contains("economics research") || lower.contains("economics thesis")
            || lower.contains("ap economics") || lower.contains("ap macro") || lower.contains("ap micro")
            || lower.contains("gre economics") || lower.contains("gre econ")
            || lower.contains("econometrics class") || lower.contains("econometrics course")
            || lower.contains("econometrics exam") || lower.contains("econometrics homework")
            || lower.contains("labor economics") || lower.contains("health economics")
            || lower.contains("environmental economics") || lower.contains("public economics")
            || lower.contains("game theory class") || lower.contains("game theory course")
            || lower.contains("game theory exam") || lower.contains("game theory homework")
            || lower.contains("monetary economics") || lower.contains("international economics")
            || lower.contains("economics problem set") || lower.contains("econ problem set") {
            return "economics"
        }
        // astrobiology — positioned BEFORE astronomy so extremophiles, prebiotic chemistry, SETI
        // science, and planetary habitability research route here rather than to astronomy's
        // observational pool. word("astrobiology") removed from astronomy branch and owned here.
        if word("astrobiology") || word("astrobiologist") || word("astrobiologists")
            || lower.contains("extremophile") || lower.contains("extremophiles")
            || lower.contains("prebiotic chemistry") || lower.contains("prebiotic molecule")
            || lower.contains("origin of life") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("research") || lower.contains("exam"))
            || lower.contains("planetary habitability") || lower.contains("habitable zone") && (lower.contains("class") || lower.contains("research") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("biosignature") || lower.contains("biosignatures")
            || word("panspermia")
            || (word("seti") && (lower.contains("class") || lower.contains("course") || lower.contains("research") || lower.contains("project") || lower.contains("science")))
            || lower.contains("hydrothermal vent") && (lower.contains("origin") || lower.contains("life") || lower.contains("class") || lower.contains("research"))
            || lower.contains("astrobiology class") || lower.contains("astrobiology course")
            || lower.contains("astrobiology exam") || lower.contains("astrobiology lab")
            || lower.contains("astrobiology research") || lower.contains("astrobiology program") {
            return "astrobiology"
        }
        // astronomylab — positioned BEFORE astronomy so specific observational/lab astronomy tasks
        // (telescope observation sessions, star charts, light curve analysis) get a dedicated pool.
        // Generic "astronomy lab", "astronomy class" still route to astronomy (fires after).
        if lower.contains("observing run") && (lower.contains("astronomy") || lower.contains("telescope") || lower.contains("observatory") || lower.contains("lab"))
            || lower.contains("star chart") && (lower.contains("lab") || lower.contains("astronomy") || lower.contains("class") || lower.contains("plot") || lower.contains("draw"))
            || lower.contains("star charts") && (lower.contains("lab") || lower.contains("astronomy") || lower.contains("class"))
            || lower.contains("telescope observation") && (lower.contains("lab") || lower.contains("report") || lower.contains("session") || lower.contains("data"))
            || lower.contains("telescope observations") && (lower.contains("lab") || lower.contains("report"))
            || lower.contains("magnitude measurement") && (lower.contains("astronomy") || lower.contains("lab") || lower.contains("telescope"))
            || lower.contains("stellar magnitude") && (lower.contains("lab") || lower.contains("astronomy") || lower.contains("measure") || lower.contains("calculate"))
            || lower.contains("light curve") && (lower.contains("astronomy") || lower.contains("lab") || lower.contains("telescope") || lower.contains("variable star"))
            || lower.contains("light curves") && (lower.contains("astronomy") || lower.contains("lab") || lower.contains("telescope"))
            || lower.contains("celestial coordinates") && (lower.contains("lab") || lower.contains("astronomy") || lower.contains("class") || lower.contains("calculate"))
            || lower.contains("astronomical calculations") && (lower.contains("lab") || lower.contains("astronomy") || lower.contains("class"))
            || lower.contains("observatory session") && (lower.contains("astronomy") || lower.contains("lab") || lower.contains("report"))
            || lower.contains("observatory report") && (lower.contains("astronomy") || lower.contains("lab"))
            || lower.contains("sky survey") && (lower.contains("astronomy") || lower.contains("lab") || lower.contains("telescope"))
            || lower.contains("stellar spectrum") && (lower.contains("lab") || lower.contains("astronomy") || lower.contains("measure"))
            || lower.contains("spectrograph lab") && (lower.contains("astronomy") || lower.contains("stellar") || lower.contains("spec"))
            || lower.contains("photometry lab") && (lower.contains("astronomy") || lower.contains("stellar") || lower.contains("ccd")) {
            return "astronomylab"
        }
        // astrophysics — positioned BEFORE astronomy to intercept research-level astrophysical
        // signals and bare word("astrophysics"). word("astrophysics"/"astrophysicist"/
        // "astrophysicists") removed from astronomy and owned here. "astrophysics class/course/
        // exam/homework" also owned here so astrophysics inputs always reach this dedicated pool.
        if word("astrophysics") || word("astrophysicist") || word("astrophysicists")
            || lower.contains("cosmological simulation") || lower.contains("cosmological simulations")
            || lower.contains("n-body simulation") || lower.contains("nbody simulation")
            || lower.contains("n-body problem") && (lower.contains("astrophysics") || lower.contains("stellar") || lower.contains("orbital") || lower.contains("gravity"))
            || lower.contains("stellar evolution research") || lower.contains("stellar structure research")
            || lower.contains("stellar population synthesis") || lower.contains("stellar population model")
            || lower.contains("galactic dynamics") || lower.contains("galaxy dynamics")
            || lower.contains("active galactic nuclei") || lower.contains("active galactic nucleus")
            || lower.contains("agn feedback") || lower.contains("agn research") || lower.contains("agn jet")
            || lower.contains("gravitational wave") && (lower.contains("data") || lower.contains("analysis") || lower.contains("detection") || lower.contains("signal") || lower.contains("research"))
            || lower.contains("gravitational waves") && (lower.contains("data") || lower.contains("analysis") || lower.contains("detection") || lower.contains("merger"))
            || lower.contains("ligo data") || lower.contains("ligo analysis") || lower.contains("ligo signal")
            || lower.contains("interstellar medium") && (lower.contains("research") || lower.contains("analysis") || lower.contains("simulation") || lower.contains("astrophysics"))
            || lower.contains("quasar") && (lower.contains("research") || lower.contains("analysis") || lower.contains("data") || lower.contains("spectra") || lower.contains("astrophysics"))
            || lower.contains("black hole accretion") || lower.contains("accretion disk") && (lower.contains("astrophysics") || lower.contains("black hole") || lower.contains("neutron star"))
            || lower.contains("neutron star merger") || lower.contains("neutron star binary")
            || lower.contains("supernova simulation") || lower.contains("supernova research")
            || lower.contains("numerical astrophysics") || lower.contains("computational astrophysics")
            || lower.contains("astrophysics class") || lower.contains("astrophysics course")
            || lower.contains("astrophysics homework") || lower.contains("astrophysics exam")
            || lower.contains("astrophysics problem set") || lower.contains("astrophysics research") {
            return "astrophysics"
        }
        // astronomy — positioned before studying so "astronomy exam" doesn't fall through to
        // the generic studying pool via word("exam"). Bare word("physics") stays in studying;
        // compound celestial/cosmological terms route here.
        // word("astrobiology") now owned by astrobiology branch above.
        // word("astrophysics"/"astrophysicist"/"astrophysicists") now owned by astrophysics above.
        if word("astronomy") || word("astronomer") || word("astronomers")
            || lower.contains("celestial mechanics") || word("cosmology") || word("cosmologist")
            || lower.contains("observational astronomy") || lower.contains("stellar physics")
            || lower.contains("stellar evolution") || lower.contains("stellar structure")
            || lower.contains("planetary science") || lower.contains("planetary formation")
            || word("exoplanet") || word("exoplanets")
            || lower.contains("orbital mechanics") || lower.contains("orbital dynamics")
            || lower.contains("radio astronomy") || lower.contains("astronomical observation")
            || lower.contains("astronomical imaging") || lower.contains("astronomical data")
            || word("observatory") || word("planetarium")
            || lower.contains("star formation")
            || lower.contains("galaxy formation") || lower.contains("galaxy evolution")
            || lower.contains("dark matter") || lower.contains("dark energy")
            || lower.contains("cosmological") || lower.contains("astr class")
            || lower.contains("astr course") || lower.contains("astr lab")
            || lower.contains("astr homework") || lower.contains("astronomy class")
            || lower.contains("astronomy course") || lower.contains("astronomy lab")
            || lower.contains("astronomy homework") || lower.contains("astronomy exam") {
            return "astronomy"
        }
        // appliedmathematics — positioned AFTER astronomy and BEFORE mathematics so "applied math",
        // "applied mathematics", differential-equations classes, scientific computing, and PDE
        // coursework route here. Pure math terms (abstract algebra, topology, number theory,
        // linear algebra, real analysis) stay in the mathematics branch.
        if lower.contains("applied mathematics") || lower.contains("applied math")
            || lower.contains("applied maths")
            || lower.contains("computational mathematics") || lower.contains("computational math")
            || lower.contains("scientific computing class") || lower.contains("scientific computing course")
            || lower.contains("scientific computing exam") || lower.contains("scientific computing lab")
            || (lower.contains("partial differential equations") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("assignment") || lower.contains("problem set") || lower.contains("homework")))
            || lower.contains("pde class") || lower.contains("pde course") || lower.contains("pde exam")
            || (lower.contains("ordinary differential equations") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || lower.contains("ode class") || lower.contains("ode course") || lower.contains("ode exam")
            || lower.contains("differential equations class") || lower.contains("differential equations course")
            || lower.contains("differential equations exam") || lower.contains("differential equations problem set")
            || lower.contains("differential equations homework")
            || lower.contains("mathematical modeling class") || lower.contains("mathematical modeling course")
            || lower.contains("mathematical modeling exam") || lower.contains("mathematical modeling assignment")
            || lower.contains("math modeling class") || lower.contains("math modeling course")
            || lower.contains("math modeling exam")
            || (lower.contains("finite element method") && (lower.contains("class") || lower.contains("course") || lower.contains("math") || lower.contains("applied")))
            || (lower.contains("finite difference method") && (lower.contains("class") || lower.contains("course") || lower.contains("math"))) {
            return "appliedmathematics"
        }
        // operationsresearch — positioned AFTER appliedmathematics and BEFORE mathematics.
        // Catches OR/MS coursework: linear programming, integer programming, queueing theory,
        // and simulation distinct from supplychain (logistics) and appliedmathematics (numerics).
        // "game theory algorithm" in code fires first; bare "simulation" NOT matched alone.
        if lower.contains("operations research")
            || lower.contains("management science") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("program"))
            || word("informs") && (lower.contains("class") || lower.contains("course") || lower.contains("research") || lower.contains("or"))
            || lower.contains("linear programming") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("problem"))
            || lower.contains("integer programming") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem"))
            || lower.contains("simplex method") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("transportation problem") && (lower.contains("or") || lower.contains("class") || lower.contains("course") || lower.contains("optimization"))
            || lower.contains("network flow") && (lower.contains("or") || lower.contains("class") || lower.contains("course") || lower.contains("optimization"))
            || lower.contains("queueing theory") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("queuing theory") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("stochastic optimization") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("deterministic optimization") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("or model") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("discrete event simulation") && (lower.contains("class") || lower.contains("course") || lower.contains("or"))
            || lower.contains("dynamic programming") && (lower.contains("or") || lower.contains("optimization class") || lower.contains("optimization course")) {
            return "operationsresearch"
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
        // historicallinguistics — positioned AFTER signlanguage and BEFORE linguistics so
        // diachronic, reconstruction, and etymology coursework routes here.
        // "historical linguistics" as a phrase stays in the linguistics branch (preserves existing routing).
        if lower.contains("diachronic linguistics") || lower.contains("diachronic language")
            || (lower.contains("language change") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("research") || lower.contains("paper") || lower.contains("assignment")))
            || lower.contains("proto-language") || lower.contains("protolanguage")
            || lower.contains("grimm's law") || lower.contains("grimms law") || lower.contains("grimm law")
            || lower.contains("verner's law") || lower.contains("verners law")
            || (lower.contains("sound change") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("linguistics")))
            || lower.contains("etymology class") || lower.contains("etymology course") || lower.contains("etymology exam")
            || (lower.contains("historical phonology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || lower.contains("language reconstruction")
            || lower.contains("ancestral language") || lower.contains("ancestor language")
            || (lower.contains("comparative method") && (lower.contains("linguistics") || lower.contains("language")))
            || (lower.contains("proto-indo-european") && !lower.contains("historical linguistics"))
            || lower.contains("pie language") || lower.contains("pie reconstruction") || lower.contains("pie phonology")
            || (lower.contains("morphological change") && (lower.contains("class") || lower.contains("course") || lower.contains("linguistics")))
            || (lower.contains("semantic change") && (lower.contains("class") || lower.contains("course") || lower.contains("linguistics"))) {
            return "historicallinguistics"
        }
        // cognitivelinguistics — positioned AFTER historicallinguistics and BEFORE linguistics so
        // cognitive grammar, construction grammar, conceptual metaphor theory, and frame semantics
        // route here. Generic linguistics terms (phonology, discourse, sociolinguistics) stay below.
        if lower.contains("cognitive linguistics") || lower.contains("cognitive grammar")
            || lower.contains("construction grammar") || lower.contains("conceptual metaphor theory")
            || lower.contains("conceptual metaphor") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("paper") || lower.contains("analysis") || lower.contains("theory"))
            || lower.contains("frame semantics") || lower.contains("fillmore") && (lower.contains("semantics") || lower.contains("linguistics") || lower.contains("frame"))
            || lower.contains("cognitive semantics") || lower.contains("mental spaces") && (lower.contains("linguistics") || lower.contains("class") || lower.contains("blending"))
            || lower.contains("blending theory") && (lower.contains("linguistics") || lower.contains("class") || lower.contains("metaphor") || lower.contains("conceptual"))
            || lower.contains("conceptual blending") || lower.contains("image schema") || lower.contains("image schemas")
            || lower.contains("embodied meaning") || lower.contains("embodied cognition") && (lower.contains("linguistics") || lower.contains("language") || lower.contains("class"))
            || (word("langacker") && (lower.contains("linguistics") || lower.contains("grammar") || lower.contains("class") || lower.contains("course") || lower.contains("paper")))
            || (word("lakoff") && (lower.contains("linguistics") || lower.contains("metaphor") || lower.contains("class") || lower.contains("cognitive") || lower.contains("paper"))) {
            return "cognitivelinguistics"
        }
        // appliedlinguistics — positioned AFTER cognitivelinguistics and BEFORE linguistics so
        // second language acquisition research, language pedagogy, and applied linguistic analysis
        // route here rather than the structural/theoretical linguistics pool.
        // "applied linguistics" and "second language acquisition" removed from linguistics branch.
        if lower.contains("applied linguistics") || lower.contains("second language acquisition")
            || lower.contains("l2 acquisition") || lower.contains("l1 acquisition")
            || (lower.contains("discourse analysis") && (lower.contains("applied") || lower.contains("language") || lower.contains("class") || lower.contains("course") || lower.contains("assignment") || lower.contains("research")))
            || lower.contains("language pedagogy") || lower.contains("language teaching method")
            || lower.contains("language policy") || lower.contains("language planning")
            || lower.contains("language assessment") || lower.contains("language testing")
            || lower.contains("language acquisition research") || lower.contains("language acquisition theory")
            || (lower.contains("interlanguage") && (lower.contains("class") || lower.contains("course") || lower.contains("research") || lower.contains("analysis")))
            || (lower.contains("multilingualism") && (lower.contains("class") || lower.contains("course") || lower.contains("research") || lower.contains("analysis")))
            || lower.contains("heritage language") && (lower.contains("class") || lower.contains("course") || lower.contains("research"))
            || lower.contains("language socialization") || lower.contains("translanguaging")
            || (word("sla") && (lower.contains("class") || lower.contains("course") || lower.contains("theory") || lower.contains("research")))
            || lower.contains("applied linguistics class") || lower.contains("applied linguistics course")
            || lower.contains("applied linguistics program") || lower.contains("applied linguistics exam")
            || lower.contains("applied linguistics major") || lower.contains("applied linguistics degree") {
            return "appliedlinguistics"
        }
        // linguistics — positioned before studying so "linguistics exam", "phonetics class",
        // and language-science assignments don't fall through to studying.
        // Language learning (vocabulary, conjugation, Duolingo) stays in the language branch below.
        // "applied linguistics" and "second language acquisition" now owned by appliedlinguistics above.
        if word("linguistics") || word("linguist") || word("linguistic")
            || word("phonology") || word("phonetics") || word("phoneme") || word("phonemes")
            || lower.contains("sociolinguistics") || lower.contains("psycholinguistics")
            || lower.contains("computational linguistics") || lower.contains("corpus linguistics")
            || lower.contains("language acquisition") || lower.contains("historical linguistics")
            || lower.contains("discourse analysis") || lower.contains("language documentation")
            || lower.contains("language endangerment") || lower.contains("language typology")
            || lower.contains("linguistic analysis") || lower.contains("linguistic theory")
            || lower.contains("linguistics class") || lower.contains("linguistics course")
            || lower.contains("linguistics program") || lower.contains("linguistics major")
            || lower.contains("linguistics exam") || lower.contains("linguistic anthropology")
            || lower.contains("international phonetic alphabet") {
            return "linguistics"
        }
        // oceanography — positioned BEFORE marinebiology so dedicated oceanography class/lab/exam
        // tasks route here rather than the marine biology pool. Bare "ocean" NOT matched alone.
        // Physical, chemical, biological, and geological oceanography all covered here.
        // word("oceanography"/"oceanographer") and "oceanography class/course/exam" removed from
        // marinebiology (below) and owned here.
        if word("oceanography") || word("oceanographer") || word("oceanographers")
            || lower.contains("oceanography class") || lower.contains("oceanography course")
            || lower.contains("oceanography exam") || lower.contains("oceanography lab")
            || lower.contains("oceanography notes") || lower.contains("oceanography textbook")
            || lower.contains("oceanography program") || lower.contains("oceanography major")
            || lower.contains("oceanography assignment") || lower.contains("oceanography homework")
            || lower.contains("physical oceanography") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("chemical oceanography") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("biological oceanography") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("geological oceanography") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("ocean circulation") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("oceanography"))
            || lower.contains("thermohaline circulation") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("ocean currents") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("oceanography"))
            || lower.contains("sea surface temperature") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("oceanography"))
            || lower.contains("ekman transport") && (lower.contains("class") || lower.contains("course") || lower.contains("oceanography"))
            || lower.contains("geostrophic flow") && (lower.contains("class") || lower.contains("course") || lower.contains("ocean"))
            || lower.contains("ocean salinity") && (lower.contains("class") || lower.contains("course") || lower.contains("oceanography"))
            || lower.contains("tidal forcing") && (lower.contains("class") || lower.contains("oceanography"))
            || lower.contains("ocean stratification") && (lower.contains("class") || lower.contains("oceanography")) {
            return "oceanography"
        }
        // marinebiology — positioned before studying so "marine biology exam" and
        // "oceanography lab" don't fall through via word("exam") or word("lab").
        // Bare word("biology") stays in studying for generic "biology exam" tasks.
        // word("oceanography"/"oceanographer") and "oceanography class/course/exam" now owned
        // by the oceanography branch above.
        if lower.contains("marine biology") || lower.contains("marine biologist")
            || lower.contains("marine biologists")
            || lower.contains("marine ecology") || lower.contains("marine ecologist")
            || lower.contains("marine science") || lower.contains("marine sciences")
            || lower.contains("marine life") || lower.contains("marine organisms")
            || lower.contains("marine mammal") || lower.contains("marine mammals")
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
            || lower.contains("marine biology homework") {
            return "marinebiology"
        }
        // marinebiology2 — positioned immediately AFTER marinebiology so lab-specific marine
        // biology sessions (plankton identification, tidepool field sampling, marine invertebrate
        // dissection, ocean field work) route to a dedicated lab pool. Bare "marine biology lab"
        // was caught above by marinebiology; compound lab-technique signals fire here first.
        if lower.contains("plankton identification") || lower.contains("plankton counting") || lower.contains("plankton sample")
            || lower.contains("phytoplankton identification") || lower.contains("zooplankton identification")
            || lower.contains("tidepool") && (lower.contains("lab") || lower.contains("field") || lower.contains("survey") || lower.contains("ecology") || lower.contains("sampling"))
            || lower.contains("tide pool") && (lower.contains("lab") || lower.contains("field") || lower.contains("survey") || lower.contains("ecology") || lower.contains("sampling"))
            || lower.contains("marine invertebrate") && (lower.contains("lab") || lower.contains("dissection") || lower.contains("identification") || lower.contains("class") || lower.contains("biology"))
            || lower.contains("marine organism dissection") || lower.contains("dissect marine") || lower.contains("marine specimen")
            || lower.contains("ocean field") && (lower.contains("sample") || lower.contains("survey") || lower.contains("data") || lower.contains("collection") || lower.contains("lab"))
            || lower.contains("ocean sampling") || lower.contains("marine field sampling") || lower.contains("marine field survey")
            || lower.contains("seawater chemistry") && (lower.contains("lab") || lower.contains("class") || lower.contains("analysis") || lower.contains("marine"))
            || lower.contains("benthic survey") || lower.contains("benthic sampling") || lower.contains("benthic community")
            || lower.contains("intertidal") && (lower.contains("lab") || lower.contains("field") || lower.contains("ecology") || lower.contains("survey") || lower.contains("zone") || lower.contains("class"))
            || lower.contains("subtidal") && (lower.contains("lab") || lower.contains("field") || lower.contains("ecology") || lower.contains("survey") || lower.contains("class"))
            || lower.contains("kelp forest") && (lower.contains("lab") || lower.contains("field") || lower.contains("ecology") || lower.contains("survey") || lower.contains("class"))
            || lower.contains("marine biology lab report") || lower.contains("marine biology lab notebook")
            || lower.contains("ocean biology lab") || lower.contains("marine science lab") {
            return "marinebiology2"
        }
        // quantummechanics — positioned BEFORE experimentalphysics so quantum mechanics and
        // quantum physics coursework gets a dedicated callout pool. "quantum mechanics + computing/
        // programming/algorithm" stays in quantumcomputing (fires much earlier).
        if lower.contains("quantum mechanics class") || lower.contains("quantum mechanics course")
            || lower.contains("quantum mechanics exam") || lower.contains("quantum mechanics notes")
            || lower.contains("quantum mechanics lab") || lower.contains("quantum mechanics homework")
            || lower.contains("quantum mechanics problem") || lower.contains("quantum mechanics textbook")
            || lower.contains("quantum physics class") || lower.contains("quantum physics course")
            || lower.contains("quantum physics exam") || lower.contains("quantum physics notes")
            || lower.contains("quantum physics homework") || lower.contains("quantum physics problem")
            || lower.contains("wave function") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("quantum") || lower.contains("homework"))
            || lower.contains("schrödinger equation") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("quantum") || lower.contains("homework"))
            || lower.contains("schrodinger equation") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("quantum") || lower.contains("homework"))
            || lower.contains("hamiltonian operator") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("quantum"))
            || lower.contains("bra-ket notation") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("quantum"))
            || lower.contains("braket notation") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("quantum"))
            || lower.contains("quantum tunneling") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("physics"))
            || lower.contains("quantum harmonic oscillator") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem"))
            || lower.contains("particle in a box") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("quantum") || lower.contains("physics"))
            || lower.contains("uncertainty principle") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("quantum") || lower.contains("physics"))
            || lower.contains("quantum superposition") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("physics"))
            || lower.contains("quantum entanglement") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("physics"))
            || lower.contains("perturbation theory") && (lower.contains("quantum") || lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("physics"))
            || lower.contains("variational method") && (lower.contains("quantum") || lower.contains("class") || lower.contains("course") || lower.contains("physics")) {
            return "quantummechanics"
        }
        // solidstatephysics — positioned BEFORE experimentalphysics so condensed matter /
        // solid state physics coursework gets a dedicated callout pool.
        if lower.contains("solid state physics class") || lower.contains("solid state physics course")
            || lower.contains("solid state physics exam") || lower.contains("solid state physics notes")
            || lower.contains("solid state physics homework") || lower.contains("solid state physics lab")
            || lower.contains("condensed matter class") || lower.contains("condensed matter course")
            || lower.contains("condensed matter exam") || lower.contains("condensed matter physics class")
            || lower.contains("condensed matter physics course") || lower.contains("condensed matter physics exam")
            || lower.contains("crystal lattice") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("physics") || lower.contains("solid state"))
            || lower.contains("band structure") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("physics") || lower.contains("solid state"))
            || lower.contains("brillouin zone") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("physics"))
            || lower.contains("bloch's theorem") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("physics"))
            || lower.contains("phonon") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("solid state") || lower.contains("condensed matter"))
            || lower.contains("fermi level") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("solid state") || lower.contains("condensed matter"))
            || lower.contains("semiconductor physics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("superconductivity") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("solid state") || lower.contains("condensed matter"))
            || lower.contains("magnetic ordering") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("solid state") || lower.contains("physics"))
            || lower.contains("ferromagnetism") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("solid state") || lower.contains("physics")) {
            return "solidstatephysics"
        }
        // classicalmechanics — positioned BEFORE experimentalphysics so analytical/classical
        // mechanics coursework (Lagrangian/Hamiltonian, rigid body) gets a dedicated pool.
        if lower.contains("classical mechanics class") || lower.contains("classical mechanics course")
            || lower.contains("classical mechanics exam") || lower.contains("classical mechanics notes")
            || lower.contains("classical mechanics homework") || lower.contains("classical mechanics problem")
            || lower.contains("analytical mechanics class") || lower.contains("analytical mechanics course")
            || lower.contains("analytical mechanics exam") || lower.contains("analytical mechanics notes")
            || lower.contains("lagrangian mechanics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem") || lower.contains("homework"))
            || lower.contains("lagrangian dynamics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem"))
            || lower.contains("hamiltonian mechanics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem") || lower.contains("homework"))
            || lower.contains("hamiltonian dynamics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem"))
            || lower.contains("rigid body dynamics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem") || lower.contains("mechanics"))
            || lower.contains("rigid body rotation") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("mechanics"))
            || lower.contains("generalized coordinates") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("mechanics"))
            || lower.contains("euler-lagrange") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("mechanics") || lower.contains("problem"))
            || lower.contains("moment of inertia tensor") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("mechanics"))
            || lower.contains("central force problem") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("mechanics"))
            || lower.contains("poisson brackets") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("mechanics"))
            || lower.contains("action principle") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("mechanics") || lower.contains("physics")) {
            return "classicalmechanics"
        }
        // optics — positioned BEFORE experimentalphysics so optics/photonics class work routes
        // to a dedicated pool. "optics lab" stays in experimentalphysics (no class qualifier needed).
        if word("optics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("homework") || lower.contains("problem set") || lower.contains("notes"))
            || word("photonics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("project") || lower.contains("homework"))
            || lower.contains("laser physics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem"))
            || lower.contains("wave optics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem"))
            || lower.contains("geometric optics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem"))
            || lower.contains("fourier optics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem"))
            || lower.contains("nonlinear optics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("quantum optics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("optical fiber") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("notes"))
            || lower.contains("optical fibers") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("diffraction grating") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem") || lower.contains("optics"))
            || lower.contains("physical optics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem"))
            || lower.contains("optics class") || lower.contains("optics course") || lower.contains("optics exam") || lower.contains("optics homework")
            || lower.contains("photonics class") || lower.contains("photonics course") || lower.contains("photonics exam")
            || lower.contains("photonic device") && (lower.contains("class") || lower.contains("course") || lower.contains("design") || lower.contains("exam")) {
            return "optics"
        }
        // experimentalphysics — positioned BEFORE the studying branch (which catches word("physics"))
        // so physics lab reports, optics experiments, and mechanics labs get a dedicated pool instead
        // of the generic studying pool. Bare word("physics") alone still falls through to studying.
        // "health physics" stays in healthphysics (fires later; "health physics class" contains
        // compound "health physics" which doesn't need word("physics") alone).
        if lower.contains("physics lab") || lower.contains("optics lab") || lower.contains("mechanics lab")
            || lower.contains("thermodynamics lab") || lower.contains("electromagnetism lab")
            || lower.contains("electricity and magnetism lab") || lower.contains("waves lab")
            || lower.contains("modern physics lab") || lower.contains("quantum mechanics class")
            || lower.contains("quantum mechanics course") || lower.contains("quantum mechanics exam")
            || lower.contains("quantum physics class") || lower.contains("quantum physics course")
            || lower.contains("quantum physics exam")
            || lower.contains("classical mechanics class") || lower.contains("classical mechanics course")
            || lower.contains("classical mechanics exam")
            || lower.contains("experimental physics") || lower.contains("physics experiment")
            || lower.contains("physics experiments") || lower.contains("lab report") && (lower.contains("physics") || lower.contains("optics") || lower.contains("mechanics") || lower.contains("electro"))
            || lower.contains("pendulum lab") || lower.contains("projectile motion lab")
            || lower.contains("free fall lab") || lower.contains("friction lab")
            || lower.contains("coulomb's law lab") || lower.contains("ohm's law lab")
            || lower.contains("snell's law lab") || lower.contains("diffraction lab")
            || lower.contains("interference pattern lab") || lower.contains("lens lab")
            || lower.contains("spectroscopy lab") && !(lower.contains("biochem") || lower.contains("chem class") || lower.contains("biophysics"))
            || lower.contains("physics report") || lower.contains("physics lab report")
            || lower.contains("computational physics") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("theoretical physics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")) {
            return "experimentalphysics"
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
        // botany — positioned AFTER agriculturalscience and BEFORE geographyearthed.
        // Catches plant biology, botany coursework, herbarium science, and mycology in
        // academic context. "plant science" in horticulturescience fires earlier.
        // "naturopathic botany" stays in naturopathicmedicine (fires much earlier).
        if word("botany") || word("botanist") || word("botanical")
            || lower.contains("plant biology class") || lower.contains("plant biology course")
            || lower.contains("plant biology exam") || lower.contains("plant biology lab")
            || lower.contains("plant biology program") || lower.contains("plant biology notes")
            || lower.contains("plant physiology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("plant ecology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("plant taxonomy") || lower.contains("plant systematics")
            || lower.contains("plant anatomy") && (lower.contains("class") || lower.contains("course") || lower.contains("lab"))
            || lower.contains("plant morphology") && (lower.contains("class") || lower.contains("course") || lower.contains("lab"))
            || lower.contains("plant genetics") && (lower.contains("class") || lower.contains("course") || lower.contains("lab"))
            || lower.contains("herbarium") && (lower.contains("class") || lower.contains("lab") || lower.contains("specimen") || lower.contains("study"))
            || word("ethnobotany") || word("ethnobotanist")
            || lower.contains("plant pathology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("mycology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("fungi"))
            || lower.contains("phytochemistry") && (lower.contains("class") || lower.contains("course") || lower.contains("lab"))
            || lower.contains("algae") && (lower.contains("class") || lower.contains("biology") || lower.contains("lab") || lower.contains("course")) {
            return "botany"
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
        // waterresources — positioned BEFORE geology so water resources engineering, hydraulics,
        // and stormwater design tasks get a dedicated pool instead of routing to geology via
        // "hydrology". "hydrology" as a bare word still fires geology; only fires here when paired
        // with engineering/design/class context. "water treatment" in chemistry context stays here.
        if lower.contains("water resources engineering") || lower.contains("water resources management")
            || lower.contains("water resources class") || lower.contains("water resources course")
            || lower.contains("water resources exam") || lower.contains("water resources program")
            || lower.contains("hydraulics class") || lower.contains("hydraulics course")
            || lower.contains("hydraulics lab") || lower.contains("hydraulics exam")
            || lower.contains("hydraulic engineering") || lower.contains("hydraulic design")
            || lower.contains("stormwater management") && !lower.contains("landscape")
            || lower.contains("stormwater engineering") || lower.contains("stormwater design")
            || lower.contains("flood control engineering") || lower.contains("flood modeling class")
            || lower.contains("groundwater engineering") || lower.contains("groundwater modeling class")
            || lower.contains("groundwater modeling course") || lower.contains("groundwater hydrology class")
            || lower.contains("water treatment engineering") || lower.contains("water treatment class")
            || lower.contains("water treatment course") || lower.contains("water treatment exam")
            || lower.contains("water supply engineering") || lower.contains("water supply class")
            || lower.contains("water supply design") || lower.contains("drinking water treatment class")
            || lower.contains("drinking water engineering") || lower.contains("water distribution class")
            || lower.contains("wastewater treatment class") || lower.contains("wastewater engineering")
            || lower.contains("wastewater design") || lower.contains("water quality engineering")
            || lower.contains("sanitary engineering") || lower.contains("water infrastructure class")
            || lower.contains("dam design") && (lower.contains("class") || lower.contains("course"))
            || lower.contains("irrigation engineering") || lower.contains("irrigation design class")
            || lower.contains("hydrology class") || lower.contains("hydrology course")
            || lower.contains("hydrology lab") || lower.contains("hydrology exam")
            || lower.contains("applied hydrology") || lower.contains("engineering hydrology") {
            return "waterresources"
        }
        // paleontology — positioned BEFORE geology so fossil-record analysis, taphonomy, and
        // paleobiology coursework get a dedicated pool. "soil mechanics" stays in geology.
        // "paleontology" and "fossil record" removed from geology branch below.
        if word("paleontology") || word("paleontologist") || word("paleontologists")
            || word("paleobiologist") || word("paleobiology")
            || lower.contains("fossil record") || lower.contains("fossil records")
            || word("taphonomy") || word("paleoecology") || word("paleoecologist")
            || lower.contains("trace fossil") || lower.contains("trace fossils")
            || word("paleobotany") || word("paleobotanist")
            || word("paleoanthropology") || word("paleoanthropologist")
            || lower.contains("prehistoric life") || lower.contains("prehistoric organisms")
            || lower.contains("cambrian explosion") || lower.contains("cambrian period")
            || lower.contains("paleozoic era") || lower.contains("mesozoic era") || lower.contains("cenozoic era")
            || lower.contains("dinosaur") && (lower.contains("class") || lower.contains("course") || lower.contains("research") || lower.contains("paper") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("invertebrate paleontology") || lower.contains("vertebrate paleontology")
            || lower.contains("micropaleontology") || lower.contains("biostratigraphy")
            || lower.contains("paleontology class") || lower.contains("paleontology course")
            || lower.contains("paleontology exam") || lower.contains("paleontology lab")
            || lower.contains("paleontology notes") || lower.contains("paleontology assignment") {
            return "paleontology"
        }
        // geochemistry — positioned BEFORE geology; isotope geochemistry, trace-element and
        // major-element geochemical analysis, fluid-rock interaction, and geochemical modeling.
        // word("geochemistry") removed from geology (below) and owned here.
        // Bare "mass spectrometry" stays in proteomics/molecularbiology (earlier).
        if lower.contains("geochemistry class") || lower.contains("geochemistry course")
            || lower.contains("geochemistry exam") || lower.contains("geochemistry lab")
            || lower.contains("geochemistry notes") || lower.contains("geochemistry program")
            || lower.contains("geochemistry major") || lower.contains("geochemistry assignment")
            || lower.contains("geochemistry textbook") || lower.contains("geochemistry homework")
            || lower.contains("isotope geochemistry") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("isotope ratio") && (lower.contains("class") || lower.contains("geochemistry") || lower.contains("geochemical"))
            || lower.contains("trace element") && (lower.contains("class") || lower.contains("geochemistry") || lower.contains("geochemical") || lower.contains("rock") || lower.contains("mineral"))
            || lower.contains("major element") && (lower.contains("class") || lower.contains("geochemistry") || lower.contains("geochemical"))
            || lower.contains("geochemical analysis") && (lower.contains("class") || lower.contains("lab") || lower.contains("course"))
            || lower.contains("geochemical modeling") && (lower.contains("class") || lower.contains("lab") || lower.contains("course"))
            || lower.contains("xrf") && (lower.contains("class") || lower.contains("geochemistry") || lower.contains("geochemical") || lower.contains("rock") || lower.contains("mineral"))
            || lower.contains("icp-ms") && (lower.contains("class") || lower.contains("geochemistry") || lower.contains("geochemical") || lower.contains("rock") || lower.contains("mineral"))
            || lower.contains("radiogenic isotope") && (lower.contains("class") || lower.contains("geochemistry") || lower.contains("lab"))
            || lower.contains("stable isotope") && (lower.contains("geochemistry") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("rock chemistry") && (lower.contains("class") || lower.contains("course") || lower.contains("lab"))
            || lower.contains("mineral chemistry") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("geochemistry"))
            || lower.contains("fluid-rock interaction") && (lower.contains("class") || lower.contains("geochemistry") || lower.contains("lab"))
            || lower.contains("hydrothermal geochemistry") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("marine geochemistry") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || word("geochemistry") || word("geochemist") || word("geochemists") {
            return "geochemistry"
        }
        // geologylab — positioned BEFORE geology so specific geology lab tasks (rock/mineral
        // identification, thin section analysis, geologic field mapping reports) get a dedicated pool.
        // Generic "geology lab" without specific lab-activity context still routes to geology (fires after).
        if lower.contains("geology lab") && (lower.contains("rock") || lower.contains("mineral") || lower.contains("thin section") || lower.contains("field") || lower.contains("class") || lower.contains("report") || lower.contains("sample"))
            || lower.contains("rock identification lab") || lower.contains("mineral identification lab")
            || lower.contains("thin section") && (lower.contains("geology") || lower.contains("lab") || lower.contains("mineralogy") || lower.contains("petrology") || lower.contains("microscopy"))
            || lower.contains("geologic field") && (lower.contains("lab") || lower.contains("report") || lower.contains("class") || lower.contains("mapping") || lower.contains("camp"))
            || lower.contains("geology field lab") || lower.contains("geology field report")
            || lower.contains("field geology") && (lower.contains("lab") || lower.contains("report") || lower.contains("mapping") || lower.contains("class"))
            || lower.contains("rock cycle lab") || lower.contains("rock sample lab")
            || lower.contains("mineral sample lab") || lower.contains("petrographic") && (lower.contains("lab") || lower.contains("class") || lower.contains("report") || lower.contains("microscope"))
            || lower.contains("hand specimen") && (lower.contains("geology") || lower.contains("lab") || lower.contains("mineral") || lower.contains("rock") || lower.contains("identify"))
            || lower.contains("geologic map lab") || lower.contains("geologic cross section lab")
            || lower.contains("rock and mineral lab") || lower.contains("minerals and rocks lab")
            || lower.contains("rock identification class") || lower.contains("mineral identification class")
            || lower.contains("igneous rock lab") || lower.contains("sedimentary rock lab") || lower.contains("metamorphic rock lab") {
            return "geologylab"
        }
        // geology — positioned before engineering so "geology lab" and earth-science field tasks
        // don't fall through to engineering or research via word("lab").
        // "geography" alone does NOT fire here (stays in studying/socialscience).
        // "gis mapping" / "gis analysis" now owned by geospatial branch above.
        // "paleontology" / "fossil record" now owned by paleontology branch above.
        // word("geochemistry") now owned by geochemistry branch above.
        if word("geology") || word("geologist") || word("geological") || word("geologists")
            || word("mineralogy") || word("petrology") || word("sedimentology")
            || word("stratigraphy") || word("stratigraphic") || word("geomorphology")
            || word("hydrogeology") || word("seismology") || word("volcanology")
            || word("geophysics")
            || lower.contains("earth science") || lower.contains("earth sciences")
            || word("geoscience") || word("geosciences")
            || lower.contains("plate tectonics") || lower.contains("tectonic plates")
            || lower.contains("rock cycle") || lower.contains("rock identification")
            || lower.contains("mineral identification") || lower.contains("mineral analysis")
            || lower.contains("geological survey") || lower.contains("geologic map")
            || lower.contains("geological map") || lower.contains("geologic cross section")
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
        // nanotechnology — positioned BEFORE materialscience so nanotechnology research, nanomaterials
        // synthesis, nanoscale imaging, and nano-device work route here with dedicated callout messages.
        // "nanomaterials" and "nanotechnology" with class/course/exam context owned here;
        // MEMS stays in materialscience; NEMS routed here (nano-scale electromechanical).
        if word("nanotechnology") || word("nanotechnologist") || word("nanoscience")
            || lower.contains("nanomaterial") || lower.contains("nanomaterials")
            || (lower.contains("nanoscale") && (lower.contains("class") || lower.contains("lab") || lower.contains("research") || lower.contains("imaging") || lower.contains("synthesis") || lower.contains("fabrication")))
            || lower.contains("nanofabrication") || lower.contains("nano-fabrication")
            || lower.contains("quantum dot") || lower.contains("quantum dots")
            || lower.contains("carbon nanotube") || lower.contains("carbon nanotubes")
            || (word("graphene") && (lower.contains("class") || lower.contains("lab") || lower.contains("research") || lower.contains("synthesis") || lower.contains("characterization")))
            || (word("nems") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("fabrication") || lower.contains("research")))
            || (lower.contains("atomic force microscopy") && !lower.contains("biophysics"))
            || lower.contains("afm imaging") || lower.contains("afm characterization")
            || lower.contains("scanning tunneling microscopy") || lower.contains("stm imaging")
            || lower.contains("nanomedicine") || lower.contains("nanotoxicology")
            || (lower.contains("nanophotonics") && (lower.contains("class") || lower.contains("lab") || lower.contains("research")))
            || (lower.contains("plasmonics") && (lower.contains("class") || lower.contains("lab") || lower.contains("research")))
            || (lower.contains("self-assembly") && (lower.contains("nano") || lower.contains("molecular machine") || lower.contains("class") || lower.contains("lab")))
            || lower.contains("nanoparticle") || lower.contains("nanoparticles")
            || lower.contains("nanostructure") || lower.contains("nanostructures")
            || lower.contains("nanotechnology class") || lower.contains("nanotechnology course")
            || lower.contains("nanotechnology exam") || lower.contains("nanotechnology lab")
            || lower.contains("nanotechnology program") || lower.contains("nanotechnology research") {
            return "nanotechnology"
        }
        // materialscience — positioned AFTER nanotechnology and BEFORE engineering.
        // Catches MSE coursework, metallurgy, polymer science, ceramics (in engineering context),
        // composite materials, and phase diagram labs. "nanomaterials"/"nanotechnology" now owned
        // by nanotechnology above. "ceramics" alone (art context) NOT matched — requires qualifier.
        if lower.contains("materials science") || lower.contains("materials engineering")
            || lower.contains("material science") || lower.contains("material engineering")
            || lower.contains("materials science and engineering")
            || lower.contains("metallurgy") || lower.contains("metallurgical engineering")
            || (lower.contains("ceramics") && !lower.contains("art") && !lower.contains("studio") && !lower.contains("pottery") && !lower.contains("wheel") && !lower.contains("glaze") && !lower.contains("raku") && !lower.contains("kiln firing") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("engineering")))
            || (lower.contains("polymer science") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || lower.contains("polymer chemistry") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("polymer engineering")
            || (lower.contains("composite materials") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab")))
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
        // materialscharacterization — positioned AFTER materialscience so XRD, SEM/TEM,
        // spectroscopy (FTIR/Raman/UV-Vis), and thermal analysis in materials research context
        // route here. nanotechnology-specific AFM/STM are already owned above; fabrication stays
        // in nanotechnology. Bare "spectroscopy" or "microscopy" without materials context NOT matched.
        if lower.contains("x-ray diffraction") || lower.contains("xrd analysis") || lower.contains("xrd pattern")
            || lower.contains("powder diffraction") || lower.contains("bragg's law") && (lower.contains("class") || lower.contains("lab") || lower.contains("materials"))
            || (lower.contains("scanning electron microscopy") && !lower.contains("nanotechnology") && (lower.contains("materials") || lower.contains("class") || lower.contains("lab") || lower.contains("characterization")))
            || lower.contains("sem imaging") && (lower.contains("material") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("sem/edx") || lower.contains("sem/eds") || lower.contains("sem analysis") && lower.contains("material")
            || (lower.contains("transmission electron microscopy") && (lower.contains("materials") || lower.contains("class") || lower.contains("lab") || lower.contains("characterization")))
            || lower.contains("tem imaging") && (lower.contains("material") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("ftir spectroscopy") || lower.contains("infrared spectroscopy") && (lower.contains("material") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("raman spectroscopy") && !lower.contains("biophysics")
            || lower.contains("uv-vis spectroscopy") && (lower.contains("material") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("thermogravimetric analysis") || word("tga") && (lower.contains("material") || lower.contains("class") || lower.contains("lab") || lower.contains("thermal"))
            || lower.contains("differential scanning calorimetry") || word("dsc") && (lower.contains("material") || lower.contains("thermal") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("dynamic mechanical analysis") || word("dma") && (lower.contains("material") || lower.contains("polymer") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("nanoindentation") && !lower.contains("nanotechnology")
            || lower.contains("hardness testing") && (lower.contains("material") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("contact angle") && (lower.contains("material") || lower.contains("surface") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("bet surface area") || lower.contains("porosimetry") && (lower.contains("material") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("materials characterization") || lower.contains("material characterization")
            || lower.contains("characterization lab") && (lower.contains("material") || lower.contains("polymer") || lower.contains("composite"))
            || lower.contains("materials characterization class") || lower.contains("materials characterization course")
            || lower.contains("materials characterization exam") || lower.contains("materials characterization lab") {
            return "materialscharacterization"
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
        // processengineering — positioned BEFORE engineering so chemical process engineering
        // coursework (unit operations, reactor design, transport phenomena, Aspen Plus) routes to
        // a specialized pool rather than the generic engineering pool. "heat transfer" alone fires
        // engineering below; only catch it here with unit-ops/reactor/process context.
        if lower.contains("unit operations") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam") || lower.contains("notes") || lower.contains("chemical"))
            || lower.contains("reactor design") && (lower.contains("class") || lower.contains("course") || lower.contains("chemical") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("chemical reaction engineering") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("notes"))
            || lower.contains("transport phenomena") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("chemical") || lower.contains("notes"))
            || lower.contains("process control") && (lower.contains("chemical") || lower.contains("che") || lower.contains("class") || lower.contains("engineering class") || lower.contains("engineering course"))
            || lower.contains("mass and energy balance") && (lower.contains("class") || lower.contains("course") || lower.contains("chemical") || lower.contains("exam"))
            || lower.contains("mass balance") && (lower.contains("chemical") || lower.contains("unit ops") || lower.contains("class") || lower.contains("course") && lower.contains("engineering"))
            || lower.contains("energy balance") && (lower.contains("chemical") || lower.contains("unit ops") || lower.contains("class") && lower.contains("engineering"))
            || lower.contains("process simulation") && (lower.contains("class") || lower.contains("course") || lower.contains("chemical") || lower.contains("lab"))
            || lower.contains("aspen plus") || lower.contains("aspen hysys") || word("hysys") && (lower.contains("class") || lower.contains("simulation") || lower.contains("chemical") || lower.contains("process"))
            || lower.contains("distillation column") && (lower.contains("design") || lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("chemical"))
            || lower.contains("heat exchanger design") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("chemical"))
            || lower.contains("chemical process engineering") || lower.contains("chemical process design")
            || lower.contains("chemical process simulation") || lower.contains("chemical process control")
            || word("pfr") && (lower.contains("class") || lower.contains("reactor") || lower.contains("design") || lower.contains("chemical"))
            || word("cstr") && (lower.contains("class") || lower.contains("reactor") || lower.contains("design") || lower.contains("chemical"))
            || lower.contains("plug flow reactor") || lower.contains("continuous stirred tank reactor")
            || lower.contains("piping and instrumentation diagram") || lower.contains("p&id") && (lower.contains("class") || lower.contains("chemical") || lower.contains("process"))
            || lower.contains("process flow diagram") && (lower.contains("class") || lower.contains("course") || lower.contains("chemical") || lower.contains("engineering")) {
            return "processengineering"
        }
        // aerospacengineering — positioned BEFORE civilengineering and engineering so aerodynamics,
        // propulsion, orbital mechanics, and aerospace coursework route here. "aviation" (FAA/pilot)
        // stays in the aviation branch (earlier). Bare "thermodynamics" stays in engineering.
        if lower.contains("aerospace engineering class") || lower.contains("aerospace engineering course")
            || lower.contains("aerospace engineering exam") || lower.contains("aerospace engineering lab")
            || lower.contains("aerospace engineering notes") || lower.contains("aerospace engineering program")
            || lower.contains("aerospace engineering major") || lower.contains("aerospace engineering degree")
            || lower.contains("aerospace engineering assignment") || lower.contains("aerospace engineering project")
            || lower.contains("aerodynamics class") || lower.contains("aerodynamics course")
            || lower.contains("aerodynamics lab") || lower.contains("aerodynamics exam")
            || lower.contains("propulsion class") || lower.contains("propulsion course")
            || lower.contains("propulsion lab") || lower.contains("propulsion exam")
            || lower.contains("rocket propulsion") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("design"))
            || lower.contains("jet propulsion") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("design"))
            || lower.contains("orbital mechanics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("homework"))
            || lower.contains("flight dynamics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("flight mechanics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("astrodynamics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("homework"))
            || lower.contains("spacecraft design") && (lower.contains("class") || lower.contains("course") || lower.contains("project") || lower.contains("lab"))
            || lower.contains("aircraft design") && (lower.contains("class") || lower.contains("course") || lower.contains("project") || lower.contains("lab"))
            || lower.contains("aeronautics class") || lower.contains("aeronautics course") || lower.contains("aeronautics exam")
            || lower.contains("hypersonic") && (lower.contains("class") || lower.contains("course") || lower.contains("flow") || lower.contains("lab"))
            || lower.contains("supersonic flow") && (lower.contains("class") || lower.contains("course") || lower.contains("lab"))
            || lower.contains("gas dynamics") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("wind tunnel") && (lower.contains("class") || lower.contains("lab") || lower.contains("aerospace") || lower.contains("test"))
            || lower.contains("orbit determination") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("satellite design") && (lower.contains("class") || lower.contains("course") || lower.contains("project"))
            || lower.contains("compressible flow") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("aiaa") && (lower.contains("class") || lower.contains("design") || lower.contains("project") || lower.contains("competition")) {
            return "aerospacengineering"
        }
        // electromagnetism — positioned BEFORE electricalengineering so physics E&M courses
        // (Gauss/Ampere/Faraday/Maxwell in a physics context) get a dedicated pool. EE-specific
        // signals (circuits, FPGA, signal processing) remain in electricalengineering.
        // "maxwell's equations+class" and "electromagnetic fields+class/exam" owned here;
        // those lines removed from electricalengineering below.
        if lower.contains("gauss's law") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem") || lower.contains("homework"))
            || lower.contains("ampere's law") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem") || lower.contains("homework"))
            || lower.contains("faraday's law") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem") || lower.contains("homework"))
            || lower.contains("maxwell's equations") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem") || lower.contains("homework"))
            || lower.contains("electromagnetic fields") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem") || lower.contains("homework"))
            || lower.contains("electrostatics class") || lower.contains("electrostatics course") || lower.contains("electrostatics exam")
            || lower.contains("magnetostatics class") || lower.contains("magnetostatics course") || lower.contains("magnetostatics exam")
            || lower.contains("electromagnetic wave") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem"))
            || lower.contains("electromagnetic waves") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem"))
            || lower.contains("electricity and magnetism class") || lower.contains("electricity and magnetism course") || lower.contains("electricity and magnetism exam")
            || lower.contains("e&m class") || lower.contains("e&m course") || lower.contains("e&m exam") || lower.contains("e&m problem")
            || lower.contains("em class") && (lower.contains("physics") || lower.contains("fields") || lower.contains("waves")) || lower.contains("em course") && (lower.contains("physics") || lower.contains("fields"))
            || lower.contains("electromagnetism class") || lower.contains("electromagnetism course")
            || lower.contains("electromagnetism exam") || lower.contains("electromagnetism homework")
            || lower.contains("electromagnetism problem set") || lower.contains("electromagnetism notes") {
            return "electromagnetism"
        }
        // electricalengineering — positioned AFTER aerospacengineering and BEFORE civilengineering/engineering
        // so circuits class, signal processing, and EE coursework route here.
        // "electrical engineering" removed from engineering branch below (now owned here).
        // Electrician licensing (journeyman, NEC code) stays in electricaltechnology (earlier).
        // "maxwell's equations+class" and "electromagnetic fields+class" owned by electromagnetism above.
        if lower.contains("electrical engineering class") || lower.contains("electrical engineering course")
            || lower.contains("electrical engineering exam") || lower.contains("electrical engineering lab")
            || lower.contains("electrical engineering notes") || lower.contains("electrical engineering program")
            || lower.contains("electrical engineering major") || lower.contains("electrical engineering degree")
            || lower.contains("electrical engineering assignment") || lower.contains("electrical engineering project")
            || lower.contains("ee class") && !lower.contains("see class") || lower.contains("ee course") || lower.contains("ee exam") || lower.contains("ee lab")
            || lower.contains("circuit analysis class") || lower.contains("circuit analysis course")
            || lower.contains("circuit analysis exam") || lower.contains("circuit analysis lab")
            || lower.contains("electric circuit") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("electrical circuit") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("kirchhoff") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("law"))
            || lower.contains("thevenin") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("equivalent"))
            || lower.contains("norton equivalent") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("op-amp") && (lower.contains("class") || lower.contains("lab") || lower.contains("circuit") || lower.contains("exam"))
            || lower.contains("operational amplifier") && (lower.contains("class") || lower.contains("lab") || lower.contains("circuit"))
            || lower.contains("digital electronics class") || lower.contains("digital electronics course") || lower.contains("digital electronics lab")
            || lower.contains("analog electronics class") || lower.contains("analog electronics course") || lower.contains("analog electronics lab")
            || lower.contains("digital signal processing") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("signal processing class") || lower.contains("signal processing course") || lower.contains("signal processing exam")
            || word("fpga") && (lower.contains("class") || lower.contains("lab") || lower.contains("course") || lower.contains("design") || lower.contains("project"))
            || word("vhdl") && (lower.contains("class") || lower.contains("lab") || lower.contains("course") || lower.contains("design"))
            || word("verilog") && (lower.contains("class") || lower.contains("lab") || lower.contains("course") || lower.contains("design"))
            || lower.contains("power electronics") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("electric machines class") || lower.contains("electric machines course") || lower.contains("electric machines lab")
            || lower.contains("microelectronics class") || lower.contains("microelectronics course") || lower.contains("microelectronics lab")
            || lower.contains("semiconductor devices class") || lower.contains("semiconductor devices course")
            || lower.contains("ee lab report") || lower.contains("electrical engineering report") {
            return "electricalengineering"
        }
        // civilengineering — positioned BEFORE engineering so structural, geotechnical, and
        // transportation engineering coursework routes here. "civil engineering" removed from
        // engineering branch below. "solidworks/CAD" stays in engineering.
        if lower.contains("civil engineering class") || lower.contains("civil engineering course")
            || lower.contains("civil engineering exam") || lower.contains("civil engineering lab")
            || lower.contains("civil engineering program") || lower.contains("civil engineering major")
            || lower.contains("civil engineering degree") || lower.contains("civil engineering notes")
            || lower.contains("civil engineering assignment") || lower.contains("civil engineering project")
            || lower.contains("structural engineering") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("design") || lower.contains("analysis"))
            || lower.contains("geotechnical engineering") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("report"))
            || lower.contains("soil mechanics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("foundation design") && (lower.contains("class") || lower.contains("course") || lower.contains("engineering"))
            || lower.contains("reinforced concrete") && (lower.contains("class") || lower.contains("course") || lower.contains("design") || lower.contains("exam"))
            || lower.contains("concrete design") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("steel design") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("structural analysis") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("bridge design") && (lower.contains("class") || lower.contains("course") || lower.contains("engineering"))
            || lower.contains("truss analysis") && (lower.contains("class") || lower.contains("course") || lower.contains("engineering"))
            || lower.contains("beam design") && (lower.contains("class") || lower.contains("engineering") || lower.contains("structural"))
            || lower.contains("seismic design") && (lower.contains("class") || lower.contains("course") || lower.contains("engineering"))
            || lower.contains("transportation engineering") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("design"))
            || lower.contains("highway engineering") && (lower.contains("class") || lower.contains("course") || lower.contains("design"))
            || lower.contains("pavement design") && (lower.contains("class") || lower.contains("course") || lower.contains("engineering"))
            || lower.contains("traffic engineering") && (lower.contains("class") || lower.contains("course") || lower.contains("engineering"))
            || word("asce") && (lower.contains("class") || lower.contains("code") || lower.contains("standard") || lower.contains("design"))
            || lower.contains("surveying class") || lower.contains("surveying course") || lower.contains("surveying exam") || lower.contains("surveying lab") {
            return "civilengineering"
        }
        // mechanicalengineering — BEFORE engineering; machine design, vibrations, kinematics,
        // statics, and dynamics coursework. "mechanical engineering" in generic text still falls
        // through to engineering; only specific ME coursework routes here.
        if lower.contains("mechanical engineering class") || lower.contains("mechanical engineering course")
            || lower.contains("mechanical engineering exam") || lower.contains("mechanical engineering lab")
            || lower.contains("mechanical engineering notes") || lower.contains("mechanical engineering program")
            || lower.contains("mechanical engineering major") || lower.contains("mechanical engineering degree")
            || lower.contains("mechanical engineering assignment") || lower.contains("mechanical engineering project")
            || lower.contains("machine design class") || lower.contains("machine design course")
            || lower.contains("machine design exam") || lower.contains("machine design lab")
            || lower.contains("manufacturing processes class") || lower.contains("manufacturing processes course")
            || lower.contains("manufacturing processes exam") || lower.contains("manufacturing processes lab")
            || lower.contains("manufacturing processes assignment")
            || lower.contains("mechanical vibrations") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("vibrations class") || lower.contains("vibrations course") || lower.contains("vibrations exam")
            || lower.contains("kinematics class") || lower.contains("kinematics course") || lower.contains("kinematics exam")
            || lower.contains("mechanism design class") || lower.contains("mechanism design course") || lower.contains("mechanism design exam")
            || lower.contains("statics class") && !lower.contains("electrostatics")
            || lower.contains("statics course") && !lower.contains("electrostatics")
            || lower.contains("statics exam") && !lower.contains("electrostatics")
            || lower.contains("dynamics class") && lower.contains("mechanical")
            || lower.contains("dynamics course") && lower.contains("mechanical")
            || lower.contains("dynamics exam") && lower.contains("mechanical")
            || lower.contains("tribology class") || lower.contains("tribology course") || lower.contains("tribology exam")
            || lower.contains("engineering mechanics class") || lower.contains("engineering mechanics course") || lower.contains("engineering mechanics exam") {
            return "mechanicalengineering"
        }
        // nuclearengineering — BEFORE engineering; reactor physics, neutron transport, thermal hydraulics.
        // Bare "nuclear" NOT matched (nuclearmedtech already handles nuclear medicine; nuclear chemistry
        // stays in nuclearchemistry). "fission/fusion" require engineering/reactor/class context.
        if lower.contains("nuclear engineering class") || lower.contains("nuclear engineering course")
            || lower.contains("nuclear engineering exam") || lower.contains("nuclear engineering lab")
            || lower.contains("nuclear engineering notes") || lower.contains("nuclear engineering program")
            || lower.contains("nuclear engineering major") || lower.contains("nuclear engineering degree")
            || lower.contains("nuclear engineering assignment") || lower.contains("nuclear engineering project")
            || lower.contains("nuclear reactor class") || lower.contains("nuclear reactor course")
            || lower.contains("nuclear reactor design") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("reactor physics class") || lower.contains("reactor physics course") || lower.contains("reactor physics exam")
            || lower.contains("neutron physics class") || lower.contains("neutron physics course") || lower.contains("neutron physics exam")
            || lower.contains("neutron transport") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("thermal hydraulics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("nuclear power class") || lower.contains("nuclear power course")
            || lower.contains("reactor safety class") || lower.contains("reactor safety course") || lower.contains("reactor safety exam")
            || lower.contains("nuclear fuel") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("design"))
            || lower.contains("nuclear criticality") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("analysis"))
            || lower.contains("mcnp") && (lower.contains("class") || lower.contains("simulation") || lower.contains("lab") || lower.contains("course"))
            || lower.contains("nuclear waste management class") || lower.contains("nuclear waste management course")
            || lower.contains("fission class") || lower.contains("fission course") || lower.contains("fission exam")
            || lower.contains("fusion reactor") && (lower.contains("class") || lower.contains("course") || lower.contains("engineering")) {
            return "nuclearengineering"
        }
        // materialstesting — BEFORE engineering; tensile/compressive/Charpy/hardness/fatigue testing lab.
        // Bare "materials" stays in materialscience or engineering. Characterization stays in
        // materialscharacterization (earlier). "impact test" requires materials context.
        if lower.contains("tensile test") && (lower.contains("class") || lower.contains("lab") || lower.contains("course") || lower.contains("report") || lower.contains("data") || lower.contains("exam"))
            || lower.contains("compressive test") && (lower.contains("class") || lower.contains("lab") || lower.contains("course") || lower.contains("report") || lower.contains("exam"))
            || lower.contains("charpy test") || lower.contains("charpy impact")
            || lower.contains("hardness test") && (lower.contains("class") || lower.contains("lab") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("rockwell hardness") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("test"))
            || lower.contains("brinell hardness") && (lower.contains("class") || lower.contains("lab") || lower.contains("test"))
            || lower.contains("vickers hardness") && (lower.contains("class") || lower.contains("lab") || lower.contains("test"))
            || lower.contains("fatigue test") && (lower.contains("class") || lower.contains("lab") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("fatigue testing lab") || lower.contains("materials testing lab")
            || lower.contains("materials testing class") || lower.contains("materials testing course") || lower.contains("materials testing exam")
            || lower.contains("stress-strain") && (lower.contains("class") || lower.contains("lab") || lower.contains("test") || lower.contains("curve") || lower.contains("exam"))
            || lower.contains("stress strain") && (lower.contains("class") || lower.contains("lab") || lower.contains("test") || lower.contains("exam"))
            || lower.contains("yield strength") && (lower.contains("class") || lower.contains("lab") || lower.contains("test") || lower.contains("exam"))
            || lower.contains("ultimate tensile strength") && (lower.contains("class") || lower.contains("lab") || lower.contains("test"))
            || lower.contains("fracture toughness") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("test"))
            || lower.contains("creep test") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("materials"))
            || lower.contains("impact test") && lower.contains("materials") && (lower.contains("class") || lower.contains("lab") || lower.contains("course")) {
            return "materialstesting"
        }
        // biomedicalengineering — BEFORE engineering; biomechanics, biomaterials, bioinstrumentation,
        // medical device design. "biomedical engineering" removed from generic engineering below.
        if lower.contains("biomedical engineering class") || lower.contains("biomedical engineering course")
            || lower.contains("biomedical engineering exam") || lower.contains("biomedical engineering lab")
            || lower.contains("biomedical engineering notes") || lower.contains("biomedical engineering program")
            || lower.contains("biomedical engineering major") || lower.contains("biomedical engineering degree")
            || lower.contains("biomedical engineering assignment") || lower.contains("biomedical engineering project")
            || word("bme") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab")) && lower.contains("engineering")
            || lower.contains("biomechanics class") || lower.contains("biomechanics course")
            || lower.contains("biomechanics exam") || lower.contains("biomechanics lab")
            || lower.contains("biomaterials class") || lower.contains("biomaterials course")
            || lower.contains("biomaterials exam") || lower.contains("biomaterials lab")
            || lower.contains("bioinstrumentation") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("medical device design") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("project"))
            || lower.contains("medical imaging class") || lower.contains("medical imaging course") || lower.contains("medical imaging exam")
            || lower.contains("tissue engineering class") || lower.contains("tissue engineering course") || lower.contains("tissue engineering exam")
            || lower.contains("biosignal processing") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("physiological modeling") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("rehabilitation engineering") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("project")) {
            return "biomedicalengineering"
        }
        // chemicalengineering — BEFORE engineering; transport phenomena, unit operations, mass
        // transfer, reaction engineering. Reactor-simulation tools (CSTR/PFR/Aspen) already owned
        // by processengineering. "chemical engineering" removed from generic engineering below.
        if lower.contains("chemical engineering class") || lower.contains("chemical engineering course")
            || lower.contains("chemical engineering exam") || lower.contains("chemical engineering lab")
            || lower.contains("chemical engineering notes") || lower.contains("chemical engineering program")
            || lower.contains("chemical engineering major") || lower.contains("chemical engineering degree")
            || lower.contains("chemical engineering assignment") || lower.contains("chemical engineering project")
            || lower.contains("transport phenomena") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("hw") || lower.contains("assignment"))
            || lower.contains("unit operations class") || lower.contains("unit operations course")
            || lower.contains("unit operations exam") || lower.contains("unit operations lab")
            || lower.contains("mass transfer class") || lower.contains("mass transfer course")
            || lower.contains("mass transfer exam") || lower.contains("mass transfer lab")
            || lower.contains("reaction engineering class") || lower.contains("reaction engineering course") || lower.contains("reaction engineering exam")
            || lower.contains("chemical reaction engineering") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("heat transfer class") || lower.contains("heat transfer course")
            || lower.contains("heat transfer exam") || lower.contains("heat transfer lab")
            || lower.contains("thermodynamics class") && lower.contains("chemical")
            || lower.contains("thermodynamics course") && lower.contains("chemical")
            || lower.contains("thermodynamics exam") && lower.contains("chemical")
            || lower.contains("fluid mechanics class") && lower.contains("chemical") {
            return "chemicalengineering"
        }
        // thermodynamics — positioned AFTER chemicalengineering (which owns "thermodynamics class chemical")
        // and BEFORE engineering. Catches standalone engineering/applied thermodynamics class/exam.
        // "chemical thermodynamics" → physicalchemistry (earlier). "thermodynamics lab" → experimentalphysics (earlier).
        // "thermodynamics class chemical" → chemicalengineering (immediately above). Bare "entropy"
        // or "enthalpy" without class/thermo context NOT matched.
        if lower.contains("thermodynamics class") && !lower.contains("chemical")
            || lower.contains("thermodynamics course") && !lower.contains("chemical")
            || lower.contains("thermodynamics exam") && !lower.contains("chemical")
            || lower.contains("thermodynamics notes") && !lower.contains("chemical")
            || lower.contains("thermodynamics problem set") && !lower.contains("chemical")
            || lower.contains("thermodynamics homework") && !lower.contains("chemical")
            || lower.contains("thermodynamics textbook") && !lower.contains("chemical")
            || lower.contains("thermodynamics assignment") && !lower.contains("chemical")
            || lower.contains("engineering thermodynamics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("problem set") || lower.contains("hw"))
            || lower.contains("applied thermodynamics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("rankine cycle") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("thermo") || lower.contains("engineering"))
            || lower.contains("carnot cycle") && (lower.contains("class") || lower.contains("thermo") || lower.contains("exam") || lower.contains("engineering"))
            || lower.contains("heat engine") && (lower.contains("class") || lower.contains("thermo") || lower.contains("exam") || lower.contains("cycle"))
            || lower.contains("otto cycle") && (lower.contains("class") || lower.contains("thermo") || lower.contains("exam"))
            || lower.contains("diesel cycle") && (lower.contains("class") || lower.contains("thermo") || lower.contains("exam"))
            || lower.contains("steam tables") && (lower.contains("class") || lower.contains("thermo") || lower.contains("exam") || lower.contains("engineering"))
            || lower.contains("refrigeration cycle") && (lower.contains("class") || lower.contains("thermo") || lower.contains("exam") || lower.contains("engineering"))
            || lower.contains("second law of thermodynamics") && (lower.contains("class") || lower.contains("exam") || lower.contains("engineering"))
            || lower.contains("first law of thermodynamics") && (lower.contains("class") || lower.contains("exam") || lower.contains("engineering"))
            || lower.contains("entropy") && lower.contains("thermo") && (lower.contains("class") || lower.contains("exam"))
            || lower.contains("enthalpy") && lower.contains("thermo") && (lower.contains("class") || lower.contains("exam")) {
            return "thermodynamics"
        }
        // engineering — positioned before datascience and research so tool/hardware-specific terms
        // (solidworks, arduino, pcb) don't fall through to generic research via word("lab").
        // "civil engineering" → civilengineering; "mechanical/biomedical/chemical engineering" →
        // dedicated branches above. Generic mechanical/chemical/biomedical text still catches here.
        if word("solidworks") || lower.contains("fusion 360") || word("ansys")
            || word("microcontroller") || word("arduino") || lower.contains("raspberry pi")
            || word("pcb") || lower.contains("circuit board") || lower.contains("circuit diagram")
            || lower.contains("circuit design")
            || lower.contains("mechanical engineering") || lower.contains("chemical engineering")
            || lower.contains("biomedical engineering") || lower.contains("computer engineering")
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
        // computationalbiology — positioned BEFORE bioinformatics so systems biology,
        // mathematical biology, and biological modeling with class/course context route here.
        // Generic "computational biology" stays in bioinformatics; class context fires here first.
        if lower.contains("computational biology class") || lower.contains("computational biology course")
            || lower.contains("computational biology exam") || lower.contains("computational biology assignment")
            || lower.contains("computational biology program") || lower.contains("computational biology major")
            || lower.contains("systems biology") || lower.contains("mathematical biology")
            || lower.contains("population dynamics model") || lower.contains("population dynamics class")
            || lower.contains("population dynamics course") || lower.contains("population dynamics exam")
            || lower.contains("biological modeling") || lower.contains("biological simulation")
            || lower.contains("network biology") || lower.contains("biological network analysis")
            || (lower.contains("gene regulatory network") && (lower.contains("class") || lower.contains("model")))
            || (lower.contains("regulatory network") && lower.contains("biolog") && lower.contains("model"))
            || (lower.contains("protein interaction network") && lower.contains("class")) {
            return "computationalbiology"
        }
        // proteomics — positioned BEFORE bioinformatics so mass-spectrometry based protein
        // identification, 2D-PAGE, and shotgun proteomics route to a dedicated pool.
        // Bare "proteomics" removed from bioinformatics branch below.
        if lower.contains("proteomics") || lower.contains("proteomic")
            || lower.contains("mass spectrometry") && (lower.contains("protein") || lower.contains("proteomics") || lower.contains("peptide"))
            || lower.contains("lc-ms/ms") && (lower.contains("protein") || lower.contains("proteomics") || lower.contains("peptide"))
            || lower.contains("shotgun proteomics") || lower.contains("bottom-up proteomics")
            || lower.contains("top-down proteomics") || lower.contains("data-dependent acquisition")
            || lower.contains("dda proteomics") || lower.contains("dia proteomics")
            || lower.contains("2d-page") || lower.contains("2d page") || lower.contains("two-dimensional gel")
            || lower.contains("protein identification") && (lower.contains("mass spec") || lower.contains("proteomics") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("peptide sequencing") && (lower.contains("mass spec") || lower.contains("proteomics") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("tandem mass spectrometry") && (lower.contains("protein") || lower.contains("proteomics") || lower.contains("peptide"))
            || lower.contains("msms") && (lower.contains("protein") || lower.contains("proteomics") || lower.contains("peptide"))
            || lower.contains("protein quantification") && (lower.contains("mass spec") || lower.contains("proteomics") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("itraq") || lower.contains("tmtlabeling") || lower.contains("tmt labeling") && lower.contains("proteomics")
            || lower.contains("label-free quantification") && lower.contains("proteomics")
            || lower.contains("maxquant") && lower.contains("proteomics")
            || lower.contains("mascot search") && lower.contains("proteomics")
            || lower.contains("sequest") && lower.contains("protein")
            || lower.contains("protein atlas") && (lower.contains("class") || lower.contains("research") || lower.contains("proteomics")) {
            return "proteomics"
        }
        // metabolomics — positioned BEFORE bioinformatics so NMR-based metabolomics, LC-MS
        // metabolite profiling, and metabolic flux analysis route here.
        // Bare "metabolomics" removed from bioinformatics branch below.
        if lower.contains("metabolomics") || lower.contains("metabolomic")
            || lower.contains("metabolite profiling") || lower.contains("metabolite identification")
            || lower.contains("nmr metabolomics") || lower.contains("nmr-based metabolomics")
            || lower.contains("lc-ms metabolomics") || lower.contains("metabolomic analysis")
            || lower.contains("metabolome") && (lower.contains("class") || lower.contains("research") || lower.contains("lab") || lower.contains("analysis"))
            || lower.contains("metabolic flux analysis") && !lower.contains("systems biology")
            || lower.contains("metabolic flux balance") && (lower.contains("class") || lower.contains("lab") || lower.contains("metabolomics"))
            || lower.contains("untargeted metabolomics") || lower.contains("targeted metabolomics")
            || lower.contains("nmr spectroscopy") && (lower.contains("metabolomics") || lower.contains("metabolite"))
            || lower.contains("mass spectrometry") && lower.contains("metabolomics")
            || lower.contains("met-xcms") || lower.contains("xcms") && lower.contains("metabolomics")
            || lower.contains("metaboanalyst") && (lower.contains("class") || lower.contains("research") || lower.contains("lab") || lower.contains("metabolomics"))
            || lower.contains("metabolomics class") || lower.contains("metabolomics course")
            || lower.contains("metabolomics exam") || lower.contains("metabolomics lab")
            || lower.contains("metabolomics research") || lower.contains("metabolomics program") {
            return "metabolomics"
        }
        // bioinformatics — positioned after datascience (ML tools may co-occur) and before ux
        // so sequence analysis, genomics, and computational-biology pipelines route here.
        // Bare "biology" stays in studying; "biomedical engineering" stays in engineering above.
        // "proteomics" and "metabolomics" now owned by dedicated branches above.
        if lower.contains("bioinformatics") || lower.contains("computational biology")
            || lower.contains("genomics")
            || lower.contains("transcriptomics")
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
        // environmentalplanning — positioned AFTER urbanplanning and BEFORE realestate.
        // Catches EIS/EIA preparation, NEPA/CEQA compliance coursework, and environmental
        // permitting classes. "environmental law" and bare word("nepa") stay in environmentallaw
        // (fires much later). "environmental science" stays in enviro. "environmental engineering"
        // stays in enviroengineering.
        if lower.contains("environmental impact statement") || lower.contains("environmental impact assessment")
            || word("eis") && (lower.contains("environmental") || lower.contains("class") || lower.contains("preparation") || lower.contains("review") || lower.contains("planning"))
            || word("eia") && (lower.contains("environmental") || lower.contains("assessment") || lower.contains("class") || lower.contains("planning"))
            || lower.contains("nepa compliance") || lower.contains("nepa class") || lower.contains("nepa course") || lower.contains("nepa exam") || lower.contains("nepa training") || lower.contains("nepa review process")
            || word("ceqa")
            || word("sepa") && (lower.contains("environmental") || lower.contains("planning") || lower.contains("compliance") || lower.contains("class"))
            || lower.contains("environmental permitting") || lower.contains("environmental permit") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("application") || lower.contains("planning"))
            || lower.contains("environmental review") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("process") || lower.contains("planning"))
            || lower.contains("environmental planning") && !lower.contains("law") && !lower.contains("legislation")
            || lower.contains("land use planning") && lower.contains("environmental")
            || lower.contains("eis preparation") || lower.contains("eis writing") || lower.contains("eis scoping")
            || lower.contains("cumulative impact assessment") || lower.contains("environmental scoping")
            || lower.contains("mitigation monitoring") {
            return "environmentalplanning"
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
        // hrmanagement — positioned AFTER businessintelligence and BEFORE business so SHRM/PHR/SPHR
        // certification prep and dedicated HR management coursework route to a focused pool.
        // Generic "human resources" and "hr management" remain in the business branch below.
        if lower.contains("shrm-cp") || lower.contains("shrm-scp") || lower.contains("shrm cp")
            || lower.contains("shrm scp") || lower.contains("shrm certification")
            || (word("shrm") && (lower.contains("exam") || lower.contains("cert") || lower.contains("prep") || lower.contains("study") || lower.contains("class")))
            || lower.contains("phr exam") || lower.contains("phr certification") || lower.contains("phr prep")
            || lower.contains("phr study") || lower.contains("phr class")
            || lower.contains("sphr exam") || lower.contains("sphr certification") || lower.contains("sphr prep")
            || lower.contains("sphr study") || lower.contains("sphr class")
            || lower.contains("aphr exam") || lower.contains("aphr certification") || lower.contains("aphr prep")
            || (word("hrci") && (lower.contains("exam") || lower.contains("cert") || lower.contains("prep") || lower.contains("study")))
            || lower.contains("human resource management class") || lower.contains("human resource management course")
            || lower.contains("human resource management exam") || lower.contains("human resource management program")
            || lower.contains("human resource management degree") || lower.contains("human resource management major")
            || lower.contains("human resources management class") || lower.contains("human resources management course")
            || lower.contains("hr management class") || lower.contains("hr management course")
            || lower.contains("hr management exam") || lower.contains("hr management program")
            || lower.contains("talent management class") || lower.contains("talent management course")
            || lower.contains("talent acquisition class") || lower.contains("talent acquisition course")
            || lower.contains("compensation and benefits class") || lower.contains("compensation and benefits course")
            || lower.contains("employee relations class") || lower.contains("employee relations course")
            || lower.contains("hr analytics class") || lower.contains("hr analytics course")
            || lower.contains("workforce planning class") || lower.contains("workforce planning course")
            || lower.contains("hris class") || lower.contains("hris course") || lower.contains("hris exam")
            || lower.contains("dei class") || lower.contains("dei certification")
            || (lower.contains("diversity and inclusion class") && (lower.contains("hr") || lower.contains("human resource") || lower.contains("cert") || lower.contains("exam"))) {
            return "hrmanagement"
        }
        // changemanagement — positioned AFTER hrmanagement and BEFORE business so Prosci
        // certification prep, ADKAR/Kotter coursework, CCMP exam prep, and organizational
        // development classes route here. Distinct from projectmanagement (PMP/agile) and
        // business (MBA-level strategic topics).
        if lower.contains("change management class") || lower.contains("change management course")
            || lower.contains("change management exam") || lower.contains("change management certification")
            || lower.contains("change management program") || lower.contains("change management assignment")
            || lower.contains("change management professional") || lower.contains("change management training")
            || lower.contains("prosci certification") || lower.contains("prosci program") || lower.contains("prosci training")
            || (word("prosci") && (lower.contains("class") || lower.contains("exam") || lower.contains("cert") || lower.contains("prep")))
            || lower.contains("adkar model") || lower.contains("adkar framework")
            || (word("adkar") && (lower.contains("class") || lower.contains("course") || lower.contains("assignment") || lower.contains("exam")))
            || lower.contains("kotter's model") || lower.contains("kotter model") || lower.contains("kotter change")
            || (word("ccmp") && (lower.contains("exam") || lower.contains("cert") || lower.contains("class") || lower.contains("prep") || lower.contains("study")))
            || lower.contains("change leadership class") || lower.contains("change leadership course")
            || lower.contains("organizational change class") || lower.contains("organizational change course")
            || lower.contains("organizational change management class") || lower.contains("organizational change management course")
            || lower.contains("organizational development class") || lower.contains("organizational development course")
            || lower.contains("organizational development exam") || lower.contains("organizational development program")
            || lower.contains("apmg change management") || lower.contains("change agent certification")
            || lower.contains("managing organizational change") {
            return "changemanagement"
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
        // clinicalresearch — positioned BEFORE translationalresearch so CRC/CRA/GCP study tasks
        // route here. "IRB" alone stays in bioethics (fires much earlier).
        if lower.contains("clinical research coordinator") || lower.contains("clinical research associate")
            || lower.contains("crc certification") || lower.contains("crc class") || lower.contains("crc exam")
            || lower.contains("crc program") || lower.contains("crc training")
            || lower.contains("cra certification") || lower.contains("cra class") || lower.contains("cra exam")
            || lower.contains("cra training") || lower.contains("clinical research class")
            || lower.contains("clinical research course") || lower.contains("clinical research exam")
            || lower.contains("clinical research program") || lower.contains("clinical research training")
            || lower.contains("clinical research certification") || lower.contains("clinical research notes")
            || lower.contains("clinical research assignment")
            || word("acrp") && (lower.contains("class") || lower.contains("exam") || lower.contains("certification") || lower.contains("training") || lower.contains("study"))
            || word("socra") || lower.contains("socra exam") || lower.contains("socra certification")
            || lower.contains("gcp training") || lower.contains("gcp certification") || lower.contains("gcp class")
            || lower.contains("gcp exam") || lower.contains("good clinical practice") && (lower.contains("class") || lower.contains("training") || lower.contains("certification"))
            || lower.contains("clinical trial protocol") && (lower.contains("class") || lower.contains("course") || lower.contains("review") || lower.contains("notes") || lower.contains("write"))
            || lower.contains("study monitoring") && lower.contains("clinical")
            || lower.contains("ctms") && (lower.contains("class") || lower.contains("training") || lower.contains("clinical"))
            || lower.contains("case report form") && (lower.contains("clinical") || lower.contains("trial") || lower.contains("class"))
            || lower.contains("clinical data management") && (lower.contains("class") || lower.contains("course") || lower.contains("training") || lower.contains("certification"))
            || lower.contains("investigational drug") && (lower.contains("class") || lower.contains("course") || lower.contains("study"))
            || lower.contains("site monitoring visit") || lower.contains("clinical monitoring visit")
            || lower.contains("clinical operations class") || lower.contains("clinical operations course")
            || lower.contains("regulatory affairs clinical") || lower.contains("informed consent clinical") {
            return "clinicalresearch"
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
        // digitalhumanities — positioned BEFORE research so digital humanities projects,
        // text mining, distant reading, and cultural analytics tasks route here rather than
        // the generic research pool. Bare "digital" alone is NOT matched.
        if lower.contains("digital humanities") || lower.contains("humanities computing")
            || lower.contains("computational humanities") || lower.contains("distant reading")
            || lower.contains("cultural analytics") || lower.contains("spatial humanities")
            || lower.contains("digital history class") || lower.contains("digital history course")
            || lower.contains("digital history program") || lower.contains("digital history exam")
            || (lower.contains("text mining") && (lower.contains("humanities") || lower.contains("literary") || lower.contains("historical") || lower.contains("corpus")))
            || lower.contains("digital archives class") || lower.contains("digital archive project")
            || (lower.contains("network analysis") && (lower.contains("humanities") || lower.contains("literary") || lower.contains("historical text")))
            || (lower.contains("corpus analysis") && (lower.contains("humanities") || lower.contains("literary")))
            || (lower.contains("topic modeling") && (lower.contains("humanities") || lower.contains("literary") || lower.contains("historical"))) {
            return "digitalhumanities"
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
        // internalaudit — positioned AFTER accounting and BEFORE forensicaccounting.
        // Catches CIA certification, IIA standards, internal controls, and SOX audit prep
        // distinct from forensicaccounting (fraud investigation) and qualitymanagement (ISO).
        // "CISA" stays in informationassurance (fires much earlier). Bare "CIA" NOT matched alone.
        if lower.contains("internal audit") || lower.contains("internal auditing")
            || lower.contains("internal auditor") || lower.contains("internal controls class")
            || lower.contains("internal controls course") || lower.contains("internal controls exam")
            || lower.contains("internal controls assignment") || lower.contains("internal control testing")
            || (word("cia") || lower.contains("cia exam") || lower.contains("cia certification") || lower.contains("cia cert")) && (lower.contains("audit") || lower.contains("iia") || lower.contains("internal"))
            || lower.contains("iia standard") || lower.contains("iia certification") || lower.contains("iia program")
            || lower.contains("sox audit") || lower.contains("sarbanes-oxley audit")
            || lower.contains("sox compliance") && lower.contains("audit")
            || lower.contains("audit planning class") || lower.contains("audit planning course") || lower.contains("audit planning exam")
            || lower.contains("it audit class") || lower.contains("it audit course") || lower.contains("it audit program") || lower.contains("it audit cert")
            || lower.contains("cobit") && (lower.contains("audit") || lower.contains("class") || lower.contains("course") || lower.contains("cert"))
            || lower.contains("risk-based audit") || lower.contains("risk based audit")
            || lower.contains("audit report writing") && (lower.contains("class") || lower.contains("course"))
            || lower.contains("audit sampling") && (lower.contains("class") || lower.contains("course"))
            || lower.contains("control testing") && (lower.contains("class") || lower.contains("course") || lower.contains("audit"))
            || lower.contains("audit engagement") && (lower.contains("class") || lower.contains("course")) {
            return "internalaudit"
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
        // computationalfinance — positioned AFTER forensicaccounting and BEFORE finance so
        // quantitative-finance, financial-engineering, and algorithmic-trading coursework route here.
        // Generic finance terms (DCF, LBO, CFA, balance sheets) still route to finance below.
        if lower.contains("quantitative finance") || lower.contains("quant finance")
            || lower.contains("quant analyst") && (lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("finance"))
            || (lower.contains("financial engineering") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("program") || lower.contains("degree") || lower.contains("major")))
            || (lower.contains("algorithmic trading") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("project") || lower.contains("strategy")))
            || lower.contains("black-scholes") || lower.contains("black scholes")
            || (lower.contains("monte carlo simulation") && (lower.contains("finance") || lower.contains("pricing") || lower.contains("option") || lower.contains("risk") || lower.contains("quant")))
            || (lower.contains("stochastic calculus") && (lower.contains("finance") || lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || (lower.contains("options pricing") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("model")))
            || (lower.contains("option pricing") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("model")))
            || (lower.contains("derivatives pricing") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || lower.contains("financial mathematics") || lower.contains("mathematical finance")
            || lower.contains("computational finance")
            || (lower.contains("math finance") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("program")))
            || lower.contains("risk-neutral pricing") || lower.contains("risk neutral pricing")
            || (lower.contains("portfolio optimization") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("quant")))
            || (lower.contains("high frequency trading") && (lower.contains("class") || lower.contains("course") || lower.contains("algo") || lower.contains("strategy"))) {
            return "computationalfinance"
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
        // insurancefinance — positioned AFTER behavioraleconomics and BEFORE budget.
        // Catches CPCU/LOMA/AINS designation prep, insurance licensing exams, underwriting
        // coursework, and P&C insurance classes. "title insurance" stays in realestate (fires earlier).
        // Bare "insurance" alone NOT matched — requires specific professional/educational context.
        if lower.contains("insurance underwriting")
            || lower.contains("property and casualty") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("certification") || lower.contains("license") || lower.contains("insurance"))
            || lower.contains("p&c insurance") || lower.contains("p & c insurance")
            || word("cpcu")
            || lower.contains("loma program") || lower.contains("loma exam") || lower.contains("loma designation") || lower.contains("loma certification")
            || word("ains") && (lower.contains("insurance") || lower.contains("designation") || lower.contains("certification") || lower.contains("exam"))
            || lower.contains("life insurance") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("licensing") || lower.contains("license exam") || lower.contains("certification"))
            || lower.contains("health insurance") && (lower.contains("licensing") || lower.contains("license exam") || lower.contains("class") || lower.contains("course") || lower.contains("certification"))
            || lower.contains("insurance licensing") || lower.contains("insurance license exam") || lower.contains("insurance state exam")
            || lower.contains("insurance principles") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("insurance regulation") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("risk and insurance") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("reinsurance") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("study") || lower.contains("assignment")) {
            return "insurancefinance"
        }
        if word("budget") || word("budgeting") || word("budgets")
            || word("spreadsheet") || word("spreadsheets")
            || word("finances") || word("financial") || word("accounting") || word("bookkeeping")
            || word("taxes") || lower.contains("tax return") || word("invoice") || word("invoices") {
            return "budget"
        }
        // tesol — positioned BEFORE education so TESOL/TEFL certification prep, ESL/ELL
        // teaching practicums, and second-language-acquisition coursework route here rather than
        // the generic education pool. "English class" for native speakers stays in studying.
        if lower.contains("tesol") || lower.contains("tefl")
            || lower.contains("esl teacher") || lower.contains("ell teacher")
            || lower.contains("esl practicum") || lower.contains("esl student teaching")
            || lower.contains("english language teaching") || lower.contains("english language learner")
            || lower.contains("second language acquisition") || lower.contains("second language teaching")
            || lower.contains("english as a second language") || lower.contains("english as an additional language")
            || word("celta") && (lower.contains("class") || lower.contains("cert") || lower.contains("exam") || lower.contains("course") || lower.contains("teach") || lower.contains("program"))
            || lower.contains("elt program") || lower.contains("elt class") || lower.contains("elt course")
            || lower.contains("applied linguistics") && (lower.contains("teach") || lower.contains("esl") || lower.contains("tesol") || lower.contains("language acquisition"))
            || lower.contains("teaching english") && (lower.contains("abroad") || lower.contains("foreign language") || lower.contains("second language") || lower.contains("learners") || lower.contains("esl") || lower.contains("ell"))
            || lower.contains("efl teaching") || lower.contains("efl class") || lower.contains("efl course")
            || lower.contains("language acquisition class") || lower.contains("language acquisition course")
            || lower.contains("language acquisition exam") || lower.contains("language acquisition program") {
            return "tesol"
        }
        // specialeducation — positioned AFTER tesol and BEFORE education so SPED teacher
        // credentialing, IEP writing, and IDEA/IDEIA coursework get a dedicated pool.
        // Bare "lesson plan" and "classroom management" stay in education (fires after this).
        if lower.contains("special education") || lower.contains("special ed ")
            || word("sped") && (lower.contains("class") || lower.contains("teacher") || lower.contains("credential") || lower.contains("cert") || lower.contains("program") || lower.contains("teach") || lower.contains("notes") || lower.contains("exam") || lower.contains("practicum"))
            || lower.contains("special ed teacher") || lower.contains("special ed class")
            || lower.contains("special ed program") || lower.contains("special ed credential")
            || lower.contains("special ed certification")
            || lower.contains("individuals with disabilities education")
            || word("ideia") || lower.contains("idea act") && lower.contains("special")
            || lower.contains("exceptional learners") || lower.contains("exceptional children")
            || lower.contains("learning disabilities class") || lower.contains("learning disabilities course")
            || lower.contains("504 plan") || lower.contains("section 504") && (lower.contains("class") || lower.contains("course") || lower.contains("education"))
            || lower.contains("inclusion classroom") || lower.contains("inclusion teaching")
            || lower.contains("response to intervention") && (lower.contains("class") || lower.contains("course") || lower.contains("special") || lower.contains("sped") || lower.contains("teach"))
            || lower.contains("autism spectrum") && (lower.contains("class") || lower.contains("teach") || lower.contains("student") || lower.contains("iep") || lower.contains("education"))
            || lower.contains("iep writing") || lower.contains("iep development") || lower.contains("iep goals")
            || lower.contains("praxis special education") || lower.contains("praxis sped")
            || lower.contains("adapted curriculum") || lower.contains("disability studies class")
            || lower.contains("individualized education program") || lower.contains("individualized education plan") {
            return "specialeducation"
        }
        // educationalleadership — positioned AFTER specialeducation and BEFORE education so
        // principal preparation, superintendent certification, and EdD programs get a dedicated pool.
        // Generic "lesson plan"/"curriculum" stays in education (fires after this).
        if lower.contains("educational leadership") || lower.contains("school leadership")
            || lower.contains("educational administration") && (lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("exam") || lower.contains("degree") || lower.contains("major"))
            || lower.contains("school administration") && (lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("principal") || lower.contains("superintendent"))
            || lower.contains("principal preparation") || lower.contains("principal certification")
            || lower.contains("principal licensure") || lower.contains("principal credential")
            || lower.contains("principal exam") && (lower.contains("class") || lower.contains("principal") || lower.contains("certification") || lower.contains("program") || lower.contains("study"))
            || lower.contains("principal program") || lower.contains("principal class") || lower.contains("principal course")
            || lower.contains("building principal") || lower.contains("school principal") && (lower.contains("class") || lower.contains("program") || lower.contains("exam") || lower.contains("prep") || lower.contains("leadership"))
            || lower.contains("superintendent certification") || lower.contains("superintendent preparation")
            || lower.contains("superintendent program") || lower.contains("superintendent exam")
            || lower.contains("k-12 administration") || lower.contains("k-12 leadership")
            || lower.contains("school administrator") && (lower.contains("class") || lower.contains("program") || lower.contains("exam") || lower.contains("leadership") || lower.contains("coursework"))
            || lower.contains("instructional leadership class") || lower.contains("instructional leadership course")
            || lower.contains("instructional leadership program") || lower.contains("instructional leadership degree")
            || lower.contains("isllc standards") || lower.contains("psel standards")
            || lower.contains("edd in education") || lower.contains("edd in leadership")
            || lower.contains("edd in educational") || lower.contains("education doctorate") && lower.contains("leadership")
            || lower.contains("educational leadership major") || lower.contains("educational leadership doctorate") {
            return "educationalleadership"
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
        // performanceanalysis — positioned BEFORE sportsanalytics so video-analysis tools (Dartfish,
        // Hudl), notational analysis, tactical/match analysis, and sports performance coaching
        // tasks route to their own pool. Bare "performance" alone NOT matched (too common).
        if lower.contains("performance analysis") && (lower.contains("sport") || lower.contains("coach") || lower.contains("athletic") || lower.contains("game") || lower.contains("match") || lower.contains("team") || lower.contains("player") || lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("performance analyst") || lower.contains("performance analysts")
            || word("dartfish") || word("hudl")
            || lower.contains("hudl class") || lower.contains("hudl training") || lower.contains("hudl analysis")
            || lower.contains("dartfish class") || lower.contains("dartfish training") || lower.contains("dartfish analysis")
            || lower.contains("video analysis") && (lower.contains("sport") || lower.contains("coach") || lower.contains("athletic") || lower.contains("match") || lower.contains("game") || lower.contains("team") || lower.contains("player"))
            || lower.contains("notational analysis") || lower.contains("match analysis") && lower.contains("sport")
            || lower.contains("tactical analysis") && (lower.contains("sport") || lower.contains("coach") || lower.contains("team") || lower.contains("class"))
            || lower.contains("coaching analytics") || lower.contains("performance coding") || lower.contains("performance tagging")
            || lower.contains("sport science analysis") || lower.contains("sports science analysis")
            || lower.contains("sports performance analysis") || lower.contains("sport performance analysis")
            || lower.contains("performance analysis class") || lower.contains("performance analysis course")
            || lower.contains("performance analysis program") || lower.contains("performance analysis exam") {
            return "performanceanalysis"
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
        // informationscience — positioned BEFORE libraryscience so information science degrees,
        // knowledge management coursework, and information retrieval classes get a dedicated pool.
        // "library and information science" / "MLIS" / cataloging stay in libraryscience below.
        // "information architecture" stays in the UX branch (fires far earlier).
        if lower.contains("information science class") || lower.contains("information science course")
            || lower.contains("information science program") || lower.contains("information science degree")
            || lower.contains("information science major") || lower.contains("information science exam")
            || lower.contains("information science school") || lower.contains("information science assignment")
            || lower.contains("asis&t") || lower.contains("asist") && (lower.contains("class") || lower.contains("conference") || lower.contains("paper") || lower.contains("research"))
            || lower.contains("information retrieval class") || lower.contains("information retrieval course")
            || lower.contains("information retrieval exam") || lower.contains("information retrieval lab")
            || lower.contains("information organization class") || lower.contains("information organization course")
            || lower.contains("digital curation class") || lower.contains("digital curation course")
            || lower.contains("digital curation exam") || lower.contains("digital curation program")
            || lower.contains("knowledge management class") || lower.contains("knowledge management course")
            || lower.contains("knowledge management exam") || lower.contains("knowledge management program")
            || lower.contains("information literacy class") || lower.contains("information literacy course")
            || lower.contains("taxonomy class") && (lower.contains("information") || lower.contains("library") || lower.contains("data") || lower.contains("knowledge"))
            || lower.contains("metadata class") && (lower.contains("information") || lower.contains("digital") || lower.contains("data"))
            || lower.contains("ontology class") && (lower.contains("information") || lower.contains("knowledge") || lower.contains("data")) {
            return "informationscience"
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
        // athletictraining — positioned AFTER exercisescience/sportsmedicine, BEFORE kinesiology
        // so ATC-credential prep, therapeutic-modalities class, and taping labs route here.
        // Compound clinical/BOC/CAATE terms already caught by sportsmedicine (fires earlier).
        // "exercise physiology" and generic "athletic training" context stay in kinesiology.
        if lower.contains("athletic trainer") || lower.contains("certified athletic trainer")
            || lower.contains("athletic training program") || lower.contains("athletic training major")
            || lower.contains("athletic training degree") || lower.contains("athletic training school")
            || lower.contains("athletic training class") || lower.contains("athletic training course")
            || lower.contains("pre-athletic training") || lower.contains("pre athletic training")
            || lower.contains("therapeutic modalities") && (lower.contains("athletic") || lower.contains("atc") || lower.contains("class") || lower.contains("course") || lower.contains("lab"))
            || lower.contains("taping and bracing") || lower.contains("bracing and taping")
            || lower.contains("athletic training room")
            || lower.contains("sport injury evaluation") && (lower.contains("class") || lower.contains("course") || lower.contains("lab"))
            || lower.contains("sports injury evaluation") && (lower.contains("class") || lower.contains("course") || lower.contains("lab"))
            || lower.contains("nata exam") || lower.contains("nata certification")
            || lower.contains("athletic training certification") && !lower.contains("clinical")
            || lower.contains("secondary school athletic training") || lower.contains("collegiate athletic training") {
            return "athletictraining"
        }
        // biomechanics — positioned BEFORE kinesiology so biomechanical analysis labs, motion
        // capture research, and joint-kinetics coursework route to a dedicated pool.
        // word("biomechanics") removed from kinesiology below.
        if word("biomechanics") || word("biomechanist") || word("biomechanical")
            || lower.contains("biomechanics lab") || lower.contains("biomechanics class")
            || lower.contains("biomechanics course") || lower.contains("biomechanics exam")
            || lower.contains("biomechanics program") || lower.contains("biomechanics major")
            || lower.contains("biomechanics research") || lower.contains("sports biomechanics")
            || lower.contains("clinical biomechanics") || lower.contains("movement biomechanics")
            || lower.contains("motion capture") && (lower.contains("class") || lower.contains("lab") || lower.contains("research") || lower.contains("analysis") || lower.contains("biomechanics"))
            || lower.contains("joint kinetics") || lower.contains("joint kinematics")
            || lower.contains("kinematic analysis") && (lower.contains("class") || lower.contains("lab") || lower.contains("research"))
            || lower.contains("kinetic analysis") && (lower.contains("class") || lower.contains("lab") || lower.contains("research"))
            || lower.contains("force plate") && (lower.contains("class") || lower.contains("lab") || lower.contains("research") || lower.contains("biomechanics"))
            || lower.contains("3d motion analysis") || lower.contains("three-dimensional motion analysis")
            || lower.contains("electromyography") && (lower.contains("class") || lower.contains("lab") || lower.contains("biomechanics") || lower.contains("research"))
            || lower.contains("gait biomechanics") || lower.contains("gait lab") && (lower.contains("class") || lower.contains("research") || lower.contains("biomechanics")) {
            return "biomechanics"
        }
        // kinesiology — positioned before fitness so exercise physiology,
        // and physical therapy professional terms route here rather than the generic fitness pool.
        // word("biomechanics") now caught by biomechanics branch above.
        // "athletic training" compound academic terms now caught by athletictraining branch above.
        if word("kinesiology") || word("kinesiologist")
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
        // yogapilates — positioned BEFORE fitness so yoga-teacher-training and pilates-instructor
        // certification tasks get a dedicated pool. Generic word("yoga")/word("pilates") stay in
        // fitness (bare yoga/pilates class or workout fires fitness, not yogapilates).
        if lower.contains("yoga teacher training") || lower.contains("yoga instructor training")
            || lower.contains("yoga teacher certification") || lower.contains("yoga instructor certification")
            || word("ryt") && (lower.contains("200") || lower.contains("500") || lower.contains("yoga") || lower.contains("certif") || lower.contains("train"))
            || word("ytt") && (lower.contains("yoga") || lower.contains("teacher") || lower.contains("train") || lower.contains("200") || lower.contains("500"))
            || lower.contains("yoga certification exam") || lower.contains("yoga certification class")
            || lower.contains("yoga school") || lower.contains("yoga program") && (lower.contains("certif") || lower.contains("teach") || lower.contains("train"))
            || lower.contains("yoga alliance") || lower.contains("registered yoga")
            || lower.contains("pilates instructor") || lower.contains("pilates teacher")
            || lower.contains("pilates certification") || lower.contains("pilates exam")
            || lower.contains("pilates method alliance") || word("pma") && lower.contains("pilates")
            || lower.contains("pilates teacher training") || lower.contains("pilates training program")
            || lower.contains("barre instructor") || lower.contains("barre certification")
            || lower.contains("barre teacher training") {
            return "yogapilates"
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
        // foodscience — positioned BEFORE nutrition so food science degree/program and
        // IFT-track coursework route here rather than the generic dietetics pool.
        // "food safety" stays in foodsafety (fires much earlier); "nutrition plan"/"meal prep"
        // stay in fitness; bare "food science" without edu-program context remains in nutrition.
        if lower.contains("food chemistry") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam") || lower.contains("assignment"))
            || lower.contains("food microbiology") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam") || lower.contains("assignment"))
            || lower.contains("food processing") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("technology") || lower.contains("exam"))
            || lower.contains("food engineering") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("design"))
            || lower.contains("sensory evaluation") && (lower.contains("class") || lower.contains("course") || lower.contains("food") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("sensory science") && (lower.contains("food") || lower.contains("class") || lower.contains("course") || lower.contains("lab"))
            || word("ift") && (lower.contains("exam") || lower.contains("certification") || lower.contains("class") || lower.contains("food science") || lower.contains("food technology"))
            || lower.contains("food product development") || lower.contains("food product design")
            || lower.contains("food preservation") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("technology"))
            || lower.contains("food packaging") && (lower.contains("class") || lower.contains("course") || lower.contains("design") || lower.contains("science"))
            || lower.contains("food analysis lab") || lower.contains("food analysis class")
            || lower.contains("food science degree") || lower.contains("food science major")
            || lower.contains("food science program") || lower.contains("food science class")
            || lower.contains("food science exam") || lower.contains("food science lab")
            || lower.contains("food technologist") || lower.contains("food scientist") {
            return "foodscience"
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
        // musicbusiness — positioned BEFORE musicproduction so music industry coursework,
        // entertainment law (music context), music publishing, ASCAP/BMI class work, and
        // music management programs route here rather than the DAW/songwriting pool.
        // Bare "music" alone stays in musicproduction/musictheory; educational compound terms fire here.
        if lower.contains("music business") || lower.contains("music industry class")
            || lower.contains("music industry course") || lower.contains("music industry program")
            || lower.contains("music industry exam") || lower.contains("music industry major")
            || lower.contains("music industry degree") || lower.contains("music industry assignment")
            || lower.contains("music publishing class") || lower.contains("music publishing course")
            || lower.contains("music publishing program")
            || lower.contains("music management class") || lower.contains("music management course")
            || lower.contains("music management program") || lower.contains("music management major")
            || lower.contains("music marketing class") || lower.contains("music marketing course")
            || lower.contains("music marketing program")
            || lower.contains("record label management") || lower.contains("record label class")
            || lower.contains("artist management class") || lower.contains("artist management course")
            || lower.contains("music entrepreneurship") || lower.contains("music entrepreneur")
            || lower.contains("entertainment law") && (lower.contains("music") || lower.contains("artist") || lower.contains("record"))
            || lower.contains("ascap") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("licensing") || lower.contains("royalt"))
            || lower.contains("bmi") && (lower.contains("licensing") || lower.contains("royalt") || lower.contains("music publishing"))
            || lower.contains("music royalt") || lower.contains("sync licensing class")
            || lower.contains("music licensing class") || lower.contains("music licensing course")
            || lower.contains("music business degree") || lower.contains("music business major")
            || lower.contains("music business class") || lower.contains("music business course")
            || lower.contains("music business program") || lower.contains("music business exam") {
            return "musicbusiness"
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
        // ecologicalfieldwork — positioned BEFORE ecology so specific field ecology lab work
        // (transect sampling, quadrat surveys, mark-recapture) gets a dedicated callout pool.
        // Generic ecology class/course terms fall through to ecology (fires after).
        if lower.contains("transect sampling") && (lower.contains("class") || lower.contains("lab") || lower.contains("ecology") || lower.contains("field") || lower.contains("survey"))
            || lower.contains("transect survey") && (lower.contains("class") || lower.contains("ecology") || lower.contains("field") || lower.contains("lab"))
            || lower.contains("quadrat survey") && (lower.contains("class") || lower.contains("ecology") || lower.contains("field") || lower.contains("lab"))
            || lower.contains("quadrat sampling") && (lower.contains("class") || lower.contains("ecology") || lower.contains("field") || lower.contains("lab"))
            || lower.contains("mark-recapture") && (lower.contains("class") || lower.contains("ecology") || lower.contains("field") || lower.contains("lab") || lower.contains("study"))
            || lower.contains("mark recapture") && (lower.contains("class") || lower.contains("ecology") || lower.contains("field") || lower.contains("lab") || lower.contains("study"))
            || lower.contains("species richness") && (lower.contains("class") || lower.contains("ecology") || lower.contains("field") || lower.contains("lab") || lower.contains("survey"))
            || lower.contains("biodiversity survey") && (lower.contains("class") || lower.contains("ecology") || lower.contains("field") || lower.contains("lab"))
            || lower.contains("biodiversity index") && (lower.contains("class") || lower.contains("ecology") || lower.contains("field") || lower.contains("lab"))
            || lower.contains("shannon diversity") && (lower.contains("class") || lower.contains("ecology") || lower.contains("field") || lower.contains("lab"))
            || lower.contains("species abundance") && (lower.contains("class") || lower.contains("ecology") || lower.contains("field") || lower.contains("lab") || lower.contains("survey"))
            || lower.contains("point count survey") && (lower.contains("ecology") || lower.contains("field") || lower.contains("class") || lower.contains("lab") || lower.contains("bird"))
            || lower.contains("pitfall trap") && (lower.contains("ecology") || lower.contains("class") || lower.contains("lab") || lower.contains("field"))
            || lower.contains("field ecology lab") || lower.contains("field ecology report")
            || lower.contains("ecological sampling") && (lower.contains("class") || lower.contains("lab") || lower.contains("field") || lower.contains("ecology"))
            || lower.contains("population estimate") && (lower.contains("ecology") || lower.contains("class") || lower.contains("field") || lower.contains("lab"))
            || lower.contains("lincoln-peterson") && (lower.contains("ecology") || lower.contains("class") || lower.contains("lab")) {
            return "ecologicalfieldwork"
        }
        // ecology — positioned BEFORE ecologyconservation so general ecology class/coursework
        // routes here. Conservation-specific terms (restoration ecology, conservation biology,
        // wildlife management) fall through to ecologyconservation below.
        // "ecology" alone without class/lab/course/exam context falls through to enviro.
        if lower.contains("ecology class") || lower.contains("ecology course")
            || lower.contains("ecology exam") || lower.contains("ecology lab")
            || lower.contains("ecology notes") || lower.contains("ecology textbook")
            || lower.contains("ecology assignment") || lower.contains("ecology lecture")
            || lower.contains("ecology problem set") || lower.contains("ecology homework")
            || lower.contains("community ecology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("ecosystem ecology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("food web") && (lower.contains("class") || lower.contains("ecology") || lower.contains("exam") || lower.contains("lab") || lower.contains("assignment"))
            || lower.contains("food chain") && (lower.contains("class") || lower.contains("ecology") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("trophic level") && (lower.contains("class") || lower.contains("ecology") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("ecological niche") && (lower.contains("class") || lower.contains("ecology") || lower.contains("exam") || lower.contains("assignment"))
            || lower.contains("biome") && (lower.contains("class") || lower.contains("ecology") || lower.contains("exam") || lower.contains("assignment") || lower.contains("lab"))
            || lower.contains("ecosystem dynamics") && (lower.contains("class") || lower.contains("ecology") || lower.contains("exam"))
            || lower.contains("species diversity") && (lower.contains("class") || lower.contains("ecology") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("carrying capacity") && (lower.contains("class") || lower.contains("ecology") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("predator-prey") && (lower.contains("class") || lower.contains("ecology") || lower.contains("exam") || lower.contains("model"))
            || lower.contains("interspecific competition") && (lower.contains("class") || lower.contains("ecology") || lower.contains("exam"))
            || lower.contains("intraspecific competition") && (lower.contains("class") || lower.contains("ecology") || lower.contains("exam"))
            || lower.contains("symbiosis") && (lower.contains("class") || lower.contains("ecology") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("nutrient cycling") && (lower.contains("class") || lower.contains("ecology") || lower.contains("exam"))
            || lower.contains("primary productivity") && (lower.contains("class") || lower.contains("ecology") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("ecological succession") && (lower.contains("class") || lower.contains("ecology") || lower.contains("exam")) {
            return "ecology"
        }
        // ecologyconservation — positioned BEFORE environmentaljustice so conservation biology,
        // restoration ecology, wildlife ecology, and species management coursework route here.
        // Generic ecology/ecosystem terms stay in enviro below.
        if lower.contains("conservation biology") || lower.contains("restoration ecology")
            || lower.contains("wildlife ecology") || lower.contains("wildlife management")
            || lower.contains("species management") || lower.contains("conservation ecology")
            || lower.contains("nature reserve") && (lower.contains("management") || lower.contains("class") || lower.contains("research"))
            || lower.contains("conservation genetics") || lower.contains("conservation genomics")
            || lower.contains("rewilding") || lower.contains("re-wilding")
            || lower.contains("habitat restoration") || lower.contains("ecological restoration")
            || lower.contains("wildlife corridor") || lower.contains("wildlife corridors")
            || lower.contains("endangered species biology") || lower.contains("threatened species")
            || lower.contains("systematic conservation planning") || lower.contains("conservation planning")
            || lower.contains("population viability analysis") || lower.contains("minimum viable population")
            || lower.contains("wildlife conservation") || lower.contains("biodiversity conservation")
            || (lower.contains("species recovery") && (lower.contains("class") || lower.contains("research") || lower.contains("plan")))
            || lower.contains("conservation science") || lower.contains("conservation research")
            || lower.contains("ecology conservation") || lower.contains("conservation ecology class")
            || lower.contains("wildlife biology") && !lower.contains("zoology")
            || lower.contains("terrestrial ecology") && (lower.contains("class") || lower.contains("lab") || lower.contains("research"))
            || lower.contains("landscape ecology") && (lower.contains("class") || lower.contains("lab") || lower.contains("research"))
            || lower.contains("population ecology") && (lower.contains("class") || lower.contains("lab") || lower.contains("research") || lower.contains("conservation")) {
            return "ecologyconservation"
        }
        // environmentaljustice — positioned BEFORE environmentalpolicy so EJ analysis, environmental
        // racism research, cumulative burden studies, and EJ-specific policy work route here.
        // Generic environmental policy/science falls through to environmentalpolicy/enviro below.
        if lower.contains("environmental justice") || lower.contains("environmental racism")
            || lower.contains("cumulative environmental burden") || lower.contains("cumulative exposure burden")
            || lower.contains("ej mapping") || word("ejscreen") || lower.contains("ej analysis")
            || lower.contains("environmental health disparity") || lower.contains("environmental health disparities")
            || lower.contains("fence-line communit") || lower.contains("fenceline communit")
            || lower.contains("sacrifice zone") || lower.contains("sacrifice zones")
            || lower.contains("just transition") && (lower.contains("environmental") || lower.contains("climate") || lower.contains("class") || lower.contains("course") || lower.contains("paper"))
            || lower.contains("environmental justice class") || lower.contains("environmental justice course")
            || lower.contains("environmental justice exam") || lower.contains("environmental justice paper")
            || lower.contains("environmental justice analysis") || lower.contains("environmental justice research")
            || lower.contains("environmental justice policy") || lower.contains("environmental justice program") {
            return "environmentaljustice"
        }
        // atmosphericchemistry — positioned BEFORE atmosphericscience to intercept research-level
        // atmospheric chemistry signals. Class/course/exam contexts for atmospheric chemistry
        // still route to atmosphericscience below. Bare "atmospheric chemistry" without
        // class/course/exam/lab/homework context is owned here for research-focused tasks.
        if lower.contains("ozone depletion") && (lower.contains("research") || lower.contains("mechanism") || lower.contains("chemistry") || lower.contains("analysis"))
            || lower.contains("ozone layer") && (lower.contains("research") || lower.contains("chemistry") || lower.contains("photolysis"))
            || lower.contains("aerosol chemistry") && (lower.contains("research") || lower.contains("analysis") || lower.contains("modeling") || lower.contains("simulation"))
            || lower.contains("tropospheric oxidation") || lower.contains("tropospheric photochemistry")
            || lower.contains("stratospheric ozone") && (lower.contains("research") || lower.contains("chemistry") || lower.contains("depletion") || lower.contains("reaction"))
            || lower.contains("oh radical") && (lower.contains("chemistry") || lower.contains("atmospheric") || lower.contains("reaction") || lower.contains("oxidation"))
            || lower.contains("voc chemistry") && (lower.contains("atmospheric") || lower.contains("research") || lower.contains("reaction"))
            || lower.contains("volatile organic compound") && (lower.contains("chemistry") || lower.contains("atmospheric") || lower.contains("reaction"))
            || lower.contains("nox chemistry") && (lower.contains("atmospheric") || lower.contains("reaction") || lower.contains("research"))
            || lower.contains("photochemical smog") && (lower.contains("research") || lower.contains("chemistry") || lower.contains("mechanism") || lower.contains("modeling"))
            || lower.contains("air quality modeling") && (lower.contains("chemistry") || lower.contains("atmospheric") || lower.contains("research"))
            || lower.contains("atmospheric chemistry research") || lower.contains("atmospheric chemistry modeling")
            || lower.contains("atmospheric chemistry simulation") || lower.contains("atmospheric chemistry analysis")
            || lower.contains("atmospheric composition") && (lower.contains("research") || lower.contains("chemistry") || lower.contains("analysis") || lower.contains("modeling"))
            || lower.contains("reactive nitrogen") && (lower.contains("atmospheric") || lower.contains("chemistry") || lower.contains("research"))
            || lower.contains("halocarbon") && (lower.contains("chemistry") || lower.contains("atmospheric") || lower.contains("research"))
            || lower.contains("sulfur chemistry") && (lower.contains("atmospheric") || lower.contains("research") || lower.contains("reaction"))
            || lower.contains("atmospheric chemistry") && !(lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("homework") || lower.contains("notes")) {
            return "atmosphericchemistry"
        }
        // atmosphericscience — positioned BEFORE environmentalscience so atmospheric science/
        // meteorology coursework (synoptic meteorology, atmospheric dynamics, mesoscale met)
        // gets a dedicated pool. Generic environmental science falls through to environmentalscience.
        if lower.contains("atmospheric science class") || lower.contains("atmospheric science course")
            || lower.contains("atmospheric science exam") || lower.contains("atmospheric science lab")
            || lower.contains("atmospheric science notes") || lower.contains("atmospheric science major")
            || lower.contains("atmospheric science program") || lower.contains("atmospheric science homework")
            || lower.contains("synoptic meteorology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("notes"))
            || lower.contains("mesoscale meteorology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("atmospheric dynamics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("notes"))
            || lower.contains("atmospheric thermodynamics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("boundary layer meteorology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("numerical weather prediction") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("model"))
            || lower.contains("nwp model") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("meteorology"))
            || lower.contains("general circulation model") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("atmospheric"))
            || lower.contains("gcm model") && (lower.contains("class") || lower.contains("course") || lower.contains("atmospheric") || lower.contains("meteorology"))
            || lower.contains("weather forecasting model") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("meteorology"))
            || lower.contains("tropospheric chemistry") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("atmospheric"))
            || lower.contains("stratospheric chemistry") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("atmospheric"))
            || lower.contains("atmospheric chemistry class") || lower.contains("atmospheric chemistry course")
            || lower.contains("atmospheric chemistry exam") || lower.contains("atmospheric chemistry lab")
            || lower.contains("meteorology class") || lower.contains("meteorology course")
            || lower.contains("meteorology exam") || lower.contains("meteorology lab")
            || lower.contains("meteorology notes") || lower.contains("meteorology homework")
            || lower.contains("meteorology major") || lower.contains("meteorology program") {
            return "atmosphericscience"
        }
        // environmentalscience — positioned BEFORE environmentalpolicy so env sci coursework
        // (earth systems, biogeochemical cycles, environmental monitoring class) gets a dedicated pool.
        // "environmental policy" routes to environmentalpolicy (fires after); "environmental health"
        // routes to environmentalhealth (fires much later).
        if lower.contains("environmental science class") || lower.contains("environmental science course")
            || lower.contains("environmental science exam") || lower.contains("environmental science lab")
            || lower.contains("environmental science major") || lower.contains("environmental science program")
            || lower.contains("environmental science notes") || lower.contains("environmental science assignment")
            || lower.contains("environmental science degree") || lower.contains("environmental science homework")
            || lower.contains("environmental science textbook") || lower.contains("environmental science lecture")
            || lower.contains("env sci class") || lower.contains("env sci course") || lower.contains("env sci exam")
            || lower.contains("envi sci class") || lower.contains("envi sci course") || lower.contains("envi sci exam")
            || lower.contains("earth systems") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("assignment"))
            || lower.contains("earth systems science") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("biogeochemical cycle") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("biogeochemical cycles") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("carbon cycle") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("environmental science") || lower.contains("env sci"))
            || lower.contains("nitrogen cycle") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("environmental science"))
            || lower.contains("watershed science") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("environmental monitoring") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("environmental sampling") && (lower.contains("class") || lower.contains("lab") || lower.contains("course"))
            || lower.contains("environmental data analysis") && (lower.contains("class") || lower.contains("lab") || lower.contains("course")) {
            return "environmentalscience"
        }
        // environmentalpolicy — positioned BEFORE enviro so environmental policy and climate policy
        // with academic/analysis context route here. Generic "environmental policy" and
        // "climate policy" without class/analysis qualifiers still fall through to enviro below.
        if lower.contains("environmental policy class") || lower.contains("environmental policy course")
            || lower.contains("environmental policy exam") || lower.contains("environmental policy paper")
            || lower.contains("environmental policy assignment") || lower.contains("environmental policy program")
            || lower.contains("environmental policy major") || lower.contains("environmental policy analysis")
            || lower.contains("environmental policy research") || lower.contains("environmental policy thesis")
            || lower.contains("climate policy class") || lower.contains("climate policy course")
            || lower.contains("climate policy exam") || lower.contains("climate policy paper")
            || lower.contains("climate policy analysis") || lower.contains("climate policy research")
            || lower.contains("climate policy thesis") || lower.contains("carbon policy")
            || lower.contains("environmental regulation class") || lower.contains("environmental regulation course")
            || lower.contains("environmental regulation exam")
            || lower.contains("emissions trading class") || lower.contains("cap-and-trade class")
            || lower.contains("carbon tax class") || lower.contains("carbon tax assignment")
            || (lower.contains("climate legislation") && (lower.contains("class") || lower.contains("course") || lower.contains("paper")))
            || lower.contains("environmental governance class") || lower.contains("environmental governance course")
            || lower.contains("climate adaptation policy") || lower.contains("climate mitigation policy")
            || lower.contains("green new deal class") || lower.contains("green new deal course") {
            return "environmentalpolicy"
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
        // translationstudies — positioned BEFORE language so literary translation, CAT tools,
        // and translation studies coursework route here. Generic "translate this" / bare word("translation")
        // stays in language below. Court/conference interpreting stays in interpreting branch above.
        // "translational research" (biomedical) fires much earlier so no conflict.
        if lower.contains("translation studies") || lower.contains("translation theory")
            || lower.contains("translation research") || lower.contains("translation scholarship")
            || lower.contains("literary translation") || lower.contains("literary translator")
            || lower.contains("translator training") || lower.contains("translation quality assessment")
            || lower.contains("translation pedagogy") || lower.contains("translation class")
            || lower.contains("translation course") || lower.contains("translation program")
            || lower.contains("translation exam") || lower.contains("translation major")
            || lower.contains("translation degree")
            || lower.contains("cat tool") || lower.contains("cat tools")
            || word("trados") || word("memoq") || word("omegat") || word("wordfast")
            || (lower.contains("localization") && (lower.contains("class") || lower.contains("course") || lower.contains("project") || lower.contains("assignment") || lower.contains("translation")))
            || lower.contains("l10n class") || lower.contains("l10n project")
            || (lower.contains("subtitling") && (lower.contains("translation") || lower.contains("class") || lower.contains("project")))
            || (lower.contains("post-editing") && (lower.contains("translation") || lower.contains("machine translation")))
            || lower.contains("machine translation quality") || lower.contains("mt post-editing") {
            return "translationstudies"
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
        // animalwelfare — positioned BEFORE veterinarytechnology and veterinary so zoo
        // management, IACUC protocol, and wildlife rehabilitation tasks get a dedicated pool.
        // "animal science" and "animal behavior" in a DVM/vet-school context stay in veterinary.
        if lower.contains("animal welfare") || lower.contains("animal care and use")
            || lower.contains("iacuc") || lower.contains("institutional animal care")
            || lower.contains("zoo management") || word("zookeeper")
            || lower.contains("zoo science") || lower.contains("zoo studies")
            || lower.contains("zoo biology") || lower.contains("zoo animal") && (lower.contains("class") || lower.contains("care") || lower.contains("management") || lower.contains("welfare"))
            || lower.contains("zoological studies") || lower.contains("zoological science")
            || lower.contains("wildlife rehabilitation") || lower.contains("wildlife rehab")
            || lower.contains("wildlife care") || lower.contains("wildlife rescue")
            || lower.contains("shelter medicine") || lower.contains("animal shelter management")
            || lower.contains("humane education") || lower.contains("animal ethics")
            || lower.contains("animal welfare science") || lower.contains("animal welfare law")
            || lower.contains("animal welfare act") || lower.contains("awa compliance")
            || lower.contains("animal enrichment") && (lower.contains("zoo") || lower.contains("shelter") || lower.contains("welfare") || lower.contains("class") || lower.contains("program"))
            || lower.contains("captive animal management") || lower.contains("captive animal care")
            || lower.contains("aza accreditation") || lower.contains("aza certification")
            || lower.contains("zoo program") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("degree")) {
            return "animalwelfare"
        }
        // veterinarytechnology — positioned BEFORE veterinary so vet tech programs, VTNE exam
        // prep, and veterinary technician school tasks get a dedicated pool separate from the
        // DVM/veterinary medicine pool. "vet tech" and "veterinary technician" in the veterinary
        // branch below remain for backward compat but fire after this.
        if lower.contains("vet tech program") || lower.contains("vet tech class")
            || lower.contains("vet tech school") || lower.contains("vet tech exam")
            || lower.contains("vet tech student") || lower.contains("vet tech certification")
            || lower.contains("vet tech course") || lower.contains("vet tech notes")
            || lower.contains("veterinary technician program") || lower.contains("veterinary technician school")
            || lower.contains("veterinary technician class") || lower.contains("veterinary technician exam")
            || lower.contains("veterinary technology program") || lower.contains("veterinary technology class")
            || lower.contains("veterinary technology exam") || lower.contains("veterinary technology school")
            || word("vtne") || lower.contains("vtne exam") || lower.contains("vtne prep")
            || lower.contains("vet tech license") || lower.contains("vet tech certification") {
            return "veterinarytechnology"
        }
        // zoology — positioned BEFORE veterinary so zoology degree/program tasks, taxonomic
        // classification work, and entomology route to a dedicated pool rather than the vet pool.
        // word("zoology") removed from veterinary below; "animal science" stays in veterinary.
        if word("zoology") || word("zoologist") || word("zoologists") || word("zoological")
            || lower.contains("zoology class") || lower.contains("zoology course")
            || lower.contains("zoology exam") || lower.contains("zoology program")
            || lower.contains("zoology major") || lower.contains("zoology degree")
            || lower.contains("zoology lab") || lower.contains("zoology notes")
            || lower.contains("invertebrate zoology") || lower.contains("vertebrate zoology")
            || lower.contains("comparative zoology") || lower.contains("field zoology")
            || lower.contains("animal taxonomy") && (lower.contains("class") || lower.contains("lab") || lower.contains("zoology") || lower.contains("animal"))
            || lower.contains("taxonomic classification") && (lower.contains("class") || lower.contains("lab") || lower.contains("zoology") || lower.contains("animal"))
            || lower.contains("animal morphology") && (lower.contains("class") || lower.contains("lab") || lower.contains("course") || lower.contains("exam"))
            || word("entomology") || word("entomologist")
            || lower.contains("entomology class") || lower.contains("entomology course")
            || lower.contains("entomology lab") || lower.contains("entomology exam")
            || lower.contains("wildlife biology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("program") || lower.contains("major")) {
            return "zoology"
        }
        // veterinary — positioned before premed so "veterinary clinical rotation", "dissection"
        // in a vet-school context, and animal anatomy tasks route here, not to premed.
        // word("zoology") now caught by zoology branch above.
        if word("veterinary") || word("veterinarian") || lower.contains("vet school")
            || lower.contains("vet medicine") || lower.contains("veterinary medicine")
            || lower.contains("animal science") || word("navle")
            || lower.contains("animal behavior")
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
        // ayurvedic — positioned AFTER acupuncture (since TCM is covered there) and BEFORE podiatry;
        // catches Ayurvedic medicine/practitioner programs, panchakarma, NAMA certification.
        // Bare "dosha"/"vata"/"pitta"/"kapha" require an educational context to avoid false positives.
        if lower.contains("ayurveda") || lower.contains("ayurvedic")
            || lower.contains("ayurvedic medicine") || lower.contains("ayurvedic practitioner")
            || lower.contains("ayurvedic school") || lower.contains("ayurvedic program")
            || lower.contains("ayurvedic class") || lower.contains("ayurvedic course")
            || lower.contains("ayurvedic exam") || lower.contains("ayurvedic certification")
            || lower.contains("panchakarma") || word("nama") && lower.contains("ayurved")
            || lower.contains("vata") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("dosha") || lower.contains("ayurved"))
            || lower.contains("pitta") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("dosha") || lower.contains("ayurved"))
            || lower.contains("kapha") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("dosha") || lower.contains("ayurved"))
            || lower.contains("dosha") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("ayurved"))
            || lower.contains("prakriti") && lower.contains("ayurved")
            || lower.contains("tridosha") || lower.contains("prana") && lower.contains("ayurved")
            || lower.contains("dinacharya") || lower.contains("rasayana") {
            return "ayurvedic"
        }
        // tibetanmedicine — positioned AFTER ayurvedic and BEFORE podiatry; catches Sowa Rigpa
        // study, TTM programs, men-tsee-khang training, and Tibetan medical classics.
        // Bare "Tibet" as geography or "Tibetan history/Buddhism" do NOT fire here.
        if lower.contains("tibetan medicine") || lower.contains("tibetan medical")
            || lower.contains("sowa rigpa") || lower.contains("sowa-rigpa")
            || lower.contains("ttm program") || lower.contains("ttm class") || lower.contains("ttm course")
            || lower.contains("ttm exam") || lower.contains("ttm certification")
            || lower.contains("men-tsee-khang") || lower.contains("menteekang") || lower.contains("men tsee khang")
            || word("amchi") && (lower.contains("medicine") || lower.contains("tibetan") || lower.contains("class") || lower.contains("exam"))
            || lower.contains("gyushi") || lower.contains("four tantras") && lower.contains("tibetan")
            || lower.contains("tibetan pharmacology") || lower.contains("tibetan herbal medicine")
            || lower.contains("tibetan medical astrology") || lower.contains("tibetan medical theory")
            || lower.contains("tibetan medical school") || lower.contains("tibetan medical program")
            || lower.contains("loong") && (lower.contains("tibetan") || lower.contains("medicine") || lower.contains("tripa"))
            || lower.contains("tripa") && (lower.contains("tibetan") || lower.contains("medicine") || lower.contains("loong"))
            || lower.contains("beken") && (lower.contains("tibetan") || lower.contains("medicine")) {
            return "tibetanmedicine"
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
        // dentalanesthesia — positioned BEFORE dentalradiology and dental so dental anesthesia
        // programs, COMS/DOCS board exam prep, and sedation dentistry coursework route here.
        if lower.contains("dental anesthesia") || lower.contains("dental anesthesiologist")
            || lower.contains("dental sedation") || lower.contains("sedation dentistry")
            || lower.contains("dental anesthesia class") || lower.contains("dental anesthesia course")
            || lower.contains("dental anesthesia program") || lower.contains("dental anesthesia exam")
            || lower.contains("dental anesthesia school") || lower.contains("dental anesthesia rotation")
            || lower.contains("dental anesthesia notes") || lower.contains("dental anesthesia assignment")
            || lower.contains("coms exam") || lower.contains("coms board") || lower.contains("coms prep")
            || word("docs") && (lower.contains("board") || lower.contains("exam") || lower.contains("dental anesthesia") || lower.contains("sedation"))
            || lower.contains("docs exam") || lower.contains("docs board") || lower.contains("docs dental")
            || lower.contains("iv sedation dentistry") || lower.contains("conscious sedation dental")
            || lower.contains("nitrous oxide dentistry") || lower.contains("anesthesia for dental")
            || lower.contains("perioperative dental anesthesia") || lower.contains("dental anesthesiology")
            || lower.contains("outpatient anesthesia dental") || lower.contains("office-based dental anesthesia") {
            return "dentalanesthesia"
        }
        // dentalradiology — positioned BEFORE dental so dental radiography programs, DANB RHS
        // exam prep, and dental x-ray technique classes route to a dedicated pool rather than
        // the broad dental (DDS/DMD/perio/ortho) pool below.
        if lower.contains("dental radiography") || lower.contains("dental radiograph")
            || lower.contains("dental x-ray technique") || lower.contains("dental x-ray class")
            || lower.contains("dental x-ray course") || lower.contains("dental x-ray exam")
            || lower.contains("dental x-ray program") || lower.contains("dental x-ray school")
            || lower.contains("dental radiography program") || lower.contains("dental radiography class")
            || lower.contains("dental radiography course") || lower.contains("dental radiography exam")
            || lower.contains("dental radiography school") || lower.contains("dental radiography certification")
            || lower.contains("danb rhs") || lower.contains("danb rhs exam") || lower.contains("rhs exam")
            || lower.contains("radiographic technique") && lower.contains("dental")
            || lower.contains("intraoral radiography") || lower.contains("periapical radiograph")
            || lower.contains("bitewing radiograph") || lower.contains("panoramic radiograph")
                && !lower.contains("dental school") {
            return "dentalradiology"
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
        // homeopathy — positioned AFTER naturopathicmedicine (which catches "homeopathy class/course/exam"),
        // BEFORE integrativemedicine. Catches homeopathic prescribing, remedy selection, and standalone
        // homeopathic study not already routed by the naturopathic branch.
        if word("homeopathy") || lower.contains("homeopathic prescribing")
            || lower.contains("homeopathic remedy") || lower.contains("homeopathic remedies")
            || lower.contains("homeopathic medicine") || lower.contains("homeopathic treatment")
            || lower.contains("homeopathic case") || lower.contains("case analysis homeopathy")
            || lower.contains("classical homeopathy") || lower.contains("cch certification")
            || lower.contains("cch exam") || word("cch") && (lower.contains("homeopath") || lower.contains("certification") && lower.contains("homeopath"))
            || lower.contains("miasm") || lower.contains("miasms") || lower.contains("miasmatic")
            || lower.contains("constitutional remedy") && lower.contains("homeopath")
            || lower.contains("homeopathic potency") || lower.contains("homeopathic dilution")
            || lower.contains("hahnemann") && lower.contains("homeopath")
            || lower.contains("repertory") && (lower.contains("homeopath") || lower.contains("remedy"))
            || lower.contains("homeopathic repertory") || lower.contains("kent's repertory")
            || lower.contains("simillimum") || lower.contains("like cures like")
            || lower.contains("homeopathic materia medica") {
            return "homeopathy"
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
        // medicalscribing — positioned AFTER medicalbilling (both are clinical documentation
        // fields) and BEFORE medicallabscience so medical scribe programs, AHDPG/CCM
        // certification, and physician scribing coursework route here.
        if lower.contains("medical scribe") || lower.contains("medical scribing")
            || lower.contains("medical scriber") || lower.contains("medical scribes")
            || lower.contains("physician scribe") || lower.contains("physician scribing")
            || lower.contains("clinical scribe") || lower.contains("clinical scribing")
            || lower.contains("scribe program") && (lower.contains("medical") || lower.contains("clinical") || lower.contains("physician"))
            || lower.contains("scribe class") && (lower.contains("medical") || lower.contains("clinical"))
            || lower.contains("scribe exam") && (lower.contains("medical") || lower.contains("clinical"))
            || lower.contains("scribe certification") && (lower.contains("medical") || lower.contains("clinical"))
            || lower.contains("scribe training") && (lower.contains("medical") || lower.contains("clinical"))
            || lower.contains("ahdpg") || lower.contains("ccm certification") && (lower.contains("scribe") || lower.contains("medical documentation"))
            || lower.contains("real-time documentation") && lower.contains("medical")
            || lower.contains("ehr documentation") && lower.contains("scribe")
            || lower.contains("patient encounter documentation") || lower.contains("chart completion") && lower.contains("scribe") {
            return "medicalscribing"
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
        // cellandmolecularbiology — positioned BEFORE molecularbiology so cell biology class/lab work
        // (microscopy, cell division, organelle function) gets a dedicated pool. Bare "cell biology"
        // without class context, and "molecular biology", stay in molecularbiology (fires after).
        if lower.contains("cell biology class") || lower.contains("cell biology course")
            || lower.contains("cell biology exam") || lower.contains("cell biology lab")
            || lower.contains("cell biology notes") || lower.contains("cell biology assignment")
            || lower.contains("cell biology lecture") || lower.contains("cell biology textbook")
            || lower.contains("cell division") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("cell biology"))
            || lower.contains("mitosis") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("cell biology") || lower.contains("cell cycle"))
            || lower.contains("meiosis") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("cell biology") || lower.contains("cell cycle"))
            || lower.contains("organelle function") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("cell biology"))
            || lower.contains("cell organelle") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("cytoskeleton") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("cell biology"))
            || lower.contains("cell cycle") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("cell biology"))
            || lower.contains("cell signaling") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("cell biology"))
            || lower.contains("membrane biology") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("fluorescence microscopy") && (lower.contains("class") || lower.contains("lab") || lower.contains("cell biology"))
            || lower.contains("confocal microscopy") && (lower.contains("class") || lower.contains("lab") || lower.contains("cell biology"))
            || lower.contains("cell biology major") || lower.contains("cell biology program")
            || lower.contains("cell biology degree") {
            return "cellandmolecularbiology"
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
        // syntheticbiology — positioned AFTER molecularbiology and BEFORE toxicogenomics so
        // BioBrick assembly, genetic circuit design, iGEM, and metabolic engineering in a synthetic
        // context route here. "CRISPR gene editing" stays in molecularbiology; "metabolic flux
        // balance analysis" without synthetic context stays in metabolomics/computationalbiology.
        if lower.contains("synthetic biology") || lower.contains("synbio")
            || lower.contains("biobrick") || lower.contains("biobricks") || lower.contains("biobrick parts")
            || lower.contains("genetic circuit") || lower.contains("genetic circuits") || lower.contains("gene circuit")
            || lower.contains("metabolic engineering") && (lower.contains("class") || lower.contains("course") || lower.contains("research") || lower.contains("lab") || lower.contains("biology") || lower.contains("synthetic") || lower.contains("igem"))
            || lower.contains("igem") || lower.contains("ige m") && lower.contains("competition")
            || lower.contains("parts registry") && (lower.contains("biology") || lower.contains("synthetic") || lower.contains("igem") || lower.contains("biobrick"))
            || lower.contains("toggle switch") && (lower.contains("synthetic") || lower.contains("genetic") || lower.contains("circuit") || lower.contains("biology"))
            || lower.contains("repressilator") || lower.contains("synthetic gene network") || lower.contains("gene regulatory network") && lower.contains("synthetic")
            || lower.contains("chassis organism") || lower.contains("chassis strain") && (lower.contains("synthetic") || lower.contains("engineering"))
            || lower.contains("pathway engineering") && (lower.contains("class") || lower.contains("course") || lower.contains("research") || lower.contains("lab") || lower.contains("biology"))
            || lower.contains("heterologous expression") && (lower.contains("class") || lower.contains("research") || lower.contains("lab"))
            || lower.contains("protein engineering") && (lower.contains("class") || lower.contains("course") || lower.contains("research") || lower.contains("lab") || lower.contains("synthetic"))
            || lower.contains("directed evolution") && (lower.contains("class") || lower.contains("course") || lower.contains("research") || lower.contains("lab"))
            || lower.contains("dna assembly") && (lower.contains("class") || lower.contains("research") || lower.contains("synthetic") || lower.contains("lab"))
            || lower.contains("golden gate assembly") || lower.contains("gibson assembly") && (lower.contains("class") || lower.contains("synthetic") || lower.contains("research") || lower.contains("lab"))
            || lower.contains("synthetic biology class") || lower.contains("synthetic biology course")
            || lower.contains("synthetic biology exam") || lower.contains("synthetic biology lab")
            || lower.contains("synthetic biology research") || lower.contains("synthetic biology program") {
            return "syntheticbiology"
        }
        // toxicogenomics — positioned AFTER molecularbiology and BEFORE developmentalbiology.
        // Catches gene expression under toxic exposure, AhR pathway, TOXCAST research, and
        // omics-level toxicology. "toxicology" alone routes to toxicology branch (far below).
        // "transcriptomics" without tox context stays in molecularbiology/bioinformatics.
        if word("toxicogenomics") || word("toxicogenomic")
            || lower.contains("toxicogenomics class") || lower.contains("toxicogenomics course")
            || lower.contains("toxicogenomics exam") || lower.contains("toxicogenomics lab")
            || lower.contains("toxicogenomics research") || lower.contains("toxicogenomics program")
            || lower.contains("toxcast") || lower.contains("tox21") && (lower.contains("class") || lower.contains("research") || lower.contains("data") || lower.contains("toxicology"))
            || lower.contains("ahr pathway") || lower.contains("aryl hydrocarbon receptor") && (lower.contains("tox") || lower.contains("class") || lower.contains("research") || lower.contains("gene") || lower.contains("expression"))
            || lower.contains("gene expression") && (lower.contains("toxic") || lower.contains("toxicant") || lower.contains("toxicology") || lower.contains("toxicogenomics") || lower.contains("xenobiotic"))
            || lower.contains("transcriptomics") && (lower.contains("toxicology") || lower.contains("toxicant") || lower.contains("toxic") || lower.contains("exposure"))
            || lower.contains("epigenetic toxicology") || lower.contains("epigenomic toxicology")
            || lower.contains("toxicant-induced") && (lower.contains("gene") || lower.contains("expression") || lower.contains("epigenetic"))
            || lower.contains("dose-response") && (lower.contains("gene expression") || lower.contains("transcriptomics") || lower.contains("genomics") || lower.contains("toxicogenomics"))
            || lower.contains("omics") && (lower.contains("toxicology") || lower.contains("toxicant") || lower.contains("toxic exposure"))
            || lower.contains("oxidative stress") && (lower.contains("gene expression") || lower.contains("transcriptomics") || lower.contains("genomic") || lower.contains("toxicogenomics"))
            || lower.contains("toxicological pathway") && (lower.contains("omics") || lower.contains("genomics") || lower.contains("gene"))
            || lower.contains("adverse outcome pathway") && (lower.contains("class") || lower.contains("research") || lower.contains("omics")) {
            return "toxicogenomics"
        }
        // developmentalbiology — positioned AFTER toxicogenomics and BEFORE biochemistry.
        // Catches embryology in research context, morphogen gradients, Hox genes, fate mapping,
        // and organogenesis at the research/coursework level. Clinical embryology in premed
        // context stays in premed; CRISPR gene editing stays in molecularbiology.
        if word("developmentalbiology") || lower.contains("developmental biology class")
            || lower.contains("developmental biology course") || lower.contains("developmental biology exam")
            || lower.contains("developmental biology lab") || lower.contains("developmental biology research")
            || lower.contains("developmental biology program") || lower.contains("developmental biology major")
            || lower.contains("developmental biology notes") || lower.contains("developmental biology textbook")
            || lower.contains("morphogen gradient") || lower.contains("morphogen gradients")
            || word("morphogenesis") && (lower.contains("class") || lower.contains("research") || lower.contains("lab") || lower.contains("course"))
            || lower.contains("hox gene") || lower.contains("hox genes") || lower.contains("hox cluster")
            || lower.contains("fate mapping") || lower.contains("cell fate specification") && (lower.contains("class") || lower.contains("research") || lower.contains("lab"))
            || lower.contains("organogenesis") && (lower.contains("class") || lower.contains("research") || lower.contains("lab") || lower.contains("course"))
            || lower.contains("somitogenesis") || lower.contains("segmentation") && (lower.contains("developmental") || lower.contains("embryo") || lower.contains("class"))
            || lower.contains("gastrulation") && (lower.contains("class") || lower.contains("research") || lower.contains("lab"))
            || lower.contains("neural tube") && (lower.contains("class") || lower.contains("research") || lower.contains("lab") || lower.contains("development"))
            || lower.contains("limb bud") && (lower.contains("class") || lower.contains("research") || lower.contains("development"))
            || lower.contains("developmental gene regulation") || lower.contains("gene regulatory network") && lower.contains("developmental")
            || lower.contains("zebrafish") && (lower.contains("developmental") || lower.contains("embryo") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("drosophila") && (lower.contains("developmental") || lower.contains("embryo") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("wolpert") && lower.contains("developmental") || lower.contains("gilbert developmental biology")
            || lower.contains("wnt signaling") && (lower.contains("developmental") || lower.contains("class") || lower.contains("research"))
            || lower.contains("notch signaling") && (lower.contains("developmental") || lower.contains("class") || lower.contains("research")) {
            return "developmentalbiology"
        }
        // moleculargeneticslab — positioned AFTER developmentalbiology and BEFORE genetics so
        // molecular genetics lab-specific signals (DNA restriction mapping, gel electrophoresis in
        // genetics context, karyotype analysis, RFLP, DNA fingerprinting) fire before the broader
        // genetics branch. "gel electrophoresis" alone is caught by molecularbiology (much earlier);
        // only compound genetics-lab forms route here.
        if lower.contains("restriction mapping") && (lower.contains("genetics") || lower.contains("lab") || lower.contains("class") || lower.contains("dna"))
            || lower.contains("dna restriction") && (lower.contains("lab") || lower.contains("class") || lower.contains("genetics") || lower.contains("mapping") || lower.contains("analysis"))
            || lower.contains("restriction fragment length polymorphism") || lower.contains("rflp") && (lower.contains("genetics") || lower.contains("lab") || lower.contains("class") || lower.contains("analysis"))
            || lower.contains("dna fingerprinting") && (lower.contains("genetics") || lower.contains("lab") || lower.contains("class") || lower.contains("analysis"))
            || lower.contains("dna profiling") && (lower.contains("genetics") || lower.contains("lab") || lower.contains("class"))
            || lower.contains("karyotype analysis") || lower.contains("karyotyping") && (lower.contains("genetics") || lower.contains("lab") || lower.contains("class") || lower.contains("chromosomes"))
            || lower.contains("karyotype lab") || lower.contains("karyotype class") || lower.contains("chromosome spread")
            || lower.contains("chromosome mapping") && (lower.contains("genetics") || lower.contains("lab") || lower.contains("class"))
            || lower.contains("genetic mapping") && (lower.contains("lab") || lower.contains("class") || lower.contains("experiment") || lower.contains("report"))
            || lower.contains("complementation test") && (lower.contains("genetics") || lower.contains("lab") || lower.contains("class"))
            || lower.contains("gel electrophoresis") && (lower.contains("genetics") || lower.contains("dna") || lower.contains("restriction") || lower.contains("karyotype") || lower.contains("fingerprint"))
            || lower.contains("molecular genetics lab") || lower.contains("genetics lab report") || lower.contains("genetics lab notebook") {
            return "moleculargeneticslab"
        }
        // evolutionarybiology — positioned AFTER moleculargeneticslab and BEFORE genetics so
        // evolution-specific class signals (phylogenetic trees, speciation, evo-devo, molecular
        // evolution, adaptive radiation) route here. Population genetics (Hardy-Weinberg, allele
        // frequency) stays in genetics (fires after); "natural selection" alone without evo-bio
        // class/course context stays in studying.
        if lower.contains("evolutionary biology") || lower.contains("evolution class") || lower.contains("evolution course")
            || lower.contains("evolution exam") || lower.contains("evolution notes") || lower.contains("evolution textbook")
            || lower.contains("evolution assignment") || lower.contains("evolution problem set")
            || lower.contains("phylogenetic tree") || lower.contains("phylogenetics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("analysis") || lower.contains("build") || lower.contains("construct"))
            || lower.contains("phylogeny") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("analysis") || lower.contains("reconstruct"))
            || lower.contains("maximum parsimony") && (lower.contains("class") || lower.contains("phylogen") || lower.contains("exam"))
            || lower.contains("maximum likelihood") && (lower.contains("phylogen") || lower.contains("evolution") || lower.contains("class") || lower.contains("tree"))
            || lower.contains("speciation") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("evolution") || lower.contains("notes"))
            || lower.contains("allopatric speciation") || lower.contains("sympatric speciation") || lower.contains("peripatric speciation")
            || lower.contains("adaptive radiation") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("evolution"))
            || lower.contains("evo-devo") || lower.contains("evolutionary developmental biology")
            || lower.contains("neutral theory") && (lower.contains("evolution") || lower.contains("class") || lower.contains("molecular") || lower.contains("exam"))
            || lower.contains("molecular evolution") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("notes"))
            || lower.contains("natural selection") && (lower.contains("class") || lower.contains("course") || lower.contains("evolution") || lower.contains("exam") || lower.contains("mechanism"))
            || lower.contains("sexual selection") && (lower.contains("class") || lower.contains("course") || lower.contains("evolution") || lower.contains("exam"))
            || lower.contains("fitness landscape") && (lower.contains("class") || lower.contains("evolution") || lower.contains("exam"))
            || lower.contains("evolutionary biology class") || lower.contains("evolutionary biology course")
            || lower.contains("evolutionary biology exam") || lower.contains("evolution major")
            || lower.contains("darwin") && (lower.contains("evolution") || lower.contains("class") || lower.contains("natural selection"))
            || lower.contains("coevolution") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("evolution"))
            || lower.contains("macroevolution") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("microevolution") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")) {
            return "evolutionarybiology"
        }
        // genetics — positioned AFTER developmentalbiology and BEFORE biochemistry so classical
        // genetics (Mendelian, Hardy-Weinberg, pedigree analysis, population genetics) routes here.
        // "molecular genetics" stays in molecularbiology (earlier). Bare word("genetics") without
        // specific classical context stays in premed for MCAT usage.
        if lower.contains("genetics class") || lower.contains("genetics course")
            || lower.contains("genetics exam") || lower.contains("genetics lab")
            || lower.contains("genetics notes") || lower.contains("genetics problem set")
            || lower.contains("genetics textbook") || lower.contains("genetics assignment")
            || lower.contains("mendelian genetics") || lower.contains("mendel's law") || lower.contains("mendelian inheritance")
            || lower.contains("punnett square") && (lower.contains("class") || lower.contains("exam") || lower.contains("genetics") || lower.contains("homework"))
            || lower.contains("hardy-weinberg") && (lower.contains("class") || lower.contains("exam") || lower.contains("genetics") || lower.contains("equilibrium"))
            || lower.contains("hardy weinberg") && (lower.contains("class") || lower.contains("exam") || lower.contains("genetics"))
            || lower.contains("genetic linkage") && (lower.contains("class") || lower.contains("exam") || lower.contains("map") || lower.contains("analysis"))
            || lower.contains("chromosomal mapping") && (lower.contains("class") || lower.contains("genetics") || lower.contains("exam"))
            || lower.contains("dihybrid cross") || lower.contains("monohybrid cross")
            || lower.contains("test cross") && (lower.contains("genetics") || lower.contains("class"))
            || lower.contains("inheritance pattern") && (lower.contains("class") || lower.contains("genetics") || lower.contains("exam"))
            || lower.contains("sex-linked") && (lower.contains("genetics") || lower.contains("class") || lower.contains("trait") || lower.contains("inheritance"))
            || lower.contains("x-linked") && (lower.contains("genetics") || lower.contains("class") || lower.contains("trait") || lower.contains("inheritance"))
            || lower.contains("epistasis") && (lower.contains("class") || lower.contains("genetics") || lower.contains("exam"))
            || lower.contains("allele frequency") && (lower.contains("class") || lower.contains("genetics") || lower.contains("exam"))
            || lower.contains("gene mapping") && (lower.contains("class") || lower.contains("genetics") || lower.contains("exam"))
            || lower.contains("population genetics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("genetic drift") && (lower.contains("class") || lower.contains("genetics") || lower.contains("exam"))
            || lower.contains("gene flow") && (lower.contains("class") || lower.contains("genetics") || lower.contains("exam") || lower.contains("population"))
            || lower.contains("quantitative genetics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("qtl analysis") && (lower.contains("class") || lower.contains("genetics") || lower.contains("exam"))
            || lower.contains("linkage disequilibrium") && (lower.contains("class") || lower.contains("genetics") || lower.contains("exam"))
            || lower.contains("gwas") && (lower.contains("class") || lower.contains("genetics") || lower.contains("study"))
            || lower.contains("genome-wide association") && (lower.contains("class") || lower.contains("genetics")) {
            return "genetics"
        }
        // biochemistry2 — positioned AFTER genetics and BEFORE biochemistry so advanced biochemistry
        // topics (signal transduction, lipid metabolism, nucleotide metabolism) in a class/course
        // context route here. Generic "biochemistry class/exam" stays in biochemistry (fires after).
        if lower.contains("advanced biochemistry") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("notes") || lower.contains("textbook"))
            || lower.contains("signal transduction") && (lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("phosphorylation cascade") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam"))
            || lower.contains("second messenger") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam"))
            || lower.contains("lipid metabolism") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("fatty acid oxidation") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam"))
            || lower.contains("fatty acid synthesis") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam"))
            || lower.contains("cholesterol biosynthesis") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam"))
            || lower.contains("mevalonate pathway") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem"))
            || lower.contains("nucleotide metabolism") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam"))
            || lower.contains("purine biosynthesis") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam"))
            || lower.contains("pyrimidine biosynthesis") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam"))
            || lower.contains("nucleotide salvage") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam"))
            || lower.contains("urea cycle") && (lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("class") || lower.contains("exam")) {
            return "biochemistry2"
        }
        // biochemistry3 — positioned AFTER biochemistry2 and BEFORE biochemistry so cofactor
        // biochemistry (vitamins as coenzymes, porphyrin/heme synthesis, bile acid synthesis,
        // one-carbon/folate metabolism, methylation cycle) route to a dedicated pool distinct
        // from biochemistry2's signal transduction/lipid/nucleotide focus. Generic biochemistry
        // class/lab terms still fall through to biochemistry (fires after).
        if lower.contains("vitamin as coenzyme") || lower.contains("vitamins as coenzymes") || lower.contains("coenzyme a") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam"))
            || lower.contains("thiamine") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam") || lower.contains("cofactor"))
            || lower.contains("riboflavin") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam") || lower.contains("cofactor"))
            || lower.contains("niacin") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam") || lower.contains("cofactor") || lower.contains("nad"))
            || lower.contains("pyridoxine") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam") || lower.contains("cofactor"))
            || lower.contains("pyridoxal phosphate") || lower.contains("plp") && (lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("class") || lower.contains("cofactor"))
            || lower.contains("cobalamin") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam") || lower.contains("cofactor"))
            || lower.contains("vitamin b12") && (lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("class") || lower.contains("exam") || lower.contains("coenzyme"))
            || lower.contains("folate metabolism") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam"))
            || lower.contains("one-carbon metabolism") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam"))
            || lower.contains("methylation cycle") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam"))
            || lower.contains("porphyrin synthesis") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam"))
            || lower.contains("heme biosynthesis") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam"))
            || lower.contains("porphyrin biochemistry") || lower.contains("heme pathway") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("exam"))
            || lower.contains("bile acid synthesis") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam"))
            || lower.contains("bile acid metabolism") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam"))
            || lower.contains("cofactor biochemistry") || lower.contains("biochemical cofactor") && (lower.contains("class") || lower.contains("exam") || lower.contains("biochemistry"))
            || lower.contains("biotin") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam") || lower.contains("cofactor") || lower.contains("carboxylase"))
            || lower.contains("pantothenic acid") && (lower.contains("class") || lower.contains("biochemistry") || lower.contains("biochem") || lower.contains("exam") || lower.contains("cofactor")) {
            return "biochemistry3"
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
        // physicalchemistrylab — positioned AFTER biochemistry and BEFORE physicalchemistry so
        // specific pchem lab experiment sessions (calorimetry, spectroscopy lab, kinetics experiments)
        // route here. "pchem lab" and "physical chemistry lab" are intercepted before physicalchemistry.
        // Generic "pchem problem set" and "pchem exam" fall through to physicalchemistry (fires after).
        if lower.contains("pchem lab") || lower.contains("p-chem lab")
            || lower.contains("physical chemistry lab")
            || lower.contains("calorimetry") && (lower.contains("pchem") || lower.contains("physical chemistry") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("bomb calorimetry")
            || lower.contains("rotational spectroscopy") && (lower.contains("pchem") || lower.contains("physical chemistry") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("vibrational spectroscopy") && (lower.contains("pchem") || lower.contains("physical chemistry") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("raman spectroscopy") && (lower.contains("pchem") || lower.contains("physical chemistry") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("fluorescence spectroscopy") && (lower.contains("pchem") || lower.contains("physical chemistry") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("spectroscopy experiment") && (lower.contains("pchem") || lower.contains("physical chemistry") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("physical chemistry experiment") && (lower.contains("class") || lower.contains("course") || lower.contains("pchem") || lower.contains("lab"))
            || lower.contains("pchem experiment") && (lower.contains("class") || lower.contains("course") || lower.contains("lab"))
            || lower.contains("kinetics experiment") && (lower.contains("pchem") || lower.contains("physical chemistry") || lower.contains("class") || lower.contains("lab")) {
            return "physicalchemistrylab"
        }
        // physicalchemistry — positioned AFTER biochemistry and BEFORE inorganicchemistry/organicchemistry.
        // Catches pchem, quantum chemistry (for chemists), thermodynamics of reactions, chemical
        // kinetics, statistical thermodynamics, and molecular orbital theory coursework.
        // "quantum computing" and bare "thermodynamics" NOT matched. "physics class" stays in
        // experimentalphysics (fires much earlier).
        if lower.contains("physical chemistry") || lower.contains("pchem") || lower.contains("p-chem")
            || lower.contains("quantum chemistry") && !lower.contains("quantum computing") && !lower.contains("physics class") && !lower.contains("physics course")
            || lower.contains("chemical thermodynamics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("pchem"))
            || lower.contains("chemical kinetics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("pchem") || lower.contains("physical chemistry"))
            || lower.contains("reaction thermodynamics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("chemistry"))
            || lower.contains("gibbs energy") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("pchem"))
            || lower.contains("gibbs free energy") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("pchem"))
            || lower.contains("partition function") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("pchem") || lower.contains("statistical thermodynamics"))
            || lower.contains("statistical thermodynamics") && (lower.contains("chemistry") || lower.contains("class") || lower.contains("pchem") || lower.contains("course"))
            || lower.contains("schrodinger equation") && !lower.contains("quantum computing") && !lower.contains("physics class") && !lower.contains("physics course")
            || lower.contains("schrödinger equation") && !lower.contains("quantum computing") && !lower.contains("physics class") && !lower.contains("physics course")
            || lower.contains("wave function") && (lower.contains("chemistry") || lower.contains("pchem") || lower.contains("physical chemistry"))
            || lower.contains("molecular orbital") && (lower.contains("class") || lower.contains("course") || lower.contains("pchem") || lower.contains("chemistry") || lower.contains("exam"))
            || lower.contains("pchem class") || lower.contains("pchem course") || lower.contains("pchem exam")
            || lower.contains("pchem lab") || lower.contains("pchem problem set") || lower.contains("pchem homework")
            || lower.contains("physical chemistry class") || lower.contains("physical chemistry course")
            || lower.contains("physical chemistry exam") || lower.contains("physical chemistry lab")
            || lower.contains("physical chemistry problem set") || lower.contains("physical chemistry notes") {
            return "physicalchemistry"
        }
        // inorganicchemistry — positioned AFTER physicalchemistry and BEFORE organicchemistry.
        // Catches coordination chemistry, crystal field theory, ligand field, d-block/f-block elements,
        // main group chemistry, and organometallic chemistry. "transition metals" alone NOT matched.
        if lower.contains("inorganic chemistry") || lower.contains("inorganic chem")
            || lower.contains("coordination chemistry") || lower.contains("coordination compound")
            || lower.contains("coordination complex") || lower.contains("coordination compounds")
            || lower.contains("crystal field theory") || lower.contains("crystal field splitting")
            || lower.contains("ligand field theory") || lower.contains("ligand field")
            || lower.contains("d-block") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("element") || lower.contains("inorganic"))
            || lower.contains("f-block") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("element") || lower.contains("inorganic"))
            || lower.contains("transition metal") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("complex") || lower.contains("inorganic") || lower.contains("chem"))
            || lower.contains("transition metals") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("complex") || lower.contains("inorganic") || lower.contains("chem"))
            || lower.contains("main group chemistry") || lower.contains("main group elements") && (lower.contains("class") || lower.contains("inorganic") || lower.contains("chemistry"))
            || lower.contains("organometallic chemistry") || lower.contains("organometallic compound") || lower.contains("organometallic compounds")
            || lower.contains("spectrochemical series") || lower.contains("jahn-teller")
            || lower.contains("cfse") || lower.contains("crystal field stabilization")
            || lower.contains("molecular symmetry") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("inorganic") || lower.contains("group theory"))
            || lower.contains("point group") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("symmetry") || lower.contains("inorganic"))
            || lower.contains("inorganic lab") || lower.contains("inorganic class") || lower.contains("inorganic course")
            || lower.contains("inorganic exam") || lower.contains("inorganic notes")
            || lower.contains("inorganic chemistry class") || lower.contains("inorganic chemistry course")
            || lower.contains("inorganic chemistry exam") || lower.contains("inorganic chemistry lab") {
            return "inorganicchemistry"
        }
        // organicchemistry — positioned AFTER biochemistry and BEFORE drugdiscovery.
        // Catches orgo, reaction mechanisms, NMR, synthesis planning, and stereochemistry
        // coursework. "pharmaceutical chemistry" stays in pharmacy (fires earlier).
        // "MCAT chemistry" stays in premed (fires earlier). Bare "chemistry" NOT matched.
        if word("orgo")
            || lower.contains("organic chemistry") || lower.contains("organic chem")
            || lower.contains("nmr spectroscopy") || lower.contains("nmr spectrum")
            || word("hnmr") || word("cnmr") || lower.contains("13c nmr")
            || lower.contains("1h nmr") || lower.contains("proton nmr") || lower.contains("carbon nmr")
            || lower.contains("reaction mechanism") && !lower.contains("enzyme mechanism")
            || lower.contains("synthesis planning") || lower.contains("synthesis route") && !lower.contains("biosynthesis")
            || lower.contains("synthetic route") && !lower.contains("biosynthetic")
            || lower.contains("retrosynthesis") || lower.contains("retrosynthetic")
            || lower.contains("stereochemistry") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("orgo") || lower.contains("organic"))
            || lower.contains("chirality") && !lower.contains("biophysics")
            || lower.contains("chiral center") || lower.contains("chiral molecule")
            || lower.contains("enantiomer") || lower.contains("diastereomer")
            || lower.contains("carbocation") || lower.contains("carbanion")
            || lower.contains("sn1 reaction") || lower.contains("sn2 reaction")
            || lower.contains("e1 reaction") || lower.contains("e2 reaction")
            || lower.contains("elimination reaction") && (lower.contains("organic") || lower.contains("orgo") || lower.contains("class"))
            || lower.contains("aldol condensation") || lower.contains("aldol reaction")
            || lower.contains("diels-alder") || lower.contains("diels alder")
            || lower.contains("grignard reagent") || lower.contains("grignard reaction")
            || lower.contains("functional group analysis") && (lower.contains("organic") || lower.contains("orgo") || lower.contains("class"))
            || lower.contains("organic lab report") || lower.contains("organic chemistry lab")
            || lower.contains("fischer projection")
            || lower.contains("woodward-hoffmann") || lower.contains("woodward hoffmann")
            || lower.contains("mcat organic") || lower.contains("mcat orgo") {
            return "organicchemistry"
        }
        // organicchemistrylab — positioned AFTER organicchemistry and BEFORE analyticalchemistry
        // so specific orgo lab technique sessions (distillation, recrystallization, TLC, IR,
        // lab reports) that weren't intercepted by organicchemistry route here.
        // "NMR spectroscopy" without lab context stays in organicchemistry (fires before).
        if lower.contains("orgo lab")
            || lower.contains("distillation") && (lower.contains("organic") || lower.contains("orgo") || lower.contains("lab") || lower.contains("class") || lower.contains("chemistry"))
            || lower.contains("recrystallization") && (lower.contains("organic") || lower.contains("orgo") || lower.contains("lab") || lower.contains("class") || lower.contains("chemistry"))
            || lower.contains("thin-layer chromatography") && (lower.contains("organic") || lower.contains("orgo") || lower.contains("lab") || lower.contains("class"))
            || lower.contains("thin layer chromatography") && (lower.contains("organic") || lower.contains("orgo") || lower.contains("lab") || lower.contains("class"))
            || lower.contains("tlc") && (lower.contains("organic") || lower.contains("orgo") || lower.contains("lab") || lower.contains("class") || lower.contains("chemistry"))
            || lower.contains("melting point") && (lower.contains("organic") || lower.contains("orgo") || lower.contains("lab") || lower.contains("class"))
            || lower.contains("ir spectrum") && (lower.contains("organic") || lower.contains("orgo") || lower.contains("lab") || lower.contains("class"))
            || lower.contains("infrared spectrum") && (lower.contains("organic") || lower.contains("orgo") || lower.contains("lab") || lower.contains("class"))
            || lower.contains("column chromatography") && (lower.contains("organic") || lower.contains("orgo") || lower.contains("lab") || lower.contains("class")) {
            return "organicchemistrylab"
        }
        // analyticalchemistry — positioned AFTER organicchemistry and BEFORE drugdiscovery.
        // Catches HPLC, GC-MS, titration, chromatography, and spectroscopy in analytical context.
        // "spectrophotometry" in biochemistry context stays in biochemistry (fires earlier).
        // Bare "chemistry" NOT matched.
        if lower.contains("analytical chemistry") || lower.contains("analytic chemistry")
            || lower.contains("hplc") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("analytical") || lower.contains("course") || lower.contains("method"))
            || lower.contains("high-performance liquid chromatography") || lower.contains("high performance liquid chromatography")
            || lower.contains("gc-ms") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("analytical") || lower.contains("course"))
            || lower.contains("gas chromatography") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("analytical") || lower.contains("course"))
            || lower.contains("liquid chromatography") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("analytical") || lower.contains("course"))
            || lower.contains("mass spectrometry") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("analytical") || lower.contains("course"))
            || lower.contains("acid-base titration") || lower.contains("redox titration")
            || lower.contains("titration class") || lower.contains("titration lab") || lower.contains("titration exam")
            || lower.contains("gravimetric analysis") && (lower.contains("class") || lower.contains("lab") || lower.contains("analytical") || lower.contains("chemistry"))
            || lower.contains("potentiometry") && (lower.contains("class") || lower.contains("lab") || lower.contains("analytical") || lower.contains("course") || lower.contains("chemistry"))
            || lower.contains("icp-ms") && (lower.contains("class") || lower.contains("lab") || lower.contains("analytical") || lower.contains("course"))
            || lower.contains("atomic absorption") && (lower.contains("class") || lower.contains("lab") || lower.contains("analytical"))
            || lower.contains("ion chromatography") && (lower.contains("class") || lower.contains("lab") || lower.contains("analytical") || lower.contains("course"))
            || lower.contains("electroanalytical chemistry") || lower.contains("electroanalytical") && lower.contains("class")
            || lower.contains("quantitative analysis class") || lower.contains("quantitative analysis lab") && lower.contains("chemistry")
            || lower.contains("analytical chemistry class") || lower.contains("analytical chemistry course")
            || lower.contains("analytical chemistry exam") || lower.contains("analytical chemistry lab")
            || lower.contains("analytical chemistry notes") || lower.contains("analytical chemistry problem set") {
            return "analyticalchemistry"
        }
        // chemicalkinetics — positioned AFTER analyticalchemistry and BEFORE nuclearchemistry.
        // Catches dedicated chemical kinetics and reaction dynamics coursework distinct from
        // general physical chemistry. "rate law" without class context stays in studying.
        // "Arrhenius equation" in PChem context stays in physicalchemistry (fires earlier).
        if lower.contains("chemical kinetics class") || lower.contains("chemical kinetics course")
            || lower.contains("chemical kinetics exam") || lower.contains("chemical kinetics lab")
            || lower.contains("chemical kinetics notes") || lower.contains("chemical kinetics problem set")
            || lower.contains("reaction kinetics class") || lower.contains("reaction kinetics course")
            || lower.contains("reaction kinetics exam") || lower.contains("reaction kinetics lab")
            || lower.contains("kinetics problem set") && (lower.contains("chemistry") || lower.contains("chem") || lower.contains("reaction"))
            || lower.contains("rate law") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("chem") || lower.contains("exam") || lower.contains("problem"))
            || lower.contains("reaction order") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("chem") || lower.contains("exam"))
            || lower.contains("rate constant") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("chem") || lower.contains("exam") || lower.contains("kinetics"))
            || lower.contains("arrhenius equation") && (lower.contains("class") || lower.contains("kinetics") || lower.contains("exam"))
            || lower.contains("activation energy") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("kinetics") || lower.contains("exam"))
            || lower.contains("integrated rate law") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("chem") || lower.contains("exam"))
            || lower.contains("half-life kinetics") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("chem"))
            || lower.contains("collision theory") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("chem") || lower.contains("exam"))
            || lower.contains("transition state theory") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("kinetics"))
            || lower.contains("reaction mechanism") && (lower.contains("kinetics") || lower.contains("class") || lower.contains("chemistry"))
            || lower.contains("first-order kinetics") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("exam"))
            || lower.contains("second-order kinetics") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("exam"))
            || lower.contains("zero-order kinetics") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("exam"))
            || lower.contains("pseudo-first-order") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("kinetics"))
            || lower.contains("michaelis-menten kinetics") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("kinetics")) {
            return "chemicalkinetics"
        }
        // nuclearchemistry — positioned AFTER analyticalchemistry and BEFORE drugdiscovery.
        // Catches nuclear chemistry coursework: radioactive decay, half-life, nuclear equations,
        // fission and fusion in a chemistry class context. "nuclear medicine tech" stays in
        // nuclearmedtech (fires much earlier). "radiation safety" stays in healthphysics.
        // "radiobiology" stays in radiobiology. Bare "nuclear" alone NOT matched.
        if lower.contains("nuclear chemistry") || lower.contains("nuclear chem")
            || lower.contains("radioactive decay") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("course") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("half-life") && (lower.contains("chemistry") || lower.contains("nuclear") || lower.contains("chem") || lower.contains("lab") || lower.contains("calculation"))
            || lower.contains("half life") && (lower.contains("chemistry") || lower.contains("nuclear") || lower.contains("chem") || lower.contains("lab") || lower.contains("calculation"))
            || lower.contains("nuclear equation") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("nuclear reaction") && (lower.contains("chemistry") || lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("nuclear fission") && (lower.contains("chemistry") || lower.contains("class") || lower.contains("course"))
            || lower.contains("nuclear fusion") && (lower.contains("chemistry") || lower.contains("class") || lower.contains("course"))
            || lower.contains("alpha decay") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("lab") || lower.contains("chem"))
            || lower.contains("beta decay") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("lab") || lower.contains("chem"))
            || lower.contains("gamma decay") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("lab") || lower.contains("chem"))
            || lower.contains("radioactive isotope") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("lab") || lower.contains("chem"))
            || lower.contains("nuclear binding energy") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("chem"))
            || lower.contains("decay series") && (lower.contains("chemistry") || lower.contains("class") || lower.contains("chem"))
            || lower.contains("nuclear chemistry class") || lower.contains("nuclear chemistry course")
            || lower.contains("nuclear chemistry exam") || lower.contains("nuclear chemistry lab")
            || lower.contains("nuclear chemistry notes") || lower.contains("nuclear chemistry problem set") {
            return "nuclearchemistry"
        }
        // electrochemistry — positioned AFTER nuclearchemistry and BEFORE drugdiscovery. Catches
        // electrochemical cells, Nernst equation, galvanic/electrolytic cells, cyclic voltammetry,
        // and electrode potential coursework. Bare "oxidation" or "reduction" NOT matched.
        if lower.contains("electrochemistry") || lower.contains("electrochemistry class")
            || lower.contains("electrochemistry course") || lower.contains("electrochemistry exam")
            || lower.contains("electrochemistry lab") || lower.contains("electrochemistry notes")
            || lower.contains("electrochemical cell") || lower.contains("galvanic cell")
            || lower.contains("voltaic cell") || lower.contains("electrolytic cell")
            || lower.contains("nernst equation") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("exam") || lower.contains("electrochemistry"))
            || lower.contains("cyclic voltammetry") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("chemistry"))
            || lower.contains("linear sweep voltammetry") && (lower.contains("class") || lower.contains("lab") || lower.contains("chemistry"))
            || lower.contains("chronoamperometry") && (lower.contains("class") || lower.contains("lab") || lower.contains("chemistry"))
            || lower.contains("electrode potential") && (lower.contains("class") || lower.contains("course") || lower.contains("chemistry"))
            || lower.contains("standard reduction potential") && (lower.contains("class") || lower.contains("course") || lower.contains("chemistry"))
            || lower.contains("electrochemical series") && (lower.contains("class") || lower.contains("course") || lower.contains("chemistry"))
            || lower.contains("electrolysis class") || lower.contains("electrolysis course") || lower.contains("electrolysis exam")
            || lower.contains("electroplating class") || lower.contains("electroplating course") || lower.contains("electroplating lab")
            || lower.contains("faraday's law") && (lower.contains("electrochemistry") || lower.contains("class") || lower.contains("electrolysis"))
            || lower.contains("half-cell") && (lower.contains("class") || lower.contains("course") || lower.contains("chemistry"))
            || lower.contains("electrochemical impedance") && (lower.contains("class") || lower.contains("lab") || lower.contains("chemistry")) {
            return "electrochemistry"
        }
        // polymerchemistry — positioned AFTER electrochemistry and BEFORE drugdiscovery. Catches
        // polymer science coursework, polymerization reactions, molecular weight distribution, and
        // polymer characterization labs. "polymer" alone in materials context fires materialscience earlier.
        if lower.contains("polymer chemistry") || lower.contains("polymer science class")
            || lower.contains("polymer science course") || lower.contains("polymer science exam")
            || lower.contains("polymer science program") || lower.contains("polymer science notes")
            || lower.contains("polymer physics class") || lower.contains("polymer physics course")
            || lower.contains("polymer physics exam") || lower.contains("polymer physics notes")
            || lower.contains("polymerization reaction") && (lower.contains("class") || lower.contains("course") || lower.contains("chemistry") || lower.contains("lab"))
            || lower.contains("degree of polymerization") && (lower.contains("class") || lower.contains("course") || lower.contains("chemistry"))
            || lower.contains("molar mass distribution") && (lower.contains("class") || lower.contains("polymer") || lower.contains("chemistry"))
            || lower.contains("molecular weight distribution") && (lower.contains("polymer") || lower.contains("chemistry") || lower.contains("class"))
            || lower.contains("polydispersity index") && (lower.contains("class") || lower.contains("polymer") || lower.contains("chemistry"))
            || lower.contains("addition polymerization") && (lower.contains("class") || lower.contains("course") || lower.contains("chemistry"))
            || lower.contains("condensation polymerization") && (lower.contains("class") || lower.contains("course") || lower.contains("chemistry"))
            || lower.contains("free radical polymerization") && (lower.contains("class") || lower.contains("course") || lower.contains("chemistry"))
            || lower.contains("chain-growth polymerization") && (lower.contains("class") || lower.contains("course") || lower.contains("chemistry"))
            || lower.contains("step-growth polymerization") && (lower.contains("class") || lower.contains("course") || lower.contains("chemistry"))
            || lower.contains("ring-opening polymerization") && (lower.contains("class") || lower.contains("course") || lower.contains("chemistry"))
            || lower.contains("polymer characterization class") || lower.contains("polymer characterization course")
            || lower.contains("polymer characterization lab") || lower.contains("polymer characterization exam")
            || lower.contains("polymer chemistry class") || lower.contains("polymer chemistry course")
            || lower.contains("polymer chemistry exam") || lower.contains("polymer chemistry lab")
            || lower.contains("polymer chemistry notes") || lower.contains("polymer chemistry program") {
            return "polymerchemistry"
        }
        // computationalchemistry — positioned AFTER polymerchemistry and BEFORE drugdiscovery.
        // Catches computational quantum chemistry and molecular simulation coursework: DFT,
        // ab initio, molecular dynamics, GAUSSIAN/Schrödinger. "molecular modeling" without
        // chemistry class context stays in bioinformatics or computational biology (fires earlier).
        if lower.contains("computational chemistry") || lower.contains("computational chemist")
            || lower.contains("computational chemistry class") || lower.contains("computational chemistry course")
            || lower.contains("computational chemistry exam") || lower.contains("computational chemistry lab")
            || lower.contains("computational chemistry assignment") || lower.contains("computational chemistry program")
            || lower.contains("quantum chemistry") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("assignment") || lower.contains("computation"))
            || lower.contains("quantum chemistry class") || lower.contains("quantum chemistry course")
            || lower.contains("quantum chemistry exam") || lower.contains("quantum chemistry notes")
            || lower.contains("density functional theory") || lower.contains("dft calculation") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("chem") || lower.contains("research"))
            || lower.contains("ab initio") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("calculation") || lower.contains("method"))
            || lower.contains("molecular dynamics simulation") && (lower.contains("class") || lower.contains("course") || lower.contains("chemistry") || lower.contains("chem"))
            || lower.contains("md simulation") && (lower.contains("chemistry") || lower.contains("chem") || lower.contains("class") || lower.contains("protein"))
            || lower.contains("molecular mechanics") && (lower.contains("class") || lower.contains("course") || lower.contains("chemistry") || lower.contains("chem"))
            || lower.contains("gaussian") && (lower.contains("chemistry") || lower.contains("calculation") || lower.contains("dft") || lower.contains("ab initio") || lower.contains("class"))
            || lower.contains("schrödinger") && (lower.contains("chemistry") || lower.contains("class") || lower.contains("drug") || lower.contains("molecular"))
            || lower.contains("molpro") && (lower.contains("chemistry") || lower.contains("class") || lower.contains("calculation"))
            || lower.contains("orca software") && (lower.contains("chemistry") || lower.contains("class") || lower.contains("dft") || lower.contains("calculation"))
            || lower.contains("basis set") && (lower.contains("chemistry") || lower.contains("class") || lower.contains("dft") || lower.contains("quantum") || lower.contains("calculation"))
            || lower.contains("coupled cluster") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("calculation"))
            || lower.contains("hartree-fock") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("calculation") || lower.contains("method"))
            || lower.contains("potential energy surface") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("calculation"))
            || lower.contains("force field") && (lower.contains("class") || lower.contains("chemistry") || lower.contains("chem") || lower.contains("simulation")) {
            return "computationalchemistry"
        }
        // drugdiscovery — positioned AFTER biochemistry and BEFORE biophysics. Catches lead
        // optimization, high-throughput screening, ADMET, and medicinal chemistry research
        // distinct from pharmacy's dispensing focus. Bare "drug" NOT matched.
        if lower.contains("drug discovery") || lower.contains("drug development research")
            || lower.contains("lead optimization") || lower.contains("lead compound") && (lower.contains("drug") || lower.contains("class") || lower.contains("research"))
            || lower.contains("high-throughput screening") || lower.contains("high throughput screening")
            || word("hts") && (lower.contains("drug") || lower.contains("screen") || lower.contains("assay") || lower.contains("class") || lower.contains("research"))
            || lower.contains("admet") || lower.contains("adme") && (lower.contains("drug") || lower.contains("class") || lower.contains("research") || lower.contains("prediction"))
            || lower.contains("medicinal chemistry research") || lower.contains("medicinal chemistry class")
            || lower.contains("medicinal chemistry course") || lower.contains("medicinal chemistry exam")
            || lower.contains("medicinal chemistry lab") || lower.contains("medicinal chemistry program")
            || lower.contains("structure-activity relationship") || lower.contains("structure activity relationship") || word("sar") && (lower.contains("drug") || lower.contains("compound") || lower.contains("class") || lower.contains("medicinal"))
            || lower.contains("pharmacophore") && (lower.contains("drug") || lower.contains("class") || lower.contains("research") || lower.contains("model"))
            || lower.contains("target identification") && (lower.contains("drug") || lower.contains("class") || lower.contains("research"))
            || lower.contains("hit to lead") || lower.contains("hit-to-lead")
            || lower.contains("fragment-based drug") || lower.contains("fragment based drug")
            || lower.contains("virtual screening") && (lower.contains("drug") || lower.contains("compound") || lower.contains("class") || lower.contains("research"))
            || lower.contains("drug candidate") && (lower.contains("research") || lower.contains("class") || lower.contains("optimization"))
            || lower.contains("clinical candidate") && (lower.contains("drug") || lower.contains("research"))
            || word("qsar") && (lower.contains("drug") || lower.contains("class") || lower.contains("model") || lower.contains("research"))
            || lower.contains("drug discovery class") || lower.contains("drug discovery course")
            || lower.contains("drug discovery exam") || lower.contains("drug discovery lab")
            || lower.contains("drug discovery research") || lower.contains("drug discovery program") {
            return "drugdiscovery"
        }
        // biophysics — positioned AFTER biochemistry (which catches protein-assay, enzyme-kinetics,
        // and spectrophotometry terms) and BEFORE geneticcounseling. Catches biophysics class/lab
        // with a class/course/lab/exam/assignment guard to avoid stealing bare "thermodynamics"
        // from physics or engineering. "membrane potential" without biophysics context stays in
        // neuroscience; "ion channel" without biophysics class stays in neuroscience.
        if word("biophysics") || word("biophysicist")
            || lower.contains("biophysics class") || lower.contains("biophysics course")
            || lower.contains("biophysics lab") || lower.contains("biophysics exam")
            || lower.contains("biophysics assignment") || lower.contains("biophysics report")
            || lower.contains("biophysics major") || lower.contains("biophysics degree")
            || lower.contains("biophysics program") || lower.contains("biophysics textbook")
            || lower.contains("biophysics problem set") || lower.contains("biophysics homework")
            || lower.contains("biological physics") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("thermodynamics of living systems") || lower.contains("thermodynamics of biological")
            || lower.contains("membrane potential") && (lower.contains("biophysics") || lower.contains("physics class") || lower.contains("physics course") || lower.contains("physics lab"))
            || lower.contains("ion channel kinetics") && (lower.contains("biophysics") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("single molecule biophysics") || lower.contains("single-molecule biophysics")
            || lower.contains("force spectroscopy") && (lower.contains("class") || lower.contains("lab") || lower.contains("biophysics"))
            || lower.contains("atomic force microscopy") && (lower.contains("biophysics") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("protein folding biophysics") || lower.contains("biophysical journal")
            || lower.contains("biophysical methods") && (lower.contains("class") || lower.contains("lab"))
            || lower.contains("optical tweezers") && (lower.contains("biophysics") || lower.contains("class") || lower.contains("lab")) {
            return "biophysics"
        }
        // radiobiology — positioned AFTER biophysics and BEFORE geneticcounseling so DNA damage
        // from ionizing radiation, radiation cell biology, and radiobiology coursework route here.
        // Clinical radiation dosimetry stays in radiologictechnology/nuclearmedtech.
        // Radiation safety/protection stays in healthphysics.
        if lower.contains("radiobiology") || lower.contains("radio-biology")
            || lower.contains("radiation biology") || lower.contains("radiation cell biology")
            || (lower.contains("dna damage") && (lower.contains("radiation") || lower.contains("radiobiology")))
            || (lower.contains("dna repair") && (lower.contains("radiation") || lower.contains("radiobiology")))
            || lower.contains("radiation-induced") && (lower.contains("dna") || lower.contains("cell") || lower.contains("apoptosis") || lower.contains("mutation") || lower.contains("damage"))
            || lower.contains("chromosome aberration") && (lower.contains("radiation") || lower.contains("class") || lower.contains("lab"))
            || (lower.contains("clonogenic assay") && (lower.contains("radiation") || lower.contains("class") || lower.contains("lab")))
            || (lower.contains("survival curve") && (lower.contains("radiation") || lower.contains("radiobiology")))
            || lower.contains("relative biological effectiveness") || (word("rbe") && (lower.contains("radiation") || lower.contains("radiobiology") || lower.contains("class")))
            || lower.contains("linear energy transfer") && (lower.contains("radiation") || lower.contains("class") || lower.contains("lab") || lower.contains("radiobiology"))
            || lower.contains("radiation sensitizer") || lower.contains("radiosensitizer") || lower.contains("radiosensitivity")
            || lower.contains("ionizing radiation biology") || lower.contains("radiation oncology biology")
            || lower.contains("fractionated radiation") && (lower.contains("biology") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("radiobiological") || lower.contains("radiobiology class")
            || lower.contains("radiobiology course") || lower.contains("radiobiology exam")
            || lower.contains("radiobiology lab") || lower.contains("radiobiology research")
            || lower.contains("radiobiology assignment") || lower.contains("radiobiology program") {
            return "radiobiology"
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
        // radiologyrotation — positioned BEFORE radiologictechnology so medical-student/resident
        // radiology rotation tasks (PACS, image interpretation, reading room) route here rather
        // than to the tech-school ARRT pool. Bare "radiology" stays in studying.
        // "interventional radiology rotation" already in radiologictechnology; body-site rotations caught here.
        if lower.contains("radiology reading room") || lower.contains("reading room radiology")
            || lower.contains("pacs system") && (lower.contains("radiology") || lower.contains("rotation") || lower.contains("class") || lower.contains("imaging"))
            || lower.contains("radiology rotation") && !lower.contains("arrt") && !lower.contains("radiography program")
            || lower.contains("neuroradiology rotation") || lower.contains("neuroradiology reading")
            || lower.contains("musculoskeletal radiology") && (lower.contains("rotation") || lower.contains("class") || lower.contains("course") || lower.contains("reading"))
            || lower.contains("abdominal radiology") && (lower.contains("rotation") || lower.contains("class") || lower.contains("course"))
            || lower.contains("chest radiology") && (lower.contains("rotation") || lower.contains("class") || lower.contains("course") || lower.contains("reading"))
            || lower.contains("pediatric radiology") && (lower.contains("rotation") || lower.contains("class") || lower.contains("course"))
            || lower.contains("breast radiology") && (lower.contains("rotation") || lower.contains("class") || lower.contains("course"))
            || lower.contains("emergency radiology") && (lower.contains("rotation") || lower.contains("class") || lower.contains("course"))
            || lower.contains("radiology residency") && (lower.contains("reading") || lower.contains("rotation") || lower.contains("report") || lower.contains("case") || lower.contains("attending"))
            || lower.contains("radiology clerkship") || lower.contains("radiology elective")
            || lower.contains("image interpretation") && (lower.contains("radiology") || lower.contains("rotation") || lower.contains("class") || lower.contains("course"))
            || lower.contains("radiograph interpretation") && (lower.contains("class") || lower.contains("course") || lower.contains("rotation"))
            || lower.contains("ct interpretation") && (lower.contains("class") || lower.contains("course") || lower.contains("rotation") || lower.contains("radiology"))
            || lower.contains("mri interpretation") && (lower.contains("class") || lower.contains("course") || lower.contains("rotation") || lower.contains("radiology"))
            || lower.contains("radiology report") && (lower.contains("rotation") || lower.contains("write") || lower.contains("dictate") || lower.contains("attending"))
            || lower.contains("dictate radiology") || lower.contains("dictating radiology")
            || lower.contains("radiology attending") || lower.contains("radiology fellow") {
            return "radiologyrotation"
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
        // healthinformatics — positioned BEFORE healthcareadmin so CPHIMS exam prep, HL7/FHIR
        // interoperability coursework, and health informatics degree programs route to a dedicated pool.
        // "healthcare administration" and "health information management" (RHIA/RHIT) stay in healthcareadmin.
        if word("cphims") || lower.contains("cphims exam") || lower.contains("cphims certification")
            || lower.contains("hl7 fhir") || lower.contains("hl7/fhir") || lower.contains("fhir standards")
            || lower.contains("fhir interface") || lower.contains("fhir class") || lower.contains("fhir course")
            || lower.contains("fhir implementation") || lower.contains("hl7 interface") || lower.contains("hl7 class")
            || lower.contains("hl7 standards") || lower.contains("hl7 course") || lower.contains("hl7 exam")
            || lower.contains("health data interoperability") || lower.contains("health data exchange")
            || lower.contains("health information exchange") && (lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("exam") || lower.contains("hie"))
            || lower.contains("health informatics") && (lower.contains("degree") || lower.contains("major") || lower.contains("program") || lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("clinical informatics") && (lower.contains("degree") || lower.contains("major") || lower.contains("program") || lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("biomedical informatics") || lower.contains("bio-medical informatics")
            || lower.contains("medical informatics") && (lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("exam"))
            || lower.contains("nursing informatics") && (lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("exam"))
            || lower.contains("health informatics program") || lower.contains("health informatics degree")
            || lower.contains("health informatics major") || lower.contains("health informatics class")
            || lower.contains("health informatics course") || lower.contains("health informatics exam")
            || lower.contains("clinical decision support") && (lower.contains("class") || lower.contains("course") || lower.contains("informatics")) {
            return "healthinformatics"
        }
        // healthcarequality — positioned AFTER healthinformatics and BEFORE healthcareadmin.
        // Catches CPHQ prep, patient safety, and quality improvement in healthcare settings
        // distinct from qualitymanagement (industrial ISO/ASQ) and healthcareadmin (admin ops).
        // "six sigma in manufacturing" stays in qualitymanagement (fires much earlier).
        if lower.contains("healthcare quality improvement") || lower.contains("health care quality improvement")
            || lower.contains("patient safety class") || lower.contains("patient safety course")
            || lower.contains("patient safety exam") || lower.contains("patient safety program")
            || lower.contains("patient safety assignment") || lower.contains("patient safety project")
            || word("cphq") || lower.contains("cphq exam") || lower.contains("cphq cert")
            || lower.contains("quality improvement") && (lower.contains("healthcare") || lower.contains("hospital") || lower.contains("clinical") || lower.contains("patient"))
            || lower.contains("qi project") && (lower.contains("health") || lower.contains("clinical") || lower.contains("hospital"))
            || lower.contains("lean healthcare") || lower.contains("lean in healthcare") || lower.contains("lean hospital")
            || lower.contains("six sigma in healthcare") || lower.contains("six sigma healthcare") || lower.contains("six sigma hospital")
            || lower.contains("pdsa cycle") && (lower.contains("health") || lower.contains("clinical") || lower.contains("hospital") || lower.contains("quality"))
            || lower.contains("joint commission") && (lower.contains("class") || lower.contains("course") || lower.contains("accreditation") || lower.contains("survey"))
            || lower.contains("tjc survey") || lower.contains("tjc accreditation") && lower.contains("class")
            || lower.contains("ncqa standards") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("root cause analysis") && (lower.contains("clinical") || lower.contains("healthcare") || lower.contains("hospital") || lower.contains("patient"))
            || lower.contains("sentinel event") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("never event") && (lower.contains("class") || lower.contains("course") || lower.contains("healthcare") || lower.contains("patient"))
            || lower.contains("healthcare accreditation") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")) {
            return "healthcarequality"
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
        // medicalhumanities — positioned AFTER healthcareadmin and BEFORE premed so narrative medicine,
        // history of medicine, and medicine-and-literature coursework get a dedicated pool rather than
        // the MCAT/anatomy/pre-med pool. "medical school" alone still routes to premed (fires after).
        if lower.contains("narrative medicine") || lower.contains("medical humanities")
            || lower.contains("health humanities") && (lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("paper") || lower.contains("research"))
            || lower.contains("history of medicine") && (lower.contains("class") || lower.contains("course") || lower.contains("paper") || lower.contains("research") || lower.contains("essay"))
            || lower.contains("medicine and literature") || lower.contains("literature and medicine")
            || lower.contains("medicine in literature") && (lower.contains("class") || lower.contains("course") || lower.contains("paper") || lower.contains("study"))
            || lower.contains("arts in medicine") && (lower.contains("class") || lower.contains("course") || lower.contains("program"))
            || lower.contains("illness narrative") && (lower.contains("class") || lower.contains("course") || lower.contains("paper") || lower.contains("write") || lower.contains("analyze"))
            || lower.contains("patient narrative") && (lower.contains("class") || lower.contains("course") || lower.contains("research") || lower.contains("write") || lower.contains("humanities"))
            || lower.contains("social history of medicine") || lower.contains("cultural history of medicine")
            || lower.contains("history of public health") && (lower.contains("class") || lower.contains("course") || lower.contains("paper"))
            || lower.contains("history of nursing") && (lower.contains("class") || lower.contains("course") || lower.contains("paper"))
            || lower.contains("medicine and film") && (lower.contains("class") || lower.contains("course") || lower.contains("paper"))
            || lower.contains("disability studies") && (lower.contains("medicine") || lower.contains("health"))
            && (lower.contains("class") || lower.contains("course") || lower.contains("paper") || lower.contains("program")) {
            return "medicalhumanities"
        }
        // virology — positioned BEFORE microbiology so specific virology coursework (viral
        // replication cycles, viral pathogenesis, specific viral pathogens) routes here rather than
        // the general microbiology pool. "virology class/course/exam" was formerly caught by microbiology.
        if lower.contains("virology class") || lower.contains("virology course")
            || lower.contains("virology exam") || lower.contains("virology lab")
            || lower.contains("virology notes") || lower.contains("virology textbook")
            || lower.contains("virology assignment") || lower.contains("virology lecture")
            || lower.contains("viral replication") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("virology") || lower.contains("cycle"))
            || lower.contains("viral pathogenesis") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("virology"))
            || lower.contains("viral life cycle") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("virology"))
            || lower.contains("sars-cov-2") && (lower.contains("class") || lower.contains("course") || lower.contains("virology") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("hiv replication") && (lower.contains("class") || lower.contains("course") || lower.contains("virology") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("influenza virus") && (lower.contains("class") || lower.contains("course") || lower.contains("virology") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("viral protein") && (lower.contains("virology") || lower.contains("class") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("virus structure") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("virology"))
            || lower.contains("bacteriophage") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("virology") || lower.contains("lab"))
            || lower.contains("viral tropism") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("virology"))
            || lower.contains("viral vector") && (lower.contains("class") || lower.contains("course") || lower.contains("virology") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("virology major") || lower.contains("virology program") {
            return "virology"
        }
        // clinicalmicrobiology — positioned AFTER virology and BEFORE microbiology so clinical lab
        // rotation work (culture interpretation, antibiogram reading, infection control) routes to a
        // dedicated pool rather than the general microbiology course pool.
        if lower.contains("clinical microbiology") && (lower.contains("lab") || lower.contains("rotation") || lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("microbiology lab rotation") || lower.contains("microbiology rotation")
            || lower.contains("antibiogram") && (lower.contains("class") || lower.contains("lab") || lower.contains("rotation") || lower.contains("microbiology") || lower.contains("interpretation") || lower.contains("read"))
            || lower.contains("culture interpretation") && (lower.contains("microbiology") || lower.contains("lab") || lower.contains("rotation") || lower.contains("clinical"))
            || lower.contains("culture results") && (lower.contains("microbiology") || lower.contains("lab") || lower.contains("clinical") || lower.contains("rotation"))
            || lower.contains("susceptibility testing") && (lower.contains("microbiology") || lower.contains("lab") || lower.contains("class") || lower.contains("clinical"))
            || lower.contains("minimum inhibitory concentration") && (lower.contains("microbiology") || lower.contains("lab") || lower.contains("clinical") || lower.contains("class"))
            || lower.contains("mic testing") && (lower.contains("microbiology") || lower.contains("lab") || lower.contains("clinical"))
            || lower.contains("infection control") && (lower.contains("microbiology") || lower.contains("lab") || lower.contains("class") || lower.contains("rotation") || lower.contains("clinical"))
            || lower.contains("nosocomial infection") && (lower.contains("class") || lower.contains("lab") || lower.contains("microbiology") || lower.contains("clinical"))
            || lower.contains("blood culture") && (lower.contains("microbiology") || lower.contains("lab") || lower.contains("clinical") || lower.contains("class") || lower.contains("rotation"))
            || lower.contains("urine culture") && (lower.contains("microbiology") || lower.contains("lab") || lower.contains("clinical") || lower.contains("class"))
            || lower.contains("wound culture") && (lower.contains("microbiology") || lower.contains("lab") || lower.contains("clinical") || lower.contains("class")) {
            return "clinicalmicrobiology"
        }
        // microbiology — positioned BEFORE premed to catch dedicated microbiology class/lab work.
        // Bare word("microbiology") stays in premed for MCAT context (premed branch fires after).
        // "molecular microbiology" and PCR protocols stay in molecularbiology (much earlier).
        if lower.contains("microbiology class") || lower.contains("microbiology course")
            || lower.contains("microbiology exam") || lower.contains("microbiology lab")
            || lower.contains("microbiology notes") || lower.contains("microbiology textbook")
            || lower.contains("microbiology lab report") || lower.contains("microbiology assignment")
            || lower.contains("gram stain") && (lower.contains("class") || lower.contains("lab") || lower.contains("bacteria") || lower.contains("microbiology") || lower.contains("gram-positive") || lower.contains("gram-negative"))
            || lower.contains("bacterial culture") && (lower.contains("class") || lower.contains("lab") || lower.contains("microbiology"))
            || lower.contains("culture plate") && (lower.contains("class") || lower.contains("lab") || lower.contains("microbiology"))
            || lower.contains("streak plate") && (lower.contains("class") || lower.contains("lab") || lower.contains("microbiology") || lower.contains("bacteria"))
            || lower.contains("aseptic technique") && (lower.contains("class") || lower.contains("lab") || lower.contains("microbiology"))
            || lower.contains("broth dilution") && (lower.contains("class") || lower.contains("lab") || lower.contains("microbiology") || lower.contains("bacteria"))
            || lower.contains("microbial growth") && (lower.contains("class") || lower.contains("lab") || lower.contains("curve"))
            || lower.contains("bacterial identification") && (lower.contains("class") || lower.contains("lab") || lower.contains("microbiology"))
            || lower.contains("zone of inhibition") && (lower.contains("class") || lower.contains("lab") || lower.contains("microbiology") || lower.contains("bacteria"))
            || lower.contains("petri dish") && (lower.contains("class") || lower.contains("lab") || lower.contains("microbiology") || lower.contains("bacteria"))
            || lower.contains("microorganism") && (lower.contains("class") || lower.contains("lab") || lower.contains("course"))
            || lower.contains("bacteriology class") || lower.contains("bacteriology course") || lower.contains("bacteriology lab") || lower.contains("bacteriology exam")
            || lower.contains("virology class") || lower.contains("virology course") || lower.contains("virology exam")
            || lower.contains("mycology class") || lower.contains("mycology course") || lower.contains("mycology exam") {
            return "microbiology"
        }
        // immunologycourse — positioned AFTER microbiology and BEFORE immunology so advanced
        // immunology-specific signals (T-reg cells, complement cascade, immunotherapy mechanisms)
        // route here. Generic "immunology class/exam" stays in immunology (fires after).
        if lower.contains("advanced immunology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("notes") || lower.contains("textbook"))
            || lower.contains("regulatory t cell") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam") || lower.contains("course"))
            || lower.contains("t regulatory cell") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam"))
            || lower.contains("treg cell") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam"))
            || lower.contains("complement cascade") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam") || lower.contains("course"))
            || lower.contains("complement pathway") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam"))
            || lower.contains("immunotherapy") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam") || lower.contains("mechanism") || lower.contains("course"))
            || lower.contains("checkpoint inhibitor") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam") || lower.contains("mechanism"))
            || lower.contains("pd-1") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam"))
            || lower.contains("pd-l1") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam"))
            || lower.contains("ctla-4") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam"))
            || lower.contains("nk cell") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam") || lower.contains("course"))
            || lower.contains("toll-like receptor") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam"))
            || lower.contains("inflammasome") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam"))
            || lower.contains("immunological memory") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam")) {
            return "immunologycourse"
        }
        // immunology — positioned BEFORE premed to catch dedicated immunology class/lab work.
        // Bare word("immunology") stays in premed for MCAT context (premed branch fires after).
        // "flow cytometry" in general research context stays in molecularbiology (much earlier).
        if lower.contains("immunology class") || lower.contains("immunology course")
            || lower.contains("immunology exam") || lower.contains("immunology lab")
            || lower.contains("immunology notes") || lower.contains("immunology textbook")
            || lower.contains("immunology assignment") || lower.contains("immunology lecture")
            || lower.contains("innate immunity") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("mechanism"))
            || lower.contains("adaptive immunity") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("mechanism"))
            || lower.contains("b cell activation") || lower.contains("t cell activation")
            || lower.contains("t-cell activation") || lower.contains("b-cell activation")
            || lower.contains("antibody structure") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam"))
            || lower.contains("antigen presentation") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam"))
            || lower.contains("complement system") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam"))
            || lower.contains("cytokine signaling") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam"))
            || lower.contains("mhc class") && (lower.contains("immunology") || lower.contains("class") || lower.contains("exam") || lower.contains("presentation"))
            || lower.contains("hla") && (lower.contains("immunology") || lower.contains("typing") || lower.contains("haplotype"))
            || lower.contains("autoimmune disease") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam") || lower.contains("mechanism"))
            || lower.contains("hypersensitivity reaction") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam"))
            || lower.contains("lymphocyte development") && (lower.contains("class") || lower.contains("immunology") || lower.contains("exam"))
            || lower.contains("immunoglobulin") && (lower.contains("class") || lower.contains("immunology") || lower.contains("structure"))
            || lower.contains("flow cytometry") && (lower.contains("immunology") || lower.contains("immune cell"))
            || lower.contains("elisa") && (lower.contains("immunology") || lower.contains("immune") || lower.contains("antibody")) {
            return "immunology"
        }
        // parasitology — positioned BEFORE premed to catch dedicated parasitology class/lab work.
        // Bare word("parasite") without class context stays in studying (too broad).
        // "malaria MCAT" stays in premed (fires after). "molecular parasitology" stays in molecularbiology (earlier).
        if lower.contains("parasitology class") || lower.contains("parasitology course")
            || lower.contains("parasitology exam") || lower.contains("parasitology lab")
            || lower.contains("parasitology notes") || lower.contains("parasitology textbook")
            || lower.contains("parasitology assignment") || lower.contains("parasitology lab report")
            || lower.contains("helminthology") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("protozoology") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("parasite identification") && (lower.contains("class") || lower.contains("lab") || lower.contains("parasitology"))
            || lower.contains("protozoa identification") && (lower.contains("class") || lower.contains("lab"))
            || lower.contains("helminth") && (lower.contains("class") || lower.contains("lab") || lower.contains("parasitology") || lower.contains("identification"))
            || lower.contains("malaria life cycle") && (lower.contains("class") || lower.contains("lab") || lower.contains("parasitology") || lower.contains("exam"))
            || lower.contains("plasmodium") && (lower.contains("class") || lower.contains("lab") || lower.contains("parasitology") || lower.contains("life cycle"))
            || lower.contains("trypanosoma") && (lower.contains("class") || lower.contains("lab") || lower.contains("parasitology"))
            || lower.contains("giardia") && (lower.contains("class") || lower.contains("lab") || lower.contains("parasitology") || lower.contains("identification"))
            || lower.contains("ascaris") && (lower.contains("class") || lower.contains("lab") || lower.contains("parasitology"))
            || lower.contains("tapeworm") && (lower.contains("class") || lower.contains("lab") || lower.contains("parasitology") || lower.contains("identification"))
            || lower.contains("roundworm") && (lower.contains("class") || lower.contains("lab") || lower.contains("parasitology") || lower.contains("identification"))
            || lower.contains("nematode") && (lower.contains("class") || lower.contains("lab") || lower.contains("parasitology") || lower.contains("identification"))
            || lower.contains("trematode") && (lower.contains("class") || lower.contains("lab") || lower.contains("parasitology") || lower.contains("identification"))
            || lower.contains("cestode") && (lower.contains("class") || lower.contains("lab") || lower.contains("parasitology") || lower.contains("identification"))
            || lower.contains("parasitic disease") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("parasite biology") && (lower.contains("class") || lower.contains("course") || lower.contains("lab")) {
            return "parasitology"
        }
        // embryology — positioned BEFORE premed so embryology class/lab work routes here.
        // Bare word("embryology") stays in premed for MCAT context (fires after).
        // "gastrulation" in developmentalbiology class context stays in developmentalbiology (earlier).
        if lower.contains("embryology class") || lower.contains("embryology course")
            || lower.contains("embryology exam") || lower.contains("embryology lab")
            || lower.contains("embryology notes") || lower.contains("embryology textbook")
            || lower.contains("embryology assignment") || lower.contains("embryology lecture")
            || lower.contains("neurulation") && (lower.contains("class") || lower.contains("lab") || lower.contains("embryology") || lower.contains("exam"))
            || lower.contains("organogenesis") && (lower.contains("class") || lower.contains("lab") || lower.contains("embryology") || lower.contains("exam"))
            || lower.contains("extraembryonic membranes") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("fetal development") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("embryonic development") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("germ layers") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("embryology"))
            || lower.contains("somite development") && (lower.contains("class") || lower.contains("lab") || lower.contains("embryology"))
            || lower.contains("primitive streak") && (lower.contains("class") || lower.contains("lab") || lower.contains("embryology") || lower.contains("exam"))
            || lower.contains("blastulation") && (lower.contains("class") || lower.contains("lab") || lower.contains("embryology") || lower.contains("exam"))
            || lower.contains("cleavage division") && (lower.contains("class") || lower.contains("lab") || lower.contains("embryology"))
            || lower.contains("placental development") && (lower.contains("class") || lower.contains("lab") || lower.contains("embryology") || lower.contains("exam"))
            || lower.contains("teratology") && (lower.contains("class") || lower.contains("lab") || lower.contains("embryology") || lower.contains("exam"))
            || lower.contains("developmental embryology") {
            return "embryology"
        }
        // histology — positioned BEFORE premed so histology class/lab work routes here.
        // Bare word("histology") stays in premed for MCAT context (fires after).
        if lower.contains("histology class") || lower.contains("histology course")
            || lower.contains("histology exam") || lower.contains("histology lab")
            || lower.contains("histology notes") || lower.contains("histology slide")
            || lower.contains("histology assignment") || lower.contains("histology practical")
            || lower.contains("histology textbook") || lower.contains("histology lecture")
            || lower.contains("tissue identification") && (lower.contains("class") || lower.contains("lab") || lower.contains("histology") || lower.contains("microscope"))
            || lower.contains("h&e staining") && (lower.contains("class") || lower.contains("lab") || lower.contains("histology"))
            || lower.contains("hematoxylin and eosin") && (lower.contains("class") || lower.contains("lab") || lower.contains("histology"))
            || lower.contains("hematoxylin eosin") && (lower.contains("class") || lower.contains("lab") || lower.contains("histology"))
            || lower.contains("histological section") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("microscopic anatomy") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("epithelial tissue") && (lower.contains("class") || lower.contains("lab") || lower.contains("histology") || lower.contains("identification"))
            || lower.contains("connective tissue histology")
            || lower.contains("smooth muscle histology")
            || lower.contains("cardiac muscle histology")
            || lower.contains("bone histology") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("histopathology lab") && !lower.contains("pathology class")
            || lower.contains("tissue staining") && (lower.contains("class") || lower.contains("lab") || lower.contains("histology")) {
            return "histology"
        }
        // pathology — positioned BEFORE premed so pathology class/lab work routes here.
        // Bare word("pathology") stays in premed for MCAT context (fires after).
        if lower.contains("pathology class") || lower.contains("pathology course")
            || lower.contains("pathology exam") || lower.contains("pathology lab")
            || lower.contains("pathology notes") || lower.contains("pathology assignment")
            || lower.contains("pathology lecture") || lower.contains("pathology textbook")
            || lower.contains("gross pathology") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("slide"))
            || lower.contains("microscopic pathology") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("histopathology") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("pathology"))
            || lower.contains("pathology slide") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("disease mechanisms") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("autopsy") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("pathology"))
            || lower.contains("pathogenesis") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("exam") || lower.contains("pathology"))
            || lower.contains("surgical pathology") && (lower.contains("class") || lower.contains("course") || lower.contains("rotation") || lower.contains("notes"))
            || lower.contains("forensic pathology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("clinical pathology") && (lower.contains("class") || lower.contains("course") || lower.contains("rotation"))
            || lower.contains("pathology report") && (lower.contains("class") || lower.contains("course") || lower.contains("lab"))
            || lower.contains("neoplasia") && (lower.contains("class") || lower.contains("pathology") || lower.contains("exam"))
            || lower.contains("inflammation pathology") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam")) {
            return "pathology"
        }
        // neuroanatomy — positioned BEFORE premed so neuroanatomy class/lab work routes here.
        // "action potential" and general neuroscience stay in neuroscience (much earlier).
        if lower.contains("neuroanatomy class") || lower.contains("neuroanatomy course")
            || lower.contains("neuroanatomy exam") || lower.contains("neuroanatomy lab")
            || lower.contains("neuroanatomy notes") || lower.contains("neuroanatomy assignment")
            || lower.contains("neuroanatomy dissection") || lower.contains("neuroanatomy textbook")
            || lower.contains("brain regions") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("anatomy") || lower.contains("neuroanatomy"))
            || lower.contains("spinal cord anatomy") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("cranial nerves") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("anatomy") || lower.contains("identify"))
            || lower.contains("neural pathways") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("anatomy"))
            || lower.contains("brainstem anatomy") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("cortical mapping") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("anatomy"))
            || lower.contains("limbic system") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("anatomy"))
            || lower.contains("cerebellum anatomy") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam"))
            || lower.contains("basal ganglia") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("anatomy"))
            || lower.contains("neural tracts") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("anatomy"))
            || lower.contains("brain atlas") && (lower.contains("class") || lower.contains("lab") || lower.contains("anatomy"))
            || lower.contains("dermatome") && (lower.contains("class") || lower.contains("lab") || lower.contains("exam") || lower.contains("anatomy"))
            || lower.contains("forebrain") && (lower.contains("class") || lower.contains("lab") || lower.contains("anatomy") || lower.contains("exam"))
            || lower.contains("hindbrain") && (lower.contains("class") || lower.contains("lab") || lower.contains("anatomy") || lower.contains("exam"))
            || lower.contains("thalamus") && (lower.contains("class") || lower.contains("lab") || lower.contains("anatomy") || lower.contains("exam"))
            || lower.contains("hypothalamus") && (lower.contains("class") || lower.contains("lab") || lower.contains("anatomy") || lower.contains("exam")) {
            return "neuroanatomy"
        }
        // neurobiologylab — positioned AFTER neuroanatomy and BEFORE pharmacology so neurobiology
        // lab-specific sessions (patch clamp training, neural tracing, calcium imaging, lab reports)
        // route here. "electrophysiology" in research context stays in electrophysiology (much later).
        // "neuroanatomy class" stays in neuroanatomy (fires before).
        if lower.contains("neurobiology lab") && (lower.contains("class") || lower.contains("course") || lower.contains("report") || lower.contains("notebook") || lower.contains("experiment") || lower.contains("practical") || lower.contains("assignment"))
            || lower.contains("patch clamp") && (lower.contains("class") || lower.contains("lab") || lower.contains("neurobiology") || lower.contains("course") || lower.contains("training"))
            || lower.contains("whole-cell patch") && (lower.contains("lab") || lower.contains("class") || lower.contains("neurobiology"))
            || lower.contains("neural tracing") && (lower.contains("class") || lower.contains("lab") || lower.contains("neurobiology"))
            || lower.contains("in vitro brain slice") && (lower.contains("class") || lower.contains("lab") || lower.contains("neurobiology"))
            || lower.contains("brain slice preparation") && (lower.contains("class") || lower.contains("lab") || lower.contains("neurobiology"))
            || lower.contains("calcium imaging") && (lower.contains("class") || lower.contains("lab") || lower.contains("neurobiology") || lower.contains("neuroscience"))
            || lower.contains("synaptic physiology") && (lower.contains("class") || lower.contains("lab") || lower.contains("neurobiology"))
            || lower.contains("neurobiology lab report") || lower.contains("neurobiology lab notebook") {
            return "neurobiologylab"
        }
        // pharmacology — positioned BEFORE physiology and premed to catch dedicated pharmacology
        // class/lab work. Bare word("pharmacology") stays in premed (MCAT context fires after).
        // "pharmacy" routes to pharmacy branch much earlier.
        if lower.contains("pharmacology class") || lower.contains("pharmacology course")
            || lower.contains("pharmacology exam") || lower.contains("pharmacology lab")
            || lower.contains("pharmacology notes") || lower.contains("pharmacology textbook")
            || lower.contains("pharmacology assignment") || lower.contains("pharmacology lecture")
            || lower.contains("pharmacology problem set") || lower.contains("pharmacology homework")
            || lower.contains("pharmacokinetics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("assignment"))
            || lower.contains("pharmacodynamics") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("assignment"))
            || lower.contains("drug receptor") && (lower.contains("class") || lower.contains("course") || lower.contains("pharmacology") || lower.contains("exam"))
            || lower.contains("drug-receptor") && (lower.contains("class") || lower.contains("course") || lower.contains("pharmacology") || lower.contains("exam"))
            || lower.contains("receptor binding") && (lower.contains("class") || lower.contains("pharmacology") || lower.contains("exam") || lower.contains("assay"))
            || lower.contains("dose-response") && (lower.contains("class") || lower.contains("pharmacology") || lower.contains("exam") || lower.contains("curve"))
            || lower.contains("drug metabolism") && (lower.contains("class") || lower.contains("pharmacology") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("drug toxicity") && (lower.contains("class") || lower.contains("pharmacology") || lower.contains("exam") || lower.contains("study"))
            || lower.contains("agonist") && (lower.contains("pharmacology") || lower.contains("class") || lower.contains("receptor") || lower.contains("exam"))
            || lower.contains("antagonist") && (lower.contains("pharmacology") || lower.contains("class") || lower.contains("receptor") || lower.contains("exam"))
            || lower.contains("therapeutic index") && (lower.contains("class") || lower.contains("pharmacology") || lower.contains("exam"))
            || lower.contains("bioavailability") && (lower.contains("class") || lower.contains("pharmacology") || lower.contains("exam") || lower.contains("drug"))
            || lower.contains("drug distribution") && (lower.contains("class") || lower.contains("pharmacology") || lower.contains("exam"))
            || lower.contains("drug excretion") && (lower.contains("class") || lower.contains("pharmacology") || lower.contains("exam"))
            || lower.contains("pharmacology major") || lower.contains("pharmacology degree")
            || lower.contains("clinical pharmacology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")) {
            return "pharmacology"
        }
        // medicinalchemistry — positioned AFTER pharmacology and BEFORE physiology so drug design,
        // SAR analysis, and lead optimization in a medicinal chemistry course context route here.
        // "pharmacology" and "pharmacy" stay in their respective branches (fire earlier).
        if lower.contains("medicinal chemistry") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("notes") || lower.contains("assignment") || lower.contains("lecture") || lower.contains("program"))
            || lower.contains("drug design") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("medicinal") || lower.contains("chemistry") || lower.contains("problem set"))
            || lower.contains("structure-activity relationship") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("medicinal") || lower.contains("drug"))
            || lower.contains("sar analysis") && (lower.contains("class") || lower.contains("medicinal") || lower.contains("drug") || lower.contains("chemistry"))
            || lower.contains("lead optimization") && (lower.contains("class") || lower.contains("course") || lower.contains("drug") || lower.contains("chemistry") || lower.contains("medicinal"))
            || lower.contains("lead compound") && (lower.contains("class") || lower.contains("course") || lower.contains("drug") || lower.contains("optimization") || lower.contains("medicinal"))
            || lower.contains("pharmacophore") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("model") || lower.contains("medicinal") || lower.contains("drug design"))
            || lower.contains("prodrug") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("design") || lower.contains("medicinal") || lower.contains("chemistry"))
            || lower.contains("bioisostere") && (lower.contains("class") || lower.contains("medicinal") || lower.contains("drug") || lower.contains("chemistry"))
            || lower.contains("lipinski") && (lower.contains("class") || lower.contains("drug") || lower.contains("medicinal") || lower.contains("chemistry"))
            || lower.contains("admet") && (lower.contains("class") || lower.contains("course") || lower.contains("drug design") || lower.contains("medicinal") || lower.contains("chemistry"))
            || lower.contains("scaffold hopping") && (lower.contains("class") || lower.contains("drug") || lower.contains("medicinal") || lower.contains("chemistry")) {
            return "medicinalchemistry"
        }
        // physiology — positioned AFTER pharmacology and BEFORE premed to catch dedicated physiology
        // class/lab work. Bare word("physiology") stays in premed (MCAT context fires after).
        if lower.contains("physiology class") || lower.contains("physiology course")
            || lower.contains("physiology exam") || lower.contains("physiology lab")
            || lower.contains("physiology notes") || lower.contains("physiology textbook")
            || lower.contains("physiology assignment") || lower.contains("physiology lecture")
            || lower.contains("physiology problem set") || lower.contains("physiology homework")
            || lower.contains("human physiology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("study"))
            || lower.contains("organ systems physiology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("cell physiology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("cardiovascular physiology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("respiratory physiology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("renal physiology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("gastrointestinal physiology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("endocrine physiology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("neurophysiology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("musculoskeletal physiology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("exercise physiology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("notes"))
            || lower.contains("membrane potential") && (lower.contains("physiology") || lower.contains("class") || lower.contains("exam"))
            || lower.contains("action potential") && (lower.contains("physiology") || lower.contains("class") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("homeostasis") && (lower.contains("physiology") || lower.contains("class") || lower.contains("exam") || lower.contains("lab"))
            || lower.contains("physiology major") || lower.contains("physiology degree")
            || lower.contains("physiology program") || lower.contains("physiology textbook class") {
            return "physiology"
        }
        // anesthesiology — positioned AFTER physiology and BEFORE premed so CRNA program,
        // anesthesiology rotation, and anesthetic pharmacology tasks route here.
        // "anesthesia" alone without class/rotation/CRNA context stays in premed.
        // "pharmacology of anesthetics" routes here because anesthesia fires before pharmacology (above).
        if lower.contains("anesthesiology rotation") || lower.contains("anesthesiology clerkship")
            || lower.contains("anesthesiology elective") || lower.contains("anesthesiology residency")
            || lower.contains("anesthesiology class") || lower.contains("anesthesiology course")
            || lower.contains("anesthesiology exam") || lower.contains("anesthesiology notes")
            || lower.contains("anesthesiology program") || lower.contains("anesthesiology assignment")
            || word("crna") || lower.contains("crna program") || lower.contains("crna school")
            || lower.contains("crna exam") || lower.contains("crna class") || lower.contains("crna course")
            || lower.contains("nurse anesthesia") || lower.contains("anesthesia nursing")
            || lower.contains("anesthesia rotation") || lower.contains("anesthesia clerkship")
            || lower.contains("anesthesia class") || lower.contains("anesthesia course") && !lower.contains("pharmacology")
            || lower.contains("anesthetic pharmacology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("rotation"))
            || lower.contains("volatile anesthetic") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("inhalation anesthetic") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("intravenous anesthetic") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("regional anesthesia") && (lower.contains("class") || lower.contains("course") || lower.contains("rotation") || lower.contains("exam"))
            || lower.contains("spinal anesthesia") && (lower.contains("class") || lower.contains("course") || lower.contains("rotation"))
            || lower.contains("epidural anesthesia") && (lower.contains("class") || lower.contains("course") || lower.contains("rotation"))
            || lower.contains("anesthesia machine") && (lower.contains("class") || lower.contains("course") || lower.contains("rotation") || lower.contains("lab"))
            || lower.contains("airway management") && (lower.contains("anesthesia") || lower.contains("crna") || lower.contains("rotation") || lower.contains("class"))
            || lower.contains("mac monitoring") && (lower.contains("anesthesia") || lower.contains("class") || lower.contains("rotation"))
            || lower.contains("gas laws") && (lower.contains("anesthesia") || lower.contains("crna") || lower.contains("class"))
            || word("anesthesiology") || word("anesthesiologist") || word("anesthesiologists") {
            return "anesthesiology"
        }
        // structuralbiology — positioned AFTER anesthesiology and BEFORE premed so cryo-EM,
        // protein structure determination, PDB, and SAXS route here and not to molecularbiology
        // (which owns Western blot / PCR) or materialscience (which owns "crystallography class").
        if lower.contains("structural biology") || lower.contains("structural biologist")
            || lower.contains("cryo-em") || lower.contains("cryo em") || lower.contains("cryo-electron microscopy")
            || lower.contains("protein structure determination") || lower.contains("protein structure prediction")
            || lower.contains("protein data bank") || lower.contains("pdb structure") || lower.contains("pdb database")
            || lower.contains("saxs") && (lower.contains("biology") || lower.contains("protein") || lower.contains("structural") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("small-angle x-ray scattering") && (lower.contains("biology") || lower.contains("protein") || lower.contains("structural"))
            || lower.contains("protein crystallization") && (lower.contains("lab") || lower.contains("class") || lower.contains("structural") || lower.contains("crystallography"))
            || lower.contains("protein nmr") || (lower.contains("nmr spectroscopy") && (lower.contains("protein") || lower.contains("structural") || lower.contains("biology")))
            || lower.contains("homology modeling") && (lower.contains("protein") || lower.contains("structural") || lower.contains("biology"))
            || lower.contains("protein folding") && (lower.contains("class") || lower.contains("research") || lower.contains("structural") || lower.contains("biology") || lower.contains("lab"))
            || (word("alphafold") && (lower.contains("protein") || lower.contains("structural") || lower.contains("research") || lower.contains("class")))
            || lower.contains("structural genomics") || lower.contains("structuralbiology class")
            || lower.contains("structural biology class") || lower.contains("structural biology course")
            || lower.contains("structural biology lab") || lower.contains("structural biology research") {
            return "structuralbiology"
        }
        // biochemistrylab — positioned AFTER molecularbiology (which owns Western blot/PCR) and
        // BEFORE premed. Catches hands-on biochemistry lab course work. Bare word("biochemistry")
        // without lab/class/course context stays in premed for MCAT.
        if lower.contains("sds-page") || lower.contains("sds page") || lower.contains("sds polyacrylamide")
            || lower.contains("bradford assay") || lower.contains("bca assay") || lower.contains("lowry assay")
            || lower.contains("protein assay") && (lower.contains("lab") || lower.contains("biochemistry") || lower.contains("class"))
            || lower.contains("enzyme kinetics lab") || lower.contains("enzyme kinetics class") || lower.contains("enzyme kinetics course")
            || lower.contains("michaelis-menten") && (lower.contains("lab") || lower.contains("class") || lower.contains("biochemistry") || lower.contains("experiment"))
            || lower.contains("column chromatography") && (lower.contains("lab") || lower.contains("class") || lower.contains("biochemistry"))
            || lower.contains("affinity chromatography") && (lower.contains("lab") || lower.contains("class") || lower.contains("biochemistry"))
            || lower.contains("size exclusion chromatography") && (lower.contains("lab") || lower.contains("class") || lower.contains("biochemistry"))
            || lower.contains("ion exchange chromatography") && (lower.contains("lab") || lower.contains("class") || lower.contains("biochemistry"))
            || lower.contains("hplc") && (lower.contains("biochemistry") || lower.contains("protein") || lower.contains("lab class") || lower.contains("biochem lab"))
            || lower.contains("biochemistry lab") && (lower.contains("class") || lower.contains("course") || lower.contains("report") || lower.contains("notebook") || lower.contains("experiment") || lower.contains("practical") || lower.contains("assignment"))
            || lower.contains("biochemistry experiment") || lower.contains("biochemistry practical")
            || lower.contains("biochemistry lab report") || lower.contains("biochem lab report")
            || lower.contains("biochemistry lab notebook") || lower.contains("biochem lab notebook") {
            return "biochemistrylab"
        }
        // clinicalneurology — positioned AFTER neuroanatomy and anesthesiology and BEFORE premed
        // so neurology-rotation/ward tasks route here. "neuroanatomy class" stays in neuroanatomy
        // (fires earlier). Bare "neurology" alone stays in premed.
        if lower.contains("neurology rotation") || lower.contains("neuro rotation")
            || lower.contains("neurology clerkship") || lower.contains("neuro clerkship")
            || lower.contains("neurology elective") || lower.contains("neurology ward")
            || lower.contains("neurology rounds") || lower.contains("neuro rounds")
            || lower.contains("neurology attending") || lower.contains("neuro attending")
            || lower.contains("neurology consult") || lower.contains("neuro consult")
            || lower.contains("neurology residency") && (lower.contains("reading") || lower.contains("notes") || lower.contains("rotation") || lower.contains("case"))
            || lower.contains("neurological exam") && (lower.contains("rotation") || lower.contains("ward") || lower.contains("class") || lower.contains("clinical"))
            || lower.contains("eeg interpretation") && (lower.contains("rotation") || lower.contains("class") || lower.contains("neurology") || lower.contains("clinical"))
            || lower.contains("lumbar puncture") && (lower.contains("rotation") || lower.contains("class") || lower.contains("neurology") || lower.contains("clinical"))
            || lower.contains("neurological assessment") && (lower.contains("ward") || lower.contains("rotation") || lower.contains("clinical"))
            || lower.contains("neurology case") && (lower.contains("rotation") || lower.contains("write") || lower.contains("presentation") || lower.contains("ward"))
            || lower.contains("neuro case") && (lower.contains("rotation") || lower.contains("write") || lower.contains("presentation") || lower.contains("ward")) {
            return "clinicalneurology"
        }
        // dermatologyrotation — positioned AFTER radiologyrotation and BEFORE premed so derm
        // rotation, dermoscopy, and skin-biopsy interpretation tasks route here. Bare "dermatology"
        // alone stays in premed.
        if lower.contains("dermatology rotation") || lower.contains("derm rotation")
            || lower.contains("dermatology clerkship") || lower.contains("derm clerkship")
            || lower.contains("dermatology elective") || lower.contains("derm elective")
            || lower.contains("dermatology reading") || lower.contains("derm reading")
            || lower.contains("dermatology rounds") || lower.contains("derm rounds")
            || lower.contains("dermatology attending") || lower.contains("derm attending")
            || lower.contains("dermatology residency") && (lower.contains("reading") || lower.contains("notes") || lower.contains("rotation") || lower.contains("case"))
            || lower.contains("skin biopsy") && (lower.contains("rotation") || lower.contains("class") || lower.contains("dermatology") || lower.contains("derm") || lower.contains("interpretation"))
            || lower.contains("dermoscopy") && (lower.contains("rotation") || lower.contains("class") || lower.contains("dermatology") || lower.contains("study"))
            || lower.contains("derm notes") || lower.contains("dermatology notes") && lower.contains("rotation")
            || lower.contains("dermatology case") && (lower.contains("rotation") || lower.contains("write") || lower.contains("presentation"))
            || lower.contains("lesion classification") && (lower.contains("dermatology") || lower.contains("derm") || lower.contains("rotation") || lower.contains("class"))
            || (word("dermatologist") && (lower.contains("rotation") || lower.contains("notes") || lower.contains("studying") || lower.contains("rounds"))) {
            return "dermatologyrotation"
        }
        // psychiatryrotation — positioned AFTER dermatologyrotation and BEFORE premed so psych
        // rotation, mental status exam, and DSM-5 formulation tasks route here. Bare "psychiatry"
        // alone stays in premed; "psychology" stays in psychology (fires much earlier).
        if lower.contains("psychiatry rotation") || lower.contains("psych rotation")
            || lower.contains("psychiatry clerkship") || lower.contains("psych clerkship")
            || lower.contains("psychiatry elective") || lower.contains("inpatient psychiatry")
            || lower.contains("psychiatry ward") || lower.contains("psych ward") && (lower.contains("rotation") || lower.contains("clerkship") || lower.contains("notes"))
            || lower.contains("psychiatry rounds") || lower.contains("psych rounds")
            || lower.contains("psychiatry attending") || lower.contains("psych attending")
            || lower.contains("psychiatry notes") && lower.contains("rotation")
            || lower.contains("psychiatry residency") && (lower.contains("reading") || lower.contains("notes") || lower.contains("rotation") || lower.contains("case"))
            || lower.contains("mental status exam") && (lower.contains("rotation") || lower.contains("class") || lower.contains("psychiatry") || lower.contains("psych") || lower.contains("clinical"))
            || lower.contains("dsm-5 case") || lower.contains("dsm5 case") || lower.contains("dsm-5 formulation")
            || lower.contains("psychiatric formulation") || lower.contains("psychiatric case formulation")
            || lower.contains("psychiatric assessment") && (lower.contains("rotation") || lower.contains("ward") || lower.contains("clinical"))
            || lower.contains("psychiatry case") && (lower.contains("rotation") || lower.contains("write") || lower.contains("presentation"))
            || lower.contains("mood disorder case") && (lower.contains("rotation") || lower.contains("psychiatry") || lower.contains("psych")) {
            return "psychiatryrotation"
        }
        // surgeryrotation — positioned AFTER psychiatryrotation and BEFORE premed so surgery
        // clerkship, OR tasks, and operative notes route here. Bare "surgery" stays in premed.
        if lower.contains("surgery rotation") || lower.contains("surgery clerkship")
            || lower.contains("surgical rotation") || lower.contains("surgical clerkship")
            || lower.contains("surgery elective") || lower.contains("surgical elective")
            || lower.contains("surgery rounds") || lower.contains("surgical rounds")
            || lower.contains("surgery attending") || lower.contains("surgical attending")
            || lower.contains("surgery ward") || lower.contains("surgical ward")
            || lower.contains("scrub in") || lower.contains("scrubbing in")
            || lower.contains("operative report") && (lower.contains("rotation") || lower.contains("clerkship") || lower.contains("surgery") || lower.contains("write"))
            || lower.contains("surgical notes") && (lower.contains("rotation") || lower.contains("clerkship") || lower.contains("write"))
            || lower.contains("pre-op notes") || lower.contains("preop notes")
            || lower.contains("post-op notes") || lower.contains("postop notes")
            || lower.contains("surgical case") && (lower.contains("rotation") || lower.contains("clerkship") || lower.contains("presentation"))
            || lower.contains("surgery case") && (lower.contains("rotation") || lower.contains("clerkship") || lower.contains("presentation"))
            || lower.contains("surgery residency") && (lower.contains("reading") || lower.contains("notes") || lower.contains("rotation") || lower.contains("case"))
            || lower.contains("surgical residency") && (lower.contains("reading") || lower.contains("notes") || lower.contains("rotation"))
            || lower.contains("surgery shelf") || lower.contains("surgical shelf")
            || lower.contains("nbme surgery") || lower.contains("surgery nbme") {
            return "surgeryrotation"
        }
        // pediatricsrotation — positioned AFTER surgeryrotation and BEFORE premed. Bare "pediatrics"
        // alone stays in premed; NBME/shelf context specific to peds rotation routes here.
        if lower.contains("pediatrics rotation") || lower.contains("pediatrics clerkship")
            || lower.contains("peds rotation") || lower.contains("peds clerkship")
            || lower.contains("pediatric rotation") || lower.contains("pediatric clerkship")
            || lower.contains("pediatrics elective") || lower.contains("peds elective")
            || lower.contains("pediatrics rounds") || lower.contains("peds rounds")
            || lower.contains("pediatrics attending") || lower.contains("peds attending")
            || lower.contains("pediatrics ward") || lower.contains("peds ward")
            || lower.contains("pediatric ward") && (lower.contains("rotation") || lower.contains("clerkship") || lower.contains("notes"))
            || lower.contains("developmental milestones") && (lower.contains("rotation") || lower.contains("class") || lower.contains("peds") || lower.contains("pediatric") || lower.contains("clinical"))
            || lower.contains("pediatric exam") && (lower.contains("rotation") || lower.contains("clinical") || lower.contains("clerkship"))
            || lower.contains("pediatric case") && (lower.contains("rotation") || lower.contains("write") || lower.contains("presentation"))
            || lower.contains("peds case") && (lower.contains("rotation") || lower.contains("write") || lower.contains("presentation"))
            || lower.contains("pediatrics notes") && (lower.contains("rotation") || lower.contains("write"))
            || lower.contains("peds notes") && (lower.contains("rotation") || lower.contains("write"))
            || lower.contains("pediatrics residency") && (lower.contains("reading") || lower.contains("notes") || lower.contains("rotation"))
            || lower.contains("peds shelf") || lower.contains("pediatrics shelf")
            || lower.contains("nbme pediatrics") || lower.contains("nbme peds") {
            return "pediatricsrotation"
        }
        // internalmedicine — positioned AFTER pediatricsrotation and BEFORE premed. "internal medicine"
        // alone without clerkship/rotation context stays in premed; H&P write-up and SOAP notes
        // in clinical context route here.
        if lower.contains("internal medicine clerkship") || lower.contains("internal medicine rotation")
            || lower.contains("im clerkship") || lower.contains("im rotation")
            || lower.contains("medicine clerkship") || lower.contains("medicine rotation")
            || lower.contains("internal medicine rounds") || lower.contains("im rounds")
            || lower.contains("medicine rounds") && (lower.contains("rotation") || lower.contains("clerkship") || lower.contains("attending") || lower.contains("notes"))
            || lower.contains("internal medicine attending") || lower.contains("im attending")
            || lower.contains("internal medicine ward") || lower.contains("im ward")
            || lower.contains("internal medicine elective")
            || lower.contains("h&p write") || lower.contains("h and p write") || lower.contains("history and physical") && (lower.contains("write") || lower.contains("rotation") || lower.contains("clerkship") || lower.contains("notes"))
            || lower.contains("soap notes") && (lower.contains("rotation") || lower.contains("clerkship") || lower.contains("internal medicine") || lower.contains("im ") || lower.contains("ward"))
            || lower.contains("internal medicine case") && (lower.contains("rotation") || lower.contains("write") || lower.contains("presentation"))
            || lower.contains("im case") && (lower.contains("rotation") || lower.contains("write") || lower.contains("presentation"))
            || lower.contains("internal medicine notes") && (lower.contains("rotation") || lower.contains("write"))
            || lower.contains("im shelf") || lower.contains("internal medicine shelf")
            || lower.contains("medicine shelf") && (lower.contains("rotation") || lower.contains("clerkship") || lower.contains("nbme")) {
            return "internalmedicine"
        }
        // obgynrotation — positioned AFTER internalmedicine and BEFORE premed. Bare "obstetrics" or
        // "gynecology" alone stays in premed; OB/GYN clerkship-specific context routes here.
        if lower.contains("ob/gyn rotation") || lower.contains("ob/gyn clerkship")
            || lower.contains("obgyn rotation") || lower.contains("obgyn clerkship")
            || lower.contains("ob-gyn rotation") || lower.contains("ob-gyn clerkship")
            || lower.contains("obstetrics rotation") || lower.contains("obstetrics clerkship")
            || lower.contains("gynecology rotation") || lower.contains("gynecology clerkship")
            || lower.contains("obs rotation") || lower.contains("labor and delivery rotation")
            || lower.contains("labor and delivery notes") && (lower.contains("rotation") || lower.contains("clerkship") || lower.contains("write"))
            || lower.contains("l&d rotation") || lower.contains("l&d notes") && (lower.contains("rotation") || lower.contains("write") || lower.contains("clerkship"))
            || lower.contains("ob/gyn rounds") || lower.contains("obgyn rounds")
            || lower.contains("ob/gyn attending") || lower.contains("obgyn attending")
            || lower.contains("ob/gyn notes") && (lower.contains("rotation") || lower.contains("write"))
            || lower.contains("obgyn notes") && (lower.contains("rotation") || lower.contains("write"))
            || lower.contains("ob/gyn case") && (lower.contains("rotation") || lower.contains("write") || lower.contains("presentation"))
            || lower.contains("gynecology case") && (lower.contains("rotation") || lower.contains("write") || lower.contains("presentation"))
            || lower.contains("ob/gyn shelf") || lower.contains("obgyn shelf")
            || lower.contains("nbme ob/gyn") || lower.contains("nbme obgyn") {
            return "obgynrotation"
        }
        // familymedicine — positioned AFTER obgynrotation and BEFORE premed. Bare "family medicine"
        // alone without clerkship/rotation context stays in premed; FM clerkship tasks route here.
        if lower.contains("family medicine clerkship") || lower.contains("family medicine rotation")
            || lower.contains("fm clerkship") || lower.contains("fm rotation")
            || lower.contains("family medicine elective") || lower.contains("family medicine clinic")
            || lower.contains("fm clinic") && (lower.contains("rotation") || lower.contains("clerkship") || lower.contains("notes"))
            || lower.contains("family medicine rounds") || lower.contains("fm rounds")
            || lower.contains("family medicine attending") || lower.contains("fm attending")
            || lower.contains("family medicine notes") && (lower.contains("rotation") || lower.contains("write") || lower.contains("clerkship"))
            || lower.contains("fm notes") && (lower.contains("rotation") || lower.contains("write") || lower.contains("clerkship"))
            || lower.contains("continuity clinic") && (lower.contains("rotation") || lower.contains("clerkship") || lower.contains("family") || lower.contains("fm"))
            || lower.contains("family medicine case") && (lower.contains("rotation") || lower.contains("write") || lower.contains("presentation"))
            || lower.contains("fm case") && (lower.contains("rotation") || lower.contains("write") || lower.contains("presentation"))
            || lower.contains("family medicine shelf") || lower.contains("fm shelf")
            || lower.contains("nbme family medicine") {
            return "familymedicine"
        }
        // emergencymedicinerotation — positioned AFTER familymedicine and BEFORE premed so EM
        // clerkship, shift notes, and EM shelf study route to a dedicated pool. Bare "emergency
        // medicine" without rotation/clerkship context stays in premed (fires after).
        if lower.contains("emergency medicine rotation") || lower.contains("emergency medicine clerkship")
            || lower.contains("emergency medicine elective") || lower.contains("em rotation")
            || lower.contains("em clerkship") || lower.contains("em elective")
            || lower.contains("emergency medicine shift") && (lower.contains("notes") || lower.contains("write") || lower.contains("rotation") || lower.contains("clerkship") || lower.contains("report"))
            || lower.contains("em shift notes") || lower.contains("em shift write")
            || lower.contains("emergency medicine rounds") || lower.contains("em rounds") && (lower.contains("rotation") || lower.contains("clerkship") || lower.contains("notes") || lower.contains("attending"))
            || lower.contains("emergency medicine attending") || lower.contains("em attending")
            || lower.contains("emergency medicine case") && (lower.contains("rotation") || lower.contains("clerkship") || lower.contains("write") || lower.contains("presentation"))
            || lower.contains("em case") && (lower.contains("rotation") || lower.contains("clerkship") || lower.contains("write") || lower.contains("presentation"))
            || lower.contains("emergency medicine notes") && (lower.contains("rotation") || lower.contains("clerkship") || lower.contains("write") || lower.contains("shift"))
            || lower.contains("em notes") && (lower.contains("rotation") || lower.contains("clerkship") || lower.contains("write") || lower.contains("shift"))
            || lower.contains("emergency medicine shelf") || lower.contains("em shelf")
            || lower.contains("nbme emergency medicine") || lower.contains("nbme em") {
            return "emergencymedicinerotation"
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
        // maternalhealth — positioned AFTER midwifery and BEFORE palliativecare. Catches maternal
        // health class/course, maternal mortality coursework, OB nursing class, prenatal care class,
        // perinatal nursing, and maternal-fetal medicine programs. Midwifery-specific charting/notes
        // already owned above; "birth plan" owned by midwifery.
        if lower.contains("maternal health class") || lower.contains("maternal health course")
            || lower.contains("maternal health exam") || lower.contains("maternal health program")
            || lower.contains("maternal health notes") || lower.contains("maternal health assignment")
            || lower.contains("maternal mortality class") || lower.contains("maternal mortality course")
            || lower.contains("maternal mortality assignment") || lower.contains("maternal mortality exam")
            || lower.contains("maternal mortality paper") || lower.contains("maternal mortality research")
            || lower.contains("maternal-fetal medicine class") || lower.contains("maternal-fetal medicine course")
            || lower.contains("maternal-fetal medicine exam") || lower.contains("maternal-fetal medicine program")
            || lower.contains("maternal fetal medicine class") || lower.contains("maternal fetal medicine course")
            || lower.contains("obstetric nursing class") || lower.contains("obstetric nursing course")
            || lower.contains("obstetric nursing exam") || lower.contains("obstetric nursing notes")
            || lower.contains("ob nursing class") || lower.contains("ob nursing course")
            || lower.contains("ob nursing exam") || lower.contains("ob nursing notes")
            || lower.contains("perinatal nursing class") || lower.contains("perinatal nursing course")
            || lower.contains("perinatal nursing exam") || lower.contains("perinatal nursing notes")
            || lower.contains("maternal-newborn nursing class") || lower.contains("maternal-newborn nursing course")
            || lower.contains("maternal newborn nursing class") || lower.contains("maternal newborn nursing course")
            || lower.contains("prenatal care class") || lower.contains("prenatal care course")
            || lower.contains("prenatal care exam") || lower.contains("prenatal care assignment")
            || lower.contains("intrapartum nursing class") || lower.contains("intrapartum nursing course")
            || lower.contains("postpartum nursing class") || lower.contains("postpartum nursing course")
            || lower.contains("postpartum care class") || lower.contains("postpartum care course")
            || lower.contains("obstetrics class") || lower.contains("obstetrics course")
            || lower.contains("obstetrics exam") || lower.contains("obstetrics assignment")
            || (lower.contains("obstetrics and gynecology") || lower.contains("ob/gyn") || lower.contains("ob-gyn"))
                && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("rotation") || lower.contains("assignment")) {
            return "maternalhealth"
        }
        // palliativecare — positioned BEFORE forensicnursing and nursing so CHPN exam prep,
        // hospice nursing, end-of-life care, and palliative medicine clinical tasks route here.
        if lower.contains("palliative care") || lower.contains("palliative nurse")
            || lower.contains("palliative nursing") || lower.contains("palliative medicine")
            || lower.contains("palliative care class") || lower.contains("palliative care course")
            || lower.contains("palliative care program") || lower.contains("palliative care exam")
            || lower.contains("palliative care rotation") || lower.contains("palliative care notes")
            || lower.contains("palliative care assignment") || lower.contains("palliative care clinical")
            || lower.contains("hospice care") || lower.contains("hospice nurse")
            || lower.contains("hospice nursing") || lower.contains("hospice class")
            || lower.contains("hospice course") || lower.contains("hospice program")
            || lower.contains("hospice exam") || lower.contains("hospice notes")
            || lower.contains("hospice assignment") || lower.contains("hospice volunteer training")
            || word("chpn") || lower.contains("chpn exam") || lower.contains("chpn certification")
            || lower.contains("hpcc board") || lower.contains("hpcc exam")
            || lower.contains("end-of-life care") || lower.contains("end of life care")
            || lower.contains("comfort care nursing") || lower.contains("comfort measures")
            || lower.contains("palliative care nurse") || lower.contains("palliative care specialist")
            || lower.contains("symptom management") && (lower.contains("palliative") || lower.contains("hospice") || lower.contains("end of life") || lower.contains("terminal")) {
            return "palliativecare"
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
        // nursepractitioner — positioned AFTER emergencynursing and BEFORE nursing so FNP,
        // PMHNP, AGPCNP, DNP (NP track), and AANP/ANCC certification prep gets a dedicated pool.
        // General nursing tasks stay in the nursing branch below.
        if lower.contains("nurse practitioner") || lower.contains("nurse practitioners")
            || word("fnp") || word("pmhnp") || word("agpcnp") || word("whnp") || word("acnp")
            || lower.contains("fnp-bc") || lower.contains("pmhnp-bc") || lower.contains("fnp-c") || lower.contains("pmhnp-c")
            || lower.contains("aanp cert") || lower.contains("aanp exam") || lower.contains("aanp certification")
            || lower.contains("ancc fnp") || lower.contains("ancc pmhnp")
            || lower.contains("ancc exam") && (lower.contains("np") || lower.contains("nurse practitioner"))
            || lower.contains("ancc certification") && (lower.contains("np") || lower.contains("nurse practitioner"))
            || lower.contains("np program") || lower.contains("np school") || lower.contains("np class")
            || lower.contains("np course") || lower.contains("np exam") || lower.contains("np rotation")
            || lower.contains("np clinical") || lower.contains("np practicum") || lower.contains("np residency")
            || lower.contains("np notes") || lower.contains("np coursework") || lower.contains("np degree")
            || lower.contains("dnp program") && lower.contains("np")
            || lower.contains("dnp school") && lower.contains("np")
            || lower.contains("clinical nurse specialist") || word("cns") && (lower.contains("nurse") || lower.contains("clinical nurse"))
            || lower.contains("advanced practice nursing") || lower.contains("advanced practice nurse")
            || lower.contains("aprn program") || lower.contains("aprn exam") || lower.contains("aprn certification")
            || lower.contains("aprn class") || lower.contains("aprn course") || lower.contains("aprn notes") {
            return "nursepractitioner"
        }
        // nursinganesthesia — positioned AFTER nursepractitioner and BEFORE nursing so CRNA,
        // nurse anesthesia programs, and NBCRNA exam prep get a dedicated pool rather than the
        // broader nursing pool. "nurse practitioner" stays in nursepractitioner above.
        if lower.contains("nurse anesthesia") || lower.contains("nurse anesthetist")
            || lower.contains("nurse anesthesiologist") || word("crna")
            || lower.contains("crna program") || lower.contains("crna school")
            || lower.contains("crna class") || lower.contains("crna exam")
            || lower.contains("crna certification") || lower.contains("crna clinical")
            || lower.contains("crna rotation") || lower.contains("crna notes")
            || word("nbcrna") || lower.contains("nbcrna exam") || lower.contains("nbcrna certification")
            || lower.contains("nurse anesthesia program") || lower.contains("nurse anesthesia class")
            || lower.contains("nurse anesthesia course") || lower.contains("nurse anesthesia school")
            || lower.contains("nurse anesthesia exam") || lower.contains("nurse anesthesia rotation")
            || lower.contains("nurse anesthesia clinical") || lower.contains("nurse anesthesia notes")
            || lower.contains("dnap program") || lower.contains("dnap class") || lower.contains("dnap school")
            || lower.contains("msna program") || lower.contains("msna class")
            || lower.contains("anesthesia pharmacology") && (lower.contains("nursing") || lower.contains("crna")) {
            return "nursinganesthesia"
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
        // polyvagaltheory — positioned AFTER behavioranalysis and BEFORE socialwork so polyvagal
        // theory coursework, somatic experiencing certification, and IFS therapy training route here.
        // Generic somatic or therapy terms stay in the therapy branch below.
        if lower.contains("polyvagal theory") || lower.contains("polyvagal class") || lower.contains("polyvagal course")
            || lower.contains("polyvagal training") || lower.contains("polyvagal certification")
            || lower.contains("polyvagal exam") || lower.contains("polyvagal program")
            || lower.contains("polyvagal therapy") || lower.contains("polyvagal nervous system")
            || lower.contains("somatic experiencing") && (lower.contains("class") || lower.contains("course") || lower.contains("training") || lower.contains("cert") || lower.contains("program") || lower.contains("practition") || lower.contains("level") || lower.contains("module") || lower.contains("notes"))
            || lower.contains("internal family systems") && (lower.contains("class") || lower.contains("course") || lower.contains("training") || lower.contains("cert") || lower.contains("program") || lower.contains("therapy") || lower.contains("level") || lower.contains("practition"))
            || word("ifs") && (lower.contains("therapy training") || lower.contains("parts work") || lower.contains("trailhead") || lower.contains("ifs cert") || lower.contains("ifs program"))
            || lower.contains("parts work therapy") || lower.contains("parts work training")
            || lower.contains("somatic therapy training") || lower.contains("somatic therapy certification")
            || lower.contains("somatic therapy class") || lower.contains("somatic therapy course")
            || lower.contains("somatic therapy program")
            || lower.contains("autonomic nervous system regulation") && (lower.contains("class") || lower.contains("course") || lower.contains("training") || lower.contains("therapy") || lower.contains("cert"))
            || lower.contains("nervous system regulation") && (lower.contains("polyvagal") || lower.contains("somatic") || lower.contains("therapy training"))
            || lower.contains("vagal tone") && (lower.contains("class") || lower.contains("training") || lower.contains("therapy")) {
            return "polyvagaltheory"
        }
        // schoolcounseling — positioned AFTER polyvagaltheory and BEFORE socialwork so school
        // counselors, CACREP programs, career counseling class, and student affairs coursework
        // route here. Generic "counseling" stays in the therapy branch (fires later).
        if lower.contains("school counselor") || lower.contains("school counseling")
            || word("cacrep") || lower.contains("cacrep program") || lower.contains("cacrep class")
            || lower.contains("cacrep accredited") || lower.contains("cacrep internship")
            || lower.contains("guidance counselor") || lower.contains("guidance counseling")
            || lower.contains("career counseling class") || lower.contains("career counseling course")
            || lower.contains("career counseling exam") || lower.contains("career counseling program")
            || lower.contains("career counseling assignment") || lower.contains("career development class")
            || lower.contains("career development course") || lower.contains("career development theory")
            || lower.contains("college counseling class") || lower.contains("college counseling course")
            || lower.contains("college counseling program") || lower.contains("academic counseling class")
            || lower.contains("student affairs class") || lower.contains("student affairs course")
            || lower.contains("student affairs program") || lower.contains("student affairs practicum")
            || lower.contains("student development theory") || lower.contains("higher education counseling")
            || lower.contains("academic advising class") || lower.contains("academic advising course")
            || lower.contains("school counseling practicum") || lower.contains("school counseling internship")
            || lower.contains("school counseling licensure") || lower.contains("counseling licensure class")
            || lower.contains("counseling program") && (lower.contains("school") || lower.contains("cacrep") || lower.contains("guidance"))
            || lower.contains("counseling class") && (lower.contains("school") || lower.contains("guidance") || lower.contains("student affairs")) {
            return "schoolcounseling"
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
        // recreationaltherapy — positioned AFTER occupationaltherapy and BEFORE massagetherapy.
        // Catches CTRS/NCTRC certification, therapeutic recreation, and adaptive recreation.
        // "activity therapy" and "leisure" in general context stay in studying/other branches.
        if lower.contains("recreational therapy") || lower.contains("recreational therapist")
            || lower.contains("recreational therapists") || word("ctrs")
            || lower.contains("nctrc") || lower.contains("nctrc exam") || lower.contains("nctrc certification")
            || lower.contains("therapeutic recreation") || lower.contains("recreator")
            || lower.contains("tr class") || lower.contains("tr course") || lower.contains("tr exam")
            || lower.contains("tr program") || lower.contains("tr internship")
            || lower.contains("tr fieldwork") || lower.contains("tr clinical")
            || lower.contains("tr notes") && (lower.contains("therapy") || lower.contains("recreation") || lower.contains("client"))
            || lower.contains("recreation therapy") && !(lower.contains("music therapy") || lower.contains("art therapy"))
            || lower.contains("recreation therapist") || lower.contains("recreation therapy class")
            || lower.contains("recreation therapy program") || lower.contains("recreation therapy exam")
            || lower.contains("adaptive recreation") || lower.contains("adaptive leisure")
            || lower.contains("activity therapy") && (lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("clinical"))
            || lower.contains("leisure education") && (lower.contains("class") || lower.contains("course") || lower.contains("client") || lower.contains("program"))
            || lower.contains("diversional therapy") || lower.contains("therapeutic leisure")
            || lower.contains("equine-assisted therapy") && lower.contains("recreation")
            || lower.contains("aquatic therapy") && lower.contains("recreation")
            || lower.contains("recreational therapy certification") || lower.contains("recreational therapy licensure") {
            return "recreationaltherapy"
        }
        // animalassistedtherapy — positioned AFTER recreationaltherapy, BEFORE massagetherapy.
        // Catches AAT/AAI certification, therapy dog handling, equine-assisted psychotherapy,
        // and canine-assisted therapy as primary disciplines.
        // "equine-assisted therapy" WITH "recreation" context stays in recreationaltherapy above.
        if lower.contains("animal-assisted therapy") || lower.contains("animal assisted therapy")
            || lower.contains("animal-assisted intervention") || lower.contains("animal assisted intervention")
            || lower.contains("therapy dog") || lower.contains("therapy dogs")
            || lower.contains("canine-assisted therapy") || lower.contains("canine assisted therapy")
            || lower.contains("therapy animal") || lower.contains("therapy animals")
            || lower.contains("pet therapy") || lower.contains("pet-assisted therapy")
            || lower.contains("equine-assisted psychotherapy") || lower.contains("equine assisted psychotherapy")
            || lower.contains("equine-assisted learning") && !lower.contains("recreation")
            || lower.contains("animal-facilitated therapy") || lower.contains("animal facilitated therapy")
            || lower.contains("caahtt") || lower.contains("pet partners") && lower.contains("therapy")
            || lower.contains("animal assisted") && (lower.contains("class") || lower.contains("certification") || lower.contains("program") || lower.contains("intervention"))
            || word("aat") && (lower.contains("therapy") || lower.contains("animal") || lower.contains("certification"))
            || word("aai") && (lower.contains("therapy") || lower.contains("animal") || lower.contains("certification")) {
            return "animalassistedtherapy"
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
        // globalhealthpolicy — positioned AFTER publichealthnutrition and BEFORE environmentalhealth.
        // Catches global health policy, international health policy, global health governance,
        // health systems strengthening, and UHC policy. Bare "global health" NOT matched —
        // requires a policy/governance/law/diplomacy qualifier or explicit class context.
        if lower.contains("global health policy") || lower.contains("international health policy")
            || lower.contains("global health governance") || lower.contains("global health diplomacy")
            || lower.contains("global health law") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("program"))
            || lower.contains("health systems strengthening") && (lower.contains("class") || lower.contains("course") || lower.contains("policy") || lower.contains("exam") || lower.contains("program") || lower.contains("assignment"))
            || lower.contains("universal health coverage") && (lower.contains("policy") || lower.contains("class") || lower.contains("course") || lower.contains("assignment") || lower.contains("paper"))
            || lower.contains("uhc policy") || lower.contains("uhc class") || lower.contains("uhc course")
            || lower.contains("global burden of disease") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("paper") || lower.contains("assignment"))
            || lower.contains("lancet commission") && (lower.contains("class") || lower.contains("course") || lower.contains("paper") || lower.contains("assignment"))
            || lower.contains("who policy") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("assignment"))
            || lower.contains("global health financing") && (lower.contains("class") || lower.contains("course") || lower.contains("policy") || lower.contains("paper"))
            || lower.contains("global health security") && (lower.contains("class") || lower.contains("course") || lower.contains("policy") || lower.contains("paper") || lower.contains("exam"))
            || lower.contains("international health regulations") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("assignment"))
            || lower.contains("global health equity") && (lower.contains("class") || lower.contains("course") || lower.contains("policy") || lower.contains("paper"))
            || lower.contains("sdg health") && (lower.contains("class") || lower.contains("course") || lower.contains("policy") || lower.contains("paper") || lower.contains("target"))
            || lower.contains("global health policy class") || lower.contains("global health policy course")
            || lower.contains("global health policy exam") || lower.contains("global health policy paper")
            || lower.contains("global health policy program") || lower.contains("global health policy assignment") {
            return "globalhealthpolicy"
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
        // toxicology — positioned AFTER environmentalhealth (which owns "environmental
        // toxicology class") and BEFORE epidemiology so toxicology coursework, forensic
        // toxicology, and clinical toxicology programs route to a dedicated pool.
        if lower.contains("toxicology class") || lower.contains("toxicology course")
            || lower.contains("toxicology exam") || lower.contains("toxicology lab")
            || lower.contains("toxicology program") || lower.contains("toxicology major")
            || lower.contains("toxicology degree") || lower.contains("toxicology notes")
            || lower.contains("toxicology assignment") || lower.contains("toxicology paper")
            || lower.contains("toxicology report") || lower.contains("toxicologist")
            || lower.contains("forensic toxicology") || lower.contains("clinical toxicology")
            || lower.contains("analytical toxicology") || lower.contains("neurotoxicology")
            || lower.contains("reproductive toxicology") || lower.contains("ecotoxicology")
            || lower.contains("toxicokinetics") || lower.contains("dose-response")
                && (lower.contains("toxicology") || lower.contains("class") || lower.contains("course"))
            || lower.contains("risk assessment") && (lower.contains("toxicology") || lower.contains("toxicologist"))
            || lower.contains("tox screen") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("poisoning mechanisms") || lower.contains("toxic dose")
                && (lower.contains("class") || lower.contains("course") || lower.contains("toxicology")) {
            return "toxicology"
        }
        // socialepidemiology — positioned BEFORE epidemiologicalmodeling and epidemiology so social
        // determinants of health, health disparities research, and social-structural analyses of
        // population health get a dedicated pool. "disease surveillance"/"outbreak investigation"
        // stay in epidemiology. "health inequities" without epi context stays in publicheath.
        if lower.contains("social epidemiology") || lower.contains("social determinants of health")
            || lower.contains("social determinants of disease")
            || lower.contains("sdoh") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("paper") || lower.contains("assignment") || lower.contains("research"))
            || lower.contains("health disparities research") || lower.contains("health disparity research")
            || lower.contains("health disparities class") || lower.contains("health disparities course")
            || lower.contains("health disparities exam") || lower.contains("health disparities paper")
            || lower.contains("health inequities class") || lower.contains("health inequities course")
            || lower.contains("health inequalities class") || lower.contains("health inequalities course")
            || lower.contains("social gradient of health") || lower.contains("social gradient health")
            || lower.contains("socioeconomic determinants") && (lower.contains("health") || lower.contains("class") || lower.contains("course") || lower.contains("paper"))
            || lower.contains("social epidemiology class") || lower.contains("social epidemiology course")
            || lower.contains("social epidemiology exam") || lower.contains("social epidemiology paper")
            || lower.contains("life course epidemiology") || lower.contains("life-course epidemiology")
            || lower.contains("neighborhood effects on health") || lower.contains("structural determinants")
                && (lower.contains("health") || lower.contains("disease") || lower.contains("class") || lower.contains("course")) {
            return "socialepidemiology"
        }
        // epidemiologicalmodeling — positioned BEFORE epidemiology so mathematical/computational
        // epidemic modeling, SIR/SEIR compartmental models, and disease transmission dynamics
        // coursework get a dedicated pool. General epidemiology tasks stay in the branch below.
        if lower.contains("sir model") || lower.contains("seir model") || lower.contains("sis model")
            || lower.contains("seird model") || lower.contains("sird model")
            || lower.contains("compartmental model") && (lower.contains("disease") || lower.contains("epidemic") || lower.contains("infect") || lower.contains("class") || lower.contains("course"))
            || lower.contains("disease modeling") || lower.contains("epidemic modeling")
            || lower.contains("epidemiological model") || lower.contains("epidemiological modeling")
            || lower.contains("infectious disease model") || lower.contains("disease transmission model")
            || lower.contains("mathematical epidemiology") || lower.contains("computational epidemiology")
            || lower.contains("disease transmission dynamics") || lower.contains("epidemic dynamics class")
            || lower.contains("reproductive number") && (lower.contains("model") || lower.contains("disease") || lower.contains("epi") || lower.contains("class") || lower.contains("course"))
            || lower.contains("basic reproduction number") || lower.contains("effective reproduction number")
            || lower.contains("agent-based model") && (lower.contains("disease") || lower.contains("epidemic") || lower.contains("infect") || lower.contains("epi"))
            || lower.contains("network epidemiology") || lower.contains("pandemic modeling")
            || lower.contains("stochastic epidemic") || lower.contains("stochastic disease model")
            || lower.contains("transmission rate") && (lower.contains("model") || lower.contains("epi") || lower.contains("disease") || lower.contains("class"))
            || lower.contains("disease dynamics class") || lower.contains("disease dynamics course") {
            return "epidemiologicalmodeling"
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
        // communityhealth — positioned BEFORE publicheath so CHW certification, CHES exam,
        // and community health educator programs get a dedicated pool rather than the broad
        // MPH/epidemiology publicheath pool. "community health" alone stays in publicheath.
        if lower.contains("community health worker") || lower.contains("community health workers")
            || word("chw") && (lower.contains("certification") || lower.contains("exam") || lower.contains("program") || lower.contains("class") || lower.contains("training"))
            || lower.contains("chw certification") || lower.contains("chw exam") || lower.contains("chw program")
            || lower.contains("chw training") || lower.contains("chw class")
            || word("ches") && (lower.contains("exam") || lower.contains("certification") || lower.contains("health education"))
            || lower.contains("ches exam") || lower.contains("ches certification")
            || lower.contains("community health educator") || lower.contains("community health education")
            || lower.contains("health educator certification") || lower.contains("certified health education specialist")
            || lower.contains("community health outreach") || lower.contains("health outreach program")
            || lower.contains("lay health worker") || lower.contains("promotora")
            || lower.contains("community health advocate") || lower.contains("patient navigator") {
            return "communityhealth"
        }
        // healthequity — positioned BEFORE publicheath so course/program/research-specific health equity
        // and disparities terms get a dedicated pool. Bare "health equity" or "health disparities" alone
        // stay in publicheath (fires after this). Requires educational context for compound terms.
        if lower.contains("health equity class") || lower.contains("health equity course")
            || lower.contains("health equity program") || lower.contains("health equity research")
            || lower.contains("health equity certificate") || lower.contains("health equity curriculum")
            || lower.contains("health equity assignment") || lower.contains("health equity seminar")
            || lower.contains("health equity concentration") || lower.contains("health equity training")
            || lower.contains("health disparities class") || lower.contains("health disparities course")
            || lower.contains("health disparities research") || lower.contains("health disparities paper")
            || lower.contains("health disparities assignment") || lower.contains("health disparities seminar")
            || lower.contains("health disparities program")
            || lower.contains("social determinants of health class") || lower.contains("social determinants of health course")
            || lower.contains("social determinants of health assignment") || lower.contains("social determinants of health research")
            || lower.contains("sdoh class") || lower.contains("sdoh course") || lower.contains("sdoh research") || lower.contains("sdoh framework")
            || lower.contains("structural racism") && (lower.contains("health") || lower.contains("medicine") || lower.contains("healthcare"))
            || lower.contains("racial health disparities") || lower.contains("ethnic health disparities")
            || lower.contains("health equity and social justice") || lower.contains("social justice and health")
            || lower.contains("health inequity") && (lower.contains("class") || lower.contains("course") || lower.contains("research") || lower.contains("paper") || lower.contains("assignment"))
            || lower.contains("minority health class") || lower.contains("minority health course")
            || lower.contains("minority health research") || lower.contains("minority health program")
            || lower.contains("health justice") && (lower.contains("class") || lower.contains("course") || lower.contains("program") || lower.contains("research") || lower.contains("paper"))
            || lower.contains("dei in medicine") || lower.contains("dei in healthcare") || lower.contains("dei in health")
            || lower.contains("implicit bias in healthcare") || lower.contains("implicit bias in medicine")
            || lower.contains("disparate health outcomes") && (lower.contains("class") || lower.contains("research") || lower.contains("paper") || lower.contains("analysis")) {
            return "healthequity"
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
        // cognitivescience — positioned BEFORE neuroscience so cognitive science/cogsci
        // interdisciplinary programs (mind, brain, computation, language) get a dedicated pool.
        // "cognitive neuroscience" now owned by cognitiveneuroscience (fires between this and neuroscience).
        // Bare "cognitive" alone NOT matched.
        if lower.contains("cognitive science") || word("cogsci")
            || lower.contains("cognitive systems") || lower.contains("cognitive science class")
            || lower.contains("cognitive science course") || lower.contains("cognitive science exam")
            || lower.contains("cognitive science program") || lower.contains("cognitive science major")
            || lower.contains("cognitive science degree") || lower.contains("cognitive science assignment")
            || lower.contains("cognitive science paper") || lower.contains("cognitive science research")
            || lower.contains("cogsci class") || lower.contains("cogsci course") || lower.contains("cogsci exam")
            || lower.contains("cogsci major") || lower.contains("cogsci program")
            || lower.contains("mind and brain") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("language and cognition") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("human cognition") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("study"))
            || lower.contains("cognitive modeling") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("cognitive architecture class") || lower.contains("cognitive architecture course")
            || lower.contains("philosophy of mind") && (lower.contains("cogsci") || lower.contains("cognitive science"))
            || lower.contains("computational mind") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")) {
            return "cognitivescience"
        }
        // electrophysiology — positioned BEFORE cognitiveneuroscience so patch clamp, action
        // potential recording, and MEA data analysis route here. Bare "action potential" stays
        // in neuroscience; compound recording/patch terms fire here first.
        if lower.contains("patch clamp") || lower.contains("patch-clamp") || lower.contains("whole-cell patch")
            || lower.contains("whole cell patch") || lower.contains("perforated patch")
            || lower.contains("voltage clamp") && (lower.contains("class") || lower.contains("lab") || lower.contains("recording") || lower.contains("electrophysiology"))
            || lower.contains("current clamp") && (lower.contains("class") || lower.contains("lab") || lower.contains("recording") || lower.contains("electrophysiology"))
            || lower.contains("action potential recording") || lower.contains("action potential analysis") && (lower.contains("class") || lower.contains("lab"))
            || lower.contains("single unit recording") || lower.contains("single-unit recording")
            || lower.contains("local field potential") || lower.contains("field potential") && (lower.contains("recording") || lower.contains("electrophysiology") || lower.contains("class") || lower.contains("lab"))
            || lower.contains("extracellular recording") || lower.contains("intracellular recording")
            || lower.contains("multi-electrode array") || lower.contains("multielectrode array") || word("mea") && (lower.contains("recording") || lower.contains("electrophysiology") || lower.contains("neuron") || lower.contains("cell"))
            || lower.contains("spike sorting") || lower.contains("spike train") && (lower.contains("class") || lower.contains("lab") || lower.contains("analysis") || lower.contains("electrophysiology"))
            || lower.contains("in vivo recording") || lower.contains("in-vivo recording") || lower.contains("in vitro electrophysiology") || lower.contains("in vivo electrophysiology")
            || lower.contains("sharp electrode") && (lower.contains("class") || lower.contains("lab") || lower.contains("recording"))
            || lower.contains("neuron firing") && (lower.contains("class") || lower.contains("lab") || lower.contains("recording") || lower.contains("electrophysiology"))
            || lower.contains("electrophysiology class") || lower.contains("electrophysiology course")
            || lower.contains("electrophysiology lab") || lower.contains("electrophysiology exam")
            || lower.contains("electrophysiology research") || lower.contains("electrophysiology recording")
            || lower.contains("electrophysiological") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("research") || lower.contains("recording")) {
            return "electrophysiology"
        }
        // neuroimaging — positioned BEFORE cognitiveneuroscience to intercept specific
        // neuroimaging-software and pipeline signals (SPM, FSL, FreeSurfer, nilearn, nipype,
        // tractography, connectome). Broad fMRI/BOLD/VBM signals remain in cognitiveneuroscience.
        if lower.contains("neuroimaging class") || lower.contains("neuroimaging course")
            || lower.contains("neuroimaging lab") || lower.contains("neuroimaging exam")
            || lower.contains("neuroimaging homework") || lower.contains("neuroimaging assignment")
            || lower.contains("fmri class") || lower.contains("fmri course") || lower.contains("fmri lab")
            || lower.contains("fmri analysis") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("homework"))
            || lower.contains("spm") && (lower.contains("brain") || lower.contains("imaging") || lower.contains("neuroimaging") || lower.contains("fmri") || lower.contains("statistical parametric"))
            || lower.contains("fsl") && (lower.contains("brain") || lower.contains("imaging") || lower.contains("neuroimaging") || lower.contains("fmri") || lower.contains("dti") || lower.contains("fmrib"))
            || lower.contains("freesurfer") && (lower.contains("brain") || lower.contains("cortex") || lower.contains("segmentation") || lower.contains("parcellation") || lower.contains("neuroimaging"))
            || lower.contains("nilearn") || lower.contains("nipype")
            || lower.contains("afni") && (lower.contains("brain") || lower.contains("fmri") || lower.contains("imaging") || lower.contains("analysis"))
            || lower.contains("tractography") && (lower.contains("brain") || lower.contains("white matter") || lower.contains("fiber") || lower.contains("dti") || lower.contains("class") || lower.contains("research") || lower.contains("analysis"))
            || lower.contains("connectome") && (lower.contains("brain") || lower.contains("network") || lower.contains("analysis") || lower.contains("class") || lower.contains("research") || lower.contains("mapping"))
            || lower.contains("mri preprocessing") || lower.contains("fmri preprocessing")
            || lower.contains("brain parcellation") || lower.contains("cortical parcellation")
            || lower.contains("roi analysis") && (lower.contains("brain") || lower.contains("fmri") || lower.contains("neuroimaging") || lower.contains("imaging"))
            || lower.contains("atlas registration") && (lower.contains("brain") || lower.contains("neuroimaging") || lower.contains("mri"))
            || lower.contains("structural mri") && (lower.contains("class") || lower.contains("research") || lower.contains("analysis") || lower.contains("neuroimaging"))
            || lower.contains("diffusion weighted imaging") || lower.contains("dwi analysis") && (lower.contains("brain") || lower.contains("white matter")) {
            return "neuroimaging"
        }
        // cognitiveneuroscience — positioned BEFORE neuroscience so fMRI/EEG study design, BOLD
        // signal analysis, and neuroimaging coursework get a dedicated pool. "cognitive neuroscience"
        // removed from neuroscience branch below. Bare "neuroscience" stays in neuroscience.
        if lower.contains("cognitive neuroscience") || lower.contains("cognitive neuroscientist")
            || lower.contains("fmri") || lower.contains("bold signal") || lower.contains("bold response")
            || lower.contains("eeg study") || lower.contains("eeg research") || lower.contains("eeg analysis")
            || lower.contains("erp study") || lower.contains("erp research") || lower.contains("erp analysis")
            || lower.contains("event-related potential") || lower.contains("event related potential")
            || lower.contains("neuroimaging analysis") || lower.contains("neuroimaging study")
            || lower.contains("neuroimaging research") || lower.contains("neuroimaging data")
            || lower.contains("brain imaging") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("research") || lower.contains("lab") || lower.contains("analysis"))
            || lower.contains("voxel-based morphometry") || lower.contains("vbm analysis")
            || lower.contains("resting state fmri") || lower.contains("task-based fmri")
            || lower.contains("functional connectivity") && (lower.contains("class") || lower.contains("research") || lower.contains("fmri") || lower.contains("brain") || lower.contains("analysis"))
            || lower.contains("diffusion tensor imaging") || word("dti") && (lower.contains("brain") || lower.contains("white matter") || lower.contains("neuroimaging") || lower.contains("class") || lower.contains("research"))
            || lower.contains("cognitive neuroscience class") || lower.contains("cognitive neuroscience course")
            || lower.contains("cognitive neuroscience exam") || lower.contains("cognitive neuroscience paper")
            || lower.contains("cognitive neuroscience research") || lower.contains("cognitive neuroscience major")
            || lower.contains("affective neuroscience") || lower.contains("social neuroscience")
            || lower.contains("developmental neuroscience") && (lower.contains("class") || lower.contains("course") || lower.contains("research") || lower.contains("exam")) {
            return "cognitiveneuroscience"
        }
        // neuroscience — positioned BEFORE psychology so brain/neuron-biology terms get a
        // dedicated pool. "neural network" (ML) stays in datascience (fires much earlier).
        // "cognitive neuroscience" now owned by cognitiveneuroscience branch above.
        if word("neuroscience") || word("neuroscientist") || word("neurobiology") || word("neurobiologist")
            || word("neuroanatomy") || word("neuropathology") || word("neuropharmacology")
            || lower.contains("behavioral neuroscience")
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
        // psychopharmacology — positioned AFTER neuroscience (which catches neuroimaging/synaptic
        // terms) and BEFORE clinicalpsychology. Catches psychopharmacology class/exam and
        // neuropsychopharmacology coursework. "pharmacology" alone stays in pharmacy.
        // "psychiatric medication" in a clinical context stays in clinicalpsychology/therapy.
        if word("psychopharmacology") || word("neuropsychopharmacology")
            || lower.contains("psychopharmacology class") || lower.contains("psychopharmacology course")
            || lower.contains("psychopharmacology exam") || lower.contains("psychopharmacology paper")
            || lower.contains("psychopharmacology assignment") || lower.contains("psychopharmacology major")
            || lower.contains("psychopharmacology program") || lower.contains("psychopharmacology textbook")
            || lower.contains("psychopharmacology lab") || lower.contains("psychopharmacology homework")
            || lower.contains("neuropsychopharmacology class") || lower.contains("neuropsychopharmacology course")
            || lower.contains("neuropsychopharmacology exam") || lower.contains("neuropsychopharmacology paper")
            || lower.contains("pharmacology of mental disorders") || lower.contains("pharmacology of psychiatric")
            || lower.contains("pharmacology of mood disorders") || lower.contains("pharmacology of anxiety")
            || lower.contains("psychiatric pharmacology class") || lower.contains("psychiatric pharmacology course")
            || lower.contains("psychiatric pharmacology exam") || lower.contains("psychiatric drugs class")
            || lower.contains("psychiatric drugs course") || lower.contains("psychiatric drugs exam")
            || lower.contains("drug action in the brain") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("antidepressant mechanism") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("paper"))
            || lower.contains("antipsychotic pharmacology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("psychotropic medication") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("paper"))
            || lower.contains("medication mechanism") && (lower.contains("psych") || lower.contains("psychiatry") || lower.contains("mental health")) && (lower.contains("class") || lower.contains("course")) {
            return "psychopharmacology"
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
        // iopsychology — positioned AFTER clinicalpsychology and BEFORE psychology so
        // industrial-organizational psychology programs, personnel psychology coursework, and
        // SIOP-context papers route to a dedicated pool. Generic "psychology" and "applied
        // psychology" remain in the psychology branch below.
        if lower.contains("industrial-organizational") || lower.contains("industrial organizational")
            || lower.contains("i/o psychology") || lower.contains("io psychology")
            || lower.contains("i-o psychology")
            || lower.contains("personnel psychology") || lower.contains("work psychology")
            || lower.contains("organizational psychology class") || lower.contains("organizational psychology course")
            || lower.contains("organizational psychology exam") || lower.contains("organizational psychology program")
            || lower.contains("organizational psychology major") || lower.contains("organizational psychology degree")
            || (word("siop") && (lower.contains("class") || lower.contains("research") || lower.contains("conference") || lower.contains("paper") || lower.contains("study")))
            || lower.contains("io psych") || lower.contains("i-o psych")
            || (lower.contains("occupational health psychology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")))
            || lower.contains("selection and assessment class") || lower.contains("personnel selection class")
            || lower.contains("job analysis class") || lower.contains("job analysis assignment")
            || lower.contains("performance appraisal class") || lower.contains("performance appraisal course")
            || lower.contains("motivation at work class") || lower.contains("work motivation class") {
            return "iopsychology"
        }
        // positivepsychology — positioned BEFORE psychology so "positive psychology" class/course
        // terms get a dedicated pool instead of falling into the generic psychology branch.
        // "positive psychology" is still listed in psychology as a fallback for bare mentions,
        // but explicit class/program/research terms route here.
        if lower.contains("positive psychology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("program") || lower.contains("research") || lower.contains("paper") || lower.contains("thesis") || lower.contains("major") || lower.contains("assignment"))
            || lower.contains("well-being science") || lower.contains("wellbeing science")
            || lower.contains("happiness science") || lower.contains("science of happiness")
            || lower.contains("mapp program") || lower.contains("master of applied positive psychology")
            || lower.contains("character strengths") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("assignment") || lower.contains("via"))
            || lower.contains("via strengths") || lower.contains("via survey") && lower.contains("psych")
            || lower.contains("perma model") || lower.contains("perma framework") && (lower.contains("class") || lower.contains("course") || lower.contains("psych"))
            || (word("seligman") && (lower.contains("class") || lower.contains("course") || lower.contains("psych") || lower.contains("paper") || lower.contains("book")))
            || lower.contains("flourishing theory") || lower.contains("theories of flourishing")
            || lower.contains("strengths-based") && (lower.contains("psych") || lower.contains("class") || lower.contains("counseling"))
            || lower.contains("strength-based approach") && (lower.contains("psych") || lower.contains("class") || lower.contains("counseling"))
            || lower.contains("resilience psychology") && (lower.contains("class") || lower.contains("course") || lower.contains("exam"))
            || lower.contains("grit theory") && (lower.contains("psych") || lower.contains("class") || lower.contains("paper"))
            || lower.contains("self-determination theory") && (lower.contains("psych") || lower.contains("class") || lower.contains("paper") || lower.contains("course")) {
            return "positivepsychology"
        }
        // cognitivepsychology — positioned BEFORE psychology so working memory, attention,
        // information processing, and cognitive load research route here with a specific pool.
        // "cognitive psychology" itself still routes to psychology (fires below) as a fallback
        // for bare mentions; explicit research/class terms with memory/attention context route here.
        if lower.contains("working memory") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("research") || lower.contains("paper") || lower.contains("lab"))
            || lower.contains("cognitive load theory") || lower.contains("cognitive load") && (lower.contains("class") || lower.contains("research") || lower.contains("paper") || lower.contains("exam") || lower.contains("assignment"))
            || lower.contains("attention and perception") || lower.contains("selective attention") && (lower.contains("class") || lower.contains("course") || lower.contains("research") || lower.contains("exam"))
            || lower.contains("information processing model") && (lower.contains("psych") || lower.contains("class") || lower.contains("cogniti"))
            || lower.contains("baddeley") && (lower.contains("model") || lower.contains("class") || lower.contains("memory") || lower.contains("working"))
            || lower.contains("attention research") && (lower.contains("psych") || lower.contains("cognitive") || lower.contains("class"))
            || lower.contains("cognitive processes") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("research"))
            || lower.contains("perceptual learning") && (lower.contains("class") || lower.contains("psych") || lower.contains("cognitive"))
            || lower.contains("memory research") && (lower.contains("psych") || lower.contains("cognitive") || lower.contains("class"))
            || lower.contains("cognitive aging") && (lower.contains("class") || lower.contains("course") || lower.contains("research") || lower.contains("psych"))
            || lower.contains("dual-process theory") && (lower.contains("psych") || lower.contains("cognitive") || lower.contains("class") || lower.contains("paper"))
            || lower.contains("dual process theory") && (lower.contains("psych") || lower.contains("cognitive") || lower.contains("class") || lower.contains("paper")) {
            return "cognitivepsychology"
        }
        // developmentalpsychology — positioned BEFORE psychology so child development, lifespan
        // development, Vygotsky, Erikson, and Kohlberg coursework route here. Bare "Piaget" and
        // "developmental psychology" without child/lifespan context still fall through to psychology.
        if lower.contains("child development") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("paper") || lower.contains("research") || lower.contains("milestone") || lower.contains("theory") || lower.contains("assignment"))
            || lower.contains("lifespan development") || lower.contains("life-span development")
            || lower.contains("infant development") || lower.contains("toddler development")
            || lower.contains("adolescent development") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("psych") || lower.contains("paper"))
            || lower.contains("vygotsky") && (lower.contains("class") || lower.contains("course") || lower.contains("psych") || lower.contains("paper") || lower.contains("development") || lower.contains("theory") || lower.contains("zpd") || lower.contains("scaffolding"))
            || lower.contains("zone of proximal development")
            || lower.contains("erikson") && (lower.contains("class") || lower.contains("course") || lower.contains("psych") || lower.contains("paper") || lower.contains("stage") || lower.contains("development") || lower.contains("identity"))
            || lower.contains("kohlberg") && (lower.contains("class") || lower.contains("course") || lower.contains("psych") || lower.contains("paper") || lower.contains("moral") || lower.contains("development"))
            || lower.contains("developmental milestone") || lower.contains("developmental milestones")
            || lower.contains("early childhood development") && (lower.contains("class") || lower.contains("course") || lower.contains("research") || lower.contains("program") || lower.contains("theory"))
            || lower.contains("developmental stages") && (lower.contains("class") || lower.contains("course") || lower.contains("psych") || lower.contains("paper") || lower.contains("exam")) {
            return "developmentalpsychology"
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
        // mortuaryscience — positioned BEFORE forensicscience so mortuary science school,
        // NBE exam prep, and funeral service education route here, not to forensic-science pools.
        if lower.contains("mortuary science") || lower.contains("mortuary school")
            || lower.contains("mortuary program") || lower.contains("mortuary class")
            || lower.contains("mortuary course") || lower.contains("mortuary exam")
            || lower.contains("mortuary student") || lower.contains("mortuary college")
            || lower.contains("mortuary degree") || lower.contains("mortuary education")
            || lower.contains("funeral service") && (lower.contains("program") || lower.contains("class") || lower.contains("school") || lower.contains("exam") || lower.contains("education") || lower.contains("student") || lower.contains("degree") || lower.contains("course"))
            || lower.contains("funeral director program") || lower.contains("funeral director school")
            || lower.contains("funeral director exam") || lower.contains("funeral director class")
            || word("nbe") && (lower.contains("mortuar") || lower.contains("funeral") || lower.contains("embalm"))
            || lower.contains("nbfe exam") || lower.contains("nbfe board")
            || word("abfse")
            || lower.contains("embalming class") || lower.contains("embalming course")
            || lower.contains("embalming lab") || lower.contains("embalming technique")
            || lower.contains("restorative art") && (lower.contains("mortuar") || lower.contains("funeral") || lower.contains("class") || lower.contains("course"))
            || lower.contains("thanatology class") || lower.contains("thanatology course")
            || lower.contains("thanatology program") || lower.contains("death studies class")
            || lower.contains("cremation technology") || lower.contains("cremation class") {
            return "mortuaryscience"
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
        // policeacademy — positioned BEFORE criminaljustice so POST certification, police academy,
        // and law-enforcement-officer training tasks get a dedicated pool. Generic "law enforcement"
        // and "policing" terms without academy context still fall through to criminaljustice.
        if lower.contains("police academy") || lower.contains("law enforcement academy")
            || lower.contains("police officer training") || lower.contains("police officer exam")
            || lower.contains("police officer certification") || lower.contains("police certification")
            || lower.contains("post certification") && (lower.contains("police") || lower.contains("officer") || lower.contains("law enforce") || lower.contains("peace officer"))
            || lower.contains("post exam") && (lower.contains("police") || lower.contains("officer") || lower.contains("law enforce"))
            || lower.contains("peace officer exam") || lower.contains("peace officer certification")
            || lower.contains("peace officer training") || lower.contains("peace officer standard")
            || lower.contains("basic law enforcement training") || lower.contains("blet exam") || word("blet") && lower.contains("law enforce")
            || lower.contains("police science class") || lower.contains("police science course") || lower.contains("police science exam")
            || lower.contains("police science program") || lower.contains("police science major")
            || lower.contains("law enforcement officer training") || lower.contains("leo certification")
            || lower.contains("field training officer") && (lower.contains("program") || lower.contains("class") || lower.contains("exam"))
            || lower.contains("police entrance exam") || lower.contains("police entrance test")
            || lower.contains("police oral board") || lower.contains("police written exam")
            || lower.contains("police department application") && lower.contains("exam") {
            return "policeacademy"
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
        // militaryscience — positioned BEFORE militarystudies so formal ROTC coursework, military
        // science department classes, and leadership-lab assignments route to a dedicated pool.
        // "military history", war studies, veterans studies, and ASVAB stay in militarystudies.
        if lower.contains("military science class") || lower.contains("military science course")
            || lower.contains("military science lab") || lower.contains("military science program")
            || lower.contains("military science exam") || lower.contains("military science notes")
            || lower.contains("rotc lab") || lower.contains("rotc leadership")
            || lower.contains("rotc program") && (lower.contains("class") || lower.contains("course") || lower.contains("lab") || lower.contains("train"))
            || lower.contains("leadership development lab") && (lower.contains("rotc") || lower.contains("military") || lower.contains("cadet"))
            || lower.contains("cadet training class") || lower.contains("cadet leadership class")
            || lower.contains("cadet program") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("lab") || lower.contains("train"))
            || lower.contains("army rotc class") || lower.contains("navy rotc class") || lower.contains("air force rotc class")
            || lower.contains("army rotc course") || lower.contains("navy rotc course") || lower.contains("air force rotc course")
            || lower.contains("military tactics class") || lower.contains("military tactics course")
            || lower.contains("military leadership class") && !lower.contains("studies") {
            return "militaryscience"
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
        // globalpoliticaleconomy — positioned AFTER internationalrelations and BEFORE socialscience.
        // Catches IPE coursework, comparative political economy, and global political economy.
        // Bare "political economy" without edu context stays in socialscience.
        if lower.contains("international political economy")
            || lower.contains("global political economy")
            || lower.contains("comparative political economy")
            || lower.contains("political economy of")
            || (word("ipe") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("program") || lower.contains("major") || lower.contains("paper") || lower.contains("thesis")))
            || lower.contains("ipe class") || lower.contains("ipe course") || lower.contains("ipe exam")
            || lower.contains("ipe program") || lower.contains("ipe major")
            || lower.contains("political economy class") || lower.contains("political economy course")
            || lower.contains("political economy exam") || lower.contains("political economy paper")
            || lower.contains("political economy program") || lower.contains("political economy major")
            || lower.contains("political economy thesis") || lower.contains("political economy research")
            || (lower.contains("world systems theory") && (lower.contains("class") || lower.contains("course") || lower.contains("paper") || lower.contains("exam")))
            || (lower.contains("dependency theory") && (lower.contains("class") || lower.contains("course") || lower.contains("paper") || lower.contains("exam")))
            || (lower.contains("global governance") && (lower.contains("political economy") || lower.contains("ipe"))) {
            return "globalpoliticaleconomy"
        }
        // geopolitics — positioned AFTER globalpoliticaleconomy and BEFORE socialscience.
        // Catches geopolitical analysis, risk assessment, and strategy tasks. Note: "geopolitics
        // class/course/exam" already fires internationalrelations above; this branch handles
        // standalone analytical/research contexts without requiring edu-context qualifiers.
        if lower.contains("geopolitical analysis") || lower.contains("geopolitical risk")
            || lower.contains("geopolitical strategy") || lower.contains("geopolitical competition")
            || lower.contains("geopolitical rivalry") || lower.contains("geopolitical landscape")
            || lower.contains("geopolitical forecast") || lower.contains("geopolitical assessment")
            || lower.contains("geopolitical tension") || lower.contains("geopolitical dynamics")
            || lower.contains("geopolitical power") || lower.contains("geopolitical implications")
            || lower.contains("geopolitical conflict") || lower.contains("geopolitics paper")
            || lower.contains("geopolitics assignment") || lower.contains("geopolitics thesis")
            || lower.contains("geopolitics research") || lower.contains("geopolitics essay") {
            return "geopolitics"
        }
        // anthropology — positioned BEFORE socialscience so cultural/physical/linguistic/biological
        // anthropology coursework gets a dedicated callout pool instead of the generic socialscience pool.
        // word("anthropology") is currently caught by socialscience — intercepting here first gives it
        // friend-like anthropology-specific messages.
        if word("anthropology") || word("anthropologist") || word("anthropological") || word("anthropologists")
            || lower.contains("cultural anthropology") || lower.contains("physical anthropology")
            || lower.contains("linguistic anthropology") || lower.contains("biological anthropology")
            || lower.contains("medical anthropology") || lower.contains("urban anthropology")
            || lower.contains("forensic anthropology") && !lower.contains("forensic science")
            || lower.contains("social anthropology") || lower.contains("applied anthropology")
            || lower.contains("archaeological fieldwork")
            || lower.contains("archaeology class") || lower.contains("archaeology course")
            || lower.contains("archaeology exam") || lower.contains("archaeology assignment")
            || lower.contains("ethnography") || lower.contains("ethnographic research")
            || lower.contains("participant observation") && (lower.contains("anthropology") || lower.contains("ethnography") || lower.contains("field") || lower.contains("class"))
            || lower.contains("kinship systems") && (lower.contains("anthropology") || lower.contains("class") || lower.contains("course"))
            || lower.contains("cross-cultural") && (lower.contains("class") || lower.contains("course") || lower.contains("anthropology") || lower.contains("study"))
            || lower.contains("paleoanthropology") || lower.contains("paleoanthropologist")
            || lower.contains("anthropology major") || lower.contains("anthropology program")
            || lower.contains("anthropology class") || lower.contains("anthropology course")
            || lower.contains("anthropology exam") || lower.contains("anthropology notes") {
            return "anthropology"
        }
        // sociology — positioned BEFORE socialscience so sociological theory, structural analysis,
        // and sociology coursework gets a dedicated callout pool. Bare word("sociology") routes to
        // studying (fires much earlier); compound sociology terms without bare study-words route here.
        if word("sociological") || word("sociologist") || word("sociologists")
            || lower.contains("sociological theory") || lower.contains("sociological analysis")
            || lower.contains("sociological perspective") || lower.contains("sociological framework")
            || lower.contains("symbolic interactionism") || lower.contains("structural functionalism")
            || lower.contains("conflict theory") && (lower.contains("class") || lower.contains("sociology") || lower.contains("course") || lower.contains("paper") || lower.contains("essay"))
            || lower.contains("social stratification") && (lower.contains("class") || lower.contains("course") || lower.contains("sociology") || lower.contains("paper"))
            || lower.contains("social inequality") && (lower.contains("class") || lower.contains("course") || lower.contains("sociology") || lower.contains("paper"))
            || lower.contains("sociology major") || lower.contains("sociology program")
            || lower.contains("sociology class") || lower.contains("sociology course")
            || lower.contains("sociology exam") || lower.contains("sociology assignment")
            || lower.contains("sociology notes") || lower.contains("sociology paper")
            || lower.contains("sociology of religion") || lower.contains("sociology of education")
            || lower.contains("sociology of the family") || lower.contains("urban sociology")
            || lower.contains("rural sociology") || lower.contains("race and ethnicity") && (lower.contains("sociology") || lower.contains("class") || lower.contains("course"))
            || lower.contains("gender and society") && (lower.contains("sociology") || lower.contains("class") || lower.contains("course"))
            || lower.contains("deviance and crime") && (lower.contains("class") || lower.contains("sociology") || lower.contains("course"))
            || lower.contains("social mobility") && (lower.contains("sociology") || lower.contains("class") || lower.contains("course")) {
            return "sociology"
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
        // philosophyofmind — positioned BEFORE philosophy so consciousness studies, qualia,
        // and phenomenology of mind tasks route here rather than the general philosophy pool.
        // "philosophy of mind" combined with "cogsci"/"cognitive science" fires cognitivescience above.
        // Guard: bare "theory of mind" in developmental psych (autism/ToM context) routes to psychology.
        if lower.contains("philosophy of mind")
            || lower.contains("consciousness studies") || lower.contains("study of consciousness")
            || word("qualia") || lower.contains("phenomenal consciousness")
            || lower.contains("hard problem of consciousness")
            || lower.contains("philosophy of consciousness")
            || lower.contains("mind-body problem") || lower.contains("mind body problem")
            || (word("phenomenology") && (lower.contains("philosophy") || lower.contains("phil of mind") || lower.contains("consciousness") || lower.contains("class")))
            || (word("functionalism") && (lower.contains("philosophy") || lower.contains("mind")))
            || (lower.contains("mental state") && lower.contains("philosophy"))
            || (word("intentionality") && lower.contains("philosophy"))
            || (word("physicalism") && lower.contains("philosophy"))
            || (word("dualism") && lower.contains("mind") && (lower.contains("philosophy") || lower.contains("class") || lower.contains("paper")))
            || (lower.contains("folk psychology") && (lower.contains("philosophy") || lower.contains("class")))
            || (lower.contains("zombie") && lower.contains("philosophy") && !lower.contains("game"))
            || (lower.contains("theory of mind") && lower.contains("philosophy")) {
            return "philosophyofmind"
        }
        // philosophy — positioned after socialscience (shared "political philosophy" territory)
        // and before legal so "ethics paper" and "philosophical argument" don't fall to legal.
        if word("philosophy") || word("philosophical") || word("philosopher")
            || word("kant") || word("plato") || word("socrates") || word("aristotle")
            || word("nietzsche") || word("descartes") || word("hume") || word("locke")
            || word("hegel") || word("hegelian")
            || word("metaphysics") || word("epistemology") || word("ontology")
            || lower.contains("moral philosophy") || lower.contains("political philosophy")
            || lower.contains("philosophy of science")
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
        // climatelaw — positioned AFTER environmentallaw (which owns NEPA/CERCLA/Clean-Air-Act/
        // "climate change law"/"climate litigation") so international climate treaty and carbon-market
        // legal coursework gets a dedicated pool. Focuses on Paris Agreement, carbon trading law,
        // emissions trading systems, and international climate finance that environmentallaw doesn't cover.
        if lower.contains("paris agreement") && (lower.contains("law") || lower.contains("class") || lower.contains("course") || lower.contains("legal") || lower.contains("compliance") || lower.contains("treaty") || lower.contains("analysis"))
            || lower.contains("paris accord") && (lower.contains("law") || lower.contains("class") || lower.contains("course") || lower.contains("legal"))
            || lower.contains("international climate law") || lower.contains("international climate agreement")
            || lower.contains("international climate treaty") && (lower.contains("class") || lower.contains("course") || lower.contains("law") || lower.contains("legal"))
            || lower.contains("carbon trading law") || lower.contains("carbon market law") || lower.contains("carbon market class") || lower.contains("carbon market regulation")
            || lower.contains("emissions trading law") || lower.contains("emissions trading scheme") && (lower.contains("law") || lower.contains("class") || lower.contains("course") || lower.contains("legal"))
            || lower.contains("eu ets") && (lower.contains("law") || lower.contains("class") || lower.contains("course") || lower.contains("legal") || lower.contains("regulation"))
            || lower.contains("cap and trade law") || lower.contains("cap-and-trade law") || lower.contains("cap and trade class")
            || lower.contains("carbon credits law") || lower.contains("carbon offset law") || lower.contains("carbon offset regulation")
            || lower.contains("climate finance law") || lower.contains("climate finance class") || lower.contains("climate finance regulation")
            || lower.contains("green bond law") || lower.contains("green bond regulation") && (lower.contains("class") || lower.contains("course") || lower.contains("legal"))
            || lower.contains("kyoto protocol law") || lower.contains("kyoto protocol class") || lower.contains("kyoto protocol legal")
            || lower.contains("unfccc") && (lower.contains("law") || lower.contains("class") || lower.contains("course") || lower.contains("legal") || lower.contains("treaty"))
            || lower.contains("climate treaty") && (lower.contains("law") || lower.contains("class") || lower.contains("legal") || lower.contains("analysis"))
            || lower.contains("net zero law") || lower.contains("net-zero law") || lower.contains("net zero regulation class")
            || lower.contains("climate disclosure law") || lower.contains("climate disclosure regulation") && (lower.contains("class") || lower.contains("course") || lower.contains("legal")) {
            return "climatelaw"
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
        // criminallaw — positioned AFTER laborlaw and BEFORE legal so criminal law class,
        // crim law exam, and Model Penal Code study route here. "criminal justice"/criminology
        // stays in criminaljustice (fires earlier). Bare "criminal" NOT matched alone.
        if lower.contains("criminal law class") || lower.contains("criminal law course")
            || lower.contains("criminal law exam") || lower.contains("criminal law paper")
            || lower.contains("criminal law assignment") || lower.contains("criminal law clinic")
            || lower.contains("criminal law professor") || lower.contains("crim law class")
            || lower.contains("crim law course") || lower.contains("crim law exam")
            || lower.contains("crim law paper") || lower.contains("crim law outline")
            || lower.contains("model penal code") || (word("mpc") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("law")))
            || lower.contains("mens rea") || lower.contains("actus reus")
            || lower.contains("homicide class") || lower.contains("homicide law") || lower.contains("homicide course")
            || lower.contains("murder law class") || lower.contains("criminal homicide")
            || (lower.contains("assault and battery") && (lower.contains("law class") || lower.contains("law course") || (lower.contains("class") && lower.contains("law"))))
            || (lower.contains("robbery and theft") && (lower.contains("law") || lower.contains("class")))
            || lower.contains("criminal defense class") || lower.contains("criminal defense course") || lower.contains("criminal defense analysis")
            || lower.contains("criminal prosecution class")
            || lower.contains("crime and punishment class")
            || lower.contains("substantive criminal law")
            || (lower.contains("criminal liability") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("law")))
            || lower.contains("criminal statutes class")
            || lower.contains("law school criminal law") || lower.contains("law school crim law") {
            return "criminallaw"
        }
        // civilprocedure — positioned AFTER criminallaw and BEFORE legal so civ pro class, FRCP
        // study, and civil procedure exam tasks route here. Bare "pleading"/"jurisdiction"/"discovery"
        // NOT matched alone — those stay in legal.
        if lower.contains("civil procedure class") || lower.contains("civil procedure course")
            || lower.contains("civil procedure exam") || lower.contains("civil procedure paper")
            || lower.contains("civil procedure assignment") || lower.contains("civil procedure clinic")
            || lower.contains("civ pro class") || lower.contains("civ pro course")
            || lower.contains("civ pro exam") || lower.contains("civ pro paper") || lower.contains("civ pro outline")
            || lower.contains("frcp class") || lower.contains("frcp course") || lower.contains("frcp exam")
            || lower.contains("federal rules of civil procedure")
            || lower.contains("personal jurisdiction class") || lower.contains("personal jurisdiction course")
            || lower.contains("subject matter jurisdiction class") || lower.contains("subject matter jurisdiction course")
            || (lower.contains("venue class") && lower.contains("civil")) || (lower.contains("venue") && lower.contains("civil procedure"))
            || lower.contains("service of process class") || lower.contains("service of process course")
            || lower.contains("pleading standards class") || lower.contains("pleading standards course")
            || lower.contains("summary judgment class") || (lower.contains("summary judgment") && lower.contains("civil procedure"))
            || (lower.contains("discovery class") && (lower.contains("civil procedure") || lower.contains("litigation class")))
            || lower.contains("class action class") || lower.contains("class action course")
            || (lower.contains("joinder class") && lower.contains("civil")) || (lower.contains("joinder") && lower.contains("civil procedure"))
            || lower.contains("erie doctrine class") || lower.contains("erie doctrine course")
            || lower.contains("res judicata class") || lower.contains("res judicata course")
            || lower.contains("preclusion doctrine class")
            || (lower.contains("motion practice class") && lower.contains("civil")) || (lower.contains("motion practice") && lower.contains("civil procedure"))
            || (lower.contains("12(b)(6)") && (lower.contains("class") || lower.contains("exam") || lower.contains("motion")))
            || lower.contains("federal civil procedure")
            || (lower.contains("standing") && lower.contains("civil procedure class")) {
            return "civilprocedure"
        }
        // constitutionallaw — positioned AFTER civilprocedure and BEFORE legal so con law class,
        // First Amendment analysis, and constitutional law exam tasks route here. Bare
        // "constitutional"/"constitution" NOT matched alone.
        if lower.contains("constitutional law class") || lower.contains("constitutional law course")
            || lower.contains("constitutional law exam") || lower.contains("constitutional law paper")
            || lower.contains("constitutional law assignment") || lower.contains("constitutional law clinic")
            || lower.contains("con law class") || lower.contains("con law course")
            || lower.contains("con law exam") || lower.contains("con law paper") || lower.contains("con law outline")
            || lower.contains("conlaw class") || lower.contains("conlaw exam")
            || lower.contains("first amendment class") || lower.contains("first amendment course") || (lower.contains("first amendment analysis") && lower.contains("law"))
            || lower.contains("fourth amendment class") || lower.contains("fourth amendment course") || (lower.contains("fourth amendment analysis") && lower.contains("law"))
            || lower.contains("fourteenth amendment class") || lower.contains("fourteenth amendment course")
            || lower.contains("due process clause class") || lower.contains("due process clause course") || lower.contains("due process clause analysis")
            || lower.contains("equal protection class") || lower.contains("equal protection clause class") || (lower.contains("equal protection analysis") && lower.contains("law"))
            || lower.contains("judicial review class") || lower.contains("judicial review course")
            || (lower.contains("constitutional analysis") && lower.contains("class")) || (lower.contains("constitutional analysis") && lower.contains("law school"))
            || (lower.contains("federalism class") && lower.contains("law")) || (lower.contains("federalism course") && lower.contains("law"))
            || lower.contains("commerce clause class") || lower.contains("commerce clause course")
            || lower.contains("bill of rights class") || lower.contains("bill of rights course")
            || lower.contains("constitutional interpretation")
            || lower.contains("constitutional doctrine class") || lower.contains("constitutional doctrine course")
            || lower.contains("law school con law") || lower.contains("law school constitutional law")
            || lower.contains("constitutional amendment class") || lower.contains("constitutional amendment course") || lower.contains("constitutional amendment analysis") {
            return "constitutionallaw"
        }
        // evidencelaw — positioned AFTER constitutionallaw and BEFORE legal so evidence class,
        // FRE study, and hearsay analysis route here. Bare "evidence" NOT matched alone.
        // "crime scene evidence" stays in forensicscience (fires much earlier).
        if lower.contains("evidence law class") || lower.contains("evidence law course")
            || lower.contains("evidence law exam") || lower.contains("evidence law paper")
            || lower.contains("evidence law assignment") || lower.contains("evidence law clinic")
            || (lower.contains("evidence class") && (lower.contains("law school") || lower.contains("law exam") || lower.contains("legal")))
            || (lower.contains("evidence course") && (lower.contains("law school") || lower.contains("law exam") || lower.contains("legal")))
            || (lower.contains("evidence exam") && (lower.contains("law") || lower.contains("hearsay") || lower.contains("fre")))
            || lower.contains("fre class") || lower.contains("fre course") || lower.contains("fre exam")
            || lower.contains("federal rules of evidence")
            || lower.contains("hearsay rule class") || lower.contains("hearsay rule course") || lower.contains("hearsay rule analysis") || lower.contains("hearsay exception class") || lower.contains("hearsay exception course")
            || (lower.contains("hearsay") && (lower.contains("class") || lower.contains("course") || lower.contains("evidence law") || lower.contains("law school")))
            || (lower.contains("authentication") && (lower.contains("evidence") || lower.contains("law class") || (lower.contains("class") && lower.contains("law"))))
            || (lower.contains("chain of custody") && (lower.contains("law class") || lower.contains("evidence class") || lower.contains("evidence law")))
            || (lower.contains("expert witness") && (lower.contains("evidence") || lower.contains("law class") || (lower.contains("class") && lower.contains("law"))))
            || lower.contains("character evidence class") || lower.contains("character evidence course")
            || (lower.contains("privilege") && lower.contains("evidence class")) || (lower.contains("privilege") && lower.contains("evidence law"))
            || lower.contains("admissibility class") || (lower.contains("admissibility") && lower.contains("law class"))
            || (lower.contains("impeachment") && (lower.contains("evidence") || (lower.contains("witness") && lower.contains("class"))))
            || lower.contains("best evidence rule") || (lower.contains("original document rule") && lower.contains("class"))
            || (lower.contains("confrontation clause") && lower.contains("evidence"))
            || lower.contains("law of evidence") || lower.contains("evidence outline") {
            return "evidencelaw"
        }
        // tortlaw — positioned AFTER evidencelaw and BEFORE legal so torts class, negligence
        // analysis, and products liability study route here. Bare "torts"/"tort"/"negligence" NOT
        // matched without law/class/course/exam/assignment context.
        if lower.contains("tort law class") || lower.contains("tort law course")
            || lower.contains("tort law exam") || lower.contains("tort law paper")
            || lower.contains("tort law assignment") || lower.contains("tort law clinic")
            || lower.contains("torts class") || lower.contains("torts course")
            || lower.contains("torts exam") || lower.contains("torts paper") || lower.contains("torts assignment") || lower.contains("torts analysis") || lower.contains("torts outline")
            || lower.contains("law of torts")
            || lower.contains("negligence class") || lower.contains("negligence course") || (lower.contains("negligence analysis") && (lower.contains("law") || lower.contains("torts")))
            || lower.contains("products liability class") || lower.contains("products liability course") || lower.contains("products liability analysis")
            || lower.contains("intentional torts class") || lower.contains("intentional torts course") || lower.contains("intentional torts analysis")
            || (lower.contains("strict liability") && (lower.contains("torts") || (lower.contains("class") && lower.contains("law"))))
            || (lower.contains("proximate cause") && (lower.contains("torts") || (lower.contains("class") && lower.contains("law"))))
            || (lower.contains("duty of care") && (lower.contains("torts") || (lower.contains("class") && lower.contains("law"))))
            || (lower.contains("breach of duty") && (lower.contains("torts") || (lower.contains("class") && lower.contains("law"))))
            || (lower.contains("palsgraf") && (lower.contains("class") || lower.contains("case") || lower.contains("law") || lower.contains("torts")))
            || lower.contains("learned hand formula") || (lower.contains("learned hand test") && lower.contains("torts"))
            || lower.contains("tort reform class") || lower.contains("tort reform course")
            || lower.contains("negligence per se class") || lower.contains("negligence per se course") || lower.contains("negligence per se law")
            || lower.contains("comparative negligence class") || lower.contains("comparative negligence course")
            || lower.contains("contributory negligence class") || lower.contains("contributory negligence course")
            || (lower.contains("assumption of risk") && (lower.contains("torts") || (lower.contains("class") && lower.contains("law"))))
            || (lower.contains("defamation") && (lower.contains("torts class") || lower.contains("torts course") || lower.contains("tort law")))
            || (lower.contains("nuisance") && (lower.contains("torts class") || lower.contains("torts course") || lower.contains("tort law")))
            || (lower.contains("respondeat superior") && (lower.contains("class") || lower.contains("law"))) {
            return "tortlaw"
        }
        // neurolaw — positioned AFTER tortlaw and BEFORE mediationarbitration. Catches the intersection
        // of law and neuroscience (brain imaging in court, adolescent culpability, criminal responsibility).
        // "forensicpsychology" owns EPPP/psychometric assessment; "criminaljustice" owns criminology.
        // Bare "neuroscience"/"brain" alone stay in neuroscience (fires much earlier).
        if lower.contains("neurolaw") || lower.contains("neuro-law")
            || lower.contains("law and neuroscience") || lower.contains("neuroscience and law")
            || lower.contains("neuroscience in court") || lower.contains("neuroscience in the courtroom")
            || lower.contains("brain imaging") && (lower.contains("law") || lower.contains("court") || lower.contains("legal") || lower.contains("evidence") || lower.contains("trial"))
            || lower.contains("fmri evidence") || lower.contains("fmri in court") || lower.contains("fmri legal")
            || lower.contains("brain-based lie detection") || lower.contains("brain fingerprinting")
            || lower.contains("criminal culpability") && (lower.contains("brain") || lower.contains("neuroscience") || lower.contains("neuro"))
            || lower.contains("criminal responsibility") && (lower.contains("brain") || lower.contains("neuroscience"))
            || lower.contains("adolescent brain") && (lower.contains("law") || lower.contains("criminal") || lower.contains("court") || lower.contains("sentencing") || lower.contains("culpability"))
            || lower.contains("juvenile culpability") && (lower.contains("brain") || lower.contains("neuroscience"))
            || lower.contains("insanity defense") && (lower.contains("neuroscience") || lower.contains("brain"))
            || lower.contains("diminished capacity") && (lower.contains("neuroscience") || lower.contains("brain"))
            || lower.contains("legal neuroscience") || lower.contains("cognitive neuroscience") && lower.contains("law")
            || lower.contains("neuroscience evidence") && (lower.contains("court") || lower.contains("trial") || lower.contains("legal") || lower.contains("class"))
            || lower.contains("neuroscience and criminal justice") && (lower.contains("class") || lower.contains("course") || lower.contains("paper") || lower.contains("research"))
            || lower.contains("neuroethics") && (lower.contains("law") || lower.contains("legal") || lower.contains("court")) {
            return "neurolaw"
        }
        // mediationarbitration — positioned AFTER tortlaw and BEFORE legal. Catches ADR/mediation/
        // arbitration as a study domain. "conflict resolution" alone stays generic;
        // "negotiation" alone stays in business/meeting.
        if lower.contains("alternative dispute resolution") || lower.contains("adr class")
            || lower.contains("adr course") || lower.contains("adr exam") || lower.contains("adr program")
            || lower.contains("adr certification") || lower.contains("adr training")
            || lower.contains("mediation class") || lower.contains("mediation course")
            || lower.contains("mediation exam") || lower.contains("mediation training")
            || lower.contains("mediation certification") || lower.contains("mediation program")
            || lower.contains("mediator certification") || lower.contains("mediator training")
            || lower.contains("mediator program") || lower.contains("mediator class")
            || lower.contains("arbitration class") || lower.contains("arbitration course")
            || lower.contains("arbitration exam") || lower.contains("arbitration law class")
            || lower.contains("arbitration law course") || lower.contains("arbitration training")
            || lower.contains("arbitration certification") || lower.contains("arbitration certification program")
            || lower.contains("dispute resolution class") || lower.contains("dispute resolution course")
            || lower.contains("dispute resolution program") || lower.contains("dispute resolution exam")
            || lower.contains("dispute resolution certification") || lower.contains("conflict resolution class")
            || lower.contains("conflict resolution course") || lower.contains("conflict resolution program")
            || lower.contains("conflict resolution exam") || lower.contains("conflict resolution cert")
            || lower.contains("negotiation class") && (lower.contains("adr") || lower.contains("mediation") || lower.contains("dispute") || lower.contains("law") || lower.contains("legal"))
            || lower.contains("mcle mediation") || lower.contains("mediation mcle")
            || lower.contains("family mediation class") || lower.contains("divorce mediation class")
            || lower.contains("jams arbitration class") || lower.contains("aaa arbitration class") {
            return "mediationarbitration"
        }
        // sportslaw — positioned AFTER mediationarbitration and BEFORE legal so sports-law class,
        // NCAA compliance, and athlete representation route here. "sports psychology" stays in
        // kinesiology; "sports analytics" stays in sportsanalytics; bare "sports" stays generic.
        if lower.contains("sports law") || lower.contains("sport law")
            || lower.contains("ncaa compliance") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("officer") || lower.contains("program"))
            || lower.contains("athlete contract") && (lower.contains("class") || lower.contains("course") || lower.contains("law") || lower.contains("legal"))
            || lower.contains("sports agent") && (lower.contains("class") || lower.contains("course") || lower.contains("law") || lower.contains("legal") || lower.contains("certification"))
            || lower.contains("sports management law") || lower.contains("sports management legal")
            || lower.contains("collective bargaining") && (lower.contains("sports") || lower.contains("athlete") || lower.contains("nba") || lower.contains("nfl") || lower.contains("mlb") || lower.contains("nhl"))
            || lower.contains("sports governance") && (lower.contains("law") || lower.contains("class") || lower.contains("course") || lower.contains("legal"))
            || lower.contains("athlete representation") && (lower.contains("law") || lower.contains("class") || lower.contains("course"))
            || lower.contains("sports liability") && (lower.contains("class") || lower.contains("course") || lower.contains("law"))
            || lower.contains("title ix") && (lower.contains("sports") || lower.contains("athletics") || lower.contains("class") || lower.contains("course") || lower.contains("law"))
            || lower.contains("professional sports law") || lower.contains("sports industry law")
            || lower.contains("esports law") && (lower.contains("class") || lower.contains("course") || lower.contains("exam")) {
            return "sportslaw"
        }
        // constructionlaw — positioned AFTER sportslaw, BEFORE legal.
        // Catches AIA contracts, mechanics liens, surety bonds, and construction dispute coursework.
        // "construction management" and "construction technology" both fire far earlier in the chain.
        if lower.contains("construction law")
            || lower.contains("construction contract law") || lower.contains("aia contract") || lower.contains("aia document")
            || lower.contains("surety bond") && (lower.contains("class") || lower.contains("course") || lower.contains("exam") || lower.contains("law") || lower.contains("construction"))
            || lower.contains("surety law") || lower.contains("surety bonding class")
            || lower.contains("mechanics lien") || lower.contains("mechanic's lien") || lower.contains("construction lien")
            || lower.contains("payment bond") && (lower.contains("construction") || lower.contains("class") || lower.contains("law"))
            || lower.contains("performance bond") && lower.contains("construction")
            || lower.contains("construction defect") || lower.contains("construction claim") && (lower.contains("law") || lower.contains("class") || lower.contains("legal") || lower.contains("analysis"))
            || lower.contains("construction dispute") || lower.contains("construction litigation")
            || lower.contains("construction delay claim") || lower.contains("subcontractor claims") && lower.contains("construction") {
            return "constructionlaw"
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
        // architecturaldesign — positioned BEFORE interiordesign and architecture so
        // portfolio/charrette/design-competition phrases route here instead of the
        // technical-drawing messages in the architecture branch.
        if lower.contains("architecture portfolio") || lower.contains("architectural portfolio")
            || lower.contains("design charrette") || lower.contains("design charette")
            || lower.contains("design-build") && (lower.contains("architecture") || lower.contains("studio") || lower.contains("project") || lower.contains("class"))
            || lower.contains("design build") && (lower.contains("architecture") || lower.contains("studio") || lower.contains("project") || lower.contains("class"))
            || lower.contains("architectural competition") || lower.contains("architecture competition")
            || lower.contains("building design competition")
            || lower.contains("schematic design") && !lower.contains("software") && !lower.contains("database") && !lower.contains("system")
            || lower.contains("design development") && (lower.contains("architect") || lower.contains("building") || lower.contains("studio"))
            || lower.contains("architectural concept") || lower.contains("design concept") && lower.contains("architect")
            || lower.contains("concept design") && lower.contains("architect")
            || lower.contains("architectural presentation") || lower.contains("architecture presentation")
            || lower.contains("architecture portfolio") || lower.contains("arch portfolio")
            || lower.contains("building typology") || lower.contains("building typologies")
            || lower.contains("program diagram") && (lower.contains("architect") || lower.contains("building") || lower.contains("studio"))
            || lower.contains("bubble diagram") && (lower.contains("architect") || lower.contains("studio") || lower.contains("building"))
            || lower.contains("parti diagram") || lower.contains("design parti")
            || lower.contains("massing model") || lower.contains("architectural massing")
            || lower.contains("section perspective") && (lower.contains("architect") || lower.contains("studio"))
            || lower.contains("architectural drawing set") || lower.contains("working drawing set") && lower.contains("architect") {
            return "architecturaldesign"
        }
        // historicpreservation — positioned BEFORE landscapearchitecture and architecture so
        // preservation-specific terms (HABS, NRHP, adaptive reuse) route here.
        if lower.contains("historic preservation") || lower.contains("historical preservation")
            || lower.contains("preservation architect") || lower.contains("preservation architecture")
            || lower.contains("adaptive reuse") || lower.contains("building rehabilitation") && lower.contains("histor")
            || lower.contains("building rehab") && lower.contains("histor")
            || lower.contains("habs documentation") || lower.contains("haer documentation") || word("habs") || word("haer")
            || lower.contains("national register of historic places") || lower.contains("nrhp")
            || lower.contains("secretary of the interior standards") || lower.contains("secretary of interior standards")
            || lower.contains("historic district") && (lower.contains("class") || lower.contains("course") || lower.contains("project") || lower.contains("exam") || lower.contains("study") || lower.contains("plan") || lower.contains("survey"))
            || lower.contains("historic structure report") || lower.contains("historic resources survey")
            || lower.contains("preservation planning") || lower.contains("heritage conservation")
            || lower.contains("heritage preservation") || lower.contains("built heritage")
            || lower.contains("preservation technology") || lower.contains("preservation program") && !lower.contains("software")
            || lower.contains("historic building") && (lower.contains("class") || lower.contains("course") || lower.contains("survey") || lower.contains("documentation") || lower.contains("analysis"))
            || lower.contains("preservation class") || lower.contains("preservation course") || lower.contains("preservation exam")
            || lower.contains("preservation school") || lower.contains("preservation degree")
            || lower.contains("building conservation") && !lower.contains("energy") {
            return "historicpreservation"
        }
        // sustainabledesign — positioned BEFORE architecture so LEED, passive house, and net-zero
        // design terms route here rather than to the generic architecture messages.
        if lower.contains("leed certification") || lower.contains("leed exam") || lower.contains("leed ap")
            || lower.contains("leed project") || lower.contains("leed credit") || lower.contains("leed rating")
            || lower.contains("leed class") || lower.contains("leed course") || lower.contains("leed study")
            || lower.contains("passive house") || lower.contains("passivhaus") || lower.contains("passive design") && !lower.contains("electronics") && !lower.contains("signal")
            || lower.contains("net-zero energy") || lower.contains("net zero energy") || lower.contains("net zero building") || lower.contains("net-zero building")
            || lower.contains("zero energy building") || lower.contains("zero-energy building")
            || lower.contains("biophilic design") || lower.contains("biophilic architecture")
            || lower.contains("living building challenge") || word("lbc") && lower.contains("building")
            || lower.contains("well certification") || lower.contains("well building") || lower.contains("well standard")
            || lower.contains("sustainable architecture") || lower.contains("green architecture")
            || lower.contains("sustainable building") || lower.contains("green building design")
            || lower.contains("sustainable design class") || lower.contains("sustainable design course") || lower.contains("sustainable design exam")
            || lower.contains("sustainable design project") || lower.contains("sustainable design studio")
            || lower.contains("energy modeling") && (lower.contains("architect") || lower.contains("building") || lower.contains("design") || lower.contains("class"))
            || lower.contains("daylighting analysis") || lower.contains("daylight analysis") && lower.contains("design")
            || lower.contains("embodied carbon") && (lower.contains("architect") || lower.contains("building") || lower.contains("design") || lower.contains("class"))
            || lower.contains("carbon neutral design") || lower.contains("carbon-neutral design")
            || lower.contains("green roof design") || lower.contains("living roof") && lower.contains("design")
            || lower.contains("solar design") && (lower.contains("architect") || lower.contains("building") || lower.contains("class"))
            || lower.contains("thermal performance") && (lower.contains("architect") || lower.contains("building") || lower.contains("class") || lower.contains("design")) {
            return "sustainabledesign"
        }
        // exhibitdesign — positioned BEFORE graphicdesign and architecture so exhibit/museum/trade
        // show design tasks route here instead of generic design messages.
        if lower.contains("exhibit design") || lower.contains("exhibition design")
            || lower.contains("museum exhibit") || lower.contains("museum design")
            || lower.contains("gallery design") || lower.contains("gallery installation")
            || lower.contains("trade show exhibit") || lower.contains("trade show design") || lower.contains("trade show booth")
            || lower.contains("display design") && !lower.contains("web") && !lower.contains("digital") && !lower.contains("ui") && !lower.contains("screen")
            || lower.contains("interpretive design") || lower.contains("interpretive exhibit")
            || lower.contains("exhibit installation") || lower.contains("exhibition installation")
            || lower.contains("visitor experience design")
            || lower.contains("museum curation") && lower.contains("design")
            || lower.contains("exhibit label") || lower.contains("exhibit copy") && lower.contains("design")
            || lower.contains("exhibition panel") || lower.contains("exhibition graphic")
            || lower.contains("pop-up exhibit") || lower.contains("pop up exhibit")
            || lower.contains("immersive exhibit") || lower.contains("interactive exhibit")
            || lower.contains("wayfinding design") || lower.contains("wayfinding signage")
            || lower.contains("environmental graphic") && (lower.contains("design") || lower.contains("class") || lower.contains("project"))
            || lower.contains("exhibit design class") || lower.contains("exhibit design course") || lower.contains("exhibit design program") {
            return "exhibitdesign"
        }
        // lightingdesign — positioned BEFORE architecture and interiordesign so lighting-specific
        // terms (NCQLP, luminaire, photometric) route here rather than to architecture messages.
        if lower.contains("lighting design") || lower.contains("architectural lighting")
            || lower.contains("theatrical lighting") || lower.contains("stage lighting")
            || word("ncqlp") || lower.contains("lighting certified")
            || lower.contains("well lighting") && lower.contains("design")
            || lower.contains("luminaire") || lower.contains("luminaires") || lower.contains("luminaire specification")
            || lower.contains("photometric analysis") || lower.contains("photometric calculation") || lower.contains("photometric plan")
            || lower.contains("daylighting design") || lower.contains("daylighting study") && lower.contains("design")
            || lower.contains("light fixture specification") || lower.contains("lighting specification")
            || lower.contains("ies lighting") || lower.contains("ies standard") && lower.contains("lighting")
            || lower.contains("lighting plan") && (lower.contains("design") || lower.contains("class") || lower.contains("project") || lower.contains("architect") || lower.contains("interior"))
            || lower.contains("lighting layout") && (lower.contains("design") || lower.contains("class") || lower.contains("project"))
            || lower.contains("lighting class") || lower.contains("lighting course") || lower.contains("lighting exam") || lower.contains("lighting program")
            || lower.contains("theatrical lighting design") || lower.contains("stage lighting design")
            || lower.contains("concert lighting") || lower.contains("event lighting design")
            || lower.contains("lighting simulation") || lower.contains("lighting software") && (lower.contains("design") || lower.contains("class"))
            || lower.contains("dimming system") && (lower.contains("design") || lower.contains("class") || lower.contains("lighting"))
            || lower.contains("color temperature") && (lower.contains("lighting") || lower.contains("design") || lower.contains("class"))
            || lower.contains("lighting level") && (lower.contains("design") || lower.contains("class") || lower.contains("space")) {
            return "lightingdesign"
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
