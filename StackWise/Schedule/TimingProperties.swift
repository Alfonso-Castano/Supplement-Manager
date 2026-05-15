import Foundation

struct TimingProperties: Equatable {
    let requiredFood: Bool
    let requiresEmptyStomach: Bool
    let preferredTimeOfDay: String?   // "morning" | "afternoon" | "evening" | nil
    let avoidWithCaffeine: Bool

    static let none = TimingProperties(
        requiredFood: false,
        requiresEmptyStomach: false,
        preferredTimeOfDay: nil,
        avoidWithCaffeine: false
    )

    /// Decode from the `timing_properties` JSON blob stored in the `ingredients` table.
    /// Returns `.none` if the blob is absent or unparseable.
    static func decode(from jsonString: String?) -> TimingProperties {
        guard let json = jsonString,
              let data = json.data(using: .utf8),
              let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return .none }

        return TimingProperties(
            requiredFood: dict["required_food"] as? Bool ?? false,
            requiresEmptyStomach: dict["requires_empty_stomach"] as? Bool ?? false,
            preferredTimeOfDay: dict["preferred_time_of_day"] as? String,
            avoidWithCaffeine: dict["avoid_with_caffeine"] as? Bool ?? false
        )
    }
}
