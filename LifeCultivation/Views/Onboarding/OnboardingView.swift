import SwiftUI
import UIKit

struct OnboardingView: View {
    @Bindable var vm: OnboardingViewModel

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                TabView(selection: $vm.currentStep) {
                    welcomeStep.tag(OnboardingStep.welcome)
                    healthKitStep.tag(OnboardingStep.healthKit)
                    profileStep.tag(OnboardingStep.profile)
                    activityStep.tag(OnboardingStep.activityLevel)
                    targetWeightStep.tag(OnboardingStep.targetWeight)
                    apiStep.tag(OnboardingStep.apiKey)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                progressBar
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { dismissKeyboard() }
                }
            }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        let total = Double(OnboardingStep.allCases.count - 1)
        let current = Double(vm.currentStep.rawValue)

        return VStack(spacing: 8) {
            ProgressView(value: current / total)
                .tint(AppColors.primary)
                .padding(.horizontal, 20)
            Text("\(vm.currentStep.rawValue + 1) / \(OnboardingStep.allCases.count)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 16)
        .background(.regularMaterial)
    }

    // MARK: - Steps

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "leaf.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppColors.primary)
            Text("轻迹")
                .font(.largeTitle.weight(.bold))
            Text("AI 赋能的科学减重助手")
                .font(.title3)
                .foregroundStyle(.secondary)
            Text("通过记录饮食、运动和体重，\n科学管理你的健康之路")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            nextButton("开始") { vm.currentStep = .healthKit }
        }
        .padding(32)
    }

    private var healthKitStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.pink)

            Text("连接健康")
                .font(.title2.weight(.bold))

            Text("授权 HealthKit 以自动获取\n步数、能量消耗和体重数据")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            if vm.healthKitDenied {
                Label("健康权限被拒绝，您可以手动输入数据", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(AppColors.primary)
            }

            VStack(spacing: 12) {
                Button {
                    Task { @MainActor in
                        let ok = await vm.requestHealthKit()
                        if ok { vm.currentStep = .profile }
                    }
                } label: {
                    Label("授权 HealthKit", systemImage: "heart.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.pink, in: RoundedRectangle(cornerRadius: 10))
                        .foregroundStyle(.white)
                }

                Button("跳过，手动输入") {
                    vm.healthKitDenied = true
                    vm.currentStep = .profile
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(32)
    }

    private var profileStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "person.fill")
                .font(.system(size: 60))
                .foregroundStyle(.blue)

            Text("基本信息")
                .font(.title2.weight(.bold))

            VStack(spacing: 16) {
                HStack {
                    Text("身高 (cm)")
                    Spacer()
                    TextField("175", value: $vm.height, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .textFieldStyle(.roundedBorder)
                }
                HStack {
                    Text("年龄")
                    Spacer()
                    TextField("30", value: $vm.age, format: .number)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .textFieldStyle(.roundedBorder)
                }
                HStack {
                    Text("当前体重 (kg)")
                    Spacer()
                    TextField("70", value: $vm.weight, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 100)
                        .textFieldStyle(.roundedBorder)
                }
                HStack {
                    Text("性别")
                    Spacer()
                    Picker("性别", selection: $vm.gender) {
                        ForEach(Gender.allCases, id: \.self) { gender in
                            Text(gender.rawValue).tag(gender)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 120)
                }
            }
            .padding(20)
            .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 12))

            nextButton("下一步") { vm.currentStep = .activityLevel }
            Spacer()
        }
        .padding(32)
    }

    private var activityStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "figure.walk")
                .font(.system(size: 60))
                .foregroundStyle(.green)

            Text("活动水平")
                .font(.title2.weight(.bold))

            VStack(spacing: 12) {
                ForEach(ActivityLevel.allCases, id: \.self) { level in
                    Button {
                        vm.activityLevel = level
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(level.rawValue)
                                    .font(.subheadline.weight(.medium))
                                Text(activityDescription(level))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if vm.activityLevel == level {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(AppColors.primary)
                            }
                        }
                        .padding(12)
                        .background(
                            vm.activityLevel == level
                                ? AppColors.primaryLight
                                : Color(.systemGray6),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            nextButton("下一步") { vm.currentStep = .targetWeight }
            Spacer()
        }
        .padding(32)
    }

    private var targetWeightStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "scalemass.fill")
                .font(.system(size: 60))
                .foregroundStyle(.indigo)

            Text("目标体重")
                .font(.title2.weight(.bold))

            Text("设定你的目标体重，我们会追踪进度")
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline) {
                TextField("70", value: $vm.targetWeight, format: .number)
                    .font(.system(size: 48, design: .rounded).weight(.bold))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .frame(width: 120)
                    .textFieldStyle(.plain)

                Text("kg")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .padding(24)

            nextButton("下一步") { vm.currentStep = .apiKey }
            Spacer()
        }
        .padding(32)
    }

    private var apiStep: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "key.fill")
                .font(.system(size: 60))
                .foregroundStyle(AppColors.primary)

            Text("AI 服务配置")
                .font(.title2.weight(.bold))

            Text("设置 Anthropic 兼容 API Key\n以启用 AI 食物识别功能")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            VStack(spacing: 12) {
                SecureField("API Key", text: $vm.apiKey)
                    .textFieldStyle(.roundedBorder)
                TextField("Base URL (可选)", text: $vm.baseURL)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.horizontal, 20)

            VStack(spacing: 12) {
                nextButton("开始使用") { vm.finishOnboarding() }
                Button("跳过，稍后设置") { vm.finishOnboarding() }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(32)
    }

    // MARK: - Helpers

    private func nextButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.primary, in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)
        }
    }

    private func activityDescription(_ level: ActivityLevel) -> String {
        switch level {
        case .sedentary: "几乎不运动"
        case .light: "每周轻度运动 1-3 天"
        case .moderate: "每周运动 3-5 天"
        case .active: "每天运动或高强度训练"
        }
    }
}
