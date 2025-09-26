//
//  SuggestedQuestionsView.swift
//  MIA By HDBank
//
//  Created by minhhoccode on 26/9/25.
//

import SwiftUI

struct SuggestedQuestionsView: View {
    let questions: [String]
    let onQuestionTap: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if !questions.isEmpty {
                Text("Gợi ý câu hỏi:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(questions, id: \.self) { question in
                            Button(action: {
                                onQuestionTap(question)
                            }) {
                                Text(question)
                                    .font(.caption)
                                    .foregroundColor(.primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color(UIColor.systemGray6))
                                            .stroke(Color(UIColor.systemGray4), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .contentShape(Rectangle())
                            .frame(minHeight: 44)
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .padding(.bottom, 8)
            }
        }
    }
}

#Preview {
    SuggestedQuestionsView(
        questions: [
            "Làm thế nào để tối ưu?",
            "Tôi cần làm gì?", 
            "Có rủi ro không?"
        ],
        onQuestionTap: { question in
            print("Tapped: \(question)")
        }
    )
    .previewLayout(.sizeThatFits)
}