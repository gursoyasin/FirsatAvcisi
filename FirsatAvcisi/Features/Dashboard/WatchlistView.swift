import SwiftUI

struct WatchlistView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @ObservedObject var watchlistManager = WatchlistManager.shared
    @State private var showingSettings = false
    @State private var selectedSort: SortOption = .smart
    
    // Sort Options
    enum SortOption {
        case smart, drop, newest
    }
    
    var filteredProducts: [Product] {
        let trackedIds = watchlistManager.trackedProductIds
        let baseProducts = viewModel.products.filter { trackedIds.contains($0.id) }
        
        switch selectedSort {
        case .smart: // "İndirime en yakın" based on discount %
            return baseProducts.sorted {
                let p1Original = $0.originalPrice ?? $0.currentPrice
                let p2Original = $1.originalPrice ?? $1.currentPrice
                
                let p1Discount = (p1Original - $0.currentPrice) / p1Original
                let p2Discount = (p2Original - $1.currentPrice) / p2Original
                return p1Discount > p2Discount
            }
        case .drop: // Amount dropped
            return baseProducts.sorted {
                let p1Original = $0.originalPrice ?? 0
                let p2Original = $1.originalPrice ?? 0
                return (p1Original - $0.currentPrice) > (p2Original - $1.currentPrice)
            }
        case .newest:
            return baseProducts // Assuming API returns newest first or locally sorted
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Durum Paneli (Status Bar)
                        if !viewModel.products.isEmpty {
                            StatusBar(count: viewModel.products.count, discountedCount: discountCount)
                                .padding(.top, 10)
                        }
                        
                        // 2. Sorting Tabs
                        if !viewModel.products.isEmpty {
                            HStack(spacing: 12) {
                                SortButton(title: "🔥 İndirime Yakın", isSelected: selectedSort == .smart) { selectedSort = .smart }
                                SortButton(title: "📉 En Çok Düşen", isSelected: selectedSort == .drop) { selectedSort = .drop }
                                SortButton(title: "⏳ En Yeni", isSelected: selectedSort == .newest) { selectedSort = .newest }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }
                        
                        // 3. Product List (Smart Cards)
                        if viewModel.isLoading {
                            VStack {
                                ProgressView()
                                    .padding()
                                Text("Durumlar kontrol ediliyor...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 200)
                        } else if viewModel.filteredProducts.isEmpty {
                            EmptyStateView(
                                icon: "hourglass",
                                title: "Bekleme Listen Boş",
                                message: "Ana sayfadan bir ürün ekle, senin yerine biz nöbet tutalım.",
                                buttonTitle: nil,
                                action: nil
                            )
                            .padding(.top, 40)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredProducts) { product in
                                    NavigationLink(destination: ProductAggregatorView(product: product)) {
                                        SmartWaitingCard(product: product)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                        }
                    }
                }
                .refreshable {
                    await viewModel.fetchProducts()
                    Task { try? await APIService.shared.triggerWatchlistCheck() }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Takip Listem")
                        .font(.system(.headline, design: .rounded))
                        .fontWeight(.bold)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .task {
            await viewModel.fetchProducts()
        }
    }
    
    var discountCount: Int {
        viewModel.products.filter { ($0.originalPrice ?? 0) > $0.currentPrice }.count
    }
}

// MARK: - Components

struct StatusBar: View {
    let count: Int
    let discountedCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Waiting Stat
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "hourglass")
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(count)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Beklemede")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(12)
            .background(Color(uiColor: .tertiarySystemGroupedBackground))
            .cornerRadius(16)
            
            // Discount Stat
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(discountedCount)")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Harekette")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(12)
            .background(Color(uiColor: .tertiarySystemGroupedBackground))
            .cornerRadius(16)
        }
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

struct SortButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .medium)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(isSelected ? Color.primary : Color(uiColor: .secondarySystemBackground))
                .foregroundColor(isSelected ? Color(uiColor: .systemBackground) : .primary)
                .cornerRadius(20)
        }
    }
}

struct SmartWaitingCard: View {
    let product: Product
    @State private var showTargetSheet = false
    @State private var showPaywall = false
    @ObservedObject var watchlistManager = WatchlistManager.shared
    
    // Derived States
    var waitingDays: Int {
        guard let createdString = product.createdAt,
              let date = ISO8601DateFormatter().date(from: createdString) else { return 1 }
        let components = Calendar.current.dateComponents([.day], from: date, to: Date())
        return max(1, components.day ?? 1)
    }
    
    var changePercentage: Double {
        guard let original = product.originalPrice, original > 0 else { return 0 }
        return ((original - product.currentPrice) / original) * 100
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - MAIN CARD CONTENT
            HStack(spacing: 16) {
                // Image Section
                ZStack(alignment: .topLeading) {
                    AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
                        if let image = phase.image {
                            image.resizable().aspectRatio(contentMode: .fill)
                        } else {
                            Color(uiColor: .secondarySystemBackground)
                            Image(systemName: "photo").foregroundColor(.gray)
                        }
                    }
                    .frame(width: 90, height: 110)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    
                    // Discount Badge (Glass)
                    if changePercentage > 0 {
                        Text("%\(Int(changePercentage))")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(.ultraThinMaterial) // Glass Effect
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                            .shadow(radius: 2)
                            .padding(6)
                    }
                }
                
                // Info Section
                VStack(alignment: .leading, spacing: 6) {
                    // Top Row: Brand & Days
                    HStack {
                        Text(product.brandDisplay.uppercased())
                            .font(.system(size: 10, weight: .heavy))
                            .tracking(1)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Label("\(waitingDays) gündür", systemImage: "hourglass")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(uiColor: .tertiarySystemGroupedBackground))
                            .clipShape(Capsule())
                    }
                    
                    // Title
                    Text(product.title)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Price Row
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text("\(Int(product.currentPrice)) TL")
                            .font(.system(size: 18, weight: .black, design: .rounded))
                            .foregroundColor(changePercentage > 0 ? .green : .primary)
                        
                        if let original = product.originalPrice, original > product.currentPrice {
                            Text("\(Int(original)) TL")
                                .strikethrough()
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(12)
            
            // MARK: - ACTION BAR (Bottom)
            Button(action: {
                if SubscriptionManager.shared.isPro {
                    showTargetSheet = true
                } else {
                    showPaywall = true
                }
            }) {
                HStack {
                    // Status Text / Emotional Copy
                    if let target = product.targetPrice, target > 0 {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        Text("Hedef: \(Int(target)) TL")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "bell.badge")
                            .font(.system(size: 12))
                            .foregroundColor(.white)
                        Text("Hedef Fiyat Belirle")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    // Pro Lock or Arrow
                    if !SubscriptionManager.shared.isPro {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                // Premium Gradient Button
                .background(
                    LinearGradient(
                        colors: changePercentage > 0 ? [.green, .teal] : [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }
            // Bottom Corner Radius Only (for the button to fit card)
            .clipShape(UnevenRoundedRectangle(bottomLeadingRadius: 16, bottomTrailingRadius: 16))
            .sheet(isPresented: $showTargetSheet) {
                TargetPriceSheet(product: product)
                    .presentationDetents([.fraction(0.5)])
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 5) // Soft Premium Shadow
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
    }
}
// Helper for Uneven corners (iOS 16+ native, but custom struct for compatibility if needed. Assuming iOS 16+)
struct UnevenRoundedRectangle: Shape {
    var topLeadingRadius: CGFloat = 0
    var topTrailingRadius: CGFloat = 0
    var bottomLeadingRadius: CGFloat = 0
    var bottomTrailingRadius: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                topLeadingRadius > 0 ? .topLeft : [],
                topTrailingRadius > 0 ? .topRight : [],
                bottomLeadingRadius > 0 ? .bottomLeft : [],
                bottomTrailingRadius > 0 ? .bottomRight : []
            ].reduce(into: UIRectCorner()) { $0.insert($1) },
            cornerRadii: CGSize(width: max(topLeadingRadius, topTrailingRadius, bottomLeadingRadius, bottomTrailingRadius), height: max(topLeadingRadius, topTrailingRadius, bottomLeadingRadius, bottomTrailingRadius))
        )
        return Path(path.cgPath)
    }
}

// Extension to help brand display if not available in model
extension Product {
    var brandDisplay: String {
        return self.source.capitalized // Use source (zara, nike) as brand for now
    }
}
