//
//  SettingsView.swift
//  LifeCultivation
//
//  Created by luke on 2025/11/23.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    
    @State private var wakeUpTime = Date()
    @State private var bedTime = Date()
    @State private var screenTimeLimit = 30
    
    private var appSettings: AppSettings {
        settings.first ?? AppSettings()
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("目标设置")) {
                    DatePicker("起床时间", selection: $wakeUpTime, displayedComponents: .hourAndMinute)
                    DatePicker("睡觉时间", selection: $bedTime, displayedComponents: .hourAndMinute)
                    
                    Stepper("屏幕时间限制: \(screenTimeLimit)分钟",
                           value: $screenTimeLimit, in: 15...120, step: 5)
                }
                
                Section(header: Text("数据管理")) {
                    Button("导出数据") {
                        exportData()
                    }
                    
                    Button("重置所有数据", role: .destructive) {
                        resetAllData()
                    }
                }
                
                Section(header: Text("关于")) {
                    HStack {
                        Text("版本")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Text("《人生修行》- 培养更好的自己")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("设置")
            .onAppear {
                wakeUpTime = appSettings.wakeUpTime
                bedTime = appSettings.bedTime
                screenTimeLimit = appSettings.screenTimeLimit
            }
            .onChange(of: wakeUpTime) { updateSettings() }
            .onChange(of: bedTime) { updateSettings() }
            .onChange(of: screenTimeLimit) { updateSettings() }
        }
    }
    
    private func updateSettings() {
        appSettings.wakeUpTime = wakeUpTime
        appSettings.bedTime = bedTime
        appSettings.screenTimeLimit = screenTimeLimit
        
        do {
            try modelContext.save()
        } catch {
            print("保存设置失败: \(error)")
        }
    }
    
    private func exportData() {
        // 实现数据导出逻辑
        print("导出数据")
    }
    
    private func resetAllData() {
        // 实现数据重置逻辑
        print("重置数据")
    }
}
