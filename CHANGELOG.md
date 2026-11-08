# Calendar Focus Sync

## 0.7.0

First release from the maintained fork.

- Direct-download builds are now signed with a Developer ID, notarized by Apple and stapled, so macOS Sequoia no longer blocks the DMG as malware (upstream issue #8)
- New GitHub Actions pipeline: CI builds and tests every change; pushing a `vX.Y.Z` tag produces the notarized DMG on GitHub Releases and uploads a Mac App Store build to App Store Connect
- Project updated for current Xcode: signing, version and bundle identifier moved to `Config/Shared.xcconfig`, `LaunchAtLogin-Modern` pinned to 1.1.0, privacy manifest added, stale user data removed from the repository
- Shortcuts are now invoked directly instead of through a shell, and the bundled shortcut is opened via the system workspace API
- Fixed a potential deadlock when scheduling focus timers from the main thread, and dead timers are no longer kept around after a re-sync
- Heads-up notifications are sent immediately (instead of never) when an event starts less than a minute from now

## 0.6

- Add support for filtering for events from specific calendars
- Fixes issue with triggering focus in MacOS 14.4
