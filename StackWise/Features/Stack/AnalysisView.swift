import SwiftUI

struct AnalysisView: View {
    @Environment(AnalysisStore.self) private var store

    var body: some View {
        let results = store.currentResults()
        Group {
            if results == .empty {
                ContentUnavailableView(
                    "Nothing to analyze yet",
                    systemImage: "magnifyingglass",
                    description: Text("Add at least two items to your stack to see interactions.")
                )
            } else {
                List {
                    if !results.critical.isEmpty {
                        Section("Critical") {
                            ForEach(results.critical) { PairRow(pair: $0, accent: .red) }
                        }
                    }
                    if !results.advisory.isEmpty {
                        Section("Advisory") {
                            ForEach(results.advisory) { PairRow(pair: $0, accent: .orange) }
                        }
                    }
                    if !results.synergy.isEmpty {
                        Section("Positive insights") {
                            ForEach(results.synergy) { PairRow(pair: $0, accent: .green) }
                        }
                    }
                    if !results.notInDatabase.isEmpty {
                        Section {
                            ForEach(results.notInDatabase, id: \.self) { label in
                                HStack {
                                    Image(systemName: "questionmark.circle")
                                        .foregroundStyle(.secondary)
                                    Text(label)
                                    Spacer()
                                    Text("Not in DB")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        } header: {
                            Text("Not in our database")
                        } footer: {
                            Text("No interaction data available for these items.")
                        }
                    }
                }
            }
        }
        .navigationTitle("Analysis")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct PairRow: View {
    let pair: InteractionPair
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: iconName)
                    .foregroundStyle(accent)
                Text("\(displayName(pair.compoundA)) ↔ \(displayName(pair.compoundB))")
                    .font(.body.weight(.medium))
            }
            Text(pair.effect)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(pair.suggestedAction)
                .font(.callout)
                .foregroundStyle(.primary)
                .padding(.top, 2)
        }
        .padding(.vertical, 4)
    }

    private var iconName: String {
        switch pair.interactionType {
        case .synergy: return "leaf.fill"
        case .unsafeCombination: return "exclamationmark.octagon.fill"
        case .absorptionCompetition: return "arrow.left.arrow.right.circle"
        case .timingConflict: return "clock.badge.exclamationmark"
        }
    }

    private func displayName(_ slug: String) -> String {
        slug
            .split(separator: "_")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
