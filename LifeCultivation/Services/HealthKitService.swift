import Foundation
import HealthKit

// MARK: - DTO

struct HealthKitWorkout: Sendable {
    let type: ExerciseType
    let duration: TimeInterval
    let calories: Double
    let distance: Double?
    let date: Date
}

// MARK: - Protocol

@MainActor
protocol HealthKitServiceProtocol {
    func requestAuthorization() async throws
    func fetchRestingEnergy(from start: Date, to end: Date) async throws -> Double?
    func fetchActiveEnergy(from start: Date, to end: Date) async throws -> Double?
    func fetchWeight(for date: Date) async throws -> Double?
    func fetchLatestWeight() async throws -> Double?
    func fetchHeight() async throws -> Double?
    func fetchAge() async throws -> Int?
    func fetchStepCount(from start: Date, to end: Date) async throws -> Int?
    func fetchWorkouts(from start: Date, to end: Date) async throws -> [HealthKitWorkout]
    func backfillEnergyData(days: Int) async throws -> [Date: (resting: Double?, active: Double?)]
    func saveWeight(_ weightKg: Double, date: Date) async throws
}

// MARK: - Quantity Type Identifiers (iOS 26 uses RawRepresentable)

extension HKQuantityTypeIdentifier {
    static let restingEnergyBurned = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBasalEnergyBurned")
    static let activeEnergyBurned = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierActiveEnergyBurned")
    static let bodyMass = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierBodyMass")
    static let height = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierHeight")
    static let stepCount = HKQuantityTypeIdentifier(rawValue: "HKQuantityTypeIdentifierStepCount")
}

// MARK: - Errors

enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case authorizationDenied
    var errorDescription: String? {
        switch self {
        case .notAvailable: "HealthKit 不可用"
        case .authorizationDenied: "健康数据授权被拒绝"
        }
    }
}

// MARK: - Implementation

final class HealthKitService: HealthKitServiceProtocol {
    let healthStore = HKHealthStore()

    private var readTypes: Set<HKObjectType> {
        let quantityTypes: [HKQuantityTypeIdentifier] = [
            .restingEnergyBurned,
            .activeEnergyBurned,
            .bodyMass,
            .height,
            .stepCount
        ]
        let types = quantityTypes.compactMap { HKObjectType.quantityType(forIdentifier: $0) }
        return Set(types).union([HKObjectType.workoutType()])
    }

    private var writeTypes: Set<HKSampleType> {
        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            return [bodyMass]
        }
        return []
    }

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else {
            throw HealthKitError.notAvailable
        }
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: writeTypes, read: readTypes) { success, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if !success {
                    continuation.resume(throwing: HealthKitError.authorizationDenied)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - Energy

    func fetchRestingEnergy(from start: Date, to end: Date) async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .restingEnergyBurned) else {
            return nil
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return try await fetchCumulativeSum(for: type, predicate: predicate, unit: HKUnit.kilocalorie())
    }

    func fetchActiveEnergy(from start: Date, to end: Date) async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return nil
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return try await fetchCumulativeSum(for: type, predicate: predicate, unit: HKUnit.kilocalorie())
    }

    // MARK: - Weight

    func fetchWeight(for date: Date) async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return nil }
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let samples = try await fetchSamples(for: type, predicate: predicate, limit: 1, sortDescending: true)
        return samples.first?.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
    }

    func fetchLatestWeight() async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return nil }
        let samples = try await fetchSamples(for: type, predicate: nil, limit: 1, sortDescending: true)
        return samples.first?.quantity.doubleValue(for: HKUnit.gramUnit(with: .kilo))
    }

    func saveWeight(_ weightKg: Double, date: Date) async throws {
        guard let type = HKObjectType.quantityType(forIdentifier: .bodyMass) else { return }
        let quantity = HKQuantity(unit: HKUnit.gramUnit(with: .kilo), doubleValue: weightKg)
        let sample = HKQuantitySample(
            type: type,
            quantity: quantity,
            start: date,
            end: date
        )
        try await healthStore.save(sample)
    }

    // MARK: - Height, Age

    func fetchHeight() async throws -> Double? {
        guard let type = HKObjectType.quantityType(forIdentifier: .height) else { return nil }
        let samples = try await fetchSamples(for: type, predicate: nil, limit: 1, sortDescending: true)
        return samples.first?.quantity.doubleValue(for: HKUnit.meter())
    }

    func fetchAge() async throws -> Int? {
        guard let birthday = try? healthStore.dateOfBirthComponents(),
              let date = birthday.date else { return nil }
        return Calendar.current.dateComponents([.year], from: date, to: Date()).year
    }

    // MARK: - Steps

    func fetchStepCount(from start: Date, to end: Date) async throws -> Int? {
        guard let type = HKObjectType.quantityType(forIdentifier: .stepCount) else { return nil }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        return try await fetchCumulativeSum(for: type, predicate: predicate, unit: HKUnit.count()).map { Int($0) }
    }

    // MARK: - Workouts

    func fetchWorkouts(from start: Date, to end: Date) async throws -> [HealthKitWorkout] {
        let nsPredicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let samplePredicate = HKSamplePredicate.workout(nsPredicate)
        let descriptor = HKSampleQueryDescriptor(
            predicates: [samplePredicate],
            sortDescriptors: [SortDescriptor<HKWorkout>(\.startDate, order: .reverse)]
        )
        let workouts = try await descriptor.result(for: healthStore)

        let kcal = HKUnit.kilocalorie()
        let km = HKUnit.meterUnit(with: .kilo)
        let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)
        return workouts.compactMap { w in
            let energy = activeEnergyType
                .flatMap { w.statistics(for: $0)?.sumQuantity()?.doubleValue(for: kcal) }
            return HealthKitWorkout(
                type: mapWorkoutType(w.workoutActivityType),
                duration: w.duration / 60,
                calories: energy ?? 0,
                distance: w.totalDistance?.doubleValue(for: km),
                date: w.startDate
            )
        }
    }

    private func mapWorkoutType(_ type: HKWorkoutActivityType) -> ExerciseType {
        switch type {
        case .running: .running
        case .cycling: .cycling
        case .swimming: .swimming
        case .walking: .walking
        case .traditionalStrengthTraining, .functionalStrengthTraining: .strength
        case .yoga, .mindAndBody: .other
        case .soccer, .basketball, .tennis, .baseball, .volleyball: .ballGames
        default: .other
        }
    }

    // MARK: - Backfill

    func backfillEnergyData(days: Int = 7) async throws -> [Date: (resting: Double?, active: Double?)] {
        var result: [Date: (resting: Double?, active: Double?)] = [:]
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for offset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let nextDay = calendar.date(byAdding: .day, value: 1, to: date)!
            let resting = try? await fetchRestingEnergy(from: date, to: nextDay)
            let active = try? await fetchActiveEnergy(from: date, to: nextDay)
            result[date] = (resting, active)
        }
        return result
    }

    // MARK: - Private helpers

    private func fetchCumulativeSum(
        for type: HKQuantityType,
        predicate: NSPredicate?,
        unit: HKUnit
    ) async throws -> Double? {
        let samplePredicate = HKSamplePredicate.quantitySample(type: type, predicate: predicate)
        let descriptor = HKStatisticsQueryDescriptor(predicate: samplePredicate, options: .cumulativeSum)
        let stats = try await descriptor.result(for: healthStore)
        return stats?.sumQuantity()?.doubleValue(for: unit)
    }

    private func fetchSamples(
        for type: HKQuantityType,
        predicate: NSPredicate?,
        limit: Int? = nil,
        sortDescending: Bool = false
    ) async throws -> [HKQuantitySample] {
        let samplePredicate = HKSamplePredicate.quantitySample(type: type, predicate: predicate)
        let sortOrder: SortOrder = sortDescending ? .reverse : .forward
        let descriptor = HKSampleQueryDescriptor(
            predicates: [samplePredicate],
            sortDescriptors: [SortDescriptor<HKQuantitySample>(\.startDate, order: sortOrder)],
            limit: limit
        )
        return try await descriptor.result(for: healthStore)
    }
}
