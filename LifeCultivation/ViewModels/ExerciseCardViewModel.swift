import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class ExerciseCardViewModel {
    private let modelContainer: ModelContainer
    private let healthKitService: HealthKitServiceProtocol
    var context: ModelContext { modelContainer.mainContext }

    var stepCount: Int = 0
    var stepGoal: Int = 10000
    var exercises: [ExerciseEntry] = []
    var showAddExercise = false
    var editingExercise: ExerciseEntry?

    init(modelContainer: ModelContainer, healthKitService: HealthKitServiceProtocol) {
        self.modelContainer = modelContainer
        self.healthKitService = healthKitService
    }

    func load(from record: DailyRecord, profile: UserProfile?) {
        stepCount = record.stepCount
        stepGoal = profile?.stepGoal ?? 10000
        exercises = record.exercises ?? []
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
        to date: Date
    ) {
        let met = type.met
        let wt = weight ?? 70.0
        let calories = CalorieCalculator.exerciseCalories(met: met, weightKg: wt, minutes: duration / 60)

        let entry = ExerciseEntry(
            exerciseType: type,
            duration: duration,
            calories: calories,
            distance: distance,
            source: .manual
        )
        let record = fetchOrCreateRecord(for: date)
        entry.dailyRecord = record
        context.insert(entry)
        try? context.save()

        if record.activeEnergy == nil {
            record.activeEnergy = 0
        }
        record.activeEnergy! += calories
        try? context.save()

        exercises = record.exercises ?? []
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
