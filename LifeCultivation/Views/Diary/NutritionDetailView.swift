import SwiftUI
import Charts

struct NutritionDetailView: View {
    let record: DailyRecord?
    let profile: UserProfile?

    var body: some View {
        NavigationStack {
            Group {
                if let record {
                    List {
                        netCalorieSection(record)
                        macroSection(record)
                    }
                } else {
                    ContentUnavailableView(
                        "暂无数据",
                        systemImage: "chart.pie",
                        description: Text("请先记录饮食数据")
                    )
                }
            }
            .navigationTitle("营养详情")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Net Calorie Section

    private func netCalorieSection(_ record: DailyRecord) -> some View {
        Section("热量概览") {
            HStack {
                VStack(alignment: .leading) {
                    Text("摄入")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(record.totalIntake)) kcal")
                        .font(.title3.weight(.medium))
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text("消耗 (TDEE)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(Int(record.effectiveTDEE(profile: profile) + record.exerciseCalories)) kcal")
                        .font(.title3.weight(.medium))
                }
            }

            HStack {
                Text("净摄入")
                Spacer()
                let net = record.totalIntake - record.effectiveTDEE(profile: profile) - record.exerciseCalories
                Text(net >= 0 ? "+\(Int(net)) kcal" : "\(Int(net)) kcal")
                    .foregroundStyle(net > 0 ? .red : .green)
                    .fontWeight(.medium)
            }
        }
    }

    // MARK: - Macro Section

    private func macroSection(_ record: DailyRecord) -> some View {
        let macros = calculateMacros(record)
        let totalGrams = macros.protein + macros.fat + macros.carbs

        return Section("宏量营养分布") {
            if totalGrams > 0 {
                Chart {
                    SectorMark(
                        angle: .value("蛋白质", macros.protein),
                        innerRadius: .ratio(0.6),
                        angularInset: 1
                    )
                    .foregroundStyle(.red)

                    SectorMark(
                        angle: .value("脂肪", macros.fat),
                        innerRadius: .ratio(0.6),
                        angularInset: 1
                    )
                    .foregroundStyle(.yellow)

                    SectorMark(
                        angle: .value("碳水", macros.carbs),
                        innerRadius: .ratio(0.6),
                        angularInset: 1
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 200)

                HStack(spacing: 20) {
                    legendDot(.red, "蛋白质", macros.protein)
                    legendDot(.yellow, "脂肪", macros.fat)
                    legendDot(.blue, "碳水", macros.carbs)
                }

                let totalCal = Double(macros.protein) * 4 + Double(macros.fat) * 9 + Double(macros.carbs) * 4
                HStack {
                    Text("宏量能量合计")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(Int(totalCal)) kcal")
                        .font(.subheadline.weight(.medium))
                }
                .padding(.top, 4)
            } else {
                Text("暂无数据")
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func calculateMacros(_ record: DailyRecord) -> (protein: Int, fat: Int, carbs: Int) {
        var protein = 0.0
        var fat = 0.0
        var carbs = 0.0
        for food in record.foods ?? [] {
            protein += food.protein ?? 0
            fat += food.fat ?? 0
            carbs += food.carbs ?? 0
        }
        return (Int(protein), Int(fat), Int(carbs))
    }

    private func legendDot(_ color: Color, _ label: String, _ grams: Int) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(label) \(grams)g")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
