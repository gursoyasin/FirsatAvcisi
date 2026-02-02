import SwiftUI
import Combine

@MainActor
class WatchlistManager: ObservableObject {
    static let shared = WatchlistManager()
    
    @Published var trackedProductIds: Set<Int> = []
    private var cancellables = Set<AnyCancellable>()
    private let dataManager = DataManager.shared
    private let analytics = AnalyticsManager.shared
    
    private init() {
        // Initial fetch to populate tracked IDs
        Task {
            await refreshTrackedIds()
        }
    }
    
    func refreshTrackedIds() async {
        do {
            let response = try await APIService.shared.fetchProducts(page: 1, limit: 1000)
            self.trackedProductIds = Set(response.products.map { $0.id })
            
            // Cache products locally
            dataManager.saveProducts(response.products)
        } catch {
            print("Failed to refresh watchlist IDs: \(error)")
            
            // Load from cache if API fails
            let cachedProducts = dataManager.fetchAllProducts()
            self.trackedProductIds = Set(cachedProducts.map { $0.id })
        }
    }
    
    func isWatching(productId: Int) -> Bool {
        return trackedProductIds.contains(productId)
    }
    
    func toggleWatchlist(product: Product) {
        if isWatching(productId: product.id) {
            removeFromWatchlist(productId: product.id)
        } else {
            addToWatchlist(product: product)
        }
    }
    
    private func addToWatchlist(product: Product) {
        Task {
            do {
                // Map Product to ProductPreview for APIService compatibility
                let preview = AddProductViewModel.ProductPreview(
                    title: product.title,
                    currentPrice: product.currentPrice,
                    imageUrl: product.imageUrl ?? "",
                    source: product.source,
                    url: product.url
                )
                try await APIService.shared.addProduct(preview: preview)
                self.trackedProductIds.insert(product.id)
                
                // Cache locally
                dataManager.saveProduct(product)
                
                // Analytics: Ürün takibe eklendi
                analytics.logProductAdded(
                    source: product.source,
                    price: product.currentPrice,
                    hasDiscount: (product.discountPercentage ?? 0) > 0
                )
                
                HapticManager.shared.notification(type: .success)
            } catch {
                AlertManager.shared.toast("Takip listesine eklenemedi", type: .error)
                HapticManager.shared.notification(type: .error)
            }
        }
    }
    
    private func removeFromWatchlist(productId: Int) {
        Task {
            do {
                try await APIService.shared.deleteProduct(id: productId)
                self.trackedProductIds.remove(productId)
                
                // Remove from cache
                dataManager.deleteProduct(byId: productId)
                
                // Analytics: Ürün takipten çıkarıldı
                analytics.logProductRemoved(
                    source: "watchlist",
                    daysTracked: 0
                )
                
                HapticManager.shared.impact(style: .medium)
            } catch {
                AlertManager.shared.toast("Takip listesinden kaldırılamadı", type: .error)
                HapticManager.shared.notification(type: .error)
            }
        }
    }
}
