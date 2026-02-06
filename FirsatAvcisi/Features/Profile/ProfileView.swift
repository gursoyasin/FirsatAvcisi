import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEditProfile = false
    @State private var showSettings = false
    
    // Stats (Mock for V1, then connect to real data)
    @State private var followingCount = 0
    @State private var totalSavings = 0.0
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // 1. Header & Avatar
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 100, height: 100)
                                .shadow(radius: 10)
                            
                            Text(authViewModel.userSession?.email?.prefix(1).uppercased() ?? "U")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text(authViewModel.userSession?.displayName ?? "Kullanıcı")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(authViewModel.userSession?.email ?? "email@example.com")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        
                        Button(action: { showEditProfile = true }) {
                            Text("Profili Düzenle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 10)
                                .background(Color.black.opacity(0.8))
                                .cornerRadius(20)
                        }
                    }
                    .padding(.top, 20)
                    
                    // 2. Stats Cards
                    HStack(spacing: 16) {
                        ProfileStatCard(title: "Takip Edilen", value: "\(followingCount)", icon: "heart.fill", color: .red)
                        ProfileStatCard(title: "Toplam Kazanç", value: "₺\(Int(totalSavings))", icon: "banknote.fill", color: .green)
                    }
                    .padding(.horizontal)
                    
                    // 3. Menu List
                    VStack(spacing: 0) {
                        MenuRow(title: "Ayarlar", icon: "gearshape.fill", color: .gray) {
                            showSettings = true
                        }
                        
                        Divider().padding(.leading, 50)
                        
                        MenuRow(title: "Yardım & Destek", icon: "questionmark.circle.fill", color: .blue) {
                            // Link to support
                        }
                        
                        Divider().padding(.leading, 50)
                        
                        MenuRow(title: "Çıkış Yap", icon: "rectangle.portrait.and.arrow.right", color: .red, showChevron: false) {
                            authViewModel.signOut()
                        }
                    }
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                    
                    Spacer()
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("Profil")
            .navigationBarHidden(true)
            .sheet(isPresented: $showEditProfile) {
                EditProfileView()
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .onAppear {
                // Load stats logic here later
                if let savedCount = UserDefaults.standard.array(forKey: "watchlist_ids")?.count {
                    followingCount = savedCount
                }
            }
        }
    }
}

// Helper Views
struct ProfileStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.system(size: 18))
                    .padding(8)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct MenuRow: View {
    let title: String
    let icon: String
    let color: Color
    var showChevron: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(color)
                    .frame(width: 30)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }
            .padding(16)
        }
    }
}
