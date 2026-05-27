import Observation

@Observable
final class AppState {
    var onboardingComplete: Bool = false
    var subscriptionStatus: String = "unknown"
    var selectedTab: Int = 0
}
