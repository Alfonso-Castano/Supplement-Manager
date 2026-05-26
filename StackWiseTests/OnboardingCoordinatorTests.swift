import XCTest
import CoreData
@testable import StackWise

/// Tests for the OnboardingCoordinatorView smart-resume logic (REQ-18) and
/// trial trigger write-on-complete (REQ-19).
///
/// These stubs are RED until OnboardingCoordinatorView and its applySmartResume()
/// logic are implemented in Wave 1–3 plans.
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
        XCTFail("not yet implemented — implement after OnboardingCoordinatorView is built in Wave 1-3")
    }

    /// REQ-18: When UserProfile has age > 0 and weightKg > 0, and StackItem count == 0,
    /// coordinator path should equal [.stackEntry].
    func testResumeWithProfileFilledAndNoItems_startsAtStep2() throws {
        XCTFail("not yet implemented — implement after OnboardingCoordinatorView is built in Wave 1-3")
    }

    /// REQ-18: When UserProfile is filled and StackItem count > 0 but profile.wakeTime == nil,
    /// coordinator path should equal [.stackEntry, .scheduleInputs].
    func testResumeWithItemsAndNoWakeTime_startsAtStep3() throws {
        XCTFail("not yet implemented — implement after OnboardingCoordinatorView is built in Wave 1-3")
    }

    /// REQ-18: When UserProfile is filled, StackItem count > 0, and profile.wakeTime != nil,
    /// coordinator path should equal [.stackEntry, .scheduleInputs] and showPreview should be true.
    func testResumeWithAllData_showsPreview() throws {
        XCTFail("not yet implemented — implement after OnboardingCoordinatorView is built in Wave 1-3")
    }

    /// REQ-19: After completeOnboarding() equivalent logic is called, profile.trialStartDate != nil
    /// and profile.onboardingComplete == true. Tests the call chain from the coordinator's
    /// perspective (UserProfileStore.markOnboarded is already covered in UserProfileStoreTests).
    func testCompleteOnboarding_writesTrialStartDateAndSetsFlag() throws {
        XCTFail("not yet implemented — implement after OnboardingCoordinatorView is built in Wave 1-3")
    }
}
