import Foundation

enum ScheduleEngine {

    struct Input {
        let items: [ItemProjection]
        let pairs: [PairProjection]
        let timingProps: [String: TimingProperties]  // keyed by activeIngredient slug
        let wakeTime: Date
        let breakfastTime: Date
        let lunchTime: Date
        let dinnerTime: Date
        let sleepTime: Date
    }

    struct ItemProjection: Identifiable {
        let id: UUID
        let label: String
        let activeIngredient: String
        let dosage: String
        let isPrescription: Bool
        let isInDatabase: Bool
        let sortOrder: Int16
    }

    struct PairProjection {
        let slugA: String
        let slugB: String
        let timingRelevant: Bool
        let timingWindowHours: Int?
        let isSynergy: Bool
    }

    enum Block: Int, CaseIterable {
        case morning = 0
        case afternoon = 1
        case evening = 2
    }

    static func schedule(_ input: Input) -> ScheduleResult {
        // Suggested time for each block (used for conflict separation math).
        let blockTimes: [Block: Date] = [
            .morning: input.breakfastTime,
            .afternoon: input.lunchTime,
            .evening: input.dinnerTime
        ]

        // Initial block assignment dictionary: item.id -> Block.
        var assignment: [UUID: Block] = [:]

        // --- Rule 3: timing_properties constraints (applied before Rule 1 so prescription
        //     placement in Rule 1 can respect food/timing preferences). ---
        for item in input.items {
            guard item.isInDatabase, !item.activeIngredient.isEmpty else { continue }
            let props = input.timingProps[item.activeIngredient] ?? .none
            if let preferred = props.preferredTimeOfDay {
                switch preferred {
                case "morning":   assignment[item.id] = .morning
                case "afternoon": assignment[item.id] = .afternoon
                case "evening":   assignment[item.id] = .evening
                default: break
                }
            }
            if props.requiredFood {
                // Prefer preferred time if already a meal block, else default to morning.
                if assignment[item.id] == nil { assignment[item.id] = .morning }
            }
            if props.requiresEmptyStomach {
                // Always morning (at wake, before breakfast) -- override other constraints.
                assignment[item.id] = .morning
            }
            if props.avoidWithCaffeine && !props.requiresEmptyStomach {
                // Move away from morning (typical caffeine window) unless empty-stomach overrides.
                if assignment[item.id] == nil || assignment[item.id] == .morning {
                    assignment[item.id] = .afternoon
                }
            }
        }

        // --- Rule 1: prescriptions lock in -- override timing_properties if needed,
        //     but keep their timing_properties block if it already satisfies a meal constraint. ---
        for item in input.items where item.isPrescription {
            if assignment[item.id] == nil {
                assignment[item.id] = .morning // default if no timing constraint
            }
            // Prescriptions keep their assignment (already set above or now morning).
        }

        // Assign remaining items (supplements not yet assigned) to morning by default.
        for item in input.items where assignment[item.id] == nil {
            assignment[item.id] = .morning
        }

        // --- Rule 2: timing-conflict separation. ---
        for pair in input.pairs where pair.timingRelevant {
            guard let windowHours = pair.timingWindowHours,
                  let itemA = input.items.first(where: { $0.activeIngredient == pair.slugA }),
                  let itemB = input.items.first(where: { $0.activeIngredient == pair.slugB })
            else { continue }

            let blockA = assignment[itemA.id] ?? .morning
            let blockB = assignment[itemB.id] ?? .morning

            guard let timeA = blockTimes[blockA], let timeB = blockTimes[blockB] else { continue }
            let separation = abs(timeA.timeIntervalSince(timeB)) / 3600

            if separation < Double(windowHours) {
                // Move the lower-priority item (supplement over prescription; higher sortOrder loses).
                let aLosesPriority = !itemA.isPrescription && (itemB.isPrescription || itemA.sortOrder >= itemB.sortOrder)
                let itemToMove = aLosesPriority ? itemA : itemB
                let anchorBlock = aLosesPriority ? blockB : blockA
                let anchorTime = blockTimes[anchorBlock]!

                // Find earliest block with sufficient separation from anchor.
                let candidate = Block.allCases.first { block in
                    guard block != anchorBlock,
                          let t = blockTimes[block] else { return false }
                    return abs(t.timeIntervalSince(anchorTime)) / 3600 >= Double(windowHours)
                }
                if let candidate {
                    // Re-validate timing constraints before committing the move.
                    let slug = itemToMove.activeIngredient
                    let props = input.timingProps[slug] ?? .none
                    let constraintsSatisfied: Bool = {
                        if props.requiresEmptyStomach { return candidate == .morning }
                        if props.requiredFood { return true } // all blocks have meals
                        return true
                    }()
                    if constraintsSatisfied {
                        assignment[itemToMove.id] = candidate
                    }
                }
            }
        }

        // --- Rule 4: overflow if any block exceeds 5 items. ---
        var morning = input.items.filter { assignment[$0.id] == .morning }
        var afternoon = input.items.filter { assignment[$0.id] == .afternoon }
        var evening = input.items.filter { assignment[$0.id] == .evening }

        func sort(_ items: [ItemProjection]) -> [ItemProjection] {
            items.sorted {
                if $0.isPrescription != $1.isPrescription { return $0.isPrescription }
                return $0.sortOrder < $1.sortOrder
            }
        }

        morning = sort(morning)
        afternoon = sort(afternoon)
        evening = sort(evening)

        // Overflow: spill from morning -> afternoon -> evening.
        // Note: evening has no cap -- it is the terminal block so overflow
        // accumulates there. With typical stacks (< 15 items) this is fine.
        while morning.count > 5 {
            let spill = morning.removeLast()
            afternoon.insert(spill, at: 0)
        }
        while afternoon.count > 5 {
            let spill = afternoon.removeLast()
            evening.insert(spill, at: 0)
        }

        if evening.count > 5 {
            assertionFailure("Evening block has \(evening.count) items — consider splitting into sub-blocks")
        }

        // Build ScheduledItems.
        func makeItems(
            _ projections: [ItemProjection],
            block: Block,
            pairs: [PairProjection],
            allAssignments: [UUID: Block]
        ) -> [ScheduledItem] {
            projections.enumerated().map { idx, proj in
                let blockTime = blockTimes[block]!
                let hasSynergyFlag = pairs.contains {
                    $0.isSynergy && ($0.slugA == proj.activeIngredient || $0.slugB == proj.activeIngredient)
                }
                return ScheduledItem(
                    id: proj.id,
                    label: proj.label,
                    activeIngredient: proj.activeIngredient,
                    dosage: proj.dosage,
                    isPrescription: proj.isPrescription,
                    position: Int16(idx),
                    suggestedTime: blockTime,
                    hasTimingConflict: false, // simplified: conflict detection in AnalysisStore
                    hasSynergy: hasSynergyFlag
                )
            }
        }

        return ScheduleResult(
            morning: makeItems(morning, block: .morning, pairs: input.pairs, allAssignments: assignment),
            afternoon: makeItems(afternoon, block: .afternoon, pairs: input.pairs, allAssignments: assignment),
            evening: makeItems(evening, block: .evening, pairs: input.pairs, allAssignments: assignment)
        )
    }
}
