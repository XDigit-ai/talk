import Foundation

@MainActor
class TransformAction: ActionHandler {
    static let shared = TransformAction()

    var supportedActions: [ActionType] { [.transform] }

    func execute(intent: VoiceIntent, context: AppContext) async throws -> ActionResult {
        let textToTransform = context.selectedText ?? intent.content
        guard !textToTransform.isEmpty else {
            return .failure(ActionFailure(
                message: "No text to transform",
                error: ActionError.noSelectedText,
                isRecoverable: true,
                suggestion: "Select some text or dictate the text you want to transform"
            ))
        }

        let instruction = intent.parameters["instruction"] ?? intent.target
        let prompt: String
        if let instruction = instruction {
            prompt = """
            \(LLMPrompts.enhancement)

            Additional instruction: \(instruction)
            """
        } else {
            prompt = LLMPrompts.enhancement
        }

        do {
            let result = try await AIEnhancementService.shared.enhance(textToTransform, prompt: prompt)
            return .success(ActionSuccess(
                message: "Text transformed",
                resultText: result,
                shouldPaste: true
            ))
        } catch {
            return .failure(ActionFailure(
                message: "Failed to transform text: \(error.localizedDescription)",
                error: error,
                isRecoverable: true,
                suggestion: "Check that your LLM provider is configured and running"
            ))
        }
    }
}
