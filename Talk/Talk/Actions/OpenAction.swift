import Foundation
import AppKit

@MainActor
class OpenAction: ActionHandler {
    static let shared = OpenAction()

    var supportedActions: [ActionType] { [.open] }

    func execute(intent: VoiceIntent, context: AppContext) async throws -> ActionResult {
        let target = intent.target ?? intent.content
        guard !target.isEmpty else {
            return .failure(ActionFailure(
                message: "No app or URL specified",
                isRecoverable: true,
                suggestion: "Say the name of the app or URL you want to open"
            ))
        }

        // Check if it's a URL
        if let url = URL(string: target), url.scheme != nil {
            NSWorkspace.shared.open(url)
            return .success(ActionSuccess(
                message: "Opened \(target)",
                shouldPaste: false,
                metadata: ["url": target]
            ))
        }

        // Try to find and open as an application via NSWorkspace (non-blocking)
        let appName = target
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appName) {
            // Found by bundle ID
            let config = NSWorkspace.OpenConfiguration()
            try await NSWorkspace.shared.openApplication(at: appURL, configuration: config)
            return .success(ActionSuccess(
                message: "Opened \(appName)",
                shouldPaste: false,
                metadata: ["app": appName]
            ))
        }

        // Try to find by name in /Applications and ~/Applications
        if let appURL = findApplication(named: appName) {
            let config = NSWorkspace.OpenConfiguration()
            try await NSWorkspace.shared.openApplication(at: appURL, configuration: config)
            return .success(ActionSuccess(
                message: "Opened \(appName)",
                shouldPaste: false,
                metadata: ["app": appName]
            ))
        }

        // Last resort: use open command (non-blocking, handles fuzzy app names)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = ["-a", appName]
        let pipe = Pipe()
        process.standardError = pipe
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            return .success(ActionSuccess(
                message: "Opened \(appName)",
                shouldPaste: false,
                metadata: ["app": appName]
            ))
        } else {
            let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "App not found"
            return .failure(ActionFailure(
                message: "Could not open \(appName): \(errorMessage)",
                isRecoverable: true,
                suggestion: "Make sure the app name is correct and the app is installed"
            ))
        }
    }

    private func findApplication(named name: String) -> URL? {
        let searchDirs = [
            "/Applications",
            "/System/Applications",
            NSHomeDirectory() + "/Applications",
            "/Applications/Utilities"
        ]

        let targetName = name.lowercased()

        for dir in searchDirs {
            guard let contents = try? FileManager.default.contentsOfDirectory(atPath: dir) else { continue }
            for item in contents where item.hasSuffix(".app") {
                let appNameWithoutExt = item.replacingOccurrences(of: ".app", with: "").lowercased()
                if appNameWithoutExt == targetName || appNameWithoutExt.contains(targetName) {
                    return URL(fileURLWithPath: dir).appendingPathComponent(item)
                }
            }
        }

        return nil
    }
}
