import Foundation

struct AnalysisResults: Equatable {
    var critical: [InteractionPair]
    var advisory: [InteractionPair]
    var synergy: [InteractionPair]
    var notInDatabase: [String]

    static let empty = AnalysisResults(critical: [], advisory: [], synergy: [], notInDatabase: [])

    func worstSeverity(forSlug slug: String) -> InteractionSeverity? {
        let inCritical = critical.contains { $0.compoundA == slug || $0.compoundB == slug }
        if inCritical { return .critical }
        let inAdvisory = advisory.contains { $0.compoundA == slug || $0.compoundB == slug }
        if inAdvisory { return .advisory }
        return nil
    }

    func hasSynergy(forSlug slug: String) -> Bool {
        synergy.contains { $0.compoundA == slug || $0.compoundB == slug }
    }
}
