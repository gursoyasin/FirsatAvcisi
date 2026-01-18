import SwiftUI

struct TrendingView: View {
    @StateObject private var viewModel = TrendingViewModel()
    @State private var showSuccessToast = false
    
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView("Piyasa Taranıyor...")
                        .scaleEffect(1.2)
                } else if let error = viewModel.errorMessage {
                    VStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .padding()
                        Button("Tekrar Dene") {
                            Task { await viewModel.loadTrending() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            // 1. LIVE TICKER
                            if !viewModel.products.isEmpty {
                                LiveTickerView(products: viewModel.products)
                                    .frame(height: 30)
                                    .background(Color.black.opacity(0.8))
                                    .cornerRadius(4)
                                    .padding(.horizontal)
                            }
                            
                            // 2. HERO SECTION (Günün Yıldızı)
                            if let topDeal = viewModel.topDeal {
                                HeroDealCard(product: topDeal) {
                                    viewModel.saveToWatchlist(product: topDeal)
                                    showToast()
                                }
                                .padding(.horizontal)
                            }
                            
                            // 3. CATEGORY CHIPS
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.categories, id: \.self) { category in
                                        TrendingFilterChip(
                                            title: category,
                                            isSelected: viewModel.selectedCategory == category,
                                            action: { 
                                                viewModel.selectedCategory = category
                                                Task { await viewModel.loadTrending() }
                                            }
                                        )
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // 4. MAIN GRID
                            if viewModel.filteredProducts.isEmpty {
                                Text("Bu kategoride fırsat bulunamadı.")
                                    .foregroundColor(.secondary)
                                    .padding(.top, 40)
                            } else {
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(viewModel.filteredProducts) { product in
                                        TrendingProductCard(product: product) {
                                            viewModel.saveToWatchlist(product: product)
                                            showToast()
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.bottom, 80)
                            }
                        }
                        .padding(.top, 10)
                    }
                    .refreshable {
                        await viewModel.loadTrending()
                    }
                }
                
                // Success Toast
                if showSuccessToast {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Takip Listesine Eklendi")
                                .fontWeight(.medium)
                        }
                        .padding()
                        .background(Material.thinMaterial)
                        .cornerRadius(20)
                        .shadow(radius: 10)
                        .padding(.bottom, 50)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Piyasa 🌍")
            .navigationBarTitleDisplayMode(.inline) // More pro look
            .onAppear {
                Task {
                    await viewModel.loadTrending()
                }
            }
        }
    }
    
    func showToast() {
        withAnimation { showSuccessToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation { showSuccessToast = false }
        }
    }
}

// MARK: - SUBVIEWS

struct LiveTickerView: View {
    let products: [Product]
    @State private var offset: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    ForEach(products.prefix(5)) { product in
                        HStack(spacing: 4) {
                            Text(product.title)
                                .lineLimit(1)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("↘ %\(Int(product.discountPercentage ?? 0))")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.horizontal)
                .onAppear {
                    // Simple animation loop (Ticker Effect) implementation is tricky in pure SwiftUI without extensive state.
                    // For MVP we just show a static scrollable list that looks like a ticker.
                    // Or precise offset animation. But sticking to scrollable HStack matches "Bloomberg" mobile style better.
                }
            }
        }
    }
}

struct TrendingFilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
    }
}

struct HeroDealCard: View {
    let product: Product
    let onQuickSave: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle().fill(Color.gray.opacity(0.2))
                }
            }
            .frame(height: 250)
            .clipped()
            
            // Gradient Overlay
            LinearGradient(colors: [.black.opacity(0.8), .clear], startPoint: .bottom, endPoint: .top)
            
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("GÜNÜN YILDIZI ⭐️")
                        .font(.caption)
                        .fontWeight(.black)
                        .foregroundColor(.yellow)
                        .padding(.bottom, 2)
                    
                    Text(product.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(2)
                    
                    HStack {
                        Text("\(Int(product.currentPrice))₺")
                            .font(.title2)
                            .fontWeight(.heavy)
                            .foregroundColor(.green)
                        
                        Text("-\(Int(product.discountPercentage ?? 0))%")
                            .font(.headline)
                            .padding(4)
                            .background(Color.red)
                            .cornerRadius(4)
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                Button(action: onQuickSave) {
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .blue)
                        .font(.system(size: 44))
                }
            }
            .padding()
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(radius: 5)
    }
}

struct TrendingProductCard: View {
    let product: Product
    let onQuickSave: () -> Void
    @Environment(\.openURL) var openURL
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Image
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { phase in
                    if let image = phase.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Rectangle().fill(Color.gray.opacity(0.1))
                    }
                }
                .frame(height: 140)
                .clipped()
                
                Button(action: onQuickSave) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                        .foregroundColor(.blue)
                        .background(Color.white.clipShape(Circle()))
                }
                .padding(8)
            }
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(product.source.capitalized)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                    Spacer()
                    
                    // NEW BADGES
                    if let discount = product.discountPercentage, discount > 15 {
                        Text("-%\(Int(discount))")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(4)
                    }
                }
                
                Text(product.title)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .frame(height: 32, alignment: .topLeading)
                
                HStack {
                    Text("\(Int(product.currentPrice))₺")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    // Badges (Fire for Popularity, Clock for Freshness)
                    HStack(spacing: 4) {
                        if (product.followerCount ?? 0) > 1 {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                Text("\(product.followerCount ?? 0)")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(10)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 3)
        .onTapGesture {
            if let url = URL(string: product.url) {
                openURL(url)
            }
        }
    }
}
