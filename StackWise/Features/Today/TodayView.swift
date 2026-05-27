import SwiftUI
import CoreData

struct TodayView: View {
    @Environment(ScheduleStore.self) private var scheduleStore
    @Environment(\.managedObjectContext) private var context

    @FetchRequest private var checkOffs: FetchedResults<DailyCheckOff>

    init() {
        let today = Calendar.current.startOfDay(for: Date())
        _checkOffs = FetchRequest(
            sortDescriptors: [],
            predicate: NSPredicate(format: "checkOffDate == %@", today as NSDate)
        )
    }

    // MARK: - Testable Static Helpers

    /// Returns true if the block's first item suggestedTime is before now.
    static func isPastBlock(items: [ScheduledItem]) -> Bool {
        guard let first = items.first else { return false }
        return first.suggestedTime < Date()
    }

    /// Upserts a DailyCheckOff record for the given timeBlock with midnight-normalized date.
    static func markCompleteBlock(timeBlock: String, in context: NSManagedObjectContext) {
        let today = Calendar.current.startOfDay(for: Date())
        let request = DailyCheckOff.fetchRequest()
        request.predicate = NSPredicate(
            format: "checkOffDate == %@ AND timeBlock == %@",
            today as NSDate, timeBlock
        )
        request.fetchLimit = 1
        let existing = (try? context.fetch(request))?.first
        let record = existing ?? DailyCheckOff(context: context)
        record.id = record.id ?? UUID()
        record.checkOffDate = today
        record.timeBlock = timeBlock
        record.completed = true
        record.completedAt = Date()
        try? context.save()
    }

    // MARK: - Instance Helpers

    private func isComplete(block: String) -> Bool {
        checkOffs.contains { $0.timeBlockValue == block && $0.completed }
    }

    private func isPast(block: String, items: [ScheduledItem]) -> Bool {
        Self.isPastBlock(items: items)
    }

    private func markComplete(timeBlock: String) {
        Self.markCompleteBlock(timeBlock: timeBlock, in: context)
    }

    private var completedCount: Int {
        let schedule = scheduleStore.currentSchedule()
        var count = 0
        if !schedule.morning.isEmpty && isComplete(block: "morning") { count += 1 }
        if !schedule.afternoon.isEmpty && isComplete(block: "afternoon") { count += 1 }
        if !schedule.evening.isEmpty && isComplete(block: "evening") { count += 1 }
        return count
    }

    private var totalBlockCount: Int {
        let schedule = scheduleStore.currentSchedule()
        var count = 0
        if !schedule.morning.isEmpty { count += 1 }
        if !schedule.afternoon.isEmpty { count += 1 }
        if !schedule.evening.isEmpty { count += 1 }
        return count
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            let schedule = scheduleStore.currentSchedule()
            if schedule.allItems().isEmpty {
                ContentUnavailableView(
                    "Nothing scheduled today",
                    systemImage: "checkmark.circle",
                    description: Text("Add items to your stack to generate a schedule.")
                )
                .navigationTitle("Today")
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Completion summary
                        HStack {
                            if completedCount == totalBlockCount && totalBlockCount > 0 {
                                Text("All done for today.")
                                    .font(.swFootnote)
                                    .foregroundStyle(.sagePrimary)
                            } else {
                                Text("\(completedCount) of \(totalBlockCount) blocks done today")
                                    .font(.swFootnote)
                                    .foregroundStyle(.textSecondary)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        // Block cards
                        if !schedule.morning.isEmpty {
                            BlockRow(
                                blockName: "Morning",
                                timeBlock: "morning",
                                items: schedule.morning,
                                isComplete: isComplete(block: "morning"),
                                isPast: isPast(block: "morning", items: schedule.morning),
                                toggleBinding: Binding(
                                    get: { isComplete(block: "morning") },
                                    set: { newValue in if newValue { markComplete(timeBlock: "morning") } }
                                )
                            )
                        }
                        if !schedule.afternoon.isEmpty {
                            BlockRow(
                                blockName: "Afternoon",
                                timeBlock: "afternoon",
                                items: schedule.afternoon,
                                isComplete: isComplete(block: "afternoon"),
                                isPast: isPast(block: "afternoon", items: schedule.afternoon),
                                toggleBinding: Binding(
                                    get: { isComplete(block: "afternoon") },
                                    set: { newValue in if newValue { markComplete(timeBlock: "afternoon") } }
                                )
                            )
                        }
                        if !schedule.evening.isEmpty {
                            BlockRow(
                                blockName: "Evening",
                                timeBlock: "evening",
                                items: schedule.evening,
                                isComplete: isComplete(block: "evening"),
                                isPast: isPast(block: "evening", items: schedule.evening),
                                toggleBinding: Binding(
                                    get: { isComplete(block: "evening") },
                                    set: { newValue in if newValue { markComplete(timeBlock: "evening") } }
                                )
                            )
                        }
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 48)
                }
                .navigationTitle("Today")
                .background(Color.backgroundPage.ignoresSafeArea())
            }
        }
    }
}

// MARK: - BlockRow

private struct BlockRow: View {
    let blockName: String
    let timeBlock: String
    let items: [ScheduledItem]
    let isComplete: Bool
    let isPast: Bool
    @Binding var toggleBinding: Bool

    // Time formatter for suggestedTime display
    private var timeString: String {
        guard let first = items.first else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: first.suggestedTime)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Block header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(blockName)
                        .font(.swHeadline)
                        .foregroundStyle(isComplete ? Color.sagePrimary : Color.textPrimary)
                    if !timeString.isEmpty {
                        Text(timeString)
                            .font(.swCallout)
                            .foregroundStyle(.textSecondary)
                    }
                }
                Spacer()
                if isComplete {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .font(.swFootnote)
                        .foregroundStyle(.positiveFG)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.positiveBG)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider()
                .padding(.horizontal, 16)

            // Item list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(items) { item in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.aquaPrimary.opacity(0.25))
                            .frame(width: 6, height: 6)
                        Text(displayName(item.label))
                            .font(.swBody)
                            .foregroundStyle(.textPrimary)
                        if !item.dosage.isEmpty {
                            Text(item.dosage)
                                .font(.swCallout)
                                .foregroundStyle(.textSecondary)
                        }
                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)

            Divider()
                .padding(.horizontal, 16)

            // Mark complete row
            HStack {
                Text("Mark complete")
                    .font(.swBody)
                    .foregroundStyle((isPast && !isComplete) ? Color.textTertiary : Color.textPrimary)
                Spacer()
                Toggle("", isOn: $toggleBinding)
                    .labelsHidden()
                    .tint(.aquaPrimary)
                    .disabled(isPast && !isComplete)
                    .animation(.easeIn(duration: 0.3), value: isComplete)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(Color.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 16)
        .opacity((isPast && !isComplete) ? 0.4 : 1.0)
    }
}
