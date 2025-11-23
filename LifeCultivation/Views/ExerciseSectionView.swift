//
//  ExerciseSectionView.swift
//  LifeCultivation
//
//  Created by luke on 2025/11/23.
//

// ExerciseSectionView.swift
import SwiftUI

struct ExerciseSectionView: View {
    @Binding var exerciseCount: Int
    @Binding var exerciseDone: Bool

    private var exerciseScore: Int {
        return exerciseCount
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("今日锻炼")
                    .font(.headline)
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("得分: \(exerciseScore)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    Image(systemName: exerciseDone ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(exerciseDone ? .green : .gray)
                }
            }

            Text("每次锻炼加1分，每周完成3次额外加1分")
                .font(.caption)
                .foregroundColor(.secondary)

            HStack {
                Text("锻炼次数:")
                    .font(.subheadline)
                Spacer()
                HStack(spacing: 12) {
                    Button(action: {
                        if exerciseCount > 0 {
                            exerciseCount -= 1
                        }
                    }) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(exerciseCount > 0 ? .orange : .gray)
                    }
                    .disabled(exerciseCount == 0)

                    Text("\(exerciseCount)")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .frame(minWidth: 30)

                    Button(action: {
                        exerciseCount += 1
                        exerciseDone = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                    }
                }
            }

            Toggle("今日已锻炼", isOn: $exerciseDone)
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .onChange(of: exerciseDone) { _, newValue in
                    if newValue && exerciseCount == 0 {
                        exerciseCount = 1
                    }
                }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}
