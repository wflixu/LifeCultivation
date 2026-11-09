import SwiftData
import SwiftUI

struct NutritionCards: View {
    let date: Date
    let vm: NutritionCardsViewModel
    let addFoodVM: AddFoodViewModel

    @Query private var todayFoods: [FoodEntry]

    init(date: Date, vm: NutritionCardsViewModel, addFoodVM: AddFoodViewModel) {
        self.date = date
        self.vm = vm
        self.addFoodVM = addFoodVM
        _todayFoods = Query(sort: \FoodEntry.timestamp)
    }

    private var foodsForDate: [FoodEntry] {
        let dayStart = Calendar.current.startOfDay(for: date)
        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
        return todayFoods.filter { food in
            // Prefer recordDate, fallback to dailyRecord?.date for old data
            let d = food.recordDate != Date.distantPast
                ? food.recordDate
                : (food.dailyRecord?.date ?? Date.distantPast)
            return d >= dayStart && d < dayEnd
        }
    }

    private var meals: [MealType: [FoodEntry]] {
        var grouped: [MealType: [FoodEntry]] = [:]
        for food in foodsForDate {
            let meal = food.mealType ?? .snack
            grouped[meal, default: []].append(food)
        }
        return grouped
    }

    var body: some View {
        @Bindable var vm = self.vm
        VStack(spacing: 0) {
            ForEach(Array(MealType.allCases.enumerated()), id: \.element.self) { index, meal in
                mealSection(meal)

                if index < MealType.allCases.count - 1 {
                    divider
                }
            }
        }
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .appCardShadow()
        .alert("确认删除", isPresented: $vm.showDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let food = vm.foodToDelete { vm.deleteFood(food) }
            }
        } message: {
            Text("删除「\(vm.foodToDelete?.name ?? "")」？此操作不可撤销。")
        }
        .sheet(isPresented: $vm.showDetail) {
            if let food = vm.selectedFood {
                FoodEntryDetailView(food: food, onDelete: {
                    vm.showDetail = false
                    vm.deleteFood(food)
                })
            }
        }
    }

    // MARK: - Divider

    private var divider: some View {
        Rectangle()
            .fill(Color(.systemGray6))
            .frame(height: 1)
            .padding(.leading, 56)
    }

    // MARK: - Meal Section

    private func mealSection(_ meal: MealType) -> some View {
        let foods = meals[meal] ?? []
        let totalCal = foods.reduce(0) { $0 + $1.calories }
        let color = AppColors.mealColor(meal)

        return VStack(spacing: 0) {
            // Header row
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Text(mealEmoji(meal))
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(meal.rawValue)
                        .font(.subheadline.weight(.semibold))
                    if totalCal > 0 {
                        Text("\(Int(totalCal)) kcal")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Button {
                    Haptic.light()
                    addFoodVM.targetMealType = meal
                    addFoodVM.targetDate = date
                    vm.selectedMealType = meal
                    vm.showAddFood = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(color)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            if !foods.isEmpty {
                VStack(spacing: 0) {
                    ForEach(foods) { food in
                        foodRow(food)
                    }
                }
            }
        }
    }

    // MARK: - Food Row

    private func foodRow(_ food: FoodEntry) -> some View {
        SwipeableFoodRow(
            food: food,
            onTap: {
                Haptic.light()
                vm.selectedFood = food
                vm.showDetail = true
            },
            onDeleteRequest: {
                Haptic.warning()
                vm.foodToDelete = food
                vm.showDeleteConfirmation = true
            }
        )
    }

    // MARK: - Helpers

    private func mealEmoji(_ meal: MealType) -> String {
        switch meal {
        case .breakfast: "🌅"
        case .lunch: "☀️"
        case .dinner: "🌙"
        case .snack: "🍿"
        }
    }
}
