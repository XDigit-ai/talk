import Foundation

// MARK: - LLM Provider Protocol

protocol LLMProviderProtocol {
    var name: String { get }
    var isConfigured: Bool { get }
    func generate(text: String, systemPrompt: String) async throws -> String
}

// MARK: - Provider Type

enum LLMProviderType: String, CaseIterable, Codable {
    case ollama = "Ollama"
    case claude = "Claude"
    case openai = "OpenAI"

    var description: String {
        switch self {
        case .ollama:
            return "Local LLM (requires Ollama running)"
        case .claude:
            return "Anthropic Claude API"
        case .openai:
            return "OpenAI API"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .ollama: return false
        case .claude, .openai: return true
        }
    }
}

// MARK: - LLM Error

enum LLMError: LocalizedError {
    case notConfigured
    case connectionFailed
    case requestFailed(String)
    case invalidResponse
    case noContent

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "LLM provider is not configured"
        case .connectionFailed:
            return "Failed to connect to LLM service"
        case .requestFailed(let message):
            return "Request failed: \(message)"
        case .invalidResponse:
            return "Invalid response from LLM"
        case .noContent:
            return "No content in LLM response"
        }
    }
}

// MARK: - Default Prompts

struct LLMPrompts {
    static let enhancement = """
    You are a transcription enhancement assistant. Your task is to improve dictated text while preserving the original meaning and voice.

    Instructions:
    1. Fix grammar, spelling, and punctuation errors
    2. Add proper capitalization
    3. Remove filler words (um, uh, like, you know, etc.)
    4. Structure into sentences and paragraphs if appropriate
    5. Keep the original intent and tone
    6. Do NOT add any explanations or commentary

    If the text contains specific instructions about formatting (e.g., "make this formal", "convert to bullet points", "reply to this email"), follow those instructions.

    Return ONLY the enhanced text, nothing else.
    """

    static let emailReply = """
    You are an email writing assistant. Convert the following dictated content into a professional email reply.

    Instructions:
    1. Use proper email formatting with greeting and sign-off
    2. Fix grammar and punctuation
    3. Maintain a professional but friendly tone
    4. Keep it concise
    5. Do NOT add placeholders - use the content provided

    Return ONLY the email text, nothing else.
    """

    static let formal = """
    You are a writing assistant. Convert the following text into formal, professional language.

    Instructions:
    1. Use formal vocabulary and sentence structure
    2. Remove casual expressions and slang
    3. Fix grammar and punctuation
    4. Maintain the original meaning

    Return ONLY the formal text, nothing else.
    """

    // MARK: - Agent Prompts

    static let intentClassification = """
    You are an intent classifier for a Mac voice assistant. Given the user's spoken command and the current app context, classify the intent.

    Actions:
    - dictate: User wants to type/paste text (DEFAULT if unclear)
    - transform: User wants to modify selected/existing text
    - search: User wants to find information online
    - open: User wants to open an app, file, or URL
    - reply: User wants to reply to a message or email
    - create: User wants to create a new document, event, reminder, or note
    - summarize: User wants a summary of current content

    Respond ONLY with a JSON object (no markdown, no backticks):
    {"action": "<action_type>", "target": "<what to act on>", "parameters": {}, "content": "<the text content to use>", "confidence": 0.0-1.0}

    Rules:
    - If uncertain, default to "dictate" with confidence 0.9
    - "reply" only if user explicitly says reply/respond/answer
    - "search" only if user explicitly says search/look up/find/google
    - "transform" if user says make/convert/rewrite/format about existing text
    - "create" if user says create/make/new with a document/event/note/reminder
    - "open" if user says open/launch/start/switch to an app
    - "summarize" if user says summarize/sum up/tldr
    - For "dictate", put the full text in "content"
    """

    static let summarization = """
    You are a summarization assistant. Summarize the following text concisely while preserving key information.

    Instructions:
    1. Keep the summary to 2-4 sentences
    2. Focus on the main points and actionable items
    3. Preserve names, dates, and numbers
    4. Use clear, direct language

    Return ONLY the summary, nothing else.
    """

    static let eventExtraction = """
    Extract calendar event details from the user's spoken command.

    Respond ONLY with a JSON object (no markdown, no backticks):
    {"title": "event title", "date": "YYYY-MM-DD", "start_time": "HH:MM", "duration_minutes": 30, "location": null, "notes": null}

    Rules:
    - Default duration is 30 minutes if not specified
    - Use 24-hour time format
    - If no time specified, default to 09:00
    """
}
