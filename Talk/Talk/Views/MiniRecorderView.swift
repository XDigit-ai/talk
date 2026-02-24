import SwiftUI

struct MiniRecorderView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var whisperState: WhisperState
    @ObservedObject var pipeline = AgentPipeline.shared

    var body: some View {
        let activeMode = appState.currentSessionMode ?? appState.processingMode
        let isAgentProcessing = !appState.isRecording && appState.isProcessing && activeMode == .agent

        VStack(spacing: 12) {
            if isAgentProcessing {
                // Agent processing view
                agentProcessingView
            } else {
                // Normal recording view
                recordingView(activeMode: activeMode)
            }
        }
        .padding(16)
        .frame(width: 280, height: isAgentProcessing ? 120 : 100)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(radius: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isAgentProcessing ? agentStepColor.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.2), value: isAgentProcessing)
    }

    // MARK: - Recording View

    private func recordingView(activeMode: ProcessingMode) -> some View {
        VStack(spacing: 12) {
            // Audio Visualizer
            AudioVisualizerView(level: appState.audioLevel)
                .frame(height: 40)

            // Status Row
            HStack {
                // Recording indicator
                HStack(spacing: 6) {
                    Circle()
                        .fill(.red)
                        .frame(width: 10, height: 10)
                        .opacity(appState.isRecording ? 1 : 0)

                    Text(appState.formattedDuration)
                        .font(.system(.title3, design: .monospaced))
                        .monospacedDigit()
                }

                Spacer()

                // Mode indicator
                Label(activeMode.rawValue, systemImage: activeMode.icon)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(modeColor(activeMode))
                    .cornerRadius(4)

                Spacer()

                // Cancel button
                Button {
                    appState.cancelRecording()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.escape, modifiers: [])
            }
        }
    }

    // MARK: - Agent Processing View

    private var agentProcessingView: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                // Animated step icon
                ZStack {
                    Circle()
                        .fill(agentStepColor.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: agentStepIcon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(agentStepColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(agentStatusText)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.primary)

                    if let intent = pipeline.lastIntent,
                       case .executing = pipeline.currentStep {
                        let preview = String(intent.content.prefix(35))
                        Text("\"\(preview)\(intent.content.count > 35 ? "..." : "")\"")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()
            }

            // Animated progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.primary.opacity(0.1))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(agentStepColor)
                        .frame(width: agentProgress * geo.size.width, height: 4)
                        .animation(.easeInOut(duration: 0.3), value: pipeline.currentStep)
                }
            }
            .frame(height: 4)

            // Step labels
            HStack(spacing: 0) {
                stepLabel("Context", step: .readingContext)
                Spacer()
                stepLabel("Classify", step: .classifying)
                Spacer()
                stepLabel("Execute", step: nil) // executing covers multiple action types
            }
            .font(.system(size: 9))
        }
    }

    private func stepLabel(_ text: String, step: AgentStep?) -> some View {
        let isActive: Bool
        let isPast: Bool

        switch pipeline.currentStep {
        case .readingContext:
            isActive = (step == .readingContext)
            isPast = false
        case .classifying:
            isActive = (step == .classifying)
            isPast = (step == .readingContext)
        case .executing:
            isActive = (step == nil) // "Execute" label
            isPast = true
        case .complete:
            isActive = false
            isPast = true
        default:
            isActive = false
            isPast = false
        }

        return Text(text)
            .foregroundStyle(isActive ? agentStepColor : .secondary)
            .opacity(isActive ? 1.0 : (isPast ? 0.7 : 0.4))
            .fontWeight(isActive ? .medium : .regular)
    }

    // MARK: - Agent Helpers

    private var agentStepIcon: String {
        switch pipeline.currentStep {
        case .idle: return "brain.head.profile"
        case .readingContext: return "eye.fill"
        case .classifying: return "brain.head.profile"
        case .executing(let action): return action.icon
        case .complete(true): return "checkmark.circle.fill"
        case .complete(false): return "xmark.circle.fill"
        }
    }

    private var agentStepColor: Color {
        switch pipeline.currentStep {
        case .idle: return .blue
        case .readingContext: return .cyan
        case .classifying: return .purple
        case .executing: return .blue
        case .complete(true): return .green
        case .complete(false): return .red
        }
    }

    private var agentStatusText: String {
        switch pipeline.currentStep {
        case .idle: return "Processing..."
        case .readingContext: return "Reading context..."
        case .classifying: return "Understanding..."
        case .executing(let action):
            switch action {
            case .search: return "Searching..."
            case .open: return "Opening..."
            case .reply: return "Drafting reply..."
            case .create: return "Creating..."
            case .summarize: return "Summarizing..."
            case .transform: return "Transforming..."
            case .dictate: return "Typing..."
            }
        case .complete(true): return "Done!"
        case .complete(false): return "Failed"
        }
    }

    private var agentProgress: CGFloat {
        switch pipeline.currentStep {
        case .idle: return 0.05
        case .readingContext: return 0.25
        case .classifying: return 0.55
        case .executing: return 0.85
        case .complete: return 1.0
        }
    }

    // MARK: - Helpers

    private func modeColor(_ mode: ProcessingMode) -> Color {
        switch mode {
        case .simple: return Color.gray.opacity(0.2)
        case .advanced: return Color.purple.opacity(0.3)
        case .agent: return Color.blue.opacity(0.3)
        }
    }
}

// MARK: - Audio Visualizer

struct AudioVisualizerView: View {
    let level: Float
    let barCount = 20

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(barColor(for: index))
                        .frame(width: barWidth(in: geometry), height: barHeight(for: index, in: geometry))
                        .animation(.linear(duration: 0.05), value: level)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func barWidth(in geometry: GeometryProxy) -> CGFloat {
        let totalSpacing = CGFloat(barCount - 1) * 3
        return (geometry.size.width - totalSpacing) / CGFloat(barCount)
    }

    private func barHeight(for index: Int, in geometry: GeometryProxy) -> CGFloat {
        let maxHeight = geometry.size.height
        let minHeight: CGFloat = 4

        let centerIndex = barCount / 2
        let distanceFromCenter = abs(index - centerIndex)
        let normalizedDistance = CGFloat(distanceFromCenter) / CGFloat(centerIndex)

        let heightMultiplier = 1.0 - (normalizedDistance * 0.5)
        let levelHeight = CGFloat(level) * maxHeight * heightMultiplier

        let randomFactor = CGFloat.random(in: 0.8...1.2)

        return max(minHeight, min(maxHeight, levelHeight * randomFactor))
    }

    private func barColor(for index: Int) -> Color {
        let intensity = CGFloat(level)
        if intensity > 0.8 {
            return .red
        } else if intensity > 0.5 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Preview

#Preview("Recording") {
    MiniRecorderView()
        .environmentObject({
            let state = AppState.shared
            return state
        }())
        .environmentObject(WhisperState.shared)
        .background(.black.opacity(0.3))
        .padding(50)
}
