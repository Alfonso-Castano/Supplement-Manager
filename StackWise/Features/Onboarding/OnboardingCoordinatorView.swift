import SwiftUI
import CoreData

enum OnboardingStep: Hashable {
    case stackEntry
    case scheduleInputs
}

struct OnboardingCoordinatorView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.managedObjectContext) private var context

    @State private var path: [OnboardingStep] = []
    @State private var showPreview: Bool = false
    @State private var showPaywall: Bool = false

    var body: some View {
        NavigationStack(path: $path) {
            HealthProfileView(onNext: { path.append(.stackEntry) })
                .navigationDestination(for: OnboardingStep.self) { step in
                    switch step {
                    case .stackEntry:
                        StackEntryStepView(onNext: { path.append(.scheduleInputs) })
                    case .scheduleInputs:
                        ScheduleInputsView(onNext: { showPreview = true })
                    }
                }
        }
        .fullScreenCover(isPresented: $showPreview) {
            OnboardingPreviewView(onStartTrial: { showPaywall = true })
                .fullScreenCover(isPresented: $showPaywall) {
                    PaywallPlaceholderView(onComplete: { completeOnboarding() })
                        .interactiveDismissDisabled(true)
                }
        }
        .task { applySmartResume() }
    }

    private func applySmartResume() {
        let profile = UserProfileStore.fetchOrCreate(in: context)
        let itemRequest = StackItem.fetchRequest()
        itemRequest.predicate = NSPredicate(format: "isActive == YES")
        let itemCount = (try? context.count(for: itemRequest)) ?? 0

        // D-07: infer resume step from Core Data entity state
        if profile.age == 0 || profile.weightKg == 0 {
            path = []                                          // Step 1: no profile data
        } else if itemCount == 0 {
            path = [.stackEntry]                               // Step 2: profile filled, no items
        } else if profile.wakeTime == nil {
            path = [.stackEntry, .scheduleInputs]              // Step 3: items exist, no schedule
        } else {
            path = [.stackEntry, .scheduleInputs]
            showPreview = true                                 // Step 4: all data, go to preview
        }
    }

    private func completeOnboarding() {
        let profile = UserProfileStore.fetchOrCreate(in: context)
        UserProfileStore.markOnboarded(profile, in: context)
        // markOnboarded already guards trialStartDate == nil (REQ-19)
        appState.onboardingComplete = true
    }
}
