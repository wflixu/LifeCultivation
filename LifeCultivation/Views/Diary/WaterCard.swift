import SwiftUI

struct WaterCard: View {
    let record: DailyRecord
    let vm: WaterCardViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Label("饮水", systemImage: "drop.fill")
                    .font(.headline)
                    .foregroundStyle(AppColors.accentBlue)
                Spacer()
                Text(waterText)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            // Bar-based water tracker
            HStack(spacing: 6) {
                ForEach(0..<vm.targetCups, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            i < vm.currentCups
                                ? LinearGradient(
                                    gradient: Gradient(colors: [AppColors.accentBlue, AppColors.accentBlue.opacity(0.7)]),
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                                : LinearGradient(
                                    gradient: Gradient(colors: [Color(.systemGray5), Color(.systemGray6)]),
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .animation(.spring(response: 0.3), value: vm.currentCups)
                        .onTapGesture {
                            Haptic.light()
                            // Set cups to N (clicking N-th bar sets cups to N+1)
                            vm.setCups(i + 1, record: record)
                        }
                }
            }

            // Quick actions
            HStack {
                Button {
                    Haptic.light()
                    vm.adjustCups(by: -1, record: record)
                } label: {
                    Image(systemName: "minus.circle")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .disabled(vm.currentCups <= 0)

                Spacer()

                Text("每杯 250ml")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    Haptic.light()
                    vm.adjustCups(by: 1, record: record)
                } label: {
                    Image(systemName: "plus.circle")
                        .font(.title3)
                        .foregroundStyle(AppColors.accentBlue)
                }
                .disabled(vm.currentCups >= vm.targetCups)
            }
        }
        .padding(20)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .appCardShadow()
    }

    private var waterText: String {
        let liters = Double(vm.currentCups) * 0.25
        let targetLiters = Double(vm.targetCups) * 0.25
        return String(format: "%.2fL / %.1fL", liters, targetLiters)
    }
}
