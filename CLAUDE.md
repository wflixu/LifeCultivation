# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LifeCultivation (人生修行) is an AI-powered weight-loss and calorie-tracking iOS app built with SwiftUI and SwiftData. It helps users track diet, exercise, and weight through AI food recognition, HealthKit integration, and data visualization.

3 tabs: 日记 (Diary), 食谱 (Recipes), 个人资料 (Profile)

## Technology Stack

- **Language**: Swift 6
- **UI Framework**: SwiftUI (iOS 26+)
- **Data Persistence**: SwiftData
- **Charts**: SwiftUI Charts framework
- **HealthKit**: iOS HealthKit for steps, energy, weight, workouts
- **AI**: Anthropic Messages API for food recognition
- **Architecture**: MVVM + Service Layer with protocol abstraction
- **Observation**: @MainActor @Observable classes (NOT @ObservableObject)
- **Development**: Xcode project (no package managers)

## Build Commands

```bash
# Build the app (simulator)
xcodebuild -scheme LifeCultivation -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

# Run tests
xcodebuild test -scheme LifeCultivation

# Clean build folder
xcodebuild clean -scheme LifeCultivation
```

## Project Structure

```
LifeCultivation/
├── Models/
│   ├── Enums.swift            # MealType, FoodSource, FoodCategory, ExerciseType, ActivityLevel, ViewState<T>
│   ├── DailyRecord.swift      # @Model — daily food, exercise, weight, energy, water, steps
│   ├── FoodEntry.swift        # @Model — individual food with macros
│   ├── ExerciseEntry.swift    # @Model — individual exercise with MET calculation
│   ├── FavoriteFood.swift     # @Model — favorited foods with useCount sorting
│   └── UserProfile.swift      # @Model — singleton profile (height, age, targets, API key)
├── Services/
│   ├── HealthKitService.swift # Protocol + impl — HK queries, DTO: HealthKitWorkout
│   ├── AINutritionService.swift # Protocol + impl — Anthropic API, DTOs: RecognizedFood, NutritionSuggestion
│   ├── CalorieCalculator.swift # Stateless enum — BMR, TDEE, MET exercise, step distance
│   └── StreakCalculator.swift  # Stateless enum — recording streak, goal-met streak
├── ViewModels/
│   ├── DiaryViewModel.swift        # Date navigation, HK sync, backfill, midnight transition
│   ├── NutritionCardsViewModel.swift # Meals grouped by MealType, delete food
│   ├── WaterCardViewModel.swift    # Cup toggle
│   ├── ExerciseCardViewModel.swift # Steps, manual exercise with MET
│   ├── AddFoodViewModel.swift      # 3 modes (search/input/camera), AI recognition, cart
│   ├── RecipeViewModel.swift       # Favorite CRUD, search, category filter
│   ├── ProfileViewModel.swift       # Profile, weight entry, streaks, data export
│   └── OnboardingViewModel.swift   # 7-step onboarding with HealthKit skip path
├── Views/
│   ├── ContentView.swift           # 3-tab navigation
│   ├── Diary/
│   │   ├── DiaryView.swift         # Horizontal paging + calendar jump
│   │   ├── DiaryPageView.swift     # Vertical scroll of daily cards
│   │   ├── CalorieRingCard.swift   # Intake vs TDEE ring chart
│   │   ├── NutritionCards.swift    # 4 meal type cards with swipe-delete
│   │   ├── ExerciseCard.swift      # Step progress + exercise list
│   │   ├── WaterCard.swift         # Cup toggle icons
│   │   ├── NutritionDetailView.swift # Macro pie chart
│   │   └── AddExerciseView.swift   # Exercise type grid + MET estimate
│   ├── Food/
│   │   ├── AddFoodView.swift       # Search / text input / camera modes + cart
│   │   └── FoodEditView.swift      # Food form with AI suggestions
│   ├── Recipe/
│   │   ├── RecipeView.swift        # Category filter + favorites list
│   │   └── RecipeFoodRow.swift     # Food list row
│   ├── Profile/
│   │   ├── ProfileView.swift       # ScrollView of profile cards
│   │   ├── ProgressCard.swift      # Weight loss progress bar
│   │   ├── StreakCard.swift        # Recording & goal streaks
│   │   ├── GoalsCard.swift         # Activity level, height, age, targets
│   │   ├── WeightEntryCard.swift   # Manual weight entry
│   │   └── SettingsCard.swift      # API key, export
│   └── Onboarding/
│       └── OnboardingView.swift    # 6-step onboarding flow
└── LifeCultivationApp.swift        # @main — ModelContainer, ViewModel init, onboarding gate
```

## Architecture Pattern

### ViewModel Construction
ViewModels receive `ModelContainer` via constructor, access `modelContainer.mainContext`:
```swift
@MainActor
@Observable
final class DiaryViewModel {
    private let modelContainer: ModelContainer
    var context: ModelContext { modelContainer.mainContext }
    init(modelContainer: ModelContainer, healthKitService: HealthKitServiceProtocol) { ... }
}
```

### iOS 26.5 HealthKit API
- `HKQuantityTypeIdentifier` is `RawRepresentable` — use `HKQuantityTypeIdentifier(rawValue:)` for identifiers
- Use `NSSortDescriptor(key:HKSampleSortIdentifierStartDate, ascending:)` instead of `HKSortDescriptor`
- Explicit `HKUnit.kilocalorie()` calls (no implicit member expressions)
- Cumulative statistics queries: `HKStatisticsQuery` with `.cumulativeSum`

### SwiftData
- Store file: `LifeCultivation-v2.store` (separate from v1)
- Models use `@Attribute(.unique)` on date for upsert behavior
- `@Relationship(deleteRule: .cascade)` for foods/exercises

### View Pattern
- `@Bindable var vm: SomeViewModel` for accessing `$vm.property` bindings from `@Observable` types
- `@AppStorage("onboardingCompleted")` for onboarding gate
- `ContentView` holds all ViewModels, passes them to tab views

## Testing

Testing on iOS 26.5 real device connected to Mac via USB. Simulator build with `iPhone 17 Pro` destination.

## Documentation

See `spec/prd-v2.md` for v2 PRD and `spec/system-design.md` for system design.
