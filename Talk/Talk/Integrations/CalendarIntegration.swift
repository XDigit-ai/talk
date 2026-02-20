import Foundation
import EventKit

@MainActor
class CalendarIntegration: AppIntegration {
    static let shared = CalendarIntegration()

    let bundleIdentifier = "com.apple.iCal"
    let displayName = "Calendar"
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
                message: "Calendar access not granted",
                isRecoverable: true,
                suggestion: "Grant calendar access in System Settings > Privacy & Security > Calendars"
            ))
        }

        switch intent.action {
        case .create:
            return try await createEventFromIntent(intent)

        case .summarize:
            return try await todaySummaryResult()

        default:
            return .failure(ActionFailure(
                message: "Calendar does not support \(intent.action.displayName)",
                isRecoverable: false
            ))
        }
    }

    // MARK: - Access

    /// Request full access to calendar events (macOS 14+).
    func requestAccess() async {
        if #available(macOS 14.0, *) {
            do {
                accessGranted = try await eventStore.requestFullAccessToEvents()
            } catch {
                accessGranted = false
            }
        } else {
            let granted = await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
            accessGranted = granted
        }
    }

    // MARK: - Calendar Actions

    /// Create a calendar event.
    func createEvent(title: String, startDate: Date, endDate: Date, notes: String? = nil) throws -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.notes = notes
        event.calendar = eventStore.defaultCalendarForNewEvents
        try eventStore.save(event, span: .thisEvent)
        return event
    }

    /// Get today's events sorted by start date.
    func getTodayEvents() -> [EKEvent] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return []
        }
        let predicate = eventStore.predicateForEvents(withStart: startOfDay, end: endOfDay, calendars: nil)
        return eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }

    /// Get a formatted summary of today's events.
    func todaySummary() -> String {
        let events = getTodayEvents()
        if events.isEmpty {
            return "No events scheduled for today."
        }

        let formatter = DateFormatter()
        formatter.timeStyle = .short

        var lines: [String] = ["Today's schedule:"]
        for event in events {
            let start = formatter.string(from: event.startDate)
            let end = formatter.string(from: event.endDate)
            lines.append("- \(start)-\(end): \(event.title ?? "Untitled")")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Private Helpers

    private func createEventFromIntent(_ intent: VoiceIntent) async throws -> ActionResult {
        // Use LLM to extract event details from natural language
        let extraction = try await AIEnhancementService.shared.enhance(
            intent.content,
            prompt: LLMPrompts.eventExtraction
        )

        // Parse the JSON response
        guard let data = extraction.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let title = json["title"] as? String else {
            // Fallback: create event with raw content as title, default to next hour
            let calendar = Calendar.current
            let now = Date()
            let startDate = calendar.nextDate(after: now, matching: DateComponents(minute: 0), matchingPolicy: .nextTime) ?? now
            let endDate = calendar.date(byAdding: .minute, value: 30, to: startDate) ?? startDate

            let event = try createEvent(title: intent.content, startDate: startDate, endDate: endDate)
            return .success(ActionSuccess(
                message: "Event \"\(event.title ?? "")\" created",
                metadata: ["title": event.title ?? ""]
            ))
        }

        // Build date from extracted fields
        let dateString = json["date"] as? String
        let timeString = json["start_time"] as? String ?? "09:00"
        let durationMinutes = json["duration_minutes"] as? Int ?? 30
        let notes = json["notes"] as? String

        let startDate = parseDateTime(date: dateString, time: timeString)
        let endDate = Calendar.current.date(byAdding: .minute, value: durationMinutes, to: startDate) ?? startDate

        let event = try createEvent(title: title, startDate: startDate, endDate: endDate, notes: notes)

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        return .success(ActionSuccess(
            message: "Event \"\(title)\" created for \(formatter.string(from: startDate))",
            metadata: ["title": title, "date": formatter.string(from: startDate)]
        ))
    }

    private func todaySummaryResult() async throws -> ActionResult {
        let summary = todaySummary()
        return .success(ActionSuccess(
            message: "Today's schedule",
            resultText: summary,
            shouldPaste: true
        ))
    }

    private func parseDateTime(date dateString: String?, time timeString: String) -> Date {
        let calendar = Calendar.current
        let now = Date()

        var dateComponents: DateComponents
        if let dateString = dateString {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let parsed = dateFormatter.date(from: dateString) {
                dateComponents = calendar.dateComponents([.year, .month, .day], from: parsed)
            } else {
                dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
            }
        } else {
            dateComponents = calendar.dateComponents([.year, .month, .day], from: now)
        }

        // Parse time
        let timeParts = timeString.split(separator: ":").compactMap { Int($0) }
        dateComponents.hour = timeParts.count > 0 ? timeParts[0] : 9
        dateComponents.minute = timeParts.count > 1 ? timeParts[1] : 0

        return calendar.date(from: dateComponents) ?? now
    }
}
