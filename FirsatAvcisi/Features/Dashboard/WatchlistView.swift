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
        HStack {
            HStack(spacing: 6) {
                Image(systemName: "hourglass")
                    .foregroundColor(.blue)
                Text("\(count) ürün beklemede")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            
            Divider()
                .frame(height: 20)
            
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)
                Text("\(discountedCount) ürün harekette")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
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
    var lowestPrice: Double {
        guard let history = product.history, !history.isEmpty else { return product.currentPrice }
        return history.map { $0.price }.min() ?? product.currentPrice
    }
    
    var waitingDays: Int {
        guard let createdString = product.createdAt,
              let date = ISO8601DateFormatter().date(from: createdString) else {
            return 1
        }
        let components = Calendar.current.dateComponents([.day], from: date, to: Date())
        return max(1, components.day ?? 1)
    }
    
    var emotionalCopy: String {
        let copies = [
            "Hâlâ buradayız 💙",
            "Biraz daha sabır 👀",
            "Hazır ol… geliyor 🔥",
            "Birlikte bekliyoruz 🤝",
            "Fiyatı düşüreceğiz 💪",
            "Radarımızda 📡"
        ]
        let index = abs(product.id.hashValue % copies.count)
        return copies[index]
    }
    
    var changePercentage: Double {
        guard let original = product.originalPrice, original > 0 else { return 0 }
        return ((original - product.currentPrice) / original) * 100
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Main Content
            HStack(spacing: 16) {
                // Product Image
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
                    if let image = phase.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else {
                        Color.gray.opacity(0.1)
                    }
                }
                .frame(width: 80, height: 100)
                .cornerRadius(12)
                .clipped()
                .overlay(alignment: .topTrailing) {
                    Button(action: {
                        HapticManager.shared.impact(style: .medium)
                        watchlistManager.toggleWatchlist(product: product)
                    }) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.red)
                            .padding(6)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                    .padding(4)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(product.brandDisplay)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        // Waiting Time Badge (Real Data)
                        Text("\(waitingDays) gündür")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Text(product.title)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.medium)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(Int(product.currentPrice)) TL")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(changePercentage > 0 ? .green : .primary)
                        
                        if let original = product.originalPrice, original > product.currentPrice {
                            Text("\(Int(original)) TL")
                                .strikethrough()
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(12)
            
            Divider()
                .padding(.horizontal)
            
            // Footer: Emotional & Pro Upsell
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text("Fiyat Takibi Aktif") 
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(emotionalCopy)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
            }
            .padding(12)
            .background(Color(uiColor: .secondarySystemBackground).opacity(0.5))
            
            // TARGET PRICE BUTTON (Pro Logic)
            Button(action: {
                if SubscriptionManager.shared.isPro {
                    showTargetSheet = true
                } else {
                    showPaywall = true
                }
            }) {
                HStack {
                    Image(systemName: "bell.badge")
                        .font(.caption)
                        .foregroundColor(.white)
                    
                    // Show Lock Icon if not Pro
                    if SubscriptionManager.shared.isPro {
                        if let target = product.targetPrice, target > 0 {
                            Text("Hedef: \(Int(target)) TL")
                                .font(.caption).fontWeight(.bold).foregroundColor(.white)
                        } else {
                            Text("Hedef Fiyat Belirle")
                                .font(.caption).fontWeight(.bold).foregroundColor(.white)
                        }
                    } else {
                        Text("Hedef Fiyat Belirle")
                            .font(.caption).fontWeight(.bold).foregroundColor(.white)
                        Image(systemName: "lock.fill")
                            .font(.caption2).foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundColor(.white.opacity(0.8))
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                )
            }
            .sheet(isPresented: $showTargetSheet) {
                TargetPriceSheet(product: product)
                    .presentationDetents([.fraction(0.5)]) // Increased height for new design
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// Extension to help brand display if not available in model
extension Product {
    var brandDisplay: String {
        return self.source.capitalized // Use source (zara, nike) as brand for now
    }
}
