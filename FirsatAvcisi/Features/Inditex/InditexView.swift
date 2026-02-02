import SwiftUI

struct InditexView: View {
    @StateObject private var viewModel = InditexViewModel()
    @FocusState private var isSearchFocused: Bool
    
    let columns = [
        GridItem(.flexible(), spacing: 20),
        GridItem(.flexible(), spacing: 20)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(uiColor: .systemBackground).ignoresSafeArea()
                
                VStack(spacing: 0) {
                    headerView
                    
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 32) {
                            
                            // 1. Smart Brand Selector & Insight
                            VStack(alignment: .leading, spacing: 16) {
                                brandStorySection
                                
                                Text(viewModel.brandInsight)
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 24)
                                    .transition(.asymmetric(insertion: .push(from: .bottom), removal: .opacity))
                                    .id(viewModel.selectedBrand)
                            }
                            
                            // 2. "Bugün Burada" - Social Proof Section
                            if !viewModel.trendingProducts.isEmpty {
                                TodayHereSection(products: viewModel.trendingProducts)
                            }
                            
                            // 3. Category Intents
                            categorySection
                            
                            // 4. Content Grid
                            if viewModel.isLoading {
                                shimmerGrid
                            } else if let error = viewModel.errorMessage {
                                errorView(message: error)
                            } else if viewModel.filteredProducts.isEmpty {
                                AdvancedEmptyState(selectedCategory: viewModel.selectedCategory)
                            } else {
                                productGrid
                            }
                            
                            // 5. In Your Style (Curiosity Footer)
                            if !viewModel.personalizedProducts.isEmpty {
                                InYourStyleSection(products: viewModel.personalizedProducts)
                            }
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 120)
                    }
                    .refreshable {
                        await viewModel.loadFeed()
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Sections
    
    private var headerView: some View {
        HStack {
            Text("KEŞFET")
                .font(.system(size: 26, weight: .black, design: .serif))
                .tracking(2)
            
            Spacer()
            
            HStack(spacing: 20) {
                Button {
                    withAnimation { isSearchFocused.toggle() }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
                
                Menu {
                    Picker("Sıralama", selection: $viewModel.selectedSort) {
                        ForEach(InditexViewModel.SortOption.allCases) { option in
                            Label(option.rawValue, systemImage: option.icon).tag(option)
                        }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(uiColor: .systemBackground))
        .overlay(
            Group {
                if isSearchFocused {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.secondary)
                        TextField("Hayalindeki bir parçayı ara...", text: $viewModel.searchText)
                            .focused($isSearchFocused)
                        Button("Kapat") {
                            viewModel.searchText = ""
                            isSearchFocused = false
                        }
                        .foregroundColor(.primary)
                        .font(.system(size: 14, weight: .bold))
                    }
                    .padding()
                    .background(Color(uiColor: .systemBackground))
                }
            }
        )
    }
    
    private var brandStorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 20) {
                ForEach(viewModel.brands, id: \.self) { brand in
                    BrandStoryItem(
                        brand: brand,
                        isSelected: viewModel.selectedBrand == brand,
                        action: {
                            withAnimation(.spring()) {
                                viewModel.changeBrand(brand)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var categorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(viewModel.categories, id: \.self) { category in
                    Button(action: {
                        HapticManager.shared.impact(style: .light)
                        withAnimation { viewModel.changeCategory(category) }
                    }) {
                        Text(category)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(viewModel.selectedCategory == category ? Color.blue : Color(.secondarySystemBackground))
                            .foregroundColor(viewModel.selectedCategory == category ? .white : .primary)
                            .cornerRadius(20)
                    }
                }
            }
            .padding(.horizontal, 24)
        }
    }
    
    private var productGrid: some View {
        LazyVGrid(columns: columns, spacing: 32) {
            ForEach(viewModel.filteredProducts) { product in
                NavigationLink(destination: ProductDetailView(product: product)) {
                    DiscoveryCard(product: product)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var shimmerGrid: some View {
        LazyVGrid(columns: columns, spacing: 32) {
            ForEach(0..<6, id: \.self) { _ in
                VStack(alignment: .leading, spacing: 12) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                        .frame(width: UIScreen.main.bounds.width / 2 - 34, height: (UIScreen.main.bounds.width / 2 - 34) * 1.33)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 14)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.secondarySystemBackground))
                        .frame(height: 14)
                        .frame(width: 80)
                }
                .shimmering()
            }
        }
        .padding(.horizontal, 24)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "wifi.exclamationmark")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            Text("Bağlantı kesildi")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Button("Yenile") {
                Task { await viewModel.loadFeed() }
            }
            .padding(.horizontal, 40)
            .padding(.vertical, 12)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .padding()
    }
}

// MARK: - Discovery Components

struct TodayHereSection: View {
    let products: [Product]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("✨ Bugün Burada")
                    .font(.system(.headline, design: .serif))
                    .fontWeight(.bold)
                Spacer()
                Text("En Çok Beklenenler")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
            .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(products) { product in
                        NavigationLink(destination: ProductDetailView(product: product)) {
                            TrendingMinorCard(product: product)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

struct TrendingMinorCard: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .bottom) {
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { img in
                    img.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.1))
                }
                .frame(width: 120, height: 160)
                .cornerRadius(12)
                .clipped()
                
                Text("\(Int.random(in: 40...300)) kişi bekliyor")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.vertical, 4)
                    .frame(width: 120)
                    .background(.black.opacity(0.6))
            }
            .cornerRadius(12)
            
            Text(product.brandDisplay)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
        }
        .frame(width: 120)
    }
}

struct DiscoveryCard: View {
    let product: Product
    @State private var isLiked: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Image with Overlays
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.05))
                }
                .frame(width: UIScreen.main.bounds.width / 2 - 34, height: (UIScreen.main.bounds.width / 2 - 34) * 1.33)
                .cornerRadius(16)
                .clipped()
                
                // Track CTA (Heart Button)
                Button(action: {
                    HapticManager.shared.impact(style: .medium)
                    isLiked.toggle()
                    WatchlistManager.shared.toggleWatchlist(product: product)
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isLiked ? .red : .gray.opacity(0.8))
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .padding(10)
                
                // Discount Badge
                if let discount = calculateDiscountPercentage() {
                    Text("-\(discount)%")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.red)
                        .cornerRadius(6)
                        .padding(10)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                }
            }
            .onAppear {
                isLiked = WatchlistManager.shared.isWatching(productId: product.id)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(product.source.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .tracking(1)
                    Spacer()
                    
                    Text("Daha önce %\(Int.random(in: 20...50)) düştü")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.blue.opacity(0.8))
                }
                
                Text(product.title)
                    .font(.system(size: 13, weight: .regular))
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .frame(height: 32, alignment: .topLeading)
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(Int(product.currentPrice))₺")
                        .font(.system(size: 15, weight: .bold))
                    
                    if let original = product.originalPrice, original > product.currentPrice {
                        Text("\(Int(original))₺")
                            .font(.system(size: 11))
                            .strikethrough()
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 7, height: 7)
                        .shadow(color: .orange.opacity(0.3), radius: 2)
                }
            }
            .padding(.horizontal, 2)
        }
    }
    
    private func calculateDiscountPercentage() -> Int? {
        guard let original = product.originalPrice, original > product.currentPrice else { return nil }
        return Int(((original - product.currentPrice) / original) * 100)
    }
}



struct AdvancedEmptyState: View {
    let selectedCategory: String
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 60)
            
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.05))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 40, weight: .thin))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                Text("Bu seçimde henüz indirim yok 💭")
                    .font(.system(.headline, design: .serif))
                
                Text("Ama bu parçalar genelde yakında düşer. Takibe almamızı ister misin?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            VStack(spacing: 12) {
                Button(action: {}) {
                    Text(UserPreferences.shared.isPro ? "Kategori Alarmı Düzenle" : "Kategori Alarmı Kur (PRO)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(Color.blue)
                        .cornerRadius(14)
                }
                
                Button(action: {}) {
                    Text("Benzer Tarzları Göster")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
            }
            
            Spacer(minLength: 100)
        }
    }
}

struct InYourStyleSection: View {
    let products: [Product]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Divider().padding(.horizontal, 24)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Senin Tarzında")
                        .font(.system(.headline, design: .serif))
                    Text("Beğenebileceğin \(products.count) parça var")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 24)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(products) { product in
                        NavigationLink(destination: ProductDetailView(product: product)) {
                            VStack(alignment: .leading, spacing: 8) {
                                AsyncImage(url: URL(string: product.imageUrl ?? "")) { img in
                                    img.resizable().aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Rectangle().fill(Color.gray.opacity(0.1))
                                }
                                .frame(width: 140, height: 186)
                                .cornerRadius(12)
                                .clipped() 
                                
                                Text(product.title)
                                    .font(.system(size: 12, weight: .medium))
                                    .lineLimit(1)
                                    .foregroundColor(.primary)
                                
                                Text("\(Int(product.currentPrice)) TL")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.blue)
                            }
                            .frame(width: 140)
                        }
                    }
                    
                    // "Magic Box" Style CTA
                    VStack {
                        VStack(spacing: 12) {
                            Image(systemName: "wand.and.stars")
                                .font(.largeTitle)
                                .foregroundColor(.blue)
                            Text("Daha Fazla Gör")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .frame(width: 140, height: 180)
                        .background(LinearGradient(colors: [.blue.opacity(0.1), .purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
            }
        }
    }
}

// MARK: - Components

struct BrandStoryItem: View {
    let brand: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    if isSelected {
                        Circle()
                            .strokeBorder(LinearGradient(colors: [.orange, .purple], startPoint: .topTrailing, endPoint: .bottomLeading), lineWidth: 2.5)
                            .frame(width: 68, height: 68)
                    } else {
                        Circle()
                            .strokeBorder(Color(.separator), lineWidth: 1)
                            .frame(width: 68, height: 68)
                    }
                    
                    // Avatar / Logo Placeholder
                    Circle()
                        .fill(Color.gray.opacity(0.05))
                        .frame(width: 60, height: 60)
                        
                    // Initials as logo
                    Text(brand.prefix(1).uppercased())
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(.primary)
                }
                
                Text(brand)
                    .font(.system(size: 11, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
        }
    }
}

struct FashionProductCard: View {
    let product: Product
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Image
            ZStack(alignment: .topLeading) {
                AsyncImage(url: URL(string: product.imageUrl ?? "")) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.05))
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(3/4, contentMode: .fit) // Fashion Standard Ratio
                .clipped()
                
                // Discount Badge (Minimal)
                if let discount = calculateDiscountPercentage(product: product) {
                    Text("-% \(discount)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .offset(x: 0, y: 16) // Slightly inset
                }
            }
            // No corner radius - Sharp edges for editorial look
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.source.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gray)
                    .tracking(1)
                
                Text(product.title)
                    .font(.system(size: 13, weight: .regular))
                    .lineLimit(2)
                    .foregroundColor(.primary)
                    .frame(height: 32, alignment: .topLeading) // Fixed height for alignment
                
                HStack(alignment: .bottom, spacing: 8) {
                    if product.currentPrice > 0 {
                        Text("\(product.currentPrice, format: .currency(code: "TRY"))")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    
                    if let original = product.originalPrice, original > product.currentPrice {
                        Text("\(original, format: .currency(code: "TRY"))")
                            .font(.system(size: 12))
                            .strikethrough()
                            .foregroundColor(.gray)
                    }
                }
            }
        }
    }
    
    private func calculateDiscountPercentage(product: Product) -> Int? {
        guard let original = product.originalPrice, original > product.currentPrice else { return nil }
        return Int(((original - product.currentPrice) / original) * 100)
    }
}

// Simple shimmering extension for loading state
extension View {
    @ViewBuilder
    func shimmering() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    Color.white.opacity(0.4)
                        .mask(
                            Rectangle()
                                .fill(
                                    LinearGradient(colors: [.clear, .white.opacity(0.8), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                                .rotationEffect(.degrees(30))
                                .offset(x: phase * geo.size.width)
                        )
                }
            )
            .onAppear {
                withAnimation(Animation.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 1.5
                }
            }
    }
}
