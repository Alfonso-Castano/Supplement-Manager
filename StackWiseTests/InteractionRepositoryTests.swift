import XCTest
import SQLite3
@testable import StackWise

final class InteractionRepositoryTests: XCTestCase {

    var repo: InteractionRepository!

    override func setUpWithError() throws {
        repo = InteractionRepository(bundle: .main)
    }

    override func tearDownWithError() throws {
        repo = nil
    }

    // MARK: - Helpers

    /// Open the bundled `stackwise.sqlite` directly so tests can dynamically discover
    /// real-data fixtures (same technique as `testSearchByAliasDynamicallyDiscovered`).
    private func openBundledDB() throws -> OpaquePointer {
        guard let url = Bundle(for: type(of: self)).url(forResource: "stackwise", withExtension: "sqlite")
            ?? Bundle.main.url(forResource: "stackwise", withExtension: "sqlite") else {
            throw XCTSkip("stackwise.sqlite not in test bundle or main bundle")
        }
        var db: OpaquePointer?
        XCTAssertEqual(sqlite3_open_v2(url.path, &db, SQLITE_OPEN_READONLY, nil), SQLITE_OK)
        guard let db else { throw XCTSkip("sqlite3_open_v2 returned nil handle") }
        return db
    }

    // MARK: - Tests

    func testPairwiseReturnsEmptyForLessThanTwoSlugs() throws {
        XCTAssertEqual(repo.pairwise(for: []), [])
        XCTAssertEqual(repo.pairwise(for: ["vitamin_d3"]), [])
    }

    func testPairwiseReturnsRealPairFromBundledDB() throws {
        // Discover any real (compound_a, compound_b) pair from the bundled DB.
        let db = try openBundledDB()
        defer { sqlite3_close_v2(db) }

        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        let sql = "SELECT id, compound_a, compound_b FROM interactions LIMIT 1"
        XCTAssertEqual(sqlite3_prepare_v2(db, sql, -1, &stmt, nil), SQLITE_OK)

        guard sqlite3_step(stmt) == SQLITE_ROW else {
            throw XCTSkip("interactions table is empty in bundled DB")
        }
        let expectedId = sqlite3_column_int64(stmt, 0)
        let a = String(cString: sqlite3_column_text(stmt, 1))
        let b = String(cString: sqlite3_column_text(stmt, 2))

        let results = repo.pairwise(for: [a, b])
        XCTAssertTrue(results.contains { $0.id == expectedId },
                      "pairwise(for:) should return the discovered pair (id=\(expectedId), a=\(a), b=\(b))")
    }

    func testPairwiseDoesNotReturnSingleSidedMatches() throws {
        // Find a real interaction row, then query with ONLY compound_a (omit compound_b).
        // The IN/IN filter must reject that row.
        let db = try openBundledDB()
        defer { sqlite3_close_v2(db) }

        var stmt: OpaquePointer?
        defer { sqlite3_finalize(stmt) }
        let sql = "SELECT id, compound_a, compound_b FROM interactions LIMIT 1"
        XCTAssertEqual(sqlite3_prepare_v2(db, sql, -1, &stmt, nil), SQLITE_OK)

        guard sqlite3_step(stmt) == SQLITE_ROW else {
            throw XCTSkip("interactions table is empty in bundled DB")
        }
        let rowId = sqlite3_column_int64(stmt, 0)
        let a = String(cString: sqlite3_column_text(stmt, 1))
        let b = String(cString: sqlite3_column_text(stmt, 2))

        // Use a second arbitrary slug that is unlikely to be compound_b.
        // We need ≥2 slugs to avoid the short-circuit, so add a sentinel that
        // definitely is not equal to `b`.
        let sentinel = "___not_a_real_slug___"
        XCTAssertNotEqual(sentinel, b)
        let results = repo.pairwise(for: [a, sentinel])
        XCTAssertFalse(results.contains { $0.id == rowId },
                       "Single-sided match (compound_a present, compound_b missing) must not return row id=\(rowId)")
    }

    func testKnownWarfarinVitaminKCriticalPair() throws {
        let results = repo.pairwise(for: ["vitamin_k2", "warfarin"])
        guard !results.isEmpty else {
            throw XCTSkip("Bundled DB no longer contains a warfarin / vitamin_k2 pair — DB may have been regenerated")
        }
        XCTAssertTrue(
            results.contains { $0.severity == .critical && $0.interactionType == .unsafeCombination },
            "Expected at least one (warfarin, vitamin_k2) row with severity=critical AND interactionType=unsafe_combination"
        )
    }

    func testKnownVitaminCIronSynergyPair() throws {
        let results = repo.pairwise(for: ["vitamin_c", "iron"])
        guard !results.isEmpty else {
            throw XCTSkip("Bundled DB no longer contains a vitamin_c / iron pair — DB may have been regenerated")
        }
        XCTAssertTrue(
            results.contains { $0.interactionType == .synergy },
            "Expected at least one (vitamin_c, iron) row with interactionType=synergy"
        )
    }
}
