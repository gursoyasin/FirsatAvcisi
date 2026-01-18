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
                // Premium Background
                LinearGradient(
                    colors: [Color.black, Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack {
                    ZStack {
                        // Glowing Orbs
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 200, height: 200)
                            .blur(radius: 60)
                            .offset(x: -50, y: -50)
                            
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 200, height: 200)
                            .blur(radius: 60)
                            .offset(x: 50, y: 50)
                            
                        // Icon / Logo Representation
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .shadow(color: .purple, radius: 20, x: 0, y: 0)
                    }
                    .scaleEffect(size)
                    .opacity(opacity)
                    .onAppear {
                        withAnimation(.easeIn(duration: 1.2)) {
                            self.size = 0.9
                            self.opacity = 1.00
                        }
                    }
                    
                    Text("FIRSAT AVCISI")
                        .font(.title)
                        .fontWeight(.heavy)
                        .foregroundColor(.white.opacity(0.80))
                        .padding(.top, 20)
                        .opacity(textOpacity)
                        .onAppear {
                            withAnimation(.easeIn(duration: 1.0).delay(0.5)) {
                                self.textOpacity = 1.0
                            }
                        }
                        
                    // Removed "Ultra ++ Edition" text
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
