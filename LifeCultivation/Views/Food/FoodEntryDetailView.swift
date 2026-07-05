import Charts
import SwiftUI

struct FoodEntryDetailView: View {
    let food: FoodEntry
    var onDelete: (() -> Void)?

    @Environment(\.dismiss) private var dismiss
    @State private var showDeleteConfirmation = false

    init(food: FoodEntry, onDelete: (() -> Void)? = nil) {
        self.food = food
        self.onDelete = onDelete
    }

    var body: some View {
        NavigationStack {
            List {
                basicInfoSection
                macroSection

                if onDelete != nil {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("删除此记录", systemImage: "trash")
                                    .foregroundStyle(.red)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(food.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .alert("确认删除", isPresented: $showDeleteConfirmation) {
                Button("取消", role: .cancel) {}
                Button("删除", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
            } message: {
                Text("删除「\(food.name)」？此操作不可撤销。")
            }
        }
    }

    // MARK: - Basic Info Section

    private var basicInfoSection: some View {
        Section("基本信息") {
            labeledRow("份量", food.serving)

            if let meal = food.mealType {
                labeledRow("餐类", "\(mealEmoji(meal)) \(meal.rawValue)")
            }

            labeledRow("时间", timeFormatter.string(from: food.timestamp))

            labeledRow("来源", food.source.displayName)
        }
    }

    private func labeledRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
    }

    // MARK: - Macro Section

    private var macroSection: some View {
        let protein = food.protein ?? 0
        let fat = food.fat ?? 0
        let carbs = food.carbs ?? 0
        let totalGrams = protein + fat + carbs

        return Section("宏量营养组成") {
            HStack {
                Spacer()
                VStack(spacing: 4) {
                    Text("\(Int(food.calories))")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primary)
                    Text("kcal")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 8)

            if totalGrams > 0 {
                Chart {
                    SectorMark(
                        angle: .value("蛋白质", protein),
                        innerRadius: .ratio(0.6),
                        angularInset: 1
                    )
                    .foregroundStyle(.red)

                    SectorMark(
                        angle: .value("脂肪", fat),
                        innerRadius: .ratio(0.6),
                        angularInset: 1
                    )
                    .foregroundStyle(.yellow)

                    SectorMark(
                        angle: .value("碳水", carbs),
                        innerRadius: .ratio(0.6),
                        angularInset: 1
                    )
                    .foregroundStyle(.blue)
                }
                .frame(height: 200)

                HStack(spacing: 20) {
                    legendDot(.red, "蛋白质", Int(protein))
                    legendDot(.yellow, "脂肪", Int(fat))
                    legendDot(.blue, "碳水", Int(carbs))
                }

                let totalCal = protein * 4 + fat * 9 + carbs * 4
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
                HStack {
                    Spacer()
                    Text("暂无营养数据")
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.vertical, 20)
            }
        }
    }

    // MARK: - Helpers

    private func legendDot(_ color: Color, _ label: String, _ grams: Int) -> some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text("\(label) \(grams)g")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func mealEmoji(_ meal: MealType) -> String {
        switch meal {
        case .breakfast: "🌅"
        case .lunch: "☀️"
        case .dinner: "🌙"
        case .snack: "🍿"
        }
    }

    private var timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "HH:mm"
        return f
    }()
}

// MARK: - FoodSource Display Helpers

private extension FoodSource {
    var displayName: String {
        switch self {
        case .text: "文字输入"
        case .photo: "拍照识别"
        case .favorite: "收藏食物"
        }
    }
}
