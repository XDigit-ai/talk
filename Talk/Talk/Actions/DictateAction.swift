import Foundation
import AppKit

@MainActor
class DictateAction: ActionHandler {
    static let shared = DictateAction()

    var supportedActions: [ActionType] { [.dictate] }

    func execute(intent: VoiceIntent, context: AppContext) async throws -> ActionResult {
        let text = intent.content
        guard !text.isEmpty else {
            return .failure(ActionFailure(
                message: "No text to dictate",
                isRecoverable: true,
                suggestion: "Try speaking again"
            ))
        }

        // Return text with shouldPaste=true so AppState handles the paste
        return .success(ActionSuccess(
            message: "Dictated \(text.count) characters",
            resultText: text,
            shouldPaste: true
        ))
    }
}
