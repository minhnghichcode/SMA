//
//  BiometricService.swift
//  MIA By HDBank
//
//  Created by minhhoccode on 26/9/25.
//

import Foundation
import LocalAuthentication
import SwiftUI

enum BiometricType {
    case none
    case touchID
    case faceID
    case opticID
}

enum BiometricError: LocalizedError {
    case notAvailable
    case notEnrolled
    case authenticationFailed
    case userCancel
    case systemCancel
    case biometryLockout
    case biometryNotAvailable
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "Thiết bị không hỗ trợ sinh trực học"
        case .notEnrolled:
            return "Chưa thiết lập sinh trực học"
        case .authenticationFailed:
            return "Xác thực sinh trực học thất bại"
        case .userCancel:
            return "Người dùng hủy xác thực"
        case .systemCancel:
            return "Hệ thống hủy xác thực"
        case .biometryLockout:
            return "Sinh trực học bị khóa"
        case .biometryNotAvailable:
            return "Sinh trực học không khả dụng"
        case .unknown:
            return "Lỗi không xác định"
        }
    }
}

final class BiometricService {
    private let context = LAContext()
    
    var biometricType: BiometricType {
        let _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .none:
            return .none
        case .touchID:
            return .touchID
        case .faceID:
            return .faceID
        case .opticID:
            return .opticID
        @unknown default:
            return .none
        }
    }
    
    var isAvailable: Bool {
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }
    
    var isDevicePasscodeAvailable: Bool {
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }
    
    func authenticate(reason: String) async -> Result<Bool, BiometricError> {
        guard isAvailable else {
            return .failure(.notAvailable)
        }
        
        do {
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return .success(result)
        } catch let error as LAError {
            return .failure(mapLAError(error))
        } catch {
            return .failure(.unknown)
        }
    }
    
    func authenticateWithDevicePasscode(reason: String) async -> Result<Bool, BiometricError> {
        guard isDevicePasscodeAvailable else {
            return .failure(.notAvailable)
        }
        
        do {
            let result = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: reason
            )
            return .success(result)
        } catch let error as LAError {
            return .failure(mapLAError(error))
        } catch {
            return .failure(.unknown)
        }
    }
    
    // Mock authentication for testing
    func mockAuthenticate(reason: String) async -> Result<Bool, BiometricError> {
        // Simulate FaceID animation delay
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        // Mock success (you can change this to simulate failures)
        return .success(true)
    }
    
    private func mapLAError(_ error: LAError) -> BiometricError {
        switch error.code {
        case .authenticationFailed:
            return .authenticationFailed
        case .userCancel:
            return .userCancel
        case .systemCancel:
            return .systemCancel
        case .biometryLockout:
            return .biometryLockout
        case .biometryNotAvailable:
            return .biometryNotAvailable
        case .biometryNotEnrolled:
            return .notEnrolled
        default:
            return .unknown
        }
    }
}