import SwiftUI

struct SplashView: View {
    @State private var appeared = false
    @State private var bounce = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.08, blue: 0.12),
                    Color(red: 0.18, green: 0.06, blue: 0.10)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Soft radial glow behind the logo.
            RadialGradient(
                colors: [
                    Color(red: 1.00, green: 0.55, blue: 0.30).opacity(0.35),
                    .clear
                ],
                center: .center,
                startRadius: 20,
                endRadius: 280
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                logo

                VStack(spacing: 6) {
                    Text("PomodoCat")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.white)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)

                    Text("Focus & félins")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(2.5)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 10)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.55)) { bounce = true }
            withAnimation(.easeOut(duration: 0.6).delay(0.2)) { appeared = true }
        }
    }

    private var logo: some View {
        ZStack {
            Text("🍅")
                .font(.system(size: 130))
                .scaleEffect(bounce ? 1.0 : 0.4)
                .shadow(color: .black.opacity(0.35), radius: 24, y: 12)

            Text("🐱")
                .font(.system(size: 70))
                .offset(x: 38, y: 30)
                .scaleEffect(bounce ? 1.0 : 0.2)
                .rotationEffect(.degrees(bounce ? 0 : -25))
                .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
        }
    }
}
