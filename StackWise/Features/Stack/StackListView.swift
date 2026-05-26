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
    @State private var showAnalysis: Bool = false

    private var reviewCount: Int {
        let results = analysisStore.currentResults()
        return items.filter { item in
            guard item.isInDatabase else { return false }
            let slug = item.activeIngredientValue
            guard !slug.isEmpty else { return false }
            return results.worstSeverity(forSlug: slug) != nil
        }.count
    }

    private var flaggedCount: Int { reviewCount }

    private var subtitleText: String {
        "\(items.count) items · \(flaggedCount) flagged"
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
            .navigationTitle("My Stack")
            .navigationDestination(isPresented: $showAnalysis) {
                AnalysisView()
            }
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
            .safeAreaInset(edge: .bottom) {
                if !items.isEmpty {
                    AnalyzeStackButton(reviewCount: reviewCount) {
                        showAnalysis = true
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private var addItemButton: some View {
        Button {
            showAddItem = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                Text("Add Item")
                    .font(.swHeadline)
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(Color.aquaLight)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var emptyState: some View {
        VStack {
            addItemButton
                .padding(.horizontal, 16)
                .padding(.top, 16)
            Spacer()
        }
    }

    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                Text(subtitleText)
                    .font(.subheadline)
                    .foregroundStyle(.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                addItemButton
                    .padding(.horizontal, 16)
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
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: "pill.fill")
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
        .buttonStyle(.plain)
    }
}

// MARK: - Severity Badge

private enum RowSeverityKind {
    case critical, advisory, positive, notInDB

    var label: String {
        switch self {
        case .critical: return "Critical"
        case .advisory: return "Advisory"
        case .positive: return "Positive"
        case .notInDB:  return "Not in DB"
        }
    }

    var icon: String {
        switch self {
        case .critical: return "exclamationmark.octagon.fill"
        case .advisory: return "exclamationmark.triangle.fill"
        case .positive: return "checkmark.circle.fill"
        case .notInDB:  return "questionmark.circle"
        }
    }

    var background: Color {
        switch self {
        case .critical: return .criticalBG
        case .advisory: return .advisoryBG
        case .positive: return .positiveBG
        case .notInDB:  return .notFoundBG
        }
    }

    var foreground: Color {
        switch self {
        case .critical: return .criticalFG
        case .advisory: return .advisoryFG
        case .positive: return .positiveFG
        case .notInDB:  return .notFoundFG
        }
    }
}

private struct SeverityBadge: View {
    let kind: RowSeverityKind

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: kind.icon)
                .font(.caption2.weight(.semibold))
            Text(kind.label)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(kind.background)
        .foregroundStyle(kind.foreground)
        .clipShape(Capsule())
    }
}

// MARK: - Item Card

private struct StackItemCard: View {
    @ObservedObject var item: StackItem
    @Environment(AnalysisStore.self) private var analysisStore

    @State private var showEdit = false

    private var rowSeverity: RowSeverityKind? {
        if !item.isInDatabase { return .notInDB }
        let slug = item.activeIngredientValue
        guard !slug.isEmpty else { return nil }
        let results = analysisStore.currentResults()
        if let worst = results.worstSeverity(forSlug: slug) {
            switch worst {
            case .critical: return .critical
            case .advisory: return .advisory
            }
        }
        if results.hasSynergy(forSlug: slug) { return .positive }
        return nil
    }

    private var subtitle: String {
        let dose = (item.dosage ?? "").trimmingCharacters(in: .whitespaces)
        let freq = (item.frequency ?? "").trimmingCharacters(in: .whitespaces)
        switch (dose.isEmpty, freq.isEmpty) {
        case (true, true):   return ""
        case (false, true):  return dose
        case (true, false):  return freq
        case (false, false): return "\(dose) · \(freq)"
        }
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName(item.labelValue))
                    .font(.body.weight(.medium))
                    .foregroundStyle(.textPrimary)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.textSecondary)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                Text(item.itemTypeValue.capitalized)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(badgeColor(for: item.itemTypeValue).opacity(0.15))
                    .foregroundStyle(badgeColor(for: item.itemTypeValue))
                    .clipShape(Capsule())
                if let kind = rowSeverity {
                    SeverityBadge(kind: kind)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture { showEdit = true }
        .sheet(isPresented: $showEdit) { EditItemView(item: item) }
    }

    private func badgeColor(for itemType: String) -> Color {
        itemType == "drug" ? .sagePrimary : .aquaPrimary
    }
}
