import SwiftUI
import WebKit
import AdiCore

/// Shown in the notch panel when the user navigates to a blocked domain.
struct BlockedPageView: View {
    let domain: String
    @EnvironmentObject var appState: AppState
    @State private var showReasoning = false

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 40))
                .foregroundColor(.orange)

            Text("Blocked")
                .font(.system(size: 22, weight: .bold))

            Text(domain)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)

            if let session = appState.session {
                Text("You're working on: \(session.task.description)")
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }

            Button {
                showReasoning = true
            } label: {
                Text("I have a reason")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.accentColor)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showReasoning) {
            ReasoningConversationView()
                .environmentObject(appState)
        }
    }

    static func htmlPage(domain: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <title>Blocked — Adia</title>
          <style>
            body { font-family: -apple-system, sans-serif; display: flex; flex-direction: column;
                   align-items: center; justify-content: center; height: 100vh; margin: 0;
                   background: #1a1a1a; color: #eee; }
            h1 { font-size: 2rem; margin-bottom: 0.5rem; }
            .domain { color: #888; margin-bottom: 1rem; }
            .reason { font-size: 0.9rem; color: #aaa; max-width: 400px; text-align: center; }
          </style>
        </head>
        <body>
          <h1>Blocked</h1>
          <div class="domain">\(domain)</div>
          <p class="reason">Adia has blocked this site during your session.<br>Open the notch panel to make your case.</p>
        </body>
        </html>
        """
    }
}

struct BlockedWebView: NSViewRepresentable {
    let html: String

    func makeNSView(context: Context) -> WKWebView {
        WKWebView()
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(html, baseURL: nil)
    }
}
