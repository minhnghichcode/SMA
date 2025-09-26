//
//  ChatView.swift
//  MIA By HDBank
//
//  Created by Vũ Ngọc Minh on 25/9/25.
//

import SwiftUI
import UIKit

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @FocusState private var isTextFieldFocused: Bool
    // Track last appended/streaming message id to avoid redundant scrolls
    @State private var lastScrolledMessageId: UUID?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages area
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) { // Reduced spacing for denser chat look
                            ForEach(viewModel.messages) { message in
                                ChatBubbleView(
                                    message: message,
                                    onConfirm: { messageId, confirmed in
                                        viewModel.handleConfirmAction(for: messageId, confirmed: confirmed)
                                    },
                                    onSuggestedQuestionTap: { question in
                                        viewModel.sendSuggestedQuestion(question)
                                    }
                                )
                                .id(message.id)
                            }
                        }
                        .padding(.vertical, 8) // Tighter vertical padding
                    }
                    // Scroll when messages array structurally changes (new message added)
                    .onChange(of: viewModel.messages) { oldValue, newValue in
                        guard let last = viewModel.messages.last else { return }
                        // Defer to next runloop to let layout settle (prevents jump-to-top flash)
                        DispatchQueue.main.async {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                                lastScrolledMessageId = last.id
                            }
                        }
                    }
                    // Scroll during streaming chunks (text updates) using dedicated token
                    .onChange(of: viewModel.scrollToBottomToken) { _, _ in
                        guard let last = viewModel.messages.last else { return }
                        // Only auto-scroll if we're already at (or very near) bottom; naive check: same message id
                        if lastScrolledMessageId == last.id {
                            withAnimation(.linear(duration: 0.12)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        } else if lastScrolledMessageId == nil { // First load
                            proxy.scrollTo(last.id, anchor: .bottom)
                            lastScrolledMessageId = last.id
                        }
                    }
                }

                // Voice call status bar
                if viewModel.isVoiceConnecting || viewModel.isInVoiceCall || viewModel.voiceError != nil {
                    HStack(spacing: 12) {
                        if viewModel.isVoiceConnecting {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Đang kết nối cuộc gọi...")
                                .font(.footnote)
                                .foregroundColor(.themePrimary)
                        } else if viewModel.isInVoiceCall {
                            Image(systemName: "waveform")
                                .foregroundColor(.themePrimary)
                            Text("Voice call đang hoạt động")
                                .font(.footnote)
                                .foregroundColor(.themePrimary)
                        }
                        if let voiceError = viewModel.voiceError {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.red)
                            Text(voiceError)
                                .font(.footnote)
                                .foregroundColor(.red)
                                .lineLimit(2)
                        }
                        Spacer()
                        if viewModel.isInVoiceCall {
                            Button(action: { viewModel.toggleMute() }) {
                                Image(systemName: viewModel.isMuted ? "mic.slash" : "mic.fill")
                                    .foregroundColor(viewModel.isMuted ? .themeAccent : .themePrimary)
                            }
                            .buttonStyle(PlainButtonStyle())
                            Button(action: { viewModel.stopVoiceCall() }) {
                                Image(systemName: "phone.down.fill")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        } else if !viewModel.isVoiceConnecting && viewModel.voiceError != nil {
                            Button("Thử lại") {
                                viewModel.startVoiceCall()
                            }
                            .font(.footnote)
                        }
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.themeSecondary.opacity(0.35))
                    )
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Color.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red.opacity(0.08))
                        )
                        .padding(.top, 4)
                        .padding(.horizontal, 12)
                        .transition(.opacity)
                }
                
                // Input area
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(alignment: .center, spacing: 10) {
                        // Plus / attachment button
                        Button(action: {}) {
                            Image(systemName: "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.themePrimary)
                                .frame(width: 44, height: 44)
                                .background(Color.themeSecondary)
                                .clipShape(Circle())
                                .contentShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Input field + action button
                        HStack(spacing: 10) {
                            CustomTextField(
                                text: $viewModel.currentMessage,
                                placeholder: "Ask MIA",
                                isDisabled: viewModel.isStreaming,
                                onSubmit: {
                                    if !viewModel.isStreaming && !viewModel.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        viewModel.sendMessage()
                                    }
                                }
                            )
                            .focused($isTextFieldFocused)
                            .padding(.horizontal, 4)
                            .frame(height: 38)
                            
                            Group {
                                if viewModel.isStreaming {
                                    ProgressView()
                                        .scaleEffect(0.8, anchor: .center)
                                        .tint(Color.themePrimary)
                                        .frame(width: 32, height: 32)
                                } else if !viewModel.currentMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isInVoiceCall {
                                    Button(action: { viewModel.sendMessage() }) {
                                        Image(systemName: "arrow.up")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(width: 36, height: 36)
                                            .background(Color.themePrimary)
                                            .clipShape(Circle())
                                            .contentShape(Circle())
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                    .disabled(viewModel.isStreaming)
                                    .transition(.scale.combined(with: .opacity))
                                } else {
                                    // Voice call control button (idle state)
                                    if viewModel.isInVoiceCall {
                                        Button(action: { viewModel.stopVoiceCall() }) {
                                            Image(systemName: "phone.down.fill")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.white)
                                                .frame(width: 40, height: 40)
                                                .background(Color.red)
                                                .clipShape(Circle())
                                                .contentShape(Circle())
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .transition(.scale)
                                    } else if viewModel.isVoiceConnecting {
                                        ProgressView()
                                            .scaleEffect(0.9)
                                            .frame(width: 40, height: 40)
                                            .transition(.opacity)
                                    } else {
                                        Button(action: { viewModel.startVoiceCall() }) {
                                            Image(systemName: "mic")
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundColor(.themeAccent)
                                                .frame(width: 40, height: 40)
                                                .contentShape(Circle())
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                        .transition(.opacity)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.themeBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.themeBorder, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.themeInputBackground)
                }
            }
            .navigationTitle("MIA Chatbot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear") {
                        viewModel.clearChat()
                    }
                    .font(.headline)
                    .foregroundColor(.themePrimary)
                    .disabled(viewModel.isStreaming)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .contentShape(RoundedRectangle(cornerRadius: 8))
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Image("avatar_chatbot")
                        .resizable()
                        .frame(width: 30, height: 30)
                        .clipShape(Circle())
                }
            }
        }
        .onTapGesture {
            isTextFieldFocused = false
        }
    }
}

struct CustomTextField: UIViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var isDisabled: Bool = false
    var onSubmit: () -> Void
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.delegate = context.coordinator
        textField.returnKeyType = .send
        textField.isEnabled = !isDisabled
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        uiView.isEnabled = !isDisabled
        if isDisabled && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: CustomTextField
        
        init(_ parent: CustomTextField) {
            self.parent = parent
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            guard !parent.isDisabled else { return false }
            parent.onSubmit()
            return false // Prevent new line
        }
    }
}

#Preview {
    ChatView()
}
