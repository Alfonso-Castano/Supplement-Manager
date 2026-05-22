import SwiftUI
import CoreData

struct ScheduleView: View {
    @Environment(ScheduleStore.self) private var scheduleStore
    @Environment(\.managedObjectContext) private var context

    private var schedule: ScheduleResult {
        scheduleStore.cachedResult ?? .empty
    }

    @State private var profile: UserProfile?

    var body: some View {
        NavigationStack {
            Group {
                if schedule == .empty {
                    ContentUnavailableView(
                        "No schedule yet",
                        systemImage: "calendar.badge.exclamationmark",
                        description: Text("Add items to your stack to generate a schedule.")
                    )
                } else {
                    List {
                        if !schedule.morning.isEmpty {
                            Section {
                                ForEach(schedule.morning) { item in
                                    ScheduleItemRow(item: item)
                                }
                            } header: {
                                Text(sectionHeader(block: "Morning"))
                            }
                        }
                        if !schedule.afternoon.isEmpty {
                            Section {
                                ForEach(schedule.afternoon) { item in
                                    ScheduleItemRow(item: item)
                                }
                            } header: {
                                Text(sectionHeader(block: "Afternoon"))
                            }
                        }
                        if !schedule.evening.isEmpty {
                            Section {
                                ForEach(schedule.evening) { item in
                                    ScheduleItemRow(item: item)
                                }
                            } header: {
                                Text(sectionHeader(block: "Evening"))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Schedule")
        }
        .task {
            scheduleStore.currentSchedule()
            let request = UserProfile.fetchRequest()
            request.fetchLimit = 1
            profile = try? context.fetch(request).first
        }
    }

    // MARK: - Section Header Helpers

    private func sectionHeader(block: String) -> String {
        let prof = self.profile
        let now = Date()
        let cal = Calendar.current

        let (start, end): (Date, Date) = {
            switch block {
            case "Morning":
                let s = prof?.wakeTime ?? cal.date(bySettingHour: 7, minute: 0, second: 0, of: now)!
                let e = prof?.lunchTime ?? cal.date(bySettingHour: 12, minute: 0, second: 0, of: now)!
                return (s, e)
            case "Afternoon":
                let s = prof?.lunchTime ?? cal.date(bySettingHour: 12, minute: 0, second: 0, of: now)!
                let e = prof?.dinnerTime ?? cal.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
                return (s, e)
            case "Evening":
                let s = prof?.dinnerTime ?? cal.date(bySettingHour: 18, minute: 0, second: 0, of: now)!
                let e = prof?.sleepTime ?? cal.date(bySettingHour: 22, minute: 0, second: 0, of: now)!
                return (s, e)
            default:
                return (now, now)
            }
        }()

        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(block) \u{00B7} \(formatter.string(from: start))\u{2013}\(formatter.string(from: end))"
    }
}

// MARK: - Item Row

private struct ScheduleItemRow: View {
    let item: ScheduledItem
    @Environment(AnalysisStore.self) private var analysisStore

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(displayName(item.label))
                    .font(.body.weight(.medium))
                HStack(spacing: 4) {
                    if !item.dosage.isEmpty {
                        Text(item.dosage)
                            .font(.callout)
                            .foregroundStyle(.textSecondary)
                    }
                    if item.isPrescription {
                        if !item.dosage.isEmpty {
                            Text("\u{00B7}")
                                .font(.callout)
                                .foregroundStyle(.textSecondary)
                        }
                        Text("Rx")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.aquaPrimary)
                    }
                }
            }
            Spacer()
            badges
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder
    private var badges: some View {
        let slug = item.activeIngredient
        let results = analysisStore.currentResults()
        let severity = slug.isEmpty ? nil : results.worstSeverity(forSlug: slug)
        let synergy = !slug.isEmpty && results.hasSynergy(forSlug: slug)

        HStack(spacing: 6) {
            if severity == .critical {
                Image(systemName: "exclamationmark.octagon.fill")
                    .foregroundStyle(.criticalFG)
            }
            if synergy {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.positiveFG)
            }
            if item.isPrescription {
                Image(systemName: "cross.case.fill")
                    .foregroundStyle(.aquaPrimary)
            }
        }
        .font(.callout)
    }

    private func displayName(_ label: String) -> String {
        label
            .split(separator: "_")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
