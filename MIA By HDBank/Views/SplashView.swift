import SwiftUI

struct SplashView: View {
    @State private var animateLogo = false
    @State private var animateCircles = false

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color.themePrimary, Color.themeAccent.opacity(0.85)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: geometry.size.width * 0.85)
                        .scaleEffect(animateCircles ? 1 : 0.7)
                        .offset(x: -geometry.size.width * 0.15, y: -geometry.size.height * 0.2)

                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                        .frame(width: geometry.size.width * 0.6)
                        .scaleEffect(animateCircles ? 1.1 : 0.8)
                        .offset(x: geometry.size.width * 0.3, y: geometry.size.height * 0.2)
                        .blur(radius: 1)
                }
                .animation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true), value: animateCircles)
            }

            VStack(spacing: 20) {
                Image("app_icon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                    .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 12)
                    .scaleEffect(animateLogo ? 1 : 0.7)
                    .opacity(animateLogo ? 1 : 0)

                VStack(spacing: 6) {
                    Text("MIA by HDBank")
                        .font(.system(.title, design: .rounded))
                        .fontWeight(.heavy)
                        .foregroundColor(.white)

                    Text("Trợ lý số cho mọi giao dịch thông minh")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.85))
                }

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.white.opacity(0.9)))
                    .scaleEffect(1.2)
                    .padding(.top, 16)
                    .opacity(animateLogo ? 1 : 0)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateLogo = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateCircles = true
            }
        }
    }
}

#Preview {
    SplashView()
}
