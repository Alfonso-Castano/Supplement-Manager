import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.managedObjectContext) private var context
    @AppStorage("notificationPermissionShown") private var notificationPermissionShown = false

    var body: some View {
        @Bindable var appState = appState

        Group {
            if appState.onboardingComplete {
                if !notificationPermissionShown {
                    NotificationPermissionView(onComplete: {
                        notificationPermissionShown = true
                    })
                } else {
                    TabView(selection: $appState.selectedTab) {
                        StackListView()
                            .tabItem { Label("Stack", systemImage: "pills") }
                            .tag(0)

                        TodayView()
                            .tabItem { Label("Today", systemImage: "checkmark.circle") }
                            .tag(1)

                        ScheduleView()
                            .tabItem { Label("Schedule", systemImage: "calendar") }
                            .tag(2)
                    }
                    .tint(.aquaPrimary)
                }
            } else {
                OnboardingCoordinatorView()
            }
        }
        .task {
            let profile = UserProfileStore.fetchOrCreate(in: context)
            appState.onboardingComplete = profile.onboardingComplete
        }
    }
}
