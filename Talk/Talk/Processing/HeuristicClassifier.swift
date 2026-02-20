import Foundation

class HeuristicClassifier {
    static let shared = HeuristicClassifier()

    private struct Pattern {
        let regex: NSRegularExpression
        let action: ActionType
    }

    private let patterns: [Pattern]

    private init() {
        let definitions: [(String, ActionType)] = [
            ("^(?:search|look up|find|google)\\s+(?:for\\s+)?(.+)", .search),
            ("^(?:open|launch|start|switch to)\\s+(.+)", .open),
            ("^(?:draft|write|compose|send)\\s+(?:an?\\s+)?(?:email|mail|message)\\s+(?:to\\s+)?(.+)", .reply),
            ("^(?:email|mail)\\s+(.+)", .reply),
            ("^(?:reply|respond|answer)\\s+(?:saying|with|that)?\\s*(.+)", .reply),
            ("^(?:create|make|new|add)\\s+(?:a\\s+)?(.+)", .create),
            ("^(?:summarize|sum up|give me a summary|tldr)\\s*(.+)?", .summarize),
            ("^(?:make|convert|rewrite|format)\\s+(?:this|it|that)\\s+(.+)", .transform)
        ]

        patterns = definitions.compactMap { (pattern, action) in
            guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else {
                return nil
            }
            return Pattern(regex: regex, action: action)
        }
    }

    func classify(_ text: String) -> VoiceIntent {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let nsRange = NSRange(trimmed.startIndex..., in: trimmed)

        for pattern in patterns {
            guard let match = pattern.regex.firstMatch(in: trimmed, range: nsRange) else {
                continue
            }

            var content = trimmed
            if match.numberOfRanges > 1,
               let captureRange = Range(match.range(at: 1), in: trimmed) {
                let captured = String(trimmed[captureRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !captured.isEmpty {
                    content = captured
                }
            }

            return VoiceIntent(
                action: pattern.action,
                target: extractTarget(for: pattern.action, from: content),
                parameters: extractParameters(for: pattern.action, from: content, rawText: trimmed),
                content: content,
                rawText: text,
                confidence: 0.8
            )
        }

        // Default: dictation
        return VoiceIntent(
            action: .dictate,
            target: nil,
            parameters: [:],
            content: trimmed,
            rawText: text,
            confidence: 0.9
        )
    }

    private func extractTarget(for action: ActionType, from content: String) -> String? {
        switch action {
        case .open:
            return content
        case .search:
            return nil
        case .reply:
            return nil
        case .create, .summarize, .transform:
            return nil
        case .dictate:
            return nil
        }
    }

    private func extractParameters(for action: ActionType, from content: String, rawText: String) -> [String: String] {
        var params: [String: String] = [:]
        let lower = rawText.lowercased()

        // Detect email-related intents
        let emailKeywords = ["email", "mail", "draft", "compose"]
        if emailKeywords.contains(where: { lower.contains($0) }) {
            params["medium"] = "email"

            // Extract recipient: "email to Krista about project" → to="Krista", content after "about/saying/that"
            if let toRange = lower.range(of: "to ") {
                let afterTo = String(rawText[toRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                // Split on "about", "saying", "that", "regarding"
                let separators = [" about ", " saying ", " that ", " regarding ", " with "]
                var recipient = afterTo
                var body = ""
                for sep in separators {
                    if let sepRange = afterTo.lowercased().range(of: sep) {
                        recipient = String(afterTo[..<sepRange.lowerBound])
                        body = String(afterTo[sepRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                        break
                    }
                }
                params["to"] = recipient.trimmingCharacters(in: .whitespacesAndNewlines)
                if !body.isEmpty {
                    params["body"] = body
                }
            }
        }

        // Detect message-related intents
        let messageKeywords = ["text", "imessage", "message"]
        if messageKeywords.contains(where: { lower.contains($0) }) {
            params["medium"] = "message"
        }

        return params
    }
}
