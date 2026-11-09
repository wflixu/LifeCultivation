import SwiftUI

struct SettingsCard: View {
    @Bindable var vm: ProfileViewModel

    var body: some View {
        VStack(spacing: 12) {
            Button {
                vm.showSettingsSheet = true
            } label: {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(.title3)
                    Text("设置")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .foregroundStyle(.primary)
            }

            Divider()

            if let json = vm.exportJSONString() {
                ShareLink(item: json) {
                    HStack {
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.title3)
                        Text("导出数据")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .padding(20)
        .background(AppColors.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.card))
        .appCardShadow()
    }
}
