import SwiftUI
import Combine
import FirebaseAuth
import Firebase
import AuthenticationServices
import CryptoKit

@MainActor
class AuthViewModel: ObservableObject {
    @Published var userSession: FirebaseAuth.User?
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String?
    
    fileprivate var currentNonce: String?
    
    private var handle: AuthStateDidChangeListenerHandle?
    
    init() {
        self.handle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            self?.userSession = user
            self?.isAuthenticated = user != nil && user!.isEmailVerified
            
            // Share Email with Extension
            if let email = user?.email {
                if let sharedDefaults = UserDefaults(suiteName: "group.yacN.FirsatAvcisi") {
                    sharedDefaults.set(email, forKey: "userEmail")
                }
                
                // Sync Profile (Gender & Brands) from Backend
                Task {
                    if let status = try? await APIService.shared.checkUserStatus() {
                        await MainActor.run {
                            if let gender = status.gender {
                                UserPreferences.shared.gender = gender
                            }
                            if let brands = status.brands {
                                UserPreferences.shared.interestedBrands = Set(brands)
                                UserDefaults.standard.set(brands, forKey: "interested_brands")
                            }
                        }
                    }
                }
            } else {
                 // Clear on logout
                 if let sharedDefaults = UserDefaults(suiteName: "group.yacN.FirsatAvcisi") {
                    sharedDefaults.removeObject(forKey: "userEmail")
                }
            }
        }
    }
    
    deinit {
        if let handle = handle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    
    func checkVerificationStatus() async {
        guard let user = userSession else { return }
        try? await user.reload()
        self.userSession = Auth.auth().currentUser
        self.isAuthenticated = self.userSession?.isEmailVerified ?? false
        
        // Final sync after verification/reload
        if isAuthenticated, let _ = userSession?.email {
            if let status = try? await APIService.shared.checkUserStatus() {
                await MainActor.run {
                    if let gender = status.gender { UserPreferences.shared.gender = gender }
                    if let brands = status.brands { 
                        UserPreferences.shared.interestedBrands = Set(brands)
                        UserDefaults.standard.set(brands, forKey: "interested_brands")
                    }
                }
            }
        }
    }
    
    func signIn(email: String, password: String) async {
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.errorMessage = nil
            await checkVerificationStatus()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
    
    func signUp(email: String, password: String, gender: String) async -> Bool {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Set profile on backend immediately
            try? await APIService.shared.updateUserProfile(gender: gender)
            
            try await result.user.sendEmailVerification()
            // Sign out immediately so they can't login without verification
            try Auth.auth().signOut()
            
            await MainActor.run {
                self.userSession = nil
                self.errorMessage = nil
            }
            return true
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
            return false
        }
    }
    
    func resendVerificationEmail() async {
        guard let user = Auth.auth().currentUser else { return }
        try? await user.sendEmailVerification()
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            self.userSession = nil
            
            // Reset Local Pro Status on Logout
            // This ensures next user doesn't inherit Previous User's status on this device
            UserDefaults.standard.set(false, forKey: "isProUser")
            
        } catch {
            print("Sign out error: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Sign in with Apple logic
    func signInWithApple(credential: ASAuthorizationAppleIDCredential) {
        guard let appleIDToken = credential.identityToken else { return }
        guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else { return }
        guard let nonce = currentNonce else { return }
        
        let firebaseCredential = OAuthProvider.appleCredential(withIDToken: idTokenString,
                                                             rawNonce: nonce,
                                                             fullName: credential.fullName)
        
        Task {
            do {
                try await Auth.auth().signIn(with: firebaseCredential)
                await checkVerificationStatus()
                // Apple accounts are usually verified by default if email is provided
                if let user = Auth.auth().currentUser {
                    self.isAuthenticated = true
                }
            } catch {
                self.errorMessage = error.localizedDescription
            }
        }
    }
    
    func prepareAppleIDRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
            Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in UInt8.random(in: 0...255) }

            randoms.forEach { random in
                if remainingLength == 0 { return }
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()

        return hashString
    }
}
