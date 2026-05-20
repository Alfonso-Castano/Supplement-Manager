import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.managedObjectContext) private var context

    var body: some View {
        @Bindable var appState = appState

        TabView {
            StackListView()
                .tabItem {
                    Label("Stack", systemImage: "pills")
                }

            TodayView()
                .tabItem {
                    Label("Today", systemImage: "checkmark.circle")
                }

            ScheduleView()
                .tabItem {
                    Label("Schedule", systemImage: "calendar")
                }
        }
        .tint(.aquaPrimary)
        .task {
            let profile = UserProfileStore.fetchOrCreate(in: context)
            appState.onboardingComplete = profile.onboardingComplete
        }
        .sheet(isPresented: Binding(
            get: { !appState.onboardingComplete },
            set: { _ in /* dismissal is driven by the save action, not the user */ }
        )) {
            HealthProfileView()
        }
    }
}
