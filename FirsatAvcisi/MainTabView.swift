import SwiftUI

struct MainTabView: View {
    @State private var currentTab: Tab = .market
    @Namespace var animation
    
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
                    MarketFeedView()
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
            CustomTabBar(currentTab: $currentTab, animation: animation)
                .padding(.bottom, 10)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onOpenURL { url in
            handleURL(url)
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
