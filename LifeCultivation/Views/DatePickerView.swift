//
//  DatePickerView.swift
//  LifeCultivation
//
//  Created by luke on 2025/11/23.
//

import SwiftUI

struct DatePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedDate: Date
    let onDateChanged: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("选择日期")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding(.top)

                DatePicker(
                    "选择日期",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding()
                .onChange(of: selectedDate) { _, _ in
                    onDateChanged()
                }

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("确定") {
                        dismiss()
                    }
                }
            }
        }
    }
}