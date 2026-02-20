import Foundation

// MARK: - Action Handler Protocol

/// Protocol for all voice action handlers.
/// Each action type (dictate, search, reply, etc.) implements this protocol.
protocol ActionHandler {
    /// The action types this handler supports
    var supportedActions: [ActionType] { get }

    /// Execute the action with the given intent and context
    /// - Parameters:
    ///   - intent: The classified voice intent
    ///   - context: Current app context (active app, selected text, etc.)
    /// - Returns: The result of the action execution
    func execute(intent: VoiceIntent, context: AppContext) async throws -> ActionResult
}

// MARK: - App Integration Protocol

/// Protocol for deep app integrations (Mail, Calendar, Notes, etc.)
/// Integrations provide richer actions than basic ActionHandlers by leveraging
/// app-specific APIs (AppleScript, EventKit, etc.)
protocol AppIntegration {
    /// The bundle identifier of the integrated app
    var bundleIdentifier: String { get }

    /// Human-readable name of the integration
    var displayName: String { get }

    /// Actions this integration supports
    var supportedActions: [ActionType] { get }

    /// Whether the integration is currently available (app installed, permissions granted)
    var isAvailable: Bool { get }

    /// Execute an action via this integration
    func execute(intent: VoiceIntent, context: AppContext) async throws -> ActionResult

    /// Read app-specific context (optional, for enriching AppContext)
    func readContext() async throws -> [String: String]
}

extension AppIntegration {
    func readContext() async throws -> [String: String] {
        return [:]
    }
}
