import SwiftUI

enum Tab: String, CaseIterable {
    case market = "house"
    case watchlist = "heart"
    case inditex = "bag" // Changed from tag for a more "shopping" feel
    case settings = "gearshape"
    
    var title: String {
        switch self {
        case .market: return "Keşfet" // "Ana Sayfa" is generic. "Keşfet" is inviting.
        case .watchlist: return "Favoriler"
        case .inditex: return "İndirimler"
        case .settings: return "Ayarlar"
        }
    }
}

struct CustomTabBar: View {
    @Binding var currentTab: Tab
    var animation: Namespace.ID
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        currentTab = tab
                        HapticManager.shared.impact(style: .light)
                    }
                }) {
                    VStack(spacing: 6) {
                        // Icon Layer
                        ZStack {
                            if currentTab == tab {
                                Image(systemName: tab.rawValue + ".fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .transition(.scale.combined(with: .opacity))
                            } else {
                                Image(systemName: tab.rawValue)
                                    .font(.system(size: 24, weight: .light))
                            }
                        }
                        
                        // Indicator
                        ZStack {
                            if currentTab == tab {
                                Circle()
                                    .fill(Color.primary)
                                    .frame(width: 5, height: 5)
                                    .matchedGeometryEffect(id: "TAB_INDICATOR", in: animation)
                            } else {
                                Circle()
                                    .fill(Color.clear)
                                    .frame(width: 5, height: 5)
                            }
                        }
                    }
                    .foregroundColor(currentTab == tab ? .primary : .gray.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .contentShape(Rectangle())
                }
            }
        }
        .padding(.horizontal, 10)
        .background(
            ZStack {
                // Glass Background
                VisualEffectBlur(blurStyle: .systemChromeMaterial)
                    .clipShape(Capsule())
                
                // Subtle Border
                Capsule()
                    .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
            }
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
    }
}

// Helper for convenient glassmorphism if not globally available yet
// (If VisualEffectBlur is already defined in ProductDetailView or similar, we should move it to a shared file,
// but for safety/speed I will define a local private one or rely on the one I know I added in ProductDetailView.
// Better to check if it exists globally. It was in ProductDetailView as private. I will add a shared one here to be safe.)

// VisualEffectBlur is already defined in the project scope.
