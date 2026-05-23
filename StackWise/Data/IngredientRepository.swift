import Foundation
import SQLite3

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

struct IngredientMatch: Equatable, Identifiable {
    let id: Int64
    let canonicalName: String
    let itemType: String
    let matchedAlias: String?
}

@Observable
final class IngredientRepository: @unchecked Sendable {
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

    func search(_ query: String, limit: Int = 10) -> [IngredientMatch] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let db else { return [] }

        let sql = """
        SELECT id, canonical_name, item_type, aliases
        FROM ingredients
        WHERE canonical_name LIKE ?1 ESCAPE '\\' COLLATE NOCASE
           OR aliases LIKE ?1 ESCAPE '\\' COLLATE NOCASE
        ORDER BY
            CASE WHEN canonical_name LIKE ?2 ESCAPE '\\' COLLATE NOCASE THEN 0 ELSE 1 END,
            length(canonical_name),
            canonical_name
        LIMIT ?3
        """

        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }

        let escaped = escapeLikePattern(trimmed)
        let likePattern = "%\(escaped)%"
        let prefixPattern = "\(escaped)%"
        sqlite3_bind_text(stmt, 1, likePattern, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, prefixPattern, -1, SQLITE_TRANSIENT)
        sqlite3_bind_int(stmt, 3, Int32(limit))

        var results: [IngredientMatch] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = sqlite3_column_int64(stmt, 0)
            let canonicalName = String(cString: sqlite3_column_text(stmt, 1))
            let itemType = String(cString: sqlite3_column_text(stmt, 2))
            let aliasesJSON = sqlite3_column_text(stmt, 3).map { String(cString: $0) } ?? "[]"
            let matchedAlias = firstAliasMatching(query: trimmed, aliasesJSON: aliasesJSON,
                                                  canonicalName: canonicalName)
            results.append(IngredientMatch(id: id, canonicalName: canonicalName,
                                           itemType: itemType, matchedAlias: matchedAlias))
        }
        return results
    }

    /// Returns timing constraints for a single ingredient slug.
    /// Returns `TimingProperties.none` if the slug is not in the DB or has no timing blob.
    func timingProperties(for slug: String) -> TimingProperties {
        guard let db else { return .none }
        let sql = "SELECT timing_properties FROM ingredients WHERE canonical_name = ? LIMIT 1"
        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return .none }
        sqlite3_bind_text(stmt, 1, slug, -1, SQLITE_TRANSIENT)
        guard sqlite3_step(stmt) == SQLITE_ROW else { return .none }
        let blob: String? = (sqlite3_column_type(stmt, 0) != SQLITE_NULL)
            ? String(cString: sqlite3_column_text(stmt, 0)) : nil
        return TimingProperties.decode(from: blob)
    }

    private func escapeLikePattern(_ input: String) -> String {
        input
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "%", with: "\\%")
            .replacingOccurrences(of: "_", with: "\\_")
    }

    private func firstAliasMatching(query: String, aliasesJSON: String,
                                    canonicalName: String) -> String? {
        if canonicalName.range(of: query, options: .caseInsensitive) != nil { return nil }
        guard let data = aliasesJSON.data(using: .utf8),
              let aliases = try? JSONDecoder().decode([String].self, from: data) else { return nil }
        return aliases.first { $0.range(of: query, options: .caseInsensitive) != nil }
    }
}
