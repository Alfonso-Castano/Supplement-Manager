import CoreData

enum UserProfileStore {

    /// Returns the singleton UserProfile, creating it on first launch.
    /// Safe to call repeatedly — guaranteed to yield the same objectID within a context.
    @discardableResult
    static func fetchOrCreate(in context: NSManagedObjectContext) -> UserProfile {
        let request = UserProfile.fetchRequest()
        request.fetchLimit = 1
        if let existing = try? context.fetch(request).first {
            return existing
        }
        let profile = UserProfile(context: context)
        profile.id = UUID()
        profile.onboardingComplete = false
        profile.subscriptionStatus = "unknown"
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to create UserProfile singleton: \(error)")
        }
        return profile
    }

    static func markOnboarded(_ profile: UserProfile, in context: NSManagedObjectContext) {
        profile.onboardingComplete = true
        if profile.trialStartDate == nil {
            profile.trialStartDate = .now
        }
        do {
            try context.save()
        } catch {
            assertionFailure("Failed to mark UserProfile onboarded: \(error)")
        }
    }
}
