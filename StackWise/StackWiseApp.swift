import CoreData
import SwiftUI

@main
struct StackWiseApp: App {
    @State private var appState: AppState
    @State private var ingredientRepo: IngredientRepository
    @State private var interactionRepo: InteractionRepository
    @State private var analysisStore: AnalysisStore
    @State private var scheduleStore: ScheduleStore
    let persistenceController = PersistenceController.shared

    init() {
        // Bootstrap onboarding state synchronously so ContentView renders the correct
        // branch on the first frame — avoids a flash of OnboardingCoordinatorView for
        // returning users whose Core Data record has onboardingComplete = true.
        let context = PersistenceController.shared.container.viewContext
        let profileRequest = UserProfile.fetchRequest()
        profileRequest.fetchLimit = 1
        let onboardingDone = (try? context.fetch(profileRequest).first?.onboardingComplete) ?? false

        let app = AppState()
        app.onboardingComplete = onboardingDone

        let ing = IngredientRepository()
        let inter = InteractionRepository()
        _appState        = State(initialValue: app)
        _ingredientRepo  = State(initialValue: ing)
        _interactionRepo = State(initialValue: inter)
        _analysisStore   = State(initialValue: AnalysisStore(
            repo: inter,
            context: { PersistenceController.shared.container.viewContext }
        ))
        _scheduleStore   = State(initialValue: ScheduleStore(
            interactionRepo: inter,
            ingredientRepo: ing,
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
                .environment(scheduleStore)
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
