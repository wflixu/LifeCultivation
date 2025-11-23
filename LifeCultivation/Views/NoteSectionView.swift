//
//  NoteSectionView.swift
//  LifeCultivation
//
//  Created by luke on 2025/11/23.
//
// NoteSectionView.swift
import SwiftUI

struct NoteSectionView: View {
    @Binding var note: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今日备注")
                .font(.headline)
            
            TextField("记录今天的心得体会...", text: $note, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(color: .gray.opacity(0.2), radius: 5)
    }
}

struct SaveButtonView: View {
    let onSave: () -> Void
    
    var body: some View {
        Button(action: onSave) {
            Text("保存记录")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .cornerRadius(12)
        }
    }
}
