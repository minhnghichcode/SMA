//
//  ContentView.swift
//  MIA By HDBank
//
//  Created by Vũ Ngọc Minh on 25/9/25.
//

import SwiftUI

struct ContentView: View {
    @State private var showSplash = true
    @State private var hasAppeared = false

    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                ChatView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.45), value: showSplash)
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
