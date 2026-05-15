import XCTest
import CoreData
@testable import StackWise

final class ScheduleStoreTests: XCTestCase {

    // MARK: - Helpers

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

    private func makePreloadedStore(result: ScheduleResult) -> ScheduleStore {
        ScheduleStore(
            interactionRepo: InteractionRepository(),
            ingredientRepo: IngredientRepository(),
            context: { [unowned self] in self.container.viewContext },
            preloadedResult: result
        )
    }

    private var cal: Calendar { Calendar.current }
    private var now: Date { Date() }

    private func sampleResult() -> ScheduleResult {
        let morning = [
            ScheduledItem(
                id: UUID(),
                label: "Vitamin D",
                activeIngredient: "vitamin_d",
                dosage: "5000 IU",
                isPrescription: false,
                position: 0,
                suggestedTime: cal.date(bySettingHour: 7, minute: 0, second: 0, of: now)!,
                hasTimingConflict: false,
                hasSynergy: false
            )
        ]
        return ScheduleResult(morning: morning, afternoon: [], evening: [])
    }

    // MARK: - Tests

    func testCurrentScheduleReturnsCachedResult() {
        let expected = sampleResult()
        let store = makePreloadedStore(result: expected)
        let result = store.currentSchedule()
        XCTAssertEqual(result, expected)
    }

    func testInvalidateSetsDirtyFlag() {
        let store = makePreloadedStore(result: sampleResult())
        // Initially not dirty (preloaded).
        let firstResult = store.currentSchedule()
        XCTAssertEqual(firstResult.morning.count, 1)

        store.invalidate()
        // After invalidation, calling currentSchedule triggers recompute.
        // With no StackItems in the in-memory store, result should be empty.
        let afterInvalidate = store.currentSchedule()
        XCTAssertEqual(afterInvalidate, ScheduleResult.empty)
    }

    func testCurrentScheduleAfterInvalidateRecomputes() {
        let store = makePreloadedStore(result: sampleResult())
        XCTAssertEqual(store.currentSchedule().morning.count, 1)

        store.invalidate()
        // Recompute with empty Core Data -> empty result.
        let result = store.currentSchedule()
        XCTAssertTrue(result.morning.isEmpty)
        XCTAssertTrue(result.afternoon.isEmpty)
        XCTAssertTrue(result.evening.isEmpty)
    }

    func testEmptyStackYieldsEmptyResult() {
        // No preloaded result, but store starts dirty so recompute fires immediately.
        let store = ScheduleStore(
            interactionRepo: InteractionRepository(),
            ingredientRepo: IngredientRepository(),
            context: { [unowned self] in self.container.viewContext }
        )
        let result = store.currentSchedule()
        XCTAssertEqual(result, ScheduleResult.empty)
    }
}
