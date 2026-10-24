import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var health: HealthKitService
    @Query private var profiles: [UserProfile]
    @Query private var weights: [WeightEntry]
    @Query private var entries: [DiaryEntry]
    @Query private var exercises: [ExerciseEntry]
    @Query private var water: [WaterEntry]

    private var profile: UserProfile? { profiles.first }
    private let today = Calendar.current.startOfDay(for: .now)

    private var currentWeight: Double {
        weights.sorted { $0.date > $1.date }.first?.weightKg ?? profile?.startWeightKg ?? 80
    }

    private var todayEntries: [DiaryEntry] { entries.filter { $0.date == today } }
    private var todayTotals: DayTotals {
        var t = DayTotals()
        todayEntries.forEach { t.add($0) }
        t.exerciseCalories = exercises.filter { $0.date == today }.reduce(0) { $0 + $1.calories }
        t.waterML = water.filter { $0.date == today }.reduce(0) { $0 + $1.amountML }
        return t
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if let profile {
                    let totals = todayTotals
                    let goal = NutritionMath.calorieGoal(profile: profile, currentWeightKg: currentWeight)
                    let exerciseBonus = profile.addExerciseCalories ? totals.exerciseCalories : 0
                    let budget = goal + exerciseBonus
                    let remaining = budget - totals.calories
                    let macros = NutritionMath.macroGrams(calories: goal, profile: profile)

                    VStack(spacing: 20) {
                        budgetCard(remaining: remaining, budget: budget,
                                   eaten: totals.calories, exercise: exerciseBonus, goal: goal)
                        macroCard(totals: totals, macros: macros)
                        quickStats(totals: totals, profile: profile)
                        QuickAddBar()
                    }
                    .padding()
                } else {
                    ProgressView()
                }
            }
            .navigationTitle(Text(today, format: .dateTime.weekday(.wide).month().day()))
            .background(Color(.systemGroupedBackground))
            .task { await health.refreshToday() }
        }
    }

    private func budgetCard(remaining: Double, budget: Double, eaten: Double,
                            exercise: Double, goal: Double) -> some View {
        VStack(spacing: 16) {
            ZStack {
                ProgressRing(progress: budget > 0 ? eaten / budget : 0,
                             tint: remaining >= 0 ? .green : .red)
                    .frame(width: 180, height: 180)
                VStack(spacing: 2) {
                    Text(Fmt.kcal(abs(remaining)))
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    Text(remaining >= 0 ? "kcal left" : "kcal over")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
            }
            HStack {
                statPill("Goal", Fmt.kcal(goal), .blue)
                statPill("Food", Fmt.kcal(eaten), .orange)
                statPill("Exercise", Fmt.kcal(exercise), .green)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private func macroCard(totals: DayTotals,
                           macros: (protein: Double, carbs: Double, fat: Double)) -> some View {
        HStack {
            MacroBar(label: "Protein", value: totals.protein, goal: macros.protein, tint: .pink)
            MacroBar(label: "Carbs", value: totals.carbs, goal: macros.carbs, tint: .blue)
            MacroBar(label: "Fat", value: totals.fat, goal: macros.fat, tint: .yellow)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private func quickStats(totals: DayTotals, profile: UserProfile) -> some View {
        HStack {
            statPill("Steps", "\(Int(health.stepsToday))", .purple)
            statPill("Water", Fmt.ml(totals.waterML), .teal)
            statPill("Fiber", Fmt.grams(totals.fiber), .brown)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private func statPill(_ label: String, _ value: String, _ tint: Color) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline).foregroundStyle(tint)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

/// Row of shortcuts to the main logging actions.
struct QuickAddBar: View {
    @State private var showSearch = false
    @State private var showBarcode = false
    @State private var showExercise = false
    @State private var showWater = false

    var body: some View {
        HStack(spacing: 12) {
            button("Food", "magnifyingglass") { showSearch = true }
            button("Scan", "barcode.viewfinder") { showBarcode = true }
            button("Exercise", "figure.run") { showExercise = true }
            button("Water", "drop.fill") { showWater = true }
        }
        .sheet(isPresented: $showSearch) { FoodSearchView(meal: .snacks) }
        .sheet(isPresented: $showBarcode) { BarcodeScanView(meal: .snacks) }
        .sheet(isPresented: $showExercise) { ExerciseLogView() }
        .sheet(isPresented: $showWater) { WaterLogView() }
    }

    private func button(_ title: String, _ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon).font(.title2)
                Text(title).font(.caption2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(.background, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
