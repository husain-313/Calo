import SwiftUI
import SwiftData

@main
struct CaloApp: App {
    let container: ModelContainer
    @StateObject private var health = HealthKitService()

    init() {
        let schema = Schema([
            FoodItem.self, DiaryEntry.self, UserProfile.self,
            WeightEntry.self, ExerciseEntry.self, WaterEntry.self, FastingSession.self
        ])
        do {
            container = try ModelContainer(for: schema)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(health)
                .modelContainer(container)
        }
    }
}
