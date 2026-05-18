import Foundation

public enum BlockingError: Error, LocalizedError, Sendable {
    case permissionDenied
    case readError(String)
    case writeError(String)

    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Permission denied. The app needs elevated privileges to modify /etc/hosts."
        case .readError(let msg): return "Read error: \(msg)"
        case .writeError(let msg): return "Write error: \(msg)"
        }
    }
}

public final class BlockingEngine: @unchecked Sendable {
    private let hostsPath: String
    private let markerStart = "# Adia Block Start"
    private let markerEnd = "# Adia Block End"

    public static let shared = BlockingEngine()

    public init(hostsPath: String = "/etc/hosts") {
        self.hostsPath = hostsPath
    }

    /// Replaces any existing Adia block section with entries for `domains`.
    public func block(domains: [String]) throws {
        var content = try readHosts()
        content = removeAdiaSection(from: content)

        let entries = domains.flatMap { domain -> [String] in
            let d = domain.lowercased().trimmingCharacters(in: .whitespaces)
            return ["127.0.0.1 \(d)", "127.0.0.1 www.\(d)"]
        }

        let section = "\n\(markerStart)\n" + entries.joined(separator: "\n") + "\n\(markerEnd)"
        content += section
        try writeHosts(content)
    }

    /// Removes the Adia block section, restoring /etc/hosts to its previous state.
    public func unblockAll() throws {
        let content = try readHosts()
        try writeHosts(removeAdiaSection(from: content))
    }

    /// Returns the currently blocked domains (without the www. prefix variant).
    public func blockedDomains() throws -> [String] {
        let content = try readHosts()
        return parseBlockedDomains(from: content)
    }

    // MARK: - Private

    private func readHosts() throws -> String {
        do {
            return try String(contentsOfFile: hostsPath, encoding: .utf8)
        } catch {
            throw BlockingError.readError(error.localizedDescription)
        }
    }

    private func writeHosts(_ content: String) throws {
        do {
            try content.write(toFile: hostsPath, atomically: true, encoding: .utf8)
        } catch let error as NSError {
            if error.code == NSFileWriteNoPermissionError {
                throw BlockingError.permissionDenied
            }
            throw BlockingError.writeError(error.localizedDescription)
        }
    }

    private func removeAdiaSection(from content: String) -> String {
        let lines = content.components(separatedBy: "\n")
        var result: [String] = []
        var inSection = false

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == markerStart {
                inSection = true
            } else if trimmed == markerEnd {
                inSection = false
            } else if !inSection {
                result.append(line)
            }
        }

        // Trim trailing blank lines added by our section
        while result.last?.trimmingCharacters(in: .whitespaces).isEmpty == true {
            result.removeLast()
        }

        return result.joined(separator: "\n")
    }

    private func parseBlockedDomains(from content: String) -> [String] {
        var domains: [String] = []
        var inSection = false

        for line in content.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == markerStart { inSection = true; continue }
            if trimmed == markerEnd { inSection = false; continue }
            guard inSection, trimmed.hasPrefix("127.0.0.1 ") else { continue }
            let domain = String(trimmed.dropFirst("127.0.0.1 ".count))
            // Skip the www. variant to avoid duplicates
            if !domain.hasPrefix("www.") {
                domains.append(domain)
            }
        }

        return domains
    }
}
