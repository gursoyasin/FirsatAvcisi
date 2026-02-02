import Foundation
import SwiftData

@Model
class ProductEntity {
    @Attribute(.unique) var id: Int
    var title: String
    var imageUrl: String?
    var currentPrice: Double
    var originalPrice: Double?
    var source: String
    var url: String
    var inStock: Bool?
    var createdAt: String?
    var targetPrice: Double?
    var discountPercentage: Double?
    var followerCount: Int?
    var smartScore: Double?
    var category: String?
    var bestAlternativePrice: Double?
    var bestAlternativeSource: String?
    
    @Relationship(deleteRule: .cascade, inverse: \PriceHistoryEntity.product) 
    var history: [PriceHistoryEntity]?
    
    @Relationship(deleteRule: .cascade, inverse: \SellerEntity.product) 
    var sellers: [SellerEntity]?
    
    @Relationship(deleteRule: .cascade, inverse: \ProductVariantEntity.product) 
    var variants: [ProductVariantEntity]?
    
    var smartAnalysisData: Data? // Store as JSON Data
    
    init(id: Int, title: String, imageUrl: String? = nil, currentPrice: Double, originalPrice: Double? = nil, 
         source: String, url: String, inStock: Bool? = nil, createdAt: String? = nil, targetPrice: Double? = nil,
         discountPercentage: Double? = nil, followerCount: Int? = nil, smartScore: Double? = nil, 
         category: String? = nil, bestAlternativePrice: Double? = nil, bestAlternativeSource: String? = nil) {
        self.id = id
        self.title = title
        self.imageUrl = imageUrl
        self.currentPrice = currentPrice
        self.originalPrice = originalPrice
        self.source = source
        self.url = url
        self.inStock = inStock
        self.createdAt = createdAt
        self.targetPrice = targetPrice
        self.discountPercentage = discountPercentage
        self.followerCount = followerCount
        self.smartScore = smartScore
        self.category = category
        self.bestAlternativePrice = bestAlternativePrice
        self.bestAlternativeSource = bestAlternativeSource
    }
    
    // Convert from API Product struct
    static func from(_ product: Product) -> ProductEntity {
        let entity = ProductEntity(
            id: product.id,
            title: product.title,
            imageUrl: product.imageUrl,
            currentPrice: product.currentPrice,
            originalPrice: product.originalPrice,
            source: product.source,
            url: product.url,
            inStock: product.inStock,
            createdAt: product.createdAt,
            targetPrice: product.targetPrice,
            discountPercentage: product.discountPercentage,
            followerCount: product.followerCount,
            smartScore: product.smartScore,
            category: product.category,
            bestAlternativePrice: product.bestAlternativePrice,
            bestAlternativeSource: product.bestAlternativeSource
        )
        
        // Convert relationships
        if let history = product.history {
            entity.history = history.map { 
                let h = PriceHistoryEntity.from($0)
                h.product = entity
                return h
            }
        }
        if let sellers = product.sellers {
            entity.sellers = sellers.map { 
                let s = SellerEntity.from($0)
                s.product = entity
                return s
            }
        }
        if let variants = product.variants {
            entity.variants = variants.map { 
                let v = ProductVariantEntity.from($0)
                v.product = entity
                return v
            }
        }
        
        // Store smart analysis as JSON
        if let analysis = product.smartAnalysis {
            entity.smartAnalysisData = try? JSONEncoder().encode(analysis)
        }
        
        return entity
    }
    
    // Convert to API Product struct
    func toProduct() -> Product {
        let smartAnalysis: SmartAnalysis? = {
            guard let data = smartAnalysisData else { return nil }
            return try? JSONDecoder().decode(SmartAnalysis.self, from: data)
        }()
        
        return Product(
            id: id,
            title: title,
            imageUrl: imageUrl,
            currentPrice: currentPrice,
            originalPrice: originalPrice,
            source: source,
            url: url,
            inStock: inStock,
            createdAt: createdAt,
            targetPrice: targetPrice,
            history: history?.map { $0.toPriceHistory() },
            discountPercentage: discountPercentage,
            followerCount: followerCount,
            smartScore: smartScore,
            category: category,
            bestAlternativePrice: bestAlternativePrice,
            bestAlternativeSource: bestAlternativeSource,
            sellers: sellers?.map { $0.toSeller() },
            variants: variants?.map { $0.toProductVariant() },
            smartAnalysis: smartAnalysis
        )
    }
}

@Model
class PriceHistoryEntity {
    var id: Int
    var price: Double
    var checkedAt: String
    var product: ProductEntity?
    
    init(id: Int, price: Double, checkedAt: String) {
        self.id = id
        self.price = price
        self.checkedAt = checkedAt
    }
    
    static func from(_ history: PriceHistory) -> PriceHistoryEntity {
        PriceHistoryEntity(id: history.id, price: history.price, checkedAt: history.checkedAt)
    }
    
    func toPriceHistory() -> PriceHistory {
        PriceHistory(id: id, price: price, checkedAt: checkedAt)
    }
}

@Model
class SellerEntity {
    var merchant: String?
    var price: Double?
    var url: String?
    var badge: String?
    var product: ProductEntity?
    
    init(merchant: String?, price: Double?, url: String?, badge: String?) {
        self.merchant = merchant
        self.price = price
        self.url = url
        self.badge = badge
    }
    
    static func from(_ seller: Seller) -> SellerEntity {
        SellerEntity(merchant: seller.merchant, price: seller.price, url: seller.url, badge: seller.badge)
    }
    
    func toSeller() -> Seller {
        Seller(merchant: merchant, price: price, url: url, badge: badge)
    }
}

@Model
class ProductVariantEntity {
    var title: String?
    var url: String?
    var active: Bool?
    var product: ProductEntity?
    
    init(title: String?, url: String?, active: Bool?) {
        self.title = title
        self.url = url
        self.active = active
    }
    
    static func from(_ variant: ProductVariant) -> ProductVariantEntity {
        ProductVariantEntity(title: variant.title, url: variant.url, active: variant.active)
    }
    
    func toProductVariant() -> ProductVariant {
        ProductVariant(title: title, url: url, active: active)
    }
}
