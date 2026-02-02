import Foundation

class AffiliateManager {
    static let shared = AffiliateManager()
    
    // Konfigürasyon: Buraya kendi affiliate ID'lerinizi girmelisiniz.
    private let amazonTag = "firsatavcisi-21" // Örnek
    private let trendyolAffiliateId = "YOUR_TRENDYOL_ID"
    private let hepsiburadaAffiliateId = "YOUR_HEPSIBURADA_ID"
    
    /// Verilen ürün linkini Affiliate linkine dönüştürür
    func convertToAffiliateLink(_ urlStr: String) -> URL? {
        guard var components = URLComponents(string: urlStr) else { return URL(string: urlStr) }
        let host = components.host?.lowercased() ?? ""
        
        var queryItems = components.queryItems ?? []
        
        // 1. AMAZON
        if host.contains("amazon") {
            // Mevcut tag varsa güncelle, yoksa ekle
            if let index = queryItems.firstIndex(where: { $0.name == "tag" }) {
                queryItems[index].value = amazonTag
            } else {
                queryItems.append(URLQueryItem(name: "tag", value: amazonTag))
            }
        }
        
        // 2. TRENDYOL (Örnek Parametreler)
        else if host.contains("trendyol") {
            // Trendyol genelde LinkGelir veya Influencer link yapısı kullanır.
            // Örnek: utm_source=affiliate&utm_campaign=...
            if !containsQuery(items: queryItems, name: "utm_source") {
                queryItems.append(URLQueryItem(name: "utm_source", value: "affiliate"))
                queryItems.append(URLQueryItem(name: "utm_campaign", value: "firsatavcisi_app"))
                if trendyolAffiliateId != "YOUR_TRENDYOL_ID" {
                     queryItems.append(URLQueryItem(name: "affiliate_id", value: trendyolAffiliateId))
                }
            }
        }
        
        // 3. HEPSIBURADA
        else if host.contains("hepsiburada") {
             if !containsQuery(items: queryItems, name: "utm_source") {
                queryItems.append(URLQueryItem(name: "utm_source", value: "affiliate"))
                queryItems.append(URLQueryItem(name: "utm_campaign", value: "firsatavcisi"))
            }
        }
        
        // 4. ZARA / INDITEX (Genelde affiliate vermezler ama UTM ekleyebiliriz takibi görmek için)
        else if host.contains("zara") || host.contains("bershka") {
             if !containsQuery(items: queryItems, name: "utm_source") {
                queryItems.append(URLQueryItem(name: "utm_source", value: "firsatavcisi_app"))
            }
        }
        
        components.queryItems = queryItems
        return components.url
    }
    
    private func containsQuery(items: [URLQueryItem], name: String) -> Bool {
        return items.contains(where: { $0.name == name })
    }
}
