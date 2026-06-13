---
created: 2026-06-13
updated: 2026-06-13
tags:
  - iOS
  - SwiftUI
  - system-design
  - architecture
reviewed_by: apple-ecosystem-expert
---

# LifeCultivation v2 — System Design

> 系统设计文档，描述 v2 的技术架构、数据模型、服务设计、视图结构。
> 已通过专家 review，此为修订版。

---

## 1. 数据模型

### 1.1 DailyRecord — 每日记录

```
DailyRecord (@Model)
├── @Attribute(.unique) date: Date      // 日期（unique 约束）
├── foods: [FoodEntry]?                 // @Relationship(deleteRule: .cascade)
├── exercises: [ExerciseEntry]?         // @Relationship(deleteRule: .cascade)
├── weight: Double?                     // 当日体重(kg)
├── restingEnergy: Double?              // 静息消耗(kcal)
├── activeEnergy: Double?               // 活动消耗(kcal)
├── waterCups: Int                      // 饮水杯数，默认0
├── stepCount: Int                      // 当日步数，默认0
└──────────────────────────────────────
```

**计算属性**（非持久化）：
| 属性 | 公式 |
|------|------|
| `tdee` | `(restingEnergy ?? 0) + (activeEnergy ?? 0)` |
| `totalIntake` | `foods?.reduce(0) { $0 + $1.calories } ?? 0` |
| `netCalories` | `totalIntake - tdee` |
| `remaining` | `tdee - totalIntake` |

> **注意**：`remaining` 和 `deficit` 实际是同义反复，只保留 `remaining`。

> **`@Attribute(.unique)`**：防止创建同一天的多条记录。仍需 ViewModel 层 fetch-or-create 模式。

> **`height`/`age`/`activityLevel` 已移除**：这些是用户属性（低频变化），不应每天重复存储。移入 `UserProfile`，计算 TDEE 时从 UserProfile 读取。

### 1.2 FoodEntry — 食物记录

```
FoodEntry (@Model)
├── id: UUID
├── name: String                        // 食物名称
├── calories: Double                    // 热量(kcal)
├── protein: Double?                    // 蛋白质(g)
├── fat: Double?                        // 脂肪(g)
├── carbs: Double?                      // 碳水(g)
├── serving: String                     // 份量描述（"一碗"、"200ml"、"2个"）
├── mealType: MealType?                 // 用餐时段，可选
├── source: FoodSource                  // 来源
├── timestamp: Date                     // 记录时间
├── imageData: Data?                    // 拍照原图（Phase 2）
└── dailyRecord: DailyRecord?           // @Relationship(inverse: \DailyRecord.foods)
```

> **`imageData` blob 警告**：SwiftData 不支持 Core Data 的 "external storage" 选项。Phase 2 图片应存为文件，`imageData` 改为存文件路径 `String?`。Phase 1 无需关心（文字识别不走图片）。

> **FavoriteFood 与 FoodEntry 解耦**：修改 FavoriteFood 不会影响历史 FoodEntry 记录，这是刻意设计——保证历史记录的准确性。

### 1.3 FavoriteFood — 收藏食物

```
FavoriteFood (@Model)
├── id: UUID
├── name: String
├── calories: Double
├── protein: Double?
├── fat: Double?
├── carbs: Double?
├── serving: String                     // 默认份量
├── category: FoodCategory?             // 分类，可选
├── useCount: Int                       // 使用次数（排序），默认0
├── lastUsed: Date?                     // 最近使用时间
└──────────────────────────────────────
```

### 1.4 ExerciseEntry — 运动记录

```
ExerciseEntry (@Model)
├── id: UUID
├── exerciseType: ExerciseType          // 运动类型
├── duration: TimeInterval              // 时长(分钟)
├── calories: Double                    // 消耗热量(kcal)
├── distance: Double?                   // 距离(km)
├── source: ExerciseSource              // 数据来源
├── timestamp: Date
└── dailyRecord: DailyRecord?           // @Relationship(inverse: \DailyRecord.exercises)
```

### 1.5 UserProfile — 用户配置（单例）

```
UserProfile (@Model)
├── targetWeight: Double?               // 目标体重(kg)
├── dailyWaterTarget: Double            // 每日饮水目标(L)，默认2.0
├── stepGoal: Int                       // 每日步数目标，默认10000
├── activityLevel: ActivityLevel        // 活动系数，默认.light
├── height: Double?                     // 身高(cm)，HealthKit读取或手动输入
├── age: Int?                           // 年龄，HealthKit读取或手动输入
├── apiKey: String?                     // Anthropic API Key
├── apiBaseURL: String?                 // API Base URL，nil则用官方
└──────────────────────────────────────
```

> **单例模式**：表中始终只有一条记录。App 启动时 fetch-or-create。
> **`height`/`age`/`activityLevel`**：从 DailyRecord 移入，所有日期的计算共用这一份值。

### 1.6 枚举定义

```swift
enum MealType: String, Codable, CaseIterable {
    case breakfast = "早餐"
    case lunch = "午餐"
    case dinner = "晚餐"
    case snack = "小吃"
}

enum FoodSource: String, Codable {
    case text
    case photo       // Phase 2
    case favorite
}

enum FoodCategory: String, Codable, CaseIterable {
    case staple = "主食"
    case drink = "饮品"
    case snack = "小吃"
    case dish = "菜肴"
    case other = "其他"
}

enum ExerciseType: String, Codable, CaseIterable {
    case running = "跑步"
    case cycling = "骑行"
    case swimming = "游泳"
    case walking = "步行"
    case strength = "力量训练"
    case yoga = "瑜伽"
    case aerobics = "有氧体操"
    case ballGames = "球类运动"
    case other = "其他"

    var met: Double {
        switch self {
        case .running: return 8.0
        case .cycling: return 6.0
        case .swimming: return 7.0
        case .walking: return 3.5
        case .strength: return 5.0
        case .yoga: return 3.0
        case .aerobics: return 6.0
        case .ballGames: return 7.0
        case .other: return 4.0
        }
    }
}

enum ExerciseSource: String, Codable {
    case healthKit
    case manual
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary = "久坐"     // 1.2
    case light = "轻度"         // 1.375
    case moderate = "中度"      // 1.55
    case active = "活跃"        // 1.725

    var coefficient: Double {
        switch self {
        case .sedentary: return 1.2
        case .light: return 1.375
        case .moderate: return 1.55
        case .active: return 1.725
        }
    }
}
```

---

## 2. 架构设计

### 2.1 分层架构

```
┌──────────────────────────────────────────┐
│  View Layer (SwiftUI)                    │
│  - 纯 UI 展示 + 用户交互                  │
│  - 通过 @Environment(VM.self) 获取数据     │
│  - 不直接操作 SwiftData                   │
└────────────────┬─────────────────────────┘
                 │
┌────────────────▼─────────────────────────┐
│  ViewModel Layer                         │
│  - @MainActor + @Observable              │
│  - 管理 ViewState + 业务逻辑编排          │
│  - 持有 Service 协议引用                  │
│  - 通过 ModelContext 读写数据              │
└────────────────┬─────────────────────────┘
                 │
┌────────────────▼─────────────────────────┐
│  Service Layer (协议 + 实现)              │
│  - HealthKitServiceProtocol + impl       │
│  - NutritionServiceProtocol + impl       │
│  - CalorieCalculator (enum, 无状态)       │
│  - StreakCalculator (enum, 无状态)        │
└────────────────┬─────────────────────────┘
                 │
┌────────────────▼─────────────────────────┐
│  Data Layer (SwiftData)                  │
│  - DailyRecord, FoodEntry, etc.          │
└──────────────────────────────────────────┘
```

### 2.2 关键架构决策

**`@Observable` 而非 `@ObservableObject`**（iOS 18+）：
- 字段级观察（非对象级），性能更好
- 无 `@Published` 样板代码
- 原生 `@MainActor` 支持
- 注意：不与 `@Model` 类混用（`@Model` 已是 `@Observable`）。ViewModel 不应直接暴露 SwiftData 对象给 View，避免双重观察。

**`@MainActor` ViewModel 约束**：所有 ViewModel 类必须标注 `@MainActor`，Swift 6 严格并发检查下这是必须的。

```swift
@MainActor
@Observable
final class DiaryViewModel { ... }
```

**Service 不使用 `@Observable`**：Service 是纯 I/O 层，不依赖 SwiftUI。ViewModel 调用 Service 后将结果写入自身的 `@Observable` 属性。

**`@Environment` 类型唯一性**：`@Environment` 按类型查找，每种 ViewModel 只能有一个实例。对 3-Tab App 这不是问题，但意味着不能有两个独立的 DiaryView。

### 2.3 数据流

```
用户操作 → View 发消息 → ViewModel 调用 Service → 结果回 ViewModel → UI 更新

日期导航（核心交互）：
  DiaryView 使用水平分页滑动切换日期：
    默认显示「今天」
    → 向右滑 = 昨天
    → 再右滑 = 前天
    → 可一直往回翻

  实现方式：TabView + PageTabViewStyle，或 ScrollView + LazyHStack + scrollTargetBehavior

  日期传播：
    ContentView
      └── DiaryView
            ├── diaryVM.currentDate: Date  // 当前页面显示的日期
            ├── 水平分页容器（每页 = 一个日期）
            │     └── DiaryPageView(date) { record in
            │           ├── CalorieRingCard(record)
            │           ├── NutritionCards(record)
            │           ├── ExerciseCard(record)
            │           └── WaterCard(record)
            │         }
            └── 滑动时 currentDate 实时更新

  日期切换时 → ModelContext.fetch(DailyRecord for date) → 该页内容刷新
```

**具体例子（添加食物）**：
```
用户输入文字 → AddFoodView
  → AddFoodViewModel.recognizeFood(text)
    → AINutritionService.recognizeFood(text) → Anthropic API
      → 返回 [RecognizedFood]
  → ViewModel 展示结果列表
  
用户选好食物点完成
  → AddFoodViewModel.commit(selectedFoods, mealType)
    → 创建 FoodEntry 对象 → 关联 DailyRecord → ModelContext.insert + save
  → 关闭 Sheet，DiaryView 自动刷新
```

### 2.4 ViewModel 清单

| ViewModel | 职责 | 持有的 Service |
|-----------|------|---------------|
| `DiaryViewModel` | 日记主页状态、滑动日期切换、预加载相邻日期、fetch-or-create DailyRecord | HealthKitService, CalorieCalculator |
| `NutritionCardsViewModel` | 三餐卡片状态、食物列表展示 | — |
| `WaterCardViewModel` | 水杯切换、计数 | — |
| `ExerciseCardViewModel` | 步数、运动方块、手动添加运动 | HealthKitService |
| `AddFoodViewModel` | AI 识别、购物车、收藏入库 | AINutritionService |
| `RecipeViewModel` | 收藏列表、搜索过滤、编辑/删除 | — |
| `ProfileViewModel` | 目标进度、Streak、设置读写 | HealthKitService, StreakCalculator |
| `OnboardingViewModel` | 首次引导流程 | HealthKitService |

### 2.5 错误处理 & ViewState

所有数据加载视图使用统一的 ViewState 模式：

```swift
enum ViewState<T> {
    case idle
    case loading
    case loaded(T)
    case error(String)
}
```

**每个 View 的状态**：

| View | 状态 |
|------|------|
| DiaryView | loading（HealthKit 同步中）, empty（今天无数据）, partial（部分餐有记录）, full |
| AddFoodView | initial, aiLoading, aiResults, aiError, cartEmpty, cartFilled |
| RecipeView | empty（无收藏）, populated, searchActive, searchNoResults |
| ProfileView | loading（首次 HealthKit 读取）, loaded, needsSetup（无 UserProfile） |

### 2.6 ViewModel 注入方式

```swift
// LifeCultivationApp.swift
@main
struct LifeCultivationApp: App {
    @State private var diaryVM = DiaryViewModel()
    @State private var recipeVM = RecipeViewModel()
    @State private var profileVM = ProfileViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(diaryVM)
                .environment(recipeVM)
                .environment(profileVM)
        }
        .modelContainer(sharedModelContainer)
    }
}
```

View 中获取：
```swift
@Environment(DiaryViewModel.self) private var viewModel
```

### 2.7 服务协议抽象

所有 Service 定义协议，ViewModel 依赖协议而非具体实现：

```swift
protocol HealthKitServiceProtocol {
    func requestAuthorization() async throws
    func fetchRestingEnergy(from start: Date, to end: Date) async throws -> Double?
    func fetchActiveEnergy(from start: Date, to end: Date) async throws -> Double?
    func fetchWeight(for date: Date) async throws -> Double?
    func fetchHeight() async throws -> Double?
    func fetchAge() async throws -> Int?
    func fetchStepCount(from start: Date, to end: Date) async throws -> Int?
    func fetchWorkouts(from start: Date, to end: Date) async throws -> [HealthKitWorkout]
    func backfillEnergyData(days: Int) async throws -> [Date: (resting: Double?, active: Double?)]
    func saveWeight(_ weightKg: Double, date: Date) async throws
}

protocol NutritionServiceProtocol {
    func recognizeFood(description: String, imageData: Data?) async throws -> [RecognizedFood]
    func suggestNutrition(foodName: String, serving: String) async throws -> [NutritionSuggestion]
}
```

> 好处：单元测试可用 mock 实现；SwiftUI Preview 不依赖真实 HealthKit；未来切换 AI 服务商不影响上层代码。

---

## 3. 服务设计

### 3.1 HealthKitService

```swift
final class HealthKitService: HealthKitServiceProtocol {
    private let healthStore = HKHealthStore()

    func requestAuthorization() async throws

    // 注意：HK 的 restingEnergy / activeEnergy 是 cumulative 量，
    // 必须传日期范围做 statistics query 求和，而非单点读取
    func fetchRestingEnergy(from start: Date, to end: Date) async throws -> Double?
    func fetchActiveEnergy(from start: Date, to end: Date) async throws -> Double?
    func fetchStepCount(from start: Date, to end: Date) async throws -> Int?

    func fetchWeight(for date: Date) async throws -> Double?
    func fetchHeight() async throws -> Double?
    func fetchAge() async throws -> Int?
    func fetchWorkouts(from start: Date, to end: Date) async throws -> [HealthKitWorkout]

    // 体重写回 HealthKit（用户手动输入时）
    func saveWeight(_ weightKg: Double, date: Date) async throws

    // 回溯填充最近 N 天的能量数据
    func backfillEnergyData(days: Int = 7) async throws -> [Date: (resting: Double?, active: Double?)]
}

// 返回 DTO，不返回 @Model 对象
struct HealthKitWorkout {
    let type: ExerciseType
    let duration: TimeInterval
    let calories: Double
    let distance: Double?
    let date: Date
}
```

**权限类型**：
| 数据 | HKQuantityTypeIdentifier |
|------|--------------------------|
| 静息消耗 | `.restingEnergyBurned` |
| 活动消耗 | `.activeEnergyBurned` |
| 体重（读/写） | `.bodyMass` |
| 身高 | `.height` |
| 步数 | `.stepCount` |
| 出生日期 | `.dateOfBirth` (characteristic) |
| 生物性别 | `.biologicalSex` (characteristic) |
| 运动 | `.workoutType()` |

> **Apple Watch 数据延迟**：Watch 数据异步同步到 HealthKit。Phase 1 依赖手动刷新或 App 重新打开获取最新数据。后续可通过 `HKObserverQuery` + 后台推送获取实时更新。

> **Mifflin-St Jeor 公式当前仅支持男性**（`+ 5`）。女性公式为 `- 161`。后续如需支持女性用户，从 HealthKit 读取 `.biologicalSex` 即可判断。

### 3.2 AINutritionService

```swift
final class AINutritionService: NutritionServiceProtocol {
    private var apiKey: String?
    private var baseURL: String  // default: "https://api.anthropic.com"
    private var model: String    // default: "claude-sonnet-4-6"

    func recognizeFood(description: String, imageData: Data? = nil) async throws -> [RecognizedFood]
    func suggestNutrition(foodName: String, serving: String) async throws -> [NutritionSuggestion]
}
```

**API 调用方式**（Anthropic Messages API）：

```
POST {baseURL}/v1/messages
Headers:
  x-api-key: {apiKey}
  anthropic-version: 2023-06-01

Body:
{
  "model": "{model}",            // 可配置
  "max_tokens": 1024,
  "system": [
    {
      "type": "text",
      "text": "你是一个营养师。根据用户描述...返回JSON...",
      "cache_control": {"type": "ephemeral"}  // prompt caching 降成本
    }
  ],
  "messages": [
    {"role": "user", "content": "两个包子一碗胡辣汤"}
  ]
}
```

**⚠️ 响应验证层（必须实现）**：

AI 返回可能包含异常值，Service 层必须做校验：

```swift
func validate(_ foods: [RecognizedFood]) -> [RecognizedFood] {
    foods.filter { food in
        food.calories > 0 &&
        food.calories < 3000 &&      // 单种食物不超过 3000kcal
        (food.protein ?? 0) >= 0 &&
        (food.fat ?? 0) >= 0 &&
        (food.carbs ?? 0) >= 0 &&
        !food.name.isEmpty
    }
}
```

**⚠️ 防重复请求**：ViewModel 在发起识别后立即设置 `viewState = .aiLoading`，识别按钮 disabled，避免双击产生双重计费。

**⚠️ 图片预处理（Phase 2 注意）**：Anthropic API 图片以 base64 传输，token 消耗与分辨率正相关。上传前 resize 到约 512px。

**⚠️ API Key 存储**：MVP 阶段存 SwiftData（明文），后续应迁移到 Keychain。

### 3.3 CalorieCalculator

```swift
enum CalorieCalculator {
    /// Mifflin-St Jeor 公式 — 男性（当前实现）
    static func bmr(weightKg: Double, heightCm: Double, age: Int) -> Double {
        10 * weightKg + 6.25 * heightCm - 5 * Double(age) + 5
    }

    /// 无 Watch 时的活动消耗估算
    static func estimatedActiveEnergy(bmr: Double, level: ActivityLevel) -> Double {
        bmr * level.coefficient - bmr
    }

    /// TDEE
    static func tdee(resting: Double, active: Double) -> Double {
        resting + active
    }

    /// MET 运动消耗估算
    static func exerciseCalories(met: Double, weightKg: Double, minutes: Double) -> Double {
        met * weightKg * (minutes / 60.0)
    }

    /// 步数 → 距离
    static func distance(steps: Int) -> Double {
        Double(steps) * 0.7 / 1000.0
    }
}
```

### 3.4 StreakCalculator

```swift
enum StreakCalculator {
    /// 连续记录天数（至少有一条 FoodEntry）
    static func recordingStreak(records: [DailyRecord]) -> Int

    /// 连续达标天数（netCalories <= 0）
    static func goalMetStreak(records: [DailyRecord]) -> Int
}
```

从今天往回数，找到第一个不满足条件的天即停止。

---

## 4. 视图结构

### 4.1 整体导航

```
ContentView (TabView)
├── Tab 0: DiaryView (日记)
│   └── NavigationStack
│       └── 水平分页容器（每页=一天）
│           └── DiaryPageView(date)
│               ├── CalorieRingCard
│               │   └── ℹ️ → NutritionDetailView (sheet)
│               ├── NutritionCards（早餐/午餐/晚餐/小吃）
│               │   ├── 食物列表（swipe-to-delete）
│               │   └── ＋ → AddFoodView (sheet, 预填 MealType)
│               ├── ExerciseCard
│               │   ├── 步数进度条
│               │   ├── 运动方块（tap 编辑, long-press 删除）
│               │   └── ＋ → AddExerciseView (sheet)
│               └── WaterCard（杯子网格, tap 切换）
│
├── Tab 1: RecipeView (食谱)
│   └── NavigationStack
│       ├── SearchBar + CategoryFilter
│       ├── FavoriteFoodList
│       │   └── tap → ActionSheet [编辑｜选餐添加｜删除]
│       │       └── 编辑 → FoodEditView (sheet)
│       │       └── 选餐 → 弹出 MealType 选择 → 加入 DiaryView
│       └── ＋AI → AddFoodView (sheet, 结果自动收藏)
│
└── Tab 2: ProfileView (个人资料)
    └── NavigationStack
        ├── ProgressCard（目标体重进度条）
        ├── StreakCard（记录天数 + 达标天数）
        ├── GoalsCard（可编辑目标）
        ├── WeightEntryCard（手动录入体重）
        └── SettingsCard
            ├── 活动系数 Picker
            ├── 身高 / 年龄（只读，来自 HealthKit 或手动输入）
            ├── 每日饮水目标 Stepper
            ├── API Key (SecureField)
            ├── API Base URL (TextField)
            ├── [导出数据]
            └── [清除所有记录]
```

### 4.2 关键视图说明

#### DiaryView（日记主页）

- **水平分页滑动**切换日期：
  - 默认定位在「今天」
  - 向右滑动 → 昨天 → 前天 → 可一直往历史翻
  - 顶部显示当前页日期（如「6月13日 · 周六」）
  - 实现：`ScrollView(.horizontal)` + `LazyHStack` + `.scrollTargetBehavior(.paging)`，或 `TabView` + `.tabViewStyle(.page)`
- `DiaryViewModel.currentDate` 跟随滑动实时更新
- ViewModel 预加载当前页 ±1 天的 DailyRecord，滑动时无白屏
- 每个日期页内是垂直滚动的卡片列表（热量圆环 + 三餐 + 运动 + 水分）
- 食物列表项支持 **swipe-to-delete**

#### NutritionDetailView（点击 ℹ️ 进入）
- 净热量趋势：今日 vs 昨日 vs 本周平均
- 三餐热量分布饼图（Swift Charts）
- 碳水/蛋白/脂肪详细数值

#### AddFoodView（添加食物，Sheet）
- 三 tab 切换：搜索 / 输入 / 相机（Phase 2）
- 搜索 tab：搜索收藏食物，点击 `+` 加入购物车
- 输入 tab：文字框 → AI 识别（按钮点击后立即 disabled + loading → 防重复请求）→ 结果列表 + 收藏按钮
- 底部购物车：已选食物 + 合计热量 + 完成按钮

#### AddExerciseView（添加运动，Sheet）
- 运动类型选择网格
- 距离型运动：填距离 → MET 公式估算热量
- 时间型运动：填时长 → MET 估算热量

#### OnboardingView（首次引导）
- 请求 HealthKit 权限
- 读取/输入身高、年龄
- 选择活动系数
- 设置目标体重
- 填写 API Key

#### ProfileView / WeightEntryCard
- 显示最新体重（HealthKit 或手动），来源标识
- 手动录入：TextField + 保存按钮
- 保存时 → 写入 HealthKit + 写入当前日期的 DailyRecord

---

## 5. HealthKit 数据策略

### 5.1 权限请求时机

App 首次启动 → OnboardingView 引导 → 请求 HealthKit 权限 → 进入主页

### 5.2 回溯填充逻辑

```
用户打开 App
  → 检查最近 7 天 DailyRecord 的 restingEnergy 是否为空
  → 从 HealthKit 批量读取：HKStatisticsCollectionQuery(.cumulativeSum, interval: 1 day)
  → 填充到已有 DailyRecord 中
  → 对于没有 DailyRecord 的日期不创建空记录
```

### 5.3 无 Apple Watch 降级

```
restingEnergy:
  有 HK restingEnergy → 使用 HealthKit 值
  无 → CalorieCalculator.bmr(height, weight, age)

activeEnergy:
  有 HK activeEnergy → 使用 HealthKit 值
  无 → CalorieCalculator.estimatedActiveEnergy(bmr, activityLevel)
```

### 5.4 体重回写

用户手动输入体重时，同时：
1. 写入 HealthKit → `HKQuantityType(.bodyMass)` — 其他 App 可用
2. 更新当前日期的 `DailyRecord.weight`

---

## 6. 迁移策略（关键）

### 6.1 SwiftData 旧 Schema 处理

v1 的 SwiftData store 与 v2 schema 不兼容。必须处理迁移，否则首次启动 crash：

```swift
var sharedModelContainer: ModelContainer = {
    let schema = Schema([DailyRecord.self, FoodEntry.self, ...])
    // 使用新的 store 文件名，避免与 v1 冲突
    let storeURL = URL.applicationSupportDirectory
        .appending(path: "LifeCultivation-v2.store")
    let config = ModelConfiguration(schema: schema, url: storeURL)
    return try ModelContainer(for: schema, configurations: [config])
}()
```

> 用新文件名 `LifeCultivation-v2.store`，v1 的旧 store 不会被读取，自动隔离。
> 不需要数据迁移——v1 是习惯追踪、v2 是减肥记录，数据结构完全不同。

### 6.2 旧视图文件

- 大部分旧视图直接删除
- 可保留用于重构的组件：`ScoreCardView` 的圆环绘制逻辑 → `CalorieRing`
- `DatePickerView` 的日期选择 UI → 不直接复用（需要的是 "今天/昨天/日历" 快捷切换，而非日期范围选择器）

---

## 7. 色彩与设计规范

| 用途 | 颜色 |
|------|------|
| 主色调 | `#FF9500` 暖橙（沿用 v1） |
| 达标/预算内 | 绿色（`Color.green`） |
| 超标/警告 | 红色（`Color.red`） |
| 卡片背景 | `Color(.systemBackground)` |
| 卡片圆角 | 15pt |
| 卡片阴影 | `gray.opacity(0.2), radius: 5` |
| 三餐标签色 | 早餐-黄 / 午餐-橙 / 晚餐-紫 / 小吃-灰 |

```
早餐 #FFD60A  午餐 #FF9500  晚餐 #AF52DE  小吃 #8E8E93
```

---

## 8. 验证清单

- [ ] 数据模型覆盖 PRD 所有功能场景
- [ ] `@Attribute(.unique)` 防止同日重复 DailyRecord
- [ ] `height`/`age`/`activityLevel` 在 UserProfile 而非 DailyRecord
- [ ] Service 有协议抽象，ViewModel 依赖协议
- [ ] 所有 ViewModel 标注 `@MainActor`
- [ ] AI 响应验证层（过滤异常值）
- [ ] 防重复请求（识别按钮 loading 态 disabled）
- [ ] HealthKit cumulative quantity 用 statistics query（非单点读取）
- [ ] 无 Watch 时降级到公式计算正确
- [ ] 体重手动输入 → 写回 HealthKit
- [ ] 新 store 文件名，不与 v1 冲突
- [ ] Anthropic API 通过 baseURL 兼容第三方
- [ ] NutritionDetailView（ℹ️ 详情页）在视图层次中
- [ ] OnboardingView（引导流程）在视图层次中
- [ ] selectedDate 传播路径明确
- [ ] 每个 View 有明确的 ViewState 状态
