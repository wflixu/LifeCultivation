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

    /// Calories burned from manually-added exercises (separate from HK activeEnergy to avoid double-counting)
    var exerciseCalories: Double {
        (exercises ?? []).reduce(0) { $0 + $1.calories }
    }

    var netCalories: Double {
        totalIntake - tdee - exerciseCalories
    }

    var remaining: Double {
        tdee + exerciseCalories - totalIntake
    }

    /// Effective resting energy: HealthKit data if available, otherwise computed from profile via Mifflin-St Jeor
    func effectiveRestingEnergy(profile: UserProfile?) -> Double {
        if let re = restingEnergy, re > 0 { return re }
        guard let p = profile,
              let h = p.height, h > 0,
              let a = p.age, a > 0,
              let w = weight ?? p.latestWeight, w > 0 else { return 0 }
        return CalorieCalculator.bmr(weightKg: w, heightCm: h, age: a, gender: p.gender)
    }

    /// Effective TDEE using best available data
    func effectiveTDEE(profile: UserProfile?) -> Double {
        let resting = effectiveRestingEnergy(profile: profile)
        let active = activeEnergy ?? 0
        // If no HealthKit active energy, estimate from BMR * activity coefficient
        if active == 0, let p = profile, resting > 0 {
            let estimated = CalorieCalculator.estimatedActiveEnergy(bmr: resting, level: p.activityLevel)
            return resting + estimated
        }
        return resting + active
    }

    init(date: Date) {
        self.date = Calendar.current.startOfDay(for: date)
    }
}
