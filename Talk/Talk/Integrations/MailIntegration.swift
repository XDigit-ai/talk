import Foundation
import AppKit

@MainActor
class MailIntegration: AppIntegration {
    static let shared = MailIntegration()

    let bundleIdentifier = "com.apple.mail"
    let displayName = "Mail"
    let supportedActions: [ActionType] = [.reply, .create, .summarize]

    var isAvailable: Bool { true }  // We always have a way to send email (Gmail, mailto:, etc.)

    private init() {}

    // MARK: - AppIntegration

    func execute(intent: VoiceIntent, context: AppContext) async throws -> ActionResult {
        switch intent.action {
        case .reply:
            // If we have a "to" parameter, this is a new email (e.g. "draft email to Krista")
            if let to = intent.parameters["to"], !to.isEmpty {
                let body = intent.parameters["body"] ?? intent.content
                let subject = intent.parameters["subject"] ?? ""
                return try await composeNew(to: to, subject: subject, body: body)
            }
            // Otherwise reply to the selected email in Mail
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

    // MARK: - Email Delivery Strategy

    /// Determines the best way to compose an email:
    /// 1. If Gmail is open in a browser tab → use Gmail compose URL
    /// 2. Otherwise → use mailto: URL (opens the user's default mail app, e.g. Spark)
    private enum ComposeStrategy {
        case gmail(browserBundleId: String)
        case defaultMailApp
    }

    private func detectComposeStrategy() -> ComposeStrategy {
        // Check running browsers for Gmail tabs
        let browserBundleIds = [
            "com.google.Chrome",
            "com.brave.Browser",
            "com.apple.Safari",
            "com.microsoft.edgemac",
            "com.vivaldi.Vivaldi"
        ]

        for bid in browserBundleIds {
            guard NSWorkspace.shared.runningApplications.contains(where: { $0.bundleIdentifier == bid }) else {
                continue
            }
            if let url = BrowserIntegration.shared.getCurrentURL(bundleId: bid),
               url.contains("mail.google.com") {
                return .gmail(browserBundleId: bid)
            }
        }

        return .defaultMailApp
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

    /// Compose a new email. Checks for Gmail in browser first, then falls back to default mail app.
    func composeNew(to: String, subject: String, body: String) async throws -> ActionResult {
        // Use LLM to draft a proper email from the voice description
        var emailBody = body
        var emailSubject = subject
        if AIEnhancementService.shared.isConfigured && !body.isEmpty {
            let prompt = """
            Draft a professional email based on this voice description. The recipient is \(to).
            Return ONLY the email body text (no subject line, no "Subject:", no greeting prefix like "Email:").
            Keep it concise and natural.
            """
            emailBody = try await AIEnhancementService.shared.enhance(body, prompt: prompt)
        }

        if emailSubject.isEmpty && !emailBody.isEmpty {
            if AIEnhancementService.shared.isConfigured {
                let subjectPrompt = "Generate a short email subject line (max 8 words) for this email. Return ONLY the subject line, nothing else."
                emailSubject = try await AIEnhancementService.shared.enhance(emailBody, prompt: subjectPrompt)
            }
        }

        let strategy = detectComposeStrategy()

        switch strategy {
        case .gmail(let browserBundleId):
            return try await composeViaGmail(to: to, subject: emailSubject, body: emailBody, browserBundleId: browserBundleId)
        case .defaultMailApp:
            return composeViaMailto(to: to, subject: emailSubject, body: emailBody)
        }
    }

    /// Compose via Gmail in the browser that already has it open.
    private func composeViaGmail(to: String, subject: String, body: String, browserBundleId: String) async throws -> ActionResult {
        var components = URLComponents(string: "https://mail.google.com/mail/")!
        components.queryItems = [
            URLQueryItem(name: "view", value: "cm"),
            URLQueryItem(name: "to", value: to),
            URLQueryItem(name: "su", value: subject),
            URLQueryItem(name: "body", value: body)
        ]

        guard let url = components.url else {
            return composeViaMailto(to: to, subject: subject, body: body)
        }

        let appName = BrowserIntegration.shared.appNameForBundleId(browserBundleId)
        let script = "tell application \"\(appName)\" to open location \"\(url.absoluteString.escapedForAppleScript)\""
        try await AppleScriptBridge.execute(script)

        return .success(ActionSuccess(
            message: "Email drafted to \(to) in Gmail",
            metadata: ["to": to, "subject": subject, "via": "gmail"]
        ))
    }

    /// Compose via mailto: URL — opens the user's default mail app (Spark, Outlook, etc.)
    private func composeViaMailto(to: String, subject: String, body: String) -> ActionResult {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = to
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]

        guard let url = components.url else {
            return .failure(ActionFailure(
                message: "Could not create email URL",
                isRecoverable: false
            ))
        }

        NSWorkspace.shared.open(url)

        return .success(ActionSuccess(
            message: "Email drafted to \(to)",
            metadata: ["to": to, "subject": subject, "via": "default_mail_app"]
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
