import SwiftUI

struct MarketFeedView: View {
    @StateObject private var viewModel = TrendingViewModel()
    @State private var showSuccessToast = false
    @State private var showingAddProduct = false
    @FocusState private var isSearchFocused: Bool
    
    // Grid Layout - slightly wider for marketplace feel
    let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottom) {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // MARK: - 1. HEADER & SEARCH HERO
                    VStack(spacing: 16) {
                        // Title / Logo Area
                        HStack {
                            Text("Fırsat Avcısı")
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundStyle(LinearGradient(colors: [.blue, .indigo], startPoint: .leading, endPoint: .trailing))
                            Spacer()
                            // Notifications / Cart
                            Button(action: {}) {
                                Image(systemName: "bell")
                                    .font(.system(size: 20))
                                    .foregroundColor(.primary)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        // Hero Search Bar
                        HStack {
                            // Search Button (Left)
                            Button(action: {
                                isSearchFocused = false
                                Task { await viewModel.performGlobalSearch() }
                            }) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 18))
                            }
                            
                            TextField("Ürün, marka veya kategori ara...", text: $viewModel.searchText)
                                .textFieldStyle(.plain)
                                .focused($isSearchFocused)
                                .submitLabel(.search)
                                .onSubmit {
                                    isSearchFocused = false
                                    Task { await viewModel.performGlobalSearch() }
                                }
                            
                            if !viewModel.searchText.isEmpty {
                                Button(action: {
                                    viewModel.searchText = ""
                                    viewModel.isGlobalSearching = false
                                    viewModel.globalSearchResults = []
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                            
                            // Link/Add Button
                            Button(action: {
                                showingAddProduct = true
                            }) {
                                Image(systemName: "link.badge.plus")
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(14)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
                        .padding(.horizontal)
                        .padding(.bottom, 10)
                    }
                    .background(Color(uiColor: .systemGroupedBackground))
                    .zIndex(10)
                    
                    // MARK: - 2. CONTENT SCROLL VIEW
                    ScrollView {
                        VStack(spacing: 24) {
                            
                            // A. CATEGORIES (Horizontal)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Popüler Kategoriler")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        CategoryIcon(title: "Telefon", icon: "iphone", color: .blue) {
                                            viewModel.selectedCategory = "Telefon"
                                            Task { await viewModel.loadTrending() }
                                        }
                                        CategoryIcon(title: "Bilgisayar", icon: "laptopcomputer", color: .purple) {
                                            viewModel.selectedCategory = "Bilgisayar"
                                            Task { await viewModel.loadTrending() }
                                        }
                                        CategoryIcon(title: "Moda", icon: "tshirt", color: .pink) {
                                            viewModel.selectedCategory = "Moda"
                                            Task { await viewModel.loadTrending() }
                                        }
                                        CategoryIcon(title: "Market", icon: "cart", color: .green) {
                                            viewModel.selectedCategory = "Market"
                                            Task { await viewModel.loadTrending() }
                                        }
                                        CategoryIcon(title: "Kozmetik", icon: "eyebrow", color: .orange) {
                                            viewModel.selectedCategory = "Kozmetik"
                                            Task { await viewModel.loadTrending() }
                                        }
                                        CategoryIcon(title: "Spor", icon: "figure.run", color: .teal) {
                                            viewModel.selectedCategory = "Spor"
                                            Task { await viewModel.loadTrending() }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                            .padding(.top, 10)
                            
                            // B. GLOBAL SEARCH RESULTS (If Text Exists)
                            if !viewModel.searchText.isEmpty {
                                GlobalSearchResultsSection(viewModel: viewModel)
                            } else {
                                // C. TRENDING / DISCOUNTS FEED
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Text("Günün Fırsatları 🔥")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    
                                    if viewModel.isLoading {
                                        ProgressView().frame(maxWidth: .infinity, minHeight: 100)
                                    } else if viewModel.filteredProducts.isEmpty {
                                        Text("Şu an vitrinde ürün yok.")
                                            .foregroundColor(.secondary)
                                            .frame(maxWidth: .infinity, minHeight: 100)
                                    } else {
                                        LazyVGrid(columns: columns, spacing: 16) {
                                            ForEach(viewModel.filteredProducts) { product in
                                                NavigationLink(destination: ProductAggregatorView(product: product)) {
                                                    ProductCard(product: product) {
                                                        viewModel.saveToWatchlist(product: product)
                                                        showToast()
                                                    }
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        await viewModel.loadTrending()
                    }
                }
                
                // Toast
                if showSuccessToast {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Takip Listesine Eklendi")
                                .fontWeight(.bold)
                        }
                        .padding()
                        .background(Material.regularMaterial)
                        .cornerRadius(30)
                        .shadow(radius: 10)
                        .padding(.bottom, 30)
                        .transition(.scale.combined(with: .opacity))
                    }
                    .zIndex(100)
                }
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showingAddProduct) {
                AddProductView()
            }
            .onAppear {
                Task { await viewModel.loadTrending() }
            }
        }
    }
    
    func showToast() {
        withAnimation { showSuccessToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation { showSuccessToast = false }
        }
    }
}

// MARK: - Subviews for Market Feed

struct CategoryIcon: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(color)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
    }
}

// MarketProductCard moved to Core/Components/ProductCard.swift
// Helper Subview for Search Results
struct GlobalSearchResultsSection: View {
    @ObservedObject var viewModel: TrendingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "globe.europe.africa.fill")
                    .font(.title2)
                    .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.isGlobalSearching ? "Web Taranıyor..." : "Arama Sonuçları")
                        .font(.headline)
                    Text("Tüm mağazalar taranıyor")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal)
            
            if viewModel.isGlobalSearching {
                ProgressView()
                    .scaleEffect(1.2)
                    .frame(maxWidth: .infinity)
                    .padding(40)
            } else if viewModel.globalSearchResults.isEmpty {
                 VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.gray.opacity(0.3))
                    Text(viewModel.errorMessage ?? "Sonuç bulunamadı")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(viewModel.globalSearchResults) { globalProduct in
                            GlobalSearchCard(product: globalProduct)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
            }
        }
        .padding(.vertical, 20)
        .background(Color(uiColor: .secondarySystemBackground))
    }
}


