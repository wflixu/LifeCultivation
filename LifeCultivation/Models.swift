//
//  Models.swift
//  LifeCultivation
//
//  Created by luke on 2025/11/23.
//

import SwiftData
import Foundation

@Model
final class DailyRecord {
    var date: Date
    var dietScore: Int // 0-3
    var sleepScore: Int // 0-3
    var screenTimeScore: Int // 0-4
    var exerciseCount: Int // 每次锻炼计1分，无上限
    var exerciseCompleted: Bool
    var note: String?

    // 计算属性
    var totalScore: Int {
        let baseScore = dietScore + sleepScore + screenTimeScore + exerciseCount
        return baseScore
    }
    
    var rating: String {
        switch totalScore {
        case 12: return "自律大师"
        case 10...11: return "高手"
        case 8...9: return "践行者"
        case 6...7: return "新手"
        default: return "休整日"
        }
    }

    // 计算每周锻炼奖励分
    static func calculateWeeklyExerciseBonus(from records: [DailyRecord]) -> Int {
        let calendar = Calendar.current
        let now = Date()

        // 获取本周的所有记录
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let thisWeekRecords = records.filter { record in
            record.date >= weekStart
        }

        // 计算本周总锻炼次数
        let totalExerciseCount = thisWeekRecords.reduce(0) { $0 + $1.exerciseCount }

        // 每完成3次锻炼额外加1分
        return totalExerciseCount / 3
    }

    init(date: Date = .now, dietScore: Int = 0, sleepScore: Int = 0,
         screenTimeScore: Int = 0, exerciseCount: Int = 0, exerciseCompleted: Bool = false, note: String? = nil) {
        self.date = Calendar.current.startOfDay(for: date)
        self.dietScore = dietScore
        self.sleepScore = sleepScore
        self.screenTimeScore = screenTimeScore
        self.exerciseCount = exerciseCount
        self.exerciseCompleted = exerciseCompleted
        self.note = note
    }
}

@Model
final class AppSettings {
    var wakeUpTime: Date
    var bedTime: Date
    var screenTimeLimit: Int // 分钟
    
    init(wakeUpTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: .now)!,
         bedTime: Date = Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: .now)!,
         screenTimeLimit: Int = 30) {
        self.wakeUpTime = wakeUpTime
        self.bedTime = bedTime
        self.screenTimeLimit = screenTimeLimit
    }
}
