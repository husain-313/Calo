import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var health: HealthKitService
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            List {
                Section("Tracking") {
                    NavigationLink { FastingView() } label: { Label("Fasting timer", systemImage: "timer") }
                    NavigationLink { WaterLogView() } label: { Label("Water", systemImage: "drop.fill") }
                }
                if let profile {
                    Section("Goals") {
                        NavigationLink { GoalsView(profile: profile) } label: {
                            Label("Calorie & macro goals", systemImage: "target")
                        }
                        NavigationLink { ProfileEditView(profile: profile) } label: {
                            Label("Body & activity", systemImage: "person.fill")
                        }
                    }
                }
                Section("Integrations") {
                    HStack {
                        Label("Apple Health", systemImage: "heart.fill")
                        Spacer()
                        Text(health.authorized ? "Connected" : "Not connected")
                            .foregroundStyle(.secondary)
                    }
                    if !health.authorized {
                        Button("Connect Health") { Task { await health.requestAuthorization() } }
                    }
                }
                Section {
                    Text("Food data from Open Food Facts (ODbL). Nutrition estimates are informational only.")
                        .font(.caption).foregroundStyle(.secondary)
                } header: { Text("About") } footer: { Text("Calo \(version)") }
            }
            .navigationTitle("More")
        }
    }

    private var version: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
    }
}
