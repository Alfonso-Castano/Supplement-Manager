import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

enum InteractionSeverity: String { case advisory, critical }

enum InteractionType: String {
    case absorptionCompetition = "absorption_competition"
    case timingConflict        = "timing_conflict"
    case unsafeCombination     = "unsafe_combination"
    case synergy
}

enum InteractionDirection: String { case bidirectional, directional }

struct InteractionPair: Equatable, Identifiable {
    let id: Int64
    let compoundA: String          // snake_case slug
    let compoundB: String          // snake_case slug
    let compoundAType: String      // "supplement" | "drug"
    let compoundBType: String      // "supplement" | "drug"
    let interactionType: InteractionType
    let severity: InteractionSeverity
    let direction: InteractionDirection?
    let mechanism: String?
    let effect: String             // NOT NULL in DB
    let suggestedAction: String    // NOT NULL in DB
    let timingRelevant: Bool
    let timingWindowHours: Int?
    let citations: String          // raw text from DB
    let confidence: String         // "high" | "medium" | "low"
    let conflictNote: String?
}

@Observable
final class InteractionRepository {
    private var db: OpaquePointer?

    init(bundle: Bundle = .main, resource: String = "stackwise", ext: String = "sqlite") {
        guard let url = bundle.url(forResource: resource, withExtension: ext) else {
            assertionFailure("Bundled \(resource).\(ext) not found")
            return
        }
        var handle: OpaquePointer?
        let flags = SQLITE_OPEN_READONLY | SQLITE_OPEN_FULLMUTEX
        guard sqlite3_open_v2(url.path, &handle, flags, nil) == SQLITE_OK else {
            assertionFailure("sqlite3_open_v2 failed: \(String(cString: sqlite3_errmsg(handle)))")
            sqlite3_close(handle)
            return
        }
        self.db = handle
    }

    deinit {
        if let db { sqlite3_close_v2(db) }
    }

    /// Returns every interaction row where BOTH `compound_a` and `compound_b` appear in `slugs`.
    /// Slug matching is exact and case-sensitive (DB slugs are normalized snake_case).
    /// Returns an empty array when `slugs.count < 2` or `db` is nil.
    func pairwise(for slugs: Set<String>) -> [InteractionPair] {
        guard slugs.count >= 2, let db else { return [] }

        let slugArray = Array(slugs)
        let placeholders = Array(repeating: "?", count: slugArray.count).joined(separator: ", ")

        let sql = """
        SELECT id, compound_a, compound_b, compound_a_type, compound_b_type,
               interaction_type, severity, mechanism, direction, effect,
               suggested_action, timing_relevant, timing_window_hours,
               citations, confidence, conflict_note
          FROM interactions
         WHERE compound_a IN (\(placeholders))
           AND compound_b IN (\(placeholders))
        """

        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }

        // Bind slugs twice — once per IN clause.
        let total = slugArray.count
        for (offset, slug) in slugArray.enumerated() {
            // first IN: positions 1...total
            sqlite3_bind_text(stmt, Int32(offset + 1), slug, -1, SQLITE_TRANSIENT)
            // second IN: positions (total+1)...(2*total)
            sqlite3_bind_text(stmt, Int32(total + offset + 1), slug, -1, SQLITE_TRANSIENT)
        }

        var results: [InteractionPair] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let compoundA = String(cString: sqlite3_column_text(stmt, 1))
            let compoundB = String(cString: sqlite3_column_text(stmt, 2))
            let compoundAType = String(cString: sqlite3_column_text(stmt, 3))
            let compoundBType = String(cString: sqlite3_column_text(stmt, 4))
            let interactionTypeRaw = String(cString: sqlite3_column_text(stmt, 5))
            let severityRaw = String(cString: sqlite3_column_text(stmt, 6))

            let mechanism: String? = (sqlite3_column_type(stmt, 7) != SQLITE_NULL)
                ? String(cString: sqlite3_column_text(stmt, 7)) : nil

            let direction: InteractionDirection?
            if sqlite3_column_type(stmt, 8) != SQLITE_NULL {
                let raw = String(cString: sqlite3_column_text(stmt, 8))
                direction = InteractionDirection(rawValue: raw)
            } else {
                direction = nil
            }

            let effect = String(cString: sqlite3_column_text(stmt, 9))
            let suggestedAction = String(cString: sqlite3_column_text(stmt, 10))
            let timingRelevant = sqlite3_column_int(stmt, 11) != 0

            let timingWindowHours: Int?
            if sqlite3_column_type(stmt, 12) != SQLITE_NULL {
                timingWindowHours = Int(sqlite3_column_int(stmt, 12))
            } else {
                timingWindowHours = nil
            }

            let citations = (sqlite3_column_type(stmt, 13) != SQLITE_NULL)
                ? String(cString: sqlite3_column_text(stmt, 13)) : ""
            let confidence = (sqlite3_column_type(stmt, 14) != SQLITE_NULL)
                ? String(cString: sqlite3_column_text(stmt, 14)) : ""

            let conflictNote: String? = (sqlite3_column_type(stmt, 15) != SQLITE_NULL)
                ? String(cString: sqlite3_column_text(stmt, 15)) : nil

            // Defensive: skip rows whose enum values fail to parse (impossible per DB CHECK).
            guard let interactionType = InteractionType(rawValue: interactionTypeRaw),
                  let severity = InteractionSeverity(rawValue: severityRaw) else {
                continue
            }

            results.append(InteractionPair(
                id: id,
                compoundA: compoundA,
                compoundB: compoundB,
                compoundAType: compoundAType,
                compoundBType: compoundBType,
                interactionType: interactionType,
                severity: severity,
                direction: direction,
                mechanism: mechanism,
                effect: effect,
                suggestedAction: suggestedAction,
                timingRelevant: timingRelevant,
                timingWindowHours: timingWindowHours,
                citations: citations,
                confidence: confidence,
                conflictNote: conflictNote
            ))
        }
        return results
    }
}
