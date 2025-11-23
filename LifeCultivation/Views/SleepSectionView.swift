//
//  Untitled.swift
//  LifeCultivation
//
//  Created by luke on 2025/11/23.
//
// SleepSectionView.swift
import SwiftUI

struct SleepSectionView: View {
    @Binding var sleepOnTime: Bool
    @Binding var wakeOnTime: Bool
    let score: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "规律作息", score: score, maxScore: 3)
            
            VStack(spacing: 10) {
                ToggleRow(title: "按时早睡", isOn: $sleepOnTime)
                ToggleRow(title: "按时早起", isOn: $wakeOnTime)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}
