import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class ExerciseCardViewModel {
    private let modelContainer: ModelContainer
    private let healthKitService: HealthKitServiceProtocol
    private let nutritionService: NutritionServiceProtocol
    var context: ModelContext { modelContainer.mainContext }

    var stepCount: Int = 0
    var stepGoal: Int = 10000
    var exercises: [ExerciseEntry] = []
    var showAddExercise = false
    var editingExercise: ExerciseEntry?
    var userWeight: Double = 70  // default fallback, populated from record/profile

    init(modelContainer: ModelContainer, healthKitService: HealthKitServiceProtocol, nutritionService: NutritionServiceProtocol) {
        self.modelContainer = modelContainer
        self.healthKitService = healthKitService
        self.nutritionService = nutritionService
    }

    func load(from record: DailyRecord, profile: UserProfile?) {
        stepCount = record.stepCount
        stepGoal = profile?.stepGoal ?? 10000
        exercises = record.exercises ?? []
        // Read weight: record.weight first, fallback to 70
        if let w = record.weight, w > 0 {
            userWeight = w
        }
    }

    func fetchStepsAndWorkouts(for date: Date) async {
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!

        if let steps = try? await healthKitService.fetchStepCount(from: start, to: end) {
            stepCount = steps
            let record = fetchOrCreateRecord(for: date)
            record.stepCount = steps
            try? context.save()
        }
    }

    func addManualExercise(
        _ type: ExerciseType,
        duration: TimeInterval,
        distance: Double?,
        weight: Double?,
        to date: Date,
        calorieSource: CalorieSource = .met,
        manualCalories: Double? = nil,
        intensity: String? = nil
    ) {
        let calories: Double
        switch calorieSource {
        case .manual:
            calories = manualCalories ?? 0
        case .ai, .met:
            let met = type.met
            let wt = weight ?? userWeight
            calories = CalorieCalculator.exerciseCalories(met: met, weightKg: wt, minutes: duration / 60)
        }

        let entry = ExerciseEntry(
            exerciseType: type,
            duration: duration,
            calories: calories,
            distance: distance,
            source: .manual,
            calorieSource: calorieSource,
            intensity: intensity
        )
        let record = fetchOrCreateRecord(for: date)
        entry.dailyRecord = record
        context.insert(entry)
        try? context.save()

        exercises = record.exercises ?? []
    }

    func estimateExerciseCalories(
        type: ExerciseType,
        duration: TimeInterval,
        intensity: String
    ) async throws -> Double {
        let minutes = duration / 60
        let description = "\(type.rawValue)，\(Int(minutes))分钟，强度：\(intensity)"
        return try await nutritionService.estimateExerciseCalories(description: description)
    }

    func deleteExercise(_ entry: ExerciseEntry) {
        context.delete(entry)
        try? context.save()
    }

    private func fetchOrCreateRecord(for date: Date) -> DailyRecord {
        let dayStart = Calendar.current.startOfDay(for: date)
        let descriptor = FetchDescriptor<DailyRecord>(predicate: #Predicate { $0.date == dayStart })
        if let existing = try? context.fetch(descriptor).first { return existing }
        let record = DailyRecord(date: dayStart)
        context.insert(record)
        try? context.save()
        return record
    }
}
