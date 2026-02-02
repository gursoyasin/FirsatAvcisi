import SwiftUI

struct ProductAggregatorView: View {
    let product: Product
    @StateObject private var viewModel: ProductDetailViewModel
    @Environment(\.dismiss) var dismiss
    @Environment(\.openURL) var openURL
    @EnvironmentObject var uiState: UIState
    @State private var showDeleteConfirmation = false
    
    init(product: Product) {
        self.product = product
        _viewModel = StateObject(wrappedValue: ProductDetailViewModel(product: product))
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(spacing: 24) {
                    // 1. Stretchy Parallax Hero
                    StretchyHeader(
                        imageUrl: viewModel.product.imageUrl ?? "",
                        watchCount: viewModel.product.smartAnalysis?.socialWatchCount,
                        onDelete: { showDeleteConfirmation = true }
                    )
                    .frame(height: 380)
                    
                    VStack(spacing: 28) {
                        // 2. Title & Score Section
                        TitleSection(product: viewModel.product, score: viewModel.opportunityScore)
                        
                        // 3. Quick stats Grid
                        QuickStatsGrid(product: viewModel.product, viewModel: viewModel)
                        
                        // 4. AI Analysis (Premium Integrated)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Yapay Zeka Görüşü")
                                .font(.system(.headline, design: .rounded))
                                .padding(.horizontal)
                            
                            AnalysisCard(analysis: viewModel.analysisResult, isLoading: viewModel.isAnalyzeLoading)
                                .padding(.horizontal)
                        }
                        
                        // 5. Price Trend Chart
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Fiyat Değişimi")
                                    .font(.system(.headline, design: .rounded))
                                Spacer()
                                Text("Son 30 Gün")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            
                            // DELICI FEATURE: Time Prediction
                            if let prediction = viewModel.product.smartAnalysis?.timePrediction {
                                HStack(spacing: 6) {
                                    Image(systemName: "calendar.badge.clock")
                                        .foregroundColor(.purple)
                                    Text(prediction)
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .foregroundColor(.purple)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.purple.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                            }
                            
                            PriceTrendChart(history: viewModel.priceHistory)
                                .frame(height: 150)
                                .padding(.horizontal)
                                .padding(.top, 8)
                        }
                        
                        // 6. Variants
                        if let variants = product.variants, !variants.isEmpty {
                            VariantSelector(variants: variants)
                        }
                        
                        // 7. Seller Comparison
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Market Karşılaştırma")
                                .font(.system(.headline, design: .rounded))
                                .padding(.horizontal)
                            
                            VStack(spacing: 12) {
                                ForEach(viewModel.product.sellers ?? []) { seller in
                                    PremiumSellerRow(seller: seller)
                                }
                                
                                // Best fallback if no sellers but we have the main source
                                if (viewModel.product.sellers ?? []).isEmpty {
                                    PremiumSellerRow(seller: Seller(
                                        merchant: product.source.capitalized,
                                        price: product.currentPrice,
                                        url: product.url,
                                        badge: "En İyi Fiyat"
                                    ))
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 120) // For bottom bar
                    }
                    .padding(.top, -40)
                    .background(
                        Color(uiColor: .systemBackground)
                            .cornerRadius(32, corners: [.topLeft, .topRight])
                    )
                }
            }
            .coordinateSpace(name: "scroll")
            .ignoresSafeArea(.container, edges: .top)
            
            // 8. Floating Action Bar
            BottomActionBar(product: product)
        }
        .navigationBarHidden(true)
        .onAppear {
            uiState.isTabBarHidden = true
            Task {
                await viewModel.refreshData()
                await viewModel.loadAlternatives()
                await viewModel.fetchAnalysis()
            }
        }
        .onDisappear {
            uiState.isTabBarHidden = false
        }
        .alert("Ürünü Takibi Bırak", isPresented: $showDeleteConfirmation) {
            Button("Takibi Bırak", role: .destructive) {
                Task {
                    await WatchlistManager.shared.toggleWatchlist(product: product)
                    dismiss()
                }
            }
            Button("Vazgeç", role: .cancel) { }
        } message: {
            Text("Bu ürünü bekleme listenizden kaldırmak istediğinize emin misiniz?")
        }
    }
}

// MARK: - Subcomponents

struct StretchyHeader: View {
    let imageUrl: String
    let watchCount: Int? // DELICI FEATURE: Social Proof
    let onDelete: () -> Void
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        GeometryReader { geo in
            let minY = geo.frame(in: .named("scroll")).minY
            let scrollOffset = minY > 0 ? minY : 0
            
            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: imageUrl)) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geo.size.width, height: geo.size.height + scrollOffset)
                            .clipped()
                            .offset(y: -scrollOffset)
                    } else {
                        Color.gray.opacity(0.1)
                            .frame(width: geo.size.width, height: geo.size.height + scrollOffset)
                            .offset(y: -scrollOffset)
                    }
                }
                
                // Dimmer layer
                LinearGradient(colors: [.black.opacity(0.4), .clear], startPoint: .top, endPoint: .center)
                    .frame(height: 150)
                    .offset(y: -scrollOffset)
                
                // Back Button
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
                .padding(.top, 50)
                .padding(.leading, 20)
                .offset(y: -scrollOffset)
                
                // Delete Button
                HStack {
                    Spacer()
                    Button(action: onDelete) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(Color.red.opacity(0.8))
                            .clipShape(Circle())
                    }
                }
                .padding(.top, 50)
                .padding(.trailing, 20)
                .offset(y: -scrollOffset)
                
                // DELICI FEATURE: Social Watch Count
                if let count = watchCount {
                    VStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "eye.fill")
                                .font(.caption)
                            Text("\(count) Kişi Takipte")
                                .font(.caption)
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.ultraThinMaterial)
                        .foregroundColor(.white)
                        .cornerRadius(20)
                        .padding(.leading, 20)
                        .padding(.bottom, 60) // Lift above the curved sheet
                    }
                    .offset(y: -scrollOffset)
                }
            }
        }
    }
}

struct TitleSection: View {
    let product: Product
    let score: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // DELICI FEATURE: Real Discount Badge
            if let analysis = product.smartAnalysis {
                HStack {
                    if analysis.realDiscountStatus == .real {
                        Label("GERÇEK İNDİRİM", systemImage: "checkmark.seal.fill")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green)
                            .cornerRadius(8)
                    } else if analysis.realDiscountStatus == .inflated {
                        Label("ŞİŞİRİLMİŞ FİYAT", systemImage: "exclamationmark.triangle.fill")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .cornerRadius(8)
                    }
                    Spacer()
                }
            }
            
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(product.brandDisplay)
                        .font(.system(.subheadline, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text(product.title)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.bold)
                        .lineLimit(2)
                }
                
                Spacer()
                
                // Score Badge
                VStack(spacing: 2) {
                    Text("\(score)")
                        .font(.system(.headline, design: .rounded))
                        .foregroundColor(.white)
                    Text("SKOR")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(width: 44, height: 44)
                .background(Circle().fill(scoreColor))
                .shadow(color: scoreColor.opacity(0.3), radius: 6, x: 0, y: 3)
            }
        }
        .padding(.horizontal)
        .padding(.top, 30) // Extra padding for the badge
    }
    
    var scoreColor: Color {
        if score > 80 { return .green }
        if score > 50 { return .orange }
        return .red
    }
}

struct QuickStatsGrid: View {
    let product: Product
    @ObservedObject var viewModel: ProductDetailViewModel
    
    var waitingDays: Int {
        guard let createdString = product.createdAt,
              let date = ISO8601DateFormatter().date(from: createdString) else {
            return 1
        }
        let components = Calendar.current.dateComponents([.day], from: date, to: Date())
        return max(1, components.day ?? 1)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            StatBox(title: "Bekleme", value: "\(waitingDays) Gün", icon: "hourglass", color: .blue)
            StatBox(title: "En Düşük", value: "\(Int(viewModel.minPrice)) TL", icon: "arrow.down.circle", color: .green)
            StatBox(title: "Market", value: "\(product.sellers?.count ?? 1)", icon: "cart", color: .purple)
        }
        .padding(.horizontal)
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundColor(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.1))
                .cornerRadius(8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fontWeight(.bold)
                Text(value)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .cornerRadius(16)
    }
}

struct PriceTrendChart: View {
    let history: [PricePoint]
    
    var body: some View {
        GeometryReader { geo in
            if history.count < 2 {
                ChartEmptyPlaceholder()
            } else {
                let prices = history.map { $0.price }
                let min = prices.min() ?? 0
                let max = prices.max() ?? 1
                let range = max - min == 0 ? 1 : max - min
                
                Path { path in
                    for (index, point) in history.enumerated() {
                        let x = CGFloat(index) / CGFloat(history.count - 1) * geo.size.width
                        let y = geo.size.height - (CGFloat((point.price - min) / range) * geo.size.height)
                        
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                .background(
                    PriceChartGradient(geo: geo, history: history, min: min, range: range)
                )
            }
        }
    }
}

struct PriceChartGradient: View {
    let geo: GeometryProxy
    let history: [PricePoint]
    let min: Double
    let range: Double
    
    var body: some View {
        Path { path in
            path.move(to: CGPoint(x: 0, y: geo.size.height))
            for (index, point) in history.enumerated() {
                let x = CGFloat(index) / CGFloat(history.count - 1) * geo.size.width
                let y = geo.size.height - (CGFloat((point.price - min) / range) * geo.size.height)
                path.addLine(to: CGPoint(x: x, y: y))
            }
            path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(colors: [.blue.opacity(0.2), .clear], startPoint: .top, endPoint: .bottom)
        )
    }
}

struct ChartEmptyPlaceholder: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Yeterli fiyat geçmişi yok")
                .font(.caption2)
                .foregroundColor(.secondary)
            Text("Fiyat değişimlerini burada göreceksiniz")
                .font(.system(size: 8))
                .foregroundColor(.secondary.opacity(0.7))
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4]))
                .foregroundColor(.gray.opacity(0.3))
        )
    }
}

struct VariantSelector: View {
    let variants: [ProductVariant]
    @Environment(\.openURL) var openURL
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Seçenekler")
                .font(.system(.headline, design: .rounded))
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(variants) { variant in
                        Button(action: {
                            if let s = variant.url, let url = AffiliateManager.shared.convertToAffiliateLink(s) {
                                openURL(url)
                            }
                        }) {
                            Text(variant.title ?? "?")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(12)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct PremiumSellerRow: View {
    let seller: Seller
    @Environment(\.openURL) var openURL
    
    var body: some View {
        HStack(spacing: 16) {
            // Placeholder Logo
            Circle()
                .fill(LinearGradient(colors: [.gray.opacity(0.1), .gray.opacity(0.05)], startPoint: .top, endPoint: .bottom))
                .frame(width: 44, height: 44)
                .overlay(
                    Text((seller.merchant ?? "").prefix(1).uppercased())
                        .font(.headline)
                        .foregroundColor(.blue)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(seller.merchant ?? "Bilinmiyor")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                
                if let badge = seller.badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.1))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(Int(seller.price ?? 0)) TL")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.bold)
                
                Button(action: {
                    if let s = seller.url, let url = AffiliateManager.shared.convertToAffiliateLink(s) {
                        openURL(url)
                    }
                }) {
                    Text("Mağazaya Git")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

struct BottomActionBar: View {
    let product: Product
    @Environment(\.openURL) var openURL
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("GÜNCEL FİYAT")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    Text("\(Int(product.currentPrice)) TL")
                        .font(.system(.title3, design: .rounded))
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                Button(action: {
                    if let url = AffiliateManager.shared.convertToAffiliateLink(product.url) {
                        openURL(url)
                    }
                }) {
                    HStack {
                        Image(systemName: "safari.fill")
                        Text("Satın Al")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                    )
                    .cornerRadius(18)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 34)
            .background(.ultraThinMaterial)
        }
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape( RoundedCorner(radius: radius, corners: corners) )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

