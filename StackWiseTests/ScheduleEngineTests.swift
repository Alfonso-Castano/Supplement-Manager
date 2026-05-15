import XCTest
@testable import StackWise

final class ScheduleEngineTests: XCTestCase {

    // MARK: - Helpers

    private let cal = Calendar.current
    private lazy var baseDate: Date = {
        cal.date(from: DateComponents(year: 2026, month: 1, day: 1))!
    }()

    private func time(hour: Int, minute: Int = 0) -> Date {
        cal.date(bySettingHour: hour, minute: minute, second: 0, of: baseDate)!
    }

    private func makeItem(
        id: UUID = UUID(),
        label: String = "Item",
        slug: String = "",
        dosage: String = "100mg",
        isPrescription: Bool = false,
        isInDatabase: Bool = true,
        sortOrder: Int16 = 0
    ) -> ScheduleEngine.ItemProjection {
        ScheduleEngine.ItemProjection(
            id: id,
            label: label,
            activeIngredient: slug,
            dosage: dosage,
            isPrescription: isPrescription,
            isInDatabase: isInDatabase,
            sortOrder: sortOrder
        )
    }

    private func defaultInput(
        items: [ScheduleEngine.ItemProjection] = [],
        pairs: [ScheduleEngine.PairProjection] = [],
        timingProps: [String: TimingProperties] = [:],
        breakfastHour: Int = 7,
        lunchHour: Int = 12,
        dinnerHour: Int = 18
    ) -> ScheduleEngine.Input {
        ScheduleEngine.Input(
            items: items,
            pairs: pairs,
            timingProps: timingProps,
            wakeTime: time(hour: 6, minute: 30),
            breakfastTime: time(hour: breakfastHour),
            lunchTime: time(hour: lunchHour),
            dinnerTime: time(hour: dinnerHour),
            sleepTime: time(hour: 22)
        )
    }

    // MARK: - Tests

    func testEmptyStackReturnsEmptyResult() {
        let result = ScheduleEngine.schedule(defaultInput())
        XCTAssertEqual(result, ScheduleResult.empty)
    }

    func testRxPrescriptionPlacedBeforeSupplement() {
        let rxID = UUID()
        let suppID = UUID()
        let items = [
            makeItem(id: suppID, label: "Vitamin C", slug: "vitamin_c", sortOrder: 0),
            makeItem(id: rxID, label: "Warfarin", slug: "warfarin", isPrescription: true, sortOrder: 1)
        ]
        let result = ScheduleEngine.schedule(defaultInput(items: items))

        // Prescription should be at position 0 in morning.
        XCTAssertEqual(result.morning.count, 2)
        XCTAssertEqual(result.morning[0].id, rxID)
        XCTAssertTrue(result.morning[0].isPrescription)
        XCTAssertEqual(result.morning[0].position, 0)
        XCTAssertEqual(result.morning[1].id, suppID)
    }

    func testRule2TimingConflictSeparationPushesItem() {
        let ironID = UUID()
        let calciumID = UUID()
        let items = [
            makeItem(id: ironID, label: "Iron", slug: "iron", sortOrder: 0),
            makeItem(id: calciumID, label: "Calcium", slug: "calcium", sortOrder: 1)
        ]
        let pair = ScheduleEngine.PairProjection(
            slugA: "iron",
            slugB: "calcium",
            timingRelevant: true,
            timingWindowHours: 4,
            isSynergy: false
        )

        // Case 1: breakfast=8am, lunch=10am -> separation 2h < 4h required.
        // Calcium (higher sortOrder = lower priority) should move to a block with >= 4h separation.
        let result = ScheduleEngine.schedule(defaultInput(
            items: items,
            pairs: [pair],
            breakfastHour: 8,
            lunchHour: 10,
            dinnerHour: 18
        ))

        // Iron stays in morning, calcium should move to evening (18-8 = 10h >= 4h).
        // (afternoon at 10am is only 2h from morning at 8am, so it does not qualify)
        XCTAssertTrue(result.morning.contains(where: { $0.id == ironID }))
        XCTAssertFalse(result.morning.contains(where: { $0.id == calciumID }))
        // Calcium should be in evening (dinner=18, 18-8=10h >= 4h)
        XCTAssertTrue(result.evening.contains(where: { $0.id == calciumID }))
    }

    func testRule3RequiredFoodDefaultsMorning() {
        let id = UUID()
        let items = [makeItem(id: id, label: "CoQ10", slug: "coq10")]
        let props: [String: TimingProperties] = [
            "coq10": TimingProperties(
                requiredFood: true,
                requiresEmptyStomach: false,
                preferredTimeOfDay: nil,
                avoidWithCaffeine: false
            )
        ]
        let result = ScheduleEngine.schedule(defaultInput(items: items, timingProps: props))
        XCTAssertEqual(result.morning.count, 1)
        XCTAssertEqual(result.morning[0].id, id)
    }

    func testRule3PreferredTimeOfDayRespected() {
        let id = UUID()
        let items = [makeItem(id: id, label: "Magnesium", slug: "magnesium")]
        let props: [String: TimingProperties] = [
            "magnesium": TimingProperties(
                requiredFood: false,
                requiresEmptyStomach: false,
                preferredTimeOfDay: "evening",
                avoidWithCaffeine: false
            )
        ]
        let result = ScheduleEngine.schedule(defaultInput(items: items, timingProps: props))
        XCTAssertEqual(result.evening.count, 1)
        XCTAssertEqual(result.evening[0].id, id)
    }

    func testRule3RequiresEmptyStomachOverridesPreferred() {
        let id = UUID()
        let items = [makeItem(id: id, label: "L-Theanine", slug: "l_theanine")]
        let props: [String: TimingProperties] = [
            "l_theanine": TimingProperties(
                requiredFood: false,
                requiresEmptyStomach: true,
                preferredTimeOfDay: "afternoon",
                avoidWithCaffeine: false
            )
        ]
        let result = ScheduleEngine.schedule(defaultInput(items: items, timingProps: props))
        // requiresEmptyStomach overrides preferredTimeOfDay to morning.
        XCTAssertEqual(result.morning.count, 1)
        XCTAssertEqual(result.morning[0].id, id)
        XCTAssertTrue(result.afternoon.isEmpty)
    }

    func testRule4OverflowAt5Items() {
        // 6 unconstrained items -> 5 in morning, 1 spills to afternoon.
        let items = (0..<6).map { i in
            makeItem(
                label: "Supplement \(i)",
                slug: "supp_\(i)",
                sortOrder: Int16(i)
            )
        }
        let result = ScheduleEngine.schedule(defaultInput(items: items))
        XCTAssertEqual(result.morning.count, 5)
        XCTAssertEqual(result.afternoon.count, 1)
        XCTAssertTrue(result.evening.isEmpty)
    }
}
