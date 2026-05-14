import SwiftUI
import CoreData

struct StackListView: View {
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\StackItem.sortOrder, order: .forward)],
        predicate: NSPredicate(format: "isActive == YES")
    )
    private var items: FetchedResults<StackItem>

    @State private var showAddItem = false

    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No items yet",
                        systemImage: "pills",
                        description: Text("Tap + to add your first supplement or medication.")
                    )
                } else {
                    List(items) { item in
                        StackItemRow(item: item)
                    }
                }
            }
            .navigationTitle("Stack")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddItem = true
                    } label: {
                        Label("Add", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddItem) {
                AddItemView()
            }
        }
    }
}

private struct StackItemRow: View {
    @ObservedObject var item: StackItem

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(item.labelValue)
                        .font(.body.weight(.medium))
                    if !item.isInDatabase {
                        Label("Custom", systemImage: "exclamationmark.triangle.fill")
                            .labelStyle(.iconOnly)
                            .foregroundStyle(.orange)
                            .accessibilityLabel("Not in interaction database")
                    }
                }
                if let dosage = item.dosage, !dosage.isEmpty {
                    Text(dosage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
        .padding(.vertical, 2)
    }

    private func badgeColor(for itemType: String) -> Color {
        itemType == "drug" ? .red : .blue
    }
}
