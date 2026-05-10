import XCTest
import CoreData
@testable import StackWise

final class CoreDataSchemaTests: XCTestCase {

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

    func testCoreDataSchemaLoads() throws {
        let profile = UserProfile(context: context)
        profile.id = UUID()
        profile.onboardingComplete = false
        profile.subscriptionStatus = "unknown"
        XCTAssertNoThrow(try context.save(), "UserProfile save should not throw")
    }

    func testStackItemInsert() throws {
        let item = StackItem(context: context)
        item.id = UUID()
        item.isPrescription = false
        item.isInDatabase = false
        item.isActive = true
        item.sortOrder = 0
        XCTAssertNoThrow(try context.save(), "StackItem save should not throw")
    }

    func testScheduledDoseRelationship() throws {
        let item = StackItem(context: context)
        item.id = UUID()
        item.isPrescription = false
        item.isInDatabase = false
        item.isActive = true
        item.sortOrder = 0

        let dose = ScheduledDose(context: context)
        dose.id = UUID()
        dose.timeBlock = "morning"
        dose.position = 0
        dose.stackItem = item

        XCTAssertNoThrow(try context.save())

        let request = StackItem.fetchRequest()
        let items = try context.fetch(request)
        XCTAssertEqual(items.first?.scheduledDoses?.count, 1, "StackItem should have 1 ScheduledDose")
    }

    func testTransformableArrayRoundtrip() throws {
        let profile = UserProfile(context: context)
        profile.id = UUID()
        profile.onboardingComplete = false
        profile.allergies = ["peanuts", "shellfish"]

        XCTAssertNoThrow(try context.save())

        let request = UserProfile.fetchRequest()
        let profiles = try context.fetch(request)
        XCTAssertEqual(profiles.first?.allergies, ["peanuts", "shellfish"],
                       "Transformable [String] roundtrip should preserve array values")
    }

    func testDailyCheckOffInsert() throws {
        let checkOff = DailyCheckOff(context: context)
        checkOff.id = UUID()
        checkOff.completed = false
        checkOff.timeBlock = "morning"
        XCTAssertNoThrow(try context.save(), "DailyCheckOff save should not throw")
    }

    func testFeedbackItemInsert() throws {
        let feedback = FeedbackItem(context: context)
        feedback.id = UUID()
        feedback.submitted = false
        feedback.type = "general"
        XCTAssertNoThrow(try context.save(), "FeedbackItem save should not throw")
    }
}
