import SwiftUI
import CoreData

struct ScheduleView: View {
    @Environment(ScheduleStore.self) private var scheduleStore
    @Environment(\.managedObjectContext) private var context

    private var schedule: ScheduleResult {
        scheduleStore.cachedResult ?? .empty
    }

    @State private var profile: UserProfile?
    @State private var isEditing = false
    @State private var editingItem: ScheduledItem?
    @State private var editingBlock: String = "morning"
    @State private var notesItem: ScheduledItem?

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

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
                                    rowView(for: item, block: "morning")
                                }
                            } header: {
                                Text(sectionHeader(block: "Morning"))
                            }
                        }
                        if !schedule.afternoon.isEmpty {
                            Section {
                                ForEach(schedule.afternoon) { item in
                                    rowView(for: item, block: "afternoon")
                                }
                            } header: {
                                Text(sectionHeader(block: "Afternoon"))
                            }
                        }
                        if !schedule.evening.isEmpty {
                            Section {
                                ForEach(schedule.evening) { item in
                                    rowView(for: item, block: "evening")
                                }
                            } header: {
                                Text(sectionHeader(block: "Evening"))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Schedule")
            .safeAreaInset(edge: .bottom) {
                if schedule != .empty {
                    EditScheduleButton(isEditing: isEditing) {
                        isEditing.toggle()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
            }
        }
        .task {
            scheduleStore.currentSchedule()
            let request = UserProfile.fetchRequest()
            request.fetchLimit = 1
            profile = try? context.fetch(request).first
        }
        .sheet(item: $editingItem) { item in
            ScheduleItemEditSheet(
                item: item,
                currentBlock: editingBlock,
                profile: profile,
                scheduleStore: scheduleStore
            )
        }
        .sheet(item: $notesItem) { item in
            NotesReadSheet(item: item)
        }
    }

    // MARK: - Row Builder

    @ViewBuilder
    private func rowView(for item: ScheduledItem, block: String) -> some View {
        if isEditing {
            Button {
                editingBlock = block
                editingItem = item
            } label: {
                ScheduleItemRow(
                    item: item,
                    isEditing: true,
                    onNotesTapped: { notesItem = item }
                )
            }
            .buttonStyle(.plain)
        } else {
            ScheduleItemRow(
                item: item,
                isEditing: false,
                onNotesTapped: { notesItem = item }
            )
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

        let formatter = Self.timeFormatter
        return "\(block) \u{00B7} \(formatter.string(from: start))\u{2013}\(formatter.string(from: end))"
    }
}

// MARK: - Edit Schedule Floating Button

private struct EditScheduleButton: View {
    let isEditing: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isEditing ? "checkmark" : "pencil")
                    .font(.swHeadline)
                Text(isEditing ? "Done" : "Edit Schedule")
                    .font(.swHeadline)
                Spacer()
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(isEditing ? Color.sagePrimary : Color.aquaPrimary)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Item Row

struct ScheduleItemRow: View {
    let item: ScheduledItem
    let isEditing: Bool
    let onNotesTapped: () -> Void

    @Environment(AnalysisStore.self) private var analysisStore

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 0) {
                    Text(displayName(item.label))
                        .font(.body.weight(.medium))
                    if let customTime = item.customTime {
                        Text(" \u{00B7} " + Self.timeFormatter.string(from: customTime))
                            .font(.body.weight(.medium))
                            .foregroundStyle(.aquaPrimary)
                    }
                }
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
                if let notes = item.scheduleNotes, !notes.isEmpty {
                    Button(action: onNotesTapped) {
                        Text("Tap to see notes")
                            .font(.caption)
                            .foregroundStyle(.aquaPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }
            Spacer()
            HStack(spacing: 8) {
                badges
                if isEditing {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.textSecondary)
                }
            }
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

// MARK: - Read-Only Notes Sheet

private struct NotesReadSheet: View {
    let item: ScheduledItem
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                Text(item.scheduleNotes ?? "")
                    .font(.body)
                    .foregroundStyle(.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
            .navigationTitle(displayName(item.label))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func displayName(_ label: String) -> String {
        label
            .split(separator: "_")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
