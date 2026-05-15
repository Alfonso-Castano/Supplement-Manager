import Foundation
import CoreData
import Observation

@Observable
final class ScheduleStore {
    private(set) var cachedResult: ScheduleResult? = nil
    private var dirty = true

    private let interactionRepo: InteractionRepository
    private let ingredientRepo: IngredientRepository
    private let context: () -> NSManagedObjectContext

    init(
        interactionRepo: InteractionRepository,
        ingredientRepo: IngredientRepository,
        context: @escaping () -> NSManagedObjectContext
    ) {
        self.interactionRepo = interactionRepo
        self.ingredientRepo = ingredientRepo
        self.context = context
    }

    func invalidate() {
        dirty = true
    }

    /// Returns cached result if clean; recomputes if dirty.
    func currentSchedule() -> ScheduleResult {
        if dirty || cachedResult == nil {
            recompute()
        }
        return cachedResult ?? ScheduleResult.empty
    }

    private func recompute() {
        let ctx = context()

        // 1. Fetch all active StackItems.
        let request = StackItem.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        let items: [StackItem] = (try? ctx.fetch(request)) ?? []

        guard !items.isEmpty else {
            deleteAllScheduledDoses(in: ctx)
            cachedResult = .empty
            dirty = false
            return
        }

        // 2. Build slug set for DB-matched items.
        let slugs: Set<String> = Set(
            items.compactMap { $0.isInDatabase ? $0.activeIngredientValue : nil }
                .filter { !$0.isEmpty }
        )

        // 3. Fetch interaction pairs and map to PairProjection.
        let rawPairs = interactionRepo.pairwise(for: slugs)
        let pairs: [ScheduleEngine.PairProjection] = rawPairs.map { pair in
            ScheduleEngine.PairProjection(
                slugA: pair.compoundA,
                slugB: pair.compoundB,
                timingRelevant: pair.timingRelevant,
                timingWindowHours: pair.timingWindowHours,
                isSynergy: pair.interactionType == .synergy
            )
        }

        // 4. Build timing properties dictionary.
        var timingProps: [String: TimingProperties] = [:]
        for slug in slugs {
            timingProps[slug] = ingredientRepo.timingProperties(for: slug)
        }

        // 5. Fetch UserProfile for meal/wake times.
        let profileRequest = UserProfile.fetchRequest()
        profileRequest.fetchLimit = 1
        let profile = (try? ctx.fetch(profileRequest))?.first

        let now = Date()
        let cal = Calendar.current
        let wakeTime = profile?.wakeTime ?? cal.date(bySettingHour: 7, minute: 0, second: 0, of: now)!
        let breakfastTime = profile?.breakfastTime ?? cal.date(bySettingHour: 7, minute: 30, second: 0, of: now)!
        let lunchTime = profile?.lunchTime ?? cal.date(bySettingHour: 12, minute: 0, second: 0, of: now)!
        let dinnerTime = profile?.dinnerTime ?? cal.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
        let sleepTime = profile?.sleepTime ?? cal.date(bySettingHour: 22, minute: 0, second: 0, of: now)!

        // 6. Build item projections and call engine.
        let projections: [ScheduleEngine.ItemProjection] = items.map { item in
            ScheduleEngine.ItemProjection(
                id: item.id ?? UUID(),
                label: item.labelValue,
                activeIngredient: item.activeIngredientValue,
                dosage: item.dosage ?? "",
                isPrescription: item.isPrescription,
                isInDatabase: item.isInDatabase,
                sortOrder: item.sortOrder
            )
        }

        let input = ScheduleEngine.Input(
            items: projections,
            pairs: pairs,
            timingProps: timingProps,
            wakeTime: wakeTime,
            breakfastTime: breakfastTime,
            lunchTime: lunchTime,
            dinnerTime: dinnerTime,
            sleepTime: sleepTime
        )

        let result = ScheduleEngine.schedule(input)

        // 7. Delete old ScheduledDose records, insert new ones.
        deleteAllScheduledDoses(in: ctx)

        // Build StackItem lookup by id for relationship assignment.
        let itemLookup: [UUID: StackItem] = Dictionary(
            uniqueKeysWithValues: items.compactMap { item in
                guard let id = item.id else { return nil }
                return (id, item)
            }
        )

        for scheduledItem in result.allItems() {
            let dose = ScheduledDose(context: ctx)
            dose.id = UUID()
            dose.position = scheduledItem.position
            dose.suggestedTime = scheduledItem.suggestedTime
            // Determine timeBlock from position in result.
            if result.morning.contains(where: { $0.id == scheduledItem.id }) {
                dose.timeBlock = "morning"
            } else if result.afternoon.contains(where: { $0.id == scheduledItem.id }) {
                dose.timeBlock = "afternoon"
            } else {
                dose.timeBlock = "evening"
            }
            dose.stackItem = itemLookup[scheduledItem.id]
        }

        try? ctx.save()

        // 8. Update cache.
        cachedResult = result
        dirty = false
    }

    private func deleteAllScheduledDoses(in ctx: NSManagedObjectContext) {
        let fetchRequest = ScheduledDose.fetchRequest()
        if let existing = try? ctx.fetch(fetchRequest) {
            for dose in existing {
                ctx.delete(dose)
            }
        }
    }

    #if DEBUG
    init(
        interactionRepo: InteractionRepository,
        ingredientRepo: IngredientRepository,
        context: @escaping () -> NSManagedObjectContext,
        preloadedResult: ScheduleResult
    ) {
        self.interactionRepo = interactionRepo
        self.ingredientRepo = ingredientRepo
        self.context = context
        self.cachedResult = preloadedResult
        self.dirty = false
    }
    #endif
}
