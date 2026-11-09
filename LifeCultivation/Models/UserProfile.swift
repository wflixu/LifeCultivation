import Foundation
import SwiftData

@Model
final class UserProfile {
    var targetWeight: Double?
    var dailyWaterTarget: Double = 2.0
    var stepGoal: Int = 10000
    var activityLevel: ActivityLevel = ActivityLevel.light
    var height: Double?
    var age: Int?
    var apiKey: String?
    var apiBaseURL: String?
    var aiModel: String?
    /// Cached most recent weight, used when a day has no weight reading of its own.
    var latestWeight: Double?
    /// Weight at the start of the current goal, used for progress calculation.
    var startWeight: Double?
    var genderRawValue: String = Gender.male.rawValue

    @Transient
    var gender: Gender {
        get { Gender(rawValue: genderRawValue) ?? .male }
        set { genderRawValue = newValue.rawValue }
    }

    init() {}

    static func fetchOrCreate(context: ModelContext) -> UserProfile {
        var descriptor = FetchDescriptor<UserProfile>()
        descriptor.fetchLimit = 1
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let profile = UserProfile()
        context.insert(profile)
        try? context.save()
        return profile
    }
}
