import SwiftUI

struct InditexView: View {
    @StateObject private var viewModel = InditexViewModel()
    @FocusState private var isSearchFocused: Bool
    
    // Fashion Standard 2-Column Grid
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea() // Pure white background for premium feel
                
                VStack(spacing: 0) {
                    // Minimal Header
                    headerView
                    
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // Story-style Brand Filter
                            brandStorySection
                            
                            // Categories (Pill Style - Subtle)
                            categorySection
                            
                            // Content
                            if viewModel.isLoading {
                                shimmerGrid
                            } else if let error = viewModel.errorMessage {
                                errorView(message: error)
                            } else if viewModel.filteredProducts.isEmpty {
                                emptyStateView
                            } else {
                                productGrid
                            }
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 100)
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
                .font(.system(size: 24, weight: .heavy, design: .serif)) // Editorial / Vogue style
                .tracking(2) // Tracking for elegance
            
            Spacer()
            
            // Search Icon (expands or overlay)
            Button {
                withAnimation { isSearchFocused.toggle() }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.black)
            }
            .padding(.trailing, 8)
            
            // Sort Menu
            Menu {
                Picker("Sıralama", selection: $viewModel.selectedSort) {
                    ForEach(InditexViewModel.SortOption.allCases) { option in
                        Label(option.rawValue, systemImage: option.icon)
                            .tag(option)
                    }
                }
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
            // Search Overlay
            Group {
                if isSearchFocused {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(.gray)
                        TextField("Marka, ürün veya kategori ara", text: $viewModel.searchText)
                            .focused($isSearchFocused)
                        Button("İptal") {
                            viewModel.searchText = ""
                            isSearchFocused = false
                        }
                        .foregroundColor(.black)
                        .font(.system(size: 14))
                    }
                    .padding()
                    .background(Color.white)
                }
            }
        )
    }
    
    private var brandStorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.brands, id: \.self) { brand in
                    BrandStoryItem(
                        brand: brand,
                        isSelected: viewModel.selectedBrand == brand,
                        action: {
                            HapticManager.shared.impact(style: .light)
                            viewModel.changeBrand(brand)
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var categorySection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.categories, id: \.self) { category in
                    Button(action: {
                        HapticManager.shared.impact(style: .light)
                        viewModel.changeCategory(category)
                    }) {
                        Text(category)
                            .font(.system(size: 13, weight: .medium))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(viewModel.selectedCategory == category ? Color.black : Color.gray.opacity(0.1))
                            .foregroundColor(viewModel.selectedCategory == category ? .white : .black)
                            .cornerRadius(8) // Slightly rounded, but boxy
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var productGrid: some View {
        LazyVGrid(columns: columns, spacing: 24) { // More breathing room vertical
            ForEach(viewModel.filteredProducts) { product in
                NavigationLink(destination: ProductDetailView(product: product)) {
                    FashionProductCard(product: product)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Loading & States
    
    private var shimmerGrid: some View {
        LazyVGrid(columns: columns, spacing: 24) {
            ForEach(0..<6, id: \.self) { _ in
                VStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.gray.opacity(0.1))
                        .aspectRatio(3/4, contentMode: .fit)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 12)
                        .frame(width: 100)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.1))
                        .frame(height: 12)
                        .frame(width: 60)
                }
                .shimmering() // Assuming Shimmer modifier exists usually, or we use basic opacity animation
            }
        }
        .padding(.horizontal, 20)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "wifi.slash")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(.gray)
            Text("Bağlantı Sorunu")
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
            Button("Tekrar Dene") {
                Task { await viewModel.loadFeed() }
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 12)
            .background(Color.black)
            .foregroundColor(.white)
            .cornerRadius(0)
            Spacer()
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 100)
            Image(systemName: "bag")
                .font(.system(size: 50, weight: .thin))
                .foregroundColor(.gray)
            Text("Sonuç Bulunamadı")
                .font(.custom("Didot", size: 18))
            Text("Seçimlerinize uygun stil bulunamadı.")
                .font(.caption)
                .foregroundColor(.gray)
            Spacer()
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
                            .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                            .frame(width: 68, height: 68)
                    }
                    
                    // Avatar / Logo Placeholder
                    Circle()
                        .fill(Color.gray.opacity(0.05))
                        .frame(width: 60, height: 60)
                        
                    // Initials as logo
                    Text(brand.prefix(1).uppercased())
                        .font(.system(size: 24, weight: .bold, design: .serif))
                        .foregroundColor(.black)
                }
                
                Text(brand)
                    .font(.system(size: 11, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? .black : .gray)
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
                    .foregroundColor(.black)
                    .frame(height: 32, alignment: .topLeading) // Fixed height for alignment
                
                HStack(alignment: .bottom, spacing: 8) {
                    if product.currentPrice > 0 {
                        Text("\(product.currentPrice, format: .currency(code: "TRY"))")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.black)
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
