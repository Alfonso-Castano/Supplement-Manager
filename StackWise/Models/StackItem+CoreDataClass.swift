import CoreData

@objc(StackItem)
public class StackItem: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID?
    @NSManaged public var label: String?
    @NSManaged public var activeIngredient: String?
    @NSManaged public var itemType: String?         // "supplement" or "drug"
    @NSManaged public var isPrescription: Bool
    @NSManaged public var isInDatabase: Bool
    @NSManaged public var dosage: String?
    @NSManaged public var frequency: String?
    @NSManaged public var addedDate: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var sortOrder: Int16
    @NSManaged public var customScheduleTime: Date?
    @NSManaged public var pinnedBlock: String?
    @NSManaged public var scheduleNotes: String?
    @NSManaged public var scheduledDoses: NSSet?

    var labelValue: String { label ?? "" }
    var activeIngredientValue: String { activeIngredient ?? "" }
    var itemTypeValue: String { itemType ?? "supplement" }
    var scheduledDosesArray: [ScheduledDose] {
        (scheduledDoses?.allObjects as? [ScheduledDose] ?? []).sorted { $0.position < $1.position }
    }

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StackItem> {
        return NSFetchRequest<StackItem>(entityName: "StackItem")
    }
}
