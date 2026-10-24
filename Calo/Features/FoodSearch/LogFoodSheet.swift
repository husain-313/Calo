import SwiftUI
import SwiftData

/// Pick a serving/amount for a food and write a DiaryEntry.
struct LogFoodSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let food: FoodItem
    @State var meal: MealType
    var date: Date = .now
    var onLogged: () -> Void = {}

    @State private var serving: ServingSize
    @State private var quantity = 1.0

    init(food: FoodItem, meal: MealType, date: Date = .now, onLogged: @escaping () -> Void = {}) {
        self.food = food
        self._meal = State(initialValue: meal)
        self.date = date
        self.onLogged = onLogged
        self._serving = State(initialValue: food.servings.first ?? .hundred)
    }

    private var amountInBase: Double { serving.amountInBase * quantity }
    private var factor: Double { amountInBase / 100 }

    private var kcal: Double { food.caloriesPer100 * factor }
    private var protein: Double { food.proteinPer100 * factor }
    private var carbs: Double { food.carbsPer100 * factor }
    private var fat: Double { food.fatPer100 * factor }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(food.name).font(.headline)
                        if let b = food.brand, !b.isEmpty {
                            Text(b).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Section("Amount") {
                    Picker("Meal", selection: $meal) {
                        ForEach(MealType.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("Serving", selection: $serving) {
                        ForEach(food.servings) { Text($0.label).tag($0) }
                    }
                    Stepper(value: $quantity, in: 0.25...20, step: 0.25) {
                        HStack { Text("Quantity"); Spacer()
                            Text(quantity.formatted(.number.precision(.fractionLength(0...2))))
                                .foregroundStyle(.secondary) }
                    }
                }
                Section("Nutrition for this amount") {
                    nutriRow("Calories", "\(Fmt.kcal(kcal)) kcal")
                    nutriRow("Protein", Fmt.grams(protein))
                    nutriRow("Carbs", Fmt.grams(carbs))
                    nutriRow("Fat", Fmt.grams(fat))
                }
            }
            .navigationTitle("Log food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Add", action: log) }
            }
        }
    }

    private func nutriRow(_ l: String, _ v: String) -> some View {
        HStack { Text(l); Spacer(); Text(v).foregroundStyle(.secondary) }
    }

    private func log() {
        // Persist the food in the library for reuse, and record the entry.
        if food.modelContext == nil { context.insert(food) }
        food.lastUsedAt = .now

        let entry = DiaryEntry(
            date: date, meal: meal, foodName: food.name, brand: food.brand,
            amountInBase: amountInBase, servingLabel: "\(quantity.formatted()) × \(serving.label)",
            calories: kcal, protein: protein, carbs: carbs, fat: fat,
            fiber: food.fiberPer100 * factor, sugar: food.sugarPer100 * factor,
            sodium: food.sodiumPer100 * factor, foodID: food.id
        )
        context.insert(entry)
        try? context.save()
        onLogged()
        dismiss()
    }
}

/// Create a custom food (or quick-add calories).
struct CustomFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    var meal: MealType
    var date: Date = .now
    var onLogged: () -> Void = {}

    @State private var name = ""
    @State private var brand = ""
    @State private var kcal = 0.0
    @State private var protein = 0.0
    @State private var carbs = 0.0
    @State private var fat = 0.0
    @State private var servingGrams = 100.0

    var body: some View {
        Form {
            Section("Food") {
                TextField("Name", text: $name)
                TextField("Brand (optional)", text: $brand)
            }
            Section("Per serving") {
                numberRow("Serving size (g)", $servingGrams)
                numberRow("Calories", $kcal)
                numberRow("Protein (g)", $protein)
                numberRow("Carbs (g)", $carbs)
                numberRow("Fat (g)", $fat)
            }
            Button("Save & log", action: save)
                .disabled(name.isEmpty)
        }
        .navigationTitle("Custom food")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func numberRow(_ label: String, _ value: Binding<Double>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", value: value, format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 90)
        }
    }

    private func save() {
        let per100 = servingGrams > 0 ? 100 / servingGrams : 1
        let food = FoodItem(
            name: name, brand: brand.isEmpty ? nil : brand, source: "custom",
            caloriesPer100: kcal * per100, proteinPer100: protein * per100,
            carbsPer100: carbs * per100, fatPer100: fat * per100,
            servings: [ServingSize(label: "1 serving (\(Int(servingGrams)) g)", amountInBase: servingGrams), .hundred],
            lastUsedAt: .now
        )
        context.insert(food)
        let entry = DiaryEntry(
            date: date, meal: meal, foodName: name, brand: brand.isEmpty ? nil : brand,
            amountInBase: servingGrams, servingLabel: "1 serving",
            calories: kcal, protein: protein, carbs: carbs, fat: fat, foodID: food.id
        )
        context.insert(entry)
        try? context.save()
        onLogged()
        dismiss()
    }
}
