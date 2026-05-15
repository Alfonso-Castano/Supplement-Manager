enum AnalysisEngine {
    static func analyze(
        activeItems: [StackItemView],
        pairFetcher: (Set<String>) -> [InteractionPair]
    ) -> AnalysisResults {
        let notInDB = activeItems.filter { !$0.isInDatabase }.map { $0.label }
        let slugs = Set(activeItems.filter { $0.isInDatabase }.map { $0.slug })
        guard slugs.count >= 2 else {
            return AnalysisResults(critical: [], advisory: [], synergy: [], notInDatabase: notInDB)
        }
        let pairs = pairFetcher(slugs)
        var critical: [InteractionPair] = []
        var advisory: [InteractionPair] = []
        var synergy: [InteractionPair] = []
        for pair in pairs {
            if pair.interactionType == .synergy {
                synergy.append(pair)
            } else if pair.severity == .critical {
                critical.append(pair)
            } else {
                advisory.append(pair)
            }
        }
        return AnalysisResults(critical: critical, advisory: advisory, synergy: synergy, notInDatabase: notInDB)
    }
}

struct StackItemView: Equatable {
    let label: String
    let slug: String
    let isInDatabase: Bool
}
