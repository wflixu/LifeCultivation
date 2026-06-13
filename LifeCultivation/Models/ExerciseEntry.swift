import Foundation
import SwiftData

@Model
final class ExerciseEntry {
    var id: UUID = UUID()
    var exerciseType: ExerciseType = ExerciseType.other
    var duration: TimeInterval = 0
    var calories: Double = 0
    var distance: Double?
    var source: ExerciseSource = ExerciseSource.manual
    var timestamp: Date = Date()

    @Relationship(inverse: \DailyRecord.exercises) var dailyRecord: DailyRecord?

    init(
        exerciseType: ExerciseType,
        duration: TimeInterval,
        calories: Double,
        distance: Double? = nil,
        source: ExerciseSource = .manual
    ) {
        self.exerciseType = exerciseType
        self.duration = duration
        self.calories = calories
        self.distance = distance
        self.source = source
        self.timestamp = Date()
    }
}
