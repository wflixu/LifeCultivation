//
//  ExerciseSectionView.swift
//  LifeCultivation
//
//  Created by luke on 2025/11/23.
//

// ExerciseSectionView.swift
import SwiftUI

struct ExerciseSectionView: View {
    @Binding var exerciseDone: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日锻炼")
                    .font(.headline)
                Spacer()
                Image(systemName: exerciseDone ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(exerciseDone ? .green : .gray)
            }
            
            Text("每周完成3次锻炼可获得额外奖励分")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Toggle("今日已完成锻炼", isOn: $exerciseDone)
                .toggleStyle(SwitchToggleStyle(tint: .green))
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}
