import Foundation

/// Routes VoiceIntents to the correct ActionHandler based on action type.
@MainActor
class ActionRouter {
    static let shared = ActionRouter()

    private var handlers: [ActionType: ActionHandler] = [:]
    private var integrations: [String: AppIntegration] = [:]  // keyed by bundle ID

    /// Named integration references for intent-based routing
    private var emailIntegration: AppIntegration?
    private var messageIntegration: AppIntegration?
    private var calendarIntegration: AppIntegration?

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

    /// Register an integration under multiple bundle IDs (for apps like Spark that have variants)
    func registerIntegration(_ integration: AppIntegration, additionalBundleIds: [String]) {
        integrations[integration.bundleIdentifier] = integration
        for bid in additionalBundleIds {
            integrations[bid] = integration
        }
    }

    /// Register the primary email integration (used for intent-based routing)
    func registerEmailIntegration(_ integration: AppIntegration) {
        emailIntegration = integration
    }

    /// Register the primary message integration (used for intent-based routing)
    func registerMessageIntegration(_ integration: AppIntegration) {
        messageIntegration = integration
    }

    /// Register the primary calendar integration (used for intent-based routing)
    func registerCalendarIntegration(_ integration: AppIntegration) {
        calendarIntegration = integration
    }

    // MARK: - Routing

    /// Route a VoiceIntent to the appropriate handler and execute it.
    func route(intent: VoiceIntent, context: AppContext) async throws -> ActionResult {
        // First, check if there's a specific integration for the active app
        if let integration = integrations[context.bundleIdentifier],
           integration.isAvailable,
           integration.supportedActions.contains(intent.action) {
            debugLog("Routing to app integration: \(integration.displayName)")
            return try await integration.execute(intent: intent, context: context)
        }

        // Check if the intent targets a specific app via parameters (e.g. "email to Krista")
        if let targetIntegration = resolveTargetIntegration(for: intent) {
            debugLog("Resolved target integration: \(targetIntegration.displayName), available=\(targetIntegration.isAvailable), supports=\(targetIntegration.supportedActions.contains(intent.action))")
            if targetIntegration.isAvailable, targetIntegration.supportedActions.contains(intent.action) {
                return try await targetIntegration.execute(intent: intent, context: context)
            }
        }

        // Fall back to generic action handlers
        debugLog("Falling back to generic handler for action: \(intent.action)")
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
            return emailIntegration
        case "message":
            return messageIntegration
        default:
            break
        }

        // Also check raw text for keywords as fallback
        let lower = intent.rawText.lowercased()
        if lower.contains("email") || lower.contains("mail") {
            return emailIntegration
        }
        if lower.contains("imessage") || lower.contains("text message") {
            return messageIntegration
        }

        // Calendar keywords
        let calendarKeywords = ["calendar", "event", "invite", "meeting", "appointment", "schedule"]
        if calendarKeywords.contains(where: { lower.contains($0) }) {
            return calendarIntegration
        }

        return nil
    }

    private func debugLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let line = "[\(timestamp)] [ActionRouter] \(message)\n"
        let path = "/tmp/dictai_agent.log"
        if let handle = FileHandle(forWritingAtPath: path) {
            handle.seekToEndOfFile()
            handle.write(line.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? line.write(toFile: path, atomically: true, encoding: .utf8)
        }
    }
}
