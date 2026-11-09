import SwiftUI

struct ProgressCard: View {
    let vm: ProfileViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("体重进度")
                    .font(.headline)
                Spacer()
            }

            if let target = vm.targetWeight, let current = vm.currentWeight ?? vm.latestWeight {
                let initial = vm.initialWeight ?? current
                let totalToLose = initial - target
                let lostSoFar = initial - current
                let remainingToLose = current - target
                let progress: Double = {
                    guard totalToLose > 0 else {
                        return current <= target ? 1 : 0
                    }
                    return max(0, min(1, lostSoFar / totalToLose))
                }()

                VStack(spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        VStack {
                            Text(String(format: "%.1f", current))
                                .font(.system(.largeTitle, design: .rounded))
                            Text("当前 (kg)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        VStack {
                            Text(String(format: "%.1f", target))
                                .font(.system(.largeTitle, design: .rounded))
                            Text("目标 (kg)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    // Custom gradient progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color(.systemGray5))
                                .frame(height: 10)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: remainingToLose <= 0 ? [.green, .mint] : [AppColors.primary, AppColors.primary.opacity(0.6)]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(geo.size.width * progress, progress > 0 ? 10 : 0), height: 10)
                                .animation(.easeInOut(duration: 0.6), value: progress)
                        }
                    }
                    .frame(height: 10)

                    HStack {
                        Text(remainingToLose <= 0 ? "已达标" : "还需减重 \(String(format: "%.1f", abs(remainingToLose))) kg")
                            .font(.caption)
                            .foregroundStyle(remainingToLose <= 0 ? .green : .secondary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if lostSoFar > 0 {
                        Text("已减重 \(String(format: "%.1f", lostSoFar)) kg · 起始 \(String(format: "%.1f", initial)) kg")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            } else {
                VStack(spacing: 8) {
                    if let current = vm.currentWeight ?? vm.latestWeight {
                        Text(String(format: "%.1f kg", current))
                            .font(.title.weight(.medium))
                        Text("当前体重")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text("设置目标体重以查看进度")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 20)
            }
        }
        .padding(20)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .appCardShadow()
    }
}
