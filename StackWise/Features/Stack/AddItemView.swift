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
    @State private var customFrequency: String = ""
    @State private var isPrescription: Bool = false
    @State private var selectedMatch: IngredientMatch?
    @State private var suggestions: [IngredientMatch] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var saveError: String?

    private static let frequencyOptions = ["daily", "twice daily", "as needed", "weekly", "Custom…"]

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
                            if let selected = selectedMatch {
                                let canonical = selected.canonicalName
                                let display = displayName(canonical)
                                let containsCanonical = newValue.localizedCaseInsensitiveContains(canonical)
                                let containsDisplay = newValue.localizedCaseInsensitiveContains(display)
                                let containsAlias = selected.matchedAlias
                                    .map { newValue.localizedCaseInsensitiveContains($0) } ?? false
                                if !containsCanonical && !containsDisplay && !containsAlias {
                                    selectedMatch = nil
                                }
                            }
                            scheduleSearch(for: newValue)
                        }

                    if let match = selectedMatch {
                        HStack {
                            Image(systemName: "checkmark.seal.fill").foregroundStyle(.positiveFG)
                            Text("Matched: \(displayName(match.canonicalName))")
                            Spacer()
                            Button("Clear") { selectedMatch = nil }
                                .buttonStyle(.borderless)
                        }
                    } else if !suggestions.isEmpty {
                        ForEach(suggestions) { match in
                            Button { select(match) } label: {
                                VStack(alignment: .leading) {
                                    Text(displayName(match.canonicalName)).foregroundStyle(.textPrimary)
                                    if let alias = match.matchedAlias {
                                        Text("Also known as: \(alias)")
                                            .font(.caption)
                                            .foregroundStyle(.textSecondary)
                                    }
                                }
                            }
                        }
                    } else if !label.trimmingCharacters(in: .whitespaces).isEmpty {
                        Text("No database match — will be added as a custom item.")
                            .font(.caption)
                            .foregroundStyle(.textSecondary)
                    }
                }

                Section("Details") {
                    TextField("Dosage (e.g. 2000 IU)", text: $dosage)
                    Picker("Frequency", selection: $frequency) {
                        ForEach(Self.frequencyOptions, id: \.self) { Text($0).tag($0) }
                    }
                    if frequency == "Custom…" {
                        TextField("Custom frequency (e.g. every 8 hours)", text: $customFrequency)
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
        .alert("Error", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK") { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    private func scheduleSearch(for query: String) {
        searchTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else {
            suggestions = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: 200_000_000)
            guard !Task.isCancelled else { return }
            let results = repo.search(trimmed)
            guard !Task.isCancelled else { return }
            await MainActor.run { suggestions = results }
        }
    }

    private func select(_ match: IngredientMatch) {
        selectedMatch = match
        label = displayName(match.canonicalName)
        isPrescription = (match.itemType == "drug")
        suggestions = []
    }

    private func save() {
        // Duplicate check against existing active StackItems
        let request = StackItem.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        let existing = (try? context.fetch(request)) ?? []

        if let match = selectedMatch {
            let slug = match.canonicalName.lowercased()
            if existing.contains(where: { $0.activeIngredientValue.lowercased() == slug }) {
                saveError = "You've already added \(displayName(match.canonicalName)) to your stack."
                return
            }
        } else {
            let trimmed = label.trimmingCharacters(in: .whitespaces)
            let key = trimmed.lowercased()
            if existing.contains(where: { $0.labelValue.trimmingCharacters(in: .whitespaces).lowercased() == key }) {
                saveError = "You've already added \(trimmed) to your stack."
                return
            }
        }

        let resolvedFrequency = (frequency == "Custom…")
            ? customFrequency.trimmingCharacters(in: .whitespaces)
            : frequency

        let input = StackItemFactory.Input(
            label: label,
            dosage: dosage,
            frequency: resolvedFrequency,
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
            saveError = "Could not save item. Please try again."
        }
    }
}
