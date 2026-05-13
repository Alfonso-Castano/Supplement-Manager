import SwiftUI

struct ContentView: View {
    var body: some View {
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
    }
}
