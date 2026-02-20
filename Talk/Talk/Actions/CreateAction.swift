import Foundation

@MainActor
class CreateAction: ActionHandler {
    static let shared = CreateAction()

    var supportedActions: [ActionType] { [.create] }

    func execute(intent: VoiceIntent, context: AppContext) async throws -> ActionResult {
        let content = intent.content
        guard !content.isEmpty else {
            return .failure(ActionFailure(
                message: "No content provided for creation",
                isRecoverable: true,
                suggestion: "Describe what you want to create"
            ))
        }

        let itemType = intent.target ?? "note"
        let prompt = """
        You are a content creation assistant. The user wants to create a \(itemType).
        Format the following dictated content appropriately for a \(itemType).

        Instructions:
        1. Fix grammar, spelling, and punctuation
        2. Format appropriately for the content type (\(itemType))
        3. Add structure (headings, bullet points) if appropriate
        4. Keep the original meaning and intent

        Return ONLY the formatted content, nothing else.
        """

        do {
            let result = try await AIEnhancementService.shared.enhance(content, prompt: prompt)
            return .success(ActionSuccess(
                message: "\(itemType.capitalized) created",
                resultText: result,
                shouldPaste: true,
                metadata: ["type": itemType]
            ))
        } catch {
            return .failure(ActionFailure(
                message: "Failed to create \(itemType): \(error.localizedDescription)",
                error: error,
                isRecoverable: true,
                suggestion: "Check that your LLM provider is configured and running"
            ))
        }
    }
}
