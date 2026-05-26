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
    @State private var saveError: String?

    private static let sexOptions = ["female", "male", "unspecified"]
    private static let maxFreeTextLength = 500
    private static let maxListEntries = 20

    private var canSave: Bool {
        age > 0 && age < 120 && weightKg > 0 && weightKg < 500 && !sex.isEmpty
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
                    .onChange(of: allergiesText) { _, new in
                        if new.count > Self.maxFreeTextLength {
                            allergiesText = String(new.prefix(Self.maxFreeTextLength))
                        }
                    }
                TextField("Conditions (comma-separated)", text: $conditionsText, axis: .vertical)
                    .onChange(of: conditionsText) { _, new in
                        if new.count > Self.maxFreeTextLength {
                            conditionsText = String(new.prefix(Self.maxFreeTextLength))
                        }
                    }
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
                    do {
                        try save()
                        onNext()
                    } catch {
                        saveError = "Could not save profile. Please try again."
                    }
                }.disabled(!canSave)
            }
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
        profile.age = Int16(age)
        profile.sex = sex
        profile.weightKg = weightKg
        let allergies = Array(Self.parseList(String(allergiesText.prefix(Self.maxFreeTextLength))).prefix(Self.maxListEntries))
        let conditions = Array(Self.parseList(String(conditionsText.prefix(Self.maxFreeTextLength))).prefix(Self.maxListEntries))
        profile.allergies = allergies.isEmpty ? nil : allergies
        profile.conditions = conditions.isEmpty ? nil : conditions
        try context.save()
    }

    static func parseList(_ raw: String) -> [String] {
        raw.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
