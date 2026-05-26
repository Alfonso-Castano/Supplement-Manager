import SwiftUI
import CoreData

struct StackEntryStepView: View {
    var onNext: () -> Void = {}

    @FetchRequest(
        sortDescriptors: [SortDescriptor(\StackItem.sortOrder, order: .forward)],
        predicate: NSPredicate(format: "isActive == YES")
    )
    private var items: FetchedResults<StackItem>

    @State private var showAddItem = false

    var body: some View {
        VStack(spacing: 0) {
            if items.isEmpty {
                Spacer()
                Text("Add your supplements to see how they interact and get your personalized schedule")
                    .font(.swBody)
                    .foregroundStyle(.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Spacer()
            } else {
                List(items) { item in
                    Text(item.labelValue)
                        .font(.swBody)
                        .foregroundStyle(.textPrimary)
                }
                .listStyle(.plain)
            }

            Button("Next", action: onNext)
                .disabled(items.isEmpty)
                .opacity(items.isEmpty ? 0.4 : 1.0)
                .buttonStyle(.borderedProminent)
                .tint(.aquaPrimary)
                .padding(.horizontal, 16)
                .frame(minHeight: 50)
                .padding(.bottom, 16)
        }
        .navigationTitle("Your Supplement Stack")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showAddItem = true } label: {
                    Image(systemName: "plus").foregroundStyle(.aquaPrimary)
                }
            }
        }
        .sheet(isPresented: $showAddItem) {
            AddItemView()
        }
    }
}
