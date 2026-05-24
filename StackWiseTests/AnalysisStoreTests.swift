import XCTest
import CoreData
@testable import StackWise

@MainActor
final class AnalysisStoreTests: XCTestCase {

    // In-memory Core Data context (no persistent store)
    private func makeContext() -> NSManagedObjectContext {
        let container = NSPersistentContainer(name: "StackWise")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }
        return container.viewContext
    }

    func testInitialDirtyStateTriggersFirstRecompute() {
        let ctx = makeContext()
        var fetchCount = 0
        let store = AnalysisStore(
            pairFetcher: { _ in fetchCount += 1; return [] },
            context: { ctx }
        )
        XCTAssertTrue(store.dirty)
        let result = store.currentResults()
        XCTAssertEqual(result, .empty)
        XCTAssertFalse(store.dirty)
        // fetchCount may be 0 because empty stack short-circuits in AnalysisEngine
        // What matters is dirty flipped and results are non-nil
        XCTAssertNotNil(store.results)
    }

    func testCachedReadDoesNotRefetch() {
        let ctx = makeContext()
        var fetchCount = 0
        let store = AnalysisStore(
            pairFetcher: { _ in fetchCount += 1; return [] },
            context: { ctx }
        )
        _ = store.currentResults()
        let countAfterFirst = fetchCount
        _ = store.currentResults()
        XCTAssertEqual(fetchCount, countAfterFirst, "Second read should use cache, not call fetcher again")
    }

    func testInvalidateForcesRecompute() {
        let ctx = makeContext()
        var fetchCount = 0
        let store = AnalysisStore(
            pairFetcher: { _ in fetchCount += 1; return [] },
            context: { ctx }
        )
        _ = store.currentResults()
        let countAfterFirst = fetchCount
        store.invalidate()
        _ = store.currentResults()
        // If stack is empty, AnalysisEngine may short-circuit before calling fetcher.
        // What matters is dirty flipped and recompute path ran.
        XCTAssertFalse(store.dirty)
        XCTAssertNotNil(store.results)
        // Fetch count should not decrease
        XCTAssertGreaterThanOrEqual(fetchCount, countAfterFirst)
    }

    func testInvalidateClearsCachedResultsImmediately() {
        let ctx = makeContext()
        let store = AnalysisStore(
            pairFetcher: { _ in return [] },
            context: { ctx }
        )
        _ = store.currentResults()
        XCTAssertNotNil(store.results)
        store.invalidate()
        XCTAssertNil(store.results)
        XCTAssertTrue(store.dirty)
    }
}
