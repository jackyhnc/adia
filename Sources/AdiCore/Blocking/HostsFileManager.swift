import Foundation

// Manages /etc/hosts entries for domain blocking.
// Writing /etc/hosts requires root. In production, a privileged XPC helper
// (SMJobBless / SMAppService) performs the write; the main app sends it requests.
// For now the read path is always available; the write path is gated on success.
public actor HostsFileManager {
    public static let shared = HostsFileManager()

    private let hostsPath = "/etc/hosts"
    private let blockMarkerBegin = "# adia-block-begin"
    private let blockMarkerEnd   = "# adia-block-end"

    private init() {}

    // MARK: - Public API

    public func block(domains: [String]) async throws {
        var content = try readHosts()
        content = stripped(content)
        content += buildBlock(domains: domains)
        try writeHosts(content)
    }

    public func unblockAll() async throws {
        var content = try readHosts()
        content = stripped(content)
        try writeHosts(content)
    }

    public func currentlyBlocked() throws -> [String] {
        let content = try readHosts()
        return parseBlocked(content)
    }

    // MARK: - Private helpers

    private func readHosts() throws -> String {
        try String(contentsOfFile: hostsPath, encoding: .utf8)
    }

    private func writeHosts(_ content: String) throws {
        try content.write(toFile: hostsPath, atomically: true, encoding: .utf8)
    }

    private func stripped(_ content: String) -> String {
        // Walk lines, discarding everything between the adia markers (inclusive).
        let lines = content.components(separatedBy: "\n")
        var result: [String] = []
        var inBlock = false
        for line in lines {
            if line.hasPrefix(blockMarkerBegin) { inBlock = true; continue }
            if line.hasPrefix(blockMarkerEnd)   { inBlock = false; continue }
            if !inBlock { result.append(line) }
        }
        return result.joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines) + "\n"
    }

    private func buildBlock(domains: [String]) -> String {
        let lines = domains.flatMap { domain in
            ["127.0.0.1 \(domain)", "127.0.0.1 www.\(domain)"]
        }.joined(separator: "\n")
        return "\n\(blockMarkerBegin)\n\(lines)\n\(blockMarkerEnd)\n"
    }

    private func parseBlocked(_ content: String) -> [String] {
        guard let begin = content.range(of: blockMarkerBegin),
              let end   = content.range(of: blockMarkerEnd) else { return [] }
        let block = String(content[begin.upperBound..<end.lowerBound])
        return block.components(separatedBy: .newlines)
            .compactMap { line -> String? in
                let parts = line.split(separator: " ")
                guard parts.count == 2, parts[0] == "127.0.0.1" else { return nil }
                let domain = String(parts[1])
                return domain.hasPrefix("www.") ? nil : domain
            }
    }
}
