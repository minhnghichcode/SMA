//
//  ChatViewModel.swift
//  MIA By HDBank
//
//  Created by Vũ Ngọc Minh on 25/9/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var currentMessage = ""
    @Published var isStreaming = false
    @Published var errorMessage: String?
    // Token increases to notify view to keep scrolling while current bot message is streaming
    @Published var scrollToBottomToken: Int = 0
    // Voice call state (Vapi)
    @Published var isInVoiceCall: Bool = false
    @Published var isVoiceConnecting: Bool = false
    @Published var isMuted: Bool = false
    @Published var voiceError: String?
    
    private let chatService = ChatService()
    private var conversationId: String?
    private var streamingTask: Task<Void, Never>?
    private var pendingTransactionData: [TransactionData]? // Buffer for transaction data
    private var currentMessageId: String? // Store current message ID for suggested questions
    
    deinit {
        streamingTask?.cancel()
    }
    
    init() {
        loadWelcomeMessage()
    }
    
    private func loadWelcomeMessage() {
        // Delay 1.2 seconds before showing welcome message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self else { return }
            
            let welcomeText = """
            Chào Quang, tôi là MIA, bạn đồng hành trên hành trình tự do tài chính của bạn. Tôi nhận thấy bạn đang có một khoản tiền nhàn rỗi trong tài khoản. Đừng để nó 'ngủ quên'! Tôi có thể giúp bạn biến nó thành cơ hội sinh lời, đồng thời tìm các ưu đãi độc quyền từ Sovico chỉ dành riêng cho bạn.
            """
            
            let suggestedQuestions = [
                "Chi tiết cơ hội sinh lời thế nào?",
                "Ưu đãi từ Sovico gồm những gì?",
                "Mình muốn tham gia."
            ]
            
            let welcomeMessage = Message(
                text: welcomeText,
                isFromUser: false,
                suggestedQuestions: suggestedQuestions
            )
            
            // Add message with animation
            withAnimation(.easeInOut(duration: 0.6)) {
                self.messages.append(welcomeMessage)
            }
        }
    }
    
    func sendMessage() {
        guard !isStreaming else { return }
        let trimmedMessage = currentMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMessage.isEmpty else { return }
        
        errorMessage = nil
        streamingTask?.cancel()
        
        let userMessage = Message(text: trimmedMessage, isFromUser: true)
        messages.append(userMessage)
        currentMessage = ""
        
        let botMessage = Message(text: "", isFromUser: false)
        messages.append(botMessage)
        let botMessageId = botMessage.id
        isStreaming = true
        pendingTransactionData = nil // Clear any pending data
        currentMessageId = nil // Clear any pending message ID
        
        streamingTask = Task { [weak self] in
            guard let self else { return }
            await self.handleStreamingResponse(for: trimmedMessage, botMessageId: botMessageId)
        }
    }
    
    func clearChat() {
        streamingTask?.cancel()
        streamingTask = nil
        messages.removeAll()
        conversationId = nil
        isStreaming = false
        errorMessage = nil
        pendingTransactionData = nil
        currentMessageId = nil
        
        // Reload welcome message after clearing with same delay and animation
        loadWelcomeMessage()
    }
    
    private func handleStreamingError(_ error: Error, botMessageId: UUID) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let index = self.messages.firstIndex(where: { $0.id == botMessageId }) {
                self.messages[index].text = "⚠️ Đã xảy ra lỗi khi kết nối tới máy chủ."
            }
            if let chatError = error as? ChatServiceError {
                self.errorMessage = chatError.localizedDescription
            } else {
                self.errorMessage = error.localizedDescription
            }
            self.isStreaming = false
        }
    }
    
    private func handleStreamingResponse(for query: String, botMessageId: UUID) async {
        var aggregatedResponse = ""
        do {
            for try await event in chatService.streamChat(query: query, conversationId: conversationId) {
                if Task.isCancelled { throw ChatServiceError.cancelled }
                switch event {
                case .conversation(let id):
                    conversationId = id
                case .messageId(let msgId):
                    // Store message ID for fetching suggested questions later
                    currentMessageId = msgId
                case .messageChunk(let chunk):
                    aggregatedResponse += chunk
                    DispatchQueue.main.async { [weak self] in
                        guard let self else { return }
                        if let index = self.messages.firstIndex(where: { $0.id == botMessageId }) {
                            self.messages[index].text = aggregatedResponse
                            // Increment token to trigger incremental autoscroll in view
                            self.scrollToBottomToken &+= 1 // wrapping add to avoid overflow crash
                        }
                    }
                case .transactionData(let transactions):
                    // Store transaction data to be shown after stream finishes
                    pendingTransactionData = transactions
                case .finished:
                    finalizeBotMessage(botMessageId: botMessageId, finalText: aggregatedResponse)
                    
                    // Show transaction chart if we have pending data
                    if let transactionData = pendingTransactionData {
                        let chartMessage = Message(
                            text: "Đây là báo cáo thu chi của bạn:",
                            isFromUser: false,
                            type: .transactionChart,
                            transactionData: transactionData
                        )
                        messages.append(chartMessage)
                        pendingTransactionData = nil
                    }
                    
                    // Fetch suggested questions if we have a message ID
                    if let msgId = currentMessageId {
                        await fetchSuggestedQuestions(for: botMessageId, messageId: msgId)
                    }
                    
                    isStreaming = false
                    streamingTask = nil
                    return
                }
            }
            finalizeBotMessage(botMessageId: botMessageId, finalText: aggregatedResponse)
            
            // Show transaction chart if we have pending data
            if let transactionData = pendingTransactionData {
                let chartMessage = Message(
                    text: "Đây là báo cáo thu chi của bạn:",
                    isFromUser: false,
                    type: .transactionChart,
                    transactionData: transactionData
                )
                messages.append(chartMessage)
                pendingTransactionData = nil
            }
            
            // Fetch suggested questions if we have a message ID
            if let msgId = currentMessageId {
                await fetchSuggestedQuestions(for: botMessageId, messageId: msgId)
            }
            
            isStreaming = false
            streamingTask = nil
        } catch let error as ChatServiceError {
            if case .cancelled = error {
                isStreaming = false
                streamingTask = nil
                return
            }
            handleStreamingError(error, botMessageId: botMessageId)
        } catch is CancellationError {
            isStreaming = false
            streamingTask = nil
            return
        } catch {
            handleStreamingError(error, botMessageId: botMessageId)
        }
    }
    
    private func finalizeBotMessage(botMessageId: UUID, finalText: String) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let index = self.messages.firstIndex(where: { $0.id == botMessageId }) {
                let cleanedText = finalText.trimmingCharacters(in: .whitespacesAndNewlines)
                if cleanedText.isEmpty {
                    self.messages[index].text = "Xin lỗi, tôi chưa nhận được phản hồi."
                } else {
                    self.messages[index].text = cleanedText
                    
                    // Store message ID in the message for later reference
                    if let msgId = self.currentMessageId {
                        self.messages[index].messageId = msgId
                    }
                    
                    // Check if message contains ~confirm~ and convert to confirmation message
                    if cleanedText.contains("~confirm~") {
                        self.messages[index] = Message(
                            id: self.messages[index].id,
                            text: cleanedText,
                            isFromUser: false,
                            timestamp: self.messages[index].timestamp,
                            type: .confirm,
                            confirmAction: self.extractConfirmAction(from: cleanedText),
                            messageId: self.currentMessageId
                        )
                    }
                }
            }
        }
    }
    
    // New function to fetch suggested questions
    private func fetchSuggestedQuestions(for botMessageId: UUID, messageId: String) async {
        print("🤖 Attempting to fetch suggested questions for message ID: \(messageId)")
        
        do {
            let suggestedQuestions = try await chatService.getSuggestedQuestions(for: messageId)
            
            print("✅ Successfully fetched suggested questions: \(suggestedQuestions)")
            
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                if let index = self.messages.firstIndex(where: { $0.id == botMessageId }) {
                    self.messages[index].suggestedQuestions = suggestedQuestions
                    print("✅ Updated message at index \(index) with \(suggestedQuestions.count) suggested questions")
                    // Trigger a gentle scroll so newly added suggested questions are visible
                    self.scrollToBottomToken &+= 1
                }
            }
        } catch {
            print("❌ Failed to fetch suggested questions for messageId \(messageId): \(error)")
            
            // Log more details about the error
            if let chatError = error as? ChatServiceError {
                print("❌ ChatServiceError details: \(chatError.localizedDescription)")
            }
            
            // Silently fail - suggested questions are not critical
        }
    }
    
    // Function to handle suggested question tap
    func sendSuggestedQuestion(_ question: String) {
        currentMessage = question
        sendMessage()
    }
    
    private func extractConfirmAction(from text: String) -> String? {
        // Extract the main action from the text (everything before ~confirm~)
        let components = text.components(separatedBy: "~confirm~")
        return components.first?.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func handleConfirmAction(for messageId: UUID, confirmed: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            if let index = self.messages.firstIndex(where: { $0.id == messageId }) {
                self.messages[index].isConfirmProcessed = true
                
                // Add response message
                let responseText = confirmed ? "✅ Giao dịch đã được xác nhận và thực hiện thành công!" : "❌ Giao dịch đã bị từ chối."
                let responseMessage = Message(
                    text: responseText,
                    isFromUser: false
                )
                self.messages.append(responseMessage)
                
                // If confirmed, you can add additional logic here (e.g., API calls)
                if confirmed {
                    // Handle successful confirmation logic
                    print("Transaction confirmed for message: \(messageId)")
                } else {
                    // Handle denial logic
                    print("Transaction denied for message: \(messageId)")
                }
            }
        }
    }
}

#if canImport(Vapi)
import Vapi
#endif

// MARK: - Voice (Vapi) functions tách riêng để dễ quản lý
extension ChatViewModel {
    func startVoiceCall(assistantId: String? = nil, overrides: [String: Any] = [:]) {
#if canImport(Vapi)
        guard !isInVoiceCall else { return }
        voiceError = nil
        isVoiceConnecting = true
        VapiVoiceService.shared.startCall(
            assistantId: assistantId ?? Config.vapiAssistantId,
            overrides: overrides,
            onStarted: { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.isVoiceConnecting = false
                    self.isInVoiceCall = true
                }
            },
            onTranscript: { [weak self] text, isUser in
                guard let self else { return }
                DispatchQueue.main.async {
                    // Append transcript incrementally (gộp vào 1 message cuối cùng nếu cùng speaker)
                    if let last = self.messages.last, last.isFromUser == isUser, last.type == .text, last.suggestedQuestions == nil, last.transactionData == nil, !last.text.contains("~confirm~") {
                        if let index = self.messages.firstIndex(where: { $0.id == last.id }) {
                            self.messages[index].text += (last.text.isEmpty ? "" : " ") + text
                            self.scrollToBottomToken &+= 1
                        }
                    } else {
                        self.messages.append(Message(text: text, isFromUser: isUser))
                        self.scrollToBottomToken &+= 1
                    }
                }
            },
            onAppMessage: { [weak self] payload in
                // Có thể xử lý function call / metadata tại đây
                print("📩 Vapi app message: \(payload)")
            },
            onEnded: { [weak self] in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.isInVoiceCall = false
                    self.isVoiceConnecting = false
                }
            },
            onError: { [weak self] error in
                guard let self else { return }
                DispatchQueue.main.async {
                    self.voiceError = error.localizedDescription
                    self.isVoiceConnecting = false
                    self.isInVoiceCall = false
                }
            }
        )
#else
        voiceError = "Chưa thêm Vapi SDK vào project (SPM)."
#endif
    }
    
    func stopVoiceCall() {
#if canImport(Vapi)
        VapiVoiceService.shared.stopCall()
#endif
    }
    
    func toggleMute() {
#if canImport(Vapi)
        isMuted.toggle()
        VapiVoiceService.shared.setMuted(isMuted)
#endif
    }
}

