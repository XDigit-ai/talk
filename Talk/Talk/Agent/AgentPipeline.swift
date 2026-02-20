import Foundation
import SwiftUI
import Combine

/// Orchestrates the full agent pipeline:
/// Transcription → Context Reading → Intent Classification → Action Routing → Execution
@MainActor
class AgentPipeline: ObservableObject {
    static let shared = AgentPipeline()

    // Published state for UI feedback
    @Published var currentStep: AgentStep = .idle
    @Published var lastIntent: VoiceIntent?
    @Published var lastResult: ActionResult?

    // Settings
    @AppStorage("agentConfidenceThreshold") var confidenceThreshold: Double = 0.7
    @AppStorage("agentRequireConfirmation") var requireConfirmation: Bool = false

    private let router = ActionRouter.shared

    private init() {
        registerIntegrations()
    }

    // MARK: - Integration Registration

    private func registerIntegrations() {
        router.registerIntegration(BrowserIntegration.shared)
        router.registerIntegration(MailIntegration.shared)
        router.registerIntegration(NotesIntegration.shared)
        router.registerIntegration(CalendarIntegration.shared)
    }

    // MARK: - Main Pipeline

    /// Process a transcription through the full agent pipeline.
    /// Returns an ActionResult indicating what happened.
    func process(transcription: String) async throws -> ActionResult {
        defer { currentStep = .idle }

        // Step 1: Read context
        currentStep = .readingContext
        let context = ContextReader.readCurrentContext()

        // Step 2: Classify intent
        currentStep = .classifying
        let intent: VoiceIntent
        do {
            intent = try await IntentClassifier.shared.classify(transcription, context: context)
        } catch {
            // If classification fails, fall back to dictation
            let fallback = VoiceIntent.dictation(from: transcription)
            return try await executeIntent(fallback, context: context)
        }

        lastIntent = intent

        // Step 3: Check confidence threshold
        if intent.confidence < confidenceThreshold {
            // Low confidence — fall back to dictation
            let fallback = VoiceIntent.dictation(from: transcription)
            return try await executeIntent(fallback, context: context)
        }

        // Step 4: Execute
        return try await executeIntent(intent, context: context)
    }

    private func executeIntent(_ intent: VoiceIntent, context: AppContext) async throws -> ActionResult {
        currentStep = .executing(intent.action)

        let result: ActionResult
        do {
            result = try await router.route(intent: intent, context: context)
        } catch {
            result = .failure(ActionFailure(
                message: error.localizedDescription,
                error: error,
                isRecoverable: false
            ))
        }

        lastResult = result
        currentStep = .complete(result.isSuccess)
        return result
    }
}

// MARK: - Agent Step (for UI feedback)

enum AgentStep: Equatable {
    case idle
    case readingContext
    case classifying
    case executing(ActionType)
    case complete(Bool)  // success or failure

    var displayText: String {
        switch self {
        case .idle: return ""
        case .readingContext: return "Reading context..."
        case .classifying: return "Understanding command..."
        case .executing(let action): return "Executing: \(action.displayName)..."
        case .complete(true): return "Done"
        case .complete(false): return "Failed"
        }
    }

    var icon: String {
        switch self {
        case .idle: return "circle"
        case .readingContext: return "eye"
        case .classifying: return "brain"
        case .executing: return "bolt.fill"
        case .complete(true): return "checkmark.circle.fill"
        case .complete(false): return "xmark.circle.fill"
        }
    }

    static func == (lhs: AgentStep, rhs: AgentStep) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle): return true
        case (.readingContext, .readingContext): return true
        case (.classifying, .classifying): return true
        case (.executing(let a), .executing(let b)): return a == b
        case (.complete(let a), .complete(let b)): return a == b
        default: return false
        }
    }
}
