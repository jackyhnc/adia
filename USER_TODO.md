# User Action Required

These items require manual action and cannot be automated by the build agent.

## API Keys
- **ANTHROPIC_API_KEY**: Set this environment variable before running Adia. The app reads it from `ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]`.

## Apple Developer Account
- Code signing, provisioning profiles, and notarization require an Apple Developer account ($99/yr).
- Until signed, run with `--disable-sandbox` or allow in System Settings > Privacy & Security.

## macOS Permissions (must grant on first launch)
- Screen Recording: required for ScreenCaptureKit (System Settings > Privacy & Security > Screen Recording)
- Accessibility: required for app monitoring via NSWorkspace
- `/etc/hosts` write access: the blocking engine needs `sudo` or a privileged helper. See `Sources/AdiCore/Blocking/HostsFileManager.swift` for the XPC helper plan.

## App Store
- Submission requires Apple Developer account + review process — out of scope for v1.
