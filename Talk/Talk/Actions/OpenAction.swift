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

        // Try to open as an application using AppleScript
        let appName = target
        let script = NSAppleScript(source: "tell application \"\(appName)\" to activate")
        var errorInfo: NSDictionary?
        script?.executeAndReturnError(&errorInfo)

        if let errorInfo = errorInfo {
            let errorMessage = errorInfo[NSAppleScript.errorMessage] as? String ?? "Unknown error"
            return .failure(ActionFailure(
                message: "Could not open \(appName): \(errorMessage)",
                error: ActionError.executionFailed(errorMessage),
                isRecoverable: true,
                suggestion: "Make sure the app name is correct and the app is installed"
            ))
        }

        return .success(ActionSuccess(
            message: "Opened \(appName)",
            shouldPaste: false,
            metadata: ["app": appName]
        ))
    }
}
