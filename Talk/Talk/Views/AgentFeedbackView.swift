import SwiftUI

// MARK: - Agent Feedback View (shown during agent processing)

struct AgentFeedbackView: View {
    @ObservedObject var pipeline = AgentPipeline.shared

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: pipeline.currentStep.icon)
                    .foregroundStyle(stepColor)
                    .font(.title3)

                Text(pipeline.currentStep.displayText)
                    .font(.callout)
                    .foregroundStyle(.primary)

                Spacer()

                if case .executing(let action) = pipeline.currentStep {
                    Label(action.displayName, systemImage: action.icon)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(4)
                }
            }

            if let result = pipeline.lastResult {
                HStack {
                    Text(result.message)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                    Spacer()
                }
            }
        }
        .padding(12)
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }

    private var stepColor: Color {
        switch pipeline.currentStep {
        case .idle: return .secondary
        case .readingContext: return .blue
        case .classifying: return .purple
        case .executing: return .orange
        case .complete(true): return .green
        case .complete(false): return .red
        }
    }
}

// MARK: - Agent Settings Tab

struct AgentSettingsTab: View {
    @ObservedObject private var pipeline = AgentPipeline.shared
    @ObservedObject private var hotkeyManager = HotkeyManager.shared

    var body: some View {
        Form {
            Section("Agent Mode") {
                HStack {
                    Image(systemName: "brain")
                        .foregroundStyle(.blue)
                    VStack(alignment: .leading) {
                        Text("Voice-to-Action Agent")
                            .font(.headline)
                        Text("Speak commands to search, open apps, reply to emails, create notes, and more")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                HStack {
                    Text("Activation Hotkey")
                    Spacer()
                    Text(hotkeyManager.agentHotkey.description)
                        .foregroundStyle(.secondary)
                    Text("(change in Hotkeys tab)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Section("Behavior") {
                HStack {
                    Text("Confidence Threshold")
                    Spacer()
                    Text("\(Int(pipeline.confidenceThreshold * 100))%")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(value: $pipeline.confidenceThreshold, in: 0.5...0.95, step: 0.05)

                Text("Commands below this confidence level will default to regular dictation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Available Actions") {
                ForEach(ActionType.allCases, id: \.self) { action in
                    HStack {
                        Image(systemName: action.icon)
                            .frame(width: 20)
                            .foregroundStyle(.blue)
                        Text(action.displayName)
                        Spacer()
                        Text(actionExample(action))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Integrations") {
                integrationRow("Safari / Chrome", icon: "safari", available: true)
                integrationRow("Mail", icon: "envelope", available: true)
                integrationRow("Notes", icon: "note.text", available: true)
                integrationRow("Calendar", icon: "calendar", available: true)
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func integrationRow(_ name: String, icon: String, available: Bool) -> some View {
        HStack {
            Image(systemName: icon)
                .frame(width: 20)
                .foregroundStyle(available ? .green : .secondary)
            Text(name)
            Spacer()
            if available {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
            } else {
                Text("Not configured")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func actionExample(_ action: ActionType) -> String {
        switch action {
        case .dictate: return "\"Meeting notes: we discussed...\""
        case .transform: return "\"Make this formal\""
        case .search: return "\"Search for Swift tutorials\""
        case .open: return "\"Open Slack\""
        case .reply: return "\"Reply saying I'll be there at 3\""
        case .create: return "\"Create a note about...\""
        case .summarize: return "\"Summarize this\""
        }
    }
}
