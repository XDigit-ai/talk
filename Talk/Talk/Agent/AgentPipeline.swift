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

        // Register mail integration under all known email client bundle IDs
        let mail = MailIntegration.shared
        router.registerIntegration(mail, additionalBundleIds: [
            "com.readdle.SparkDesktop.appstore",  // Spark Desktop (App Store)
            "com.readdle.SparkDesktop",           // Spark Desktop (direct download)
            "com.readdle.smartemail-macos",       // Spark Classic
            "com.microsoft.Outlook"               // Outlook
        ])
        router.registerEmailIntegration(mail)

        router.registerIntegration(NotesIntegration.shared)

        let calendar = CalendarIntegration.shared
        router.registerIntegration(calendar)
        router.registerCalendarIntegration(calendar)

        let messages = MessagesIntegration.shared
        router.registerIntegration(messages)
        router.registerMessageIntegration(messages)
    }

    // MARK: - Main Pipeline

    /// Process a transcription through the full agent pipeline.
    /// Returns an ActionResult indicating what happened.
    func process(transcription: String) async throws -> ActionResult {
        debugLog("Pipeline started, transcription='\(transcription)'")

        // Step 1: Read context
        currentStep = .readingContext
        let context = ContextReader.readCurrentContext()
        debugLog("Context: app=\(context.appName) bundle=\(context.bundleIdentifier)")

        // Step 2: Classify intent
        currentStep = .classifying
        let intent: VoiceIntent
        do {
            intent = try await IntentClassifier.shared.classify(transcription, context: context)
            debugLog("Classification result: action=\(intent.action) confidence=\(intent.confidence) content='\(intent.content)'")
        } catch {
            // If classification fails, fall back to dictation
            debugLog("Classification FAILED: \(error.localizedDescription) — falling back to dictation")
            let fallback = VoiceIntent.dictation(from: transcription)
            return try await executeIntent(fallback, context: context)
        }

        lastIntent = intent

        // Step 3: Check confidence threshold
        if intent.confidence < confidenceThreshold {
            // Low confidence — fall back to dictation
            debugLog("Low confidence \(intent.confidence) < \(confidenceThreshold) — falling back to dictation")
            let fallback = VoiceIntent.dictation(from: transcription)
            return try await executeIntent(fallback, context: context)
        }

        // Step 4: Execute
        debugLog("Executing intent action=\(intent.action) content='\(intent.content)'")
        return try await executeIntent(intent, context: context)
    }

    private func executeIntent(_ intent: VoiceIntent, context: AppContext) async throws -> ActionResult {
        currentStep = .executing(intent.action)

        let result: ActionResult
        do {
            result = try await router.route(intent: intent, context: context)
        } catch {
            debugLog("Execution ERROR: \(error.localizedDescription)")
            result = .failure(ActionFailure(
                message: error.localizedDescription,
                error: error,
                isRecoverable: false
            ))
        }
        if case .failure(let f) = result {
            debugLog("Execution FAILED: \(f.message)")
        }

        lastResult = result
        currentStep = .complete(result.isSuccess)

        // Keep .complete visible for a moment before resetting to idle
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run { self.currentStep = .idle }
        }

        debugLog("Pipeline complete, success=\(result.isSuccess)")
        return result
    }

    // MARK: - Debug

    private func debugLog(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        let line = "[\(timestamp)] [AgentPipeline] \(message)\n"
        let path = "/tmp/dictai_agent.log"
        if let handle = FileHandle(forWritingAtPath: path) {
            handle.seekToEndOfFile()
            handle.write(line.data(using: .utf8)!)
            handle.closeFile()
        } else {
            try? line.write(toFile: path, atomically: true, encoding: .utf8)
        }
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
