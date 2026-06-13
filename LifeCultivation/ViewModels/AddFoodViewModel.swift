import Foundation
import SwiftData
import SwiftUI

enum AddFoodViewState {
    case initial
    case aiLoading
    case aiResults([RecognizedFood])
    case aiError(String)
    case searchResults([FavoriteFood])
}

struct CartItem: Identifiable {
    let id: UUID = UUID()
    let name: String
    let calories: Double
    let serving: String
    let protein: Double?
    let fat: Double?
    let carbs: Double?
    let isFavorite: Bool
    var favoriteRef: FavoriteFood?
}

@MainActor
@Observable
final class AddFoodViewModel {
    private let modelContainer: ModelContainer
    private let nutritionService: NutritionServiceProtocol
    var context: ModelContext { modelContainer.mainContext }

    var selectedMode: Int = 0  // 0=search, 1=input, 2=camera
    var searchQuery: String = ""
    var inputText: String = ""
    var viewState: AddFoodViewState = .initial
    var cart: [CartItem] = []
    var favoriteIndices: Set<Int> = []
    var targetMealType: MealType?
    var targetDate: Date = Date()

    var totalCalories: Double { cart.reduce(0) { $0 + $1.calories } }

    init(modelContainer: ModelContainer, nutritionService: NutritionServiceProtocol) {
        self.modelContainer = modelContainer
        self.nutritionService = nutritionService
    }

    func searchFavorites() {
        let query = searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
        let descriptor = FetchDescriptor<FavoriteFood>(
            sortBy: [SortDescriptor(\.useCount, order: .reverse)]
        )
        if let all = try? context.fetch(descriptor) {
            let filtered = query.isEmpty
                ? all
                : all.filter { $0.name.lowercased().contains(query) }
            viewState = .searchResults(filtered)
        }
    }

    func recognizeFood() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty else { return }

        let profile = UserProfile.fetchOrCreate(context: context)
        guard let key = profile.apiKey, !key.isEmpty else {
            viewState = .aiError("请先在个人资料中配置 API Key")
            return
        }

        viewState = .aiLoading

        Task {
            do {
                let foods = try await nutritionService.recognizeFood(
                    description: inputText,
                    imageData: nil
                )
                viewState = .aiResults(foods)
                favoriteIndices = []
            } catch {
                viewState = .aiError(error.localizedDescription)
            }
        }
    }

    func addToCart(from recognized: RecognizedFood) {
        let item = CartItem(
            name: recognized.name,
            calories: recognized.calories,
            serving: recognized.serving,
            protein: recognized.protein,
            fat: recognized.fat,
            carbs: recognized.carbs,
            isFavorite: false
        )
        cart.append(item)
    }

    func addFavoriteToCart(_ favorite: FavoriteFood) {
        let item = CartItem(
            name: favorite.name,
            calories: favorite.calories,
            serving: favorite.serving,
            protein: favorite.protein,
            fat: favorite.fat,
            carbs: favorite.carbs,
            isFavorite: true,
            favoriteRef: favorite
        )
        cart.append(item)
    }

    func removeFromCart(_ item: CartItem) {
        cart.removeAll { $0.id == item.id }
    }

    func commit() {
        let dayStart = Calendar.current.startOfDay(for: targetDate)
        let descriptor = FetchDescriptor<DailyRecord>(predicate: #Predicate { $0.date == dayStart })
        let record: DailyRecord
        if let existing = try? context.fetch(descriptor).first {
            record = existing
        } else {
            record = DailyRecord(date: dayStart)
            context.insert(record)
        }

        for item in cart {
            let entry = FoodEntry(
                name: item.name,
                calories: item.calories,
                serving: item.serving,
                mealType: targetMealType,
                source: item.isFavorite ? .favorite : .text,
                protein: item.protein,
                fat: item.fat,
                carbs: item.carbs
            )
            entry.dailyRecord = record
            context.insert(entry)

            // Update useCount for favorite
            if let favRef = item.favoriteRef {
                favRef.useCount += 1
                favRef.lastUsed = Date()
            }
        }
        try? context.save()
    }

    func favoriteFood(at index: Int) {
        guard case .aiResults(let foods) = viewState,
              index < foods.count else { return }
        let food = foods[index]

        // Check if already favorited
        let name = food.name
        let descriptor = FetchDescriptor<FavoriteFood>(predicate: #Predicate { $0.name == name })
        if let existing = try? context.fetch(descriptor).first {
            existing.useCount += 1
            existing.lastUsed = Date()
        } else {
            let fav = FavoriteFood(
                name: food.name,
                calories: food.calories,
                serving: food.serving,
                protein: food.protein,
                fat: food.fat,
                carbs: food.carbs
            )
            context.insert(fav)
        }

        if (try? context.save()) != nil {
            favoriteIndices.insert(index)
        }
    }
}
