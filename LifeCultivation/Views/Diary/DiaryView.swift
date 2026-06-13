import SwiftUI

struct DiaryView: View {
    @Bindable var diaryVM: DiaryViewModel
    @Bindable var nutritionCardsVM: NutritionCardsViewModel
    @Bindable var waterCardVM: WaterCardViewModel
    @Bindable var exerciseCardVM: ExerciseCardViewModel
    @Bindable var addFoodVM: AddFoodViewModel

    @State private var showCalendarPicker = false
    @State private var calendarDate: Date = Date()

    private let calendar = Calendar.current

    private var dates: [Date] {
        let today = Calendar.current.startOfDay(for: Date())
        let past = (1...365).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: today) }.reversed()
        let future = (1...7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: today) }
        return past + [today] + future
    }

    var body: some View {
        VStack(spacing: 0) {
            dateHeader
            diaryPages
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $diaryVM.showNutritionDetail) {
            NutritionDetailView(record: diaryVM.records[diaryVM.currentDate])
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        HStack {
            Text(dayLabel(diaryVM.currentDate))
                .font(.title2.weight(.bold))

            Spacer()

            Button {
                calendarDate = diaryVM.currentDate
                showCalendarPicker = true
            } label: {
                Image(systemName: "calendar")
                    .font(.title3)
                    .foregroundStyle(.orange)
            }
            .sheet(isPresented: $showCalendarPicker) {
                VStack {
                    DatePicker(
                        "选择日期",
                        selection: $calendarDate,
                        in: dates.first!...dates.last!,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    .onChange(of: calendarDate) { _, newDate in
                        let start = Calendar.current.startOfDay(for: newDate)
                        diaryVM.onDateChanged(start)
                        showCalendarPicker = false
                    }
                }
                .presentationDetents([.medium])
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.regularMaterial)
    }

    // MARK: - Diary Pages

    private var diaryPages: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(dates, id: \.self) { date in
                    DiaryPageView(
                        record: diaryVM.records[date],
                        nutritionCardsVM: nutritionCardsVM,
                        waterCardVM: waterCardVM,
                        exerciseCardVM: exerciseCardVM,
                        addFoodVM: addFoodVM,
                        date: date,
                        showNutritionDetail: $diaryVM.showNutritionDetail
                    )
                    .id(date)
                    .containerRelativeFrame(.horizontal)
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: Binding(
            get: { diaryVM.currentDate },
            set: { newDate in
                if let date = newDate {
                    diaryVM.onDateChanged(date)
                }
            }
        ))
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
    }

    // MARK: - Helpers

    private func dayLabel(_ date: Date) -> String {
        if calendar.isDateInToday(date) { return "今天" }
        if calendar.isDateInYesterday(date) { return "昨天" }
        if calendar.isDateInTomorrow(date) { return "明天" }
        let df = DateFormatter()
        df.dateFormat = "M月d日"
        return df.string(from: date)
    }
}
