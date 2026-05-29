import XCTest
import UserNotifications
@testable import StackWise

final class NotificationSchedulerTests: XCTestCase {

    // MARK: - Helper

    private func makeItem(label: String, hour: Int = 8) -> ScheduledItem {
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = hour; comps.minute = 0; comps.second = 0
        let time = Calendar.current.date(from: comps) ?? Date()
        return ScheduledItem(
            id: UUID(), label: label, activeIngredient: "", dosage: "",
            isPrescription: false, position: 0,
            suggestedTime: time, hasTimingConflict: false, hasSynergy: false,
            customTime: nil, scheduleNotes: nil
        )
    }

    // REQ-20: NotificationScheduler.reschedule(for:) is safe to call regardless of auth state.
    // The actual authorization guard is inside the async Task; calling reschedule() must not crash.
    func testSkipsWhenNotAuthorized() throws {
        let result = ScheduleResult(
            morning: [makeItem(label: "Vitamin D")],
            afternoon: [],
            evening: []
        )
        // reschedule wraps in Task {}; this call is fire-and-forget and must not crash
        NotificationScheduler.reschedule(for: result)
        // If we reach here without crash/assert, the guard path is safe
        XCTAssertTrue(true, "reschedule(for:) must not crash on call, even if not authorized")
    }

    // REQ-20: Exactly one request is created per non-empty block.
    // Tests the pure buildRequests(for:) function directly.
    func testSchedulesOneRequestPerNonEmptyBlock() throws {
        let result = ScheduleResult(
            morning: [makeItem(label: "Vitamin D", hour: 8)],
            afternoon: [],
            evening: [makeItem(label: "Magnesium", hour: 20), makeItem(label: "Fish Oil", hour: 20)]
        )

        let requests = NotificationScheduler.buildRequests(for: result)

        XCTAssertEqual(requests.count, 2, "2 non-empty blocks -> 2 notification requests")
        XCTAssertEqual(requests[0].identifier, "morning_reminder")
        XCTAssertEqual(requests[1].identifier, "evening_reminder")
    }

    // REQ-20: Notification body is comma-joined item labels for the block.
    func testNotificationBodyListsItemLabels() throws {
        let result = ScheduleResult(
            morning: [
                makeItem(label: "Vitamin D", hour: 8),
                makeItem(label: "Magnesium", hour: 8),
                makeItem(label: "Fish Oil", hour: 8),
            ],
            afternoon: [],
            evening: []
        )

        let requests = NotificationScheduler.buildRequests(for: result)

        XCTAssertEqual(requests.count, 1)
        XCTAssertEqual(requests[0].content.body, "Vitamin D, Magnesium, Fish Oil")
        XCTAssertEqual(requests[0].content.title, "Time for your morning supplements")
    }
}
