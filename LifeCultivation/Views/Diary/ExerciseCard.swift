import SwiftUI

struct ExerciseCard: View {
    let record: DailyRecord
    @Bindable var vm: ExerciseCardViewModel
    let date: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("运动")
                    .font(.headline)
                Spacer()
                Button {
                    vm.showAddExercise = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.orange)
                }
            }

            stepSection

            if !vm.exercises.isEmpty {
                Divider()
                ForEach(vm.exercises) { exercise in
                    exerciseRow(exercise)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: $vm.showAddExercise) {
            AddExerciseView(vm: vm, date: date)
        }
    }

    // MARK: - Steps

    private var stepSection: some View {
        let goal = max(vm.stepGoal, 1)
        let ratio = min(Double(vm.stepCount) / Double(goal), 1.0)
        let distance = CalorieCalculator.distance(steps: vm.stepCount)

        return VStack(spacing: 8) {
            HStack {
                Image(systemName: "figure.walk")
                    .foregroundStyle(.green)
                Text("步数")
                    .font(.subheadline)
                Spacer()
                Text("\(vm.stepCount) / \(vm.stepGoal)")
                    .font(.subheadline.weight(.medium))
            }

            ProgressView(value: ratio)
                .tint(.green)

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

    // MARK: - Exercise Row

    private func exerciseRow(_ exercise: ExerciseEntry) -> some View {
        let minutes = Int(exercise.duration / 60)

        return HStack {
            Image(systemName: exercise.exerciseType == .running ? "figure.run" :
                  exercise.exerciseType == .cycling ? "bicycle" :
                  exercise.exerciseType == .swimming ? "figure.pool.swim" :
                  "figure.mixed.cardio")
                .font(.title3)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.exerciseType.rawValue)
                    .font(.subheadline)
                Text("\(minutes) 分钟")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("\(Int(exercise.calories)) kcal")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.orange)
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
                vm.deleteExercise(exercise)
            } label: {
                Label("删除", systemImage: "trash")
            }
        }
    }
}
