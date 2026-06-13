import SwiftUI

struct CalorieRingCard: View {
    let record: DailyRecord
    let showNutritionDetail: Binding<Bool>

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("热量")
                    .font(.headline)
                Spacer()
                Button {
                    showNutritionDetail.wrappedValue = true
                } label: {
                    Image(systemName: "info.circle")
                        .font(.body)
                        .foregroundStyle(.orange)
                }
            }

            ringSection
            statRow
        }
        .padding(20)
        .background(Color(.systemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Ring

    private var ringSection: some View {
        let tdee = record.tdee
        let intake = record.totalIntake
        let ratio = tdee > 0 ? min(intake / tdee, 1.5) : 0
        let isOver = intake > tdee && tdee > 0

        return ZStack {
            Circle()
                .stroke(Color(.systemGray5), lineWidth: 14)
                .frame(width: 140, height: 140)

            Circle()
                .trim(from: 0, to: min(ratio, 1))
                .stroke(
                    isOver ? Color.red : Color.green,
                    style: StrokeStyle(lineWidth: 14, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: ratio)

            VStack(spacing: 2) {
                Text("\(Int(intake))")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                Text("\(Int(tdee))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Stats

    private var statRow: some View {
        let resting = record.restingEnergy ?? 0
        let active = record.activeEnergy ?? 0
        let remaining = record.remaining

        return HStack(spacing: 12) {
            statItem(title: "BMR", value: "\(Int(resting))", unit: "kcal")
            Divider().frame(height: 30)
            statItem(title: "已消耗", value: "\(Int(active))", unit: "kcal")
            Divider().frame(height: 30)
            statItem(
                title: "剩余",
                value: remaining >= 0 ? "\(Int(remaining))" : "+\(Int(abs(remaining)))",
                unit: "kcal",
                valueColor: remaining < 0 ? .red : .green
            )
        }
    }

    private func statItem(title: String, value: String, unit: String, valueColor: Color = .primary) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .rounded))
                    .foregroundStyle(valueColor)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
