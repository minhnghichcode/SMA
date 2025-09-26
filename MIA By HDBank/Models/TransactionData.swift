//
//  TransactionData.swift
//  MIA By HDBank
//
//  Created by minhhoccode on 26/9/25.
//

import Foundation

struct TransactionData: Codable, Identifiable, Equatable {
    let id = UUID()
    let month: String
    let income: Double
    let expense: Double
    
    var netIncome: Double {
        return income - expense
    }
    
    enum CodingKeys: String, CodingKey {
        case month
        case income
        case expense
    }
}

struct AgentLogEvent: Codable {
    let event: String
    let conversationId: String
    let messageId: String
    let createdAt: Int
    let taskId: String
    let data: AgentLogData
    
    enum CodingKeys: String, CodingKey {
        case event
        case conversationId = "conversation_id"
        case messageId = "message_id"
        case createdAt = "created_at"
        case taskId = "task_id"
        case data
    }
}

struct AgentLogData: Codable {
    let nodeExecutionId: String
    let id: String
    let label: String
    let parentId: String?  // Make optional to handle null values
    let error: String?
    let status: String
    let data: AgentLogDataContent?  // Make optional to handle different structures
    let metadata: AgentLogMetadata
    let nodeId: String
    
    enum CodingKeys: String, CodingKey {
        case nodeExecutionId = "node_execution_id"
        case id
        case label
        case parentId = "parent_id"
        case error
        case status
        case data
        case metadata
        case nodeId = "node_id"
    }
}

struct AgentLogDataContent: Codable {
    let output: AgentLogOutput?  // Make optional to handle missing output
}

struct AgentLogOutput: Codable {
    let toolCallId: String?
    let toolCallInput: ToolCallInput?
    let toolCallName: String?
    let toolResponse: String?
    
    enum CodingKeys: String, CodingKey {
        case toolCallId = "tool_call_id"
        case toolCallInput = "tool_call_input"
        case toolCallName = "tool_call_name"
        case toolResponse = "tool_response"
    }
}

struct ToolCallInput: Codable {
    let customerId: String?  // Make optional
    
    enum CodingKeys: String, CodingKey {
        case customerId = "customer_id"
    }
}

struct AgentLogMetadata: Codable {
    let elapsedTime: Double
    let finishedAt: Double
    let provider: String
    let startedAt: Double
    
    enum CodingKeys: String, CodingKey {
        case elapsedTime = "elapsed_time"
        case finishedAt = "finished_at"
        case provider
        case startedAt = "started_at"
    }
}