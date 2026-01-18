import Foundation

struct Product: Identifiable, Codable {
    let id: Int
    let title: String
    let imageUrl: String?
    let currentPrice: Double
    let source: String
    let url: String
    
    // CodingKeys if needed, but assuming backend matches
}
