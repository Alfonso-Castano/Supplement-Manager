import CoreData
import SwiftUI

@main
struct StackWiseApp: App {
    @State private var appState: AppState
    @State private var ingredientRepo: IngredientRepository
    @State private var interactionRepo: InteractionRepository
    @State private var analysisStore: AnalysisStore
    let persistenceController = PersistenceController.shared

    init() {
        let app = AppState()
        let ing = IngredientRepository()
        let inter = InteractionRepository()
        _appState        = State(initialValue: app)
        _ingredientRepo  = State(initialValue: ing)
        _interactionRepo = State(initialValue: inter)
        _analysisStore   = State(initialValue: AnalysisStore(
            repo: inter,
            context: { PersistenceController.shared.container.viewContext }
        ))
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(ingredientRepo)
                .environment(interactionRepo)
                .environment(analysisStore)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
