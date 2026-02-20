import Foundation
import Combine

// MARK: - Workflow Models

struct Workflow {
    let name: String
    let steps: [WorkflowStep]
    let originalIntent: VoiceIntent

    var stepCount: Int { steps.count }
}

struct WorkflowStep {
    let index: Int
    let action: ActionType
    let description: String          // Human-readable step description
    let content: String              // Content/input for this step
    let parameters: [String: String]
    let usePreviousResult: Bool      // Whether to use output of previous step as input

    static func search(query: String) -> WorkflowStep {
        WorkflowStep(index: 0, action: .search, description: "Search for \(query)", content: query, parameters: [:], usePreviousResult: false)
    }

    static func summarize(text: String = "") -> WorkflowStep {
        WorkflowStep(index: 0, action: .summarize, description: "Summarize content", content: text, parameters: [:], usePreviousResult: text.isEmpty)
    }

    static func create(type: String, content: String = "") -> WorkflowStep {
        WorkflowStep(index: 0, action: .create, description: "Create \(type)", content: content, parameters: ["type": type], usePreviousResult: content.isEmpty)
    }

    static func reply(content: String = "") -> WorkflowStep {
        WorkflowStep(index: 0, action: .reply, description: "Send reply", content: content, parameters: [:], usePreviousResult: content.isEmpty)
    }
}

struct WorkflowProgress {
    let currentStep: Int
    let totalSteps: Int
    let stepDescription: String
    let isComplete: Bool
}

// MARK: - Workflow Engine

@MainActor
class WorkflowEngine: ObservableObject {
    static let shared = WorkflowEngine()

    @Published var isExecuting = false
    @Published var progress: WorkflowProgress?

    private let router = ActionRouter.shared

    private init() {}

    /// Attempt to decompose a complex intent into a multi-step workflow.
    /// Returns nil if the intent is a single action (no decomposition needed).
    func decomposeIfNeeded(intent: VoiceIntent, context: AppContext) async -> Workflow? {
        // Check for multi-step patterns in the raw text
        let text = intent.rawText.lowercased()

        // Pattern: "X and then Y" or "X and Y"
        let multiStepPatterns = [
            "and then", "and also", "then ", "after that",
            "and email", "and send", "and save", "and create"
        ]

        let isMultiStep = multiStepPatterns.contains { text.contains($0) }
        guard isMultiStep else { return nil }

        // Use LLM to decompose (if available), otherwise use simple heuristic
        if AIEnhancementService.shared.isConfigured {
            return await decomposeWithLLM(intent: intent, context: context)
        }

        return decomposeHeuristic(intent: intent)
    }

    /// Execute a workflow step by step
    func execute(workflow: Workflow, context: AppContext) async -> ActionResult {
        isExecuting = true
        defer { isExecuting = false; progress = nil }

        var lastResult: ActionResult?

        for (index, step) in workflow.steps.enumerated() {
            progress = WorkflowProgress(
                currentStep: index + 1,
                totalSteps: workflow.stepCount,
                stepDescription: step.description,
                isComplete: false
            )

            // Build intent for this step
            var stepContent = step.content
            if step.usePreviousResult, let prev = lastResult,
               case .success(let success) = prev, let text = success.resultText {
                stepContent = text
            }

            let stepIntent = VoiceIntent(
                action: step.action,
                target: nil,
                parameters: step.parameters,
                content: stepContent,
                rawText: stepContent,
                confidence: 1.0
            )

            do {
                lastResult = try await router.route(intent: stepIntent, context: context)
                if case .failure(let failure) = lastResult {
                    return .failure(ActionFailure(
                        message: "Workflow failed at step \(index + 1): \(failure.message)",
                        isRecoverable: failure.isRecoverable,
                        suggestion: failure.suggestion
                    ))
                }
            } catch {
                return .failure(ActionFailure(
                    message: "Workflow failed at step \(index + 1): \(error.localizedDescription)",
                    error: error,
                    isRecoverable: false
                ))
            }
        }

        progress = WorkflowProgress(
            currentStep: workflow.stepCount,
            totalSteps: workflow.stepCount,
            stepDescription: "Complete",
            isComplete: true
        )

        return lastResult ?? .success(ActionSuccess(message: "Workflow completed"))
    }

    // MARK: - Decomposition

    private func decomposeWithLLM(intent: VoiceIntent, context: AppContext) async -> Workflow? {
        let prompt = """
        Decompose this voice command into sequential steps. Each step is one of: dictate, transform, search, open, reply, create, summarize.

        Voice command: "\(intent.rawText)"
        Current app: \(context.appName)

        Respond with JSON array (no markdown):
        [{"action": "search", "description": "Search for X", "content": "search query"}]
        """

        do {
            let response = try await AIEnhancementService.shared.enhance(intent.rawText, prompt: prompt)
            guard let data = response.data(using: .utf8),
                  let stepsArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                return decomposeHeuristic(intent: intent)
            }

            let steps = stepsArray.enumerated().map { index, dict -> WorkflowStep in
                WorkflowStep(
                    index: index,
                    action: ActionType(rawValue: dict["action"] as? String ?? "dictate") ?? .dictate,
                    description: dict["description"] as? String ?? "Step \(index + 1)",
                    content: dict["content"] as? String ?? intent.content,
                    parameters: [:],
                    usePreviousResult: index > 0
                )
            }

            guard !steps.isEmpty else { return nil }
            return Workflow(name: "Multi-step", steps: steps, originalIntent: intent)
        } catch {
            return decomposeHeuristic(intent: intent)
        }
    }

    private func decomposeHeuristic(intent: VoiceIntent) -> Workflow? {
        let text = intent.rawText.lowercased()

        // Simple pattern: "search X and email/send Y"
        if text.contains("search") && (text.contains("and email") || text.contains("and send")) {
            let steps = [
                WorkflowStep.search(query: intent.content),
                WorkflowStep.summarize(),
                WorkflowStep.reply()
            ]
            return Workflow(name: "Search and email", steps: steps, originalIntent: intent)
        }

        // Pattern: "summarize and save to notes"
        if text.contains("summarize") && text.contains("note") {
            let steps = [
                WorkflowStep.summarize(text: intent.content),
                WorkflowStep.create(type: "note")
            ]
            return Workflow(name: "Summarize and save", steps: steps, originalIntent: intent)
        }

        return nil
    }
}
