# User TODO — Items requiring your action

These cannot be automated. Handle before first run.

## Required for the app to work

### 1. ANTHROPIC_API_KEY
Set the environment variable before launching:
```
export ANTHROPIC_API_KEY=sk-ant-...
```
Or add it to the launch environment in Xcode's scheme editor.
Without it, Adia runs in stub mode (blocking still works, AI features disabled).

### 2. Screen Recording permission
Go to **System Settings → Privacy & Security → Screen Recording** and add Adia.
Without this, `ScreenCaptureKit` returns a permission error and detection is disabled.

### 3. /etc/hosts write permission
Adia writes to `/etc/hosts` to block domains. This requires admin privileges.
Option A (simplest): Run Adia with `sudo` during development.
Option B (production): Create a privileged helper tool using `SMJobBless` / `AuthorizationExecuteWithPrivileges`. Log this as a follow-up engineering task.

### 4. Xcode project / code signing
The Swift Package can be opened directly in Xcode 15+ by opening `Package.swift`.
To build a proper `.app` bundle for distribution:
- Create an Xcode project wrapping the package.
- Add `Info.plist` with `LSUIElement = YES` (hides Dock icon).
- Add entitlements: `com.apple.security.screen-recording`.
- Set up code signing with your Apple Developer account.

### 5. Local block server (port 80)
`/etc/hosts` redirects blocked domains to `127.0.0.1`, but without a server on port 80 the browser shows "connection refused" instead of the Adia blocked page.
To show the blocked page:
- Implement `LocalBlockServer.swift` using `NWListener` — but port 80 requires root.
- OR use a browser extension that intercepts the hosts redirect.
- OR accept "connection refused" as the block experience for v1.

## Not needed for v1

- Apple Developer account / notarization / App Store
- Domain registration or DNS
- Backend or analytics
- Paid services
