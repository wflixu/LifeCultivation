//
//  ScreenTimeSectionView.swift
//  LifeCultivation
//
//  Created by luke on 2025/11/23.
//

import SwiftUI

struct ScreenTimeSectionView: View {
    @Binding var screenTime: Double
    let score: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "屏幕时间", score: score, maxScore: 4)
            
            VStack(spacing: 15) {
                VStack(spacing: 5) {
                    Text("\(Int(screenTime)) 分钟")
                        .font(.title2)
                        .foregroundColor(.orange)
                    
                    Slider(value: $screenTime, in: 0...180, step: 5)
                        .accentColor(.orange)
                }
                
                HStack {
                    Text("≤30分钟")
                    Spacer()
                    Text("60分钟")
                    Spacer()
                    Text("≥90分钟")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}
