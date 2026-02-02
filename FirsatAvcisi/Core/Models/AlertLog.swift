import SwiftUI

struct AlertLog: Codable, Identifiable {
    let id: Int
    let productId: Int
    let message: String
    let type: String // PRICE_DROP, STOCK_ALERT, TARGET_PRICE
    let createdAt: String
    let product: ProductSummary?
    
    struct ProductSummary: Codable {
        let title: String
        let imageUrl: String?
    }
    
    var timeAgo: String {
        guard let date = ISO8601DateFormatter().date(from: createdAt) else { return "Az önce" }
        let diff = Int(Date().timeIntervalSince(date))
        if diff < 60 { return "Şimdi" }
        if diff < 3600 { return "\(diff / 60)dk önce" }
        if diff < 86400 { return "\(diff / 3600)sa önce" }
        return "\(diff / 86400)g önce"
    }
    
    var iconName: String {
        switch type {
        case "PRICE_DROP": return "arrow.down.circle.fill"
        case "STOCK_ALERT": return "cube.box.fill"
        case "TARGET_PRICE": return "target"
        default: return "bell.fill"
        }
    }
    
    var color: Color {
        switch type {
        case "PRICE_DROP": return .green
        case "STOCK_ALERT": return .orange
        case "TARGET_PRICE": return .blue
        default: return .gray
        }
    }
}
