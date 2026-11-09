import SwiftUI

struct GoalsCard: View {
    @Bindable var vm: ProfileViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("目标设置")
                .font(.headline)

            if let profile = vm.userProfile {
                genderPicker(profile)
                Divider()
                activityLevelPicker(profile)
                Divider()
                heightAgeRow(profile)
                Divider()
                stepperRow(
                    label: "每日饮水量",
                    value: Binding(
                        get: { profile.dailyWaterTarget },
                        set: { profile.dailyWaterTarget = $0; vm.saveProfile() }
                    ),
                    range: 0.5...5.0,
                    step: 0.25,
                    format: "%.2f L"
                )
                Divider()
                stepperRow(
                    label: "每日步数目标",
                    value: Binding(
                        get: { Double(profile.stepGoal) },
                        set: { profile.stepGoal = Int($0); vm.saveProfile() }
                    ),
                    range: 1000...50000,
                    step: 1000,
                    format: "%.0f"
                )
            }
        }
        .padding(20)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .appCardShadow()
    }

    private func activityLevelPicker(_ profile: UserProfile) -> some View {
        Picker("活动系数", selection: Binding(
            get: { profile.activityLevel },
            set: { profile.activityLevel = $0; vm.saveProfile() }
        )) {
            ForEach(ActivityLevel.allCases, id: \.self) { level in
                Text("\(level.rawValue) (\(String(format: "%.2f", level.coefficient)))")
                    .tag(level)
            }
        }
    }

    private func genderPicker(_ profile: UserProfile) -> some View {
        Picker("性别", selection: Binding(
            get: { profile.gender },
            set: { profile.gender = $0; vm.saveProfile() }
        )) {
            ForEach(Gender.allCases, id: \.self) { gender in
                Text(gender.rawValue).tag(gender)
            }
        }
    }

    private func heightAgeRow(_ profile: UserProfile) -> some View {
        Group {
            HStack {
                Text("身高 (cm)")
                Spacer()
                TextField("175", value: Binding(
                    get: { profile.height ?? 175 },
                    set: { profile.height = $0; vm.saveProfile() }
                ), format: .number)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            }

            HStack {
                Text("年龄")
                Spacer()
                TextField("30", value: Binding(
                    get: { Double(profile.age ?? 30) },
                    set: { profile.age = Int($0); vm.saveProfile() }
                ), format: .number)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
            }
        }
    }

    private func stepperRow(label: String, value: Binding<Double>, range: ClosedRange<Double>, step: Double, format: String) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(String(format: format, value.wrappedValue))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(AppColors.primary)
            Stepper("", value: value, in: range, step: step)
                .labelsHidden()
        }
    }
}
