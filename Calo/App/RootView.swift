import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context
    @Query private var profiles: [UserProfile]

    var body: some View {
        Group {
            if profiles.isEmpty {
                OnboardingView()
            } else {
                MainTabView()
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject private var health: HealthKitService

    var body: some View {
        TabView {
            DashboardView()
                .tabItem { Label("Today", systemImage: "flame.fill") }
            DiaryView()
                .tabItem { Label("Diary", systemImage: "book.closed.fill") }
            WeightView()
                .tabItem { Label("Weight", systemImage: "scalemass.fill") }
            ReportsView()
                .tabItem { Label("Reports", systemImage: "chart.xyaxis.line") }
            SettingsView()
                .tabItem { Label("More", systemImage: "ellipsis.circle.fill") }
        }
        .task { await health.requestAuthorization() }
    }
}
