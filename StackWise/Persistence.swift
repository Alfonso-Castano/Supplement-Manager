import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let context = result.container.viewContext

        let profile = UserProfile(context: context)
        profile.id = UUID()
        profile.age = 30
        profile.sex = "unspecified"
        profile.weightKg = 70.0
        profile.allergies = []
        profile.conditions = []
        profile.wakeTime = Date()
        profile.sleepTime = Date()
        profile.onboardingComplete = true
        profile.subscriptionStatus = "trial"

        let item = StackItem(context: context)
        item.id = UUID()
        item.label = "Vitamin D"
        item.activeIngredient = "Cholecalciferol"
        item.itemType = "supplement"
        item.isPrescription = false
        item.isInDatabase = true
        item.dosage = "2000 IU"
        item.frequency = "daily"
        item.addedDate = Date()
        item.isActive = true
        item.sortOrder = 0

        let dose = ScheduledDose(context: context)
        dose.id = UUID()
        dose.timeBlock = "morning"
        dose.suggestedTime = Date()
        dose.position = 0
        dose.stackItem = item

        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            fatalError("Preview seed failed: \(nsError), \(nsError.userInfo)")
        }
        return result
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "StackWise")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        let storeDescription = container.persistentStoreDescriptions.first!
        storeDescription.setOption(true as NSNumber, forKey: NSMigratePersistentStoresAutomaticallyOption)
        storeDescription.setOption(true as NSNumber, forKey: NSInferMappingModelAutomaticallyOption)
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // TODO Phase 9: Replace fatalError with user-facing error screen before App Store submission
                // T-01-01: fatalError is acceptable during development (standard Xcode template pattern)
                fatalError("Unresolved Core Data error \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
