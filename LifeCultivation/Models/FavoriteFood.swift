import Foundation
import SwiftData

@Model
final class FavoriteFood {
    var id: UUID = UUID()
    var name: String = ""
    var calories: Double = 0
    var protein: Double?
    var fat: Double?
    var carbs: Double?
    var serving: String = ""
    var category: FoodCategory?
    var useCount: Int = 0
    var lastUsed: Date?

    init(
        name: String,
        calories: Double,
        serving: String,
        protein: Double? = nil,
        fat: Double? = nil,
        carbs: Double? = nil,
        category: FoodCategory? = nil
    ) {
        self.name = name
        self.calories = calories
        self.serving = serving
        self.protein = protein
        self.fat = fat
        self.carbs = carbs
        self.category = category
    }
}
