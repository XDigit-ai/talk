import Foundation

@MainActor
class SummarizeAction: ActionHandler {
    static let shared = SummarizeAction()

    var supportedActions: [ActionType] { [.summarize] }

    func execute(intent: VoiceIntent, context: AppContext) async throws -> ActionResult {
        let text = context.selectedText ?? intent.content
        guard !text.isEmpty else {
            return .failure(ActionFailure(
                message: "No text to summarize",
                error: ActionError.noSelectedText,
                isRecoverable: true,
                suggestion: "Select some text or provide content to summarize"
            ))
        }

        do {
            let result = try await AIEnhancementService.shared.enhance(text, prompt: LLMPrompts.summarization)
            return .success(ActionSuccess(
                message: "Text summarized",
                resultText: result,
                shouldPaste: true
            ))
        } catch {
            return .failure(ActionFailure(
                message: "Failed to summarize: \(error.localizedDescription)",
                error: error,
                isRecoverable: true,
                suggestion: "Check that your LLM provider is configured and running"
            ))
        }
    }
}
