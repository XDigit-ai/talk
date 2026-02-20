import SwiftUI
import AVFoundation

struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem {
                    Label("General", systemImage: "gear")
                }

            HotkeySettingsTab()
                .tabItem {
                    Label("Hotkeys", systemImage: "keyboard")
                }

            TranscriptionSettingsTab()
                .tabItem {
                    Label("Transcription", systemImage: "waveform")
                }

            EnhancementSettingsTab()
                .tabItem {
                    Label("Enhancement", systemImage: "sparkles")
                }

            AgentSettingsTab()
                .tabItem {
                    Label("Agent", systemImage: "brain")
                }

            PermissionsSettingsTab()
                .tabItem {
                    Label("Permissions", systemImage: "lock.shield")
                }
        }
        .frame(width: 520, height: 450)
    }
}

// MARK: - General Settings

struct GeneralSettingsTab: View {
    @ObservedObject private var appState = AppState.shared

    var body: some View {
        Form {
            Section {
                Picker("Processing Mode", selection: $appState.processingMode) {
                    ForEach(ProcessingMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                Picker("Recording Mode", selection: $appState.recordingMode) {
                    ForEach(RecordingMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }

                Text(appState.recordingMode.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Play sound feedback", isOn: $appState.playSoundFeedback)
                Toggle("Preserve clipboard after paste", isOn: $appState.preserveClipboard)
                Toggle("Add trailing space after paste", isOn: $appState.autoAddTrailingSpace)
                Toggle("Launch at login", isOn: $appState.launchAtLogin)
            }

            Section("Accessibility") {
                Toggle("Show Dock icon", isOn: $appState.showDockIcon)
                Text("Enable this if the menu bar icon is hidden behind the notch on your MacBook. The Dock icon provides an alternative way to access DictAI.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Hotkey Settings

struct HotkeySettingsTab: View {
    @ObservedObject private var hotkeyManager = HotkeyManager.shared

    var body: some View {
        Form {
            Section("Simple Mode Hotkey") {
                Picker("Hotkey", selection: $hotkeyManager.simpleHotkey) {
                    ForEach(HotkeyType.allCases, id: \.self) { key in
                        Text(key.description).tag(key)
                    }
                }

                Text("Transcribes and removes filler words only")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Agent Mode Hotkey") {
                Picker("Hotkey", selection: $hotkeyManager.agentHotkey) {
                    ForEach(HotkeyType.allCases, id: \.self) { key in
                        Text(key.description).tag(key)
                    }
                }

                Text("Voice-to-action: executes commands across apps (search, open, reply, create)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Tips:")
                        .font(.caption.bold())
                    Text("• Right Command (⌘) for dictation, Right Option (⌥) for agent mode")
                        .font(.caption)
                    Text("• Hold the key while speaking, release to process")
                        .font(.caption)
                    Text("• Agent mode requires Ollama or API key configured")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Transcription Settings

struct TranscriptionSettingsTab: View {
    @ObservedObject private var whisperState = WhisperState.shared

    var body: some View {
        Form {
            Section("Whisper Model") {
                Picker("Model", selection: $whisperState.selectedModel) {
                    ForEach(WhisperModel.allCases, id: \.self) { model in
                        VStack(alignment: .leading) {
                            Text(model.displayName)
                            Text("\(model.sizeDescription) • \(model.speedDescription)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .tag(model)
                    }
                }

                if whisperState.isModelDownloaded {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Model downloaded")
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                } else {
                    Button("Download Model") {
                        Task {
                            await whisperState.loadModel()
                        }
                    }
                    .disabled(whisperState.isLoading)
                }

                if whisperState.isLoading {
                    ProgressView("Downloading...")
                }

                if let error = whisperState.loadError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("Language") {
                Picker("Language", selection: $whisperState.selectedLanguage) {
                    Text("English").tag("en")
                    Text("Auto-detect").tag("auto")
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Enhancement Settings

struct EnhancementSettingsTab: View {
    @ObservedObject private var enhancementService = AIEnhancementService.shared
    @ObservedObject private var ollamaService = OllamaService.shared
    @ObservedObject private var ollamaManager = OllamaManager.shared
    @ObservedObject private var claudeService = ClaudeService.shared
    @ObservedObject private var openAIService = OpenAIService.shared
    @State private var showModelBrowser = false

    var body: some View {
        Form {
            Section("LLM Provider") {
                Picker("Provider", selection: $enhancementService.selectedProvider) {
                    ForEach(LLMProviderType.allCases, id: \.self) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .pickerStyle(.segmented)

                Text(providerDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    Image(systemName: enhancementService.isConfigured ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .foregroundStyle(enhancementService.isConfigured ? .green : .orange)
                    Text(enhancementService.configurationStatus)
                        .font(.caption)
                }
            }

            // Provider-specific settings
            providerSettingsSection

            Section("Custom Prompt") {
                Toggle("Use custom system prompt", isOn: $enhancementService.useCustomPrompt)

                if enhancementService.useCustomPrompt {
                    TextEditor(text: $enhancementService.customSystemPrompt)
                        .font(.system(.body, design: .monospaced))
                        .frame(height: 100)
                        .border(Color.secondary.opacity(0.3))
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .sheet(isPresented: $showModelBrowser) {
            ModelBrowserView()
        }
    }

    private var providerDescription: String {
        enhancementService.selectedProvider.description
    }

    @ViewBuilder
    private var providerSettingsSection: some View {
        switch enhancementService.selectedProvider {
        case .ollama:
            ollamaSettingsSection

        case .claude:
            Section("Claude API") {
                SecureField("API Key", text: Binding(
                    get: { claudeService.apiKey },
                    set: { claudeService.apiKey = $0 }
                ))
                .textFieldStyle(.roundedBorder)

                Picker("Model", selection: $claudeService.selectedModel) {
                    ForEach(claudeService.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }

                if claudeService.isConfigured {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("API Key configured")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

        case .openai:
            Section("OpenAI API") {
                SecureField("API Key", text: Binding(
                    get: { openAIService.apiKey },
                    set: { openAIService.apiKey = $0 }
                ))
                .textFieldStyle(.roundedBorder)

                Picker("Model", selection: $openAIService.selectedModel) {
                    ForEach(openAIService.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }

                if openAIService.isConfigured {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("API Key configured")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
    }

    // MARK: - Ollama Settings Section

    @ViewBuilder
    private var ollamaSettingsSection: some View {
        Section("Ollama Status") {
            // Installation status
            if ollamaManager.isInstallingOllama {
                // Show installation progress
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text(ollamaManager.installStatus)
                            .font(.callout)
                    }

                    ProgressView(value: ollamaManager.installProgress)

                    Text("\(Int(ollamaManager.installProgress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } else {
                HStack {
                    Image(systemName: ollamaManager.isInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(ollamaManager.isInstalled ? .green : .red)
                    Text(ollamaManager.isInstalled ? "Ollama installed" : "Ollama not installed")

                    Spacer()

                    if !ollamaManager.isInstalled {
                        Button("Install Now") {
                            Task {
                                let success = await ollamaManager.installOllama()
                                if success {
                                    // Auto-download a model after installation
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }

                if !ollamaManager.isInstalled {
                    Text("Click 'Install Now' to automatically download and set up Ollama. No terminal required!")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Or download manually...") {
                        ollamaManager.openOllamaDownloadPage()
                    }
                    .font(.caption)
                    .buttonStyle(.link)
                }
            }

            // Running status
            if ollamaManager.isInstalled && !ollamaManager.isInstallingOllama {
                HStack {
                    Image(systemName: ollamaManager.isRunning ? "bolt.circle.fill" : "bolt.slash.circle")
                        .foregroundStyle(ollamaManager.isRunning ? .green : .orange)
                    Text(ollamaManager.isRunning ? "Ollama running" : "Ollama not running")

                    Spacer()

                    if !ollamaManager.isRunning {
                        Button("Start") {
                            Task {
                                await ollamaManager.startOllama()
                            }
                        }
                        .font(.caption)
                    }
                }
            }

            if let error = ollamaManager.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }

        if ollamaManager.isRunning {
            Section("Model") {
                Picker("Active Model", selection: $ollamaService.selectedModel) {
                    if ollamaManager.installedModels.isEmpty {
                        Text(ollamaService.selectedModel).tag(ollamaService.selectedModel)
                    } else {
                        ForEach(ollamaManager.installedModels) { model in
                            HStack {
                                Text(model.name)
                                Spacer()
                                Text(model.size)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .tag(model.name)
                        }
                    }
                }

                Button("Download More Models...") {
                    showModelBrowser = true
                }
            }

            // Download progress
            if ollamaManager.isDownloading {
                Section("Downloading \(ollamaManager.downloadingModel ?? "")") {
                    ProgressView(value: ollamaManager.downloadProgress)
                    Text("\(Int(ollamaManager.downloadProgress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

// MARK: - Model Browser View

struct ModelBrowserView: View {
    @ObservedObject private var ollamaManager = OllamaManager.shared
    @ObservedObject private var ollamaService = OllamaService.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Download Models")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            .padding()

            Divider()

            // Recommended models
            List {
                Section("Recommended for Text Enhancement") {
                    ForEach(OllamaManager.recommendedModels) { model in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(model.name)
                                    .font(.body.bold())
                                Text(model.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(model.size)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if ollamaManager.isModelInstalled(model.name) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                            } else if ollamaManager.isDownloading && ollamaManager.downloadingModel == model.name {
                                ProgressView(value: ollamaManager.downloadProgress)
                                    .frame(width: 60)
                            } else {
                                Button("Download") {
                                    Task {
                                        let success = await ollamaManager.pullModel(model.name)
                                        if success {
                                            ollamaService.selectedModel = model.name
                                        }
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                                .disabled(ollamaManager.isDownloading)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if !ollamaManager.installedModels.isEmpty {
                    Section("Installed Models") {
                        ForEach(ollamaManager.installedModels) { model in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(model.name)
                                        .font(.body)
                                    Text(model.size)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if ollamaService.selectedModel == model.name {
                                    Text("Active")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }

                                Button(role: .destructive) {
                                    Task {
                                        await ollamaManager.deleteModel(model.name)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }
            }

            if let error = ollamaManager.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
            }
        }
        .frame(width: 500, height: 400)
        .onAppear {
            Task {
                await ollamaManager.refreshInstalledModels()
            }
        }
    }
}

// MARK: - Permissions Settings

struct PermissionsSettingsTab: View {
    @ObservedObject private var permissionManager = PermissionManager.shared

    var body: some View {
        Form {
            Section("Required Permissions") {
                // Microphone
                HStack {
                    Image(systemName: "mic.fill")
                        .foregroundStyle(permissionManager.microphoneStatus == .authorized ? .green : .orange)

                    VStack(alignment: .leading) {
                        Text("Microphone")
                            .font(.headline)
                        Text(permissionManager.microphoneStatusText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if permissionManager.microphoneStatus != .authorized {
                        Button("Grant") {
                            Task {
                                await permissionManager.requestMicrophonePermission()
                            }
                        }
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                }

                // Accessibility - only show in non-sandboxed mode
                if !permissionManager.isSandboxed {
                    HStack {
                        Image(systemName: "accessibility")
                            .foregroundStyle(permissionManager.accessibilityEnabled ? .green : .orange)

                        VStack(alignment: .leading) {
                            Text("Accessibility")
                                .font(.headline)
                            Text(permissionManager.accessibilityStatusText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        if !permissionManager.accessibilityEnabled {
                            Button("Open Settings") {
                                permissionManager.openAccessibilitySettings()
                            }
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                }
            }

            Section {
                if permissionManager.isSandboxed {
                    Text("Microphone access is required to record your voice. Transcribed text is copied to your clipboard - press ⌘V to paste.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Microphone access is required to record your voice. Accessibility access is required to auto-paste text into other applications.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Button("Refresh Permissions") {
                    permissionManager.checkAllPermissions()
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
