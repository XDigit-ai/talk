import Foundation

@MainActor
class IntentClassifier {
    static let shared = IntentClassifier()

    private init() {}

    func classify(_ transcription: String, context: AppContext) async throws -> VoiceIntent {
        let service = AIEnhancementService.shared

        guard service.isConfigured else {
            return HeuristicClassifier.shared.classify(transcription)
        }

        let prompt = """
        \(LLMPrompts.intentClassification)

        Context:
        \(context.promptSummary)

        User said: \(transcription)
        """

        do {
            let response = try await service.enhance(transcription, prompt: prompt)
            let intent = try parseResponse(response, rawText: transcription)

            if intent.confidence < 0.7 {
                return VoiceIntent.dictation(from: transcription)
            }

            // Safety net: if LLM says "dictate" but text contains strong action keywords,
            // try the heuristic classifier which may catch it
            if intent.action == .dictate {
                let heuristic = HeuristicClassifier.shared.classify(transcription)
                if heuristic.action != .dictate {
                    return heuristic
                }
            }

            return intent
        } catch {
            return HeuristicClassifier.shared.classify(transcription)
        }
    }

    private func parseResponse(_ response: String, rawText: String) throws -> VoiceIntent {
        // Strip markdown code fences if present
        let cleaned = response
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = cleaned.data(using: .utf8) else {
            throw LLMError.invalidResponse
        }

        let decoded = try JSONDecoder().decode(IntentClassificationResponse.self, from: data)
        return decoded.toVoiceIntent(rawText: rawText)
    }
}
