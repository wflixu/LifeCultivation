import SwiftUI
import UIKit

struct AddExerciseView: View {
    let vm: ExerciseCardViewModel
    let date: Date

    @State private var selectedType: ExerciseType = .running
    @State private var duration: TimeInterval = 30 * 60
    @State private var distance: Double?
    @State private var weight: Double = 70

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
            weightKg: weight,
            minutes: duration / 60
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                typeSection
                durationSection
                if distanceBased {
                    distanceSection
                }
                weightSection
                calorieSection
            }
            .navigationTitle("添加运动")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        vm.addManualExercise(
                            selectedType,
                            duration: duration,
                            distance: distanceBased ? distance : nil,
                            weight: weight,
                            to: date
                        )
                        dismiss()
                    }
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

    // MARK: - Sections

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
                                ? Color.orange.opacity(0.15)
                                : Color(.systemGray6),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

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

    private var distanceSection: some View {
        Section("距离 (公里)") {
            TextField("距离", value: $distance, format: .number)
                .keyboardType(.decimalPad)
        }
    }

    private var weightSection: some View {
        Section("体重 (公斤)") {
            TextField("体重", value: $weight, format: .number)
                .keyboardType(.decimalPad)
        }
    }

    private var calorieSection: some View {
        Section {
            HStack {
                Text("估算消耗")
                Spacer()
                Text("\(Int(estimatedCalories)) kcal")
                    .foregroundStyle(.orange)
                    .fontWeight(.medium)
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
        case .yoga: "figure.mind.and.body"
        case .aerobics: "figure.mixed.cardio"
        case .ballGames: "figure.soccer"
        case .other: "figure.mixed.cardio"
        }
    }
}
