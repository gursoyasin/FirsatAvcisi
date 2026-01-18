import SwiftUI
import FirebaseAuth
import AuthenticationServices

struct LoginView: View {
    @Environment(\.colorScheme) var colorScheme
    @StateObject var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var showingSignUp = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .ignoresSafeArea()
                
                if let user = viewModel.userSession {
                    // MARK: - Verification Pending View
                    VStack(spacing: 25) {
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 70))
                            .foregroundColor(.orange)
                            .padding(.bottom, 10)
                        
                        Text("E-posta Onayı Bekleniyor")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Hesabınızı tam olarak kullanabilmek için lütfen **\(user.email ?? "adresinize")** gönderilen bağlantıyı onaylayın.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            Button {
                                Task {
                                    await viewModel.checkVerificationStatus()
                                }
                            } label: {
                                HStack {
                                    Text("Onayladım, Giriş Yap")
                                    Image(systemName: "arrow.clockwise")
                                }
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            
                            Button {
                                Task {
                                    await viewModel.resendVerificationEmail()
                                }
                            } label: {
                                Text("Onay Kodunu Tekrar Gönder")
                                    .fontWeight(.medium)
                                    .foregroundColor(.blue)
                            }
                            .padding(.top, 4)
                            
                            Button {
                                viewModel.signOut()
                            } label: {
                                Text("Çıkış Yap")
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                            }
                            .padding(.top, 20)
                        }
                        .padding(.horizontal, 30)
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(20)
                    .shadow(color: .black.opacity(0.1), radius: 10)
                    .padding(30)
                    
                } else {
                    // MARK: - Login Form
                    VStack(spacing: 30) {
                        // Logo/Header
                        VStack(spacing: 12) {
                            Image(systemName: "bolt.shield.fill") // Placeholder logo
                                .font(.system(size: 60))
                                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                            
                            Text("Fırsat Avcısı")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                            
                            Text("En iyi fiyatları kaçırma.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 50)
                        
                        // Form
                        VStack(spacing: 20) {
                            TextField("E-posta Adresi", text: $email)
                                .padding()
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 5)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                            
                            SecureField("Şifre", text: $password)
                                .padding()
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 5)
                            
                            if let error = viewModel.errorMessage {
                                Text(error)
                                    .font(.caption)
                                    .foregroundColor(.red)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button {
                                Task {
                                    await viewModel.signIn(email: email, password: password)
                                }
                            } label: {
                                HStack {
                                    Text("Giriş Yap")
                                        .fontWeight(.bold)
                                    Image(systemName: "arrow.right")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                                .foregroundColor(.white)
                                .cornerRadius(16)
                                .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                            }
                            
                            // Apple Sign In
                            SignInWithAppleButton(
                                .signIn,
                                onRequest: viewModel.prepareAppleIDRequest,
                                onCompletion: { result in
                                    switch result {
                                    case .success(let authorization):
                                        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                            viewModel.signInWithApple(credential: appleIDCredential)
                                        }
                                    case .failure(let error):
                                        viewModel.errorMessage = error.localizedDescription
                                    }
                                }
                            )
                            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                            .frame(height: 50)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        
                        Spacer()
                        
                        // Footer
                        HStack {
                            Text("Hesabın yok mu?")
                                .foregroundColor(.secondary)
                            Button("Hemen Kayıt Ol") {
                                showingSignUp = true
                            }
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSignUp) {
                SignUpView()
            }
        }
    }
}
