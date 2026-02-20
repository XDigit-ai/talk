import Foundation
import AppKit

@MainActor
class SearchAction: ActionHandler {
    static let shared = SearchAction()

    var supportedActions: [ActionType] { [.search] }

    func execute(intent: VoiceIntent, context: AppContext) async throws -> ActionResult {
        let query = intent.content
        guard !query.isEmpty else {
            return .failure(ActionFailure(
                message: "No search query provided",
                isRecoverable: true,
                suggestion: "Say what you want to search for"
            ))
        }

        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.google.com/search?q=\(encoded)") else {
            return .failure(ActionFailure(
                message: "Could not create search URL",
                error: ActionError.invalidParameters("Invalid search query"),
                isRecoverable: true,
                suggestion: "Try a simpler search query"
            ))
        }

        NSWorkspace.shared.open(url)

        return .success(ActionSuccess(
            message: "Searching for: \(query)",
            shouldPaste: false,
            metadata: ["url": url.absoluteString, "query": query]
        ))
    }
}
