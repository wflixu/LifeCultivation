//
//  HistoryView.swift
//  LifeCultivation
//
//  Created by luke on 2025/11/23.
//

// HistoryView.swift
import SwiftUI
import SwiftData
import Charts

struct HistoryView: View {
    @Query(sort: \DailyRecord.date, order: .reverse) private var records: [DailyRecord]
    @State private var selectedTimeRange: TimeRange = .week
    @State private var showingAddRecord = false
    @State private var editingDate: Date = Date()
    
    enum TimeRange: String, CaseIterable {
        case week = "近一周"
        case month = "近一月"
        case quarter = "近一季"
        case halfYear = "近半年"
        case year = "近一年"
        
        var dateRange: Date {
            let calendar = Calendar.current
            let now = Date()
            
            switch self {
            case .week:
                return calendar.date(byAdding: .day, value: -7, to: now)!
            case .month:
                return calendar.date(byAdding: .month, value: -1, to: now)!
            case .quarter:
                return calendar.date(byAdding: .month, value: -3, to: now)!
            case .halfYear:
                return calendar.date(byAdding: .month, value: -6, to: now)!
            case .year:
                return calendar.date(byAdding: .year, value: -1, to: now)!
            }
        }
    }
    
    private var filteredRecords: [DailyRecord] {
        records.filter { $0.date >= selectedTimeRange.dateRange }
    }
    
    private var averageScore: Double {
        guard !filteredRecords.isEmpty else { return 0 }
        let total = filteredRecords.reduce(0) { $0 + $1.totalScore }
        return Double(total) / Double(filteredRecords.count)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 时间范围选择器
                    Picker("时间范围", selection: $selectedTimeRange) {
                        ForEach(TimeRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())

                    // 平均分卡片
                    AverageScoreCard(averageScore: averageScore, recordCount: filteredRecords.count)

                    // 趋势图表
                    ScoreChartView(records: filteredRecords)

                    // 详细记录列表
                    RecordListView(
                        records: Array(filteredRecords.prefix(30)),
                        onEdit: { date in
                            editingDate = date
                            showingAddRecord = true
                        }
                    )

                    // 添加历史记录按钮（较小）
                    Button(action: {
                        showingAddRecord = true
                        editingDate = Date() // 默认今天
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle")
                            Text("补记录")
                            Image(systemName: "calendar.badge.plus")
                        }
                        .font(.subheadline)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("修行历程")
            .sheet(isPresented: $showingAddRecord) {
                HistoryEditView(date: editingDate)
            }
        }
    }
}

struct AverageScoreCard: View {
    let averageScore: Double
    let recordCount: Int
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("平均分数")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text(String(format: "%.1f", averageScore))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("记录天数")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("\(recordCount)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}

struct ScoreChartView: View {
    let records: [DailyRecord]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("分数趋势")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(records.sorted(by: { $0.date < $1.date }), id: \.date) { record in
                    LineMark(
                        x: .value("日期", record.date, unit: .day),
                        y: .value("分数", record.totalScore)
                    )
                    .foregroundStyle(.orange.gradient)
                    
                    PointMark(
                        x: .value("日期", record.date, unit: .day),
                        y: .value("分数", record.totalScore)
                    )
                    .foregroundStyle(.orange)
                }
            }
            .frame(height: 200)
            .chartYScale(domain: 0...12)
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}

struct RecordListView: View {
    let records: [DailyRecord]
    let onEdit: (Date) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("详细记录")
                .font(.headline)
                .padding(.horizontal)
            
            LazyVStack(spacing: 12) {
                ForEach(records) { record in
                    RecordRowView(record: record, onEdit: onEdit)
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}

struct RecordRowView: View {
    let record: DailyRecord
    let onEdit: (Date) -> Void
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM月dd日"
        return formatter
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(dateFormatter.string(from: record.date))
                    .font(.headline)
                Text(record.rating)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 8) {
                Text("\(record.dietScore)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.green)
                Text("\(record.sleepScore)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                Text("\(record.screenTimeScore)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.purple)
                Text("\(record.exerciseCount)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.mint)

                Text("\(record.totalScore)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.orange)
                    .frame(width: 30, alignment: .trailing)
            }

            Button(action: {
                onEdit(record.date)
            }) {
                Image(systemName: "pencil.circle")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}
