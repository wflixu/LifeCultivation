import SwiftUI
import UIKit

struct FoodEditView: View {
    @Bindable var vm: RecipeViewModel

    let food: FavoriteFood
    let isNew: Bool

    @State private var name: String = ""
    @State private var serving: String = ""
    @State private var calories: Double = 0
    @State private var protein: Double?
    @State private var fat: Double?
    @State private var carbs: Double?
    @State private var category: FoodCategory?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("基本信息") {
                    TextField("食物名称", text: $name)
                    TextField("份量", text: $serving)
                    HStack {
                        Text("热量 (kcal)")
                        Spacer()
                        TextField("0", value: $calories, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("营养 (每份)") {
                    labeledField("蛋白质 (g)", value: $protein)
                    labeledField("脂肪 (g)", value: $fat)
                    labeledField("碳水 (g)", value: $carbs)
                }

                Section("分类") {
                    Picker("分类", selection: $category) {
                        Text("无").tag(nil as FoodCategory?)
                        ForEach(FoodCategory.allCases, id: \.self) { cat in
                            Text(cat.rawValue).tag(cat as FoodCategory?)
                        }
                    }
                }

                Section {
                    Button {
                        vm.requestAISuggestion(foodName: name, serving: serving)
                    } label: {
                        HStack {
                            if vm.isAISuggesting {
                                ProgressView()
                            }
                            Text(vm.isAISuggesting ? "分析中..." : "AI 建议")
                        }
                    }
                    .disabled(vm.isAISuggesting || name.trimmingCharacters(in: .whitespaces).isEmpty)

                    if let error = vm.aiSuggestionError {
                        HStack {
                            Label(error, systemImage: "exclamationmark.triangle")
                                .font(.caption)
                                .foregroundStyle(.red)
                            Spacer()
                            Button("重试") {
                                vm.requestAISuggestion(foodName: name, serving: serving)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }

                    ForEach(Array(vm.aiSuggestions.enumerated()), id: \.offset) { idx, suggestion in
                        Button {
                            calories = suggestion.calories
                            protein = suggestion.protein
                            fat = suggestion.fat
                            carbs = suggestion.carbs
                            vm.aiSuggestions = []
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("方案 \(idx + 1)")
                                        .font(.caption.weight(.medium))
                                        .foregroundStyle(AppColors.primary)
                                    Spacer()
                                    Text("\(Int(suggestion.calories)) kcal")
                                        .font(.caption.weight(.semibold))
                                }
                                HStack(spacing: 12) {
                                    Text("P: \(String(format: "%.1f", suggestion.protein))g")
                                    Text("F: \(String(format: "%.1f", suggestion.fat))g")
                                    Text("C: \(String(format: "%.1f", suggestion.carbs))g")
                                }
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                if !suggestion.reasoning.isEmpty {
                                    Text(suggestion.reasoning)
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            .padding(10)
                            .background(
                                Color(.systemGray6),
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                } header: {
                    Text("AI 营养建议")
                }
            }
            .navigationTitle(isNew ? "新建食物" : "编辑食物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { dismissKeyboard() }
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        vm.saveFood(
                            food,
                            name: name,
                            calories: calories,
                            serving: serving,
                            protein: protein,
                            fat: fat,
                            carbs: carbs,
                            category: category
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || calories <= 0)
                }
            }
            .onAppear {
                loadFood()
                vm.aiSuggestions = []
                vm.aiSuggestionError = nil
            }
        }
    }

    private func loadFood() {
        name = food.name
        serving = food.serving
        calories = food.calories
        protein = food.protein
        fat = food.fat
        carbs = food.carbs
        category = food.category
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private func labeledField(_ label: String, value: Binding<Double?>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0", value: Binding(
                get: { value.wrappedValue ?? 0 },
                set: { value.wrappedValue = $0 > 0 ? $0 : nil }
            ), format: .number)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
        }
    }
}
