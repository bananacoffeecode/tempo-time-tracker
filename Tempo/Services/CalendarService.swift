// Required SPM package (Xcode → File → Add Package Dependencies):
//   GoogleAPIClientForREST  — https://github.com/google/google-api-objectivec-client-for-rest
//   Add product: GoogleAPIClientForRESTCore + GoogleAPIClientForREST_Calendar

import Foundation

struct CalendarEvent {
    let title:    String
    let startTime: Date
    let endTime:   Date
    let colorId:   Int
}

@MainActor
final class CalendarService {

    // MARK: - Event Creation

    /// Creates an event on the user's primary Google Calendar.
    /// Returns the created event's ID.
    func createEvent(_ event: CalendarEvent, accessToken: String) async throws -> String {

        // TODO: Replace the URLSession implementation below with GTLRCalendarService
        // once GoogleAPIClientForREST is installed. Example:
        //
        //   let service = GTLRCalendarService()
        //   service.authorizer = authManager.fetcherAuthorization  // GTMAppAuth
        //
        //   let calEvent = GTLRCalendar_Event()
        //   calEvent.summary = event.title
        //   calEvent.colorId = String(event.colorId)
        //   calEvent.start = GTLRCalendar_EventDateTime()
        //   calEvent.start?.dateTime = GTLRDateTime(date: event.startTime)
        //   calEvent.end = GTLRCalendar_EventDateTime()
        //   calEvent.end?.dateTime = GTLRDateTime(date: event.endTime)
        //
        //   let query = GTLRCalendarQuery_EventsInsert.query(
        //       withObject: calEvent, calendarId: "primary")
        //
        //   return try await withCheckedThrowingContinuation { continuation in
        //       service.executeQuery(query) { _, result, error in
        //           if let error { continuation.resume(throwing: error); return }
        //           let id = (result as? GTLRCalendar_Event)?.identifier ?? ""
        //           continuation.resume(returning: id)
        //       }
        //   }

        // --- Temporary plain URLSession implementation ---
        let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let formatter = ISO8601DateFormatter()
        let body: [String: Any] = [
            "summary": event.title,
            "colorId": String(event.colorId),
            "start":   ["dateTime": formatter.string(from: event.startTime)],
            "end":     ["dateTime": formatter.string(from: event.endTime)],
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw CalendarError.apiError(message)
        }

        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["id"] as? String ?? ""
    }
}

// MARK: - Errors

enum CalendarError: LocalizedError {
    case apiError(String)

    var errorDescription: String? {
        switch self {
        case .apiError(let message): return "Calendar API error: \(message)"
        }
    }
}
