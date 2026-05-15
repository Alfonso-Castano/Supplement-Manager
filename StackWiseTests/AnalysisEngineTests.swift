import XCTest
@testable import StackWise

final class AnalysisEngineTests: XCTestCase {

    // MARK: - Helper

    private func makePair(
        id: Int64 = 1,
        a: String = "compound_a",
        b: String = "compound_b",
        type: InteractionType,
        severity: InteractionSeverity = .advisory
    ) -> InteractionPair {
        InteractionPair(
            id: id, compoundA: a, compoundB: b,
            compoundAType: "supplement", compoundBType: "supplement",
            interactionType: type, severity: severity,
            direction: .bidirectional, mechanism: nil,
            effect: "test effect", suggestedAction: "test action",
            timingRelevant: false, timingWindowHours: nil,
            citations: "", confidence: "high", conflictNote: nil
        )
    }

    // MARK: - Tests

    func testEmptyStackReturnsEmptyResults() {
        var fetcherCalled = false
        let results = AnalysisEngine.analyze(activeItems: []) { _ in
            fetcherCalled = true
            return []
        }
        XCTAssertFalse(fetcherCalled)
        XCTAssertEqual(results, .empty)
    }

    func testSingleItemInDBReturnsEmptyResults() {
        var fetcherCalled = false
        let item = StackItemView(label: "Vitamin D", slug: "vitamin_d3", isInDatabase: true)
        let results = AnalysisEngine.analyze(activeItems: [item]) { _ in
            fetcherCalled = true
            return []
        }
        XCTAssertFalse(fetcherCalled)
        XCTAssertEqual(results, .empty)
    }

    func testSynergyPairRoutesToSynergyGroup() {
        let pair = makePair(type: .synergy, severity: .advisory)
        let items = [
            StackItemView(label: "Iron", slug: "iron", isInDatabase: true),
            StackItemView(label: "Vitamin C", slug: "vitamin_c", isInDatabase: true)
        ]
        let results = AnalysisEngine.analyze(activeItems: items) { _ in [pair] }
        XCTAssertEqual(results.synergy.count, 1)
        XCTAssertTrue(results.advisory.isEmpty)
        XCTAssertTrue(results.critical.isEmpty)
    }

    func testCriticalNonSynergyRoutesToCritical() {
        let pair = makePair(type: .unsafeCombination, severity: .critical)
        let items = [
            StackItemView(label: "Warfarin", slug: "warfarin", isInDatabase: true),
            StackItemView(label: "Vitamin K2", slug: "vitamin_k2", isInDatabase: true)
        ]
        let results = AnalysisEngine.analyze(activeItems: items) { _ in [pair] }
        XCTAssertEqual(results.critical.count, 1)
        XCTAssertTrue(results.advisory.isEmpty)
        XCTAssertTrue(results.synergy.isEmpty)
    }

    func testAdvisoryNonSynergyRoutesToAdvisory() {
        let pair = makePair(type: .absorptionCompetition, severity: .advisory)
        let items = [
            StackItemView(label: "Iron", slug: "iron", isInDatabase: true),
            StackItemView(label: "Calcium", slug: "calcium", isInDatabase: true)
        ]
        let results = AnalysisEngine.analyze(activeItems: items) { _ in [pair] }
        XCTAssertEqual(results.advisory.count, 1)
        XCTAssertTrue(results.critical.isEmpty)
        XCTAssertTrue(results.synergy.isEmpty)
    }

    func testNotInDatabaseItemsPreserveOrder() {
        let items = [
            StackItemView(label: "Banana Extract", slug: "", isInDatabase: false),
            StackItemView(label: "Vitamin D", slug: "vitamin_d3", isInDatabase: true),
            StackItemView(label: "Mystery Herb", slug: "", isInDatabase: false)
        ]
        let results = AnalysisEngine.analyze(activeItems: items) { _ in [] }
        XCTAssertEqual(results.notInDatabase, ["Banana Extract", "Mystery Herb"])
    }
}
