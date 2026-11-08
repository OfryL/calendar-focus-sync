import AppKit
import SwiftUI

let SHORTCUT_NAME = "calendar-focus-sync"
let MISSING_SHORTCUT_MESSAGE = "Could not find Shortcut file. Your installation may be damaged. Reinstall Calendar Focus Sync"

/// Path of Apple's Shortcuts command line tool (ships with macOS 12+).
private let SHORTCUTS_CLI = "/usr/bin/shortcuts"

func getInstalledShortcuts() -> [String] {
    let shortcuts = runCommand(SHORTCUTS_CLI, ["list"])

    return shortcuts
        .components(separatedBy: "\n")
        .map { $0.trimmingCharacters(in: .whitespaces) }
        .filter { !$0.isEmpty }
}

func isShortcutInstalled() -> Bool {
    let installedShortcuts = getInstalledShortcuts()

    return installedShortcuts.contains(SHORTCUT_NAME)
}

/// Opens the bundled `.shortcut` file so the Shortcuts app offers to import it.
func installCFSShortcut() {
    guard let pathToShortcut = Bundle.main.url(forResource: SHORTCUT_NAME, withExtension: "shortcut") else {
        print(MISSING_SHORTCUT_MESSAGE) // TODO: Alert user
        return
    }

    NSWorkspace.shared.open(pathToShortcut)

    AppState.shared.isShortCutInstalled = true
}

/// Runs the bundled shortcut through the `shortcuts://` URL scheme.
///
/// Running shortcuts through the CLI from a sandboxed app fails with a
/// permissions error, so the URL scheme is used instead
/// (ref: https://github.com/feedback-assistant/reports/issues/468).
func runCFSShortcut(_ args: String) {
    guard isShortcutInstalled() else {
        print(MISSING_SHORTCUT_MESSAGE) // TODO: Alert user
        return
    }

    // shortcuts://run-shortcut?name=[name]&input=[input]&text=[text]
    var components = URLComponents()
    components.scheme = "shortcuts"
    components.host = "run-shortcut"
    components.queryItems = [
        URLQueryItem(name: "name", value: SHORTCUT_NAME),
        URLQueryItem(name: "input", value: args),
        URLQueryItem(name: "text", value: ""),
    ]

    guard let url = components.url else {
        print("Could not build shortcut URL for input: \(args)")
        return
    }

    NSWorkspace.shared.open(url)
}


func enableFocusMode(duration: Int, focusMode: String? = "Do Not Disturb") {
    runCFSShortcut(String(duration))
}

func deactivateFocusMode(focusMode: String? = "Do Not Disturb") {
    runCFSShortcut("off")
}
