import SwiftUI

struct AnalysisView: View {
    @Environment(AnalysisStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var expandedCards: Set<Int64> = []

    var body: some View {
        let results = store.currentResults()
        if results == .empty {
            emptyState
        } else {
            populatedState(results: results)
        }
    }

    // MARK: — Empty State

    private var emptyState: some View {
        ZStack {
            Color.backgroundPage.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 40))
                    .foregroundStyle(Color.aquaPrimary)

                Text("Your analysis will appear here")
                    .font(.swHeadline)
                    .foregroundStyle(Color.textPrimary)

                Text("Add 2 or more items to your Stack to see interactions, warnings, and synergies.")
                    .font(.swCallout)
                    .foregroundStyle(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 280)

                ShimmerSkeletonCard()
                ShimmerSkeletonCard()

                Button("Go to Stack") { dismiss() }
                    .font(.swHeadline)
                    .foregroundStyle(.white)
                    .frame(width: 200, height: 48)
                    .background(Color.aquaPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .navigationTitle("Analysis")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            anchorBar(results: .empty)
        }
    }

    // MARK: — Populated State

    private func populatedState(results: AnalysisResults) -> some View {
        let allPairIDs: [Int64] = (results.critical + results.advisory + results.synergy).map(\.id)
        let allExpanded = !allPairIDs.isEmpty && allPairIDs.allSatisfy { expandedCards.contains($0) }

        return ZStack {
            Color.backgroundPage.ignoresSafeArea()
            List {
                // Subtitle row
                Section {
                    (
                        Text("● ").foregroundStyle(Color.criticalFG)
                        + Text("\(results.critical.count) critical  ·  ").foregroundStyle(Color.textSecondary)
                        + Text("● ").foregroundStyle(Color.advisoryFG)
                        + Text("\(results.advisory.count) advisory  ·  ").foregroundStyle(Color.textSecondary)
                        + Text("● ").foregroundStyle(Color.positiveFG)
                        + Text("\(results.synergy.count) positive").foregroundStyle(Color.textSecondary)
                    )
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 4, trailing: 16))
                }

                // Critical
                if !results.critical.isEmpty {
                    Section {
                        ForEach(results.critical) { pair in
                            InteractionCard(
                                pair: pair,
                                cardType: .critical,
                                isExpanded: expandedCards.contains(pair.id)
                            ) {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    if expandedCards.contains(pair.id) {
                                        expandedCards.remove(pair.id)
                                    } else {
                                        expandedCards.insert(pair.id)
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    } header: {
                        sectionHeader(
                            icon: "exclamationmark.octagon.fill",
                            label: "CRITICAL",
                            color: Color.criticalFG
                        )
                    }
                }

                // Advisory
                if !results.advisory.isEmpty {
                    Section {
                        ForEach(results.advisory) { pair in
                            InteractionCard(
                                pair: pair,
                                cardType: .advisory,
                                isExpanded: expandedCards.contains(pair.id)
                            ) {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    if expandedCards.contains(pair.id) {
                                        expandedCards.remove(pair.id)
                                    } else {
                                        expandedCards.insert(pair.id)
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    } header: {
                        sectionHeader(
                            icon: "exclamationmark.triangle.fill",
                            label: "ADVISORY",
                            color: Color.advisoryFG
                        )
                    }
                }

                // Positive insights
                if !results.synergy.isEmpty {
                    Section {
                        ForEach(results.synergy) { pair in
                            InteractionCard(
                                pair: pair,
                                cardType: .positive,
                                isExpanded: expandedCards.contains(pair.id)
                            ) {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    if expandedCards.contains(pair.id) {
                                        expandedCards.remove(pair.id)
                                    } else {
                                        expandedCards.insert(pair.id)
                                    }
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                        }
                    } header: {
                        sectionHeader(
                            icon: "checkmark.seal.fill",
                            label: "POSITIVE INSIGHTS",
                            color: Color.positiveFG
                        )
                    }
                }

                // Not in database
                if !results.notInDatabase.isEmpty {
                    Section {
                        ForEach(results.notInDatabase, id: \.self) { label in
                            HStack {
                                Image(systemName: "questionmark.circle")
                                    .foregroundStyle(Color.notFoundFG)
                                Text(label)
                                    .foregroundStyle(Color.textPrimary)
                                Spacer()
                                badgePill(
                                    text: "Not in DB",
                                    bg: Color.notFoundBG,
                                    fg: Color.notFoundFG
                                )
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    } header: {
                        sectionHeader(
                            icon: "questionmark.circle.fill",
                            label: "NOT IN DATABASE",
                            color: Color.textTertiary
                        )
                    } footer: {
                        Text("No interaction data available for these items.")
                            .font(.swFootnote)
                            .foregroundStyle(Color.textTertiary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Analysis")
        .navigationBarTitleDisplayMode(.large)
        .safeAreaInset(edge: .bottom) {
            anchorBar(results: results, allExpanded: allExpanded, allPairIDs: allPairIDs)
        }
    }

    // MARK: — Anchor Bar

    private func anchorBar(
        results: AnalysisResults,
        allExpanded: Bool = false,
        allPairIDs: [Int64] = []
    ) -> some View {
        let isEmpty = results == .empty
        let label = (allExpanded && !isEmpty) ? "Collapse All" : "Reveal Full Analysis"
        let isActive = !isEmpty

        return Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                if allExpanded {
                    expandedCards.removeAll()
                } else {
                    expandedCards = Set(allPairIDs)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isActive ? .white : Color.white.opacity(0.6))
                Text(label)
                    .font(.swHeadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isActive ? .white : Color.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(isActive ? Color.aquaPrimary : Color.textTertiary.opacity(0.4))
        }
        .disabled(!isActive)
    }

    // MARK: — Helpers

    private func sectionHeader(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(label)
                .foregroundStyle(color)
        }
        .font(.swFootnote)
    }

    private func badgePill(text: String, bg: Color, fg: Color) -> some View {
        Text(text)
            .font(.swCaption.weight(.medium))
            .foregroundStyle(fg)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(bg)
            .clipShape(RoundedRectangle(cornerRadius: 100))
    }
}

// MARK: — Card Type

private enum CardType {
    case critical, advisory, positive, notFound

    var cardBG: Color {
        switch self {
        case .critical: return .cardCriticalBG
        case .advisory: return .cardAdvisoryBG
        case .positive: return .cardPositiveBG
        case .notFound: return .notFoundBG
        }
    }

    var borderColor: Color {
        switch self {
        case .critical: return .criticalFG
        case .advisory: return .advisoryFG
        case .positive: return .positiveFG
        case .notFound: return .notFoundFG
        }
    }

    var accentColor: Color {
        switch self {
        case .critical: return .criticalFG
        case .advisory: return .advisoryFG
        case .positive: return .positiveFG
        case .notFound: return .notFoundFG
        }
    }

    var badgeBG: Color {
        switch self {
        case .critical: return .criticalBG
        case .advisory: return .advisoryBG
        case .positive: return .positiveBG
        case .notFound: return .notFoundBG
        }
    }

    var badgeFG: Color { accentColor }

    var badgeLabel: String {
        switch self {
        case .critical: return "Critical"
        case .advisory: return "Advisory"
        case .positive: return "Positive"
        case .notFound: return "Not in DB"
        }
    }
}

// MARK: — InteractionCard

private struct InteractionCard: View {
    let pair: InteractionPair
    let cardType: CardType
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Line 1: icon + name + badge
            HStack {
                Image(systemName: iconName)
                    .foregroundStyle(cardType.accentColor)
                Text(displayName(pair.compoundA) + " ↔ " + displayName(pair.compoundB))
                    .font(.swHeadline)
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Text(cardType.badgeLabel)
                    .font(.swCaption.weight(.medium))
                    .foregroundStyle(cardType.badgeFG)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(cardType.badgeBG)
                    .clipShape(RoundedRectangle(cornerRadius: 100))
            }
            // Line 2: interaction type subtitle
            Text(interactionTypeLabel)
                .font(.swCallout)
                .foregroundStyle(Color.textSecondary)

            // Lines 3-4: expanded content
            if isExpanded {
                Text(pair.effect)
                    .font(.swCallout)
                    .foregroundStyle(Color.textSecondary)
                    .padding(.top, 2)
                Text(pair.suggestedAction)
                    .font(.swCallout)
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(cardType.cardBG)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(cardType.borderColor)
                .frame(width: 3)
                .clipShape(
                    UnevenRoundedRectangle(
                        cornerRadii: .init(
                            topLeading: 12,
                            bottomLeading: 12,
                            bottomTrailing: 0,
                            topTrailing: 0
                        )
                    )
                )
        }
        .contentShape(Rectangle())
        .onTapGesture { onTap() }
    }

    private var iconName: String {
        switch pair.interactionType {
        case .synergy:               return "leaf.fill"
        case .unsafeCombination:     return "exclamationmark.octagon.fill"
        case .absorptionCompetition: return "arrow.left.arrow.right.circle"
        case .timingConflict:        return "clock.badge.exclamationmark"
        }
    }

    private var interactionTypeLabel: String {
        switch pair.interactionType {
        case .unsafeCombination:     return "Unsafe combination"
        case .absorptionCompetition: return "Absorption competition"
        case .timingConflict:        return "Timing conflict"
        case .synergy:               return "Synergy"
        }
    }
}

// MARK: — ShimmerSkeletonCard

private struct ShimmerSkeletonCard: View {
    @State private var phase: CGFloat = -1

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle().frame(width: 16, height: 16)
                RoundedRectangle(cornerRadius: 4).frame(width: 140, height: 14)
                Spacer()
                RoundedRectangle(cornerRadius: 8).frame(width: 60, height: 22)
            }
            RoundedRectangle(cornerRadius: 4).frame(height: 12)
            RoundedRectangle(cornerRadius: 4).frame(width: 200, height: 12)
            RoundedRectangle(cornerRadius: 4).frame(width: 160, height: 12)
        }
        .padding(16)
        .background(
            ZStack {
                Color(hex: "#E8E8ED")
                LinearGradient(
                    colors: [.clear, Color.white.opacity(0.5), .clear],
                    startPoint: UnitPoint(x: phase, y: 0),
                    endPoint: UnitPoint(x: phase + 0.4, y: 0)
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                phase = 1.4
            }
        }
    }
}
