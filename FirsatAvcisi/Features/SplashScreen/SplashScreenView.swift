import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false
    @State private var size = 0.8
    @State private var opacity = 0.5
    @State private var textOpacity = 0.0
    
    @EnvironmentObject var authViewModel: AuthViewModel
    
    var body: some View {
        if isActive {
            if authViewModel.userSession != nil {
                MainTabView()
            } else {
                LoginView() // Assuming LoginView exists, or directly Dashboard if no auth required yet
            }
        } else {
            ZStack {
                // Professional Minimalist Background
                Color(uiColor: .systemBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    Spacer()
                    
                    // Main Logo Icon
                    Image(systemName: "bolt.shield.fill") // More "Hunter/Guard" vibe
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(size)
                        .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    // App Title
                    Text("FIRSAT AVCISI")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .tracking(2) // Premium letter spacing
                        .foregroundColor(.primary)
                        .opacity(textOpacity)
                    
                    Spacer()
                    
                    // Subtle Footer
                    Text("Powered by HunterAI")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary.opacity(0.6))
                        .padding(.bottom, 40)
                        .opacity(textOpacity)
                }
                .onAppear {
                    // Staggered Animation
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                        self.size = 1.0
                        self.opacity = 1.0
                    }
                    
                    withAnimation(.easeIn(duration: 0.8).delay(0.3)) {
                        self.textOpacity = 1.0
                    }
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        self.isActive = true
                    }
                }
            }
        }
    }
}
