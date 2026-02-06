import SwiftUI
import Combine

class SmartDashboardViewModel: ObservableObject {
    @Published var moodMessage: String = "Bugün senin için beklediklerim..."
    @Published var averageWaitingTime: Int = 5
    @Published var emotionalFeed: [Product] = []
    @Published var dailyDiscountPick: Product?
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        fetchDashboardData()
    }
    
    func fetchDashboardData() {
        Task {
            self.generateMood()
            await self.fetchStats()
            await self.fetchEmotionalFeed()
            await self.fetchDailyPick()
        }
    }
    
    // MARK: - 1. Mood Sentence Logic
    private func generateMood() {
        let hour = Calendar.current.component(.hour, from: Date())
        
        let messages = [
            "Bugün senin için beklediklerim... 💙",
            "Fırsat avı başladı, gözümüz üzerinde 👀",
            "İndirimlerin kokusunu alıyorum... ☕️",
            "Senin tarzın, senin fırsatın. 🔥",
            "Güzel şeyler bekleyenlere gelir... ☀️"
        ]
        
        // Dynamic mood
        DispatchQueue.main.async {
            self.moodMessage = messages.randomElement() ?? messages[0]
        }
    }
    
    // MARK: - 2. Waiting Time Logic
    private func fetchStats() async {
        do {
            let stats = try await APIService.shared.fetchDashboardStats()
            await MainActor.run {
                self.averageWaitingTime = stats.averageWaitingTime
            }
        } catch {
            print("Stats Error: \(error)")
            // Fallback stays at 5
        }
    }
    
    // MARK: - 3. Emotional Feed (Real Data + Mock Fallback)
    private func fetchEmotionalFeed() async {
        do {
            // Using Trending Products as "Heart/Emotional" Feed
            let trending = try await APIService.shared.fetchTrendingProducts()
            
            await MainActor.run {
                if !trending.isEmpty {
                    // Filter for unique brands to satisfy "Her markadan 1 ürün" request
                    var uniqueBrandProducts: [Product] = []
                    var seenBrands: Set<String> = []
                    
                    for product in trending {
                        let brand = product.source.lowercased()
                        if !seenBrands.contains(brand) {
                            uniqueBrandProducts.append(product)
                            seenBrands.insert(brand)
                            if uniqueBrandProducts.count == 3 { break }
                        }
                    }
                    
                    // If we couldn't find 3 unique brands, fill with others
                    if uniqueBrandProducts.count < 3 {
                        for product in trending {
                            if !uniqueBrandProducts.contains(where: { $0.id == product.id }) {
                                uniqueBrandProducts.append(product)
                                if uniqueBrandProducts.count == 3 { break }
                            }
                        }
                    }
                    
                    self.emotionalFeed = uniqueBrandProducts
                } else {
                    self.loadMockEmotionalFeed() // Fallback if DB is empty
                }
            }
        } catch {
            print("Dashboard Feed Error: \(error)")
            await MainActor.run { self.loadMockEmotionalFeed() }
        }
    }
    
    // MARK: - 4. Daily Inditex Pick (Real Data + Mock Fallback)
    private func fetchDailyPick() async {
        do {
            let favs = UserPreferences.shared.interestedBrands
            let brand = favs.isEmpty ? "Zara" : favs.randomElement()
            let products = try await APIService.shared.fetchInditexFeed(brand: brand, category: nil)
            
            await MainActor.run {
                let found = products.sorted(by: { p1, p2 in
                    let d1 = (p1.originalPrice ?? 0) - p1.currentPrice
                    let d2 = (p2.originalPrice ?? 0) - p2.currentPrice
                    return d1 > d2
                }).first
                
                if let validProduct = found {
                    self.dailyDiscountPick = validProduct
                } else {
                    // Fallback: If no products for selected brand, try any brand
                    Task {
                        let allProducts = try? await APIService.shared.fetchInditexFeed(brand: nil, category: nil)
                        if let bestFound = allProducts?.sorted(by: { p1, p2 in
                            let d1 = (p1.originalPrice ?? 0) - p1.currentPrice
                            let d2 = (p2.originalPrice ?? 0) - p2.currentPrice
                            return d1 > d2
                        }).first {
                            await MainActor.run {
                                self.dailyDiscountPick = bestFound
                            }
                        } else {
                            await MainActor.run { self.loadMockDailyPick() }
                        }
                    }
                }
            }
        } catch {
            print("Daily Pick Error: \(error)")
            await MainActor.run { self.loadMockDailyPick() }
        }
    }
    
    // MARK: - Mock Fallbacks (Keeps UI Alive)
    private func loadMockEmotionalFeed() {
        self.emotionalFeed = [
            Product(
                id: 101,
                title: "Zara Fitilli Kadife Blazer",
                imageUrl: "https://static.zara.net/photos///2023/I/0/1/p/2753/032/800/2/w/850/2753032800_6_1_1.jpg?ts=1697014264287",
                currentPrice: 1299.95,
                originalPrice: 1999.95,
                source: "zara",
                url: "https://www.zara.com",
                inStock: true, createdAt: nil,
                targetPrice: nil, history: nil, discountPercentage: nil,
                followerCount: 312,
                smartScore: 0.85,
                category: "Ceket",
                bestAlternativePrice: nil, bestAlternativeSource: nil, sellers: nil, variants: nil,
                smartAnalysis: nil,
                strategy: nil, metrics: nil
            ),
            Product(
                id: 102,
                title: "Bershka Paraşüt Pantolon",
                imageUrl: "https://static.bershka.net/4/photos2/2023/I/0/1/p/5063/168/800/2/w/850/5063168800_2_4_2.jpg?ts=1697103212345",
                currentPrice: 899.95,
                originalPrice: nil,
                source: "bershka",
                url: "https://www.bershka.com",
                inStock: true, createdAt: nil,
                targetPrice: nil, history: nil, discountPercentage: nil,
                followerCount: 156,
                smartScore: 0.60,
                category: "Pantolon",
                bestAlternativePrice: nil, bestAlternativeSource: nil, sellers: nil, variants: nil,
                smartAnalysis: nil,
                strategy: nil, metrics: nil
            ),
            Product(
                id: 103,
                title: "Stradivarius Suni Deri Trençkot",
                imageUrl: "https://static.e-stradivarius.net/5/photos3/2023/I/0/1/p/1844/327/430/2/w/850/1844327430_6_1_1.jpg?ts=1696238475123",
                currentPrice: 1599.00,
                originalPrice: 2299.00,
                source: "stradivarius",
                url: "https://www.stradivarius.com",
                inStock: true, createdAt: nil,
                targetPrice: nil, history: nil, discountPercentage: nil,
                followerCount: 89,
                smartScore: 0.92,
                category: "Dış Giyim",
                bestAlternativePrice: nil, bestAlternativeSource: nil, sellers: nil, variants: nil,
                smartAnalysis: nil,
                strategy: nil, metrics: nil
            )
        ]
    }
    
    private func loadMockDailyPick() {
        self.dailyDiscountPick = Product(
            id: 201,
            title: "Pull&Bear Basic Sweatshirt",
            imageUrl: "https://static.pullandbear.net/2/photos//2023/I/0/2/p/9596/505/800/2/w/850/9596505800_2_1_8.jpg?ts=1695289932123",
            currentPrice: 359.95,
            originalPrice: 599.95,
            source: "pullandbear",
            url: "https://www.pullandbear.com",
            inStock: true, createdAt: nil,
            targetPrice: nil, history: nil, discountPercentage: nil,
            followerCount: 450,
            smartScore: 0.95,
            category: "Sweatshirt",
            bestAlternativePrice: nil, bestAlternativeSource: nil, sellers: nil, variants: nil,
            smartAnalysis: nil,
            strategy: nil, metrics: nil
        )
    }
    
    // MARK: - Helper Logic
    
    func getProbabilityColor(score: Double) -> Color {
        if score >= 0.8 { return .green }
        if score >= 0.5 { return .yellow }
        return .red
    }
    
    func getProbabilityText(score: Double) -> String {
        if score >= 0.8 { return "Yüksek İhtimal" }
        if score >= 0.5 { return "Orta İhtimal" }
        return "Düşük İhtimal"
    }
}
