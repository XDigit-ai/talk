import Foundation

// MARK: - App Context

/// Represents the current state of the user's active application.
/// Used by the intent classifier and action handlers to make context-aware decisions.
struct AppContext {
    let bundleIdentifier: String   // e.g., "com.apple.mail"
    let appName: String            // e.g., "Mail"
    let windowTitle: String?       // Current window title
    let focusedElementRole: String? // "AXTextArea", "AXTextField", etc.
    let selectedText: String?      // Currently selected text
    let url: String?               // For browsers: current URL

    /// Empty context (no permissions or no frontmost app)
    static let empty = AppContext(
        bundleIdentifier: "unknown",
        appName: "Unknown",
        windowTitle: nil,
        focusedElementRole: nil,
        selectedText: nil,
        url: nil
    )

    /// Whether the active app is a web browser
    var isBrowser: Bool {
        Self.browserBundleIds.contains(bundleIdentifier)
    }

    /// Whether the active app is an email client
    var isEmailClient: Bool {
        Self.emailBundleIds.contains(bundleIdentifier)
    }

    /// Whether the active app is a messaging app
    var isMessagingApp: Bool {
        Self.messagingBundleIds.contains(bundleIdentifier)
    }

    /// Whether there is editable text focused
    var hasEditableField: Bool {
        focusedElementRole == "AXTextArea" || focusedElementRole == "AXTextField"
    }

    /// Context summary for LLM prompts (keep short to minimize tokens)
    var promptSummary: String {
        var parts: [String] = ["App: \(appName)"]
        if let title = windowTitle { parts.append("Window: \(title)") }
        if let text = selectedText?.prefix(200) { parts.append("Selected: \(text)") }
        if let url = url { parts.append("URL: \(url)") }
        return parts.joined(separator: "\n")
    }

    // MARK: - Known Bundle IDs

    static let browserBundleIds: Set<String> = [
        "com.apple.Safari",
        "com.google.Chrome",
        "com.brave.Browser",
        "org.mozilla.firefox",
        "com.microsoft.edgemac",
        "com.vivaldi.Vivaldi",
        "company.thebrowser.Browser"  // Arc
    ]

    static let emailBundleIds: Set<String> = [
        "com.apple.mail",
        "com.microsoft.Outlook",
        "com.readdle.smartemail-macos"  // Spark
    ]

    static let messagingBundleIds: Set<String> = [
        "com.apple.MobileSMS",         // Messages
        "com.tinyspeck.slackmacgap",   // Slack
        "ru.keepcoder.Telegram",        // Telegram
        "com.hnc.Discord"              // Discord
    ]
}
