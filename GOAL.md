# Adia — Build Goals

- [x] Xcode project scaffold: Swift Package + targets (AdiApp, AdiCore, AdiTests), Package.swift, folder structure
- [x] Notch UI: NSPanel subclass positioned in notch area, collapsed state (minimal dot) + expanded state (task info + actions)
- [x] Session model: SessionState enum, task description, success criteria, start time, whitelist
- [ ] Session creation view: SwiftUI form for task + criteria input, Go button
- [ ] Screen capture pipeline: ScreenCaptureKit SCStream wrapper, emits CGImage every 1-2s
- [ ] Claude API client: async/await wrapper for vision + chat completions, reads ANTHROPIC_API_KEY from ProcessInfo
- [ ] On-task detection: send screen CGImage to claude-haiku, classify on-task/off-task/ambiguous with task context
- [ ] Callout system: notch expansion triggered on off-task detection, friend-like direct message overlay
- [ ] Blocking engine: read/write /etc/hosts to block domains, restore on session end, requires elevated perms
- [ ] Blocked page: local WKWebView HTML page shown when user hits a blocked URL
- [ ] Reasoning conversation: SwiftUI chat UI for user to argue for site access; AI grants or denies with context memory
- [ ] Task verification: send screen CGImage to claude-sonnet-4-6 with success criteria, returns verified/not-verified + explanation
- [ ] Early exit conversation: AI engages user in conversation before confirming exit; user can always override
- [ ] Session persistence: encode/decode SessionState to UserDefaults or local JSON file
