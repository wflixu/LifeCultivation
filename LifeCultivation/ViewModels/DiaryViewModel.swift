import Foundation
import SwiftData
import SwiftUI

@MainActor
@Observable
final class DiaryViewModel {
    private let modelContainer: ModelContainer
    private let healthKitService: HealthKitServiceProtocol
    var context: ModelContext { modelContainer.mainContext }

    var currentDate: Date = Calendar.current.startOfDay(for: Date())
    var records: [Date: DailyRecord] = [:]
    var viewState: ViewState<DailyRecord> = .idle

    // Navigation
    var showDatePicker = false
    var showNutritionDetail = false

    init(modelContainer: ModelContainer, healthKitService: HealthKitServiceProtocol) {
        self.modelContainer = modelContainer
        self.healthKitService = healthKitService
        Task { await loadToday() }
        observeMidnight()
    }

    private func observeMidnight() {
        NotificationCenter.default.addObserver(
            forName: .NSCalendarDayChanged,
            object: nil,
            queue: .main
        ) { @Sendable [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let today = Calendar.current.startOfDay(for: Date())
                if today != self.currentDate {
                    self.currentDate = today
                    _ = self.fetchOrCreateRecord(for: today)
                    self.preloadAdjacentDays(for: today)
                    await self.syncHealthKitForToday()
                }
            }
        }
    }

    func fetchOrCreateRecord(for date: Date) -> DailyRecord {
        let dayStart = Calendar.current.startOfDay(for: date)
        if let cached = records[dayStart] { return cached }

        let descriptor = FetchDescriptor<DailyRecord>(predicate: #Predicate {
            $0.date == dayStart
        })
        if let existing = try? context.fetch(descriptor).first {
            records[dayStart] = existing
            return existing
        }
        let record = DailyRecord(date: dayStart)
        context.insert(record)
        try? context.save()
        records[dayStart] = record
        return record
    }

    func preloadAdjacentDays(for date: Date) {
        let calendar = Calendar.current
        for offset in -1...1 {
            guard let d = calendar.date(byAdding: .day, value: offset, to: date) else { continue }
            _ = fetchOrCreateRecord(for: d)
        }
    }

    func onDateChanged(_ newDate: Date) {
        currentDate = Calendar.current.startOfDay(for: newDate)
        preloadAdjacentDays(for: currentDate)
        Task { await syncHealthKitForCurrentDate() }
    }

    func syncHealthKitForCurrentDate() async {
        let record = fetchOrCreateRecord(for: currentDate)
        let start = currentDate
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!

        if record.stepCount == 0 {
            if let steps = try? await healthKitService.fetchStepCount(from: start, to: end) {
                record.stepCount = steps
            }
        }
        if record.restingEnergy == nil {
            if let re = try? await healthKitService.fetchRestingEnergy(from: start, to: end), re > 0 {
                record.restingEnergy = re
            }
        }
        if record.activeEnergy == nil {
            if let ae = try? await healthKitService.fetchActiveEnergy(from: start, to: end), ae > 0 {
                record.activeEnergy = ae
            }
        }
        try? context.save()
    }

    func syncHealthKitForToday() async {
        await syncHealthKitForCurrentDate()
    }

    func backfillHealthKitData() async {
        let energyData = (try? await healthKitService.backfillEnergyData(days: 7)) ?? [:]
        var needsSave = false
        for (date, (resting, active)) in energyData {
            let record = fetchOrCreateRecord(for: date)
            if record.restingEnergy == nil, let re = resting, re > 0 {
                record.restingEnergy = re
                needsSave = true
            }
            if record.activeEnergy == nil, let ae = active, ae > 0 {
                record.activeEnergy = ae
                needsSave = true
            }
        }
        if needsSave { try? context.save() }
    }

    private func loadToday() async {
        _ = fetchOrCreateRecord(for: currentDate)
        preloadAdjacentDays(for: currentDate)
        await backfillHealthKitData()
        await syncHealthKitForToday()
        if let record = records[currentDate] {
            viewState = .loaded(record)
        }
    }
}
