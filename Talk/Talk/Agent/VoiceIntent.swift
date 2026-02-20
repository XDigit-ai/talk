import Foundation

// MARK: - Action Types

enum ActionType: String, Codable, CaseIterable {
    case dictate        // Default: paste text at cursor (current behavior)
    case transform      // Modify selected/existing text with LLM
    case search         // Search the web
    case open           // Open an app, file, or URL
    case reply          // Reply to current email/message
    case create         // Create a document, event, reminder, note
    case summarize      // Summarize current content

    var displayName: String {
        switch self {
        case .dictate: return "Dictate"
        case .transform: return "Transform"
        case .search: return "Search"
        case .open: return "Open"
        case .reply: return "Reply"
        case .create: return "Create"
        case .summarize: return "Summarize"
        }
    }

    var icon: String {
        switch self {
        case .dictate: return "text.cursor"
        case .transform: return "wand.and.stars"
        case .search: return "magnifyingglass"
        case .open: return "arrow.up.forward.app"
        case .reply: return "arrowshape.turn.up.left"
        case .create: return "plus.rectangle"
        case .summarize: return "doc.text.magnifyingglass"
        }
    }
}

// MARK: - Voice Intent

struct VoiceIntent {
    let action: ActionType
    let target: String?           // What to act on (e.g., "Mail", "google doc", "calendar")
    let parameters: [String: String] // Action-specific params
    let content: String            // The actual text content to use
    let rawText: String            // Original transcription
    let confidence: Double         // 0.0-1.0

    /// Whether this intent is high-confidence enough to execute without confirmation
    var isHighConfidence: Bool {
        confidence >= 0.7
    }

    /// Create a default dictation intent (fallback)
    static func dictation(from text: String) -> VoiceIntent {
        VoiceIntent(
            action: .dictate,
            target: nil,
            parameters: [:],
            content: text,
            rawText: text,
            confidence: 1.0
        )
    }
}

// MARK: - Intent Classification Response (for JSON parsing from LLM)

struct IntentClassificationResponse: Codable {
    let action: String
    let target: String?
    let parameters: [String: String]?
    let content: String?
    let confidence: Double

    func toVoiceIntent(rawText: String) -> VoiceIntent {
        let actionType = ActionType(rawValue: action) ?? .dictate
        return VoiceIntent(
            action: actionType,
            target: target,
            parameters: parameters ?? [:],
            content: content ?? rawText,
            rawText: rawText,
            confidence: confidence
        )
    }
}
