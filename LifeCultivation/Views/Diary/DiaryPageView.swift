import SwiftUI

struct DiaryPageView: View {
    let record: DailyRecord?
    let profile: UserProfile?
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
                CalorieRingCard(record: record, profile: profile, showNutritionDetail: showNutritionDetail)
                NutritionCards(
                    date: date,
                    vm: nutritionCardsVM,
                    addFoodVM: addFoodVM
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
            print("[DiaryPageView] onAppear date=\(date)")
            waterCardVM.load(from: record, profile: profile)
            exerciseCardVM.load(from: record, profile: profile)
        }
        .onChange(of: nutritionCardsVM.showAddFood) { _, show in
            print("[DiaryPageView] showAddFood=\(show) date=\(date)")
            if show {
                addFoodVM.targetDate = date
            }
        }
    }
}
