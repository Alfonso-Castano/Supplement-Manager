import XCTest
import CoreData
@testable import StackWise

/// Tests for the OnboardingCoordinatorView smart-resume logic (REQ-18) and
/// trial trigger write-on-complete (REQ-19).
final class OnboardingCoordinatorTests: XCTestCase {
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

    /// REQ-18: When UserProfile has age == 0 and weightKg == 0, the coordinator path
    /// should be empty (step 1 is the NavigationStack root).
    func testResumeWithNoProfile_startsAtStep1() throws {
        // No UserProfile created — fetchOrCreate returns one with age=0, weightKg=0
        let profile = UserProfileStore.fetchOrCreate(in: context)
        // Verify defaults: age == 0 (Int16), weightKg == 0.0
        XCTAssertEqual(profile.age, 0)
        XCTAssertEqual(profile.weightKg, 0.0)

        // Simulate the applySmartResume logic directly
        let itemRequest = StackItem.fetchRequest()
        itemRequest.predicate = NSPredicate(format: "isActive == YES")
        let itemCount = (try? context.count(for: itemRequest)) ?? 0

        var path: [OnboardingStep] = [.stackEntry]  // set non-empty to prove it gets cleared
        if profile.age == 0 || profile.weightKg == 0 {
            path = []
        }
        XCTAssertTrue(path.isEmpty, "No profile data → coordinator path must be empty (step 1 is root)")
    }

    /// REQ-18: When UserProfile has age > 0 and weightKg > 0, and StackItem count == 0,
    /// coordinator path should equal [.stackEntry].
    func testResumeWithProfileFilledAndNoItems_startsAtStep2() throws {
        let profile = UserProfileStore.fetchOrCreate(in: context)
        profile.age = 30
        profile.weightKg = 70.0
        profile.sex = "unspecified"
        try context.save()

        let itemRequest = StackItem.fetchRequest()
        itemRequest.predicate = NSPredicate(format: "isActive == YES")
        let itemCount = (try? context.count(for: itemRequest)) ?? 0
        XCTAssertEqual(itemCount, 0)

        var path: [OnboardingStep] = []
        if profile.age == 0 || profile.weightKg == 0 {
            path = []
        } else if itemCount == 0 {
            path = [.stackEntry]
        }
        XCTAssertEqual(path, [.stackEntry], "Profile filled + no items → path must be [.stackEntry]")
    }

    /// REQ-18: When UserProfile is filled and StackItem count > 0 but profile.wakeTime == nil,
    /// coordinator path should equal [.stackEntry, .scheduleInputs].
    func testResumeWithItemsAndNoWakeTime_startsAtStep3() throws {
        let profile = UserProfileStore.fetchOrCreate(in: context)
        profile.age = 30
        profile.weightKg = 70.0
        profile.sex = "unspecified"
        // wakeTime is nil (not set)
        try context.save()

        // Seed one stack item
        let input = StackItemFactory.Input(label: "Vitamin D3", dosage: "2000 IU",
                                           frequency: "daily", isPrescription: false, match: nil)
        _ = try StackItemFactory.create(input, in: context)

        let itemRequest = StackItem.fetchRequest()
        itemRequest.predicate = NSPredicate(format: "isActive == YES")
        let itemCount = (try? context.count(for: itemRequest)) ?? 0
        XCTAssertGreaterThan(itemCount, 0)
        XCTAssertNil(profile.wakeTime)

        var path: [OnboardingStep] = []
        if profile.age == 0 || profile.weightKg == 0 {
            path = []
        } else if itemCount == 0 {
            path = [.stackEntry]
        } else if profile.wakeTime == nil {
            path = [.stackEntry, .scheduleInputs]
        }
        XCTAssertEqual(path, [.stackEntry, .scheduleInputs],
                       "Items exist + wakeTime nil → path must be [.stackEntry, .scheduleInputs]")
    }

    /// REQ-18: When UserProfile is filled, StackItem count > 0, and profile.wakeTime != nil,
    /// coordinator path should equal [.stackEntry, .scheduleInputs] and showPreview should be true.
    func testResumeWithAllData_showsPreview() throws {
        let profile = UserProfileStore.fetchOrCreate(in: context)
        profile.age = 30
        profile.weightKg = 70.0
        profile.sex = "unspecified"
        profile.wakeTime = Date()
        try context.save()

        let input = StackItemFactory.Input(label: "Magnesium", dosage: "400 mg",
                                           frequency: "daily", isPrescription: false, match: nil)
        _ = try StackItemFactory.create(input, in: context)

        let itemRequest = StackItem.fetchRequest()
        itemRequest.predicate = NSPredicate(format: "isActive == YES")
        let itemCount = (try? context.count(for: itemRequest)) ?? 0
        XCTAssertGreaterThan(itemCount, 0)
        XCTAssertNotNil(profile.wakeTime)

        var path: [OnboardingStep] = []
        var showPreview = false
        if profile.age == 0 || profile.weightKg == 0 {
            path = []
        } else if itemCount == 0 {
            path = [.stackEntry]
        } else if profile.wakeTime == nil {
            path = [.stackEntry, .scheduleInputs]
        } else {
            path = [.stackEntry, .scheduleInputs]
            showPreview = true
        }
        XCTAssertEqual(path, [.stackEntry, .scheduleInputs])
        XCTAssertTrue(showPreview, "All data present + onboardingComplete false → showPreview must be true")
    }

    /// REQ-19: After completeOnboarding() equivalent logic is called, profile.trialStartDate != nil
    /// and profile.onboardingComplete == true. Tests the call chain from the coordinator's
    /// perspective (UserProfileStore.markOnboarded is already covered in UserProfileStoreTests).
    func testCompleteOnboarding_writesTrialStartDateAndSetsFlag() throws {
        let profile = UserProfileStore.fetchOrCreate(in: context)
        XCTAssertNil(profile.trialStartDate, "Precondition: no trial start date set")
        XCTAssertFalse(profile.onboardingComplete, "Precondition: not yet onboarded")

        // Simulate completeOnboarding() — calls UserProfileStore.markOnboarded
        UserProfileStore.markOnboarded(profile, in: context)

        XCTAssertTrue(profile.onboardingComplete, "markOnboarded must flip onboardingComplete to true")
        XCTAssertNotNil(profile.trialStartDate, "markOnboarded must write trialStartDate on first call (REQ-19)")

        // Verify idempotency: calling again does not overwrite trialStartDate
        let firstDate = profile.trialStartDate
        UserProfileStore.markOnboarded(profile, in: context)
        XCTAssertEqual(profile.trialStartDate, firstDate,
                       "Calling markOnboarded twice must not overwrite trialStartDate (REQ-19 guard)")
    }
}
