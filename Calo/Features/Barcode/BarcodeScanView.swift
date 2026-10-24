import SwiftUI
import SwiftData

/// Full scan flow: camera -> Open Food Facts lookup -> log sheet.
struct BarcodeScanView: View {
    @Environment(\.dismiss) private var dismiss
    var meal: MealType
    var date: Date = .now

    @State private var state: ScanState = .scanning
    @State private var found: FoodItem?

    private let service = OpenFoodFactsService()

    enum ScanState: Equatable { case scanning, looking, failed(String) }

    var body: some View {
        NavigationStack {
            ZStack {
                BarcodeCamera { code in
                    guard state == .scanning else { return }
                    Task { await lookup(code) }
                }
                .ignoresSafeArea()

                VStack {
                    Spacer()
                    overlay
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .padding()
                }
            }
            .navigationTitle("Scan barcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .sheet(item: $found, onDismiss: { state = .scanning }) { food in
                LogFoodSheet(food: food, meal: meal, date: date) { dismiss() }
            }
        }
    }

    @ViewBuilder private var overlay: some View {
        switch state {
        case .scanning:
            Label("Point the camera at a barcode", systemImage: "barcode.viewfinder")
        case .looking:
            HStack { ProgressView(); Text("Looking up product…") }
        case .failed(let msg):
            VStack(spacing: 8) {
                Text(msg).multilineTextAlignment(.center)
                Button("Scan again") { state = .scanning }
            }
        }
    }

    private func lookup(_ code: String) async {
        state = .looking
        do {
            found = try await service.lookup(barcode: code)
        } catch {
            state = .failed("Product \(code) not found in the database. Try a custom food.")
        }
    }
}
