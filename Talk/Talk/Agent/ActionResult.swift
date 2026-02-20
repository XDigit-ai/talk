import Foundation

// MARK: - Action Result

enum ActionResult {
    case success(ActionSuccess)
    case failure(ActionFailure)

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var message: String {
        switch self {
        case .success(let s): return s.message
        case .failure(let f): return f.message
        }
    }
}

struct ActionSuccess {
    let message: String
    let resultText: String?       // Text output (e.g., summary, transformed text)
    let shouldPaste: Bool         // Whether to paste resultText at cursor
    let metadata: [String: String] // Extra info (e.g., URL opened, app launched)

    init(message: String, resultText: String? = nil, shouldPaste: Bool = false, metadata: [String: String] = [:]) {
        self.message = message
        self.resultText = resultText
        self.shouldPaste = shouldPaste
        self.metadata = metadata
    }
}

struct ActionFailure {
    let message: String
    let error: Error?
    let isRecoverable: Bool
    let suggestion: String?       // What the user can do to fix it

    init(message: String, error: Error? = nil, isRecoverable: Bool = false, suggestion: String? = nil) {
        self.message = message
        self.error = error
        self.isRecoverable = isRecoverable
        self.suggestion = suggestion
    }
}

// MARK: - Action Errors

enum ActionError: LocalizedError {
    case noSelectedText
    case appNotRunning(String)
    case integrationNotAvailable(String)
    case permissionDenied(String)
    case executionFailed(String)
    case appleScriptError(String)
    case invalidParameters(String)

    var errorDescription: String? {
        switch self {
        case .noSelectedText:
            return "No text is selected in the active application"
        case .appNotRunning(let app):
            return "\(app) is not running"
        case .integrationNotAvailable(let name):
            return "\(name) integration is not available"
        case .permissionDenied(let permission):
            return "Permission denied: \(permission)"
        case .executionFailed(let detail):
            return "Action failed: \(detail)"
        case .appleScriptError(let detail):
            return "AppleScript error: \(detail)"
        case .invalidParameters(let detail):
            return "Invalid parameters: \(detail)"
        }
    }
}
