import Foundation
import Network

/// Serves a "blocked by Adia" HTML page on 127.0.0.1.
/// Port 80 requires root (or an SMJobBless privileged helper in production).
/// In dev/demo, falls back to port 8080 — see USER_TODO.md.
public final class LocalBlockServer: @unchecked Sendable {
    public static let shared = LocalBlockServer()

    private var listener: NWListener?
    private let serverQueue = DispatchQueue(label: "adia.blockserver", qos: .utility)
    private var taskDescription: String = ""

    private init() {}

    internal init(forTesting: ()) {}

    public func start(blockedDomains: [String], taskDescription: String) {
        self.taskDescription = taskDescription
        stop()

        // Try port 80 first (needs root), fall back to 8080.
        for port in [80, 8080] {
            guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else { continue }
            do {
                let params = NWParameters.tcp
                params.allowLocalEndpointReuse = true
                let l = try NWListener(using: params, on: nwPort)
                l.newConnectionHandler = { [weak self] conn in
                    self?.handle(conn)
                }
                l.stateUpdateHandler = { state in
                    if case .failed(let err) = state {
                        print("[LocalBlockServer] port \(port) failed: \(err)")
                    }
                }
                l.start(queue: serverQueue)
                listener = l
                print("[LocalBlockServer] listening on port \(port)")
                return
            } catch {
                print("[LocalBlockServer] could not bind port \(port): \(error)")
            }
        }
    }

    public func stop() {
        listener?.cancel()
        listener = nil
    }

    // MARK: - Connection handling

    private func handle(_ connection: NWConnection) {
        connection.start(queue: serverQueue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, _, _ in
            guard let self, let data else { connection.cancel(); return }
            let request = String(data: data, encoding: .utf8) ?? ""
            let host = self.extractHost(from: request)
            let html = self.blockedHTML(domain: host)
            let body = html.data(using: .utf8) ?? Data()
            let header = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: \(body.count)\r\nConnection: close\r\n\r\n"
            var response = (header.data(using: .utf8) ?? Data())
            response.append(body)
            connection.send(content: response, completion: .contentProcessed { _ in connection.cancel() })
        }
    }

    private func extractHost(from request: String) -> String {
        for line in request.components(separatedBy: "\r\n") {
            let lower = line.lowercased()
            if lower.hasPrefix("host:") {
                return String(line.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            }
        }
        return "this site"
    }

    internal static func htmlEscape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    private func blockedHTML(domain: String) -> String {
        let safeDomain = Self.htmlEscape(domain)
        let safeTask = taskDescription.isEmpty
            ? "you have work to do."
            : "you said you'd \(Self.htmlEscape(taskDescription))."
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>blocked by adia</title>
          <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
              background: #0a0a0a;
              color: #fff;
              font-family: -apple-system, BlinkMacSystemFont, sans-serif;
              display: flex;
              flex-direction: column;
              align-items: center;
              justify-content: center;
              height: 100vh;
              text-align: center;
              gap: 0;
            }
            .domain {
              font-size: 11px;
              color: rgba(255,255,255,0.3);
              letter-spacing: 0.15em;
              text-transform: uppercase;
              margin-bottom: 14px;
            }
            h1 { font-size: 36px; font-weight: 700; margin-bottom: 10px; }
            p {
              color: rgba(255,255,255,0.45);
              font-size: 14px;
              margin-bottom: 36px;
            }
            .hint {
              font-size: 12px;
              color: rgba(255,255,255,0.2);
            }
          </style>
        </head>
        <body>
          <div class="domain">\(safeDomain)</div>
          <h1>get back to work.</h1>
          <p>\(safeTask)</p>
          <div class="hint">open adia from the notch to request access</div>
        </body>
        </html>
        """
    }
}
