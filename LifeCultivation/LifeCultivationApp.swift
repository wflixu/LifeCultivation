import SwiftData
import SwiftUI

@main
struct LifeCultivationApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DailyRecord.self,
            FoodEntry.self,
            ExerciseEntry.self,
            FavoriteFood.self,
            UserProfile.self
        ])
        let storeURL = URL.applicationSupportDirectory
            .appending(path: "LifeCultivation-v2.store")
        let config = ModelConfiguration(schema: schema, url: storeURL)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private let healthKitService: HealthKitServiceProtocol
    private let nutritionService: NutritionServiceProtocol

    @State private var diaryVM: DiaryViewModel
    @State private var nutritionCardsVM: NutritionCardsViewModel
    @State private var waterCardVM: WaterCardViewModel
    @State private var exerciseCardVM: ExerciseCardViewModel
    @State private var addFoodVM: AddFoodViewModel
    @State private var recipeVM: RecipeViewModel
    @State private var profileVM: ProfileViewModel
    @State private var onboardingVM: OnboardingViewModel

    init() {
        let container = sharedModelContainer
        let hk = HealthKitService()
        healthKitService = hk

        let profile = UserProfile.fetchOrCreate(context: container.mainContext)
        let apiKey = profile.apiKey ?? ""
        let baseURL = profile.apiBaseURL
        nutritionService = AINutritionService(apiKey: apiKey, baseURL: baseURL)

        _diaryVM = State(initialValue: DiaryViewModel(modelContainer: container, healthKitService: hk))
        _nutritionCardsVM = State(initialValue: NutritionCardsViewModel(modelContainer: container))
        _waterCardVM = State(initialValue: WaterCardViewModel(modelContainer: container))
        _exerciseCardVM = State(initialValue: ExerciseCardViewModel(modelContainer: container, healthKitService: hk))
        _addFoodVM = State(initialValue: AddFoodViewModel(modelContainer: container, nutritionService: nutritionService))
        _recipeVM = State(initialValue: RecipeViewModel(modelContainer: container, nutritionService: nutritionService))
        _profileVM = State(initialValue: ProfileViewModel(modelContainer: container, healthKitService: hk))
        _onboardingVM = State(initialValue: OnboardingViewModel(modelContainer: container, healthKitService: hk))
    }

    @AppStorage("onboardingCompleted") private var onboardingCompleted = false

    var body: some Scene {
        WindowGroup {
            ContentView(
                diaryVM: diaryVM,
                nutritionCardsVM: nutritionCardsVM,
                waterCardVM: waterCardVM,
                exerciseCardVM: exerciseCardVM,
                addFoodVM: addFoodVM,
                recipeVM: recipeVM,
                profileVM: profileVM
            )
            .fullScreenCover(isPresented: Binding(
                get: { !onboardingCompleted },
                set: { onboardingCompleted = !$0 }
            )) {
                OnboardingView(vm: onboardingVM)
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
