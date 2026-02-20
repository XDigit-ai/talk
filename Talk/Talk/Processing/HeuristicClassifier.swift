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
                parameters: [:],
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
}
