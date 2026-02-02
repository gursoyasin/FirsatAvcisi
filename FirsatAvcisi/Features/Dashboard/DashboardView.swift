import SwiftUI
import Charts

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingAddProduct = false
    @State private var showingSettings = false
    @State private var showingStories = false
    @State private var showingNotifications = false
    
    // Grid Layout
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    @State private var showingCollectionSelection = false
    
    // Deep Link
    @EnvironmentObject var deepLinkManager: DeepLinkManager
    @State private var deepLinkProduct: Product?
    @State private var showDeepLinkProduct = false
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // Invisible Navigation Link for Deep Linking
                NavigationLink(isActive: $showDeepLinkProduct, destination: {
                    if let product = deepLinkProduct {
                        ProductDetailView(product: product)
                    }
                }) { EmptyView() }
                
                // Background Gradient Mesh
                ZStack {
                    LinearGradient(
                        colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1), Color(uiColor: .systemGroupedBackground)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    // Decorative Orbs
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 300, height: 300)
                        .blur(radius: 60)
                        .offset(x: -100, y: -150)
                    
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 250, height: 250)
                        .blur(radius: 60)
                        .offset(x: 150, y: -50)
                }
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Dynamic Header
                        HunterHeaderView(showingNotifications: $showingNotifications)
                        
                        // 1.5 STORIES (Ultra Feature)
                        // 1.5 MONTHLY WRAP (Delici Feature)
                        // Trigger only if there are savings or activity
                        if calculateTotalSavings() > 0 {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 15) {
                                    // Wrap Entry Circle
                                    Button(action: {
                                        showingStories = true
                                    }) {
                                        VStack {
                                            ZStack {
                                                Circle()
                                                    .stroke(
                                                        LinearGradient(colors: [.green, .mint], startPoint: .bottomLeading, endPoint: .topTrailing),
                                                        lineWidth: 3
                                                    )
                                                    .frame(width: 68, height: 68)
                                                
                                                Image(systemName: "star.fill")
                                                    .font(.title)
                                                    .foregroundColor(.green)
                                                
                                                // New Badge
                                                VStack {
                                                    Spacer()
                                                    Text(LocalizedStringKey("dashboard.new"))
                                                        .font(.system(size: 8, weight: .bold))
                                                        .padding(4)
                                                        .background(Color.red)
                                                        .foregroundColor(.white)
                                                        .cornerRadius(4)
                                                        .offset(y: 8)
                                                }
                                            }
                                            Text("dashboard.month.summary")
                                                .font(.caption)
                                                .bold()
                                                .multilineTextAlignment(.center)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .padding(.bottom, 5)
                        } 
                        
                        // 2. Stats Carousel
                        HuntStatsView(
                            savedAmount: calculateTotalSavings(),
                            onSaleCount: viewModel.products.filter { $0.currentPrice < ($0.targetPrice ?? 0) }.count,
                            trackingCount: viewModel.products.count
                        )
                        
                        // 3. Search Bar (Premium Style)
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("dashboard.search.placeholder", text: $viewModel.searchText)
                                .textFieldStyle(.plain)
                            
                            if !viewModel.searchText.isEmpty {
                                Button(action: {
                                    Task {
                                        await viewModel.performGlobalSearch()
                                    }
                                }) {
                                    if viewModel.isGlobalSearching {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Text(LocalizedStringKey("dashboard.search.button"))
                                            .font(.caption)
                                            .bold()
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(Color.blue)
                                            .foregroundColor(.white)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Material.ultraThinMaterial)
                        .cornerRadius(16)
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                        
                        // 4. Premium Filters
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(DashboardViewModel.FilterType.allCases, id: \.self) { filter in
                                    PremiumFilterChip(
                                        title: filter.localizedName,
                                        icon: filterIcon(for: filter),
                                        isSelected: viewModel.selectedFilter == filter
                                    ) {
                                        viewModel.selectFilter(filter)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 4) // Space for shadow
                        }
                        
                        // Content Section
                        VStack(spacing: 20) {
                            // A. GLOBAL SEARCH RESULTS
                            if viewModel.isGlobalSearching || !viewModel.globalSearchResults.isEmpty {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "globe.europe.africa.fill")
                                            .font(.title2)
                                            .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .top, endPoint: .bottom))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(viewModel.isGlobalSearching ? "dashboard.exploring" : "dashboard.discovered")
                                                .font(.headline)
                                            Text("dashboard.scanning")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            if viewModel.isGlobalSearching {
                                                ForEach(0..<3) { _ in GlobalSearchCardSkeleton() }
                                            } else {
                                                ForEach(viewModel.globalSearchResults) { globalProduct in
                                                    GlobalSearchCard(product: globalProduct)
                                                }
                                            }
                                        }
                                        .padding(.horizontal)
                                        .padding(.bottom, 20)
                                    }
                                }
                                .padding(.vertical, 20)
                                .background(RoundedRectangle(cornerRadius: 24).fill(Color(uiColor: .secondarySystemGroupedBackground)).shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5))
                                .padding(.horizontal)
                                .transition(.asymmetric(insertion: .move(edge: .top).combined(with: .opacity), removal: .opacity))
                            } else if !viewModel.searchText.isEmpty && !viewModel.isGlobalSearching && viewModel.globalSearchResults.isEmpty && viewModel.filteredProducts.isEmpty {
                                // No results in global AND no results in local
                                VStack(spacing: 20) {
                                    Image(systemName: "exclamationmark.magnifyingglass")
                                        .font(.system(size: 50))
                                        .foregroundColor(.gray.opacity(0.3))
                                    Text("dashboard.noresults.title")
                                        .font(.headline)
                                    Text("dashboard.noresults.desc")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 50)
                            }

                            // B. MAIN LIST (Your Tracked Products)
                            if viewModel.isLoading && viewModel.products.isEmpty {
                                // Skeleton Loading
                                LazyVGrid(columns: columns, spacing: 16) {
                                    ForEach(0..<6, id: \.self) { _ in
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white)
                                            .frame(height: 280)
                                            .skeleton(isLoading: true)
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.top, 20)
                            } else if viewModel.filteredProducts.isEmpty && viewModel.globalSearchResults.isEmpty && !viewModel.isGlobalSearching {
                                EmptyStateView(
                                    icon: "bag.badge.plus",
                                    title: NSLocalizedString("dashboard.watchlist.empty.title", comment: ""),
                                    message: NSLocalizedString("dashboard.watchlist.empty.message", comment: ""),
                                    buttonTitle: NSLocalizedString("dashboard.watchlist.empty.button", comment: ""),
                                    action: { showingAddProduct = true }
                                )
                                .padding(.top, 40)
                            } else if !viewModel.filteredProducts.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    if !viewModel.globalSearchResults.isEmpty || viewModel.isGlobalSearching {
                                        Text("dashboard.tracking.title")
                                            .font(.headline)
                                            .padding(.horizontal)
                                    }
                                    
                                    LazyVGrid(columns: columns, spacing: 16) {
                                        ForEach(viewModel.filteredProducts) { product in
                                            ProductContainer(product: product, viewModel: viewModel)
                                        }
                                        
                                        if viewModel.canLoadMore {
                                            ProgressView()
                                                .onAppear { Task { await viewModel.fetchProducts(isRefresh: false) } }
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.bottom, 150)
                    }
                }
                .refreshable {
                    await viewModel.fetchProducts()
                }
                
                // Bottom Toolbar for Edit Mode
                if viewModel.isEditMode {
                    EditOverlay(
                        selectedCount: viewModel.selectedProductIDs.count,
                        onDelete: { Task { await viewModel.deleteSelected() } },
                        onAddToCollection: { 
                            Task {
                                await viewModel.fetchCollections()
                                showingCollectionSelection = true
                            }
                        },
                        onCancel: { 
                            viewModel.isEditMode = false
                            viewModel.selectedProductIDs.removeAll()
                        }
                    )
                    .transition(.move(edge: .bottom))
                    .zIndex(10)
                }
                
                // ... FAB ...
                if !viewModel.isEditMode {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Button(action: { showingAddProduct = true }) {
                                Image(systemName: "plus")
                                    .font(.title.weight(.bold))
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                    .clipShape(Circle())
                                    .shadow(color: .blue.opacity(0.4), radius: 10, x: 0, y: 5)
                            }
                            .padding()
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingCollectionSelection) {
                CollectionSelectionSheet(viewModel: viewModel)
            }
            .fullScreenCover(isPresented: $showingAddProduct) {
                AddProductView()
                    .onDisappear {
                        Task { await viewModel.fetchProducts() }
                    }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .sheet(isPresented: $showingNotifications) {
                NotificationListView()
            }
            .fullScreenCover(isPresented: $showingStories) {
                MonthlyWrapView(
                    totalSavings: calculateTotalSavings(),
                    bestCatch: viewModel.products.max(by: { ($0.discountPercentage ?? 0) < ($1.discountPercentage ?? 0) }),
                    hunterScore: min(100, Int(calculateTotalSavings() / 50) + (viewModel.products.count * 5)), // Mock Score Logic
                    isPresented: $showingStories
                )
            }
        }
        .task {
            await viewModel.fetchProducts()
        }
        .onChange(of: deepLinkManager.currentTarget) { target in
            if let target = target {
                switch target {
                case .product(let id):
                    Task {
                        // Check if in current list
                        if let local = viewModel.products.first(where: { $0.id == id }) {
                            self.deepLinkProduct = local
                            self.showDeepLinkProduct = true
                        } else {
                            // Fetch from API
                            do {
                                let remote = try await APIService.shared.fetchProduct(id: id)
                                self.deepLinkProduct = remote
                                self.showDeepLinkProduct = true
                            } catch {
                                print("Deep Link Error: \(error)")
                            }
                        }
                        // Reset target so it can be triggered again if needed
                        deepLinkManager.currentTarget = nil
                    }
                case .collection:
                    // Implement collection deep link later
                    break
                }
            }
        }
    }

    private func calculateTotalSavings() -> Double {
        var totalSavings: Double = 0
        for product in viewModel.products {
            if let history = product.history, let first = history.first, first.price > product.currentPrice {
                totalSavings += (first.price - product.currentPrice)
            }
        }
        return totalSavings
    }

    private func filterIcon(for filter: DashboardViewModel.FilterType) -> String {
        switch filter {
        case .all: return "square.grid.2x2.fill"
        case .discounted: return "percent"
        case .stock: return "box.truck.badge.clock.fill"
        case .zara, .trendyol, .amazon: return "cart.fill"
        }
    }
}


