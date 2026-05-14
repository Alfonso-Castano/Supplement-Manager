import XCTest
import CoreData
@testable import StackWise

final class StackItemFactoryTests: XCTestCase {

    var controller: PersistenceController!
    var context: NSManagedObjectContext!

    override func setUpWithError() throws {
        controller = PersistenceController(inMemory: true)
        context = controller.container.viewContext
    }

    override func tearDownWithError() throws {
        controller = nil
        context = nil
    }

    func testCreatesStackItemWithCanonicalNameWhenMatched() throws {
        let match = IngredientMatch(id: 1, canonicalName: "Vitamin D3",
                                    itemType: "supplement", matchedAlias: "D3")
        let input = StackItemFactory.Input(label: "vitamin d",
                                           dosage: "2000 IU",
                                           frequency: "daily",
                                           isPrescription: false,
                                           match: match)
        let item = try StackItemFactory.create(input, in: context)

        XCTAssertEqual(item.label, "Vitamin D3", "Label must be normalized to canonical name when matched")
        XCTAssertEqual(item.activeIngredient, "Vitamin D3",
                       "activeIngredient must equal canonical_name for interaction analysis to find this item")
        XCTAssertEqual(item.itemType, "supplement")
        XCTAssertTrue(item.isInDatabase)
        XCTAssertEqual(item.dosage, "2000 IU")
        XCTAssertEqual(item.frequency, "daily")
        XCTAssertTrue(item.isActive)
        XCTAssertNotNil(item.addedDate)
        XCTAssertNotNil(item.id)
    }

    func testCreatesStackItemUnmatchedFlaggedNotInDatabase() throws {
        let input = StackItemFactory.Input(label: "Banana extract",
                                           dosage: "1 capsule",
                                           frequency: "daily",
                                           isPrescription: false,
                                           match: nil)
        let item = try StackItemFactory.create(input, in: context)

        XCTAssertEqual(item.label, "Banana extract", "Unmatched item keeps user-entered label as-is (trimmed)")
        XCTAssertEqual(item.activeIngredient, "Banana extract")
        XCTAssertFalse(item.isInDatabase, "Custom items must be flagged so the interaction engine can warn")
        XCTAssertEqual(item.itemType, "supplement", "Defaults to supplement when no match and not prescription")
    }

    func testPrescriptionFlagRoutesItemTypeToDrug() throws {
        let input = StackItemFactory.Input(label: "Custom Rx",
                                           dosage: "10 mg",
                                           frequency: "daily",
                                           isPrescription: true,
                                           match: nil)
        let item = try StackItemFactory.create(input, in: context)
        XCTAssertEqual(item.itemType, "drug")
        XCTAssertTrue(item.isPrescription)
    }

    func testMatchedItemTypeWinsOverPrescriptionToggle() throws {
        let match = IngredientMatch(id: 99, canonicalName: "Aspirin",
                                    itemType: "drug", matchedAlias: nil)
        let input = StackItemFactory.Input(label: "aspirin",
                                           dosage: "81 mg",
                                           frequency: "daily",
                                           isPrescription: false,
                                           match: match)
        let item = try StackItemFactory.create(input, in: context)
        XCTAssertEqual(item.itemType, "drug",
                       "DB-resolved itemType is authoritative regardless of prescription toggle")
    }

    func testSortOrderMonotonicallyIncreasesAcrossInserts() throws {
        let first = try StackItemFactory.create(.init(label: "A", dosage: "", frequency: "daily",
                                                      isPrescription: false, match: nil), in: context)
        let second = try StackItemFactory.create(.init(label: "B", dosage: "", frequency: "daily",
                                                       isPrescription: false, match: nil), in: context)
        let third = try StackItemFactory.create(.init(label: "C", dosage: "", frequency: "daily",
                                                      isPrescription: false, match: nil), in: context)
        XCTAssertEqual(first.sortOrder, 0)
        XCTAssertEqual(second.sortOrder, 1)
        XCTAssertEqual(third.sortOrder, 2)
    }
}
