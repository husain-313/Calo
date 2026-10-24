import SwiftUI

enum Fmt {
    static func kcal(_ v: Double) -> String { "\(Int(v.rounded()))" }
    static func grams(_ v: Double) -> String { "\(Int(v.rounded()))g" }
    static func weight(_ kg: Double, metric: Bool) -> String {
        metric ? String(format: "%.1f kg", kg) : String(format: "%.1f lb", kg * 2.20462)
    }
    static func ml(_ v: Double) -> String { "\(Int(v.rounded())) ml" }
}

/// A circular progress ring used on the dashboard.
struct ProgressRing: View {
    var progress: Double          // 0...1+ (can exceed for over-budget)
    var lineWidth: CGFloat = 14
    var tint: Color = .accentColor

    var body: some View {
        ZStack {
            Circle()
                .stroke(tint.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(progress, 1))
                .stroke(tint, style: .init(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
        }
    }
}

struct MacroBar: View {
    var label: String
    var value: Double
    var goal: Double
    var tint: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(Fmt.grams(value)).font(.subheadline.weight(.semibold))
            ProgressView(value: min(value / max(goal, 1), 1)).tint(tint)
            Text("/ \(Fmt.grams(goal))").font(.caption2).foregroundStyle(.secondary)
        }
    }
}
