//
//  ScoreCardView.swift
//  LifeCultivation
//
//  Created by luke on 2025/11/23.
//

import SwiftUI

struct ScoreCardView: View {
    let totalScore: Int
    let dietScore: Int
    let sleepScore: Int
    let screenScore: Int
    
    private var rating: String {
        switch totalScore {
        case 10: return "自律大师"
        case 8...9: return "高手"
        case 6...7: return "践行者"
        case 4...5: return "新手"
        default: return "休整日"
        }
    }
    
    private var ratingColor: Color {
        switch totalScore {
        case 8...10: return .green
        case 6...7: return .blue
        case 4...5: return .orange
        default: return .red
        }
    }
    
    var body: some View {
        VStack(spacing: 15) {
            Text("\(totalScore)")
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(ratingColor)
            
            Text(rating)
                .font(.title2)
                .foregroundColor(ratingColor)
            
            HStack(spacing: 20) {
                ScorePill(title: "饮食", score: dietScore, maxScore: 3)
                ScorePill(title: "作息", score: sleepScore, maxScore: 3)
                ScorePill(title: "屏幕", score: screenScore, maxScore: 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}

struct ScorePill: View {
    let title: String
    let score: Int
    let maxScore: Int
    
    var body: some View {
        VStack {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text("\(score)/\(maxScore)")
                .font(.system(size: 16, weight: .semibold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.orange.opacity(0.1))
        .cornerRadius(20)
    }
}
