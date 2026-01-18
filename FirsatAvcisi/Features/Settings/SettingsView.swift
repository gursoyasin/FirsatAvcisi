import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @Environment(\.dismiss) var dismiss
    @State private var notificationsEnabled = true
    @State private var backgroundRefreshEnabled = true
    
    var body: some View {
        NavigationView {
            Form {
                // Account Section
                Section(header: Text("Hesap")) {
                    if let user = viewModel.userSession {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                            Text(user.email ?? "Kullanıcı")
                                .foregroundColor(.primary)
                        }
                        
                        Button(role: .destructive) {
                            viewModel.signOut()
                        } label: {
                            Label("Çıkış Yap", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } else {
                         Text("Giriş Yapılmadı")
                    }
                }
                
                // Pro Banner
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.yellow)
                                .font(.title)
                            VStack(alignment: .leading) {
                                Text("Fırsat Avcısı PRO")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text("Sınırsız takip ve anlık bildirimler")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        
                        Button {
                            // Trigger Paywall
                        } label: {
                            Text("Upgrade to PRO")
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.white)
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                    .background(
                        LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .listRowInsets(EdgeInsets())
                }
                
                // General Settings
                Section(header: Text("Genel")) {
                    Toggle(isOn: $notificationsEnabled) {
                        Label {
                            Text("Bildirimler")
                        } icon: {
                            Image(systemName: "bell.badge.fill")
                                .foregroundColor(.red)
                        }
                    }
                    
                    Toggle(isOn: $backgroundRefreshEnabled) {
                        Label {
                            Text("Arka Plan Yenileme")
                        } icon: {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.green)
                        }
                    }
                }
                
                // Support
                Section(header: Text("Destek")) {
                    Link(destination: URL(string: "https://twitter.com")!) {
                        Label {
                            Text("Bizi Değerlendir")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                        }
                    }
                    
                    Link(destination: URL(string: "mailto:support@firsatavcisi.com")!) {
                        Label {
                            Text("İletişime Geç")
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section {
                    Text("Versiyon 1.0.0 (Build 1)")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Ayarlar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
        }
    }
}
