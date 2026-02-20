import Foundation

// MARK: - AppleScript Errors

enum AppleScriptError: LocalizedError {
    case executionFailed(String)
    case scriptCompilationFailed

    var errorDescription: String? {
        switch self {
        case .executionFailed(let detail):
            return "AppleScript execution failed: \(detail)"
        case .scriptCompilationFailed:
            return "AppleScript failed to compile"
        }
    }
}

// MARK: - AppleScript Bridge

class AppleScriptBridge {

    /// Execute an AppleScript asynchronously and return the result string.
    static func execute(_ script: String) async throws -> String? {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                let appleScript = NSAppleScript(source: script)

                guard let appleScript = appleScript else {
                    continuation.resume(throwing: AppleScriptError.scriptCompilationFailed)
                    return
                }

                let result = appleScript.executeAndReturnError(&error)

                if let error = error {
                    let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
                    continuation.resume(throwing: AppleScriptError.executionFailed(message))
                    return
                }

                continuation.resume(returning: result.stringValue)
            }
        }
    }

    /// Execute an AppleScript synchronously (for quick scripts like getting browser URL).
    static func executeSync(_ script: String) -> String? {
        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { return nil }
        let result = appleScript.executeAndReturnError(&error)
        if error != nil { return nil }
        return result.stringValue
    }
}

// MARK: - String Extension for AppleScript Safety

extension String {
    /// Escape string for safe use inside AppleScript double quotes.
    var escapedForAppleScript: String {
        self.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}
