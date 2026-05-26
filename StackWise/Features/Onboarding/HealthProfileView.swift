import SwiftUI
import CoreData

struct HealthProfileView: View {
    var onNext: () -> Void = {}
    @Environment(\.managedObjectContext) private var context

    @State private var age: Int = 30
    @State private var sex: String = "unspecified"
    @State private var weightKg: Double = 70
    @State private var allergiesText: String = ""
    @State private var conditionsText: String = ""

    private static let sexOptions = ["female", "male", "unspecified"]

    private var canSave: Bool {
        age > 0 && weightKg > 0 && !sex.isEmpty
    }

    var body: some View {
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
                Button("Next") {
                    save()
                    onNext()
                }.disabled(!canSave)
            }
        }
    }

    private func save() {
        let profile = UserProfileStore.fetchOrCreate(in: context)
        profile.age = Int16(age)
        profile.sex = sex
        profile.weightKg = weightKg
        profile.allergies = Self.parseList(allergiesText)
        profile.conditions = Self.parseList(conditionsText)
        do {
            try context.save()
        } catch {
            assertionFailure("HealthProfileView save failed: \(error)")
        }
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
