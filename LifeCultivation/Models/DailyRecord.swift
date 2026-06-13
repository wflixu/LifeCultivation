import Foundation
import SwiftData

@Model
final class DailyRecord {
    @Attribute(.unique) var date: Date
    var weight: Double?
    var restingEnergy: Double?
    var activeEnergy: Double?
    var waterCups: Int = 0
    var stepCount: Int = 0

    @Relationship(deleteRule: .cascade) var foods: [FoodEntry]? = []
    @Relationship(deleteRule: .cascade) var exercises: [ExerciseEntry]? = []

    var tdee: Double {
        (restingEnergy ?? 0) + (activeEnergy ?? 0)
    }

    var totalIntake: Double {
        foods?.reduce(0) { $0 + $1.calories } ?? 0
    }

    var netCalories: Double {
        totalIntake - tdee
    }

    var remaining: Double {
        tdee - totalIntake
    }

    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
    }
}
