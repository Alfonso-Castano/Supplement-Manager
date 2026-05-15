import SwiftUI
import CoreData

@main
struct StackWiseApp: App {
    @State private var appState = AppState()
    @State private var ingredientRepo = IngredientRepository()
    @State private var interactionRepo = InteractionRepository()
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(ingredientRepo)
                .environment(interactionRepo)
                .environment(\.managedObjectContext,
                    persistenceController.container.viewContext)
        }
    }
}
