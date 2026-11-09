import SwiftUI

struct RecipeView: View {
    @Bindable var vm: RecipeViewModel

    @State private var showDeleteConfirmation = false
    @State private var foodToDelete: FavoriteFood?
    @State private var actionFood: FavoriteFood?
    @State private var showActionSheet = false

    var body: some View {
        VStack(spacing: 0) {
            searchBar
            categoryChips
            foodList
        }
        .background(Color(.systemGroupedBackground))
        .onAppear { vm.loadFavorites() }
        .sheet(isPresented: $vm.showFoodEdit) {
            if let food = vm.editingFood {
                FoodEditView(vm: vm, food: food, isNew: food.name.isEmpty)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("搜索食物", text: $vm.searchText)
                .textFieldStyle(.plain)
                .onChange(of: vm.searchText) { _, _ in vm.applyFilters() }
            if !vm.searchText.isEmpty {
                Button {
                    vm.searchText = ""
                    vm.applyFilters()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Category Chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("全部", isSelected: vm.selectedCategory == nil) {
                    vm.selectedCategory = nil
                    vm.applyFilters()
                }
                ForEach(FoodCategory.allCases, id: \.self) { cat in
                    chip(cat.rawValue, isSelected: vm.selectedCategory == cat) {
                        vm.selectedCategory = cat
                        vm.applyFilters()
                    }
                }
            }
            .padding(.horizontal, 12)
        }
    }

    private func chip(_ label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    isSelected ? AppColors.primary : Color(.systemGray6),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
    }

    // MARK: - Food List

    private var foodList: some View {
        Group {
            if vm.filteredFoods.isEmpty {
                ContentUnavailableView(
                    vm.searchText.isEmpty ? "暂无收藏" : "未找到",
                    systemImage: vm.searchText.isEmpty ? "fork.knife" : "magnifyingglass",
                    description: Text(vm.searchText.isEmpty ? "添加食物后会自动收藏" : "试试其他关键词")
                )
            } else {
                List {
                    ForEach(vm.filteredFoods) { food in
                        RecipeFoodRow(food: food)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                Haptic.light()
                                actionFood = food
                                showActionSheet = true
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    foodToDelete = food
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    vm.editingFood = food
                                    vm.showFoodEdit = true
                                } label: {
                                    Label("编辑", systemImage: "pencil")
                                }
                                .tint(AppColors.primary)
                            }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .alert("确认删除", isPresented: $showDeleteConfirmation) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                if let food = foodToDelete { vm.deleteFood(food) }
            }
        } message: {
            Text("删除「\(foodToDelete?.name ?? "")」？此操作不可撤销。")
        }
        .confirmationDialog("食物操作", isPresented: $showActionSheet, presenting: actionFood) { food in
            Button("编辑") {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    vm.editingFood = food
                    vm.showFoodEdit = true
                }
            }
            ForEach(MealType.allCases, id: \.self) { meal in
                Button("添加到\(meal.rawValue)") {
                    addToDiary(food, meal: meal)
                }
            }
            Button("删除", role: .destructive) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                    foodToDelete = food
                    showDeleteConfirmation = true
                }
            }
        } message: { food in
            Text("\(food.name) · 添加到今天")
        }
    }

    private func addToDiary(_ food: FavoriteFood, meal: MealType) {
        vm.addToDiary(food, mealType: meal, date: Date())
        Haptic.success()
    }
}
