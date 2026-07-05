import SwiftUI
import UIKit

struct AddExerciseView: View {
    let vm: ExerciseCardViewModel
    let date: Date

    @State private var selectedType: ExerciseType = .running
    @State private var duration: TimeInterval = 30 * 60
    @State private var distance: Double?
    @State private var calorieSource: CalorieSource = .met
    @State private var manualCalories: Double = 0
    @State private var intensity: String = ""
    @State private var aiEstimatedCalories: Double?
    @State private var isAIEstimating = false
    @State private var aiError: String?

    @Environment(\.dismiss) private var dismiss

    private let durationMinutes: [Int] = [5, 10, 15, 20, 30, 45, 60, 90, 120]

    var distanceBased: Bool {
        switch selectedType {
        case .running, .cycling, .walking: true
        default: false
        }
    }

    var estimatedCalories: Double {
        CalorieCalculator.exerciseCalories(
            met: selectedType.met,
            weightKg: vm.userWeight,
            minutes: duration / 60
        )
    }

    var effectiveCalories: Double {
        switch calorieSource {
        case .met:
            return estimatedCalories
        case .manual:
            return manualCalories
        case .ai:
            return aiEstimatedCalories ?? estimatedCalories
        }
    }

    var canSubmit: Bool {
        switch calorieSource {
        case .met:
            return true
        case .manual:
            return manualCalories > 0
        case .ai:
            return true
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                typeSection
                durationSection
                if distanceBased {
                    distanceSection
                }
                calorieSourceSection
                calorieDetailSection
            }
            .navigationTitle("添加运动")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        submit()
                    }
                    .disabled(!canSubmit)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { dismissKeyboard() }
                }
            }
        }
    }

    // MARK: - Type Section

    private var typeSection: some View {
        Section("运动类型") {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 10) {
                ForEach(ExerciseType.allCases, id: \.self) { type in
                    Button {
                        selectedType = type
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: exerciseIcon(type))
                                .font(.title2)
                            Text(type.rawValue)
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedType == type
                                ? AppColors.primaryLight
                                : Color(.systemGray6),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Duration Section

    private var durationSection: some View {
        Section("时长") {
            Picker("时长", selection: $duration) {
                ForEach(durationMinutes, id: \.self) { min in
                    Text("\(min) 分钟")
                        .tag(TimeInterval(min * 60))
                }
            }
        }
    }

    // MARK: - Distance Section

    private var distanceSection: some View {
        Section("距离 (公里)") {
            TextField("距离", value: $distance, format: .number)
                .keyboardType(.decimalPad)
        }
    }

    // MARK: - Calorie Source Section

    private var calorieSourceSection: some View {
        Section("卡路里计算方式") {
            Picker("方式", selection: $calorieSource) {
                ForEach(CalorieSource.allCases, id: \.self) { source in
                    Text(source.rawValue).tag(source)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Calorie Detail Section

    @ViewBuilder
    private var calorieDetailSection: some View {
        switch calorieSource {
        case .met:
            Section {
                HStack {
                    Text("估算消耗")
                    Spacer()
                    Text("\(Int(estimatedCalories)) kcal")
                        .foregroundStyle(AppColors.primary)
                        .fontWeight(.medium)
                }
            } footer: {
                Text("基于 MET \(String(format: "%.1f", selectedType.met)) × 体重 \(String(format: "%.0f", vm.userWeight)) kg 计算")
            }

        case .manual:
            Section("卡路里") {
                TextField("输入卡路里", value: $manualCalories, format: .number)
                    .keyboardType(.numberPad)
            }

        case .ai:
            Section {
                TextField("强度描述 (如: 中等强度，出了很多汗)", text: $intensity, axis: .vertical)
                    .lineLimit(2...4)

                Button {
                    estimateWithAI()
                } label: {
                    HStack {
                        Spacer()
                        if isAIEstimating {
                            ProgressView()
                        } else {
                            Label("AI 智能估算", systemImage: "sparkles")
                        }
                        Spacer()
                    }
                }
                .disabled(intensity.trimmingCharacters(in: .whitespaces).isEmpty || isAIEstimating)

                if let aiEstimatedCalories {
                    HStack {
                        Text("AI 估算结果")
                        Spacer()
                        Text("\(Int(aiEstimatedCalories)) kcal")
                            .foregroundStyle(.purple)
                            .fontWeight(.medium)
                    }
                }

                if let aiError {
                    Text(aiError)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            } header: {
                Text("AI 估算")
            } footer: {
                Text("AI 将根据运动类型、时长和强度描述估算消耗热量")
            }
        }
    }

    // MARK: - Submit

    private func submit() {
        vm.addManualExercise(
            selectedType,
            duration: duration,
            distance: distanceBased ? distance : nil,
            weight: nil,
            to: date,
            calorieSource: calorieSource,
            manualCalories: calorieSource == .manual ? manualCalories : nil,
            intensity: calorieSource == .ai ? intensity : nil
        )
        dismiss()
    }

    // MARK: - AI Estimation

    private func estimateWithAI() {
        guard !intensity.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        isAIEstimating = true
        aiError = nil

        let type = selectedType
        let dur = duration
        let desc = intensity

        Task {
            defer { isAIEstimating = false }
            do {
                let result = try await vm.estimateExerciseCalories(
                    type: type,
                    duration: dur,
                    intensity: desc
                )
                aiEstimatedCalories = result
            } catch {
                aiError = "估算失败: \(error.localizedDescription)"
            }
        }
    }

    // MARK: - Helpers

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func exerciseIcon(_ type: ExerciseType) -> String {
        switch type {
        case .running: "figure.run"
        case .cycling: "bicycle"
        case .swimming: "figure.pool.swim"
        case .walking: "figure.walk"
        case .strength: "dumbbell"
        case .aerobics: "figure.mixed.cardio"
        case .ballGames: "figure.soccer"
        case .other: "figure.mixed.cardio"
        }
    }
}
