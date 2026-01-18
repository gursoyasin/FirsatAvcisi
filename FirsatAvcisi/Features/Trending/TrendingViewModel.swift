import SwiftUI
import Combine

@MainActor
class TrendingViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var selectedBrand: String? = nil
    @Published var selectedCategory: String = "Hepsi"
    
    let categories = [
        "Hepsi", "Elektronik", "Moda", "Ev", "Anne & Bebek", "Kozmetik", 
        "Spor & Outdoor", "Hobi", "Ofis & Kırtasiye", "Yapı Market", "Petshop"
    ]
    
    // Derived properties
    var filteredProducts: [Product] {
        var base = products
        if let brand = selectedBrand {
            base = base.filter { $0.source.lowercased() == brand.lowercased() }
        }
        return base
    }
    
    var topDeal: Product? {
        products.first // Sorted by discount on backend
    }
    
    var availableBrands: [String] {
        Array(Set(products.map { $0.source.capitalized })).sorted()
    }
    
    func toggleBrandFilter(_ brand: String) {
        if selectedBrand == brand {
            selectedBrand = nil
        } else {
            selectedBrand = brand
        }
    }
    
    // Quick Save (Add to Watchlist)
    func saveToWatchlist(product: Product) {
        Task {
            do {
                // Convert Product to Preview format
                let preview = AddProductViewModel.ProductPreview(
                    title: product.title,
                    currentPrice: product.currentPrice,
                    imageUrl: product.imageUrl ?? "",
                    source: product.source,
                    url: product.url
                )
                try await APIService.shared.addProduct(preview: preview)
                // Haptic Feedback could occur here
            } catch {
                await MainActor.run {
                    self.errorMessage = "Kaydedilemedi: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func loadTrending() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let fetched = try await APIService.shared.fetchTrendingProducts(category: selectedCategory == "Hepsi" ? nil : selectedCategory)
            self.products = fetched
        } catch {
            self.errorMessage = "Trendler yüklenemedi: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    // MARK: - Global Search Logic
    @Published var searchText: String = ""
    @Published var isGlobalSearching: Bool = false
    @Published var globalSearchResults: [GlobalSearchProduct] = []
    
    private var searchDebounceTimer: AnyCancellable?
    
    func performGlobalSearch() async {
        guard !searchText.isEmpty else { return }
        
        await MainActor.run {
            self.isGlobalSearching = true
            self.globalSearchResults = []
            self.errorMessage = nil
        }
        
        do {
            // Using the existing APIService global search
            let results = try await APIService.shared.globalSearch(query: searchText)
            await MainActor.run {
                self.globalSearchResults = results
                self.isGlobalSearching = false
                
                if results.isEmpty {
                    self.errorMessage = "Sonuç bulunamadı."
                }
            }
        } catch {
            await MainActor.run {
                self.isGlobalSearching = false
                self.errorMessage = "Arama başarısız: \(error.localizedDescription)"
            }
        }
    }
}
