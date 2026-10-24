import SwiftUI
import SwiftData
import Charts

struct ReportsView: View {
    @Query private var entries: [DiaryEntry]
    @Query private var profiles: [UserProfile]
    @Query private var weights: [WeightEntry]

    private var profile: UserProfile? { profiles.first }
    private var currentWeight: Double {
        weights.sorted { $0.date > $1.date }.first?.weightKg ?? profile?.startWeightKg ?? 80
    }

    /// Calories per day for the last 14 days.
    private var dailyCalories: [(date: Date, kcal: Double)] {
        let cal = Calendar.current
        return (0..<14).reversed().compactMap { offset in
            guard let d = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: .now))
            else { return nil }
            let total = entries.filter { $0.date == d }.reduce(0) { $0 + $1.calories }
            return (d, total)
        }
    }

    private var avgCalories: Double {
        let logged = dailyCalories.filter { $0.kcal > 0 }
        guard !logged.isEmpty else { return 0 }
        return logged.reduce(0) { $0 + $1.kcal } / Double(logged.count)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Calories — last 14 days") {
                    Chart(dailyCalories, id: \.date) { item in
                        BarMark(x: .value("Day", item.date, unit: .day),
                                y: .value("kcal", item.kcal))
                        .foregroundStyle(.orange.gradient)
                    }
                    .frame(height: 200)
                    if let profile {
                        let goal = NutritionMath.calorieGoal(profile: profile, currentWeightKg: currentWeight)
                        LabeledContent("Daily goal", value: "\(Fmt.kcal(goal)) kcal")
                        LabeledContent("Average logged", value: "\(Fmt.kcal(avgCalories)) kcal")
                    }
                }

                if weights.count > 1 {
                    Section("Weight trend") {
                        Chart(weights.sorted { $0.date < $1.date }) { w in
                            LineMark(x: .value("Date", w.date), y: .value("kg", w.weightKg))
                                .interpolationMethod(.catmullRom)
                        }
                        .frame(height: 180)
                        let change = (weights.sorted { $0.date > $1.date }.first?.weightKg ?? 0)
                            - (profile?.startWeightKg ?? 0)
                        LabeledContent("Change since start",
                                       value: String(format: "%+.1f kg", change))
                    }
                }
            }
            .navigationTitle("Reports")
        }
    }
}
