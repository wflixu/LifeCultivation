import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class NutritionCardsViewModel {
    private let modelContainer: ModelContainer
    var context: ModelContext { modelContainer.mainContext }

    var showAddFood = false
    var selectedMealType: MealType?

    // Delete confirmation
    var showDeleteConfirmation = false
    var foodToDelete: FoodEntry?

    // Food detail
    var showDetail = false
    var selectedFood: FoodEntry?

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func deleteFood(_ entry: FoodEntry) {
        context.delete(entry)
        try? context.save()
    }
}
