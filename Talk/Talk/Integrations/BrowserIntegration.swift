import Foundation
import AppKit

@MainActor
class BrowserIntegration: AppIntegration {
    static let shared = BrowserIntegration()

    let bundleIdentifier = "com.apple.Safari"
    let displayName = "Browser"
    let supportedActions: [ActionType] = [.search, .summarize, .open]

    var isAvailable: Bool {
        // At least one browser is always available on macOS
        true
    }

    private init() {}

    // MARK: - AppIntegration

    func execute(intent: VoiceIntent, context: AppContext) async throws -> ActionResult {
        switch intent.action {
        case .search:
            let query = intent.content
            guard !query.isEmpty else {
                return .failure(ActionFailure(
                    message: "No search query provided",
                    isRecoverable: true,
                    suggestion: "Say what you want to search for"
                ))
            }
            return try await search(query: query)

        case .summarize:
            return try await summarizeCurrentPage(context: context)

        case .open:
            let urlString = intent.parameters["url"] ?? intent.content
            return try await openURL(urlString)

        default:
            return .failure(ActionFailure(
                message: "Browser does not support \(intent.action.displayName)",
                isRecoverable: false
            ))
        }
    }

    func readContext() async throws -> [String: String] {
        var ctx: [String: String] = [:]
        if let url = getCurrentURL() {
            ctx["url"] = url
        }
        return ctx
    }

    // MARK: - Browser Actions

    /// Get the current URL from the frontmost browser.
    func getCurrentURL(bundleId: String? = nil) -> String? {
        let bid = bundleId ?? frontmostBrowserBundleId()
        guard let bid = bid else { return nil }

        let script: String
        switch bid {
        case "com.apple.Safari":
            script = "tell application \"Safari\" to get URL of current tab of front window"
        case "com.google.Chrome", "com.brave.Browser", "com.microsoft.edgemac", "com.vivaldi.Vivaldi":
            let appName = appNameForBundleId(bid)
            script = "tell application \"\(appName)\" to get URL of active tab of front window"
        default:
            return nil
        }

        return AppleScriptBridge.executeSync(script)
    }

    /// Get visible page text via JavaScript injection (Safari only).
    func getPageText() async throws -> String? {
        let script = """
        tell application "Safari"
            do JavaScript "document.body.innerText" in current tab of front window
        end tell
        """
        return try await AppleScriptBridge.execute(script)
    }

    /// Open a Google search for the given query.
    func search(query: String) async throws -> ActionResult {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return .failure(ActionFailure(message: "Could not encode search query"))
        }
        let urlString = "https://www.google.com/search?q=\(encoded)"
        let script = "open location \"\(urlString.escapedForAppleScript)\""
        try await AppleScriptBridge.execute(script)
        return .success(ActionSuccess(
            message: "Searching for \"\(query)\"",
            metadata: ["url": urlString, "query": query]
        ))
    }

    /// Open a URL in the default browser.
    func openURL(_ urlString: String) async throws -> ActionResult {
        var normalized = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        if !normalized.contains("://") {
            normalized = "https://\(normalized)"
        }
        let script = "open location \"\(normalized.escapedForAppleScript)\""
        try await AppleScriptBridge.execute(script)
        return .success(ActionSuccess(
            message: "Opened \(normalized)",
            metadata: ["url": normalized]
        ))
    }

    /// Summarize the current browser page using the LLM.
    func summarizeCurrentPage(context: AppContext) async throws -> ActionResult {
        guard let pageText = try await getPageText(), !pageText.isEmpty else {
            return .failure(ActionFailure(
                message: "Could not read page content",
                isRecoverable: false,
                suggestion: "Make sure Safari is the frontmost browser with a page loaded"
            ))
        }

        let truncated = String(pageText.prefix(4000))
        let summary = try await AIEnhancementService.shared.enhance(
            truncated,
            prompt: LLMPrompts.summarization
        )
        return .success(ActionSuccess(
            message: "Page summarized",
            resultText: summary,
            shouldPaste: true,
            metadata: ["url": context.url ?? ""]
        ))
    }

    // MARK: - Helpers

    private func frontmostBrowserBundleId() -> String? {
        let workspace = NSWorkspace.shared
        guard let frontApp = workspace.frontmostApplication else { return nil }
        let bid = frontApp.bundleIdentifier ?? ""
        if AppContext.browserBundleIds.contains(bid) {
            return bid
        }
        return nil
    }

    func appNameForBundleId(_ bid: String) -> String {
        switch bid {
        case "com.google.Chrome": return "Google Chrome"
        case "com.brave.Browser": return "Brave Browser"
        case "com.microsoft.edgemac": return "Microsoft Edge"
        case "com.vivaldi.Vivaldi": return "Vivaldi"
        case "com.apple.Safari": return "Safari"
        default: return "Safari"
        }
    }
}
