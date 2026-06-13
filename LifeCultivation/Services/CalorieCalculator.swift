import Foundation

enum CalorieCalculator {
    /// Mifflin-St Jeor formula — male.
    static func bmr(weightKg: Double, heightCm: Double, age: Int) -> Double {
        10 * weightKg + 6.25 * heightCm - 5 * Double(age) + 5
    }

    /// Estimated active energy when no Apple Watch data is available.
    static func estimatedActiveEnergy(bmr: Double, level: ActivityLevel) -> Double {
        bmr * level.coefficient - bmr
    }

    /// Total Daily Energy Expenditure.
    static func tdee(resting: Double, active: Double) -> Double {
        resting + active
    }

    /// Exercise calorie estimation using MET formula.
    static func exerciseCalories(met: Double, weightKg: Double, minutes: Double) -> Double {
        met * weightKg * (minutes / 60.0)
    }

    /// Steps to distance estimation using average stride length of 0.7 m.
    static func distance(steps: Int) -> Double {
        Double(steps) * 0.7 / 1000.0
    }
}
