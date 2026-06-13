import Foundation
import SwiftData

@Model
final class FoodEntry {
    var id: UUID = UUID()
    var name: String = ""
    var calories: Double = 0
    var protein: Double?
    var fat: Double?
    var carbs: Double?
    var serving: String = ""
    var mealType: MealType?
    var source: FoodSource = FoodSource.text
    var timestamp: Date = Date()
    var imageData: String?

    @Relationship(inverse: \DailyRecord.foods) var dailyRecord: DailyRecord?

    init(
        name: String,
        calories: Double,
        serving: String,
        mealType: MealType? = nil,
        source: FoodSource = .text,
        protein: Double? = nil,
        fat: Double? = nil,
        carbs: Double? = nil
    ) {
        self.name = name
        self.calories = calories
        self.serving = serving
        self.mealType = mealType
        self.source = source
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.timestamp = Date()
    }
}
