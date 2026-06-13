import SwiftUI

struct WeightEntryCard: View {
    @Bindable var vm: ProfileViewModel
    @State private var weightInput: Double = 70

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("记录体重")
                    .font(.headline)
                Spacer()
                if let latest = vm.latestWeight {
                    Text("最新: \(String(format: "%.1f", latest)) kg")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                TextField("体重", value: $weightInput, format: .number)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 120)

                Button {
                    vm.saveWeight(weightInput)
                } label: {
                    Text("记录")
                        .fontWeight(.medium)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.orange, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
        .onAppear { weightInput = vm.latestWeight ?? 70 }
    }
}
