import Foundation
import SwiftData

/// A body-weight measurement.
@Model
final class WeightEntry {
    @Attribute(.unique) var id: UUID
    var date: Date      // start of day
    var weightKg: Double
    var note: String?

    init(id: UUID = UUID(), date: Date = .now, weightKg: Double, note: String? = nil) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.weightKg = weightKg
        self.note = note
    }
}

/// A logged exercise/workout burning calories.
@Model
final class ExerciseEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var name: String
    var minutes: Double
    var calories: Double
    /// "manual" or "healthkit"
    var source: String
    var loggedAt: Date

    init(id: UUID = UUID(), date: Date = .now, name: String, minutes: Double,
         calories: Double, source: String = "manual", loggedAt: Date = .now) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.name = name
        self.minutes = minutes
        self.calories = calories
        self.source = source
        self.loggedAt = loggedAt
    }
}

/// Water intake, one row per logged amount.
@Model
final class WaterEntry {
    @Attribute(.unique) var id: UUID
    var date: Date
    var amountML: Double
    var loggedAt: Date

    init(id: UUID = UUID(), date: Date = .now, amountML: Double, loggedAt: Date = .now) {
        self.id = id
        self.date = Calendar.current.startOfDay(for: date)
        self.amountML = amountML
        self.loggedAt = loggedAt
    }
}

/// An intermittent-fasting session.
@Model
final class FastingSession {
    @Attribute(.unique) var id: UUID
    var startAt: Date
    var endAt: Date?
    var targetHours: Double

    init(id: UUID = UUID(), startAt: Date = .now, endAt: Date? = nil, targetHours: Double = 16) {
        self.id = id
        self.startAt = startAt
        self.endAt = endAt
        self.targetHours = targetHours
    }

    var isActive: Bool { endAt == nil }
    var elapsed: TimeInterval { (endAt ?? .now).timeIntervalSince(startAt) }
}
