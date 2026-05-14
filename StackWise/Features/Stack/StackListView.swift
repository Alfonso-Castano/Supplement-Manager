import SwiftUI

struct StackListView: View {
    @State private var showAddItem = false

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "No items yet",
                systemImage: "pills",
                description: Text("Tap + to add your first supplement or medication.")
            )
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
