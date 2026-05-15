import SwiftUI
import CoreData

struct AddItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @Environment(IngredientRepository.self) private var repo
    @Environment(AnalysisStore.self) private var analysisStore
    @Environment(ScheduleStore.self) private var scheduleStore

    @State private var label: String = ""
    @State private var dosage: String = ""
    @State private var frequency: String = "daily"
    @State private var isPrescription: Bool = false
    @State private var selectedMatch: IngredientMatch?
    @State private var suggestions: [IngredientMatch] = []
    @State private var searchTask: Task<Void, Never>?

    private static let frequencyOptions = ["daily", "twice daily", "as needed", "weekly"]

    private var resolvedItemType: String {
        selectedMatch?.itemType ?? (isPrescription ? "drug" : "supplement")
    }

    private var canSave: Bool {
        !label.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("Name (e.g. Vitamin D3)", text: $label)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .onChange(of: label) { _, newValue in
                            if let selected = selectedMatch,
                               !newValue.localizedCaseInsensitiveContains(selected.canonicalName)
                                && selected.matchedAlias.map({ !newValue.localizedCaseInsensitiveContains($0) }) ?? true {
                                selectedMatch = nil
                            }
                            scheduleSearch(for: newValue)
                        }

                    if let match = selectedMatch {
                        HStack {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                            Text("Matched: \(match.canonicalName)")
                            Spacer()
                            Button("Clear") { selectedMatch = nil }
                                .buttonStyle(.borderless)
                        }
                    } else if !suggestions.isEmpty {
                        ForEach(suggestions) { match in
                            Button { select(match) } label: {
                                VStack(alignment: .leading) {
                                    Text(match.canonicalName).foregroundStyle(.primary)
                                    if let alias = match.matchedAlias {
                                        Text("Also known as: \(alias)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    } else if !label.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("No database match — will be added as a custom item.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Details") {
                    TextField("Dosage (e.g. 2000 IU)", text: $dosage)
                    Picker("Frequency", selection: $frequency) {
                        ForEach(Self.frequencyOptions, id: \.self) { Text($0).tag($0) }
                    }
                    Toggle("Prescription", isOn: $isPrescription)
                        .disabled(selectedMatch != nil)
                }
            }
            .navigationTitle("Add to Stack")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add", action: save).disabled(!canSave)
                }
            }
        }
    }

    private func scheduleSearch(for query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            suggestions = []
            return
        }
        searchTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            let results = repo.search(trimmed)
            guard !Task.isCancelled else { return }
            suggestions = results
        }
    }

    private func select(_ match: IngredientMatch) {
        selectedMatch = match
        label = match.canonicalName
        isPrescription = (match.itemType == "drug")
        suggestions = []
    }

    private func save() {
        let input = StackItemFactory.Input(
            label: label,
            dosage: dosage,
            frequency: frequency,
            isPrescription: isPrescription,
            match: selectedMatch
        )
        do {
            _ = try StackItemFactory.create(input, in: context, onSaved: {
                analysisStore.invalidate()
                scheduleStore.invalidate()
            })
            dismiss()
        } catch {
            assertionFailure("Failed to save StackItem: \(error)")
        }
    }
}
