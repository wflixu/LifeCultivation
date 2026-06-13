import SwiftUI

struct DiaryPageView: View {
    let record: DailyRecord?
    let nutritionCardsVM: NutritionCardsViewModel
    let waterCardVM: WaterCardViewModel
    let exerciseCardVM: ExerciseCardViewModel
    let addFoodVM: AddFoodViewModel
    let date: Date
    let showNutritionDetail: Binding<Bool>

    var body: some View {
        if let record {
            pageContent(record)
        } else {
            ProgressView()
                .containerRelativeFrame(.horizontal)
        }
    }

    private func pageContent(_ record: DailyRecord) -> some View {
        ScrollView(.vertical) {
            VStack(spacing: 16) {
                CalorieRingCard(record: record, showNutritionDetail: showNutritionDetail)
                NutritionCards(
                    record: record,
                    vm: nutritionCardsVM,
                    addFoodVM: addFoodVM,
                    date: date
                )
                ExerciseCard(
                    record: record,
                    vm: exerciseCardVM,
                    date: date
                )
                WaterCard(
                    record: record,
                    vm: waterCardVM
                )
            }
            .padding(16)
        }
        .scrollIndicators(.hidden)
        .containerRelativeFrame(.horizontal)
        .onAppear {
            nutritionCardsVM.loadFoods(for: record)
            waterCardVM.load(from: record, profile: nil)
            exerciseCardVM.load(from: record, profile: nil)
        }
    }
}
