import SwiftUI
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedFilter: FilterType = .all
    @Published var selectedSort: SortType = .newest
    @Published var searchText: String = ""
    
    // Batch Selection
    @Published var isEditMode: Bool = false
    @Published var selectedProductIDs: Set<Int> = []
    
    // Global Search
    @Published var globalSearchResults: [GlobalSearchProduct] = []
    @Published var isGlobalSearching: Bool = false
    
    private let apiService = APIService.shared
    
    enum FilterType: String, CaseIterable {
        case all = "Tümü"
        case discounted = "İndirimde"
        case stock = "Stokta"
        case zara = "Zara"
        case trendyol = "Trendyol"
        case amazon = "Amazon"
    }

    enum SortType {
        case newest, priceLowHigh, priceHighLow, biggestDiscount
    }
    
    @Published var currentPage = 1
    @Published var canLoadMore = true
    private let limit = 20

    func fetchProducts(isRefresh: Bool = true) async {
        if isRefresh {
            currentPage = 1
            canLoadMore = true
        }
        
        guard !isLoading && canLoadMore else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.fetchProducts(page: currentPage, limit: limit)
            if isRefresh {
                self.products = response.products
            } else {
                self.products.append(contentsOf: response.products)
            }
            
            self.currentPage += 1
            self.canLoadMore = response.pagination.page < response.pagination.totalPages
        } catch {
            self.errorMessage = "Ürünler yüklenemedi: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    var filteredProducts: [Product] {
        var result = products
        
        // 1. Search
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        // 2. Filter
        switch selectedFilter {
        case .all: break
        case .discounted:
            result = result.filter { product in
                if let history = product.history, let first = history.first {
                    return product.currentPrice < first.price
                }
                return (product.discountPercentage ?? 0) > 0
            }
        case .stock:
            result = result.filter { $0.inStock ?? true }
        case .zara:
            result = result.filter { $0.source.lowercased() == "zara" }
        case .trendyol:
            result = result.filter { $0.source.lowercased() == "trendyol" }
        case .amazon:
            result = result.filter { $0.source.lowercased() == "amazon" }
        }
        
        // 3. Sort
        switch selectedSort {
        case .newest:
            result.sort { $0.id > $1.id } // simple id based sort for newest
        case .priceLowHigh:
            result.sort { $0.currentPrice < $1.currentPrice }
        case .priceHighLow:
            result.sort { $0.currentPrice > $1.currentPrice }
        case .biggestDiscount:
            result.sort { ($0.discountPercentage ?? 0) > ($1.discountPercentage ?? 0) }
        }
        
        return result
    }

    func toggleSelection(for id: Int) {
        if selectedProductIDs.contains(id) {
            selectedProductIDs.remove(id)
        } else {
            selectedProductIDs.insert(id)
        }
    }

    func deleteSelected() async {
        guard !selectedProductIDs.isEmpty else { return }
        isLoading = true
        do {
            // Need to implement batch delete in APIService too, or loop
            // Plan said Batch Delete endpoint, so I'll add it to APIService later
            // For now, assume it exists
            try await apiService.batchDeleteProducts(ids: Array(selectedProductIDs))
            await fetchProducts()
            isEditMode = false
            selectedProductIDs.removeAll()
        } catch {
            self.errorMessage = "Silme işlemi başarısız: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    @Published var collections: [AppCollection] = []
    
    // ... logic ...
    
    func fetchCollections() async {
        do {
            self.collections = try await apiService.fetchCollections()
        } catch {
            print("Failed to fetch collections")
        }
    }

    func addToCollection(collectionId: Int) async {
        guard !selectedProductIDs.isEmpty else { return }
        do {
            for productId in selectedProductIDs {
                try await apiService.addProductToCollection(collectionId: collectionId, productId: productId)
            }
            isEditMode = false
            selectedProductIDs.removeAll()
            await fetchProducts()
        } catch {
            self.errorMessage = "Koleksiyona eklenemedi"
        }
    }
    func selectFilter(_ filter: FilterType) {
        self.selectedFilter = filter
    }
    
    func selectSort(_ sort: SortType) {
        self.selectedSort = sort
    }
    
    func performGlobalSearch() async {
        guard !searchText.isEmpty else { return }
        isGlobalSearching = true
        errorMessage = nil
        do {
            self.globalSearchResults = try await apiService.globalSearch(query: searchText)
            // Haptic Feedback when search finishes
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(self.globalSearchResults.isEmpty ? .warning : .success)
        } catch {
            self.errorMessage = "Mağazalarda arama yapılamadı: \(error.localizedDescription)"
        }
        isGlobalSearching = false
    }
}
