import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var context
    @Bindable var profile: UserProfile
    @Query private var weights: [WeightEntry]

    @State private var useManual = false
    @State private var manual = 2000.0

    private var currentWeight: Double {
        weights.sorted { $0.date > $1.date }.first?.weightKg ?? profile.startWeightKg
    }
    private var computed: Double {
        NutritionMath.calorieGoal(profile: profile, currentWeightKg: currentWeight)
    }
    private var activeGoal: Double { useManual ? manual : computed }
    private var macros: (protein: Double, carbs: Double, fat: Double) {
        NutritionMath.macroGrams(calories: activeGoal, profile: profile)
    }
    private var pctSum: Double { profile.proteinPct + profile.carbsPct + profile.fatPct }

    var body: some View {
        Form {
            Section("Calorie goal") {
                Picker("Pace", selection: $profile.pace) {
                    ForEach(GoalPace.allCases) { Text($0.title).tag($0) }
                }
                .disabled(useManual)
                Toggle("Set manually", isOn: $useManual)
                if useManual {
                    Stepper(value: $manual, in: 1200...6000, step: 50) {
                        HStack { Text("Daily calories"); Spacer()
                            Text("\(Fmt.kcal(manual)) kcal").foregroundStyle(.secondary) }
                    }
                } else {
                    LabeledContent("Daily calories", value: "\(Fmt.kcal(computed)) kcal")
                }
                Toggle("Add exercise calories back", isOn: $profile.addExerciseCalories)
            }

            Section {
                macroSlider("Protein", $profile.proteinPct, .pink)
                macroSlider("Carbs", $profile.carbsPct, .blue)
                macroSlider("Fat", $profile.fatPct, .yellow)
            } header: {
                Text("Macro split")
            } footer: {
                HStack {
                    Text("Total: \(Int(pctSum * 100))%")
                        .foregroundStyle(abs(pctSum - 1) < 0.001 ? .secondary : .red)
                    Spacer()
                    Text("P \(Fmt.grams(macros.protein)) · C \(Fmt.grams(macros.carbs)) · F \(Fmt.grams(macros.fat))")
                }
            }
        }
        .navigationTitle("Goals")
        .onAppear {
            useManual = profile.manualCalorieGoal != nil
            manual = profile.manualCalorieGoal ?? computed
        }
        .onChange(of: useManual) { syncManual() }
        .onChange(of: manual) { syncManual() }
        .onDisappear { try? context.save() }
    }

    private func syncManual() {
        profile.manualCalorieGoal = useManual ? manual : nil
    }

    private func macroSlider(_ label: String, _ value: Binding<Double>, _ tint: Color) -> some View {
        VStack(alignment: .leading) {
            HStack { Text(label); Spacer(); Text("\(Int(value.wrappedValue * 100))%").foregroundStyle(.secondary) }
            Slider(value: value, in: 0...0.7, step: 0.05).tint(tint)
        }
    }
}

struct ProfileEditView: View {
    @Environment(\.modelContext) private var context
    @Bindable var profile: UserProfile

    var body: some View {
        Form {
            Section("Body") {
                Picker("Sex", selection: $profile.sex) {
                    ForEach(Sex.allCases) { Text($0.title).tag($0) }
                }
                DatePicker("Birth date", selection: $profile.birthDate, displayedComponents: .date)
                Stepper(value: $profile.heightCm, in: 120...220) {
                    HStack { Text("Height"); Spacer(); Text("\(Int(profile.heightCm)) cm").foregroundStyle(.secondary) }
                }
                Stepper(value: $profile.goalWeightKg, in: 35...250, step: 0.5) {
                    HStack { Text("Goal weight"); Spacer()
                        Text(String(format: "%.1f kg", profile.goalWeightKg)).foregroundStyle(.secondary) }
                }
            }
            Section("Activity") {
                Picker("Activity level", selection: $profile.activity) {
                    ForEach(ActivityLevel.allCases) { Text($0.title).tag($0) }
                }
            }
            Section("Units") {
                Toggle("Use metric (kg)", isOn: $profile.useMetric)
            }
        }
        .navigationTitle("Body & activity")
        .onDisappear { try? context.save() }
    }
}
