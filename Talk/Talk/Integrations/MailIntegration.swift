import Foundation
import AppKit

@MainActor
class MailIntegration: AppIntegration {
    static let shared = MailIntegration()

    let bundleIdentifier = "com.apple.mail"
    let displayName = "Mail"
    let supportedActions: [ActionType] = [.reply, .create, .summarize]

    var isAvailable: Bool { true }  // mailto: always works

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
            // No recipient — generate reply text and paste it
            return try await generateReplyText(body: intent.content)

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
        return [:]
    }

    // MARK: - Mail Actions

    /// Compose a new email via mailto: — opens the user's default mail app (Spark, Outlook, etc.)
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

        // Build mailto: URL — macOS routes this to the user's default mail app
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = to
        var queryItems: [URLQueryItem] = []
        if !emailSubject.isEmpty {
            queryItems.append(URLQueryItem(name: "subject", value: emailSubject))
        }
        if !emailBody.isEmpty {
            queryItems.append(URLQueryItem(name: "body", value: emailBody))
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            return .failure(ActionFailure(
                message: "Could not create email URL",
                isRecoverable: false
            ))
        }

        NSWorkspace.shared.open(url)

        return .success(ActionSuccess(
            message: "Email drafted to \(to)",
            metadata: ["to": to, "subject": emailSubject]
        ))
    }

    /// Generate reply text using LLM and return it for pasting
    private func generateReplyText(body: String) async throws -> ActionResult {
        guard !body.isEmpty else {
            return .failure(ActionFailure(
                message: "No reply content provided",
                isRecoverable: true,
                suggestion: "Say what you want to reply with"
            ))
        }

        let enhancedBody = try await AIEnhancementService.shared.enhance(
            body,
            prompt: LLMPrompts.emailReply
        )

        return .success(ActionSuccess(
            message: "Reply drafted",
            resultText: enhancedBody,
            shouldPaste: true
        ))
    }

    /// Summarize selected text as an email summary using LLM.
    func summarizeSelectedThread() async throws -> ActionResult {
        // Try to get selected text from the current app
        let selectedText = PasteEligibilityService.getSelectedText()

        guard let text = selectedText, !text.isEmpty else {
            return .failure(ActionFailure(
                message: "No email content to summarize",
                isRecoverable: true,
                suggestion: "Select email text first, then ask to summarize"
            ))
        }

        let truncated = String(text.prefix(4000))
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
