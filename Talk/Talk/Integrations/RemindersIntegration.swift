import Foundation
import EventKit

@MainActor
class RemindersIntegration: AppIntegration {
    static let shared = RemindersIntegration()

    let bundleIdentifier = "com.apple.reminders"
    let displayName = "Reminders"
    let supportedActions: [ActionType] = [.create, .summarize]

    private let eventStore = EKEventStore()
    private var accessGranted = false

    var isAvailable: Bool {
        accessGranted
    }

    private init() {
        Task { await requestAccess() }
    }

    // MARK: - AppIntegration

    func execute(intent: VoiceIntent, context: AppContext) async throws -> ActionResult {
        guard accessGranted else {
            return .failure(ActionFailure(
                message: "Reminders access not granted",
                isRecoverable: true,
                suggestion: "Grant reminders access in System Settings > Privacy & Security > Reminders"
            ))
        }

        switch intent.action {
        case .create:
            let title = intent.content
            let dueDateString = intent.parameters["due_date"]
            let notes = intent.parameters["notes"]
            let dueDate = dueDateString.flatMap { parseDueDate($0) }
            return try await createReminder(title: title, dueDate: dueDate, notes: notes)

        case .summarize:
            return try await listRemindersResult()

        default:
            return .failure(ActionFailure(
                message: "Reminders does not support \(intent.action.displayName)",
                isRecoverable: false
            ))
        }
    }

    // MARK: - Access

    /// Request access to reminders (macOS 14+).
    func requestAccess() async {
        if #available(macOS 14.0, *) {
            do {
                accessGranted = try await eventStore.requestFullAccessToReminders()
            } catch {
                accessGranted = false
            }
        } else {
            let granted = await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .reminder) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
            accessGranted = granted
        }
    }

    // MARK: - Reminder Actions

    /// Create a new reminder.
    func createReminder(title: String, dueDate: Date? = nil, notes: String? = nil) async throws -> ActionResult {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes
        reminder.calendar = eventStore.defaultCalendarForNewReminders()

        if let dueDate = dueDate {
            let calendar = Calendar.current
            reminder.dueDateComponents = calendar.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: dueDate
            )
        }

        try eventStore.save(reminder, commit: true)

        var message = "Reminder \"\(title)\" created"
        if let dueDate = dueDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            message += " (due \(formatter.string(from: dueDate)))"
        }

        return .success(ActionSuccess(
            message: message,
            metadata: ["title": title]
        ))
    }

    /// List incomplete reminders.
    func listReminders() async -> [EKReminder] {
        let predicate = eventStore.predicateForIncompleteReminders(
            withDueDateStarting: nil,
            ending: nil,
            calendars: nil
        )

        return await withCheckedContinuation { continuation in
            eventStore.fetchReminders(matching: predicate) { reminders in
                continuation.resume(returning: reminders ?? [])
            }
        }
    }

    // MARK: - Private Helpers

    private func listRemindersResult() async throws -> ActionResult {
        let reminders = await listReminders()

        if reminders.isEmpty {
            return .success(ActionSuccess(
                message: "No pending reminders",
                resultText: "No pending reminders.",
                shouldPaste: true
            ))
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        var lines: [String] = ["Pending reminders:"]
        for reminder in reminders.prefix(20) {
            var line = "- \(reminder.title ?? "Untitled")"
            if let dueDateComponents = reminder.dueDateComponents,
               let dueDate = Calendar.current.date(from: dueDateComponents) {
                line += " (due \(formatter.string(from: dueDate)))"
            }
            lines.append(line)
        }

        if reminders.count > 20 {
            lines.append("... and \(reminders.count - 20) more")
        }

        let summary = lines.joined(separator: "\n")
        return .success(ActionSuccess(
            message: "\(reminders.count) pending reminder(s)",
            resultText: summary,
            shouldPaste: true
        ))
    }

    private func parseDueDate(_ string: String) -> Date? {
        let dateFormatter = DateFormatter()
        // Try ISO format first
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: string) {
            return date
        }
        // Try with time
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        if let date = dateFormatter.date(from: string) {
            return date
        }
        return nil
    }
}
