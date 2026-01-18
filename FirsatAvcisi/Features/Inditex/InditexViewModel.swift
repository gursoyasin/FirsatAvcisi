import SwiftUI
import Combine

@MainActor
class InditexViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Filter & Sort
    @Published var searchText: String = ""
    @Published var selectedSort: SortOption = .smart
    
    @Published var selectedBrand: String = "Hepsi"
    let brands = ["Hepsi", "Zara", "Bershka", "Pull&Bear", "Stradivarius", "Oysho", "Massimo Dutti"]
    
    @Published var selectedCategory: String = "Tümü"
    let categories = ["Tümü", "Elbise", "Tişört", "Ceket", "Pantolon", "Dış Giyim", "Kazak", "Gömlek", "Ayakkabı", "Çanta", "Sweatshirt", "Etek/Şort", "Şapka", "Moda"]
    
    enum SortOption: String, CaseIterable, Identifiable {
        case smart = "Önerilen"
        case newest = "En Yeni"
        case priceLowHigh = "Fiyat (Artan)"
        case priceHighLow = "Fiyat (Azalan)"
        case discountHighLow = "İndirim Oranı"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .smart: return "sparkles"
            case .newest: return "clock"
            case .priceLowHigh: return "arrow.up.forward"
            case .priceHighLow: return "arrow.down.forward"
            case .discountHighLow: return "percent"
            }
        }
    }
    
    init() {
        Task {
            await loadFeed()
        }
    }
    
    // MARK: - Computed Properties
    
    var filteredProducts: [Product] {
        var result = products
        
        // Local Search
        if !searchText.isEmpty {
            result = result.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
        }
        
        // Sorting
        switch selectedSort {
        case .smart:
            // Smart sort: High discount + recent
            // For simplicity, let's prioritize discount rate for now
            result.sort { p1, p2 in
                let d1 = calculateDiscount(p1)
                let d2 = calculateDiscount(p2)
                return d1 > d2
            }
        case .newest:
            // Assuming the list from backend is already somewhat ordered or we don't have a date field easily
            // We'll keep original order or shuffle if needed, but usually backend sends newest.
            // Let's rely on original order for 'newest' effectively
            break 
        case .priceLowHigh:
            result.sort { $0.currentPrice < $1.currentPrice }
        case .priceHighLow:
            result.sort { $0.currentPrice > $1.currentPrice }
        case .discountHighLow:
            result.sort { p1, p2 in
                let d1 = calculateDiscount(p1)
                let d2 = calculateDiscount(p2)
                return d1 > d2
            }
        }
        
        return result
    }
    
    var topDeals: [Product] {
        // Return top 5 products with significantly high discount (e.g. > 30%)
        let allSortedByDiscount = products.sorted { calculateDiscount($0) > calculateDiscount($1) }
        return Array(allSortedByDiscount.prefix(8))
    }
    
    private func calculateDiscount(_ p: Product) -> Double {
        guard let original = p.originalPrice, original > p.currentPrice else { return 0 }
        return (original - p.currentPrice) / original
    }
    
    func loadFeed() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let brand = selectedBrand == "Hepsi" ? nil : selectedBrand
            let category = selectedCategory == "Tümü" ? nil : selectedCategory
            
            let fetched = try await APIService.shared.fetchInditexFeed(brand: brand, category: category)
            self.products = fetched
        } catch {
            self.errorMessage = "İndirimler yüklenemedi: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func changeBrand(_ brand: String) {
        selectedBrand = brand
        Task { await loadFeed() }
    }
    
    func changeCategory(_ category: String) {
        selectedCategory = category
        Task { await loadFeed() }
    }
    
    // Admin Trigger for Demo
    func triggerMiner() {
        Task {
             try? await APIService.shared.triggerInditexMiner()
        }
    }
}
