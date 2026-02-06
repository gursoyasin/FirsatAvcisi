import Foundation

struct Product: Identifiable, Codable {
    let id: Int
    let title: String
    let imageUrl: String?
    let currentPrice: Double
    let originalPrice: Double?
    let source: String
    let url: String
    let inStock: Bool?
    let createdAt: String?
    
    var targetPrice: Double?
    let history: [PriceHistory]?
    var discountPercentage: Double?
    
    // Smart Scoring Fields
    let followerCount: Int?
    let smartScore: Double?
    let category: String?
    
    let bestAlternativePrice: Double?
    let bestAlternativeSource: String?
    
    // Aggregator Fields
    let sellers: [Seller]?
    let variants: [ProductVariant]?
    
    // Delici Features Data
    let smartAnalysis: SmartAnalysis?
    
    // Strategy & Metrics
    let strategy: StrategyReport?
    let metrics: ProductMetrics?
}

struct SmartAnalysis: Codable {
    let realDiscountStatus: DiscountStatus
    let lowestPriceIn30Days: Double?
    let timePrediction: String? // "Genelde Cuma günleri düşer"
    let socialWatchCount: Int? // "312 kişi"
}

enum DiscountStatus: String, Codable {
    case real = "REAL" // Great deal
    case inflated = "INFLATED" // Fake discount
    case standard = "STANDARD" // Normal price
}

struct Seller: Identifiable, Codable {
    var id: String { merchant ?? UUID().uuidString } // Unique enough for UI
    let merchant: String?
    let price: Double?
    let url: String?
    let badge: String?
}

struct ProductVariant: Identifiable, Codable {
    var id: String { title ?? UUID().uuidString }
    let title: String?
    let url: String?
    let active: Bool?
}

struct PriceHistory: Identifiable, Codable {
    let id: Int
    let price: Double
    let checkedAt: String // ISO String from backend
}

struct AlternativeProduct: Identifiable, Codable {
    var id: String { url }
    let market: String
    let title: String
    let price: Double
    let url: String
}

struct AppCollection: Identifiable, Codable {
    let id: Int
    let name: String
    let userEmail: String
    let products: [Product]?
    let _count: CollectionCount?
    
    // New Master Features
    let isPublic: Bool
    let shareToken: String?
    let type: String // MANUAL, SMART
    let icon: String // SF Symbol
    let query: String? // JSON criteria
}

struct CollectionCount: Codable {
    let products: Int
}


// MARK: - Strategy & Metrics
struct StrategyReport: Codable {
    let advice: String // BUY, WAIT
    let confidence: Int
    let reason: String
    let stats: StrategyStats?
}

struct StrategyStats: Codable {
    let minPrice: Double?
    let maxPrice: Double?
    let avgPrice: Double?
    let totalScans: Int?
    let daysTracked: Int?
}

struct ProductMetrics: Codable {
    let timeSaved: TimeSavedMetric?
}

struct TimeSavedMetric: Codable {
    let minutesSaved: Int
    let message: String
}
