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

    func toggleCup(increment: Bool, record: DailyRecord) {
        if increment {
            record.waterCups = min(targetCups, record.waterCups + 1)
        } else {
            record.waterCups = max(0, record.waterCups - 1)
        }
        try? context.save()
        currentCups = record.waterCups
    }
}
