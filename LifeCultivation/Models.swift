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
    var exerciseCompleted: Bool
    var note: String?
    
    // 计算属性
    var totalScore: Int {
        let baseScore = dietScore + sleepScore + screenTimeScore
        return baseScore
    }
    
    var rating: String {
        switch totalScore {
        case 10: return "自律大师"
        case 8...9: return "高手"
        case 6...7: return "践行者"
        case 4...5: return "新手"
        default: return "休整日"
        }
    }
    
    init(date: Date = .now, dietScore: Int = 0, sleepScore: Int = 0,
         screenTimeScore: Int = 0, exerciseCompleted: Bool = false, note: String? = nil) {
        self.date = Calendar.current.startOfDay(for: date)
        self.dietScore = dietScore
        self.sleepScore = sleepScore
        self.screenTimeScore = screenTimeScore
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
