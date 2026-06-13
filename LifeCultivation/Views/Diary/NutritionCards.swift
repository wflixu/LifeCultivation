import SwiftUI

struct NutritionCards: View {
    let record: DailyRecord
    let vm: NutritionCardsViewModel
    let addFoodVM: AddFoodViewModel
    let date: Date

    private let mealColors: [MealType: Color] = [
        .breakfast: Color(red: 1.0, green: 0.84, blue: 0.04),
        .lunch: Color.orange,
        .dinner: Color(red: 0.69, green: 0.32, blue: 0.87),
        .snack: Color(white: 0.56)
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(MealType.allCases, id: \.self) { meal in
                mealCard(meal)
            }
        }
    }

    private func mealCard(_ meal: MealType) -> some View {
        let foods = vm.meals[meal] ?? []
        let totalCal = foods.reduce(0) { $0 + $1.calories }

        return VStack(spacing: 0) {
            // Header
            HStack {
                Circle()
                    .fill(mealColors[meal] ?? .gray)
                    .frame(width: 8, height: 8)
                Text(meal.rawValue)
                    .font(.subheadline.weight(.medium))
                Spacer()
                Text("\(Int(totalCal)) kcal")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button {
                    addFoodVM.targetMealType = meal
                    addFoodVM.targetDate = date
                    vm.selectedMealType = meal
                    vm.showAddFood = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            if foods.isEmpty {
                Text("暂无记录")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 12)
            } else {
                Divider().padding(.horizontal, 16)

                ForEach(foods) { food in
                    foodRow(food)
                }
            }
        }
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))
    }

    private func foodRow(_ food: FoodEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .font(.subheadline)
                Text(food.serving)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(food.calories)) kcal")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                vm.deleteFood(food)
                vm.loadFoods(for: record)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
}
