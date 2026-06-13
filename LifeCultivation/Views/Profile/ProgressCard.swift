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
                let lost = current - target
                let initial = target + max(lost, 1)
                let progress = max(0, min(1, (initial - current) / (initial - target)))

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

                    ProgressView(value: progress)
                        .tint(lost <= 0 ? .green : .blue)

                    HStack {
                        Text(lost <= 0 ? "已达标" : "还需减重 \(String(format: "%.1f", abs(lost))) kg")
                            .font(.caption)
                            .foregroundStyle(lost <= 0 ? .green : .secondary)
                        Spacer()
                        Text("\(Int(progress * 100))%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
