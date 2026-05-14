import XCTest
import SQLite3
@testable import StackWise

final class IngredientRepositoryTests: XCTestCase {

    var repo: IngredientRepository!

    override func setUpWithError() throws {
        repo = IngredientRepository(bundle: .main)
    }

    override func tearDownWithError() throws {
        repo = nil
    }

    func testSearchByCanonicalName() throws {
        let results = repo.search("Vitamin")
        XCTAssertFalse(results.isEmpty,
                       "Search for 'Vitamin' should return ≥1 ingredient from the bundled DB")
        XCTAssertTrue(results.contains { $0.canonicalName.localizedCaseInsensitiveContains("vitamin") },
                      "At least one result should have 'vitamin' in its canonical name")
    }

    func testSearchIsCaseInsensitive() throws {
        let lower = repo.search("vitamin")
        let upper = repo.search("VITAMIN")
        XCTAssertEqual(lower.map(\.id).sorted(), upper.map(\.id).sorted(),
                       "LIKE NOCASE should make search case-insensitive")
    }

    func testSearchByAliasDynamicallyDiscovered() throws {
        // Read the bundled DB directly to find any ingredient that actually has an alias.
        // This makes the test robust to data updates — we don't hard-code an alias string.
        guard let url = Bundle(for: type(of: self)).url(forResource: "stackwise", withExtension: "sqlite")
            ?? Bundle.main.url(forResource: "stackwise", withExtension: "sqlite") else {
            XCTFail("stackwise.sqlite not in test bundle or main bundle")
            return
        }
        var db: OpaquePointer?
        defer { sqlite3_close(db) }
        XCTAssertEqual(sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil), SQLITE_OK)

        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        let sql = "SELECT canonical_name, aliases FROM ingredients WHERE aliases != '[]' AND aliases IS NOT NULL"
        XCTAssertEqual(sqlite3_prepare_v2(db, sql, -1, &stmt, nil), SQLITE_OK)

        var foundAlias: (canonical: String, alias: String)?
        while sqlite3_step(stmt) == SQLITE_ROW {
            let canonical = String(cString: sqlite3_column_text(stmt, 0))
            let aliasesJSON = String(cString: sqlite3_column_text(stmt, 1))
            if let data = aliasesJSON.data(using: .utf8),
               let aliases = try? JSONDecoder().decode([String].self, from: data),
               let firstAlias = aliases.first(where: { !$0.isEmpty
                   && !canonical.localizedCaseInsensitiveContains($0)
                   && !$0.localizedCaseInsensitiveContains(canonical) }) {
                foundAlias = (canonical, firstAlias)
                break
            }
        }
        guard let probe = foundAlias else {
            throw XCTSkip("DB has no ingredient with an alias disjoint from its canonical name")
        }

        let results = repo.search(probe.alias)
        XCTAssertTrue(results.contains { $0.canonicalName == probe.canonical },
                      "Searching for alias '\(probe.alias)' should return canonical '\(probe.canonical)'")
        XCTAssertTrue(results.contains { $0.matchedAlias?.localizedCaseInsensitiveContains(probe.alias) == true },
                      "Result should expose the matched alias when the match was on the alias column")
    }

    func testSearchEmptyQueryReturnsEmpty() throws {
        XCTAssertEqual(repo.search(""), [])
        XCTAssertEqual(repo.search("   "), [], "Whitespace-only queries should not wildcard-scan the table")
    }

    func testSearchRespectsLimit() throws {
        let results = repo.search("a", limit: 3)
        XCTAssertLessThanOrEqual(results.count, 3, "Result count must not exceed the requested limit")
    }
}
