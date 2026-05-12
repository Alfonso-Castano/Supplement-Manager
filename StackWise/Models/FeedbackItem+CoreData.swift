import CoreData

@objc(FeedbackItem)
public class FeedbackItem: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var type: String?             // "incorrect_interaction", "schedule_issue", "general"
    @NSManaged public var context: String?
    @NSManaged public var body: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var submitted: Bool

    var typeValue: String { type ?? "general" }
    var bodyValue: String { body ?? "" }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<FeedbackItem> {
        return NSFetchRequest<FeedbackItem>(entityName: "FeedbackItem")
    }
}
