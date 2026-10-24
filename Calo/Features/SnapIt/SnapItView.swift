import SwiftUI
import SwiftData
import UIKit

/// Snap It: photograph a meal, recognize it on-device, then pull nutrition
/// from Open Food Facts and log the chosen food.
struct SnapItView: View {
    @Environment(\.dismiss) private var dismiss

    var meal: MealType
    var date: Date = .now

    @State private var image: UIImage?
    @State private var guesses: [FoodGuess] = []
    @State private var analyzing = false
    @State private var picker: ImagePicker.Source?
    @State private var manualQuery = ""

    // Second stage: from a chosen label -> OFF results -> log sheet.
    @State private var searchLabel: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    imageArea
                    sourceButtons

                    if analyzing {
                        HStack { ProgressView(); Text("Recognizing food…") }
                            .padding(.top, 4)
                    }

                    if !guesses.isEmpty {
                        guessList
                    } else if image != nil && !analyzing {
                        noMatch
                    }
                }
                .padding()
            }
            .navigationTitle("Snap It")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } } }
            .fullScreenCover(item: $picker) { src in
                ImagePicker(source: src) { img in
                    image = img
                    Task { await analyze(img) }
                }
                .ignoresSafeArea()
            }
            .sheet(item: Binding(get: { searchLabel.map(IdentifiedString.init) },
                                 set: { searchLabel = $0?.value })) { wrapped in
                SnapResultsView(query: wrapped.value, meal: meal, date: date) { dismiss() }
            }
        }
    }

    @ViewBuilder private var imageArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
            if let image {
                Image(uiImage: image)
                    .resizable().scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "camera.viewfinder").font(.system(size: 48))
                    Text("Take or choose a photo of your food").foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 260)
    }

    private var sourceButtons: some View {
        HStack(spacing: 12) {
            Button { picker = .camera } label: {
                Label("Camera", systemImage: "camera.fill").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            Button { picker = .library } label: {
                Label("Library", systemImage: "photo.on.rectangle").frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private var guessList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Is it one of these?").font(.headline)
            ForEach(guesses) { g in
                Button { searchLabel = g.label } label: {
                    HStack {
                        Text(g.label)
                        Spacer()
                        Text("\(Int(g.confidence * 100))%")
                            .font(.caption).foregroundStyle(.secondary)
                        Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
            manualSearchRow
        }
    }

    private var noMatch: some View {
        VStack(spacing: 10) {
            Text("Couldn't recognize the food.").foregroundStyle(.secondary)
            manualSearchRow
        }
    }

    private var manualSearchRow: some View {
        HStack {
            TextField("Search by name instead", text: $manualQuery)
                .textFieldStyle(.roundedBorder)
            Button("Go") { if !manualQuery.isEmpty { searchLabel = manualQuery } }
                .disabled(manualQuery.isEmpty)
        }
        .padding(.top, 4)
    }

    private func analyze(_ img: UIImage) async {
        analyzing = true
        guesses = []
        defer { analyzing = false }
        guesses = await FoodRecognizer.classify(img)
    }
}

/// Wraps a String so it can drive a `.sheet(item:)`.
private struct IdentifiedString: Identifiable {
    let value: String
    var id: String { value }
}

/// Searches Open Food Facts for a recognized label and lets the user log a match.
struct SnapResultsView: View {
    @Environment(\.dismiss) private var dismiss

    let query: String
    let meal: MealType
    let date: Date
    var onLogged: () -> Void = {}

    @State private var results: [FoodItem] = []
    @State private var loading = true
    @State private var error: String?
    @State private var selected: FoodItem?

    private let service = OpenFoodFactsService()

    var body: some View {
        NavigationStack {
            List {
                if loading { HStack { ProgressView(); Text("Finding \"\(query)\"…") } }
                if let error { Text(error).foregroundStyle(.red) }
                ForEach(results) { food in
                    Button { selected = food } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(food.name).foregroundStyle(.primary)
                            Text("\(Fmt.kcal(food.caloriesPer100)) kcal / 100\(food.baseUnit)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle(query.capitalized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Back") { dismiss() } } }
            .task { await load() }
            .sheet(item: $selected) { food in
                LogFoodSheet(food: food, meal: meal, date: date) {
                    onLogged(); dismiss()
                }
            }
        }
    }

    private func load() async {
        loading = true; error = nil
        defer { loading = false }
        do {
            results = try await service.search(query)
            if results.isEmpty { error = "No nutrition data for \"\(query)\". Try a custom food." }
        } catch {
            self.error = "Lookup failed. Check your connection."
        }
    }
}
