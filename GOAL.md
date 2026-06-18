# Adia — Build Goals

- [x] Xcode project scaffold: Swift Package + targets (AdiApp, AdiCore, AdiTests), Package.swift, folder structure
- [x] Notch UI: NSPanel subclass positioned in notch area, collapsed state (minimal dot) + expanded state (task info + actions)
- [x] Session model: SessionState enum, task description, success criteria, start time, whitelist
- [x] Session creation view: SwiftUI form for task + criteria input, Go button
- [x] Screen capture pipeline: ScreenCaptureKit SCStream wrapper, emits CGImage every 1-2s
- [x] Claude API client: async/await wrapper for vision + chat completions, reads ANTHROPIC_API_KEY from ProcessInfo (claude-haiku-4-5 fast / claude-sonnet-4-6 strong)
- [x] On-task detection: send screen CGImage to claude-haiku-4-5, classify on-task/off-task/ambiguous with task context
- [x] Callout system: notch expansion triggered on off-task detection, friend-like direct message overlay
- [x] Blocking engine: read/write /etc/hosts to block domains, restore on session end, requires elevated perms
- [x] Blocked page: local NWListener HTTP server serves blocked page on port 80/8080
- [x] Reasoning conversation: SwiftUI chat UI for user to argue for site access; AI grants or denies with context memory
- [x] Task verification: send screen CGImage to claude-sonnet-4-6 with success criteria, returns verified/not-verified + explanation
- [x] Early exit conversation: AI engages user in conversation before confirming exit; user can always override
- [x] Session persistence: encode/decode SessionState to UserDefaults or local JSON file
- [x] Network loss resilience: NWPathMonitor + circuit breaker, offline UI indicators, graceful degradation when API calls fail
- [x] Whitelisted domains visibility: show AI-granted site access in active/paused session notch UI
- [x] Daily focus goal: configurable daily target with progress bar in idle notch + collapsed pill label
