import Observation

@Observable
final class AppState {
    var selectedTab: Int = 0
    // TODO Phase 2: add stackNavigationPath = NavigationPath() when Stack tab needs persistent navigation
}
