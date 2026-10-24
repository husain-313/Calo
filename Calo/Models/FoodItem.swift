import Foundation
import SwiftData

/// A food definition. Can come from Open Food Facts, USDA, or be a user-created
/// custom food / recipe. Nutrition is always stored per 100 g (or per 100 ml),
/// plus an optional list of named serving sizes for convenient logging.
@Model
final class FoodItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var brand: String?
    var barcode: String?

    /// "openfoodfacts", "usda", "custom", "recipe", "quick"
    var source: String

    // Macronutrients per 100 g/ml (the canonical reference amount).
    var caloriesPer100: Double
    var proteinPer100: Double
    var carbsPer100: Double
    var fatPer100: Double
    var fiberPer100: Double
    var sugarPer100: Double
    var sodiumPer100: Double      // mg
    var saturatedFatPer100: Double

    /// Reference unit, "g" or "ml".
    var baseUnit: String

    /// Named servings, e.g. "1 cup" = 240 g. Encoded as JSON.
    var servingsData: Data?

    var isFavorite: Bool
    var createdAt: Date
    var lastUsedAt: Date?

    init(
        id: UUID = UUID(),
        name: String,
        brand: String? = nil,
        barcode: String? = nil,
        source: String = "custom",
        caloriesPer100: Double = 0,
        proteinPer100: Double = 0,
        carbsPer100: Double = 0,
        fatPer100: Double = 0,
        fiberPer100: Double = 0,
        sugarPer100: Double = 0,
        sodiumPer100: Double = 0,
        saturatedFatPer100: Double = 0,
        baseUnit: String = "g",
        servings: [ServingSize] = [],
        isFavorite: Bool = false,
        createdAt: Date = .now,
        lastUsedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.source = source
        self.caloriesPer100 = caloriesPer100
        self.proteinPer100 = proteinPer100
        self.carbsPer100 = carbsPer100
        self.fatPer100 = fatPer100
        self.fiberPer100 = fiberPer100
        self.sugarPer100 = sugarPer100
        self.sodiumPer100 = sodiumPer100
        self.saturatedFatPer100 = saturatedFatPer100
        self.baseUnit = baseUnit
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.lastUsedAt = lastUsedAt
        self.servings = servings
    }

    var servings: [ServingSize] {
        get {
            guard let servingsData,
                  let decoded = try? JSONDecoder().decode([ServingSize].self, from: servingsData)
            else { return [] }
            return decoded
        }
        set { servingsData = try? JSONEncoder().encode(newValue) }
    }
}

/// A named portion with its weight/volume in the food's base unit.
struct ServingSize: Codable, Hashable, Identifiable {
    var id: UUID = UUID()
    var label: String      // "1 cup", "1 slice", "100 g"
    var amountInBase: Double  // grams or ml

    static let hundred = ServingSize(label: "100 g", amountInBase: 100)
    static let gram = ServingSize(label: "1 g", amountInBase: 1)
}
