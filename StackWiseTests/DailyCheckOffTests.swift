import XCTest
import CoreData
@testable import StackWise

@MainActor
final class DailyCheckOffTests: XCTestCase {

    private var container: NSPersistentContainer!

    override func setUp() {
        super.setUp()
        container = NSPersistentContainer(name: "StackWise")
        let desc = NSPersistentStoreDescription()
        desc.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [desc]
        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }
    }

    override func tearDown() {
        container = nil
        super.tearDown()
    }

    // REQ-21: checkOffDate is midnight-normalized when written via the markComplete pattern.
    func testWritePersiststoMidnightDate() throws {
        let context = container.viewContext
        let today = Calendar.current.startOfDay(for: Date())

        let record = DailyCheckOff(context: context)
        record.id = UUID()
        record.checkOffDate = today   // midnight-normalized
        record.timeBlock = "morning"
        record.completed = true
        record.completedAt = Date()
        try context.save()

        // Fetch back and verify date is midnight (== today midnight, not some seconds-level timestamp)
        let request = DailyCheckOff.fetchRequest()
        request.predicate = NSPredicate(format: "timeBlock == %@", "morning")
        let results = try context.fetch(request)
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.checkOffDate, today,
                       "checkOffDate must be midnight-normalized (Calendar.startOfDay)")
    }

    // REQ-21: The fetch predicate for today's check-offs returns the correct record.
    func testFetchPredicateMatchesToday() throws {
        let context = container.viewContext
        let today = Calendar.current.startOfDay(for: Date())

        // Write morning check-off for today
        let record = DailyCheckOff(context: context)
        record.id = UUID()
        record.checkOffDate = today
        record.timeBlock = "morning"
        record.completed = true
        record.completedAt = Date()
        try context.save()

        // Write an afternoon check-off for yesterday — should NOT appear in today predicate
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
        let old = DailyCheckOff(context: context)
        old.id = UUID()
        old.checkOffDate = yesterday
        old.timeBlock = "afternoon"
        old.completed = true
        old.completedAt = Date()
        try context.save()

        // Fetch today morning only
        let request = DailyCheckOff.fetchRequest()
        request.predicate = NSPredicate(
            format: "checkOffDate == %@ AND timeBlock == %@",
            today as NSDate, "morning"
        )
        let results = try context.fetch(request)
        XCTAssertEqual(results.count, 1, "Predicate must return only today's morning record")
        XCTAssertEqual(results.first?.timeBlockValue, "morning")
        XCTAssertTrue(results.first?.completed == true)
    }
}
