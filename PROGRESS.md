# Adia — Build Progress

## Run 1 — 2026-05-18

### Shipped
- **Task 1 complete: Xcode project scaffold**
- `Package.swift` — Swift 6 tools version, macOS 14+, three targets: `AdiApp` (executable), `AdiCore` (library), `AdiTests` (test)
- Full folder structure: `Sources/AdiApp/`, `Sources/AdiCore/{Models,AI,Blocking,Capture}/`, `Tests/AdiTests/`
- `AdiApp/AdiApp.swift` — `@main App` entry point, no dock icon via `.accessory` policy
- `AdiApp/AppDelegate.swift` — `NSApplicationDelegate` on `@MainActor`
- `AdiCore/Models/SessionState.swift` — `Session`, `SessionPhase`, `OnTaskStatus`, `VerificationResult` (all `Codable`, `Sendable`)
- `AdiCore/Models/ChatMessage.swift` — `ChatMessage` with role enum
- `AdiCore/AI/ClaudeClient.swift` — actor skeleton; reads `ANTHROPIC_API_KEY` from `ProcessInfo`
- `AdiCore/AI/OnTaskDetector.swift` — actor skeleton wired to `ClaudeClient`
- `AdiCore/Blocking/HostsFileManager.swift` — full parsing/stripping logic for `/etc/hosts` markers; write path needs root
- `AdiCore/Capture/ScreenCaptureManager.swift` — placeholder for `SCStream` wrapper
- `AdiCore/NotchWindowController.swift` — placeholder `NSWindowController`
- `AdiCore/SessionManager.swift` — `@MainActor ObservableObject` session lifecycle coordinator
- `Tests/AdiTests/SessionStateTests.swift` — Swift Testing `@Suite` covering `Session`, `ChatMessage`, `VerificationResult` Codable round-trips
- `Tests/AdiTests/HostsFileManagerTests.swift` — pure logic tests (no I/O) for blocked domain list

### Blocked
- None.

### Next agent should pick up
- **Task 2: Notch UI** — `NSPanel` subclass (`NotchPanel`) positioned in the notch area using `NSScreen` built-in camera notch rect APIs, collapsed state (small dot/indicator), expanded state (task name + criteria + elapsed + Done/Exit buttons). Replace the placeholder `NotchWindowController`.
