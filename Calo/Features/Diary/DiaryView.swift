import SwiftUI
import SwiftData

struct DiaryView: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [DiaryEntry]
    @Query private var profiles: [UserProfile]
    @Query private var weights: [WeightEntry]

    @State private var day = Calendar.current.startOfDay(for: .now)
    @State private var addMeal: MealType?

    private var profile: UserProfile? { profiles.first }
    private var currentWeight: Double {
        weights.sorted { $0.date > $1.date }.first?.weightKg ?? profile?.startWeightKg ?? 80
    }
    private var dayEntries: [DiaryEntry] { entries.filter { $0.date == day } }

    private func entries(for meal: MealType) -> [DiaryEntry] {
        dayEntries.filter { $0.meal == meal }.sorted { $0.loggedAt < $1.loggedAt }
    }

    var body: some View {
        NavigationStack {
            List {
                dateHeader
                ForEach(MealType.allCases) { meal in
                    Section {
                        ForEach(entries(for: meal)) { e in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(e.foodName)
                                    Text(e.servingLabel).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(Fmt.kcal(e.calories)) kcal").foregroundStyle(.secondary)
                            }
                        }
                        .onDelete { idx in delete(meal: meal, at: idx) }

                        Button { addMeal = meal } label: {
                            Label("Add food", systemImage: "plus.circle.fill")
                        }
                    } header: {
                        HStack {
                            Label(meal.title, systemImage: meal.symbol)
                            Spacer()
                            Text("\(Fmt.kcal(entries(for: meal).reduce(0) { $0 + $1.calories })) kcal")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Diary")
            .sheet(item: $addMeal) { meal in
                FoodSearchView(meal: meal, date: day)
            }
        }
    }

    private var dateHeader: some View {
        HStack {
            Button { shift(-1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(day, format: .dateTime.weekday().month().day())
                .font(.headline)
            Spacer()
            Button { shift(1) } label: { Image(systemName: "chevron.right") }
                .disabled(day >= Calendar.current.startOfDay(for: .now))
        }
        .buttonStyle(.bordered)
        .listRowBackground(Color.clear)
    }

    private func shift(_ days: Int) {
        if let d = Calendar.current.date(byAdding: .day, value: days, to: day) {
            day = Calendar.current.startOfDay(for: d)
        }
    }

    private func delete(meal: MealType, at offsets: IndexSet) {
        let items = entries(for: meal)
        offsets.map { items[$0] }.forEach(context.delete)
        try? context.save()
    }
}
