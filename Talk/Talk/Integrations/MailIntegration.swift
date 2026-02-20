import Foundation

@MainActor
class MailIntegration: AppIntegration {
    static let shared = MailIntegration()

    let bundleIdentifier = "com.apple.mail"
    let displayName = "Mail"
    let supportedActions: [ActionType] = [.reply, .create, .summarize]

    var isAvailable: Bool {
        FileManager.default.fileExists(atPath: "/System/Applications/Mail.app")
    }

    private init() {}

    // MARK: - AppIntegration

    func execute(intent: VoiceIntent, context: AppContext) async throws -> ActionResult {
        switch intent.action {
        case .reply:
            return try await replyToSelected(body: intent.content)

        case .create:
            let to = intent.parameters["to"] ?? ""
            let subject = intent.parameters["subject"] ?? ""
            return try await composeNew(to: to, subject: subject, body: intent.content)

        case .summarize:
            return try await summarizeSelectedThread()

        default:
            return .failure(ActionFailure(
                message: "Mail does not support \(intent.action.displayName)",
                isRecoverable: false
            ))
        }
    }

    func readContext() async throws -> [String: String] {
        guard let info = try await getSelectedEmailInfo() else { return [:] }
        return info
    }

    // MARK: - Mail Actions

    /// Get info about the currently selected email in Mail.app.
    func getSelectedEmailInfo() async throws -> [String: String]? {
        let script = """
        tell application "Mail"
            set selMsgs to selected messages of message viewer 1
            if (count of selMsgs) is 0 then return ""
            set msg to item 1 of selMsgs
            set msgSender to sender of msg
            set msgSubject to subject of msg
            set msgDate to date received of msg as string
            return msgSender & "|||" & msgSubject & "|||" & msgDate
        end tell
        """
        guard let result = try await AppleScriptBridge.execute(script),
              !result.isEmpty else {
            return nil
        }

        let parts = result.components(separatedBy: "|||")
        guard parts.count >= 3 else { return nil }

        return [
            "sender": parts[0],
            "subject": parts[1],
            "date": parts[2]
        ]
    }

    /// Reply to the currently selected email with the given body text.
    func replyToSelected(body: String) async throws -> ActionResult {
        guard isAvailable else {
            return .failure(ActionFailure(
                message: "Mail.app is not available",
                isRecoverable: false,
                suggestion: "Make sure Mail.app is installed"
            ))
        }

        // Enhance the body text for email formatting
        let enhancedBody = try await AIEnhancementService.shared.enhance(
            body,
            prompt: LLMPrompts.emailReply
        )

        let script = """
        tell application "Mail"
            set selMsgs to selected messages of message viewer 1
            if (count of selMsgs) is 0 then
                return "NO_SELECTION"
            end if
            set msg to item 1 of selMsgs
            set replyMsg to reply msg
            tell replyMsg
                set content to "\(enhancedBody.escapedForAppleScript)" & content
            end tell
            activate
        end tell
        """

        let result = try await AppleScriptBridge.execute(script)
        if result == "NO_SELECTION" {
            return .failure(ActionFailure(
                message: "No email selected in Mail",
                isRecoverable: true,
                suggestion: "Select an email in Mail.app first"
            ))
        }

        return .success(ActionSuccess(
            message: "Reply drafted in Mail",
            metadata: ["action": "reply"]
        ))
    }

    /// Compose a new email.
    func composeNew(to: String, subject: String, body: String) async throws -> ActionResult {
        guard isAvailable else {
            return .failure(ActionFailure(
                message: "Mail.app is not available",
                isRecoverable: false
            ))
        }

        let script = """
        tell application "Mail"
            set newMsg to make new outgoing message with properties {subject:"\(subject.escapedForAppleScript)", content:"\(body.escapedForAppleScript)", visible:true}
            if "\(to.escapedForAppleScript)" is not "" then
                tell newMsg
                    make new to recipient at end of to recipients with properties {address:"\(to.escapedForAppleScript)"}
                end tell
            end if
            activate
        end tell
        """

        try await AppleScriptBridge.execute(script)
        return .success(ActionSuccess(
            message: "New email composed",
            metadata: ["to": to, "subject": subject]
        ))
    }

    /// Summarize the currently selected email thread using LLM.
    func summarizeSelectedThread() async throws -> ActionResult {
        let script = """
        tell application "Mail"
            set selMsgs to selected messages of message viewer 1
            if (count of selMsgs) is 0 then return "NO_SELECTION"
            set msg to item 1 of selMsgs
            set msgContent to content of msg
            set msgSubject to subject of msg
            set msgSender to sender of msg
            return "From: " & msgSender & "\\nSubject: " & msgSubject & "\\n\\n" & msgContent
        end tell
        """

        let result = try await AppleScriptBridge.execute(script)
        if result == nil || result == "NO_SELECTION" {
            return .failure(ActionFailure(
                message: "No email selected to summarize",
                isRecoverable: true,
                suggestion: "Select an email in Mail.app first"
            ))
        }

        let truncated = String(result!.prefix(4000))
        let summary = try await AIEnhancementService.shared.enhance(
            truncated,
            prompt: LLMPrompts.summarization
        )

        return .success(ActionSuccess(
            message: "Email summarized",
            resultText: summary,
            shouldPaste: true
        ))
    }
}
