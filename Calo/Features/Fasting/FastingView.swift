import SwiftUI
import SwiftData

struct FastingView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FastingSession.startAt, order: .reverse) private var sessions: [FastingSession]

    @State private var target = 16.0
    @State private var now = Date.now
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var active: FastingSession? { sessions.first(where: { $0.isActive }) }

    var body: some View {
        List {
            Section {
                if let active {
                    activeView(active)
                } else {
                    idleView
                }
            }
            Section("Recent fasts") {
                ForEach(sessions.filter { !$0.isActive }.prefix(10)) { s in
                    HStack {
                        Text(s.startAt, format: .dateTime.month().day().hour().minute())
                        Spacer()
                        Text(hours(s.elapsed)).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Fasting")
        .onReceive(ticker) { now = $0 }
    }

    private func activeView(_ s: FastingSession) -> some View {
        let elapsed = now.timeIntervalSince(s.startAt)
        let progress = elapsed / (s.targetHours * 3600)
        return VStack(spacing: 16) {
            ZStack {
                ProgressRing(progress: progress, tint: .indigo).frame(width: 160, height: 160)
                VStack {
                    Text(clock(elapsed)).font(.title2.monospacedDigit().bold())
                    Text("of \(Int(s.targetHours))h").font(.caption).foregroundStyle(.secondary)
                }
            }
            Button("End fast", role: .destructive) {
                s.endAt = .now; try? context.save()
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical)
    }

    private var idleView: some View {
        VStack(spacing: 16) {
            Picker("Target", selection: $target) {
                ForEach([12.0, 14, 16, 18, 20, 24], id: \.self) { Text("\(Int($0))h").tag($0) }
            }
            .pickerStyle(.segmented)
            Button("Start fasting") {
                context.insert(FastingSession(startAt: .now, targetHours: target))
                try? context.save()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.vertical)
    }

    private func clock(_ t: TimeInterval) -> String {
        let h = Int(t) / 3600, m = (Int(t) % 3600) / 60, s = Int(t) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
    private func hours(_ t: TimeInterval) -> String { String(format: "%.1f h", t / 3600) }
}
