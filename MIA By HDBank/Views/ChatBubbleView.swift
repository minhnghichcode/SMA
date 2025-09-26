//
//  ChatBubbleView.swift
//  MIA By HDBank
//
//  Created by Vũ Ngọc Minh on 25/9/25.
//

import SwiftUI

struct ChatBubbleView: View {
    let message: Message
    let onConfirm: ((UUID, Bool) -> Void)?
    let onSuggestedQuestionTap: ((String) -> Void)?
    
    init(message: Message, onConfirm: ((UUID, Bool) -> Void)? = nil, onSuggestedQuestionTap: ((String) -> Void)? = nil) {
        self.message = message
        self.onConfirm = onConfirm
        self.onSuggestedQuestionTap = onSuggestedQuestionTap
    }
    
    var body: some View {
        let trimmed = message.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let isLoadingBot = !message.isFromUser && trimmed.isEmpty
        let displayText = isLoadingBot ? "Đang phản hồi..." : message.text
        let botForeground = isLoadingBot ? Color.themeSecondaryText.opacity(0.7) : Color.themeSecondaryText
        
        HStack(alignment: .bottom, spacing: 8) {
            if message.isFromUser {
                Spacer(minLength: 48)
                
                Text(displayText)
                    .font(.body)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.themePrimary)
                    .foregroundColor(.themePrimaryText)
                    .clipShape(
                        .rect(
                            topLeadingRadius: 18,
                            bottomLeadingRadius: 18,
                            bottomTrailingRadius: 4,
                            topTrailingRadius: 18
                        )
                    )
                    .fixedSize(horizontal: false, vertical: true)
                
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    // Text content
                    if !displayText.isEmpty && message.type != .confirm {
                        Group {
                            if isLoadingBot {
                                Text(displayText)
                                    .font(.subheadline)
                            } else {
                                SimpleMarkdownView(text: message.text)
                                    .font(.body)
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.themeSecondary)
                        .foregroundColor(botForeground)
                        .clipShape(
                            .rect(
                                topLeadingRadius: 4,
                                bottomLeadingRadius: message.type == .transactionChart || message.type == .confirm ? 4 : 18,
                                bottomTrailingRadius: message.type == .transactionChart || message.type == .confirm ? 4 : 18,
                                topTrailingRadius: 18
                            )
                        )
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    // Confirmation view
                    if message.type == .confirm {
                        ConfirmationView(
                            message: message,
                            onConfirm: {
                                onConfirm?(message.id, true)
                            },
                            onDeny: {
                                onConfirm?(message.id, false)
                            }
                        )
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Color.themeSecondary)
                        .clipShape(
                            .rect(
                                topLeadingRadius: 4,
                                bottomLeadingRadius: 18,
                                bottomTrailingRadius: 18,
                                topTrailingRadius: 18
                            )
                        )
                    }
                    
                    // Transaction chart
                    if message.type == .transactionChart, 
                       let transactionData = message.transactionData,
                       !transactionData.isEmpty {
                        TransactionChartView(transactions: transactionData)
                    }
                }
                
                Spacer(minLength: 48)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 2)
        
        // Show suggested questions for bot messages (only for the last bot message and if not streaming)
        if !message.isFromUser, 
           let suggestedQuestions = message.suggestedQuestions,
           !suggestedQuestions.isEmpty,
           !isLoadingBot {
            SuggestedQuestionsView(questions: suggestedQuestions) { question in
                onSuggestedQuestionTap?(question)
            }
            .padding(.top, 4)
        }
    }
}

#Preview {
    VStack {
        ChatBubbleView(message: Message(text: "Hello! This is a user message", isFromUser: true))
        ChatBubbleView(message: Message(text: "Hello! This is a bot response", isFromUser: false))
        
        let sampleTransactions = [
            TransactionData(month: "Tháng 7", income: 32000000, expense: 25000000),
            TransactionData(month: "Tháng 8", income: 33500000, expense: 27000000)
        ]
        
        ChatBubbleView(message: Message(
            text: "Đây là báo cáo thu chi của bạn:",
            isFromUser: false,
            type: .transactionChart,
            transactionData: sampleTransactions
        ))
        
        ChatBubbleView(
            message: Message(
                text: "Bạn có muốn chuyển tiền 500,000 VND đến tài khoản 123456789? ~confirm~",
                isFromUser: false,
                type: .confirm,
                confirmAction: "Chuyển tiền 500,000 VND đến tài khoản 123456789"
            ),
            onConfirm: { messageId, confirmed in
                print("Message \(messageId) \(confirmed ? "confirmed" : "denied")")
            }
        )
        
        ChatBubbleView(
            message: {
                var messageWithSuggestions = Message(text: "Chào bạn! Tôi có thể giúp gì cho bạn hôm nay?", isFromUser: false)
                messageWithSuggestions.suggestedQuestions = [
                    "Làm thế nào để tối ưu?",
                    "Tôi cần làm gì?", 
                    "Có rủi ro không?"
                ]
                return messageWithSuggestions
            }(),
            onSuggestedQuestionTap: { question in
                print("Tapped suggested question: \(question)")
            }
        )
    }
}