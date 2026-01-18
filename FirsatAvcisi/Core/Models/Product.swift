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

