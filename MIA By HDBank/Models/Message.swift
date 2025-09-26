//
//  Message.swift
//  MIA By HDBank
//
//  Created by Vũ Ngọc Minh on 25/9/25.
//

import Foundation

enum MessageType: String, Codable {
    case text
    case transactionChart
    case confirm
}

struct Message: Identifiable, Codable, Equatable {
    var id: UUID
    var text: String
    let isFromUser: Bool
    let timestamp: Date
    let type: MessageType
    var transactionData: [TransactionData]?
    var confirmAction: String?
    var isConfirmProcessed: Bool
    var messageId: String? // Message ID from LLM stream for suggested questions
    var suggestedQuestions: [String]? // Suggested questions for this message
    
    init(id: UUID = UUID(), text: String, isFromUser: Bool, timestamp: Date = Date(), type: MessageType = .text, transactionData: [TransactionData]? = nil, confirmAction: String? = nil, messageId: String? = nil, suggestedQuestions: [String]? = nil) {
        self.id = id
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = timestamp
        self.type = type
        self.transactionData = transactionData
        self.confirmAction = confirmAction
        self.isConfirmProcessed = false
        self.messageId = messageId
        self.suggestedQuestions = suggestedQuestions
    }
}
