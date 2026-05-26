import SwiftUI

struct OnboardingPreviewView: View {
    var onStartTrial: () -> Void

    @Environment(AnalysisStore.self) private var analysisStore
    @Environment(ScheduleStore.self) private var scheduleStore

    @State private var criticalCount: Int = 0
    @State private var blockCount: Int = 0

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {

                    // MARK: Summary Card
                    VStack(alignment: .leading, spacing: 20) {

                        // Interaction stat
                        VStack(alignment: .leading, spacing: 4) {
                            Text(criticalCount > 0
                                 ? "\(criticalCount) critical interaction\(criticalCount == 1 ? "" : "s") found"
                                 : "No critical interactions found")
                                .font(.swBody)
                                .foregroundStyle(criticalCount > 0 ? .criticalFG : .textSecondary)
                                .animation(.easeIn(duration: 0.3), value: criticalCount)
                        }

                        // Schedule block stat
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your \(blockCount)-block schedule is ready")
                                .font(.swBody)
                                .foregroundStyle(.sagePrimary)
                                .animation(.easeIn(duration: 0.3), value: blockCount)
                        }

                        // See full analysis link
                        NavigationLink {
                            AnalysisView()
                        } label: {
                            Text("See full analysis")
                                .font(.swBody)
                                .foregroundStyle(.aquaPrimary)
                        }
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.backgroundCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)

                }
                .padding(.top, 24)
                .padding(.bottom, 48)
            }
            .navigationTitle("Your Personalized Plan")
            .safeAreaInset(edge: .bottom) {
                Button("See What You're Getting") { onStartTrial() }
                    .buttonStyle(.borderedProminent)
                    .tint(.aquaPrimary)
                    .padding(.horizontal, 16)
                    .frame(minHeight: 50)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(Color.backgroundPage)
            }
            .background(Color.backgroundPage.ignoresSafeArea())
            .task {
                let results = analysisStore.currentResults()
                let schedule = scheduleStore.currentSchedule()
                criticalCount = results.critical.count
                let s = schedule
                blockCount = [s.morning, s.afternoon, s.evening].filter { !$0.isEmpty }.count
            }
        }
    }
}
