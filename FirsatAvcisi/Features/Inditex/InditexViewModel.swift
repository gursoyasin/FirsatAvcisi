import SwiftUI
import Combine

@MainActor
class InditexViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var trendingProducts: [Product] = []
    @Published var personalizedProducts: [Product] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Filter & Sort
    @Published var searchText: String = ""
    @Published var selectedSort: SortOption = .smart
    
    @Published var selectedBrand: String = "Hepsi"
    let brands = ["Hepsi", "Zara", "Bershka", "Pull&Bear", "Stradivarius", "Oysho", "Massimo Dutti"]
    
    // Intent-based Categories
    @Published var selectedCategory: String = "Tümü"
    let categoryMap: [String: String] = [
        "Tümü": "Tümü",
        "Günlük": "Elbise",
        "Akşamlık": "Moda",
        "Mevsim Geçişi": "Ceket",
        "Ofis Stili": "Gömlek",
        "Rahat Takıl": "Sweatshirt",
        "Tamamlayıcı": "Çanta",
        "Stil": "Ayakkabı"
    ]
    
    var categories: [String] {
        ["Tümü", "Günlük", "Akşamlık", "Mevsim Geçişi", "Ofis Stili", "Rahat Takıl", "Tamamlayıcı", "Stil"]
    }
    
    // Brand Insights (Smart Copy)
    var brandInsight: String {
        switch selectedBrand {
        case "Zara":
            return "Zara’da bugün indirim sessiz ama hareket var 👀"
        case "Bershka":
            return "Bershka genelde Cuma akşamları düşer 🔥"
        case "Pull&Bear":
            return "Street parçalar indirime yaklaşıyor, pusuda kal"
        case "Stradivarius":
            return "Basic parçalarda stoklar yenilenmiş görünüyor ✨"
        case "Massimo Dutti":
            return "Premium koleksiyonda beklenen düşüş kapıda 💎"
        default:
            return "Bugün senin için seçtiğimiz yeni fırsatlar burada"
        }
    }
    
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
            result.sort { p1, p2 in
                let d1 = calculateDiscount(p1)
                let d2 = calculateDiscount(p2)
                return d1 > d2
            }
        case .newest:
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
    
    private func calculateDiscount(_ p: Product) -> Double {
        guard let original = p.originalPrice, original > p.currentPrice else { return 0 }
        return (original - p.currentPrice) / original
    }
    
    func fetchTrending() async {
        do {
            // Use backend Trending endpoint for real analysis
            let trending = try await APIService.shared.fetchTrendingProducts()
            self.trendingProducts = Array(trending.prefix(6))
        } catch {
            print("Failed to fetch trending: \(error)")
        }
    }
    
    func fetchPersonalized() async {
        do {
            // Fetch personalized from favorite brands or Zara
            let favs = UserPreferences.shared.interestedBrands
            let brand = favs.isEmpty ? "Zara" : favs.randomElement()
            let recommended = try await APIService.shared.fetchInditexFeed(brand: brand, category: nil)
            self.personalizedProducts = Array(recommended.shuffled().prefix(6))
        } catch {
            print("Failed to fetch personalized: \(error)")
        }
    }
    
    func loadFeed() async {
        isLoading = true
        errorMessage = nil
        
        async let mainFeed = APIService.shared.fetchInditexFeed(brand: selectedBrand == "Hepsi" ? nil : selectedBrand, 
                                                               category: categoryMap[selectedCategory] == "Tümü" ? nil : categoryMap[selectedCategory])
        async let _ = fetchTrending()
        async let _ = fetchPersonalized()
        
        do {
            self.products = try await mainFeed
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
    
    func triggerMiner() {
        Task {
             try? await APIService.shared.triggerInditexMiner()
        }
    }
}
