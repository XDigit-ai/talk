import Foundation

@MainActor
class MessagesIntegration: AppIntegration {
    static let shared = MessagesIntegration()

    let bundleIdentifier = "com.apple.MobileSMS"
    let displayName = "Messages"
    let supportedActions: [ActionType] = [.reply, .create]

    var isAvailable: Bool {
        FileManager.default.fileExists(atPath: "/System/Applications/Messages.app")
    }

    private init() {}

    // MARK: - AppIntegration

    func execute(intent: VoiceIntent, context: AppContext) async throws -> ActionResult {
        switch intent.action {
        case .create:
            let to = intent.parameters["to"] ?? ""
            guard !to.isEmpty else {
                return .failure(ActionFailure(
                    message: "No recipient specified",
                    isRecoverable: true,
                    suggestion: "Specify who to send the message to"
                ))
            }
            return try await sendMessage(to: to, text: intent.content)

        case .reply:
            return try await replyToCurrentConversation(text: intent.content)

        default:
            return .failure(ActionFailure(
                message: "Messages does not support \(intent.action.displayName)",
                isRecoverable: false
            ))
        }
    }

    // MARK: - Messages Actions

    /// Send a message to a specific contact via Messages.app.
    /// Note: Messages AppleScript support is limited. The "send" command
    /// opens a compose window but may require user confirmation on newer macOS.
    func sendMessage(to recipient: String, text: String) async throws -> ActionResult {
        guard isAvailable else {
            return .failure(ActionFailure(
                message: "Messages.app is not available",
                isRecoverable: false
            ))
        }

        let script = """
        tell application "Messages"
            set targetBuddy to "\(recipient.escapedForAppleScript)"
            set targetService to 1st account whose service type = iMessage
            set theBuddy to participant targetBuddy of targetService
            send "\(text.escapedForAppleScript)" to theBuddy
        end tell
        """

        do {
            try await AppleScriptBridge.execute(script)
            return .success(ActionSuccess(
                message: "Message sent to \(recipient)",
                metadata: ["to": recipient]
            ))
        } catch {
            // Fallback: open Messages with a compose window if direct send fails
            // Messages AppleScript is notoriously limited on modern macOS
            return try await openComposeWindow(to: recipient, text: text)
        }
    }

    /// Reply in the currently active Messages conversation.
    /// Uses keyboard simulation approach since Messages AppleScript
    /// does not expose the active conversation reliably.
    func replyToCurrentConversation(text: String) async throws -> ActionResult {
        guard isAvailable else {
            return .failure(ActionFailure(
                message: "Messages.app is not available",
                isRecoverable: false
            ))
        }

        // Activate Messages and type into the active conversation's input field
        let script = """
        tell application "Messages"
            activate
        end tell
        delay 0.3
        tell application "System Events"
            tell process "Messages"
                set frontmost to true
                -- Click the message input field
                keystroke "\(text.escapedForAppleScript)"
                keystroke return
            end tell
        end tell
        """

        do {
            try await AppleScriptBridge.execute(script)
            return .success(ActionSuccess(
                message: "Reply sent in Messages",
                metadata: ["action": "reply"]
            ))
        } catch {
            return .failure(ActionFailure(
                message: "Could not reply in Messages: \(error.localizedDescription)",
                error: error,
                isRecoverable: true,
                suggestion: "Make sure Messages is open with a conversation selected"
            ))
        }
    }

    // MARK: - Private Helpers

    /// Fallback: open a compose window using the imessage:// URL scheme.
    private func openComposeWindow(to recipient: String, text: String) async throws -> ActionResult {
        guard let encodedBody = text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let encodedTo = recipient.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return .failure(ActionFailure(message: "Could not encode message"))
        }

        let urlString = "imessage://\(encodedTo)?body=\(encodedBody)"
        let script = "open location \"\(urlString.escapedForAppleScript)\""

        try await AppleScriptBridge.execute(script)
        return .success(ActionSuccess(
            message: "Message composed for \(recipient) (review and send in Messages)",
            metadata: ["to": recipient, "method": "compose_window"]
        ))
    }
}
