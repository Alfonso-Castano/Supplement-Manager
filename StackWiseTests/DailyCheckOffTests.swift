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

    // REQ-21: DailyCheckOff write persists with correct timeBlock and midnight-normalized date.
    func testWritePersiststoMidnightDate() throws {
        XCTFail("not implemented — fill in Plan 05")
    }

    // REQ-21: DailyCheckOff fetch predicate returns correct record for today.
    func testFetchPredicateMatchesToday() throws {
        XCTFail("not implemented — fill in Plan 05")
    }
}
