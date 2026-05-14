import SwiftUI
import CoreData

struct HealthProfileView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.managedObjectContext) private var context

    @State private var age: Int = 30
    @State private var sex: String = "unspecified"
    @State private var weightKg: Double = 70
    @State private var wakeTime: Date = Self.defaultTime(hour: 7)
    @State private var sleepTime: Date = Self.defaultTime(hour: 23)
    @State private var breakfastTime: Date = Self.defaultTime(hour: 8)
    @State private var lunchTime: Date = Self.defaultTime(hour: 12, minute: 30)
    @State private var dinnerTime: Date = Self.defaultTime(hour: 19)
    @State private var allergiesText: String = ""
    @State private var conditionsText: String = ""

    private static let sexOptions = ["female", "male", "unspecified"]

    private var canSave: Bool {
        age > 0 && weightKg > 0 && !sex.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Personal") {
                    Stepper("Age: \(age)", value: $age, in: 1...120)
                    Picker("Sex", selection: $sex) {
                        ForEach(Self.sexOptions, id: \.self) { Text($0.capitalized).tag($0) }
                    }
                    HStack {
                        Text("Weight (kg)")
                        Spacer()
                        TextField("kg", value: $weightKg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                    }
                }

                Section("Schedule") {
                    DatePicker("Wake", selection: $wakeTime, displayedComponents: .hourAndMinute)
                    DatePicker("Sleep", selection: $sleepTime, displayedComponents: .hourAndMinute)
                    DatePicker("Breakfast", selection: $breakfastTime, displayedComponents: .hourAndMinute)
                    DatePicker("Lunch", selection: $lunchTime, displayedComponents: .hourAndMinute)
                    DatePicker("Dinner", selection: $dinnerTime, displayedComponents: .hourAndMinute)
                }

                Section {
                    TextField("Allergies (comma-separated)", text: $allergiesText, axis: .vertical)
                    TextField("Conditions (comma-separated)", text: $conditionsText, axis: .vertical)
                } header: {
                    Text("Health")
                } footer: {
                    Text("Used to personalize interaction analysis. Stored only on this device.")
                }
            }
            .navigationTitle("Your Health Profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave)
                }
            }
        }
        .interactiveDismissDisabled(true)
    }

    private func save() {
        let profile = UserProfileStore.fetchOrCreate(in: context)
        profile.age = Int16(age)
        profile.sex = sex
        profile.weightKg = weightKg
        profile.wakeTime = wakeTime
        profile.sleepTime = sleepTime
        profile.breakfastTime = breakfastTime
        profile.lunchTime = lunchTime
        profile.dinnerTime = dinnerTime
        profile.allergies = Self.parseList(allergiesText)
        profile.conditions = Self.parseList(conditionsText)
        UserProfileStore.markOnboarded(profile, in: context)
        appState.onboardingComplete = true
    }

    static func parseList(_ raw: String) -> [String] {
        raw.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    private static func defaultTime(hour: Int, minute: Int = 0) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: .now) ?? .now
    }
}
