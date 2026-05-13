import SwiftUI
import CoreData

@main
struct StackWiseApp: App {
    @State private var appState = AppState()
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(\.managedObjectContext,
                    persistenceController.container.viewContext)
        }
    }
}
