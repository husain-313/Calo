import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

/// Thin wrapper over HealthKit for steps, active energy, weight and workouts.
/// Compiles to a no-op on platforms without HealthKit so the rest of the app
/// stays buildable.
@MainActor
final class HealthKitService: ObservableObject {

    @Published var authorized = false
    @Published var stepsToday: Double = 0
    @Published var activeEnergyToday: Double = 0

    #if canImport(HealthKit)
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async {
        guard isAvailable else { return }
        let read: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.bodyMass)
        ]
        let share: Set<HKSampleType> = [
            HKQuantityType(.bodyMass),
            HKQuantityType(.dietaryEnergyConsumed)
        ]
        do {
            try await store.requestAuthorization(toShare: share, read: read)
            authorized = true
            await refreshToday()
        } catch {
            authorized = false
        }
    }

    func refreshToday() async {
        stepsToday = await sumToday(.stepCount, unit: .count())
        activeEnergyToday = await sumToday(.activeEnergyBurned, unit: .kilocalorie())
    }

    private func sumToday(_ id: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        let type = HKQuantityType(id)
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        return await withCheckedContinuation { cont in
            let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { _, stats, _ in
                cont.resume(returning: stats?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(q)
        }
    }

    func saveWeight(kg: Double, date: Date = .now) async {
        guard authorized else { return }
        let q = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: kg)
        let sample = HKQuantitySample(type: HKQuantityType(.bodyMass), quantity: q, start: date, end: date)
        try? await store.save(sample)
    }
    #else
    var isAvailable: Bool { false }
    func requestAuthorization() async {}
    func refreshToday() async {}
    func saveWeight(kg: Double, date: Date = .now) async {}
    #endif
}
