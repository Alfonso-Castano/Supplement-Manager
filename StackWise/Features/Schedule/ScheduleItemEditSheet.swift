import SwiftUI

struct ScheduleItemEditSheet: View {
    let item: ScheduledItem
    let currentBlock: String
    let profile: UserProfile?
    let scheduleStore: ScheduleStore

    @Environment(\.dismiss) private var dismiss

    @State private var useCustomTime: Bool
    @State private var customTime: Date
    @State private var selectedBlock: String
    @State private var notes: String

    init(item: ScheduledItem, currentBlock: String, profile: UserProfile?, scheduleStore: ScheduleStore) {
        self.item = item
        self.currentBlock = currentBlock
        self.profile = profile
        self.scheduleStore = scheduleStore
        _useCustomTime = State(initialValue: item.customTime != nil)
        _customTime = State(initialValue: item.customTime ?? item.suggestedTime)
        _selectedBlock = State(initialValue: currentBlock)
        _notes = State(initialValue: item.scheduleNotes ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Set custom time", isOn: $useCustomTime)
                        .tint(.aquaPrimary)
                    if useCustomTime {
                        DatePicker(
                            "Time",
                            selection: $customTime,
                            displayedComponents: .hourAndMinute
                        )
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .onChange(of: customTime) { _, newTime in
                            selectedBlock = inferBlock(from: newTime)
                        }
                    }
                } header: {
                    Text("Custom Time")
                }

                Section {
                    Picker("Block", selection: $selectedBlock) {
                        Text("Morning").tag("morning")
                        Text("Afternoon").tag("afternoon")
                        Text("Evening").tag("evening")
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Block")
                } footer: {
                    Text(useCustomTime
                         ? "Block is inferred from your custom time. You can still override it."
                         : "Manually pin this item to a specific block.")
                    .font(.caption)
                }

                Section {
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Add notes...")
                                .foregroundStyle(.textSecondary)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                    }
                } header: {
                    Text("Notes")
                }

                if item.customTime != nil || !(item.scheduleNotes ?? "").isEmpty {
                    Section {
                        Button(role: .destructive) {
                            scheduleStore.saveOverride(
                                for: item.id,
                                pinnedBlock: nil,
                                customTime: nil,
                                notes: nil
                            )
                            dismiss()
                        } label: {
                            Text("Clear All Overrides")
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                    } footer: {
                        Text("Returns this item to its engine-computed position and removes notes.")
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(displayName(item.label))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        scheduleStore.saveOverride(
                            for: item.id,
                            pinnedBlock: selectedBlock,
                            customTime: useCustomTime ? customTime : nil,
                            notes: notes.isEmpty ? nil : notes
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Helpers

    private func inferBlock(from time: Date) -> String {
        let cal = Calendar.current
        let now = Date()
        let lunchTime = profile?.lunchTime ?? cal.date(bySettingHour: 12, minute: 0, second: 0, of: now)!
        let dinnerTime = profile?.dinnerTime ?? cal.date(bySettingHour: 18, minute: 0, second: 0, of: now)!

        let timeMinutes = cal.component(.hour, from: time) * 60 + cal.component(.minute, from: time)
        let lunchMinutes = cal.component(.hour, from: lunchTime) * 60 + cal.component(.minute, from: lunchTime)
        let dinnerMinutes = cal.component(.hour, from: dinnerTime) * 60 + cal.component(.minute, from: dinnerTime)

        if timeMinutes < lunchMinutes { return "morning" }
        if timeMinutes < dinnerMinutes { return "afternoon" }
        return "evening"
    }

    private func displayName(_ label: String) -> String {
        label
            .split(separator: "_")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}
