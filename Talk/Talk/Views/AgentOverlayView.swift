import SwiftUI

// MARK: - Agent Processing Overlay (floating HUD during agent execution)

struct AgentOverlayView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var pipeline: AgentPipeline

    var body: some View {
        VStack(spacing: 10) {
            // Animated icon
            ZStack {
                // Pulsing background circle
                Circle()
                    .fill(stepColor.opacity(0.15))
                    .frame(width: 44, height: 44)
                    .scaleEffect(isActive ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isActive)

                // Icon
                Image(systemName: currentIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(stepColor)
            }

            // Status text
            Text(statusText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .lineLimit(2)

            // Detail text (what was understood)
            if !detailText.isEmpty {
                Text(detailText)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // Animated progress dots
            if isActive {
                ProgressDotsView(color: stepColor)
                    .frame(height: 8)
            }

            // Result message
            if case .complete = pipeline.currentStep,
               let result = pipeline.lastResult {
                HStack(spacing: 4) {
                    Image(systemName: result.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(result.isSuccess ? .green : .red)
                        .font(.caption)
                    Text(result.message)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(width: 240)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.25), radius: 16, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(stepColor.opacity(0.4), lineWidth: 1.5)
        )
    }

    // MARK: - Computed Properties

    private var isActive: Bool {
        switch pipeline.currentStep {
        case .idle, .complete: return false
        default: return true
        }
    }

    private var currentIcon: String {
        switch pipeline.currentStep {
        case .idle: return "brain.head.profile"
        case .readingContext: return "eye.fill"
        case .classifying: return "brain.head.profile"
        case .executing(let action): return action.icon
        case .complete(true): return "checkmark.circle.fill"
        case .complete(false): return "xmark.circle.fill"
        }
    }

    private var stepColor: Color {
        switch pipeline.currentStep {
        case .idle: return .blue
        case .readingContext: return .cyan
        case .classifying: return .purple
        case .executing: return .blue
        case .complete(true): return .green
        case .complete(false): return .red
        }
    }

    private var statusText: String {
        // Use AppState's processingStatus if available, otherwise derive from step
        let stateStatus = appState.processingStatus
        if !stateStatus.isEmpty { return stateStatus }

        switch pipeline.currentStep {
        case .idle: return "Processing..."
        case .readingContext: return "Reading context..."
        case .classifying: return "Understanding command..."
        case .executing(let action): return executingText(for: action)
        case .complete(true): return "Done"
        case .complete(false): return "Failed"
        }
    }

    private var detailText: String {
        if let intent = pipeline.lastIntent {
            let content = intent.content.prefix(40)
            if !content.isEmpty {
                return "\"\(content)\(intent.content.count > 40 ? "..." : "")\""
            }
        }
        return ""
    }

    private func executingText(for action: ActionType) -> String {
        switch action {
        case .search: return "Searching..."
        case .open: return "Opening..."
        case .reply: return "Drafting reply..."
        case .create: return "Creating..."
        case .summarize: return "Summarizing..."
        case .transform: return "Transforming..."
        case .dictate: return "Typing..."
        }
    }
}

// MARK: - Animated Progress Dots

struct ProgressDotsView: View {
    let color: Color
    @State private var activeIndex = 0

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(color)
                    .frame(width: 6, height: 6)
                    .scaleEffect(i == activeIndex ? 1.3 : 0.8)
                    .opacity(i == activeIndex ? 1.0 : 0.3)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.3)) {
                    activeIndex = (activeIndex + 1) % 3
                }
            }
        }
    }
}

// MARK: - Preview

#Preview("Processing") {
    AgentOverlayView()
        .environmentObject(AppState.shared)
        .environmentObject(AgentPipeline.shared)
        .padding(40)
        .background(.black.opacity(0.3))
}
