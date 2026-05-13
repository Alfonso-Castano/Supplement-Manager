import CoreData

@objc(DailyCheckOff)
public class DailyCheckOff: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var checkOffDate: Date?        // Normalized to midnight
    @NSManaged public var timeBlock: String?        // "morning", "afternoon", "evening"
    @NSManaged public var completed: Bool
    @NSManaged public var completedAt: Date?

    var timeBlockValue: String { timeBlock ?? "morning" }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<DailyCheckOff> {
        return NSFetchRequest<DailyCheckOff>(entityName: "DailyCheckOff")
    }
}
