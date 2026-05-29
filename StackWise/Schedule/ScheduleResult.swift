import Foundation

struct ScheduledItem: Identifiable, Equatable {
    let id: UUID
    let label: String           // user-visible label
    let activeIngredient: String // slug; "" for isInDatabase=false items
    let dosage: String
    let isPrescription: Bool
    let position: Int16         // within-block ordering
    let suggestedTime: Date     // concrete time for ScheduledDose.suggestedTime
    let hasTimingConflict: Bool // true if a timing-conflict pair partner is in an adjacent block that violates window
    let hasSynergy: Bool        // true if a synergy pair partner is in any block
    let customTime: Date?       // user-set specific clock time; nil means engine-assigned block time
    let scheduleNotes: String?  // user-written notes; nil means none

    func withOverride(customTime: Date?, scheduleNotes: String?, suggestedTime: Date? = nil) -> ScheduledItem {
        ScheduledItem(
            id: id, label: label, activeIngredient: activeIngredient,
            dosage: dosage, isPrescription: isPrescription,
            position: position, suggestedTime: suggestedTime ?? self.suggestedTime,
            hasTimingConflict: hasTimingConflict, hasSynergy: hasSynergy,
            customTime: customTime, scheduleNotes: scheduleNotes
        )
    }
}

struct ScheduleResult: Equatable {
    let morning: [ScheduledItem]
    let afternoon: [ScheduledItem]
    let evening: [ScheduledItem]

    static let empty = ScheduleResult(morning: [], afternoon: [], evening: [])

    func allItems() -> [ScheduledItem] {
        morning + afternoon + evening
    }
}
