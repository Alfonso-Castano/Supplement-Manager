import XCTest
import CoreData
@testable import StackWise

@MainActor
final class TodayViewModelTests: XCTestCase {

    private var container: NSPersistentContainer!
    private var context: NSManagedObjectContext!

    override func setUp() {
        super.setUp()
        container = NSPersistentContainer(name: "StackWise")
        let desc = NSPersistentStoreDescription()
        desc.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [desc]
        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }
        context = container.viewContext
    }

    override func tearDown() {
        context = nil
        container = nil
        super.tearDown()
    }

    // MARK: - isPast logic

    // REQ-21: A block whose suggestedTime is before Date.now is classified as "past".
    func testIsPastReturnsTrueForPastSuggestedTime() throws {
        let pastTime = Calendar.current.date(byAdding: .hour, value: -2, to: Date())!
        let item = ScheduledItem(
            id: UUID(),
            label: "vitamin_d3",
            activeIngredient: "vitamin_d3",
            dosage: "2000 IU",
            isPrescription: false,
            position: 0,
            suggestedTime: pastTime,
            hasTimingConflict: false,
            hasSynergy: false,
            customTime: nil,
            scheduleNotes: nil
        )
        // TodayView.isPast checks first item's suggestedTime < Date()
        XCTAssertTrue(TodayView.isPastBlock(items: [item]),
                      "Block with past suggestedTime should be classified as past")
    }

    func testIsPastReturnsFalseForFutureSuggestedTime() throws {
        let futureTime = Calendar.current.date(byAdding: .hour, value: 2, to: Date())!
        let item = ScheduledItem(
            id: UUID(),
            label: "magnesium",
            activeIngredient: "magnesium",
            dosage: "400mg",
            isPrescription: false,
            position: 0,
            suggestedTime: futureTime,
            hasTimingConflict: false,
            hasSynergy: false,
            customTime: nil,
            scheduleNotes: nil
        )
        XCTAssertFalse(TodayView.isPastBlock(items: [item]),
                       "Block with future suggestedTime should not be classified as past")
    }

    func testIsPastReturnsFalseForEmptyItems() throws {
        XCTAssertFalse(TodayView.isPastBlock(items: []),
                       "Empty block should not be classified as past")
    }

    // MARK: - markComplete upsert logic

    // REQ-21: DailyCheckOff upsert uses startOfDay normalization.
    func testMarkCompleteWritesMidnightNormalizedDate() throws {
        TodayView.markCompleteBlock(timeBlock: "morning", in: context)

        let request = DailyCheckOff.fetchRequest()
        let results = try context.fetch(request)
        XCTAssertEqual(results.count, 1)

        let record = results.first!
        let expectedDate = Calendar.current.startOfDay(for: Date())
        XCTAssertEqual(record.checkOffDate, expectedDate,
                       "checkOffDate must be midnight-normalized via startOfDay")
        XCTAssertEqual(record.timeBlock, "morning")
        XCTAssertTrue(record.completed)
        XCTAssertNotNil(record.completedAt)
        XCTAssertNotNil(record.id)
    }

    // REQ-21: Second markComplete for same block does not create duplicate.
    func testMarkCompleteUpsertDoesNotDuplicate() throws {
        TodayView.markCompleteBlock(timeBlock: "afternoon", in: context)
        TodayView.markCompleteBlock(timeBlock: "afternoon", in: context)

        let request = DailyCheckOff.fetchRequest()
        request.predicate = NSPredicate(format: "timeBlock == %@", "afternoon")
        let results = try context.fetch(request)
        XCTAssertEqual(results.count, 1, "Upsert should not create duplicates")
    }

    // MARK: - isComplete logic

    func testIsCompleteReturnsTrueWhenRecordExists() throws {
        TodayView.markCompleteBlock(timeBlock: "evening", in: context)

        let today = Calendar.current.startOfDay(for: Date())
        let request = DailyCheckOff.fetchRequest()
        request.predicate = NSPredicate(format: "checkOffDate == %@", today as NSDate)
        let checkOffs = try context.fetch(request)

        let isComplete = checkOffs.contains { $0.timeBlockValue == "evening" && $0.completed }
        XCTAssertTrue(isComplete)
    }

    func testIsCompleteReturnsFalseWhenNoRecord() throws {
        let today = Calendar.current.startOfDay(for: Date())
        let request = DailyCheckOff.fetchRequest()
        request.predicate = NSPredicate(format: "checkOffDate == %@", today as NSDate)
        let checkOffs = try context.fetch(request)

        let isComplete = checkOffs.contains { $0.timeBlockValue == "morning" && $0.completed }
        XCTAssertFalse(isComplete)
    }
}
