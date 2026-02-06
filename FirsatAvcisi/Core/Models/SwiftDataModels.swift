
import Foundation
import SwiftData

@Model
class SDProduct {
    @Attribute(.unique) var id: Int
    var title: String
    var imageUrl: String?
    var currentPrice: Double
    var originalPrice: Double?
    var source: String
    var url: String
    var inStock: Bool?
    var createdAt: Date
    
    // Smart Extras
    var targetPrice: Double?
    var discountPercentage: Double?
    var smartScore: Double?
    
    init(from product: Product) {
        self.id = product.id
        self.title = product.title
        self.imageUrl = product.imageUrl
        self.currentPrice = product.currentPrice
        self.originalPrice = product.originalPrice
        self.source = product.source
        self.url = product.url
        self.inStock = product.inStock
        
        // Handle date conversion
        if let createdStr = product.createdAt {
            let formatter = ISO8601DateFormatter()
            self.createdAt = formatter.date(from: createdStr) ?? Date()
        } else {
            self.createdAt = Date()
        }
        
        self.targetPrice = product.targetPrice
        self.discountPercentage = product.discountPercentage
        self.smartScore = product.smartScore
    }
}

@Model
class SDNotification {
    var id: UUID
    var title: String
    var body: String
    var date: Date
    var isRead: Bool
    var type: String // "price_drop", "stock", "system"
    var relatedProductId: Int?
    
    init(title: String, body: String, type: String = "system", relatedProductId: Int? = nil) {
        self.id = UUID()
        self.title = title
        self.body = body
        self.date = Date()
        self.isRead = false
        self.type = type
        self.relatedProductId = relatedProductId
    }
}
