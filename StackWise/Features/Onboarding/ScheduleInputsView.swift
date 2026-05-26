import SwiftUI
import CoreData

struct ScheduleInputsView: View {
    var onNext: () -> Void = {}

    @Environment(\.managedObjectContext) private var context
    @Environment(ScheduleStore.self) private var scheduleStore

    @State private var wakeTime: Date = Self.defaultTime(hour: 7)
    @State private var sleepTime: Date = Self.defaultTime(hour: 23)
    @State private var breakfastTime: Date = Self.defaultTime(hour: 8)
    @State private var lunchTime: Date = Self.defaultTime(hour: 12, minute: 30)
    @State private var dinnerTime: Date = Self.defaultTime(hour: 19)
    @State private var saveError: String?

    private var canSave: Bool {
        wakeTime < sleepTime
    }

    var body: some View {
        Form {
            Section("Schedule") {
                DatePicker("Wake", selection: $wakeTime, displayedComponents: .hourAndMinute)
                DatePicker("Sleep", selection: $sleepTime, displayedComponents: .hourAndMinute)
                DatePicker("Breakfast", selection: $breakfastTime, displayedComponents: .hourAndMinute)
                DatePicker("Lunch", selection: $lunchTime, displayedComponents: .hourAndMinute)
                DatePicker("Dinner", selection: $dinnerTime, displayedComponents: .hourAndMinute)
            }
            if !canSave {
                Section {
                    Text("Wake time must be earlier than sleep time.")
                        .font(.swFootnote)
                        .foregroundStyle(.criticalFG)
                }
            }
        }
        .navigationTitle("Your Schedule")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Next") {
                    do {
                        try save()
                        onNext()
                    } catch {
                        saveError = "Could not save schedule. Please try again."
                    }
                }.disabled(!canSave)
            }
        }
        .onAppear {
            let profile = UserProfileStore.fetchOrCreate(in: context)
            if let wake = profile.wakeTime           { wakeTime       = wake }
            if let sleep = profile.sleepTime         { sleepTime      = sleep }
            if let breakfast = profile.breakfastTime { breakfastTime  = breakfast }
            if let lunch = profile.lunchTime         { lunchTime      = lunch }
            if let dinner = profile.dinnerTime       { dinnerTime     = dinner }
        }
        .alert("Save Error", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    private func save() throws {
        let profile = UserProfileStore.fetchOrCreate(in: context)
        profile.wakeTime = wakeTime
        profile.sleepTime = sleepTime
        profile.breakfastTime = breakfastTime
        profile.lunchTime = lunchTime
        profile.dinnerTime = dinnerTime
        try context.save()
        scheduleStore.invalidate()
    }

    private static func defaultTime(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
    }
}
