import AppKit
import ApplicationServices

/// Reads the active application's context using macOS Accessibility APIs.
/// Used to provide context-aware behavior for voice commands.
class ContextReader {

    /// Reads the current frontmost application context.
    /// Returns AppContext.empty if accessibility permissions are not granted.
    static func readCurrentContext() -> AppContext {
        guard AXIsProcessTrusted() else {
            return .empty
        }

        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let bundleId = frontApp.bundleIdentifier else {
            return .empty
        }

        let appName = frontApp.localizedName ?? "Unknown"
        let pid = frontApp.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)

        let windowTitle = getWindowTitle(appElement: appElement)
        let focusedRole = getFocusedElementRole(appElement: appElement)
        let selectedText = PasteEligibilityService.getSelectedText()
        let url = AppContext.browserBundleIds.contains(bundleId)
            ? getBrowserURL(bundleId: bundleId)
            : nil

        return AppContext(
            bundleIdentifier: bundleId,
            appName: appName,
            windowTitle: windowTitle,
            focusedElementRole: focusedRole,
            selectedText: selectedText,
            url: url
        )
    }

    // MARK: - AX Helpers

    /// Gets the title of the frontmost window.
    private static func getWindowTitle(appElement: AXUIElement) -> String? {
        var windowValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedWindowAttribute as CFString,
            &windowValue
        )
        guard result == .success else { return nil }

        var titleValue: AnyObject?
        let titleResult = AXUIElementCopyAttributeValue(
            windowValue as! AXUIElement,
            kAXTitleAttribute as CFString,
            &titleValue
        )
        guard titleResult == .success, let title = titleValue as? String else { return nil }
        return title.isEmpty ? nil : title
    }

    /// Gets the accessibility role of the currently focused UI element.
    private static func getFocusedElementRole(appElement: AXUIElement) -> String? {
        var focusedElement: AnyObject?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )
        guard result == .success else { return nil }

        var roleValue: AnyObject?
        let roleResult = AXUIElementCopyAttributeValue(
            focusedElement as! AXUIElement,
            kAXRoleAttribute as CFString,
            &roleValue
        )
        guard roleResult == .success, let role = roleValue as? String else { return nil }
        return role
    }

    // MARK: - Browser URL

    /// Gets the current URL from a known browser using AppleScript.
    private static func getBrowserURL(bundleId: String) -> String? {
        let script: String? = switch bundleId {
        case "com.apple.Safari":
            "tell application \"Safari\" to return URL of front document"
        case "com.google.Chrome":
            "tell application \"Google Chrome\" to return URL of active tab of front window"
        case "com.brave.Browser":
            "tell application \"Brave Browser\" to return URL of active tab of front window"
        case "com.microsoft.edgemac":
            "tell application \"Microsoft Edge\" to return URL of active tab of front window"
        case "company.thebrowser.Browser":
            "tell application \"Arc\" to return URL of active tab of front window"
        default:
            nil
        }

        guard let script else { return nil }

        let appleScript = NSAppleScript(source: script)
        var error: NSDictionary?
        let result = appleScript?.executeAndReturnError(&error)

        guard error == nil, let urlString = result?.stringValue, !urlString.isEmpty else {
            return nil
        }
        return urlString
    }
}
