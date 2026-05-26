import SwiftUI
import CoreData

struct EditItemView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @Environment(IngredientRepository.self) private var repo
    @Environment(AnalysisStore.self) private var analysisStore
    @Environment(ScheduleStore.self) private var scheduleStore

    @ObservedObject var item: StackItem

    @State private var label: String = ""
    @State private var dosage: String = ""
    @State private var frequency: String = "daily"
    @State private var customFrequency: String = ""
    @State private var isPrescription: Bool = false
    @State private var selectedMatch: IngredientMatch?
    @State private var suggestions: [IngredientMatch] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var saveError: String?
    @State private var didLoad = false

    private static let frequencyOptions = ["daily", "twice daily", "as needed", "weekly", "Custom…"]

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
                        Text("No database match — will be saved as a custom item.")
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

                Section {
                    Button(role: .destructive) { deleteItem() } label: {
                        HStack {
                            Spacer()
                            Label("Delete Item", systemImage: "trash")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(!canSave)
                }
            }
            .onAppear(perform: loadIfNeeded)
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

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true

        label = displayName(item.labelValue)
        dosage = item.dosage ?? ""

        let storedFrequency = item.frequency ?? "daily"
        if Self.frequencyOptions.contains(storedFrequency) && storedFrequency != "Custom…" {
            frequency = storedFrequency
        } else if storedFrequency.isEmpty {
            frequency = "daily"
        } else {
            frequency = "Custom…"
            customFrequency = storedFrequency
        }

        isPrescription = item.isPrescription

        if item.isInDatabase {
            let slug = item.activeIngredientValue
            let matches = repo.search(slug)
            selectedMatch = matches.first { $0.canonicalName.lowercased() == slug.lowercased() }
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
        // Duplicate check — exclude the item being edited
        let request = StackItem.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        let existing = ((try? context.fetch(request)) ?? []).filter { $0.objectID != item.objectID }

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

        let trimmedLabel = label.trimmingCharacters(in: .whitespaces)

        if let match = selectedMatch {
            item.label = match.canonicalName
            item.activeIngredient = match.canonicalName
            item.itemType = match.itemType
            item.isInDatabase = true
            item.isPrescription = (match.itemType == "drug")
        } else {
            item.label = trimmedLabel
            item.activeIngredient = trimmedLabel
            item.itemType = isPrescription ? "drug" : "supplement"
            item.isInDatabase = false
            item.isPrescription = isPrescription
        }
        item.dosage = dosage.trimmingCharacters(in: .whitespaces)
        item.frequency = resolvedFrequency

        do {
            try context.save()
            analysisStore.invalidate()
            scheduleStore.invalidate()
            dismiss()
        } catch {
            saveError = "Could not save changes. Please try again."
        }
    }

    private func deleteItem() {
        context.delete(item)
        do {
            try context.save()
            analysisStore.invalidate()
            scheduleStore.invalidate()
            dismiss()
        } catch {
            saveError = "Could not delete item. Please try again."
        }
    }
}
