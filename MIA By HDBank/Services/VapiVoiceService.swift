//
//  VapiVoiceService.swift
//  MIA By HDBank
//
//  Created for integrating Vapi voice assistant.
//
import Foundation
import AVFoundation
import Combine

#if canImport(Vapi)
import Vapi
#endif

final class VapiVoiceService: NSObject {
    static let shared = VapiVoiceService()
    
    #if canImport(Vapi)
    private var vapi: Vapi?
    private var cancellables = Set<AnyCancellable>()
    #endif
    
    private override init() { }
    
    struct Callbacks {
        let onStarted: () -> Void
        let onTranscript: (_ text: String, _ isUser: Bool) -> Void
        let onAppMessage: (_ payload: [String: Any]) -> Void
        let onEnded: () -> Void
        let onError: (_ error: Error) -> Void
    }
    
    private var callbacks: Callbacks?
    
    func startCall(assistantId: String, overrides: [String: Any] = [:], onStarted: @escaping () -> Void, onTranscript: @escaping (_ text: String, _ isUser: Bool) -> Void, onAppMessage: @escaping (_ payload: [String: Any]) -> Void, onEnded: @escaping () -> Void, onError: @escaping (_ error: Error) -> Void) {
        guard !assistantId.isEmpty else {
            onError(NSError(domain: "VapiVoiceService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Assistant ID trống."]))
            return
        }
        #if canImport(Vapi)
        // Khởi tạo Vapi nếu chưa có hoặc apiKey thay đổi
        if vapi == nil, !Config.vapiApiKey.isEmpty {
            vapi = Vapi(publicKey: Config.vapiApiKey)
            attachEvents(onStarted: onStarted, onTranscript: onTranscript, onAppMessage: onAppMessage, onEnded: onEnded, onError: onError)
        }
        guard let vapi else {
            onError(NSError(domain: "VapiVoiceService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Chưa cấu hình Vapi API Key."]))
            return
        }
        callbacks = Callbacks(onStarted: onStarted, onTranscript: onTranscript, onAppMessage: onAppMessage, onEnded: onEnded, onError: onError)
        
        // Sử dụng assistantId hoặc assistant object tùy theo overrides
        Task {
            do {
                if overrides.isEmpty {
                    _ = try await vapi.start(assistantId: assistantId)
                } else {
                    // Tạo assistant object với overrides
                    var assistant: [String: Any] = [
                        "model": [
                            "provider": "openai",
                            "model": "gpt-4",
                            "messages": [
                                ["role": "system", "content": "Bạn là MIA, trợ lý tài chính thông minh của HDBank. Hãy trả lời bằng tiếng Việt một cách thân thiện và hữu ích."]
                            ]
                        ],
                        "firstMessage": "Xin chào! Tôi là MIA, trợ lý tài chính của bạn. Tôi có thể giúp gì cho bạn hôm nay?",
                        "voice": [
                            "provider": "11labs",
                            "voiceId": "pNInz6obpgDQGcFmaJgB"
                        ]
                    ]
                    // Merge overrides
                    for (key, value) in overrides {
                        assistant[key] = value
                    }
                    _ = try await vapi.start(assistant: assistant)
                }
            } catch {
                await MainActor.run {
                    onError(error)
                }
            }
        }
        #else
        onError(NSError(domain: "VapiVoiceService", code: -999, userInfo: [NSLocalizedDescriptionKey: "Vapi SDK chưa được thêm vào target."]))
        #endif
    }
    
    func stopCall() {
        #if canImport(Vapi)
        vapi?.stop()
        #endif
    }
    
    func setMuted(_ muted: Bool) {
        #if canImport(Vapi)
        // Vapi SDK không có setMuted method trực tiếp, có thể cần implement khác
        // Tạm thời để trống, có thể sử dụng AVAudioSession
        do {
            let audioSession = AVAudioSession.sharedInstance()
            if muted {
                try audioSession.setActive(false)
            } else {
                try audioSession.setActive(true)
            }
        } catch {
            callbacks?.onError(error)
        }
        #endif
    }
    
    #if canImport(Vapi)
    private func attachEvents(onStarted: @escaping () -> Void, onTranscript: @escaping (_ text: String, _ isUser: Bool) -> Void, onAppMessage: @escaping (_ payload: [String: Any]) -> Void, onEnded: @escaping () -> Void, onError: @escaping (_ error: Error) -> Void) {
        guard let vapi else { return }
        
        vapi.eventPublisher
            .sink { [weak self] event in
                switch event {
                case .callDidStart:
                    onStarted()
                case .callDidEnd:
                    onEnded()
                case .transcript(let transcript):
                    // transcript có thuộc tính transcript và role
                    let text = transcript.transcript
                    let isUser = transcript.role == .user
                    onTranscript(text, isUser)
                case .conversationUpdate(let update):
                    // Convert ConversationUpdate to dictionary if needed
                    print("📱 Conversation update: \(update)")
                    // Có thể parse thêm data từ update nếu cần
                case .functionCall(let functionCall):
                    // Convert FunctionCall to dictionary if needed
                    print("📱 Function call: \(functionCall)")
                    // Có thể parse thêm data từ functionCall nếu cần
                case .error(let error):
                    onError(error)
                default:
                    // Log other events for debugging
                    print("📱 Vapi event: \(event)")
                }
            }
            .store(in: &cancellables)
    }
    #endif
}
