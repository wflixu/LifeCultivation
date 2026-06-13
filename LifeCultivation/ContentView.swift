import SwiftUI

struct ContentView: View {
    @Bindable var diaryVM: DiaryViewModel
    @Bindable var nutritionCardsVM: NutritionCardsViewModel
    @Bindable var waterCardVM: WaterCardViewModel
    @Bindable var exerciseCardVM: ExerciseCardViewModel
    @Bindable var addFoodVM: AddFoodViewModel
    @Bindable var recipeVM: RecipeViewModel
    @Bindable var profileVM: ProfileViewModel

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                DiaryView(
                    diaryVM: diaryVM,
                    nutritionCardsVM: nutritionCardsVM,
                    waterCardVM: waterCardVM,
                    exerciseCardVM: exerciseCardVM,
                    addFoodVM: addFoodVM
                )
                .navigationTitle("日记")
                .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("日记", systemImage: "book.pages.fill")
            }
            .tag(0)

            NavigationStack {
                RecipeView(vm: recipeVM)
                    .navigationTitle("食谱")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("食谱", systemImage: "fork.knife")
            }
            .tag(1)

            NavigationStack {
                ProfileView(vm: profileVM)
                    .navigationTitle("个人资料")
                    .navigationBarTitleDisplayMode(.inline)
            }
            .tabItem {
                Label("个人资料", systemImage: "person.crop.circle.fill")
            }
            .tag(2)
        }
        .tint(.orange)
        .onChange(of: nutritionCardsVM.showAddFood) { _, show in
            if show {
                addFoodVM.targetMealType = nutritionCardsVM.selectedMealType
                addFoodVM.targetDate = diaryVM.currentDate
            }
        }
        .sheet(isPresented: $nutritionCardsVM.showAddFood) {
            AddFoodView(vm: addFoodVM)
        }
    }
}
