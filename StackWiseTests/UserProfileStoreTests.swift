import XCTest
import CoreData
@testable import StackWise

final class UserProfileStoreTests: XCTestCase {

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

    func testFetchOrCreateCreatesOnFirstCall() throws {
        let request = UserProfile.fetchRequest()
        XCTAssertEqual(try context.count(for: request), 0, "Precondition: empty store")

        let profile = UserProfileStore.fetchOrCreate(in: context)
        XCTAssertEqual(try context.count(for: request), 1)
        XCTAssertFalse(profile.onboardingComplete, "New profile must default to onboardingComplete=false")
        XCTAssertNotNil(profile.id)
    }

    func testFetchOrCreateIsIdempotent() throws {
        let first = UserProfileStore.fetchOrCreate(in: context)
        let second = UserProfileStore.fetchOrCreate(in: context)
        XCTAssertEqual(first.objectID, second.objectID,
                       "Repeated calls must return the same managed object")

        let count = try context.count(for: UserProfile.fetchRequest())
        XCTAssertEqual(count, 1, "Only one UserProfile row should exist after multiple fetchOrCreate calls")
    }

    func testMarkOnboardedFlipsFlagAndPersists() throws {
        let profile = UserProfileStore.fetchOrCreate(in: context)
        XCTAssertFalse(profile.onboardingComplete)

        UserProfileStore.markOnboarded(profile, in: context)
        XCTAssertTrue(profile.onboardingComplete)
        XCTAssertNotNil(profile.trialStartDate, "markOnboarded should set trialStartDate on first transition")

        context.refreshAllObjects()
        let refetched = UserProfileStore.fetchOrCreate(in: context)
        XCTAssertTrue(refetched.onboardingComplete, "Onboarded flag must survive a context refresh")
    }

    func testParseListHandlesEdgeCases() throws {
        XCTAssertEqual(HealthProfileView.parseList(""), [])
        XCTAssertEqual(HealthProfileView.parseList("   "), [])
        XCTAssertEqual(HealthProfileView.parseList("peanuts"), ["peanuts"])
        XCTAssertEqual(HealthProfileView.parseList("peanuts, shellfish"), ["peanuts", "shellfish"])
        XCTAssertEqual(HealthProfileView.parseList("peanuts,  ,shellfish, "), ["peanuts", "shellfish"],
                       "Empty segments and surrounding whitespace must be stripped")
    }
}
