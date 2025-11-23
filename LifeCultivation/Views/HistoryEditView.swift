//
//  HistoryEditView.swift
//  LifeCultivation
//
//  Created by luke on 2025/11/23.
//

import SwiftUI
import SwiftData

struct HistoryEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedDate: Date
    @State private var record: DailyRecord?
    @State private var showingDatePicker = false

    init(date: Date = Date()) {
        self._selectedDate = State(initialValue: date)
    }

    @State private var dietBreakfast = true
    @State private var dietLunch = true
    @State private var dietDinner = true
    @State private var dietNoSpicy = true
    @State private var dietNoJunk = true

    @State private var sleepOnTime = true
    @State private var wakeOnTime = true

    @State private var screenTime: Double = 0
    @State private var exerciseCount = 0
    @State private var exerciseDone = false
    @State private var note = ""

    private var dietScore: Int {
        var score = 3
        if !dietBreakfast || !dietLunch || !dietDinner { score -= 1 }
        if !dietNoSpicy { score -= 1 }
        if !dietNoJunk { score -= 1 }
        return max(0, score)
    }

    private var sleepScore: Int {
        var score = 3
        if !sleepOnTime { score -= 1 }
        if !wakeOnTime { score -= 1 }
        return score
    }

    private var screenTimeScore: Int {
        if screenTime <= 30 { return 4 }
        if screenTime <= 60 { return 2 }
        return 0
    }

    private var totalScore: Int {
        dietScore + sleepScore + screenTimeScore + exerciseCount
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        return formatter
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 日期选择
                    VStack(spacing: 12) {
                        Button(action: {
                            showingDatePicker = true
                        }) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(dateFormatter.string(from: selectedDate))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                    Text("点击选择日期")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "calendar")
                                    .font(.title2)
                                    .foregroundColor(.orange)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // 分数卡片
                    ScoreCardView(totalScore: totalScore,
                                dietScore: dietScore,
                                sleepScore: sleepScore,
                                screenScore: screenTimeScore,
                                exerciseScore: exerciseCount)

                    // 饮食评分
                    DietSectionView(
                        breakfast: $dietBreakfast,
                        lunch: $dietLunch,
                        dinner: $dietDinner,
                        noSpicy: $dietNoSpicy,
                        noJunk: $dietNoJunk,
                        score: dietScore
                    )

                    // 作息评分
                    SleepSectionView(
                        sleepOnTime: $sleepOnTime,
                        wakeOnTime: $wakeOnTime,
                        score: sleepScore
                    )

                    // 屏幕时间
                    ScreenTimeSectionView(
                        screenTime: $screenTime,
                        score: screenTimeScore
                    )

                    // 锻炼
                    ExerciseSectionView(exerciseCount: $exerciseCount, exerciseDone: $exerciseDone)

                    // 备注
                    NoteSectionView(note: $note)

                    // 保存和删除按钮
                    HStack(spacing: 16) {
                        Button("删除记录") {
                            deleteRecord()
                        }
                        .buttonStyle(DeleteButtonStyle())

                        Button("保存记录") {
                            saveRecord()
                        }
                        .buttonStyle(SaveButtonStyle())
                    }
                    .padding(.top)
                }
                .padding()
            }
            .navigationTitle("历史记录编辑")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("取消") {
                        dismiss()
                    }
                }
            }
            .onAppear(perform: loadRecord)
            .sheet(isPresented: $showingDatePicker) {
                DatePickerView(selectedDate: $selectedDate) {
                    loadRecord()
                }
            }
        }
    }

    private func loadRecord() {
        let calendar = Calendar.current
        let dayStart = calendar.startOfDay(for: selectedDate)
        let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!

        let predicate = #Predicate<DailyRecord> { record in
            record.date >= dayStart && record.date < dayEnd
        }

        let descriptor = FetchDescriptor<DailyRecord>(predicate: predicate)

        do {
            let records = try modelContext.fetch(descriptor)
            if let existingRecord = records.first {
                record = existingRecord
                updateUI(from: existingRecord)
            } else {
                record = nil
            }
        } catch {
            record = nil
        }
    }

    private func updateUI(from record: DailyRecord) {
        dietBreakfast = record.dietScore >= 1
        dietNoSpicy = record.dietScore >= 2
        dietNoJunk = record.dietScore >= 3

        screenTime = Double(record.screenTimeScore == 4 ? 0 : (record.screenTimeScore == 2 ? 45 : 90))

        exerciseCount = record.exerciseCount
        exerciseDone = record.exerciseCompleted
        note = record.note ?? ""
    }

    private func saveRecord() {
        let targetRecord = record ?? DailyRecord(date: selectedDate)

        targetRecord.dietScore = dietScore
        targetRecord.sleepScore = sleepScore
        targetRecord.screenTimeScore = screenTimeScore
        targetRecord.exerciseCount = exerciseCount
        targetRecord.exerciseCompleted = exerciseDone
        targetRecord.note = note.isEmpty ? nil : note

        if record == nil {
            modelContext.insert(targetRecord)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("保存失败: \(error)")
        }
    }

    private func deleteRecord() {
        guard let record = record else { return }

        modelContext.delete(record)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("删除失败: \(error)")
        }
    }
}

// 自定义按钮样式
struct DeleteButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.red)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct SaveButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}