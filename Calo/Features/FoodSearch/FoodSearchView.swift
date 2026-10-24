import SwiftUI
import SwiftData

struct FoodSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query(sort: \FoodItem.lastUsedAt, order: .reverse) private var recents: [FoodItem]

    var meal: MealType
    var date: Date = .now

    @State private var query = ""
    @State private var results: [FoodItem] = []
    @State private var searching = false
    @State private var error: String?
    @State private var selected: FoodItem?

    private let service = OpenFoodFactsService()

    var body: some View {
        NavigationStack {
            List {
                if query.isEmpty {
                    Section("Recent & custom") {
                        ForEach(recents.prefix(30)) { row($0) }
                    }
                } else {
                    if searching { HStack { ProgressView(); Text("Searching…") } }
                    if let error { Text(error).foregroundStyle(.red) }
                    Section("Results") {
                        ForEach(results) { row($0) }
                    }
                }
            }
            .searchable(text: $query, prompt: "Search foods")
            .onSubmit(of: .search) { Task { await runSearch() } }
            .navigationTitle("Add to \(meal.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .primaryAction) {
                    NavigationLink("Custom") { CustomFoodView(meal: meal, date: date) { dismiss() } }
                }
            }
            .sheet(item: $selected) { food in
                LogFoodSheet(food: food, meal: meal, date: date) { dismiss() }
            }
        }
    }

    private func row(_ food: FoodItem) -> some View {
        Button { selected = food } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name).foregroundStyle(.primary)
                HStack(spacing: 6) {
                    if let b = food.brand, !b.isEmpty {
                        Text(b).font(.caption).foregroundStyle(.secondary)
                    }
                    Text("\(Fmt.kcal(food.caloriesPer100)) kcal / 100\(food.baseUnit)")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func runSearch() async {
        guard query.count >= 2 else { return }
        searching = true; error = nil
        defer { searching = false }
        do {
            results = try await service.search(query)
            if results.isEmpty { error = "No results. Try a different term or add a custom food." }
        } catch {
            self.error = "Search failed. Check your connection."
        }
    }
}
