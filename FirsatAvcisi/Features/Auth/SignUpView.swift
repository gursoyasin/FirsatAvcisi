import SwiftUI

struct SignUpView: View {
    @StateObject var viewModel = AuthViewModel()
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var password = ""
    @State private var name = ""
    @State private var selectedGender = "female"
    @State private var showVerificationAlert = false
    
    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(colors: [.purple.opacity(0.1), .blue.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                Text("Aramıza Katıl")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .padding(.top, 50)
                
                // Form
                VStack(spacing: 16) {
                    TextField("Ad Soyad", text: $name)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5)
                    
                    TextField("E-posta Adresi", text: $email)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.emailAddress)
                    
                    SecureField("Şifre", text: $password)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.05), radius: 5)

                    // Gender Selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Cinsiyet Tercihi")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                        
                        Picker("Cinsiyet", selection: $selectedGender) {
                            Text("Kadın Ürünleri").tag("female")
                            Text("Erkek Ürünleri").tag("male")
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(.top, 8)
                    
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Button {
                        Task {
                            let success = await viewModel.signUp(email: email, password: password, gender: selectedGender)
                            if success {
                                showVerificationAlert = true
                            }
                        }
                    } label: {
                        Text("Kayıt Ol")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button("Zaten hesabın var mı? Giriş Yap") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                .padding(.bottom)
            }
        }
        .alert("E-posta Doğrulama", isPresented: $showVerificationAlert) {
            Button("Tamam") {
                dismiss() // Return to Login
            }
        } message: {
            Text("Lütfen \(email) adresine gönderdiğimiz bağlantıya tıklayarak hesabınızı onaylayın.\n\n(Spam/Gereksiz kutusunu da kontrol etmeyi unutmayın!)")
        }
    }
}
