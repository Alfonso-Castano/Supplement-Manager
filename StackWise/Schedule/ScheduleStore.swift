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
    /// Recompute is implemented in Plan 04-02.
    func currentSchedule() -> ScheduleResult {
        if dirty || cachedResult == nil {
            recompute()
        }
        return cachedResult ?? ScheduleResult.empty
    }

    private func recompute() {
        // TODO (04-02): fetch items, call ScheduleEngine, write ScheduledDose, update cachedResult.
        dirty = false
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
