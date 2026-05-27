import UserNotifications
import Foundation

enum NotificationScheduler {

    // Package-internal: pure, synchronous content builder — testable without mocking UNUserNotificationCenter.
    static func buildRequests(for result: ScheduleResult) -> [UNNotificationRequest] {
        let cal = Calendar.current
        let blocks: [(name: String, items: [ScheduledItem], identifier: String)] = [
            ("morning",   result.morning,   "morning_reminder"),
            ("afternoon", result.afternoon, "afternoon_reminder"),
            ("evening",   result.evening,   "evening_reminder"),
        ]
        var requests: [UNNotificationRequest] = []
        for block in blocks {
            guard !block.items.isEmpty, let firstItem = block.items.first else { continue }

            let content = UNMutableNotificationContent()
            content.title = "Time for your \(block.name) supplements"
            content.body = block.items.map(\.label).joined(separator: ", ")
            content.sound = .default
            content.categoryIdentifier = block.identifier

            let components = cal.dateComponents([.hour, .minute], from: firstItem.suggestedTime)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

            requests.append(UNNotificationRequest(
                identifier: block.identifier,
                content: content,
                trigger: trigger
            ))
        }
        return requests
    }

    static func reschedule(for result: ScheduleResult) {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            guard settings.authorizationStatus == .authorized else { return }

            center.removeAllPendingNotificationRequests()
            for request in buildRequests(for: result) {
                try? await center.add(request)
            }
        }
    }
}
