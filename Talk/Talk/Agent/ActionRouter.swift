import Foundation

/// Routes VoiceIntents to the correct ActionHandler based on action type.
@MainActor
class ActionRouter {
    static let shared = ActionRouter()

    private var handlers: [ActionType: ActionHandler] = [:]
    private var integrations: [String: AppIntegration] = [:]  // keyed by bundle ID

    private init() {
        registerDefaultHandlers()
    }

    // MARK: - Registration

    private func registerDefaultHandlers() {
        handlers[.dictate] = DictateAction.shared
        handlers[.transform] = TransformAction.shared
        handlers[.search] = SearchAction.shared
        handlers[.open] = OpenAction.shared
        handlers[.reply] = ReplyAction.shared
        handlers[.summarize] = SummarizeAction.shared
        handlers[.create] = CreateAction.shared
    }

    func registerIntegration(_ integration: AppIntegration) {
        integrations[integration.bundleIdentifier] = integration
    }

    // MARK: - Routing

    /// Route a VoiceIntent to the appropriate handler and execute it.
    func route(intent: VoiceIntent, context: AppContext) async throws -> ActionResult {
        // First, check if there's a specific integration for the active app
        if let integration = integrations[context.bundleIdentifier],
           integration.isAvailable,
           integration.supportedActions.contains(intent.action) {
            return try await integration.execute(intent: intent, context: context)
        }

        // Check if the intent targets a specific app via parameters (e.g. "email to Krista")
        if let targetIntegration = resolveTargetIntegration(for: intent),
           targetIntegration.isAvailable,
           targetIntegration.supportedActions.contains(intent.action) {
            return try await targetIntegration.execute(intent: intent, context: context)
        }

        // Fall back to generic action handlers
        guard let handler = handlers[intent.action] else {
            return .failure(ActionFailure(
                message: "No handler for action: \(intent.action.displayName)",
                isRecoverable: false
            ))
        }

        return try await handler.execute(intent: intent, context: context)
    }

    /// Determine if the intent should be routed to a specific integration
    /// based on keywords/parameters, regardless of the frontmost app.
    private func resolveTargetIntegration(for intent: VoiceIntent) -> AppIntegration? {
        let medium = intent.parameters["medium"] ?? ""

        switch medium {
        case "email":
            return integrations["com.apple.mail"]
        case "message":
            return integrations["com.apple.MobileSMS"]
        default:
            break
        }

        // Also check raw text for email/message keywords as fallback
        let lower = intent.rawText.lowercased()
        if lower.contains("email") || lower.contains("mail") {
            return integrations["com.apple.mail"]
        }
        if lower.contains("imessage") || lower.contains("text message") {
            return integrations["com.apple.MobileSMS"]
        }

        return nil
    }
}
