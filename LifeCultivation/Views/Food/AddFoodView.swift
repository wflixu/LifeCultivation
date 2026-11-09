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
            }
            .navigationTitle("添加食物")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !vm.cart.isEmpty {
                    cartBar
                }
            }
            .onAppear {
                vm.reset()
                vm.searchFavorites()
            }
        }
    }

    // MARK: - Mode Picker

    private var modePicker: some View {
        HStack(spacing: 8) {
            modePill("搜索", icon: "magnifyingglass", tag: 0)
            modePill("输入", icon: "text.bubble", tag: 1)
            modePill("相机", icon: "camera.fill", tag: 2)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func modePill(_ title: String, icon: String, tag: Int) -> some View {
        Button {
            Haptic.light()
            withAnimation(.spring(response: 0.3)) {
                vm.selectedMode = tag
            }
            if tag == 0 {
                vm.searchFavorites()
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                vm.selectedMode == tag
                    ? AppColors.primary
                    : Color(.systemGray6),
                in: RoundedRectangle(cornerRadius: AppRadius.button)
            )
            .foregroundStyle(vm.selectedMode == tag ? .white : .primary)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Content Area

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
                    .onChange(of: vm.searchQuery) { _, _ in vm.searchFavorites() }
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
                        Button {
                            Haptic.light()
                            vm.addFavoriteToCart(food)
                        } label: {
                            foodRow(food.name, food.serving, food.calories)
                        }
                    }
                    .listStyle(.plain)
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
            // Text input area
            ZStack(alignment: .topLeading) {
                if vm.inputText.isEmpty {
                    Text("描述你今天吃的食物...\n例如：一碗米饭、一份宫保鸡丁")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .padding(12)
                }
                TextEditor(text: $vm.inputText)
                    .frame(minHeight: 100)
                    .padding(8)
                    .scrollContentBackground(.hidden)
                    .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
            }
            .frame(minHeight: 100)

            // AI button
            Button {
                Haptic.medium()
                vm.recognizeFood()
            } label: {
                HStack {
                    if isLoading {
                        ProgressView().tint(.white)
                    }
                    Image(systemName: "sparkles")
                    Text(isLoading ? "识别中..." : "AI 识别")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [AppColors.primary, AppColors.primary.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    in: RoundedRectangle(cornerRadius: AppRadius.button)
                )
                .foregroundStyle(.white)
            }
            .disabled(isRecognitionDisabled)
            .opacity(isRecognitionDisabled ? 0.5 : 1)

            // Scrollable results area
            resultsArea
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

    // MARK: - Results

    @ViewBuilder
    private var resultsArea: some View {
        if case .aiResults(let foods) = vm.viewState {
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(foods.enumerated()), id: \.offset) { idx, food in
                        resultRow(food, at: idx)
                    }
                }
            }
            .frame(maxHeight: 240)
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
        }
    }

    private func resultRow(_ food: RecognizedFood, at idx: Int) -> some View {
        HStack(spacing: 8) {
            // Food info
            VStack(alignment: .leading, spacing: 2) {
                Text(food.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text(food.serving)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .layoutPriority(1)

            Spacer(minLength: 4)

            // Calories
            Text("\(Int(food.calories)) kcal")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .layoutPriority(1)

            // Add to cart
            Button {
                Haptic.light()
                vm.addToCart(from: food)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                    .foregroundStyle(AppColors.primary)
            }
            .buttonStyle(.plain)

            // Favorite
            Button {
                Haptic.light()
                vm.toggleFavorite(at: idx)
            } label: {
                Image(systemName: vm.favoriteIndices.contains(idx) ? "heart.fill" : "heart")
                    .font(.body)
                    .foregroundStyle(vm.favoriteIndices.contains(idx) ? .pink : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: AppRadius.small))
    }

    // MARK: - Camera Tab

    private var cameraTab: some View {
        ContentUnavailableView(
            "相机识别",
            systemImage: "camera.viewfinder",
            description: Text("拍照识别功能即将上线")
        )
    }

    // MARK: - Cart Bar (using safeAreaInset now)

    private var cartBar: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
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
                            Button {
                                Haptic.light()
                                vm.removeFromCart(item)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color(.systemGray5), in: RoundedRectangle(cornerRadius: AppRadius.chip))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .layoutPriority(1)

            Divider().frame(height: 30)

            VStack(spacing: 0) {
                Text("\(Int(vm.totalCalories))")
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(AppColors.primary)
                Text("kcal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 60)

            Button {
                Haptic.success()
                vm.commit()
                dismiss()
            } label: {
                Text("完成")
                    .fontWeight(.semibold)
                    .frame(width: 64, height: 48)
                    .background(AppColors.primary, in: RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(.white)
            }
            .padding(.trailing, 8)
        }
        .frame(height: 56)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Divider()
        }
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
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(AppColors.primary)
        }
        .padding(.vertical, 4)
    }
}
