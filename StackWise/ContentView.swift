import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        @Bindable var appState = appState   // @Bindable must be inside body{} — not a stored property

        TabView(selection: $appState.selectedTab) {
            NavigationStack {
                StackListView()
            }
            .tabItem {
                Label("Stack", systemImage: "pills.fill")
            }
            .tag(0)

            NavigationStack {
                TodayView()
            }
            .tabItem {
                Label("Today", systemImage: "calendar")
            }
            .tag(1)

            NavigationStack {
                ScheduleView()
            }
            .tabItem {
                Label("Schedule", systemImage: "clock.fill")
            }
            .tag(2)
        }
    }
}
