import Foundation
import SwiftData

enum Sex: String, Codable, CaseIterable, Identifiable {
    case male, female
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum ActivityLevel: String, Codable, CaseIterable, Identifiable {
    case sedentary, light, moderate, active, veryActive
    var id: String { rawValue }
    var title: String {
        switch self {
        case .sedentary: return "Sedentary"
        case .light: return "Lightly active"
        case .moderate: return "Moderately active"
        case .active: return "Active"
        case .veryActive: return "Very active"
        }
    }
    /// Mifflin-St Jeor activity multiplier.
    var multiplier: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        case .veryActive: return 1.9
        }
    }
}

enum GoalPace: String, Codable, CaseIterable, Identifiable {
    case lose100, lose050, lose025, maintain, gain025, gain050
    var id: String { rawValue }
    /// kg per week (negative = loss).
    var kgPerWeek: Double {
        switch self {
        case .lose100: return -1.0
        case .lose050: return -0.5
        case .lose025: return -0.25
        case .maintain: return 0
        case .gain025: return 0.25
        case .gain050: return 0.5
        }
    }
    var title: String {
        switch self {
        case .lose100: return "Lose 1.0 kg / week"
        case .lose050: return "Lose 0.5 kg / week"
        case .lose025: return "Lose 0.25 kg / week"
        case .maintain: return "Maintain weight"
        case .gain025: return "Gain 0.25 kg / week"
        case .gain050: return "Gain 0.5 kg / week"
        }
    }
}

/// Single-row profile holding goals and body stats.
@Model
final class UserProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var sexRaw: String
    var birthDate: Date
    var heightCm: Double
    var startWeightKg: Double
    var goalWeightKg: Double
    var activityRaw: String
    var paceRaw: String

    // Macro split as fraction of calories (protein/carbs/fat).
    var proteinPct: Double
    var carbsPct: Double
    var fatPct: Double

    /// When true, exercise calories are added back to the day's budget.
    var addExerciseCalories: Bool
    /// Manual calorie goal override; nil = computed from profile.
    var manualCalorieGoal: Double?

    var waterGoalML: Double
    var useMetric: Bool

    var sex: Sex { get { Sex(rawValue: sexRaw) ?? .male } set { sexRaw = newValue.rawValue } }
    var activity: ActivityLevel { get { ActivityLevel(rawValue: activityRaw) ?? .sedentary } set { activityRaw = newValue.rawValue } }
    var pace: GoalPace { get { GoalPace(rawValue: paceRaw) ?? .lose050 } set { paceRaw = newValue.rawValue } }

    init(
        id: UUID = UUID(),
        name: String = "You",
        sex: Sex = .male,
        birthDate: Date = Calendar.current.date(byAdding: .year, value: -30, to: .now) ?? .now,
        heightCm: Double = 175,
        startWeightKg: Double = 80,
        goalWeightKg: Double = 72,
        activity: ActivityLevel = .light,
        pace: GoalPace = .lose050,
        proteinPct: Double = 0.30,
        carbsPct: Double = 0.40,
        fatPct: Double = 0.30,
        addExerciseCalories: Bool = true,
        manualCalorieGoal: Double? = nil,
        waterGoalML: Double = 2000,
        useMetric: Bool = true
    ) {
        self.id = id
        self.name = name
        self.sexRaw = sex.rawValue
        self.birthDate = birthDate
        self.heightCm = heightCm
        self.startWeightKg = startWeightKg
        self.goalWeightKg = goalWeightKg
        self.activityRaw = activity.rawValue
        self.paceRaw = pace.rawValue
        self.proteinPct = proteinPct
        self.carbsPct = carbsPct
        self.fatPct = fatPct
        self.addExerciseCalories = addExerciseCalories
        self.manualCalorieGoal = manualCalorieGoal
        self.waterGoalML = waterGoalML
        self.useMetric = useMetric
    }

    var ageYears: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: .now).year ?? 30
    }
}
