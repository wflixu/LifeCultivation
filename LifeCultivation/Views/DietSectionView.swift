//
//  DietSectionView.swift
//  LifeCultivation
//
//  Created by luke on 2025/11/23.
//

// DietSectionView.swift
import SwiftUI

struct DietSectionView: View {
    @Binding var breakfast: Bool
    @Binding var lunch: Bool
    @Binding var dinner: Bool
    @Binding var noSpicy: Bool
    @Binding var noJunk: Bool
    let score: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "健康饮食", score: score, maxScore: 3)
            
            VStack(spacing: 10) {
                ToggleRow(title: "三餐规律", isOn: Binding(
                    get: { breakfast && lunch && dinner },
                    set: { newValue in
                        breakfast = newValue
                        lunch = newValue
                        dinner = newValue
                    }
                ))
                
                ToggleRow(title: "不吃辛辣", isOn: $noSpicy)
                ToggleRow(title: "不吃垃圾食品", isOn: $noJunk)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}

struct SectionHeader: View {
    let title: String
    let score: Int
    let maxScore: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            Text("\(score)/\(maxScore)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.orange)
        }
    }
}

struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(.body)
        }
        .toggleStyle(SwitchToggleStyle(tint: .orange))
    }
}

