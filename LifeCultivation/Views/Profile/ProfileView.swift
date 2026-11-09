import SwiftUI
import UIKit

struct ProfileView: View {
    @Bindable var vm: ProfileViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ProgressCard(vm: vm)
                WeightEntryCard(vm: vm)
                StreakCard(recordingStreak: vm.recordingStreak, goalMetStreak: vm.goalMetStreak)
                GoalsCard(vm: vm)
                SettingsCard(vm: vm)
            }
            .padding(16)
        }
        .background(Color(.systemGroupedBackground))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完成") { dismissKeyboard() }
            }
        }
        .onAppear { vm.loadProfile() }
        .sheet(isPresented: $vm.showSettingsSheet) {
            SettingsSheet(vm: vm)
        }
    }
}

func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}

// MARK: - Placeholder types defined inline until proper refactored

struct SettingsSheet: View {
    let vm: ProfileViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Anthropic 兼容 API") {
                    SecureField("API Key", text: Binding(
                        get: { vm.userProfile?.apiKey ?? "" },
                        set: { vm.userProfile?.apiKey = $0; vm.saveProfile() }
                    ))
                    TextField("Base URL", text: Binding(
                        get: { vm.userProfile?.apiBaseURL ?? "" },
                        set: { vm.userProfile?.apiBaseURL = $0; vm.saveProfile() }
                    ))
                    TextField("Model（如 deepseek-chat）", text: Binding(
                        get: { vm.userProfile?.aiModel ?? "" },
                        set: { vm.userProfile?.aiModel = $0; vm.saveProfile() }
                    ))
                }

                Section {
                    if let json = vm.exportJSONString() {
                        ShareLink(item: json) {
                            Label("导出数据", systemImage: "square.and.arrow.up")
                        }
                    }
                } footer: {
                    Text("轻迹 v2.0")
                }
            }
            .navigationTitle("设置")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("完成") { dismissKeyboard() }
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
