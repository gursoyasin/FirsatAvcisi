import SwiftUI

struct MainTabView: View {
    @State private var currentTab: Tab = .market
    @Namespace var animation
    @EnvironmentObject var uiState: UIState
    @EnvironmentObject var networkMonitor: NetworkMonitor
    @StateObject private var alertManager = AlertManager.shared
    
    init() {
        // Hide default TabBar
        UITabBar.appearance().isHidden = true
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Content
            Group {
                switch currentTab {
                case .market:
                    SmartDashboardView(currentTab: $currentTab)
                case .watchlist:
                    WatchlistView()
                case .inditex:
                    InditexView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar
            if !uiState.isTabBarHidden {
                CustomTabBar(currentTab: $currentTab, animation: animation)
                    .padding(.bottom, 10)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            
            // Offline Notification
            if !networkMonitor.isConnected {
                VStack {
                    HStack {
                        Image(systemName: "wifi.slash")
                        Text("İnternet Bağlantısı Yok")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.9))
                    .foregroundColor(.white)
                    .transition(.move(edge: .top))
                    
                    Spacer()
                }
                .ignoresSafeArea()
                .zIndex(100)
            }
        }
        .alert(alertManager.alertTitle, isPresented: $alertManager.showAlert) {
            Button("Tamam", role: .cancel) { }
        } message: {
            Text(alertManager.alertMessage)
        }
        .overlay(alignment: .top) {
            if alertManager.showToast {
                ToastView(message: alertManager.toastMessage, type: alertManager.toastType)
                    .padding(.top, 50)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onOpenURL { url in
            handleURL(url)
        }
    }
    
    struct ToastView: View {
        let message: String
        let type: ToastType
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: type.icon)
                    .foregroundColor(type.color)
                Text(message)
                    .font(.footnote)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(Color(uiColor: .systemBackground))
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        }
    }
    
    private func handleURL(_ url: URL) {
        guard url.scheme == "firsatavcisi" else { return }
        
        let components = url.pathComponents
        if components.contains("collections") {
            currentTab = .inditex // Map properly if needed
        } else if components.contains("watchlist") {
            currentTab = .watchlist
        } else {
            currentTab = .market
        }
    }
}
