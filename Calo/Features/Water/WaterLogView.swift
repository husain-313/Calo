import SwiftUI
import SwiftData

struct WaterLogView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var water: [WaterEntry]
    @Query private var profiles: [UserProfile]

    var date: Date = .now
    private let today = Calendar.current.startOfDay(for: .now)

    private var todayTotal: Double {
        water.filter { $0.date == today }.reduce(0) { $0 + $1.amountML }
    }
    private var goal: Double { profiles.first?.waterGoalML ?? 2000 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ZStack {
                    ProgressRing(progress: goal > 0 ? todayTotal / goal : 0, tint: .teal)
                        .frame(width: 160, height: 160)
                    VStack {
                        Text(Fmt.ml(todayTotal)).font(.title.bold())
                        Text("of \(Fmt.ml(goal))").font(.caption).foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 12) {
                    addButton(250, "cup.and.saucer.fill")
                    addButton(500, "waterbottle.fill")
                    addButton(1000, "drop.fill")
                }
            }
            .padding()
            .navigationTitle("Water")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } } }
        }
    }

    private func addButton(_ ml: Double, _ icon: String) -> some View {
        Button {
            context.insert(WaterEntry(date: date, amountML: ml))
            try? context.save()
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon).font(.title)
                Text(Fmt.ml(ml)).font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(.teal.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
}
