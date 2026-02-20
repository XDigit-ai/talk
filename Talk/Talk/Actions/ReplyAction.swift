import Foundation

@MainActor
class ReplyAction: ActionHandler {
    static let shared = ReplyAction()

    var supportedActions: [ActionType] { [.reply] }

    func execute(intent: VoiceIntent, context: AppContext) async throws -> ActionResult {
        let content = intent.content
        guard !content.isEmpty else {
            return .failure(ActionFailure(
                message: "No reply content provided",
                isRecoverable: true,
                suggestion: "Say what you want to reply with"
            ))
        }

        let prompt = context.isEmailClient ? LLMPrompts.emailReply : LLMPrompts.enhancement

        do {
            let result = try await AIEnhancementService.shared.enhance(content, prompt: prompt)
            return .success(ActionSuccess(
                message: "Reply generated",
                resultText: result,
                shouldPaste: true
            ))
        } catch {
            return .failure(ActionFailure(
                message: "Failed to generate reply: \(error.localizedDescription)",
                error: error,
                isRecoverable: true,
                suggestion: "Check that your LLM provider is configured and running"
            ))
        }
    }
}
