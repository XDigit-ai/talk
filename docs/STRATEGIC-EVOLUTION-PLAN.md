# Strategic Evolution Plan: From Dictation Tool to Voice-to-Action AI Agent

**Document Version:** 1.0
**Date:** February 21, 2026
**Classification:** Internal Strategy Document

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Competitive Analysis](#2-competitive-analysis)
3. [Product Naming Strategy](#3-product-naming-strategy)
4. [Feature Roadmap](#4-feature-roadmap)
5. [Technical Architecture](#5-technical-architecture)
6. [Integration Strategy](#6-integration-strategy)
7. [Differentiation Strategy](#7-differentiation-strategy)
8. [Go-to-Market Strategy](#8-go-to-market-strategy)
9. [Execution Timeline](#9-execution-timeline)
10. [Risk Mitigation](#10-risk-mitigation)
11. [Appendix: Implementation Reference](#appendix-implementation-reference)

---

## 1. Executive Summary

### Situation

Talk (branded DictAI Pro) is a well-architected native macOS dictation app with local Whisper transcription, multi-provider LLM integration, and a clean protocol-based architecture. The app currently operates as a voice-to-text tool with basic LLM enhancement capabilities.

### Opportunity

The voice-to-action agent market on macOS is nascent. Hey Lemon (heylemon.ai) is an early mover positioning as "the first AI agent that turns voice instructions into finished tasks." The market is shifting from voice-to-text toward voice-to-action, where spoken commands trigger multi-step workflows across applications.

### Key Findings

1. **Talk has a significant technical moat**: Local Whisper transcription (zero cloud dependency for STT), local Ollama LLM support, and existing Accessibility API integration (CGEvent, AXUIElement) provide a foundation that competitors must build from scratch.
2. **Hey Lemon has a head start on integrations** but appears to rely on cloud infrastructure, creating a privacy vulnerability and latency penalty.
3. **The architectural gap is smaller than it appears**: Talk already has 70% of the infrastructure needed. The missing pieces are intent classification, an action execution layer, and app context awareness.
4. **Privacy-first local processing is a durable differentiator** in an era of increasing data sensitivity concerns.

### Recommendations

- **Rebrand** from DictAI to a name that signals agent capability (top recommendation: "Vox" or "Sayd")
- **Execute a 3-phase evolution** over 6 months to transform from dictation tool to voice-to-action agent
- **Lead with the privacy narrative**: "Your voice, your Mac, your data - never leaves your machine"
- **Target power users first** (developers, writers, knowledge workers) before expanding to general productivity users
- **Maintain the local-first architecture** as the primary differentiator against cloud-dependent competitors

---

## 2. Competitive Analysis

### 2.1 DictAI vs Hey Lemon: Feature Matrix

| Capability | DictAI (Current) | Hey Lemon | Gap |
|---|---|---|---|
| Voice activation | Right Cmd/Option hotkeys | fn key | Parity (configurable is better) |
| Speech-to-text | Local Whisper (Metal GPU) | Cloud-based (likely) | DictAI advantage |
| Text enhancement | Local Ollama + Cloud LLMs | Cloud LLM | DictAI advantage (choice) |
| Paste at cursor | Yes (CGEvent Cmd+V) | Yes | Parity |
| Voice directions | Regex patterns (basic) | Natural language | Hey Lemon advantage |
| Intent classification | None | Yes (core feature) | Critical gap |
| App integrations | None (paste only) | Gmail, Docs, Slack, Notion, Sheets, browsers | Critical gap |
| Multi-step workflows | None | Yes | Critical gap |
| Screen context | None (code exists for AX) | Yes ("works over any app") | Moderate gap |
| Research/web search | None | Yes | Moderate gap |
| Calendar actions | None | Yes | Moderate gap |
| Privacy/local processing | Full local option | Cloud-dependent | DictAI advantage |
| Offline capability | Yes (Whisper + Ollama) | No | DictAI advantage |
| Provider flexibility | Ollama/Claude/OpenAI | Single provider (likely OpenAI) | DictAI advantage |
| Pricing | Free/open | Free (30-day trial, subscription coming) | Temporary parity |
| Platform | macOS 14+ | macOS | Parity |

### 2.2 SWOT Analysis

**Strengths**
- Local-first architecture with zero cloud dependency option
- Metal-accelerated Whisper transcription (fast, private)
- Protocol-based LLM layer easily extensible to new providers
- Existing Accessibility API integration (AXUIElement for reading UI, CGEvent for keyboard simulation)
- Full Ollama lifecycle management (install, launch, model management)
- Clean Swift/SwiftUI codebase with clear separation of concerns
- Dual-hotkey system with configurable activation keys
- Clipboard preservation and paste eligibility detection

**Weaknesses**
- No intent classification beyond regex voice directions
- No action execution layer (only paste-at-cursor)
- No app context awareness (cannot read what is on screen)
- No integration with external apps (email, calendar, documents)
- Voice direction detection limited to formatting commands
- No transcription history or learning from user patterns
- Single-action model (record -> transcribe -> paste) with no agent loop

**Opportunities**
- Hey Lemon is pre-revenue and likely pre-scale; market is wide open
- Apple's increasing investment in on-device ML (Core ML, Metal) aligns with local-first approach
- Growing privacy regulation (GDPR, state privacy laws) makes local processing increasingly valuable
- macOS Accessibility APIs are powerful and underutilized by competitors
- AppleScript/JXA provide deep app integration without requiring app-specific APIs
- Shortcuts framework enables system-level automation integration
- Tool-calling capabilities in modern LLMs (Ollama supports function calling) enable structured action planning

**Threats**
- Apple could build voice-to-action into macOS natively (Siri evolution)
- Hey Lemon or similar competitors could achieve network effects with integrations
- Cloud LLM providers (OpenAI, Anthropic) could ship native Mac agents
- Local LLM quality may lag behind cloud models for complex reasoning
- Accessibility API changes in future macOS versions could break functionality

### 2.3 Porter's Five Forces Assessment

| Force | Intensity | Analysis |
|---|---|---|
| New entrants | High | Low barrier for basic voice apps; high barrier for deep Mac integration |
| Supplier power | Medium | LLM providers have leverage but multiple options exist; Ollama reduces dependency |
| Buyer power | High | Free alternatives exist; switching costs are low |
| Substitutes | Medium | Apple Dictation, Siri, keyboard shortcuts are partial substitutes |
| Rivalry | Low-Medium | Few direct competitors in local-first voice-to-action; Hey Lemon is primary |

---

## 3. Product Naming Strategy

The evolution from dictation to voice-to-action requires a name that conveys agency, intelligence, and action rather than just transcription.

### 3.1 Naming Criteria

- Conveys "agent" or "action" capability, not just dictation
- Works as both a product name and a verb ("I'll Vox that")
- Memorable, short (1-2 syllables preferred), modern
- Available as a .ai or .app domain
- No direct trademark conflicts in the productivity software space
- Suggests voice/speech origin

### 3.2 Name Options (Ranked)

| Rank | Name | Rationale | Verb Usage | Domain Availability |
|---|---|---|---|---|
| 1 | **Vox** | Latin for "voice"; short, powerful, techy. Signals voice-first but not limited to text. | "Just Vox it" | vox.ai (check), usevox.app |
| 2 | **Sayd** | Phonetic spelling of "said" with a modern twist. Past tense implies completion - you said it, it is done. | "I Sayd that email" | sayd.ai (check) |
| 3 | **Hermes** | Greek messenger god. Conveys speed, delivery, and acting on your behalf. Premium feel. | "Hermes that to John" | hermes.ai (check) |
| 4 | **Utter** | Means to speak; also means "complete/absolute." Double meaning: voice input + total execution. | "Utter a reply" | utter.ai (check) |
| 5 | **Invoke** | To call upon, to summon action. Technical enough for developers, clear enough for everyone. | "Invoke a summary" | invoke.ai (may conflict) |
| 6 | **Verbix** | From "verb" (action word) + suffix suggesting technology. Unique, trademarkable. | "Verbix that report" | verbix.ai (check) |
| 7 | **Dispatch** | Means to send off quickly, to deal with promptly. Strong action connotation. | "Dispatch a reply" | dispatch.ai (check) |

### 3.3 Recommendation

**Primary: Vox** - It is the strongest candidate. Short, memorable, immediately associated with voice, works naturally as a verb, and has a premium feel without being pretentious. The name scales from dictation ("Vox this email") to complex agent actions ("Vox, research competitor pricing and create a summary doc").

**Backup: Sayd** - If Vox has domain/trademark conflicts, Sayd is the best alternative. The past-tense framing ("already done") perfectly captures the voice-to-action value proposition.

---

## 4. Feature Roadmap

### 4.1 Phase 1: MVP Agent (Weeks 1-8)

**Goal:** Transform from "voice-to-text" to "voice-to-action" with 5 core actions.

#### 4.1.1 Intent Classification Engine

Replace the current regex-based `detectVoiceDirection()` in `AIEnhancementService.swift` with an LLM-powered intent classifier.

**Current state** (from `AIEnhancementService.swift` lines 80-127):
```swift
// Current: Regex patterns like "make this formal:", "format as bullet points:"
// Limited to formatting directions only
func detectVoiceDirection(in text: String) -> (cleanedText: String, direction: String?)
```

**Target state:**
```swift
// New: LLM-based intent classification returning structured actions
struct VoiceIntent {
    let action: ActionType       // .dictate, .email, .search, .open, .create, .edit
    let target: String?          // "email", "google doc", "calendar"
    let parameters: [String: Any] // Action-specific params
    let rawText: String          // Original transcription
    let confidence: Double       // 0.0-1.0
}

enum ActionType: String, Codable {
    case dictate        // Default: paste text at cursor (current behavior)
    case reply          // Reply to current email/message
    case search         // Search the web or local files
    case open           // Open an app or URL
    case create         // Create a document, event, reminder
    case summarize      // Summarize current content
    case transform      // Transform selected text (current "advanced" mode)
}
```

**Implementation approach:**
- Use Ollama function calling (tool_call) with a classification prompt
- Fall back to regex patterns if LLM is unavailable (preserves offline degradation)
- Confidence threshold: actions below 0.7 confidence fall back to dictation mode
- Response time budget: < 500ms for classification (use small model like qwen2.5:3b)

#### 4.1.2 Action Execution Layer

New module: `Agent/` directory containing the action execution pipeline.

**Five MVP actions:**

| Action | Trigger Examples | Execution Method |
|---|---|---|
| **Dictate** (default) | "Meeting notes: discussed Q3 targets..." | Current paste-at-cursor (unchanged) |
| **Transform** | "Make this formal", "Summarize this" | Read selected text via AX API, LLM process, paste result |
| **Search** | "Search for Swift accessibility API docs" | Open default browser with search URL |
| **Open** | "Open Slack", "Open the project folder" | NSWorkspace.shared.open() or AppleScript |
| **Reply** | "Reply saying I'll be there at 3pm" | Detect active app, compose reply via AppleScript |

#### 4.1.3 Screen Context Awareness (Basic)

Leverage the existing `PasteEligibilityService` (which already uses `AXUIElementCreateApplication` and `kAXFocusedUIElementAttribute`) to read context from the active application.

**Current state** (from `CursorPaster.swift` lines 136-218):
```swift
// Already implemented:
static func canPaste() -> Bool     // Checks focused element
static func getSelectedText() -> String?  // Reads selected text via AX
```

**Extension needed:**
```swift
struct AppContext {
    let bundleIdentifier: String   // e.g., "com.apple.mail"
    let appName: String            // e.g., "Mail"
    let windowTitle: String?       // Current window title
    let focusedElementRole: String? // "AXTextArea", "AXTextField", etc.
    let selectedText: String?      // Currently selected text
    let url: String?               // For browsers: current URL
}

class ContextReader {
    static func readCurrentContext() -> AppContext
}
```

#### 4.1.4 Processing Pipeline Refactor

Refactor `AppState.processAudio()` from a linear pipeline to a branching agent pipeline.

**Current flow** (from `AppState.swift` lines 172-248):
```
Record -> Transcribe -> (Simple cleanup | LLM enhance) -> Paste
```

**New flow:**
```
Record -> Transcribe -> Classify Intent -> Route to Action Handler
                                              |
                          +-------------------+-------------------+
                          |         |         |         |         |
                       Dictate  Transform   Search    Open     Reply
                          |         |         |         |         |
                        Paste    AX Read    Browser  NSWork   AppleScript
                                 + LLM      URL      space    + Compose
                                 + Paste
```

#### 4.1.5 Third Hotkey: Agent Mode

Add a third hotkey specifically for agent mode (voice-to-action).

**Current** (from `HotkeyManager.swift`):
- Right Cmd = Simple mode (cleanup)
- Right Option = Advanced mode (LLM enhance)

**New:**
- Right Cmd = Simple mode (unchanged)
- Right Option = Advanced mode (unchanged)
- **fn key = Agent mode** (intent classification + action execution)

This preserves backward compatibility while adding the new capability. Users who only want dictation are unaffected.

### 4.2 Phase 2: Integration Layer (Weeks 9-16)

**Goal:** Deep integration with 8 core Mac apps via AppleScript/JXA and Accessibility APIs.

#### 4.2.1 App Integration Framework

```swift
protocol AppIntegration {
    var bundleIdentifier: String { get }
    var supportedActions: [ActionType] { get }
    func execute(intent: VoiceIntent, context: AppContext) async throws -> ActionResult
    func readContext() async throws -> AppSpecificContext
}
```

#### 4.2.2 Priority Integrations

| Priority | App | Actions | Implementation |
|---|---|---|---|
| P0 | **Safari/Chrome** | Search, navigate, read page content | AppleScript + JXA for URL/tab control |
| P0 | **Mail** | Reply, compose, summarize thread | AppleScript (Mail.app has rich scripting) |
| P0 | **Notes** | Create note, append to note | AppleScript |
| P1 | **Calendar** | Create event, check schedule | EventKit framework (native) |
| P1 | **Reminders** | Create reminder, list reminders | EventKit framework (native) |
| P1 | **Messages** | Send message, reply | AppleScript (limited but functional) |
| P2 | **Slack** | Post message, reply in thread | Slack API (OAuth) or AppleScript |
| P2 | **Google Docs/Gmail** | Via browser automation | JXA browser scripting |

#### 4.2.3 Multi-Step Workflow Engine

```swift
struct Workflow {
    let steps: [WorkflowStep]
    let context: AppContext
}

struct WorkflowStep {
    let action: ActionType
    let target: String
    let parameters: [String: Any]
    let dependsOn: Int?  // Index of prerequisite step
}

// Example: "Research Swift accessibility APIs and email me a summary"
// Step 1: Search web for "Swift accessibility API"
// Step 2: Read top 3 results
// Step 3: Summarize with LLM
// Step 4: Compose email with summary
```

#### 4.2.4 Streaming Feedback UI

Replace the simple "Processing..." status with a real-time action feed showing what the agent is doing.

```
[Recording...] "Research competitor pricing and send to team"
[Classifying...] Detected: multi-step workflow (3 actions)
[Step 1/3] Searching web for "competitor pricing analysis"...
[Step 2/3] Summarizing search results...
[Step 3/3] Composing email to team...
[Complete] Email drafted in Mail - review and send?
```

### 4.3 Phase 3: Advanced Agent (Weeks 17-24)

**Goal:** Learning, personalization, and autonomous multi-step execution.

#### 4.3.1 Action History and Learning

```swift
// SwiftData model for action history
@Model
class ActionRecord {
    var timestamp: Date
    var rawTranscription: String
    var classifiedIntent: ActionType
    var wasCorrect: Bool          // User confirmed or corrected
    var executionTime: TimeInterval
    var appContext: String         // Serialized AppContext
    var userCorrection: String?   // If user changed the action
}
```

Use action history to:
- Improve intent classification (few-shot examples from user's own patterns)
- Pre-populate likely actions based on context + time of day
- Suggest automations ("You reply to standup emails every morning - want me to auto-draft?")

#### 4.3.2 Custom Automation Builder

Allow users to define named automations triggered by voice:

```
"Morning routine" ->
  1. Open Mail, summarize unread
  2. Open Calendar, read today's schedule
  3. Open Slack, check mentions
  4. Create a "Daily Plan" note with summary
```

#### 4.3.3 Agentic Loop with Verification

```swift
class AgentLoop {
    func execute(intent: VoiceIntent) async -> AgentResult {
        // 1. Plan: Break intent into steps
        let plan = await planner.createPlan(for: intent)

        // 2. Verify: Show plan to user for approval (optional, configurable)
        if settings.requireApproval && plan.isDestructive {
            let approved = await ui.requestApproval(plan)
            guard approved else { return .cancelled }
        }

        // 3. Execute: Run each step
        for step in plan.steps {
            let result = try await executor.execute(step)

            // 4. Observe: Check if action succeeded
            let verification = await verifier.verify(step, result: result)

            if !verification.success {
                // 5. Retry or recover
                let recovery = await planner.recover(from: verification.error, step: step)
                try await executor.execute(recovery)
            }
        }

        // 6. Report: Summarize what was done
        return await reporter.summarize(plan)
    }
}
```

#### 4.3.4 Proactive Suggestions

Based on context awareness, suggest actions the user might want:

- Detect user is in an email and hasn't replied: "Want me to draft a reply?"
- Detect user has a meeting in 5 minutes: "Your meeting with Sarah starts in 5 minutes. Want me to open the Zoom link?"
- Detect user is reading a long document: "Want me to summarize this?"

---

## 5. Technical Architecture

### 5.1 New Module Structure

```
Talk/
├── Talk/
│   ├── TalkApp.swift
│   ├── AppDelegate.swift
│   ├── AppState.swift              # Refactored: routes to Agent pipeline
│   │
│   ├── Core/                       # (Existing, unchanged)
│   │   ├── Recorder.swift
│   │   ├── CursorPaster.swift
│   │   └── SoundManager.swift
│   │
│   ├── Whisper/                    # (Existing, unchanged)
│   │   ├── WhisperContext.swift
│   │   └── WhisperState.swift
│   │
│   ├── Processing/                 # (Existing, extended)
│   │   ├── SimpleCleanupProcessor.swift
│   │   └── IntentClassifier.swift  # NEW: LLM-based intent detection
│   │
│   ├── LLM/                       # (Existing, extended)
│   │   ├── LLMProvider.swift       # Add tool_call support
│   │   ├── OllamaManager.swift
│   │   ├── OllamaService.swift     # Add function calling
│   │   ├── ClaudeService.swift     # Add tool use
│   │   ├── OpenAIService.swift     # Add function calling
│   │   └── AIEnhancementService.swift
│   │
│   ├── Agent/                      # NEW: Agent pipeline
│   │   ├── AgentPipeline.swift     # Orchestrates: classify -> plan -> execute
│   │   ├── ActionRouter.swift      # Routes intents to handlers
│   │   ├── ActionResult.swift      # Result types
│   │   └── AgentLoop.swift         # Plan-execute-verify loop (Phase 3)
│   │
│   ├── Actions/                    # NEW: Action handlers
│   │   ├── ActionProtocol.swift    # Protocol for all actions
│   │   ├── DictateAction.swift     # Wraps current paste behavior
│   │   ├── TransformAction.swift   # Read selected + LLM + paste
│   │   ├── SearchAction.swift      # Open browser with search
│   │   ├── OpenAction.swift        # Open apps/files/URLs
│   │   ├── ReplyAction.swift       # Reply in current app
│   │   ├── CreateAction.swift      # Create documents/events
│   │   └── SummarizeAction.swift   # Summarize content
│   │
│   ├── Context/                    # NEW: App context awareness
│   │   ├── ContextReader.swift     # Read active app state via AX API
│   │   ├── AppContext.swift         # Context data model
│   │   ├── BrowserContext.swift    # Browser-specific context (URL, page)
│   │   └── ScreenReader.swift      # Read visible text (Phase 2)
│   │
│   ├── Integrations/              # NEW: App integrations (Phase 2)
│   │   ├── IntegrationProtocol.swift
│   │   ├── MailIntegration.swift
│   │   ├── BrowserIntegration.swift
│   │   ├── CalendarIntegration.swift
│   │   ├── NotesIntegration.swift
│   │   ├── MessagesIntegration.swift
│   │   ├── SlackIntegration.swift
│   │   └── AppleScriptBridge.swift # Centralized AppleScript execution
│   │
│   ├── Automation/                # NEW: Custom workflows (Phase 3)
│   │   ├── WorkflowEngine.swift
│   │   ├── WorkflowBuilder.swift
│   │   └── ActionHistory.swift
│   │
│   ├── Hotkey/                     # (Existing, extended)
│   │   └── HotkeyManager.swift     # Add third hotkey for agent mode
│   │
│   ├── MenuBar/
│   │   └── MenuBarView.swift
│   │
│   ├── Services/
│   │   └── PermissionManager.swift # Extended for Screen Recording permission
│   │
│   └── Views/
│       ├── MiniRecorderView.swift  # Extended with action feedback
│       ├── AgentFeedbackView.swift # NEW: Shows agent action progress
│       ├── SettingsView.swift      # Extended with Agent settings tab
│       └── PermissionsView.swift
```

### 5.2 Intent Classification: Technical Design

#### Option A: Ollama Function Calling (Recommended for Phase 1)

Ollama supports tool/function calling with compatible models (llama3.1+, qwen2.5+, mistral-nemo+).

```swift
class IntentClassifier {
    private let llmProvider: LLMProviderProtocol

    // System prompt for classification
    private let classificationPrompt = """
    You are an intent classifier for a voice-controlled Mac assistant.
    Classify the user's spoken command into one of these actions:

    Actions:
    - dictate: User wants to type/paste text (DEFAULT if unclear)
    - transform: User wants to modify selected/existing text
    - search: User wants to find information online
    - open: User wants to open an app, file, or URL
    - reply: User wants to reply to a message or email
    - create: User wants to create a new document, event, or reminder
    - summarize: User wants a summary of current content

    Respond with a JSON object:
    {
      "action": "<action_type>",
      "target": "<what to act on>",
      "parameters": { <action-specific params> },
      "content": "<the actual content/text to use>",
      "confidence": <0.0-1.0>
    }
    """

    func classify(_ transcription: String, context: AppContext) async throws -> VoiceIntent {
        let contextInfo = """
        Current app: \(context.appName) (\(context.bundleIdentifier))
        Window: \(context.windowTitle ?? "unknown")
        Selected text: \(context.selectedText?.prefix(200) ?? "none")
        """

        let prompt = "\(classificationPrompt)\n\nContext:\n\(contextInfo)\n\nUser said: \"\(transcription)\""

        let response = try await llmProvider.generate(
            text: transcription,
            systemPrompt: prompt
        )

        return try parseIntent(from: response, rawText: transcription)
    }
}
```

#### Option B: Local Classification with Heuristics (Fallback)

For offline mode or when LLM is unavailable, extend the existing regex approach:

```swift
class HeuristicClassifier {
    // Expanded from current detectVoiceDirection()
    private let actionPatterns: [(NSRegularExpression, ActionType)] = [
        // Search patterns
        (try! NSRegularExpression(pattern: "^(?:search|look up|find|google)\\s+(?:for\\s+)?(.+)", options: .caseInsensitive), .search),

        // Open patterns
        (try! NSRegularExpression(pattern: "^(?:open|launch|start|switch to)\\s+(.+)", options: .caseInsensitive), .open),

        // Reply patterns
        (try! NSRegularExpression(pattern: "^(?:reply|respond|answer)\\s+(?:saying|with|that)?\\s*(.+)", options: .caseInsensitive), .reply),

        // Create patterns
        (try! NSRegularExpression(pattern: "^(?:create|make|new|add)\\s+(?:a\\s+)?(.+)", options: .caseInsensitive), .create),

        // Summarize patterns
        (try! NSRegularExpression(pattern: "^(?:summarize|sum up|give me a summary|tldr)\\s*(.+)?", options: .caseInsensitive), .summarize),

        // Transform patterns (existing voice directions, expanded)
        (try! NSRegularExpression(pattern: "^(?:make|convert|rewrite|format|change)\\s+(?:this|it|that)\\s+(.+)", options: .caseInsensitive), .transform),
    ]
}
```

### 5.3 Action Execution: Technical Design

#### AppleScript Bridge

Central service for executing AppleScript commands across apps.

```swift
class AppleScriptBridge {
    /// Execute an AppleScript and return the result
    static func execute(_ script: String) async throws -> String? {
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                let appleScript = NSAppleScript(source: script)
                let result = appleScript?.executeAndReturnError(&error)

                if let error = error {
                    let description = error[NSAppleScript.errorMessage] as? String ?? "Unknown error"
                    continuation.resume(throwing: AppleScriptError.executionFailed(description))
                } else {
                    continuation.resume(returning: result?.stringValue)
                }
            }
        }
    }

    // Pre-built scripts for common actions
    enum Scripts {
        static func mailReply(body: String) -> String {
            """
            tell application "Mail"
                set theMessage to item 1 of (selection as list)
                set theReply to reply theMessage with opening window
                tell theReply
                    set content to "\(body.escapedForAppleScript)"
                end tell
            end tell
            """
        }

        static func safariGetURL() -> String {
            """
            tell application "Safari"
                return URL of front document
            end tell
            """
        }

        static func createCalendarEvent(title: String, date: String, duration: Int) -> String {
            """
            tell application "Calendar"
                tell calendar "Home"
                    make new event with properties {summary:"\(title)", start date:date "\(date)", end date:date "\(date)" + \(duration) * minutes}
                end tell
            end tell
            """
        }

        static func openApp(name: String) -> String {
            """
            tell application "\(name)" to activate
            """
        }

        static func notesCreate(title: String, body: String) -> String {
            """
            tell application "Notes"
                make new note at folder "Notes" with properties {name:"\(title)", body:"\(body)"}
            end tell
            """
        }
    }
}
```

#### Browser Integration via JXA

For deeper browser control (reading page content, filling forms):

```swift
class BrowserIntegration: AppIntegration {
    var bundleIdentifier: String { "com.apple.Safari" }

    func getCurrentURL() async throws -> String? {
        let script = """
        var safari = Application('Safari');
        safari.documents[0].url();
        """
        return try await JXABridge.execute(script)
    }

    func getPageText() async throws -> String? {
        let script = """
        var safari = Application('Safari');
        safari.doJavaScript('document.body.innerText', {in: safari.documents[0]});
        """
        return try await JXABridge.execute(script)
    }

    func search(query: String) async throws {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let url = URL(string: "https://www.google.com/search?q=\(encoded)")!
        NSWorkspace.shared.open(url)
    }
}
```

#### EventKit Integration (Calendar/Reminders)

Native framework -- no AppleScript needed, more reliable:

```swift
import EventKit

class CalendarIntegration {
    private let eventStore = EKEventStore()

    func requestAccess() async -> Bool {
        if #available(macOS 14.0, *) {
            return (try? await eventStore.requestFullAccessToEvents()) ?? false
        } else {
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func createEvent(title: String, startDate: Date, endDate: Date, notes: String? = nil) throws {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents
        try eventStore.save(event, span: .thisEvent)
    }

    func getTodayEvents() -> [EKEvent] {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: nil)
        return eventStore.events(matching: predicate)
    }
}
```

### 5.4 Context Awareness: Technical Design

Extend the existing `PasteEligibilityService` into a full context reader.

```swift
class ContextReader {

    /// Read comprehensive context from the currently active application
    static func readCurrentContext() -> AppContext {
        guard AXIsProcessTrusted() else {
            return AppContext.empty
        }

        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return AppContext.empty
        }

        let appElement = AXUIElementCreateApplication(frontApp.processIdentifier)

        // Read window title
        var windowTitle: String?
        var focusedWindow: AnyObject?
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow) == .success {
            var titleValue: AnyObject?
            if AXUIElementCopyAttributeValue(focusedWindow as! AXUIElement, kAXTitleAttribute as CFString, &titleValue) == .success {
                windowTitle = titleValue as? String
            }
        }

        // Read focused element role
        var focusedElement: AnyObject?
        var elementRole: String?
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedElement) == .success {
            var roleValue: AnyObject?
            if AXUIElementCopyAttributeValue(focusedElement as! AXUIElement, kAXRoleAttribute as CFString, &roleValue) == .success {
                elementRole = roleValue as? String
            }
        }

        // Read selected text (reuse existing implementation)
        let selectedText = PasteEligibilityService.getSelectedText()

        // Read browser URL if applicable
        var url: String?
        let browserBundles = ["com.apple.Safari", "com.google.Chrome", "com.brave.Browser", "org.mozilla.firefox"]
        if let bundleId = frontApp.bundleIdentifier, browserBundles.contains(bundleId) {
            url = try? AppleScriptBridge.executeSync(getBrowserURLScript(for: bundleId))
        }

        return AppContext(
            bundleIdentifier: frontApp.bundleIdentifier ?? "unknown",
            appName: frontApp.localizedName ?? "Unknown",
            windowTitle: windowTitle,
            focusedElementRole: elementRole,
            selectedText: selectedText,
            url: url
        )
    }

    private static func getBrowserURLScript(for bundleId: String) -> String {
        switch bundleId {
        case "com.apple.Safari":
            return "tell application \"Safari\" to return URL of front document"
        case "com.google.Chrome":
            return "tell application \"Google Chrome\" to return URL of active tab of front window"
        default:
            return ""
        }
    }
}
```

### 5.5 Agent Pipeline: Data Flow

```
                            ┌──────────────────────┐
                            │     HotkeyManager     │
                            │  (fn key = agent mode) │
                            └──────────┬───────────┘
                                       │
                            ┌──────────▼───────────┐
                            │      Recorder         │
                            │  (16kHz mono PCM)     │
                            └──────────┬───────────┘
                                       │ audio URL
                            ┌──────────▼───────────┐
                            │    WhisperState       │
                            │ (Metal-accelerated)   │
                            └──────────┬───────────┘
                                       │ transcription text
                            ┌──────────▼───────────┐
                            │   ContextReader       │
                            │ (AX API + AppleScript)│
                            └──────────┬───────────┘
                                       │ AppContext
                     ┌─────────────────▼─────────────────┐
                     │        IntentClassifier            │
                     │  (Ollama tool_call / heuristic)    │
                     └─────────────────┬─────────────────┘
                                       │ VoiceIntent
                     ┌─────────────────▼─────────────────┐
                     │          ActionRouter              │
                     └──┬──────┬──────┬──────┬──────┬───┘
                        │      │      │      │      │
                   ┌────▼─┐ ┌─▼───┐ ┌▼────┐ ┌▼───┐ ┌▼─────┐
                   │Dictate│ │Trans│ │Search│ │Open│ │Reply │
                   │Action │ │form │ │Action│ │Act │ │Action│
                   └──┬───┘ └──┬──┘ └──┬───┘ └─┬──┘ └──┬───┘
                      │        │       │       │       │
                      ▼        ▼       ▼       ▼       ▼
                   Paste    AX Read  Browser  NSWork  AppleScript
                   at       + LLM    open()   space   + compose
                   cursor   + Paste           open()
                      │        │       │       │       │
                      └────────┴───────┴───────┴───────┘
                                       │
                            ┌──────────▼───────────┐
                            │  AgentFeedbackView    │
                            │ (shows action result) │
                            └──────────────────────┘
```

### 5.6 Permission Requirements

The agent evolution requires additional macOS permissions beyond the current set:

| Permission | Current | Agent Needs | How to Request |
|---|---|---|---|
| Microphone | Required | Same | AVCaptureDevice.requestAccess() |
| Accessibility | Required | Same (expanded use) | AXIsProcessTrusted() + System Preferences |
| Automation (AppleScript) | Not used | Required for app control | First AppleScript triggers system prompt |
| Calendar | Not used | Required for events | EventKit requestAccess() |
| Reminders | Not used | Required for reminders | EventKit requestAccess() |
| Screen Recording | Not used | Optional (Phase 3, screen reader) | CGPreflightScreenCaptureAccess() |

**Key design principle:** Request permissions progressively. Only ask for Calendar access when the user first tries a calendar action, not at app launch. This follows Apple's guidelines and reduces onboarding friction.

---

## 6. Integration Strategy

### 6.1 Priority Matrix

```
                    HIGH IMPACT
                        │
        P0: Browser ────┤──── P0: Mail
                        │
        P1: Calendar ───┤──── P1: Notes
                        │
LOW EFFORT ─────────────┼──────────────── HIGH EFFORT
                        │
        P1: Reminders ──┤──── P2: Slack
                        │
        P2: Finder ─────┤──── P2: Google Docs
                        │
                    LOW IMPACT
```

### 6.2 Implementation Details by Integration

#### P0: Browser (Safari + Chrome) -- Week 9-10

**Why P0:** Most universal action. Every knowledge worker searches and reads web content.

```swift
class BrowserIntegration: AppIntegration {
    var supportedActions: [ActionType] = [.search, .summarize, .open]

    func search(_ query: String) async throws {
        // Encode and open search URL
        let url = "https://www.google.com/search?q=\(query.urlEncoded)"
        NSWorkspace.shared.open(URL(string: url)!)
    }

    func readCurrentPage() async throws -> String {
        // AppleScript to get page text from Safari
        let script = """
        tell application "Safari"
            do JavaScript "document.body.innerText" in document 1
        end tell
        """
        return try await AppleScriptBridge.execute(script) ?? ""
    }

    func getActiveTabURL() async throws -> String {
        // Detect which browser is active and get URL
        // ... (Safari, Chrome, Brave, Firefox support)
    }
}
```

**Permissions needed:** Automation permission for Safari/Chrome (granted via system prompt on first use).

#### P0: Mail -- Week 10-11

**Why P0:** Email is the highest-friction communication task. Voice-to-email is a killer feature.

```swift
class MailIntegration: AppIntegration {
    var supportedActions: [ActionType] = [.reply, .create, .summarize]

    func replyToSelected(body: String) async throws {
        let script = """
        tell application "Mail"
            set selectedMessages to selection
            if (count of selectedMessages) > 0 then
                set theMessage to item 1 of selectedMessages
                set theReply to reply theMessage with opening window
                set content of theReply to "\(body.escapedForAppleScript)"
            end if
        end tell
        """
        try await AppleScriptBridge.execute(script)
    }

    func composeNew(to: String?, subject: String, body: String) async throws {
        let script = """
        tell application "Mail"
            set newMessage to make new outgoing message with properties \\
                {subject:"\(subject)", content:"\(body)"}
            \(to != nil ? "make new to recipient at end of to recipients of newMessage with properties {address:\"\(to!)\"}" : "")
            set visible of newMessage to true
        end tell
        """
        try await AppleScriptBridge.execute(script)
    }

    func summarizeSelectedThread() async throws -> String {
        let script = """
        tell application "Mail"
            set selectedMessages to selection
            set emailContent to ""
            repeat with msg in selectedMessages
                set emailContent to emailContent & "From: " & (sender of msg) & return
                set emailContent to emailContent & "Subject: " & (subject of msg) & return
                set emailContent to emailContent & (content of msg) & return & "---" & return
            end repeat
            return emailContent
        end tell
        """
        let content = try await AppleScriptBridge.execute(script) ?? ""
        // Feed to LLM for summarization
        return try await AIEnhancementService.shared.enhance(content, prompt: LLMPrompts.summarization)
    }
}
```

#### P1: Calendar -- Week 11-12

**Why P1:** High-frequency action, uses native EventKit (reliable, no AppleScript fragility).

```swift
class CalendarIntegration: AppIntegration {
    private let eventStore = EKEventStore()
    var supportedActions: [ActionType] = [.create, .summarize]

    func createEvent(from intent: VoiceIntent) async throws {
        // LLM extracts structured data from natural language
        let eventDetails = try await extractEventDetails(from: intent)
        let event = EKEvent(eventStore: eventStore)
        event.title = eventDetails.title
        event.startDate = eventDetails.startDate
        event.endDate = eventDetails.endDate
        event.calendar = eventStore.defaultCalendarForNewEvents
        try eventStore.save(event, span: .thisEvent)
    }

    func todaySummary() async throws -> String {
        let events = getTodayEvents()
        let summary = events.map { "\($0.startDate.formatted(.dateTime.hour().minute())) - \($0.title ?? "Untitled")" }
        return "Today's schedule:\n" + summary.joined(separator: "\n")
    }

    private func extractEventDetails(from intent: VoiceIntent) async throws -> EventDetails {
        // Use LLM to parse: "Schedule a meeting with Sarah tomorrow at 2pm for 30 minutes"
        // into structured EventDetails
        let prompt = """
        Extract calendar event details from this text. Return JSON:
        {"title": "", "date": "YYYY-MM-DD", "time": "HH:MM", "duration_minutes": 30}
        """
        let response = try await AIEnhancementService.shared.enhance(intent.rawText, prompt: prompt)
        return try JSONDecoder().decode(EventDetails.self, from: response.data(using: .utf8)!)
    }
}
```

#### P1: Notes -- Week 12-13

```swift
class NotesIntegration: AppIntegration {
    var supportedActions: [ActionType] = [.create, .dictate]

    func createNote(title: String, body: String) async throws {
        let script = """
        tell application "Notes"
            activate
            make new note at folder "Notes" with properties {name:"\(title.escapedForAppleScript)", body:"\(body.escapedForAppleScript)"}
        end tell
        """
        try await AppleScriptBridge.execute(script)
    }

    func appendToNote(title: String, text: String) async throws {
        let script = """
        tell application "Notes"
            set matchingNotes to notes whose name is "\(title.escapedForAppleScript)"
            if (count of matchingNotes) > 0 then
                set targetNote to item 1 of matchingNotes
                set body of targetNote to (body of targetNote) & return & "\(text.escapedForAppleScript)"
            end if
        end tell
        """
        try await AppleScriptBridge.execute(script)
    }
}
```

#### P2: Slack -- Week 14-15

Two implementation paths:

**Path A: AppleScript (simpler, limited)**
```swift
// Limited: can only send messages if Slack is open to the right channel
class SlackAppleScriptIntegration {
    func sendMessage(_ text: String) async throws {
        // Use Accessibility API to find the message input field
        // Type the message and press Enter
        let script = """
        tell application "Slack" to activate
        delay 0.5
        tell application "System Events"
            keystroke "\(text.escapedForAppleScript)"
            keystroke return
        end tell
        """
        try await AppleScriptBridge.execute(script)
    }
}
```

**Path B: Slack API (richer, requires OAuth)**
```swift
class SlackAPIIntegration {
    private var token: String?

    func authenticate() async throws {
        // OAuth2 flow via local HTTP server
        // Store token in Keychain
    }

    func sendMessage(channel: String, text: String) async throws {
        var request = URLRequest(url: URL(string: "https://slack.com/api/chat.postMessage")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token!)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "channel": channel,
            "text": text
        ])
        let (_, response) = try await URLSession.shared.data(for: request)
        // Handle response
    }
}
```

**Recommendation:** Start with AppleScript (Path A) for Phase 2, graduate to Slack API (Path B) in Phase 3 for richer functionality.

### 6.3 Integration Testing Strategy

Each integration should have:
1. **Unit tests** for AppleScript generation (verify script string correctness)
2. **Mock tests** for LLM-based parameter extraction
3. **Manual smoke tests** on real apps (cannot be fully automated due to AppleScript nature)
4. **Graceful failure** if target app is not installed or not running

---

## 7. Differentiation Strategy

### 7.1 Positioning: "The Private Voice Agent"

Hey Lemon and cloud-first competitors send your voice data, screen content, and app data to remote servers. This is a fundamental vulnerability in enterprise and privacy-conscious markets.

**Core narrative:** "Your voice commands are processed entirely on your Mac. Your emails, documents, and screen content never leave your machine. Every other voice agent sends your data to the cloud. We do not."

### 7.2 Differentiation Pillars

#### Pillar 1: Local-First Privacy

| Feature | Our Approach | Hey Lemon (Likely) |
|---|---|---|
| Speech-to-text | Local Whisper (Metal GPU) | Cloud API (Deepgram/OpenAI) |
| Intent classification | Local Ollama | Cloud LLM |
| Action execution | On-device (AppleScript, AX API) | On-device |
| Data storage | Local only | Cloud sync likely |
| Works offline | Yes (with Ollama) | No |

**Marketing angle:** "Enterprise-grade privacy without the enterprise price tag."

#### Pillar 2: Provider Choice and Transparency

No vendor lock-in. Users choose their LLM provider:
- **Ollama (local):** Free, private, works offline
- **Claude API:** Best reasoning, user brings their own key
- **OpenAI API:** Most popular, user brings their own key
- **Future:** Groq, Mistral API, local llama.cpp without Ollama

This is a genuine differentiator. Hey Lemon likely uses a single cloud provider with opaque pricing baked into subscription fees.

#### Pillar 3: Open and Configurable

- Custom system prompts (already implemented)
- Custom hotkey configuration (already implemented)
- Custom automation workflows (Phase 3)
- Open integration protocol (developers can add new app integrations)

#### Pillar 4: Native Mac Experience

Built with Swift/SwiftUI, not Electron or web wrapper. This means:
- Lower memory footprint
- Better battery life
- Faster launch time
- Native UI that respects system preferences (Dark Mode, accent colors)
- Metal GPU acceleration for Whisper

### 7.3 Competitive Response Scenarios

**If Hey Lemon adds local processing:**
- They will likely use Apple's on-device models (smaller, less capable)
- Our full Ollama integration with model choice remains superior
- Respond by emphasizing model flexibility and offline capability

**If Apple builds voice-to-action into macOS:**
- Apple's solution will be limited, Siri-like, and locked to Apple's LLMs
- Our advantage: works with any LLM, customizable, more capable
- Respond by positioning as "the power user's voice agent"

**If a well-funded startup enters the space:**
- Our local-first architecture is hard to replicate (most startups build cloud-first)
- Our head start on AppleScript/AX integrations is defensible
- Respond by accelerating the integration roadmap and building community

---

## 8. Go-to-Market Strategy

### 8.1 Target Segments (Priority Order)

| Segment | Size | Willingness to Pay | Key Value Prop |
|---|---|---|---|
| **Developers** | Large | Medium | Voice coding assistance, terminal commands, docs lookup |
| **Knowledge workers** | Very large | High | Email, calendar, note-taking 5x faster |
| **Writers/Content creators** | Medium | High | Voice-first drafting, editing, formatting |
| **Privacy-conscious professionals** | Medium | Very high | Lawyers, healthcare, finance - data never leaves machine |
| **Accessibility users** | Medium | High | Voice control for those with RSI or mobility limitations |

### 8.2 Pricing Model

#### Freemium with Local-First Core

| Tier | Price | Features |
|---|---|---|
| **Free** | $0 | Voice-to-text (Whisper), simple cleanup, paste-at-cursor, Ollama local LLM |
| **Pro** | $12/month or $99/year | Agent mode (voice-to-action), all integrations, cloud LLM relay, priority support |
| **Enterprise** | $29/month per seat | Team management, custom integrations, on-prem LLM support, audit logging |

**Key pricing insight:** The free tier is genuinely useful (full dictation + local LLM). This drives adoption. The Pro tier unlocks the "agent" capability that justifies the price. Users who try voice-to-text and love it will upgrade for voice-to-action.

**Why not pure subscription:** A fully local app with no cloud costs should not require a subscription for basic functionality. The free tier builds trust and goodwill.

#### Revenue Projections (Conservative)

| Quarter | Free Users | Pro Converts (5%) | Monthly Revenue |
|---|---|---|---|
| Q1 (Launch) | 5,000 | 250 | $3,000 |
| Q2 | 15,000 | 750 | $9,000 |
| Q3 | 40,000 | 2,000 | $24,000 |
| Q4 | 80,000 | 4,000 | $48,000 |

### 8.3 Launch Strategy

#### Pre-Launch (2 weeks before)

1. Create landing page with waitlist
2. Record demo video: side-by-side "voice-to-text vs voice-to-action" showing the transformation
3. Write launch blog post: "Why Your Voice Assistant Shouldn't Need the Cloud"
4. Seed in developer communities (Hacker News, Reddit r/macapps, Swift forums)

#### Launch Day

1. **Product Hunt launch** with demo video
2. **Hacker News "Show HN"** post emphasizing local-first architecture
3. **Twitter/X thread** demonstrating 5 key actions
4. **Direct outreach** to 20 Mac productivity bloggers/YouTubers

#### Post-Launch (Ongoing)

1. Weekly blog posts on voice productivity tips
2. GitHub discussions for feature requests
3. Discord community for power users
4. Monthly changelog with video demos

### 8.4 Distribution Channels

| Channel | Priority | Cost | Expected Impact |
|---|---|---|---|
| Product Hunt | P0 | Free | 2,000-5,000 sign-ups |
| Hacker News | P0 | Free | 1,000-3,000 sign-ups (dev audience) |
| Mac App Store | P1 | $99/year (dev program) | Long-tail discovery |
| Direct download (website) | P0 | Hosting cost | Primary channel for Pro users |
| Homebrew cask | P1 | Free | Developer audience |
| SetApp | P2 | Revenue share | Bundled distribution |

---

## 9. Execution Timeline

### 9.1 Detailed Phased Timeline

```
PHASE 1: MVP AGENT (Weeks 1-8)
============================================================

Week 1-2: Foundation
├── Create Agent/ module structure
├── Implement ContextReader (extend existing AX code)
├── Implement AppContext data model
├── Add third hotkey (fn) for agent mode in HotkeyManager
└── Write unit tests for context reading

Week 3-4: Intent Classification
├── Implement IntentClassifier with Ollama function calling
├── Implement HeuristicClassifier (regex fallback)
├── Define VoiceIntent and ActionType data models
├── Add classification prompt engineering and testing
└── Benchmark classification speed (target < 500ms)

Week 5-6: Core Actions
├── Implement ActionProtocol and ActionRouter
├── Implement DictateAction (wrap current paste behavior)
├── Implement TransformAction (read selected text + LLM + paste)
├── Implement SearchAction (open browser with query)
├── Implement OpenAction (NSWorkspace + AppleScript)
└── Implement ReplyAction (basic, context-aware)

Week 7-8: Pipeline Integration + Polish
├── Refactor AppState.processAudio() to use AgentPipeline
├── Create AgentFeedbackView (action progress UI)
├── Update MiniRecorderView for agent mode
├── Add Agent settings tab in SettingsView
├── End-to-end testing of all 5 actions
└── Bug fixing and performance optimization

MILESTONE: Agent MVP release (beta)
  - 5 working actions: dictate, transform, search, open, reply
  - Local intent classification via Ollama
  - Context-aware (knows active app + selected text)
  - Backward compatible (existing hotkeys work unchanged)

PHASE 2: INTEGRATION LAYER (Weeks 9-16)
============================================================

Week 9-10: Browser + AppleScript Foundation
├── Implement AppleScriptBridge (centralized script execution)
├── Implement BrowserIntegration (Safari + Chrome)
├── Add page reading capability (get page text)
├── Add tab management (list tabs, switch tabs)
└── Test across Safari, Chrome, Brave, Firefox

Week 10-11: Mail Integration
├── Implement MailIntegration (reply, compose, summarize)
├── Test with Apple Mail
├── Add Gmail web support via browser automation
├── Implement email thread summarization
└── Handle edge cases (no selection, multiple accounts)

Week 11-12: Calendar + Reminders
├── Implement CalendarIntegration via EventKit
├── Implement natural language date parsing (LLM-assisted)
├── Implement RemindersIntegration via EventKit
├── Add "What's on my calendar today?" action
└── Permission request flow for Calendar/Reminders

Week 12-13: Notes + Messages
├── Implement NotesIntegration (create, append)
├── Implement MessagesIntegration (basic send)
├── Test across different note-taking apps
└── Implement conversation context for Messages

Week 13-14: Multi-Step Workflows
├── Implement WorkflowEngine
├── Implement LLM-based workflow decomposition
├── Add step-by-step progress UI
├── Test 3 multi-step scenarios:
│   ├── "Research X and email summary to Y"
│   ├── "Check my calendar and send availability to Z"
│   └── "Summarize this page and save to Notes"
└── Error recovery between steps

Week 15-16: Polish + Performance
├── Optimize classification latency
├── Add integration health checks (is Mail running? etc.)
├── Improve error messages and recovery UX
├── Performance profiling and memory optimization
├── Beta testing with 50 users
└── Documentation and changelog

MILESTONE: Integration release
  - 8 app integrations working
  - Multi-step workflows
  - Real-time action feedback UI
  - < 2 second end-to-end for simple actions

PHASE 3: ADVANCED AGENT (Weeks 17-24)
============================================================

Week 17-18: Action History + Learning
├── Implement SwiftData models for action history
├── Implement few-shot intent classification from history
├── Add "correct this action" feedback mechanism
├── Implement usage analytics (local only)
└── Build history viewer in Settings

Week 19-20: Custom Automations
├── Implement WorkflowBuilder (define named automations)
├── Implement workflow trigger words
├── Add automation import/export
├── Build automation editor UI
└── Test with 5 common workflow templates

Week 21-22: Agentic Loop + Verification
├── Implement AgentLoop (plan -> execute -> verify)
├── Add destructive action confirmation
├── Implement result verification (did the action succeed?)
├── Add retry and recovery logic
└── Implement proactive suggestions (context-based)

Week 23-24: Polish + Launch Prep
├── Full regression testing
├── Performance optimization pass
├── Security audit (AppleScript injection, data handling)
├── Landing page and marketing materials
├── Product Hunt preparation
├── App Store submission (if pursuing)
└── Documentation finalization

MILESTONE: Full agent release (v2.0)
  - Learning from user patterns
  - Custom automation workflows
  - Agentic loop with verification
  - Proactive suggestions
  - Production-ready for launch
```

### 9.2 Key Milestones and Success Metrics

| Milestone | Date (Relative) | Success Criteria |
|---|---|---|
| Agent MVP (beta) | Week 8 | 5 actions working, < 3s latency, 80% intent accuracy |
| Integration release | Week 16 | 8 integrations, multi-step workflows, 50 beta testers |
| Public launch (v2.0) | Week 24 | 500+ daily active users, < 2s latency, 90% intent accuracy |
| Revenue milestone | Week 32 | 250+ Pro subscribers, $3K MRR |

### 9.3 Resource Requirements

| Resource | Phase 1 | Phase 2 | Phase 3 |
|---|---|---|---|
| Swift developer (senior) | 1 full-time | 1 full-time | 1 full-time |
| Prompt engineering | 20% time | 10% time | 15% time |
| QA/Testing | 10% time | 20% time | 20% time |
| Design (UI/UX) | 10% time | 15% time | 10% time |
| Marketing | 5% time | 10% time | 25% time |

---

## 10. Risk Mitigation

### 10.1 Technical Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Intent classification accuracy below 80% | Medium | High | Hybrid approach: LLM + heuristic fallback. Conservative default to dictation. User correction loop. |
| AppleScript reliability across macOS versions | Medium | Medium | Abstract behind protocol. Test on macOS 14, 15. Have AX API fallback for critical actions. |
| Ollama function calling limitations | Low | Medium | Pre-parse intent with standard generation if tool_call unavailable. JSON mode as fallback. |
| Latency exceeds 3 seconds | Medium | High | Use smallest viable model (qwen2.5:3b). Cache common intents. Parallel context reading + classification. |
| Accessibility API changes in macOS 16 | Low | High | Monitor Apple developer betas. Abstract AX calls behind a compatibility layer. |
| Memory pressure from Ollama + Whisper | Medium | Medium | Sequential model loading (unload Whisper after transcription, load LLM for classification). Monitor memory. |

### 10.2 Business Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Apple builds native voice-to-action | Medium | Very high | Move fast. Build integrations Apple will not (third-party apps). Position as "power user" tool. |
| Hey Lemon achieves dominant market share | Low | High | Differentiate on privacy. Target segments Hey Lemon ignores (enterprise, privacy-conscious). |
| Low conversion from free to Pro | High | Medium | Ensure free tier is genuinely useful. Make the upgrade path obvious. Consider lifetime license option. |
| User privacy concerns despite local processing | Low | Medium | Transparent privacy page. Open-source critical components. Third-party security audit. |

### 10.3 Execution Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| Scope creep in Phase 2 integrations | High | Medium | Strict prioritization. Ship P0 integrations first, defer P2 to Phase 3 if needed. |
| Single developer bottleneck | High | High | Document architecture thoroughly. Keep code modular. Consider open-sourcing integration layer. |
| Beta testing feedback overwhelms capacity | Medium | Low | Structured feedback channels. Prioritize bugs over features. Weekly triage. |

---

## Appendix: Implementation Reference

### A.1 Files to Modify (Phase 1)

| File | Modification |
|---|---|
| `/Users/ak/Documents/git-projects/talk/Talk/Talk/AppState.swift` | Add agent pipeline routing in `processAudio()` (line 172) |
| `/Users/ak/Documents/git-projects/talk/Talk/Talk/Hotkey/HotkeyManager.swift` | Add third hotkey for agent mode, new `ProcessingMode.agent` case |
| `/Users/ak/Documents/git-projects/talk/Talk/Talk/LLM/LLMProvider.swift` | Add `generateWithTools()` method to protocol |
| `/Users/ak/Documents/git-projects/talk/Talk/Talk/LLM/OllamaService.swift` | Add function calling support to `generate()` |
| `/Users/ak/Documents/git-projects/talk/Talk/Talk/LLM/AIEnhancementService.swift` | Extract `detectVoiceDirection()` to IntentClassifier |
| `/Users/ak/Documents/git-projects/talk/Talk/Talk/Core/CursorPaster.swift` | Extract `PasteEligibilityService` to Context module |
| `/Users/ak/Documents/git-projects/talk/Talk/Talk/Views/SettingsView.swift` | Add Agent settings tab |
| `/Users/ak/Documents/git-projects/talk/Talk/Talk/Views/MiniRecorderView.swift` | Add agent mode visual feedback |

### A.2 New Files to Create (Phase 1)

| File | Purpose |
|---|---|
| `Talk/Talk/Processing/IntentClassifier.swift` | LLM-based intent classification |
| `Talk/Talk/Processing/HeuristicClassifier.swift` | Regex fallback classifier |
| `Talk/Talk/Agent/AgentPipeline.swift` | Orchestrates classify -> route -> execute |
| `Talk/Talk/Agent/ActionRouter.swift` | Routes VoiceIntent to correct ActionHandler |
| `Talk/Talk/Agent/ActionResult.swift` | Result types for actions |
| `Talk/Talk/Actions/ActionProtocol.swift` | Protocol for all action handlers |
| `Talk/Talk/Actions/DictateAction.swift` | Wraps current paste behavior |
| `Talk/Talk/Actions/TransformAction.swift` | Read selected + LLM + paste |
| `Talk/Talk/Actions/SearchAction.swift` | Open browser with search query |
| `Talk/Talk/Actions/OpenAction.swift` | Open apps/files/URLs |
| `Talk/Talk/Actions/ReplyAction.swift` | Reply in current app context |
| `Talk/Talk/Context/ContextReader.swift` | Read active app state via AX API |
| `Talk/Talk/Context/AppContext.swift` | Context data model |
| `Talk/Talk/Views/AgentFeedbackView.swift` | Shows agent action progress |

### A.3 Key Swift/macOS Technologies by Feature

| Feature | Technology | Framework | Notes |
|---|---|---|---|
| Intent classification | Ollama tool_call / JSON mode | URLSession | Use streaming for faster TTFT |
| App context reading | AXUIElement API | ApplicationServices | Already partially implemented |
| Window title reading | kAXTitleAttribute | ApplicationServices | Extend existing AX code |
| Browser URL reading | AppleScript/JXA | Foundation (NSAppleScript) | Per-browser scripts needed |
| App launching | NSWorkspace.shared.open() | AppKit | Already available |
| Email control | AppleScript "tell application Mail" | Foundation | Requires Automation permission |
| Calendar events | EKEventStore | EventKit | Native, reliable |
| Reminders | EKReminderStore | EventKit | Native, reliable |
| Keyboard simulation | CGEvent | CoreGraphics | Already implemented |
| Selected text reading | kAXSelectedTextAttribute | ApplicationServices | Already implemented |
| Screen content reading | CGWindowListCopyWindowInfo | CoreGraphics | Phase 3, requires Screen Recording |
| Sound feedback | NSSound / AVAudioPlayer | AVFoundation | Already implemented |
| Settings persistence | @AppStorage / UserDefaults | SwiftUI | Already implemented |
| Action history | @Model / SwiftData | SwiftData | Phase 3, requires macOS 14+ |

### A.4 Prompt Templates for Agent Actions

#### Intent Classification Prompt
```
You are an intent classifier for a Mac voice assistant. Given the user's spoken
command and the current app context, classify the intent.

Current app: {app_name} ({bundle_id})
Window title: {window_title}
Selected text: {selected_text_preview}

User said: "{transcription}"

Respond ONLY with a JSON object:
{
  "action": "dictate|transform|search|open|reply|create|summarize",
  "target": "what to act on",
  "parameters": {},
  "content": "the text content to use",
  "confidence": 0.0-1.0
}

Rules:
- If uncertain, default to "dictate" with high confidence
- "reply" only if user explicitly says reply/respond/answer
- "search" only if user explicitly says search/look up/find/google
- "transform" if user says make/convert/rewrite/format about existing text
- "create" if user says create/make/new with a document/event/note
```

#### Email Reply Generation Prompt
```
You are drafting an email reply. The user dictated their response. Convert it
into a professional email reply.

Original email subject: {subject}
Original sender: {sender}

User's dictated response: "{content}"

Write ONLY the email body (no subject line, no "Re:"). Include an appropriate
greeting and sign-off. Keep the tone {formal|casual} based on the original email.
```

#### Event Extraction Prompt
```
Extract calendar event details from the user's spoken command. Today is {date}.

User said: "{transcription}"

Respond ONLY with JSON:
{
  "title": "event title",
  "date": "YYYY-MM-DD",
  "start_time": "HH:MM",
  "duration_minutes": 30,
  "location": null,
  "notes": null
}

Interpret relative dates: "tomorrow" = {tomorrow_date}, "next Monday" = {next_monday}, etc.
Default duration is 30 minutes if not specified.
```

---

**Document prepared for internal strategic planning purposes.**
**Next step: Begin Phase 1, Week 1 -- create the Agent/ module structure and implement ContextReader.**
