import Foundation

enum StreakCalculator {
    /// Count consecutive days (backward from today) with at least one FoodEntry.
    static func recordingStreak(records: [DailyRecord]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0

        for offset in 0... {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { break }
            let record = records.first { calendar.isDate($0.date, inSameDayAs: date) }
            if let record, let foods = record.foods, !foods.isEmpty {
                streak += 1
            } else if offset == 0 {
                // Today: if no record yet, don't break streak (still counting today)
                continue
            } else {
                break
            }
        }
        return streak
    }

    /// Count consecutive days (backward from today) where netCalories <= 0.
    static func goalMetStreak(records: [DailyRecord]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0

        for offset in 0... {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { break }
            guard let record = records.first(where: { calendar.isDate($0.date, inSameDayAs: date) }) else {
                if offset == 0 { continue }
                break
            }
            guard record.totalIntake > 0 else {
                if offset == 0 { continue }
                break
            }
            if record.netCalories <= 0 {
                streak += 1
            } else {
                // Today: still counting if today isn't over
                if offset == 0 { continue }
                break
            }
        }
        return streak
    }
}
