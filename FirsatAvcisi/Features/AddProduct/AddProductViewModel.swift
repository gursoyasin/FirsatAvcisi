import SwiftUI
import Combine

@MainActor
class AddProductViewModel: ObservableObject {
    @Published var url: String = ""
    @Published var isLoading: Bool = false
    @Published var previewProduct: ProductPreview?
    @Published var errorMessage: String?
    @Published var shouldDismiss: Bool = false
    @Published var showPaywall: Bool = false
    
    private let apiService = APIService.shared
    
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
        errorMessage = nil
        
        do {
            let preview = try await apiService.previewProduct(url: url)
            self.previewProduct = preview
        } catch {
            self.errorMessage = "Ürün bilgileri alınamadı: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func saveProduct() async {
        guard let p = previewProduct else { return }
        
        isLoading = true
        
        do {
            try await apiService.addProduct(preview: p)
            shouldDismiss = true
        } catch APIError.limitReached {
            self.showPaywall = true
        } catch {
            self.errorMessage = "Kaydetme başarısız: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}
