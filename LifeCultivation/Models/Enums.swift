import Foundation

enum MealType: String, Codable, CaseIterable {
    case breakfast = "早餐"
    case lunch = "午餐"
    case dinner = "晚餐"
    case snack = "小吃"
}

enum FoodSource: String, Codable {
    case text
    case photo
    case favorite
}

enum FoodCategory: String, Codable, CaseIterable {
    case staple = "主食"
    case drink = "饮品"
    case snack = "小吃"
    case dish = "菜肴"
    case other = "其他"
}

enum ExerciseType: String, Codable, CaseIterable {
    case running = "跑步"
    case cycling = "骑行"
    case swimming = "游泳"
    case walking = "步行"
    case strength = "力量训练"
    case yoga = "瑜伽"
    case aerobics = "有氧体操"
    case ballGames = "球类运动"
    case other = "其他"

    var met: Double {
        switch self {
        case .running: 8.0
        case .cycling: 6.0
        case .swimming: 7.0
        case .walking: 3.5
        case .strength: 5.0
        case .yoga: 3.0
        case .aerobics: 6.0
        case .ballGames: 7.0
        case .other: 4.0
        }
    }
}

enum ExerciseSource: String, Codable {
    case healthKit
    case manual
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary = "久坐"
    case light = "轻度"
    case moderate = "中度"
    case active = "活跃"

    var coefficient: Double {
        switch self {
        case .sedentary: 1.2
        case .light: 1.375
        case .moderate: 1.55
        case .active: 1.725
        }
    }
}

enum ViewState<T> {
    case idle
    case loading
    case loaded(T)
    case error(String)
}
