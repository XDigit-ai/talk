import Foundation

@MainActor
class NotesIntegration: AppIntegration {
    static let shared = NotesIntegration()

    let bundleIdentifier = "com.apple.Notes"
    let displayName = "Notes"
    let supportedActions: [ActionType] = [.create, .dictate]

    var isAvailable: Bool {
        FileManager.default.fileExists(atPath: "/System/Applications/Notes.app")
    }

    private init() {}

    // MARK: - AppIntegration

    func execute(intent: VoiceIntent, context: AppContext) async throws -> ActionResult {
        switch intent.action {
        case .create:
            let title = intent.parameters["title"] ?? "Untitled Note"
            return try await createNote(title: title, body: intent.content)

        case .dictate:
            let title = intent.parameters["title"]
            if let title = title {
                return try await appendToNote(title: title, text: intent.content)
            }
            return try await createNote(title: "Voice Note", body: intent.content)

        default:
            return .failure(ActionFailure(
                message: "Notes does not support \(intent.action.displayName)",
                isRecoverable: false
            ))
        }
    }

    // MARK: - Notes Actions

    /// Create a new note with the given title and body.
    func createNote(title: String, body: String) async throws -> ActionResult {
        guard isAvailable else {
            return .failure(ActionFailure(
                message: "Notes.app is not available",
                isRecoverable: false
            ))
        }

        let script = """
        tell application "Notes"
            tell account "iCloud"
                make new note at folder "Notes" with properties {name:"\(title.escapedForAppleScript)", body:"\(body.escapedForAppleScript)"}
            end tell
            activate
        end tell
        """

        try await AppleScriptBridge.execute(script)
        return .success(ActionSuccess(
            message: "Note \"\(title)\" created",
            metadata: ["title": title]
        ))
    }

    /// Append text to an existing note found by title.
    func appendToNote(title: String, text: String) async throws -> ActionResult {
        guard isAvailable else {
            return .failure(ActionFailure(
                message: "Notes.app is not available",
                isRecoverable: false
            ))
        }

        let script = """
        tell application "Notes"
            set matchingNotes to every note whose name is "\(title.escapedForAppleScript)"
            if (count of matchingNotes) is 0 then
                return "NOT_FOUND"
            end if
            set targetNote to item 1 of matchingNotes
            set currentBody to body of targetNote
            set body of targetNote to currentBody & "<br>" & "\(text.escapedForAppleScript)"
        end tell
        """

        let result = try await AppleScriptBridge.execute(script)
        if result == "NOT_FOUND" {
            // Note not found, create a new one instead
            return try await createNote(title: title, body: text)
        }

        return .success(ActionSuccess(
            message: "Appended to note \"\(title)\"",
            metadata: ["title": title]
        ))
    }
}
