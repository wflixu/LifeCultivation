import SwiftUI

struct AddFoodView: View {
    @Bindable var vm: AddFoodViewModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                modePicker
                Divider()
                contentArea
                if !vm.cart.isEmpty {
                    cartBar
                }
            }
            .navigationTitle("添加食物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .onAppear { vm.searchFavorites() }
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        Picker("模式", selection: $vm.selectedMode) {
            Text("搜索").tag(0)
            Text("输入").tag(1)
            Text("相机").tag(2)
        }
        .pickerStyle(.segmented)
        .padding(12)
    }

    // MARK: - Content

    @ViewBuilder
    private var contentArea: some View {
        switch vm.selectedMode {
        case 0: searchTab
        case 1: inputTab
        case 2: cameraTab
        default: EmptyView()
        }
    }

    // MARK: - Search Tab

    private var searchTab: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("搜索收藏食物", text: $vm.searchQuery)
                    .textFieldStyle(.plain)
                    .onSubmit { vm.searchFavorites() }
                if !vm.searchQuery.isEmpty {
                    Button {
                        vm.searchQuery = ""
                        vm.searchFavorites()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(10)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
            .padding(12)

            if case .searchResults(let foods) = vm.viewState {
                if foods.isEmpty {
                    ContentUnavailableView(
                        "未找到食物",
                        systemImage: "magnifyingglass",
                        description: Text("尝试其他关键词或添加新食物")
                    )
                } else {
                    List(foods) { food in
                        Button { vm.addFavoriteToCart(food) } label: {
                            foodRow(food.name, food.serving, food.calories)
                        }
                    }
                }
            } else {
                ContentUnavailableView(
                    "搜索收藏",
                    systemImage: "list.bullet.rectangle",
                    description: Text("在收藏中搜索食物")
                )
            }
        }
    }

    // MARK: - Input Tab

    private var inputTab: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                if vm.inputText.isEmpty {
                    Text("描述你今天吃的食物...\n例如：一碗米饭、一份宫保鸡丁")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(12)
                }
                TextEditor(text: $vm.inputText)
                    .frame(minHeight: 120)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
            }
            .frame(minHeight: 120)

            Button {
                vm.recognizeFood()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView().tint(.white)
                    }
                    Text(isLoading ? "识别中..." : "AI 识别")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.orange, in: RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(.white)
            }
            .disabled(isRecognitionDisabled)

            resultsArea
            Spacer()
        }
        .padding(12)
    }

    private var isLoading: Bool {
        if case .aiLoading = vm.viewState { return true }
        return false
    }

    private var isRecognitionDisabled: Bool {
        vm.inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading
    }

    @ViewBuilder
    private var resultsArea: some View {
        if case .aiResults(let foods) = vm.viewState {
            List {
                Section("识别结果") {
                    ForEach(Array(foods.enumerated()), id: \.offset) { idx, food in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(food.name)
                                    .font(.subheadline.weight(.medium))
                                Text(food.serving)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(Int(food.calories)) kcal")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Button { vm.addToCart(from: food) } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.orange)
                            }
                            .buttonStyle(.plain)
                            Button { vm.favoriteFood(at: idx) } label: {
                                Image(systemName: vm.favoriteIndices.contains(idx) ? "heart.fill" : "heart")
                                    .foregroundStyle(.pink)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
        } else if case .aiError(let msg) = vm.viewState {
            HStack {
                Label(msg, systemImage: "exclamationmark.triangle")
                    .font(.subheadline)
                    .foregroundStyle(.red)
                Spacer()
                Button("重试") { vm.recognizeFood() }
                    .buttonStyle(.bordered)
            }
            .padding(12)
            .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 12)
        }
    }

    // MARK: - Camera Tab

    private var cameraTab: some View {
        ContentUnavailableView(
            "相机识别",
            systemImage: "camera.viewfinder",
            description: Text("拍照识别功能即将上线")
        )
    }

    // MARK: - Cart Bar

    private var cartBar: some View {
        VStack(spacing: 0) {
            Divider()
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(vm.cart) { item in
                        HStack(spacing: 4) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.name)
                                    .font(.caption.weight(.medium))
                                    .lineLimit(1)
                                Text("\(Int(item.calories)) kcal")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Button { vm.removeFromCart(item) } label: {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            HStack {
                Text("共 \(vm.cart.count) 项 · \(Int(vm.totalCalories)) kcal")
                    .font(.subheadline.weight(.medium))
                Spacer()
                Button {
                    vm.commit()
                    dismiss()
                } label: {
                    Text("完成")
                        .fontWeight(.semibold)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(Color.orange, in: RoundedRectangle(cornerRadius: 8))
                        .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)
        }
        .background(.regularMaterial)
    }

    // MARK: - Helpers

    private func foodRow(_ name: String, _ serving: String, _ calories: Double) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.medium))
                Text(serving)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(Int(calories)) kcal")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.trailing, 4)
            Image(systemName: "plus")
                .font(.caption.weight(.bold))
        }
    }
}
