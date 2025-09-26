//
//  ConfirmationView.swift
//  MIA By HDBank
//
//  Created by minhhoccode on 26/9/25.
//

import SwiftUI

struct ConfirmationView: View {
    let message: Message
    let onConfirm: () -> Void
    let onDeny: () -> Void
    
    @State private var biometricService = BiometricService()
    @State private var showFaceIDAnimation = false
    @State private var isAuthenticating = false
    @State private var authenticationResult: Result<Bool, BiometricError>?
    @State private var showManualButtons = false
    @State private var showSuccessBanner = false
    
    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 16) {
                // Message text (without ~confirm~)
                let cleanText = message.text.replacingOccurrences(of: "~confirm~", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !cleanText.isEmpty {
                    Text(cleanText)
                        .font(.body)
                        .foregroundColor(.themeSecondaryText)
                }
                
                // Confirmation section
                VStack(spacing: 16) {
                    if !message.isConfirmProcessed {
                        if isAuthenticating {
                            // FaceID Animation
                            faceIDAnimationView
                        } else if let result = authenticationResult {
                            // Show result
                            resultView(result)
                        } else {
                            // Initial confirmation buttons
                            confirmationButtons
                        }
                    }
                }
                .padding(16)
                .background(Color.themeSecondary.opacity(0.3))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            // Success Banner Overlay
            if showSuccessBanner {
                successBannerView
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showSuccessBanner)
    }
    
    @ViewBuilder
    private var faceIDAnimationView: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.themePrimary.opacity(0.3), lineWidth: 3)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .trim(from: 0, to: showFaceIDAnimation ? 1 : 0)
                    .stroke(Color.themePrimary, lineWidth: 3)
                    .frame(width: 80, height: 80)
                    .rotationEffect(Angle(degrees: -90))
                    .animation(.easeInOut(duration: 2), value: showFaceIDAnimation)
                
                Image(systemName: "faceid")
                    .font(.system(size: 40))
                    .foregroundColor(.themePrimary)
                    .scaleEffect(showFaceIDAnimation ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: showFaceIDAnimation)
            }
            
            Text("Đang xác thực Face ID...")
                .font(.subheadline)
                .foregroundColor(.themeSecondaryText)
            
            Button("Sử dụng mật khẩu máy") {
                isAuthenticating = false
                showFaceIDAnimation = false
                performPasswordAuthentication()
            }
            .font(.subheadline)
            .foregroundColor(.themePrimary)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.themePrimary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .contentShape(RoundedRectangle(cornerRadius: 10))
            .frame(minHeight: 44)
        }
        .onAppear {
            showFaceIDAnimation = true
            performAuthentication()
        }
    }
    
    @ViewBuilder
    private func resultView(_ result: Result<Bool, BiometricError>) -> some View {
        VStack(spacing: 12) {
            switch result {
            case .success(true):
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                    
                    Text("Xác thực thành công!")
                        .font(.headline)
                        .foregroundColor(.themeSecondaryText)
                    
                    Text("Đang xử lý giao dịch...")
                        .font(.subheadline)
                        .foregroundColor(.themeSecondaryText.opacity(0.8))
                }
                .onAppear {
                    // Show success banner after a short delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        showSuccessBanner = true
                    }
                    
                    // Complete transaction after banner is shown
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        onConfirm()
                    }
                }
                
            case .success(false), .failure(_):
                VStack(spacing: 12) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)
                    
                    Text("Xác thực thất bại")
                        .font(.headline)
                        .foregroundColor(.themeSecondaryText)
                    
                    if case .failure(let error) = result {
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.themeSecondaryText.opacity(0.8))
                    }
                    
                    HStack(spacing: 12) {
                        Button("Thử lại") {
                            authenticationResult = nil
                            isAuthenticating = true
                            showFaceIDAnimation = false
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        
                        Button("Hủy") {
                            onDeny()
                        }
                        .buttonStyle(SecondaryButtonStyle())
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var confirmationButtons: some View {
        VStack(spacing: 12) {
            Text("Xác nhận giao dịch")
                .font(.headline)
                .foregroundColor(.themeSecondaryText)
            
            if let action = message.confirmAction {
                Text(action)
                    .font(.subheadline)
                    .foregroundColor(.themeSecondaryText.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            if showManualButtons {
                // Manual buttons
                HStack(spacing: 12) {
                    Button("Từ chối") {
                        onDeny()
                    }
                    .buttonStyle(SecondaryButtonStyle())
                    
                    Button("Xác nhận") {
                        onConfirm()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            } else {
                // FaceID button or fallback to device passcode
                VStack(spacing: 8) {
                    if biometricService.isAvailable {
                        // Device has FaceID/TouchID
                        Button {
                            isAuthenticating = true
                            showFaceIDAnimation = false
                        } label: {
                            HStack(spacing: 12) {
                                let biometricIcon = biometricService.biometricType == .faceID ? "faceid" : 
                                                  biometricService.biometricType == .touchID ? "touchid" : "faceid"
                                let biometricName = biometricService.biometricType == .faceID ? "Face ID" :
                                                  biometricService.biometricType == .touchID ? "Touch ID" : "Face ID"
                                                  
                                Image(systemName: biometricIcon)
                                    .font(.title2)
                                Text("Xác thực với \(biometricName)")
                                    .font(.headline)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.themePrimary)
                            .foregroundColor(.themePrimaryText)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .contentShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else if biometricService.isDevicePasscodeAvailable {
                        // Device doesn't have biometrics but has passcode
                        Button {
                            performPasswordAuthentication()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "lock")
                                    .font(.title2)
                                Text("Xác thực với mật khẩu máy")
                                    .font(.headline)
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.themePrimary)
                            .foregroundColor(.themePrimaryText)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .contentShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        // No authentication available, show manual buttons
                        Text("Thiết bị không hỗ trợ xác thực")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Button("Hoặc sử dụng nút bấm") {
                        showManualButtons = true
                    }
                    .font(.subheadline)
                    .foregroundColor(.themePrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.themePrimary.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .contentShape(RoundedRectangle(cornerRadius: 8))
                    .frame(minHeight: 44)
                }
            }
        }
    }
    
    private func performAuthentication() {
        Task {
            // Use real FaceID authentication
            let result = await biometricService.authenticate(reason: "Xác thực để xác nhận giao dịch")
            
            await MainActor.run {
                isAuthenticating = false
                authenticationResult = result
            }
        }
    }
    
    private func performPasswordAuthentication() {
        Task {
            // Use device passcode authentication
            let result = await biometricService.authenticateWithDevicePasscode(reason: "Xác thực để xác nhận giao dịch")
            
            await MainActor.run {
                authenticationResult = result
            }
        }
    }
    
    @ViewBuilder
    private var successBannerView: some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    // Success Animation
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                            .scaleEffect(showSuccessBanner ? 1.2 : 0.1)
                            .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: showSuccessBanner)
                    }
                    
                    VStack(spacing: 8) {
                        Text("ĐÃ ĐẦU TƯ THÀNH CÔNG")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        
                        Text("Giao dịch đã được xác nhận")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Dismiss button
                    Button("Hoàn tất") {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showSuccessBanner = false
                        }
                    }
                    .buttonStyle(BannerButtonStyle())
                    .padding(.top, 8)
                }
                .padding(24)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.green.opacity(0.9),
                            Color.green.opacity(0.7)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 5)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 50)
            
            Spacer()
        }
        .background(Color.black.opacity(0.4))
        .onTapGesture {
            // Allow dismissing by tapping outside
            withAnimation(.easeInOut(duration: 0.3)) {
                showSuccessBanner = false
            }
        }
    }
}

// MARK: - Custom Button Styles

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.themePrimaryText)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(minHeight: 50)
            .frame(maxWidth: .infinity)
            .background(Color.themePrimary)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.themePrimary)
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .frame(minHeight: 50)
            .frame(maxWidth: .infinity)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.themePrimary, lineWidth: 1.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.7 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct BannerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.green)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .frame(minHeight: 50)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        ConfirmationView(
            message: Message(
                text: "Bạn có muốn chuyển tiền 500,000 VND đến tài khoản 123456789? ~confirm~",
                isFromUser: false,
                type: .confirm,
                confirmAction: "Chuyển tiền 500,000 VND đến tài khoản 123456789"
            ),
            onConfirm: { print("Confirmed") },
            onDeny: { print("Denied") }
        )
    }
    .padding()
    .background(Color.themeBackground)
}