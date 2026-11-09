import Foundation
import SwiftData
import SwiftUI

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case healthKit
    case profile
    case activityLevel
    case targetWeight
    case apiKey
}

@MainActor
@Observable
final class OnboardingViewModel {
    private let modelContainer: ModelContainer
    private let healthKitService: HealthKitServiceProtocol
    var context: ModelContext { modelContainer.mainContext }

    var currentStep: OnboardingStep = .welcome
    var height: Double = 175
    var age: Int = 30
    var weight: Double = 70
    var gender: Gender = .male
    var activityLevel: ActivityLevel = .light
    var targetWeight: Double = 70
    var apiKey: String = ""
    /// Empty means "use the dev-config/default endpoint".
    var baseURL: String = ""
    var healthKitDenied = false

    init(modelContainer: ModelContainer, healthKitService: HealthKitServiceProtocol) {
        self.modelContainer = modelContainer
        self.healthKitService = healthKitService
    }

    func requestHealthKit() async -> Bool {
        do {
            try await healthKitService.requestAuthorization()
            // Read actual data after authorization
            let hkHeight = try? await healthKitService.fetchHeight()
            let hkAge = try? await healthKitService.fetchAge()
            // HealthKit height is in meters; the profile stores centimeters.
            if let h = hkHeight { height = h * 100 }
            if let a = hkAge { age = a }
            if let w = try? await healthKitService.fetchLatestWeight() { weight = w }
            return true
        } catch {
            healthKitDenied = true
            return false
        }
    }

    func finishOnboarding() {
        let profile = UserProfile.fetchOrCreate(context: context)
        profile.height = height
        profile.age = age
        profile.gender = gender
        profile.activityLevel = activityLevel
        profile.targetWeight = targetWeight == 0 ? nil : targetWeight
        if weight > 0 {
            profile.latestWeight = weight
            if profile.startWeight == nil { profile.startWeight = weight }
        }
        if !apiKey.isEmpty {
            profile.apiKey = apiKey
        }
        if !baseURL.isEmpty {
            profile.apiBaseURL = baseURL
        }

        if weight > 0 {
            let today = Calendar.current.startOfDay(for: Date())
            let descriptor = FetchDescriptor<DailyRecord>(predicate: #Predicate { $0.date == today })
            let record: DailyRecord
            if let existing = try? context.fetch(descriptor).first {
                record = existing
            } else {
                record = DailyRecord(date: today)
                context.insert(record)
            }
            record.weight = weight
        }

        try? context.save()
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
    }
}
