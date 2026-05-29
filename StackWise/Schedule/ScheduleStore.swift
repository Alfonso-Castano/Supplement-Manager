import Foundation
import CoreData
import Observation

@MainActor
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
        cachedResult = nil
    }

    /// Returns cached result if clean; recomputes if dirty.
    @discardableResult
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

        let cal = Calendar.current
        let now = Date()
        let baseComponents = cal.dateComponents([.year, .month, .day], from: now)
        func pinned(_ hour: Int, _ minute: Int) -> Date {
            var c = baseComponents
            c.hour = hour; c.minute = minute; c.second = 0
            return cal.date(from: c)!
        }
        let wakeTime = profile?.wakeTime ?? pinned(7, 0)
        let breakfastTime = profile?.breakfastTime ?? pinned(7, 30)
        let lunchTime = profile?.lunchTime ?? pinned(12, 0)
        let dinnerTime = profile?.dinnerTime ?? pinned(18, 0)
        let sleepTime = profile?.sleepTime ?? pinned(22, 0)

        // 6. Build item projections and call engine (skip items with nil id).
        let projections: [ScheduleEngine.ItemProjection] = items.compactMap { item in
            guard let id = item.id else {
                assertionFailure("StackItem missing id")
                return nil
            }
            return ScheduleEngine.ItemProjection(
                id: id,
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

        let engineResult = ScheduleEngine.schedule(input)

        // Build StackItem lookup by id for override application and relationship assignment.
        let itemLookup: [UUID: StackItem] = Dictionary(
            uniqueKeysWithValues: items.compactMap { item in
                guard let id = item.id else { return nil }
                return (id, item)
            }
        )

        // 7. Apply user overrides (pinned blocks, custom times, notes) as post-processing.
        let result = applyUserOverrides(
            engineResult,
            itemLookup: itemLookup,
            breakfastTime: breakfastTime,
            lunchTime: lunchTime,
            dinnerTime: dinnerTime
        )

        // 8. Delete old ScheduledDose records, insert new ones using the overridden result.
        deleteAllScheduledDoses(in: ctx)

        for scheduledItem in result.morning {
            writeDose(scheduledItem, timeBlock: "morning", itemLookup: itemLookup, in: ctx)
        }
        for scheduledItem in result.afternoon {
            writeDose(scheduledItem, timeBlock: "afternoon", itemLookup: itemLookup, in: ctx)
        }
        for scheduledItem in result.evening {
            writeDose(scheduledItem, timeBlock: "evening", itemLookup: itemLookup, in: ctx)
        }

        do {
            try ctx.save()
        } catch {
            ctx.rollback()
            assertionFailure("ScheduleStore save failed: \(error)")
            return
        }

        // 9. Update cache.
        cachedResult = result
        dirty = false
        NotificationScheduler.reschedule(for: result)
    }

    private func deleteAllScheduledDoses(in ctx: NSManagedObjectContext) {
        let fetchRequest = ScheduledDose.fetchRequest()
        if let existing = try? ctx.fetch(fetchRequest) {
            for dose in existing { ctx.delete(dose) }
        }
    }

    private func writeDose(
        _ item: ScheduledItem,
        timeBlock: String,
        itemLookup: [UUID: StackItem],
        in ctx: NSManagedObjectContext
    ) {
        let dose = ScheduledDose(context: ctx)
        dose.id = UUID()
        dose.position = item.position
        dose.suggestedTime = item.customTime ?? item.suggestedTime
        dose.timeBlock = timeBlock
        dose.stackItem = itemLookup[item.id]
    }

    private func applyUserOverrides(
        _ result: ScheduleResult,
        itemLookup: [UUID: StackItem],
        breakfastTime: Date,
        lunchTime: Date,
        dinnerTime: Date
    ) -> ScheduleResult {
        var morning = result.morning
        var afternoon = result.afternoon
        var evening = result.evening

        for (id, stackItem) in itemLookup {
            let pinned = stackItem.pinnedBlock
            let customTime = stackItem.customScheduleTime
            let notes = stackItem.scheduleNotes

            if pinned == nil && customTime == nil && (notes == nil || notes!.isEmpty) { continue }

            // Notes-only: update in-place without changing block or position.
            if pinned == nil && customTime == nil {
                if let idx = morning.firstIndex(where: { $0.id == id }) {
                    morning[idx] = morning[idx].withOverride(customTime: nil, scheduleNotes: notes)
                } else if let idx = afternoon.firstIndex(where: { $0.id == id }) {
                    afternoon[idx] = afternoon[idx].withOverride(customTime: nil, scheduleNotes: notes)
                } else if let idx = evening.firstIndex(where: { $0.id == id }) {
                    evening[idx] = evening[idx].withOverride(customTime: nil, scheduleNotes: notes)
                }
                continue
            }

            // Pinned or custom-time: remove from engine-assigned block, re-append to target block.
            let original: ScheduledItem
            if let idx = morning.firstIndex(where: { $0.id == id }) {
                original = morning.remove(at: idx)
            } else if let idx = afternoon.firstIndex(where: { $0.id == id }) {
                original = afternoon.remove(at: idx)
            } else if let idx = evening.firstIndex(where: { $0.id == id }) {
                original = evening.remove(at: idx)
            } else {
                continue
            }

            let targetBlock: String
            if let pinned {
                targetBlock = pinned
            } else {
                targetBlock = inferBlock(from: customTime!, breakfastTime: breakfastTime, lunchTime: lunchTime, dinnerTime: dinnerTime)
            }

            let blockTime: Date
            switch targetBlock {
            case "afternoon": blockTime = lunchTime
            case "evening":   blockTime = dinnerTime
            default:          blockTime = breakfastTime
            }

            let updated = original.withOverride(
                customTime: customTime,
                scheduleNotes: notes,
                suggestedTime: customTime ?? blockTime
            )

            switch targetBlock {
            case "afternoon": afternoon.append(updated)
            case "evening":   evening.append(updated)
            default:          morning.append(updated)
            }
        }

        // Re-index positions within each block.
        func reindex(_ items: [ScheduledItem]) -> [ScheduledItem] {
            items.enumerated().map { idx, item in
                ScheduledItem(
                    id: item.id, label: item.label, activeIngredient: item.activeIngredient,
                    dosage: item.dosage, isPrescription: item.isPrescription,
                    position: Int16(idx), suggestedTime: item.suggestedTime,
                    hasTimingConflict: item.hasTimingConflict, hasSynergy: item.hasSynergy,
                    customTime: item.customTime, scheduleNotes: item.scheduleNotes
                )
            }
        }

        return ScheduleResult(morning: reindex(morning), afternoon: reindex(afternoon), evening: reindex(evening))
    }

    private func inferBlock(from time: Date, breakfastTime: Date, lunchTime: Date, dinnerTime: Date) -> String {
        let cal = Calendar.current
        let timeHour = cal.component(.hour, from: time) * 60 + cal.component(.minute, from: time)
        let lunchMinute = cal.component(.hour, from: lunchTime) * 60 + cal.component(.minute, from: lunchTime)
        let dinnerMinute = cal.component(.hour, from: dinnerTime) * 60 + cal.component(.minute, from: dinnerTime)
        if timeHour < lunchMinute { return "morning" }
        if timeHour < dinnerMinute { return "afternoon" }
        return "evening"
    }

    func saveOverride(for itemID: UUID, pinnedBlock: String?, customTime: Date?, notes: String?) {
        let ctx = context()
        let request = StackItem.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", itemID as CVarArg)
        request.fetchLimit = 1
        guard let item = (try? ctx.fetch(request))?.first else { return }
        item.pinnedBlock = pinnedBlock
        item.customScheduleTime = customTime
        item.scheduleNotes = (notes?.isEmpty == true) ? nil : notes
        do { try ctx.save() } catch { ctx.rollback() }
        invalidate()
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
