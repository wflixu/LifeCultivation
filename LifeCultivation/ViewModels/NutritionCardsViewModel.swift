import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class NutritionCardsViewModel {
    private let modelContainer: ModelContainer
    var context: ModelContext { modelContainer.mainContext }

    var meals: [MealType: [FoodEntry]] = [:]
    var showAddFood = false
    var selectedMealType: MealType?

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func loadFoods(for record: DailyRecord) {
        var grouped: [MealType: [FoodEntry]] = [:]
        for food in record.foods ?? [] {
            let meal = food.mealType ?? .snack
            grouped[meal, default: []].append(food)
        }
        meals = grouped
    }

    func deleteFood(_ entry: FoodEntry) {
        context.delete(entry)
        try? context.save()
    }
}
