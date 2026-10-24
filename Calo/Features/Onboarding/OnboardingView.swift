import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var context

    @State private var name = ""
    @State private var sex: Sex = .male
    @State private var age = 30.0
    @State private var heightCm = 175.0
    @State private var weightKg = 80.0
    @State private var goalWeightKg = 72.0
    @State private var activity: ActivityLevel = .light
    @State private var pace: GoalPace = .lose050

    var body: some View {
        NavigationStack {
            Form {
                Section("About you") {
                    TextField("Name", text: $name)
                    Picker("Sex", selection: $sex) {
                        ForEach(Sex.allCases) { Text($0.title).tag($0) }
                    }
                    stepperRow("Age", value: $age, range: 13...100, unit: "yr")
                    stepperRow("Height", value: $heightCm, range: 120...220, unit: "cm")
                }
                Section("Weight") {
                    stepperRow("Current", value: $weightKg, range: 35...250, unit: "kg", step: 0.5)
                    stepperRow("Goal", value: $goalWeightKg, range: 35...250, unit: "kg", step: 0.5)
                }
                Section("Activity & pace") {
                    Picker("Activity", selection: $activity) {
                        ForEach(ActivityLevel.allCases) { Text($0.title).tag($0) }
                    }
                    Picker("Goal", selection: $pace) {
                        ForEach(GoalPace.allCases) { Text($0.title).tag($0) }
                    }
                }
                Section {
                    Button("Start tracking", action: save)
                        .frame(maxWidth: .infinity)
                        .fontWeight(.semibold)
                }
            }
            .navigationTitle("Welcome to Calo")
        }
    }

    private func stepperRow(_ title: String, value: Binding<Double>,
                            range: ClosedRange<Double>, unit: String, step: Double = 1) -> some View {
        Stepper(value: value, in: range, step: step) {
            HStack {
                Text(title)
                Spacer()
                Text("\(value.wrappedValue.formatted(.number.precision(.fractionLength(step < 1 ? 1 : 0)))) \(unit)")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func save() {
        let birth = Calendar.current.date(byAdding: .year, value: -Int(age), to: .now) ?? .now
        let profile = UserProfile(
            name: name.isEmpty ? "You" : name,
            sex: sex, birthDate: birth, heightCm: heightCm,
            startWeightKg: weightKg, goalWeightKg: goalWeightKg,
            activity: activity, pace: pace
        )
        context.insert(profile)
        context.insert(WeightEntry(weightKg: weightKg))
        try? context.save()
    }
}
