import SwiftUI

struct WaterCard: View {
    let record: DailyRecord
    let vm: WaterCardViewModel

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("饮水")
                    .font(.headline)
                Spacer()
                Text(waterText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                ForEach(0..<vm.targetCups, id: \.self) { i in
                    Image(systemName: i < vm.currentCups ? "drop.fill" : "drop")
                        .font(.title2)
                        .foregroundStyle(i < vm.currentCups ? .blue : Color(.systemGray4))
                        .onTapGesture {
                            if i < vm.currentCups {
                                vm.toggleCup(increment: false, record: record)
                            } else {
                                vm.toggleCup(increment: true, record: record)
                            }
                        }
                }
            }
        }
        .padding(20)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var waterText: String {
        let liters = Double(vm.currentCups) * 0.25
        let targetLiters = Double(vm.targetCups) * 0.25
        return String(format: "%.2fL / %.1fL", liters, targetLiters)
    }
}
