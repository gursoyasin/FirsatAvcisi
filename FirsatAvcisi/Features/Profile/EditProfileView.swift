import SwiftUI
import FirebaseAuth

struct EditProfileView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var authViewModel: AuthViewModel // Assuming we might update global state
    
    @State private var name: String = ""
    @State private var selectedGender: String = "kadın"
    @State private var isLoading = false
    
    let genders = ["kadın", "erkek"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Kişisel Bilgiler")) {
                    TextField("Ad Soyad", text: $name)
                        .textContentType(.name)
                    
                    Picker("Cinsiyet", selection: $selectedGender) {
                        ForEach(genders, id: \.self) { gender in
                            Text(gender.capitalized).tag(gender)
                        }
                    }
                }
                
                Section(footer: Text("Bu bilgiler sana daha iyi öneriler sunmamız için kullanılır.")) {
                    Button(action: saveProfile) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Kaydet")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.blue)
                        }
                    }
                    .disabled(isLoading)
                }
            }
            .navigationTitle("Profili Düzenle")
            .navigationBarItems(leading: Button("İptal") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                // Pre-fill data
                if let user = authViewModel.userSession {
                    name = user.displayName ?? ""
                }
                selectedGender = UserPreferences.shared.gender
            }
        }
    }
    
    func saveProfile() {
        isLoading = true
        
        // Mock API Call or Real Logic
        Task {
            // Update Display Name in Firebase
            let changeRequest = authViewModel.userSession?.createProfileChangeRequest()
            changeRequest?.displayName = name
            try? await changeRequest?.commitChanges()
            
            // Update Preferences
            UserPreferences.shared.gender = selectedGender
            
            // Sync with Backend
            try? await APIService.shared.updateUserProfile(gender: selectedGender)
            
            await MainActor.run {
                isLoading = false
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}
