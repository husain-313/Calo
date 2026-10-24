import SwiftUI
import SwiftData

/// Simple MET-based exercise calorie estimate + manual entry.
struct ExerciseLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var weights: [WeightEntry]
    @Query private var profiles: [UserProfile]

    var date: Date = .now

    @State private var selected = ExerciseType.all[0]
    @State private var minutes = 30.0

    private var weightKg: Double {
        weights.sorted { $0.date > $1.date }.first?.weightKg ?? profiles.first?.startWeightKg ?? 75
    }
    // kcal = MET * 3.5 * kg / 200 * minutes
    private var kcal: Double { selected.met * 3.5 * weightKg / 200 * minutes }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Activity", selection: $selected) {
                    ForEach(ExerciseType.all) { Text($0.name).tag($0) }
                }
                Stepper(value: $minutes, in: 5...300, step: 5) {
                    HStack { Text("Duration"); Spacer(); Text("\(Int(minutes)) min").foregroundStyle(.secondary) }
                }
                HStack { Text("Calories burned"); Spacer()
                    Text("\(Fmt.kcal(kcal)) kcal").foregroundStyle(.secondary) }
            }
            .navigationTitle("Log exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        context.insert(ExerciseEntry(date: date, name: selected.name,
                                                      minutes: minutes, calories: kcal))
                        try? context.save()
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ExerciseType: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let met: Double

    static let all: [ExerciseType] = [
        .init(name: "Walking (3 mph)", met: 3.5),
        .init(name: "Brisk walk (4 mph)", met: 5.0),
        .init(name: "Running (6 mph)", met: 9.8),
        .init(name: "Cycling (moderate)", met: 7.5),
        .init(name: "Swimming", met: 8.0),
        .init(name: "Elliptical", met: 5.0),
        .init(name: "Weight training", met: 5.0),
        .init(name: "HIIT", met: 8.0),
        .init(name: "Yoga", met: 2.5),
        .init(name: "Soccer", met: 7.0),
        .init(name: "Basketball", met: 6.5),
        .init(name: "Rowing", met: 7.0)
    ]
}
