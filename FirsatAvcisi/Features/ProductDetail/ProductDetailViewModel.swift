import SwiftUI
import Combine

@MainActor
class ProductDetailViewModel: ObservableObject {
    @Published var product: Product
    @Published var isLoading = false
    // Grafikte göstereceğimiz veri seti (MVP için mock, sonrasında API'den detay gelecek)
    @Published var priceHistory: [PricePoint] = []
    @Published var alternatives: [AlternativeProduct] = []
    
    // AI Analysis
    @Published var analysisResult: APIService.AnalysisResult?
    @Published var isAnalyzeLoading = false

    init(product: Product) {
        self.product = product
        
        // Başlangıçta mevcut fiyatı tek bir nokta olarak ekle
        self.priceHistory = [
            PricePoint(date: Date(), price: product.currentPrice)
        ]
    }
    
    func loadAlternatives() async {
        do {
            let results = try await APIService.shared.fetchAlternatives(for: product.id)
            await MainActor.run {
                self.alternatives = results
            }
        } catch {
            print("Failed to load alternatives: \(error)")
        }
    }
    
    func fetchAnalysis() async {
        isAnalyzeLoading = true
        do {
            let result = try await APIService.shared.fetchProductAnalysis(productId: product.id)
            await MainActor.run {
                self.analysisResult = result
                self.isAnalyzeLoading = false
            }
        } catch {
            print("Analysis failed: \(error)")
            await MainActor.run { self.isAnalyzeLoading = false }
        }
    }
    
    func updateTargetPrice(_ price: Double) async {
        do {
            try await APIService.shared.updateTargetPrice(id: product.id, price: price)
            // Update local state
            await MainActor.run {
                var updated = product
                updated.targetPrice = price
                self.product = updated
            }
        } catch {
            print("Target price update failed: \(error)")
        }
    }
    
    func deleteProduct() async throws {
        try await APIService.shared.deleteProduct(id: product.id)
    }
    
    // Statistics
    var minPrice: Double {
        priceHistory.map { $0.price }.min() ?? product.currentPrice
    }
    
    var maxPrice: Double {
        priceHistory.map { $0.price }.max() ?? product.currentPrice
    }
    
    var averagePrice: Double {
        guard !priceHistory.isEmpty else { return product.currentPrice }
        let total = priceHistory.reduce(0) { $0 + $1.price }
        return total / Double(priceHistory.count)
    }
    
    var opportunityScore: Int {
        let max = maxPrice
        guard max > 0 else { return 50 }
        let current = product.currentPrice
        
        // Simple algorithm: Lower price relative to max = Higher Score
        // If current == max, score 0. If current == 0, score 100.
        // But likely prices don't drop to 0. Let's aim for 50% discount = 100 score.
        
        let ratio = current / max
        // ratio 1.0 -> 0 score
        // ratio 0.5 -> 100 score
        
        if ratio >= 1.0 { return 10 }
        let score = (1.0 - ratio) * 200 // e.g. 0.9 (10% off) -> 0.1 * 200 = 20
        return min(Int(score) + 40, 100) // Base 40 points for just being here
    }

    // Process or refresh history data
    func refreshData() async {
        // Use real history from the product model
        if let history = product.history, !history.isEmpty {
            let dateFormatter = ISO8601DateFormatter()
            dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] 
            
            self.priceHistory = history.compactMap { h in
                // Handle date string
                guard let date = dateFormatter.date(from: h.checkedAt) ?? ISO8601DateFormatter().date(from: h.checkedAt) else { return nil }
                return PricePoint(date: date, price: h.price)
            }
        } else {
             // Fallback: If absolutely no history, show current price point
             self.priceHistory = [PricePoint(date: Date(), price: product.currentPrice)]
        }
    }
}

struct PricePoint: Identifiable {
    let id = UUID()
    let date: Date
    let price: Double
}
