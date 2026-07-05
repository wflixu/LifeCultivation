import SwiftUI

struct ExerciseCard: View {
    let record: DailyRecord
    @Bindable var vm: ExerciseCardViewModel
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Label("运动", systemImage: "figure.run")
                    .font(.headline)
                    .foregroundStyle(.green)
                Spacer()
                Button {
                    Haptic.light()
                    vm.showAddExercise = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.green)
                }
            }

            stepSection

            if !vm.exercises.isEmpty {
                Divider()
                exerciseList
            }
        }
        .padding(20)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .appCardShadow()
        .sheet(isPresented: $vm.showAddExercise) {
            AddExerciseView(vm: vm, date: date)
        }
    }

    // MARK: - Steps

    private var stepSection: some View {
        let goal = max(vm.stepGoal, 1)
        let ratio = min(Double(vm.stepCount) / Double(goal), 1.0)
        let distance = CalorieCalculator.distance(steps: vm.stepCount)

        return VStack(spacing: 10) {
            HStack {
                Image(systemName: "figure.walk")
                    .font(.subheadline)
                    .foregroundStyle(.green)
                Text("步数")
                    .font(.subheadline)
                Spacer()
                Text("\(vm.stepCount) / \(vm.stepGoal)")
                    .font(.subheadline.weight(.medium))
            }

            // Custom capsule progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemGray5))
                        .frame(height: 10)

                    Capsule()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [.green, .mint]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(geo.size.width * ratio, ratio > 0 ? 10 : 0), height: 10)
                        .animation(.easeInOut(duration: 0.6), value: ratio)
                }
            }
            .frame(height: 10)

            if vm.stepCount > 0 {
                HStack {
                    Spacer()
                    Text(String(format: "≈ %.1f km", distance))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Exercise List

    private var exerciseList: some View {
        VStack(spacing: 8) {
            ForEach(vm.exercises) { exercise in
                exerciseRow(exercise)
            }
        }
    }

    private func exerciseRow(_ exercise: ExerciseEntry) -> some View {
        let minutes = Int(exercise.duration / 60)

        return HStack(spacing: 12) {
            // Icon in a colored circle
            ZStack {
                Circle()
                    .fill(exerciseColor(exercise.exerciseType).opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: exerciseIcon(exercise.exerciseType))
                    .font(.system(size: 16))
                    .foregroundStyle(exerciseColor(exercise.exerciseType))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.exerciseType.rawValue)
                    .font(.subheadline.weight(.medium))
                Text("\(minutes) 分钟")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if exercise.calorieSource == .ai {
                Image(systemName: "sparkles")
                    .font(.caption2)
                    .foregroundStyle(.purple)
            }

            Text("\(Int(exercise.calories)) kcal")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.primary)
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                vm.editingExercise = exercise
                vm.showAddExercise = true
            } label: {
                Label("编辑", systemImage: "pencil")
            }
            Button(role: .destructive) {
                Haptic.warning()
                vm.deleteExercise(exercise)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }

    private func exerciseColor(_ type: ExerciseType) -> Color {
        switch type {
        case .running: .red
        case .cycling: .blue
        case .swimming: .cyan
        case .walking: .green
        case .strength: .purple
        case .aerobics: .red
        case .ballGames: .indigo
        case .other: .gray
        }
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
