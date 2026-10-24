import SwiftUI
import SwiftData
import Charts

struct WeightView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var health: HealthKitService
    @Query(sort: \WeightEntry.date, order: .reverse) private var weights: [WeightEntry]
    @Query private var profiles: [UserProfile]

    @State private var showAdd = false

    private var profile: UserProfile? { profiles.first }
    private var metric: Bool { profile?.useMetric ?? true }

    var body: some View {
        NavigationStack {
            List {
                if !weights.isEmpty {
                    Section {
                        chart
                            .frame(height: 220)
                            .listRowInsets(.init(top: 12, leading: 12, bottom: 12, trailing: 12))
                    }
                    if let profile {
                        Section {
                            summaryRow("Current", weights.first?.weightKg ?? profile.startWeightKg)
                            summaryRow("Start", profile.startWeightKg)
                            summaryRow("Goal", profile.goalWeightKg)
                        }
                    }
                }
                Section("History") {
                    ForEach(weights) { w in
                        HStack {
                            Text(w.date, format: .dateTime.year().month().day())
                            Spacer()
                            Text(Fmt.weight(w.weightKg, metric: metric)).foregroundStyle(.secondary)
                        }
                    }
                    .onDelete { $0.map { weights[$0] }.forEach(context.delete); try? context.save() }
                }
            }
            .navigationTitle("Weight")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showAdd) { AddWeightView() }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(weights.reversed()) { w in
                LineMark(x: .value("Date", w.date), y: .value("Weight", w.weightKg))
                    .interpolationMethod(.catmullRom)
                PointMark(x: .value("Date", w.date), y: .value("Weight", w.weightKg))
            }
            if let goal = profile?.goalWeightKg {
                RuleMark(y: .value("Goal", goal))
                    .foregroundStyle(.green)
                    .lineStyle(.init(lineWidth: 1, dash: [5]))
            }
        }
    }

    private func summaryRow(_ label: String, _ kg: Double) -> some View {
        HStack { Text(label); Spacer(); Text(Fmt.weight(kg, metric: metric)).foregroundStyle(.secondary) }
    }
}

struct AddWeightView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var health: HealthKitService
    @Query private var profiles: [UserProfile]

    @State private var weightKg = 80.0
    @State private var date = Date.now

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                Stepper(value: $weightKg, in: 35...300, step: 0.1) {
                    HStack { Text("Weight"); Spacer()
                        Text(String(format: "%.1f kg", weightKg)).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("Log weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        context.insert(WeightEntry(date: date, weightKg: weightKg))
                        try? context.save()
                        Task { await health.saveWeight(kg: weightKg, date: date) }
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let last = profiles.first?.startWeightKg { weightKg = last }
            }
        }
    }
}
