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

    /// Minimum seconds between callbacks for the same domain — prevents rapid-reload spam.
    internal static let notifyMinInterval: TimeInterval = 10.0

    /// Called on serverQueue when a blocked domain request arrives (rate-limited per domain).
    /// Set from @MainActor during session lifecycle; not concurrent with active page serving.
    var onBlockedDomainAccessed: (@Sendable (String) -> Void)? = nil

    // Rate-limit state — only accessed from serverQueue.
    private var lastNotifyDomain: String? = nil
    private var lastNotifyAt: Date? = nil

    private init() {}

    internal init(forTesting: ()) {}

    /// Starts the block server. `onBlockedDomainAccessed` is assigned before the listener
    /// begins accepting connections, eliminating the race window that existed when the
    /// callback was set separately by the caller after `start()` returned.
    public func start(
        blockedDomains: [String],
        taskDescription: String,
        sessionStartTime: Date? = nil,
        onBlockedDomainAccessed: (@Sendable (String) -> Void)? = nil
    ) {
        self.taskDescription = taskDescription
        stop()
        // Set callback before the listener starts so the first connection can never miss it.
        self.onBlockedDomainAccessed = onBlockedDomainAccessed

        // Capture both values as local constants so the connection handler closure
        // never reads self from a different thread (serverQueue vs. MainActor).
        let capturedTask = taskDescription
        let capturedStart = sessionStartTime

        // Try port 80 first (needs root), fall back to 8080.
        for port in [80, 8080] {
            guard let nwPort = NWEndpoint.Port(rawValue: UInt16(port)) else { continue }
            do {
                let params = NWParameters.tcp
                params.allowLocalEndpointReuse = true
                let l = try NWListener(using: params, on: nwPort)
                l.newConnectionHandler = { [weak self] conn in
                    self?.handle(conn, taskDescription: capturedTask, sessionStartTime: capturedStart)
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
        onBlockedDomainAccessed = nil
        lastNotifyDomain = nil
        lastNotifyAt = nil
    }

    // MARK: - Connection handling

    private func handle(_ connection: NWConnection, taskDescription: String, sessionStartTime: Date?) {
        connection.start(queue: serverQueue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 8192) { [weak self] data, _, _, _ in
            guard let self, let data else { connection.cancel(); return }
            let request = String(data: data, encoding: .utf8) ?? ""
            let host = self.extractHost(from: request)
            // Auto-expand the notch into reasoning mode when a blocked page is served.
            if let callback = self.onBlockedDomainAccessed,
               Self.shouldNotifyCallback(
                   forDomain: host,
                   lastDomain: self.lastNotifyDomain,
                   lastNotifiedAt: self.lastNotifyAt,
                   now: Date()
               ) {
                self.lastNotifyDomain = host
                self.lastNotifyAt = Date()
                callback(host)
            }
            let html = Self.blockedHTML(domain: host, taskDescription: taskDescription, sessionStartTime: sessionStartTime)
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

    /// Pure helper — true if the blocked-domain callback should fire for `domain` right now.
    /// Extracted as `internal static` so tests can verify rate-limiting without a live connection.
    internal static func shouldNotifyCallback(
        forDomain domain: String,
        lastDomain: String?,
        lastNotifiedAt: Date?,
        now: Date,
        minInterval: TimeInterval = LocalBlockServer.notifyMinInterval
    ) -> Bool {
        guard domain == lastDomain, let last = lastNotifiedAt else { return true }
        return now.timeIntervalSince(last) >= minInterval
    }

    internal static func htmlEscape(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }

    /// Formats `date` as an ISO 8601 UTC string suitable for `Date.parse()` in JavaScript.
    internal static func isoFormat(_ date: Date) -> String {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime]
        return fmt.string(from: date)
    }

    /// Returns a self-contained `<script>` block that reads the ISO timestamp `startISO`,
    /// computes elapsed time, and updates `#elapsed` every second.
    internal static func elapsedScriptTag(startISO: String) -> String {
        """
        <script>
        (function() {
          var start = Date.parse("\(startISO)");
          function tick() {
            var s = Math.floor((Date.now() - start) / 1000);
            var m = Math.floor(s / 60);
            var h = Math.floor(m / 60);
            var txt;
            if (h > 0) { txt = h + 'h ' + (m % 60) + 'm in'; }
            else if (m > 0) { txt = m + 'm in'; }
            else { txt = 'just started'; }
            var el = document.getElementById('elapsed');
            if (el) { el.textContent = txt; }
          }
          tick();
          setInterval(tick, 1000);
        })();
        </script>
        """
    }

    internal static func blockedHTML(domain: String, taskDescription: String, sessionStartTime: Date? = nil) -> String {
        let safeDomain = Self.htmlEscape(domain)
        let safeTask: String
        if taskDescription.isEmpty {
            safeTask = "you have work to do."
        } else {
            // Lowercase the first letter so "Write ENGL 101 essay" becomes
            // "you said you'd write ENGL 101 essay." not "...Write..."
            let lowered = taskDescription.prefix(1).lowercased() + taskDescription.dropFirst()
            safeTask = "you said you'd \(Self.htmlEscape(lowered))."
        }
        let elapsedScript = sessionStartTime.map { Self.elapsedScriptTag(startISO: Self.isoFormat($0)) } ?? ""
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
              margin-bottom: 8px;
            }
            .elapsed {
              font-size: 11px;
              color: rgba(255,255,255,0.18);
              letter-spacing: 0.08em;
              margin-bottom: 18px;
              min-height: 1em;
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
          <div class="elapsed" id="elapsed"></div>
          <h1>get back to work.</h1>
          <p>\(safeTask)</p>
          <div class="hint">adia is opening above — chat there to request access</div>
        \(elapsedScript)</body>
        </html>
        """
    }
}
