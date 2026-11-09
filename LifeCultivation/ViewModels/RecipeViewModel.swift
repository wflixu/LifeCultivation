import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class RecipeViewModel {
    private let modelContainer: ModelContainer
    private let nutritionService: NutritionServiceProtocol
    var context: ModelContext { modelContainer.mainContext }

    var favoriteFoods: [FavoriteFood] = []
    var filteredFoods: [FavoriteFood] = []
    var searchText: String = ""
    var selectedCategory: FoodCategory?
    var showFoodEdit = false
    var editingFood: FavoriteFood?

    var aiSuggestions: [NutritionSuggestion] = []
    var isAISuggesting = false
    var aiSuggestionError: String?

    init(modelContainer: ModelContainer, nutritionService: NutritionServiceProtocol) {
        self.modelContainer = modelContainer
        self.nutritionService = nutritionService
    }

    func loadFavorites() {
        let descriptor = FetchDescriptor<FavoriteFood>(
            sortBy: [SortDescriptor(\.useCount, order: .reverse)]
        )
        favoriteFoods = (try? context.fetch(descriptor)) ?? []
        applyFilters()
    }

    func applyFilters() {
        var result = favoriteFoods

        if let category = selectedCategory {
            result = result.filter { $0.category == category }
        }

        let query = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        if !query.isEmpty {
            result = result.filter { $0.name.lowercased().contains(query) }
        }

        filteredFoods = result
    }

    func deleteFood(_ food: FavoriteFood) {
        context.delete(food)
        try? context.save()
        loadFavorites()
    }

    func saveFood(_ food: FavoriteFood, name: String, calories: Double, serving: String,
                  protein: Double?, fat: Double?, carbs: Double?, category: FoodCategory?) {
        food.name = name
        food.calories = calories
        food.serving = serving
        food.protein = protein
        food.fat = fat
        food.carbs = carbs
        food.category = category
        try? context.save()
        loadFavorites()
    }

    func requestAISuggestion(foodName: String, serving: String) {
        guard !foodName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isAISuggesting = true
        aiSuggestionError = nil
        aiSuggestions = []

        Task {
            do {
                aiSuggestions = try await nutritionService.suggestNutrition(
                    foodName: foodName,
                    serving: serving
                )
            } catch {
                aiSuggestionError = error.localizedDescription
            }
            isAISuggesting = false
        }
    }

    func addToDiary(_ food: FavoriteFood, mealType: MealType, date: Date) {
        let dayStart = Calendar.current.startOfDay(for: date)
        let descriptor = FetchDescriptor<DailyRecord>(predicate: #Predicate { $0.date == dayStart })
        let record: DailyRecord
        if let existing = try? context.fetch(descriptor).first {
            record = existing
        } else {
            record = DailyRecord(date: dayStart)
            context.insert(record)
        }

        let entry = FoodEntry(
            name: food.name,
            calories: food.calories,
            serving: food.serving,
            mealType: mealType,
            source: .favorite,
            protein: food.protein,
            fat: food.fat,
            carbs: food.carbs,
            recordDate: dayStart
        )
        entry.dailyRecord = record
        context.insert(entry)

        food.useCount += 1
        food.lastUsed = Date()
        try? context.save()
    }
}
