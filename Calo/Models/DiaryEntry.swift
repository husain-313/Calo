import Foundation
import SwiftData

enum MealType: String, Codable, CaseIterable, Identifiable {
    case breakfast, lunch, dinner, snacks
    var id: String { rawValue }
    var title: String {
        switch self {
        case .breakfast: return "Breakfast"
        case .lunch: return "Lunch"
        case .dinner: return "Dinner"
        case .snacks: return "Snacks"
        }
    }
    var symbol: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.stars.fill"
        case .snacks: return "takeoutbag.and.cup.and.straw.fill"
        }
    }
}

/// A logged food within a day's diary. Stores a snapshot of nutrition so edits
/// to the underlying FoodItem don't rewrite history.
@Model
final class DiaryEntry {
    @Attribute(.unique) var id: UUID
    var date: Date            // normalized to start of day
    var mealRaw: String
    var foodName: String
    var brand: String?

    /// Logged amount expressed in the food base unit (g/ml).
    var amountInBase: Double
    var servingLabel: String

    // Snapshot of nutrition for the logged amount.
    var calories: Double
    var protein: Double
    var carbs: Double
    var fat: Double
    var fiber: Double
    var sugar: Double
    var sodium: Double

    var foodID: UUID?
    var loggedAt: Date

    var meal: MealType {
        get { MealType(rawValue: mealRaw) ?? .snacks }
        set { mealRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        date: Date,
        meal: MealType,
        foodName: String,
        brand: String? = nil,
        amountInBase: Double,
        servingLabel: String,
        calories: Double,
        protein: Double,
        carbs: Double,
        fat: Double,
        fiber: Double = 0,
        sugar: Double = 0,
        sodium: Double = 0,
        foodID: UUID? = nil,
        loggedAt: Date = .now
    ) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.mealRaw = meal.rawValue
        self.foodName = foodName
        self.brand = brand
        self.amountInBase = amountInBase
        self.servingLabel = servingLabel
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.fiber = fiber
        self.sugar = sugar
        self.sodium = sodium
        self.foodID = foodID
        self.loggedAt = loggedAt
    }
}
