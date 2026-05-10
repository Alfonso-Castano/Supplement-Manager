import CoreData

@objc(UserProfile)
public class UserProfile: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var age: Int16
    @NSManaged public var sex: String?
    @NSManaged public var weightKg: Double
    @NSManaged public var allergies: [String]?      // Transformable — NSArray / NSSecureUnarchiveFromData
    @NSManaged public var conditions: [String]?     // Transformable — NSArray / NSSecureUnarchiveFromData
    @NSManaged public var wakeTime: Date?
    @NSManaged public var sleepTime: Date?
    @NSManaged public var breakfastTime: Date?
    @NSManaged public var lunchTime: Date?
    @NSManaged public var dinnerTime: Date?
    @NSManaged public var onboardingComplete: Bool
    @NSManaged public var trialStartDate: Date?
    @NSManaged public var subscriptionStatus: String?

    var allergiesList: [String] { allergies ?? [] }
    var conditionsList: [String] { conditions ?? [] }
    var subscriptionStatusValue: String { subscriptionStatus ?? "unknown" }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfile> {
        return NSFetchRequest<UserProfile>(entityName: "UserProfile")
    }
}
