import SwiftUI

struct StackListView: View {
    var body: some View {
        // TODO Phase 2: implement stack list with Core Data fetch
        Text("My Stack")
            .font(.title2)
            .foregroundStyle(.secondary)
            .navigationTitle("My Stack")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AnalysisView()
                    } label: {
                        Image(systemName: "waveform.path.ecg")
                    }
                }
            }
    }
}
