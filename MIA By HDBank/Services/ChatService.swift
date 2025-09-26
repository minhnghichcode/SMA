//
//  ChatService.swift
//  MIA By HDBank
//
//  Created by minhhoccode on 25/9/25.
// 
//

import Foundation

enum ChatEvent {
    case conversation(String)
    case messageChunk(String)
    case messageId(String) // New event for message ID
    case transactionData([TransactionData])
    case finished
}

enum ChatServiceError: LocalizedError {
    case invalidResponse
    case invalidStatusCode(Int)
    case decodingFailed
    case cancelled
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Máy chủ phản hồi không hợp lệ."
        case .invalidStatusCode(let status):
            return "Yêu cầu thất bại với mã lỗi \(status)."
        case .decodingFailed:
            return "Không thể đọc dữ liệu phản hồi từ máy chủ."
        case .cancelled:
            return "Yêu cầu đã bị hủy."
        }
    }
}

struct ChatRequestPayload: Encodable {
    let inputs: [String: String]
    let query: String
    let responseMode: String
    let conversationId: String
    let user: String
    
    enum CodingKeys: String, CodingKey {
        case inputs
        case query
        case responseMode = "response_mode"
        case conversationId = "conversation_id"
        case user
    }
}

private struct StreamingEnvelope: Decodable {
    let event: String
    let conversationId: String?
    let messageId: String? // Message ID from stream
    let answer: String?
    let data: StreamingData?
    
    enum CodingKeys: String, CodingKey {
        case event
        case conversationId = "conversation_id"
        case messageId = "message_id"
        case answer
        case data
    }
}

private struct StreamingData: Decodable {
    let outputs: StreamingOutputs?
}

private struct StreamingOutputs: Decodable {
    let answer: String?
}

// Struct for suggested questions response
struct SuggestedQuestionsResponse: Decodable {
    let data: [String]
}

final class ChatService {
    private let endpoint: URL
    private let apiToken: String
    private let urlSession: URLSession
    private let decoder: JSONDecoder
    
    init(apiToken: String? = nil, session: URLSession = .shared) {
        self.endpoint = URL(string: Config.apiEndpoint)!
        self.apiToken = apiToken ?? Config.apiKey
        self.urlSession = session
        self.decoder = JSONDecoder()
    }
    
    func getSuggestedQuestions(for messageId: String) async throws -> [String] {
        var urlComponents = URLComponents(string: "\(Config.apiEndpoint.replacingOccurrences(of: "/chat-messages", with: ""))/messages/\(messageId)/suggested")!
        urlComponents.queryItems = [
            URLQueryItem(name: "user", value: "ios-client")
        ]
        
        guard let url = urlComponents.url else {
            throw ChatServiceError.invalidResponse
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Debug logging - print curl command
        print("🔗 Suggested Questions API Call:")
        print("curl -X GET '\(url.absoluteString)' \\")
        print("  -H 'Authorization: Bearer \(apiToken.prefix(10))...' \\")
        print("  -H 'Content-Type: application/json'")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw ChatServiceError.invalidResponse
        }
        
        print("📊 Response Status Code: \(httpResponse.statusCode)")
        print("📊 Response Headers: \(httpResponse.allHeaderFields)")
        
        if let responseString = String(data: data, encoding: .utf8) {
            print("📄 Response Body: \(responseString)")
        }
        
        guard 200..<300 ~= httpResponse.statusCode else {
            print("❌ API Error: Status \(httpResponse.statusCode)")
            throw ChatServiceError.invalidStatusCode(httpResponse.statusCode)
        }
        
        let suggestedResponse = try decoder.decode(SuggestedQuestionsResponse.self, from: data)
        print("✅ Successfully fetched \(suggestedResponse.data.count) suggested questions: \(suggestedResponse.data)")
        return suggestedResponse.data
    }
    
    func streamChat(query: String, conversationId: String?) -> AsyncThrowingStream<ChatEvent, Error> {
        let payload = ChatRequestPayload(
            inputs: [:],
            query: query,
            responseMode: "streaming",
            conversationId: conversationId ?? "",
            user: "ios-client"
        )
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 60
        
        do {
            request.httpBody = try JSONEncoder().encode(payload)
        } catch {
            return AsyncThrowingStream { continuation in
                continuation.finish(throwing: error)
            }
        }
        
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    let (bytes, response) = try await urlSession.bytes(for: request)
                    try Task.checkCancellation()
                    guard let httpResponse = response as? HTTPURLResponse else {
                        throw ChatServiceError.invalidResponse
                    }
                    guard 200..<300 ~= httpResponse.statusCode else {
                        throw ChatServiceError.invalidStatusCode(httpResponse.statusCode)
                    }
                    
                    var hasSentFinished = false
                    
                    for try await line in bytes.lines {
                        if Task.isCancelled {
                            throw ChatServiceError.cancelled
                        }
                        guard line.hasPrefix("data:") else { continue }
                        let jsonString = String(line.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !jsonString.isEmpty, jsonString != "[DONE]" else { continue }
                        guard let jsonData = jsonString.data(using: .utf8) else {
                            continue
                        }
                        
                        let envelope: StreamingEnvelope
                        do {
                            envelope = try decoder.decode(StreamingEnvelope.self, from: jsonData)
                        } catch {
                            throw ChatServiceError.decodingFailed
                        }
                        
                        switch envelope.event {
                        case "workflow_started":
                            if let id = envelope.conversationId {
                                continuation.yield(.conversation(id))
                            }
                        case "message":
                            // Capture message ID from the first message event
                            if let msgId = envelope.messageId {
                                continuation.yield(.messageId(msgId))
                            }
                            if let chunk = envelope.answer, !chunk.isEmpty {
                                continuation.yield(.messageChunk(chunk))
                            }
                        case "agent_log":
                            // Debug: Print the raw JSON for transaction-related agent_log events
                            if let jsonString = String(data: jsonData, encoding: .utf8),
                               jsonString.contains("income_api_get_transaction_history_get") {
                                print("Raw transaction agent_log JSON: \(jsonString)")
                            }
                            
                            // Parse agent_log for transaction data
                            if let transactionData = parseTransactionData(from: jsonData) {
                                continuation.yield(.transactionData(transactionData))
                            }
                        case "workflow_finished", "message_end":
                            if !hasSentFinished {
                                hasSentFinished = true
                                continuation.yield(.finished)
                            }
                        default:
                            break
                        }
                    }
                    
                    if !hasSentFinished {
                        continuation.yield(.finished)
                    }
                    continuation.finish()
                } catch {
                    if Task.isCancelled {
                        continuation.finish(throwing: ChatServiceError.cancelled)
                    } else {
                        continuation.finish(throwing: error)
                    }
                }
            }
            
            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
    
    private func parseTransactionData(from jsonData: Data) -> [TransactionData]? {
        do {
            let agentLogEvent = try decoder.decode(AgentLogEvent.self, from: jsonData)
            
            // Check if this is the transaction history API call
            guard agentLogEvent.data.label.contains("income_api_get_transaction_history_get"),
                  agentLogEvent.data.status == "success",
                  let dataContent = agentLogEvent.data.data,
                  let output = dataContent.output,
                  let toolResponse = output.toolResponse else {
                print("Agent log event does not contain valid transaction data structure")
                return nil
            }
            
            // Parse the JSON response from tool_response
            guard let responseData = toolResponse.data(using: .utf8) else {
                print("Failed to convert tool response to data")
                return nil
            }
            
            let transactions = try decoder.decode([TransactionData].self, from: responseData)
            print("Successfully parsed \(transactions.count) transaction records")
            return transactions
        } catch let decodingError as DecodingError {
            print("Failed to parse transaction data - DecodingError: \(decodingError)")
            switch decodingError {
            case .keyNotFound(let key, let context):
                print("Key '\(key.stringValue)' not found: \(context.debugDescription)")
            case .valueNotFound(let type, let context):
                print("Value of type '\(type)' not found: \(context.debugDescription)")
            case .typeMismatch(let type, let context):
                print("Type mismatch for '\(type)': \(context.debugDescription)")
            case .dataCorrupted(let context):
                print("Data corrupted: \(context.debugDescription)")
            @unknown default:
                print("Unknown decoding error: \(decodingError)")
            }
            return nil
        } catch {
            print("Failed to parse transaction data - Other error: \(error)")
            return nil
        }
    }
}
