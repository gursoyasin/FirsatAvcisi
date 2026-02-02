import Foundation

class AffiliateManager {
    static let shared = AffiliateManager()
    
    // Mock Config for Test
    private let amazonTag = "firsatavcisi-21"
    private let trendyolAffiliateId = "TEST_ID_123" // Simulating user entered ID
    private let hepsiburadaAffiliateId = "TEST_ID_456"
    
    func convertToAffiliateLink(_ urlStr: String) -> URL? {
        // Fix for non-encoded URLs or simple strings
        let safeStr = urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? urlStr
        guard let url = URL(string: urlStr), var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            print("Invalid URL: \(urlStr)")
            return URL(string: urlStr)
        }
        
        let host = components.host?.lowercased() ?? ""
        var queryItems = components.queryItems ?? []
        
        // 1. AMAZON
        if host.contains("amazon") {
            if let index = queryItems.firstIndex(where: { $0.name == "tag" }) {
                queryItems[index].value = amazonTag
            } else {
                queryItems.append(URLQueryItem(name: "tag", value: amazonTag))
            }
        }
        
        // 2. TRENDYOL
        else if host.contains("trendyol") {
            if !containsQuery(items: queryItems, name: "utm_source") {
                queryItems.append(URLQueryItem(name: "utm_source", value: "affiliate"))
                queryItems.append(URLQueryItem(name: "utm_campaign", value: "firsatavcisi_app"))
                // Always add affiliate_id for test to see it work
                queryItems.append(URLQueryItem(name: "affiliate_id", value: trendyolAffiliateId))
            }
        }
        
        // 3. HEPSIBURADA
        else if host.contains("hepsiburada") {
             if !containsQuery(items: queryItems, name: "utm_source") {
                queryItems.append(URLQueryItem(name: "utm_source", value: "affiliate"))
                queryItems.append(URLQueryItem(name: "utm_campaign", value: "firsatavcisi"))
            }
        }
        
        components.queryItems = queryItems
        return components.url
    }
    
    private func containsQuery(items: [URLQueryItem], name: String) -> Bool {
        return items.contains(where: { $0.name == name })
    }
}

// TEST CASES
let manager = AffiliateManager.shared

print("--- AMAZON TEST ---")
let amz1 = "https://www.amazon.com.tr/dp/B08X?th=1"
print("Input: \(amz1)")
print("Output: \(manager.convertToAffiliateLink(amz1)?.absoluteString ?? "Fail")")

print("\n--- TRENDYOL TEST ---")
let ty1 = "https://www.trendyol.com/adidas/erkek-spor-ayakkabi-p-123456"
print("Input: \(ty1)")
print("Output: \(manager.convertToAffiliateLink(ty1)?.absoluteString ?? "Fail")")

print("\n--- HEPSIBURADA TEST ---")
let hb1 = "https://www.hepsiburada.com/apple-iphone-13-128-gb-p-HBCV00000"
print("Input: \(hb1)")
print("Output: \(manager.convertToAffiliateLink(hb1)?.absoluteString ?? "Fail")")

print("\n--- ZARA TEST (NO CHANGE EXPECTED EXCEPT UTM) ---")
let zara = "https://www.zara.com/tr/tr/gomlek-p0123.html"
// Assuming I didn't verify ZARA logic in previous thought, let's see. 
// My implementation had ZARA logic.
print("Output: \(manager.convertToAffiliateLink(zara)?.absoluteString ?? "Fail")")
