import SwiftUI

struct WatchlistView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingAddProduct = false
    @State private var showingSettings = false
    
    // Premium Grid Layout
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                // ambient background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // 1. Sleek Header
                        HStack {
                            Text("Takip Listem")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Button(action: { showingSettings = true }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.secondary)
                                    .padding(10)
                                    .background(Color(uiColor: .secondarySystemBackground))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 10)
                        
                        // 2. Summary Card
                        if !viewModel.products.isEmpty {
                            HStack(spacing: 12) {
                                SummaryStatCard(
                                    title: "Takip Edilen",
                                    value: "\(viewModel.products.count)",
                                    icon: "eye.fill",
                                    color: .blue
                                )
                                
                                SummaryStatCard(
                                    title: "Tasarruf",
                                    value: calculateTotalSavings() > 0 ? "\(Int(calculateTotalSavings())) TL" : "0 TL",
                                    icon: "arrow.down.circle.fill",
                                    color: .green
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        // 3. Product Grid
                        if viewModel.isLoading {
                            VStack {
                                ProgressView()
                                    .padding()
                                Text("Fiyatlar kontrol ediliyor...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(height: 200)
                        } else if viewModel.filteredProducts.isEmpty {
                            EmptyStateView(
                                icon: "cart.badge.plus",
                                title: "Listeniz Boş",
                                message: "Fiyatını takip etmek istediğiniz ürünleri ekleyin, indirimlerden anında haberdar olun.",
                                buttonTitle: "Ürün Ekle",
                                action: { showingAddProduct = true }
                            )
                            .padding(.top, 40)
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(viewModel.filteredProducts) { product in
                                    NavigationLink(destination: ProductAggregatorView(product: product)) {
                                        ProductCard(product: product) {
                                            // Quick Action within Card if needed
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            viewModel.selectedProductIDs.insert(product.id)
                                            Task { await viewModel.deleteSelected() }
                                        } label: {
                                            Label("Listeden Kaldır", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                        }
                    }
                }
                .refreshable {
                    await viewModel.fetchProducts()
                    // Trigger backend price check on refresh
                    Task {
                        try? await APIService.shared.triggerWatchlistCheck()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
            .fullScreenCover(isPresented: $showingAddProduct) {
                AddProductView()
            }
        }
        .task {
            await viewModel.fetchProducts()
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
}

// Subview: Summary Stat Card
struct SummaryStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            Spacer()
            
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
        }
        .padding(16)
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.03), radius: 5, x: 0, y: 2)
    }
}
