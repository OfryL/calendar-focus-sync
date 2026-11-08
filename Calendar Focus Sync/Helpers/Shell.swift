import Foundation

/// Runs an executable with arguments and returns its combined stdout/stderr.
///
/// The executable is invoked directly (no shell), so arguments are never
/// re-parsed and the process cannot be influenced by the user's shell
/// configuration. Returns an empty string if the process cannot be started.
@discardableResult
func runCommand(_ executable: String, _ arguments: [String] = []) -> String {
    let process = Process()
    let pipe = Pipe()

    process.executableURL = URL(fileURLWithPath: executable)
    process.arguments = arguments
    process.standardOutput = pipe
    process.standardError = pipe
    process.standardInput = nil

    do {
        try process.run()
    } catch {
        print("Failed to run \(executable): \(error)")
        return ""
    }

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()

    return String(decoding: data, as: UTF8.self)
}
