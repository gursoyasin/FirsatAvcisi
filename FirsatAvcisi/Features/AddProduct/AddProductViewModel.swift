import SwiftUI
import Combine

@MainActor
class AddProductViewModel: ObservableObject {
    @Published var url: String = ""
    @Published var isLoading: Bool = false
    @Published var previewProduct: ProductPreview?
    @Published var shouldDismiss: Bool = false
    @Published var showPaywall: Bool = false
    
    @Published var targetPrice: Double? = nil
    
    private let apiService = APIService.shared
    private let alertManager = AlertManager.shared
    private let analytics = AnalyticsManager.shared
    
    // Geçici Preview Modeli (APIService içinde de tanımlı olabilir, buraya taşıyoruz)
    struct ProductPreview: Codable {
        let title: String
        let currentPrice: Double
        let imageUrl: String
        let source: String
        let url: String
    }
    
    func analyzeLink() async {
        guard !url.isEmpty else { return }
        
        isLoading = true
        targetPrice = nil // Reset target logic
        
        do {
            let preview = try await apiService.previewProduct(url: url)
            self.previewProduct = preview
        } catch {
            alertManager.toast("Ürün bilgileri alınamadı: \(error.localizedDescription)", type: .error)
        }
        
        isLoading = false
    }
    
    func saveProduct() async {
        guard let p = previewProduct else { return }
        
        isLoading = true
        
        do {
            try await apiService.addProduct(preview: p, targetPrice: targetPrice)
            
            // Analytics: Ürün eklendi
            analytics.logProductAdded(
                source: p.source,
                price: p.currentPrice,
                hasDiscount: false
            )
            
            // Analytics: Hedef fiyat varsa
            if let target = targetPrice {
                analytics.logTargetPriceSet(
                    originalPrice: p.currentPrice,
                    targetPrice: target
                )
            }
            
            alertManager.toast("Ürün başarıyla eklendi!", type: .success)
            shouldDismiss = true
        } catch APIError.limitReached {
            self.showPaywall = true
        } catch {
            alertManager.toast("Kaydetme başarısız: \(error.localizedDescription)", type: .error)
        }
        
        isLoading = false
    }
    
    // MARK: - Smart Probability Logic
    func getProbability(current: Double, target: Double) -> (text: String, score: Double, color: Color) {
        let discountRate = (current - target) / current
        
        // Logic:
        // < 5% discount: Easy (High Probability)
        // 5% - 15% discount: Medium (Medium Probability)
        // > 15% discount: Hard (Low Probability)
        
        if target >= current {
             return ("Anında", 1.0, .green)
        }
        
        if discountRate <= 0.05 {
            return ("Çok Yüksek", 0.95, .green)
        } else if discountRate <= 0.15 {
            return ("Orta", 0.60, .yellow)
        } else if discountRate <= 0.25 {
            return ("Düşük", 0.30, .orange)
        } else {
            return ("Mucize", 0.05, .red)
        }
    }
}
