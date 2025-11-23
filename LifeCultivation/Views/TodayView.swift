//
//  TodayView.swift
//  LifeCultivation
//
//  Created by luke on 2025/11/23.
//

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [AppSettings]
    @State private var todayRecord: DailyRecord?
    
    @State private var dietBreakfast = true
    @State private var dietLunch = true
    @State private var dietDinner = true
    @State private var dietNoSpicy = true
    @State private var dietNoJunk = true
    
    @State private var sleepOnTime = true
    @State private var wakeOnTime = true
    
    @State private var screenTime: Double = 0
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
        dietScore + sleepScore + screenTimeScore
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 分数卡片
                    ScoreCardView(totalScore: totalScore,
                                dietScore: dietScore,
                                sleepScore: sleepScore,
                                screenScore: screenTimeScore)
                    
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
                    ExerciseSectionView(exerciseDone: $exerciseDone)
                    
                    // 备注
                    NoteSectionView(note: $note)
                    
                    // 保存按钮
                    SaveButtonView(onSave: saveRecord)
                }
                .padding()
            }
            .navigationTitle("今日修行")
            .onAppear(perform: loadTodayRecord)
        }
    }
    
    private func loadTodayRecord() {
        let today = Calendar.current.startOfDay(for: Date())
        let predicate = #Predicate<DailyRecord> { record in
            Calendar.current.isDate(record.date, inSameDayAs: today)
        }
        
        let descriptor = FetchDescriptor<DailyRecord>(predicate: predicate)
        
        do {
            let records = try modelContext.fetch(descriptor)
            if let record = records.first {
                todayRecord = record
                updateUI(from: record)
            } else {
                todayRecord = DailyRecord()
            }
        } catch {
            todayRecord = DailyRecord()
        }
    }
    
    private func updateUI(from record: DailyRecord) {
        // 这里简化处理，实际需要根据记录反填UI状态
        dietBreakfast = record.dietScore >= 1
        dietNoSpicy = record.dietScore >= 2
        dietNoJunk = record.dietScore >= 3
        // 其他字段类似...
        screenTime = Double(record.screenTimeScore == 4 ? 0 : (record.screenTimeScore == 2 ? 45 : 90))
        exerciseDone = record.exerciseCompleted
        note = record.note ?? ""
    }
    
    private func saveRecord() {
        let record = todayRecord ?? DailyRecord()
        
        record.dietScore = dietScore
        record.sleepScore = sleepScore
        record.screenTimeScore = screenTimeScore
        record.exerciseCompleted = exerciseDone
        record.note = note.isEmpty ? nil : note
        
        if todayRecord == nil {
            modelContext.insert(record)
            todayRecord = record
        }
        
        do {
            try modelContext.save()
        } catch {
            print("保存失败: \(error)")
        }
    }
}
