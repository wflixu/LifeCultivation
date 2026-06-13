import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class ProfileViewModel {
    private let modelContainer: ModelContainer
    private let healthKitService: HealthKitServiceProtocol
    var context: ModelContext { modelContainer.mainContext }

    var userProfile: UserProfile?
    var latestWeight: Double?
    var recordingStreak: Int = 0
    var goalMetStreak: Int = 0
    var currentWeight: Double?
    var targetWeight: Double?
    var showSettingsSheet = false

    init(modelContainer: ModelContainer, healthKitService: HealthKitServiceProtocol) {
        self.modelContainer = modelContainer
        self.healthKitService = healthKitService
    }

    func loadProfile() {
        userProfile = UserProfile.fetchOrCreate(context: context)
        loadHealthKitData()
        updateStreaks()
    }

    private func loadHealthKitData() {
        Task {
            if let height = try? await healthKitService.fetchHeight() {
                userProfile?.height = height
            }
            if let age = try? await healthKitService.fetchAge() {
                userProfile?.age = age
            }
            if let weight = try? await healthKitService.fetchWeight(for: Date()) {
                latestWeight = weight
            }
            try? context.save()
        }
    }

    func saveWeight(_ weightKg: Double) {
        // Write to today's DailyRecord (scale syncs weight to HealthKit, read-only here)
        let today = Calendar.current.startOfDay(for: Date())
        let descriptor = FetchDescriptor<DailyRecord>(predicate: #Predicate { $0.date == today })
        let record: DailyRecord
        if let existing = try? context.fetch(descriptor).first {
            record = existing
        } else {
            record = DailyRecord(date: today)
            context.insert(record)
        }
        record.weight = weightKg
        try? context.save()
        latestWeight = weightKg
    }

    func saveProfile() {
        try? context.save()
    }

    func updateStreaks() {
        let descriptor = FetchDescriptor<DailyRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let records = (try? context.fetch(descriptor)) ?? []
        recordingStreak = StreakCalculator.recordingStreak(records: records)
        goalMetStreak = StreakCalculator.goalMetStreak(records: records)
    }

    func loadWeightProgress() {
        targetWeight = userProfile?.targetWeight
        if latestWeight == nil {
            Task {
                latestWeight = try? await healthKitService.fetchWeight(for: Date())
            }
        }
    }

    func exportData() -> Data? {
        let descriptor = FetchDescriptor<DailyRecord>(
            sortBy: [SortDescriptor(\.date, order: .forward)]
        )
        guard let records = try? context.fetch(descriptor) else { return nil }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try? encoder.encode(records.map { record in
            ExportDailyRecord(
                date: record.date,
                weight: record.weight,
                restingEnergy: record.restingEnergy,
                activeEnergy: record.activeEnergy,
                totalIntake: record.totalIntake,
                netCalories: record.netCalories,
                waterCups: record.waterCups,
                stepCount: record.stepCount,
                foods: (record.foods ?? []).map {
                    ExportFoodEntry(name: $0.name, calories: $0.calories, serving: $0.serving,
                                    mealType: $0.mealType?.rawValue, protein: $0.protein, fat: $0.fat, carbs: $0.carbs)
                },
                exercises: (record.exercises ?? []).map {
                    ExportExerciseEntry(type: $0.exerciseType.rawValue, duration: $0.duration,
                                        calories: $0.calories, distance: $0.distance)
                }
            )
        })
    }
}

// MARK: - Export DTOs

struct ExportDailyRecord: Codable {
    let date: Date
    let weight: Double?
    let restingEnergy: Double?
    let activeEnergy: Double?
    let totalIntake: Double
    let netCalories: Double
    let waterCups: Int
    let stepCount: Int
    let foods: [ExportFoodEntry]
    let exercises: [ExportExerciseEntry]
}

struct ExportFoodEntry: Codable {
    let name: String
    let calories: Double
    let serving: String
    let mealType: String?
    let protein: Double?
    let fat: Double?
    let carbs: Double?
}

struct ExportExerciseEntry: Codable {
    let type: String
    let duration: TimeInterval
    let calories: Double
    let distance: Double?
}
