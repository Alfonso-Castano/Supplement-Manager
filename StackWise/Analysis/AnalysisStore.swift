import CoreData

@MainActor
@Observable
final class AnalysisStore {
    private let repo: InteractionRepository
    private let context: () -> NSManagedObjectContext

    private(set) var results: AnalysisResults?
    private(set) var dirty: Bool = true

    init(repo: InteractionRepository, context: @escaping () -> NSManagedObjectContext) {
        self.repo = repo
        self.context = context
    }

    // Test-only init that accepts a pairFetcher closure (bypasses InteractionRepository)
    #if DEBUG
    init(
        pairFetcher: @escaping (Set<String>) -> [InteractionPair],
        context: @escaping () -> NSManagedObjectContext
    ) {
        self.repo = InteractionRepository()
        self.context = context
        self._testPairFetcher = pairFetcher
    }
    private var _testPairFetcher: ((Set<String>) -> [InteractionPair])?
    #endif

    func invalidate() {
        dirty = true
        results = nil
    }

    @discardableResult
    func currentResults() -> AnalysisResults {
        if let results, !dirty { return results }
        let fresh = recompute()
        results = fresh
        dirty = false
        return fresh
    }

    private func recompute() -> AnalysisResults {
        let ctx = context()
        let request = StackItem.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(key: "sortOrder", ascending: true)]
        let items: [StackItem] = (try? ctx.fetch(request)) ?? []
        let views = items.map { item -> StackItemView in
            // Use typed accessors from StackItem+CoreDataClass.swift
            let label = item.labelValue
            let slug = item.activeIngredientValue
            let isInDB = item.isInDatabase
            return StackItemView(label: label, slug: slug, isInDatabase: isInDB)
        }
        #if DEBUG
        let fetcher = _testPairFetcher ?? repo.pairwise(for:)
        return AnalysisEngine.analyze(activeItems: views, pairFetcher: fetcher)
        #else
        return AnalysisEngine.analyze(activeItems: views, pairFetcher: repo.pairwise(for:))
        #endif
    }
}
