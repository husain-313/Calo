import Foundation

/// Pure functions for calorie/macro targets. No app state, easy to unit test.
enum NutritionMath {

    /// Basal metabolic rate via Mifflin-St Jeor.
    static func bmr(sex: Sex, weightKg: Double, heightCm: Double, ageYears: Int) -> Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(ageYears)
        return sex == .male ? base + 5 : base - 161
    }

    /// Total daily energy expenditure (maintenance calories).
    static func tdee(profile: UserProfile, currentWeightKg: Double) -> Double {
        let b = bmr(sex: profile.sex, weightKg: currentWeightKg,
                    heightCm: profile.heightCm, ageYears: profile.ageYears)
        return b * profile.activity.multiplier
    }

    /// Daily calorie budget before exercise adjustment.
    /// 1 kg of body fat ≈ 7700 kcal.
    static func calorieGoal(profile: UserProfile, currentWeightKg: Double) -> Double {
        if let manual = profile.manualCalorieGoal { return manual }
        let maintenance = tdee(profile: profile, currentWeightKg: currentWeightKg)
        let dailyDelta = profile.pace.kgPerWeek * 7700 / 7
        let goal = maintenance + dailyDelta
        return max(goal, 1200) // safety floor
    }

    /// Grams of each macro for a calorie goal. 4/4/9 kcal per gram.
    static func macroGrams(calories: Double, profile: UserProfile)
        -> (protein: Double, carbs: Double, fat: Double) {
        let p = calories * profile.proteinPct / 4
        let c = calories * profile.carbsPct / 4
        let f = calories * profile.fatPct / 9
        return (p, c, f)
    }
}

/// Aggregated totals for a single day, used by the dashboard and diary.
struct DayTotals {
    var calories: Double = 0
    var protein: Double = 0
    var carbs: Double = 0
    var fat: Double = 0
    var fiber: Double = 0
    var sugar: Double = 0
    var sodium: Double = 0
    var exerciseCalories: Double = 0
    var waterML: Double = 0

    mutating func add(_ e: DiaryEntry) {
        calories += e.calories
        protein += e.protein
        carbs += e.carbs
        fat += e.fat
        fiber += e.fiber
        sugar += e.sugar
        sodium += e.sodium
    }
}
