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
    case done
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
    var activityLevel: ActivityLevel = .light
    var targetWeight: Double = 70
    var apiKey: String = ""
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
            if let h = hkHeight { height = h }
            if let a = hkAge { age = a }
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
        profile.activityLevel = activityLevel
        profile.targetWeight = targetWeight == 0 ? nil : targetWeight
        if !apiKey.isEmpty {
            profile.apiKey = apiKey
        }
        if !baseURL.isEmpty {
            profile.apiBaseURL = baseURL
        }
        try? context.save()
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
    }
}
