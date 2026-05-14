import CoreData

enum StackItemFactory {

    struct Input {
        var label: String
        var dosage: String
        var frequency: String
        var isPrescription: Bool
        var match: IngredientMatch?
    }

    @discardableResult
    static func create(_ input: Input, in context: NSManagedObjectContext) throws -> StackItem {
        let trimmedLabel = input.label.trimmingCharacters(in: .whitespaces)
        precondition(!trimmedLabel.isEmpty, "StackItemFactory requires a non-empty label")

        let item = StackItem(context: context)
        item.id = UUID()
        item.label = input.match?.canonicalName ?? trimmedLabel
        item.activeIngredient = input.match?.canonicalName ?? trimmedLabel
        item.itemType = input.match?.itemType ?? (input.isPrescription ? "drug" : "supplement")
        item.isPrescription = input.isPrescription
        item.isInDatabase = (input.match != nil)
        item.dosage = input.dosage.trimmingCharacters(in: .whitespaces)
        item.frequency = input.frequency
        item.addedDate = .now
        item.isActive = true
        item.sortOrder = Int16(nextSortOrder(in: context))

        try context.save()
        return item
    }

    static func nextSortOrder(in context: NSManagedObjectContext) -> Int {
        let request = StackItem.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: false)]
        request.fetchLimit = 1
        if let highest = (try? context.fetch(request))?.first {
            return Int(highest.sortOrder) + 1
        }
        return 0
    }
}
