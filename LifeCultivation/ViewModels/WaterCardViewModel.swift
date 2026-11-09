import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class WaterCardViewModel {
    private let modelContainer: ModelContainer
    var context: ModelContext { modelContainer.mainContext }

    var currentCups: Int = 0
    var targetCups: Int = 8

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func load(from record: DailyRecord, profile: UserProfile?) {
        currentCups = record.waterCups
        targetCups = Int((profile?.dailyWaterTarget ?? 2.0) / 0.25)
    }

    func setCups(_ value: Int, record: DailyRecord) {
        // Clicking the N-th bar toggles between N and N-1
        if value == currentCups {
            record.waterCups = max(0, value - 1)
        } else {
            record.waterCups = min(targetCups, value)
        }
        try? context.save()
        currentCups = record.waterCups
    }

    func adjustCups(by delta: Int, record: DailyRecord) {
        record.waterCups = max(0, min(targetCups, record.waterCups + delta))
        try? context.save()
        currentCups = record.waterCups
    }
}
