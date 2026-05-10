import CoreData

@objc(ScheduledDose)
public class ScheduledDose: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var timeBlock: String?        // "morning", "afternoon", "evening"
    @NSManaged public var suggestedTime: Date?
    @NSManaged public var position: Int16
    @NSManaged public var stackItem: StackItem?

    var timeBlockValue: String { timeBlock ?? "morning" }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ScheduledDose> {
        return NSFetchRequest<ScheduledDose>(entityName: "ScheduledDose")
    }
}
