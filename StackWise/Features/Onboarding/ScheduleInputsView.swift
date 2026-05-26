import SwiftUI
import CoreData

struct ScheduleInputsView: View {
    var onNext: () -> Void = {}

    @Environment(\.managedObjectContext) private var context

    @State private var wakeTime: Date = Self.defaultTime(hour: 7)
    @State private var sleepTime: Date = Self.defaultTime(hour: 23)
    @State private var breakfastTime: Date = Self.defaultTime(hour: 8)
    @State private var lunchTime: Date = Self.defaultTime(hour: 12, minute: 30)
    @State private var dinnerTime: Date = Self.defaultTime(hour: 19)

    var body: some View {
        Form {
            Section("Schedule") {
                DatePicker("Wake", selection: $wakeTime, displayedComponents: .hourAndMinute)
                DatePicker("Sleep", selection: $sleepTime, displayedComponents: .hourAndMinute)
                DatePicker("Breakfast", selection: $breakfastTime, displayedComponents: .hourAndMinute)
                DatePicker("Lunch", selection: $lunchTime, displayedComponents: .hourAndMinute)
                DatePicker("Dinner", selection: $dinnerTime, displayedComponents: .hourAndMinute)
            }
        }
        .navigationTitle("Your Schedule")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Next") {
                    save()
                    onNext()
                }
            }
        }
        .onAppear {
            let profile = UserProfileStore.fetchOrCreate(in: context)
            if let wake = profile.wakeTime       { wakeTime       = wake }
            if let sleep = profile.sleepTime     { sleepTime      = sleep }
            if let breakfast = profile.breakfastTime { breakfastTime = breakfast }
            if let lunch = profile.lunchTime     { lunchTime      = lunch }
            if let dinner = profile.dinnerTime   { dinnerTime     = dinner }
        }
    }

    private func save() {
        let profile = UserProfileStore.fetchOrCreate(in: context)
        profile.wakeTime = wakeTime
        profile.sleepTime = sleepTime
        profile.breakfastTime = breakfastTime
        profile.lunchTime = lunchTime
        profile.dinnerTime = dinnerTime
        try? context.save()
    }

    private static func defaultTime(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
    }
}
