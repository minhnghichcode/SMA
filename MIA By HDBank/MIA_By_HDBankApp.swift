//
//  MIA_By_HDBankApp.swift
//  MIA By HDBank
//
//  Created by Vũ Ngọc Minh on 25/9/25.
//

import SwiftUI
import AVFoundation

@main
struct MIA_By_HDBankApp: App {
    init() {
        // Yêu cầu quyền micro sớm để tránh gián đoạn khi bắt đầu voice call
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            print("🎤 Microphone permission granted: \(granted)")
        }
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
