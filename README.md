<div align="center">
	<img src="Calendar Focus Sync/Assets.xcassets/AppIcon.appiconset/256x256@2x.png" width="200" height="200">
	<h1>Calendar Focus Sync</h1>
	<p>
		<b>Activate macOS Focus Modes when calendar events begin</b>
	</p>
	<p>
		<a href="https://github.com/OfryL/calendar-focus-sync/actions/workflows/ci.yml"><img src="https://github.com/OfryL/calendar-focus-sync/actions/workflows/ci.yml/badge.svg" alt="CI"></a>
		<a href="https://github.com/OfryL/calendar-focus-sync/releases/latest"><img src="https://img.shields.io/github/v/release/OfryL/calendar-focus-sync?display_name=tag" alt="Latest release"></a>
	</p>
	<br>
</div>

A macOS menu bar app that automatically turns on a Focus Mode when a calendar event begins, and turns it off again when the event ends. Useful for blocking out time for meetings, deep work, or anything else on your calendar.

This is a maintained fork of [a11rew/calendar-focus-sync](https://github.com/a11rew/calendar-focus-sync). Builds from this repository are signed with a Developer ID and notarized by Apple, so macOS no longer reports the download as damaged or as malware.

## Requirements

- macOS 14 (Sonoma) or later
- The bundled `calendar-focus-sync` Shortcut, which the app offers to install on first launch (macOS exposes Focus Modes to apps only through Shortcuts)

## Download

**Direct download (DMG)**

Grab the latest `Calendar-Focus-Sync-x.y.z.dmg` from [Releases](https://github.com/OfryL/calendar-focus-sync/releases/latest), open it and drag the app to Applications. The DMG and the app inside are signed and notarized.

**Mac App Store**

An App Store listing for this fork is in progress; the link will appear here once it is live.

## Features

### Sync With Native Calendar

Events in your calendar automatically activate Focus Mode. Changes to events are reflected immediately.

### Choose Which Calendars Count

Toggle individual calendars on or off so that, for example, only your work calendar triggers Focus.

### Time Before Event

Start Focus Mode 1, 2, 5 or 10 minutes before an event so you have time to prepare.

### Automatic Deactivation

When your event ends, Focus Mode is turned off again. No need to remember to turn it off.

### Heads-up Notification

Optionally get a notification a minute before Focus Mode is activated.

## Screenshots

![Menu Bar Item](<Calendar Focus Sync/Assets.xcassets/Screenshots/menu-bar.png>)

![Settings Screen](<Calendar Focus Sync/Assets.xcassets/Screenshots/promo-light.png>)

![Settings Screen In Dark Mode](<Calendar Focus Sync/Assets.xcassets/Screenshots/promo-dark.png>)

## Building from source

Open `Calendar Focus Sync.xcodeproj` in Xcode 16 or later. Signing and version settings live in [`Config/Shared.xcconfig`](Config/Shared.xcconfig); set `DEVELOPMENT_TEAM` to your team ID there (or pick a team in Signing & Capabilities) and run.

From the command line, an unsigned build and the unit tests can be run with:

```sh
xcodebuild test -project "Calendar Focus Sync.xcodeproj" -scheme "Calendar Focus Sync" \
  -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO
```

## Releasing

Releases are built by GitHub Actions: pushing a `vX.Y.Z` tag produces a notarized DMG on the GitHub Release and uploads a build to App Store Connect. See [RELEASING.md](RELEASING.md) for the one-time Apple setup and the required repository secrets.

## Privacy

Calendar Focus Sync reads your calendar locally and never sends any data anywhere. See the [privacy policy](PRIVACY_POLICY.md).

## License

Calendar Focus Sync is available under the MIT license. See the [LICENSE](LICENSE) file for more info. Originally created by [Andrew Glago](https://github.com/a11rew).
