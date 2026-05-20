import SwiftUI
import CoreData

struct StackListView: View {
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\StackItem.sortOrder, order: .forward)],
        predicate: NSPredicate(format: "isActive == YES")
    )
    private var items: FetchedResults<StackItem>

    @Environment(AnalysisStore.self) private var analysisStore
    @State private var showAddItem = false

    private var reviewCount: Int {
        let results = analysisStore.currentResults()
        return items.filter { item in
            guard item.isInDatabase else { return false }
            let slug = item.activeIngredientValue
            guard !slug.isEmpty else { return false }
            return results.worstSeverity(forSlug: slug) != nil
        }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.backgroundPage.ignoresSafeArea()
                if items.isEmpty {
                    emptyState
                } else {
                    scrollContent
                }
            }
            .navigationTitle("Stack")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddItem = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.aquaPrimary)
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddItemView()
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No items yet",
            systemImage: "pills",
            description: Text("Tap + to add your first supplement or medication.")
        )
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                NavigationLink {
                    AnalysisView()
                } label: {
                    AnalyzeStackButton(reviewCount: reviewCount)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 16)

                LazyVStack(spacing: 10) {
                    ForEach(items) { item in
                        StackItemCard(item: item)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 24)
            }
        }
    }
}

// MARK: - Analyze Button

private struct AnalyzeStackButton: View {
    let reviewCount: Int

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform.path.ecg")
                .font(.swHeadline)
            Text("Analyze My Stack")
                .font(.swHeadline)
            Spacer()
            if reviewCount > 0 {
                Text("\(reviewCount) to review")
                    .font(.swCaption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(.white.opacity(0.25))
                    .clipShape(Capsule())
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity)
        .background(Color.aquaPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Item Card

private struct StackItemCard: View {
    @ObservedObject var item: StackItem
    @Environment(AnalysisStore.self) private var store

    private var severityForRow: InteractionSeverity? {
        guard item.isInDatabase else { return nil }
        let slug = item.activeIngredientValue
        guard !slug.isEmpty else { return nil }
        return store.currentResults().worstSeverity(forSlug: slug)
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.labelValue)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.textPrimary)
                    if !item.isInDatabase {
                        Label("Custom", systemImage: "exclamationmark.triangle.fill")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.notFoundFG)
                            .accessibilityLabel("Not in interaction database")
                    }
                    if let severity = severityForRow {
                        Image(systemName: severity == .critical
                              ? "exclamationmark.octagon.fill"
                              : "exclamationmark.circle.fill")
                            .foregroundStyle(severity == .critical ? .criticalFG : .advisoryFG)
                            .accessibilityLabel(severity == .critical
                                                ? "Critical interaction present"
                                                : "Advisory interaction present")
                    }
                }
                if let dosage = item.dosage, !dosage.isEmpty {
                    Text(dosage)
                        .font(.subheadline)
                        .foregroundStyle(.textSecondary)
                }
            }
            Spacer()
            Text(item.itemTypeValue.capitalized)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(badgeColor(for: item.itemTypeValue).opacity(0.15))
                .foregroundStyle(badgeColor(for: item.itemTypeValue))
                .clipShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func badgeColor(for itemType: String) -> Color {
        itemType == "drug" ? .sagePrimary : .aquaPrimary
    }
}
