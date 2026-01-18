import Foundation
import Combine
import FirebaseAuth

enum APIError: Error {
    case badURL
    case serverError
    case limitReached
    case unknown
}

class APIService: ObservableObject {
    static let shared = APIService()
    // Production Server (Render)
    private let baseURL = "https://firsat-avcisi-backend.onrender.com/api"
    
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120 // Increased for scraping (2 mins)
        config.timeoutIntervalForResource = 300
        return URLSession(configuration: config)
    }()

    // Helper to add auth headers
    private func createRequest(url: URL, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Pass User Email
        if let email = Auth.auth().currentUser?.email {
            request.setValue(email, forHTTPHeaderField: "X-User-Email")
        }
        
        return request
    }

    struct ProductResponse: Decodable {
        let products: [Product]
        let pagination: PaginationMetadata
    }
    
    struct PaginationMetadata: Decodable {
        let page: Int
        let limit: Int
        let total: Int
        let totalPages: Int
    }

    func fetchProducts(page: Int = 1, limit: Int = 50) async throws -> ProductResponse {
        guard let url = URL(string: "\(baseURL)/products?page=\(page)&limit=\(limit)") else { 
            throw APIError.badURL 
        }
        let request = createRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(ProductResponse.self, from: data)
    }
    
    func fetchProduct(id: Int) async throws -> Product {
        // Backend needs GET /products/:id endpoint.
        // Assuming I'll add it or it exists.
        // If not, I'll need to add it to backend too.
        guard let url = URL(string: "\(baseURL)/products/\(id)") else { throw APIError.badURL }
        let request = createRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(Product.self, from: data)
    }
    
    func previewProduct(url: String) async throws -> AddProductViewModel.ProductPreview {
        guard let endpoint = URL(string: "\(baseURL)/products/preview") else { throw APIError.badURL }
        
        var request = createRequest(url: endpoint, method: "POST")
        let body = ["url": url]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.serverError
        }
        
        return try JSONDecoder().decode(AddProductViewModel.ProductPreview.self, from: data)
    }
    
    func addProduct(preview: AddProductViewModel.ProductPreview) async throws {
        guard let endpoint = URL(string: "\(baseURL)/products") else { throw APIError.badURL }
        
        var request = createRequest(url: endpoint, method: "POST")
        
        let body: [String: Any] = [
            "url": preview.url,
            "title": preview.title,
            "price": preview.currentPrice,
            "imageUrl": preview.imageUrl ?? "",
            "source": preview.source
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.unknown }
        
        if httpResponse.statusCode == 403 { throw APIError.limitReached }
        guard httpResponse.statusCode == 200 else { throw APIError.serverError }
    }
    
    func updateTargetPrice(id: Int, price: Double) async throws {
        guard let url = URL(string: "\(baseURL)/products/\(id)") else { throw APIError.badURL }
        
        var request = createRequest(url: url, method: "PATCH")
        
        let body = ["targetPrice": price]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
    }
    
    func deleteProduct(id: Int) async throws {
        guard let url = URL(string: "\(baseURL)/products/\(id)") else { throw APIError.badURL }
        let request = createRequest(url: url, method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
    }
    func fetchCollections() async throws -> [AppCollection] {
        guard let url = URL(string: "\(baseURL)/collections") else { throw APIError.badURL }
        let request = createRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([AppCollection].self, from: data)
    }
    
    func createCollection(name: String) async throws {
        guard let url = URL(string: "\(baseURL)/collections") else { throw APIError.badURL }
        
        var request = createRequest(url: url, method: "POST")
        let body = ["name": name]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
    }
    
    func deleteCollection(id: Int) async throws {
        guard let url = URL(string: "\(baseURL)/collections/\(id)") else { throw APIError.badURL }
        let request = createRequest(url: url, method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw APIError.serverError }
    }
    
    func addProductToCollection(collectionId: Int, productId: Int) async throws {
        guard let url = URL(string: "\(baseURL)/collections/\(collectionId)/products") else { throw APIError.badURL }
        
        var request = createRequest(url: url, method: "POST")
        let body = ["productId": productId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { throw APIError.serverError }
    }
    
    // Fetch single collection with products
    func fetchCollection(id: Int) async throws -> AppCollection {
        guard let url = URL(string: "\(baseURL)/collections/\(id)") else { throw APIError.badURL }
        let request = createRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(AppCollection.self, from: data)
    }
    
    func lookupBarcode(barcode: String) async throws -> AddProductViewModel.ProductPreview {
        guard let url = URL(string: "\(baseURL)/products/barcode") else { throw APIError.badURL }
        
        var request = createRequest(url: url, method: "POST")
        let body = ["barcode": barcode]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
        
        // Map backend response (scraped data) to ProductPreview
        struct ScrapedData: Decodable {
            let title: String
            let currentPrice: Double
            let imageUrl: String?
            let source: String
            let url: String
        }
        
        let scraped = try JSONDecoder().decode(ScrapedData.self, from: data)
        return AddProductViewModel.ProductPreview(
            title: scraped.title,
            currentPrice: scraped.currentPrice,
            imageUrl: scraped.imageUrl ?? "",
            source: scraped.source,
            url: scraped.url
        )
    }
    func fetchTrendingProducts(category: String? = nil) async throws -> [Product] {
        var urlString = "\(baseURL)/products/trending"
        if let category = category {
            urlString += "?category=\(category)"
        }
        
        guard let url = URL(string: urlString) else { throw APIError.badURL }
        let request = createRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([Product].self, from: data)
    }
    func registerDeviceToken(_ token: String) async {
        do {
            guard let url = URL(string: "\(baseURL)/devices/register") else { return }
            let request = try createRequest(url: url, method: "POST")
            let body = ["token": token]
            var finalRequest = request
            finalRequest.httpBody = try JSONEncoder().encode(body)
            
            let (_, response) = try await URLSession.shared.data(for: finalRequest)
            if let httpResponse = response as? HTTPURLResponse {
                print("Device registration status: \(httpResponse.statusCode)")
            }
        } catch {
            print("Failed to register device token: \(error.localizedDescription)")
        }
    }
    
    func fetchAlternatives(for productId: Int) async throws -> [AlternativeProduct] {
        guard let url = URL(string: "\(baseURL)/products/\(productId)/alternatives") else {
            throw URLError(.badURL)
        }
        let request = createRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([AlternativeProduct].self, from: data)
    }
    
    func batchDeleteProducts(ids: [Int]) async throws {
        guard let url = URL(string: "\(baseURL)/products/batch-delete") else { throw APIError.badURL }
        var request = createRequest(url: url, method: "POST")
        let body = ["ids": ids]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
    }
    
    func removeProductFromCollection(collectionId: Int, productId: Int) async throws {
        guard let url = URL(string: "\(baseURL)/collections/\(collectionId)/products/\(productId)") else { throw APIError.badURL }
        let request = createRequest(url: url, method: "DELETE")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
    }
    
    func moveProducts(productIds: [Int], from sourceId: Int, to targetId: Int) async throws {
        guard let url = URL(string: "\(baseURL)/collections/\(targetId)/move") else { throw APIError.badURL }
        var request = createRequest(url: url, method: "POST")
        let body: [String: Any] = ["productIds": productIds, "sourceCollectionId": sourceId]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
    }
    
    func updateCollection(id: Int, name: String?, icon: String?, isPublic: Bool?) async throws {
        guard let url = URL(string: "\(baseURL)/collections/\(id)") else { throw APIError.badURL }
        var request = createRequest(url: url, method: "PATCH")
        var body: [String: Any] = [:]
        if let name = name { body["name"] = name }
        if let icon = icon { body["icon"] = icon }
        if let isPublic = isPublic { body["isPublic"] = isPublic }
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
    }

    func globalSearch(query: String) async throws -> [GlobalSearchProduct] {
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(baseURL)/search/global?q=\(encodedQuery)") else {
            throw APIError.badURL
        }
        
        let request = createRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([GlobalSearchProduct].self, from: data)
    }

    func fetchInditexFeed(brand: String? = nil, category: String? = nil) async throws -> [Product] {
        var urlComponents = URLComponents(string: "\(baseURL)/products/inditex/feed")
        var queryItems: [URLQueryItem] = []
        
        if let brand = brand {
            queryItems.append(URLQueryItem(name: "brand", value: brand))
        }
        
        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: category))
        }
        
        urlComponents?.queryItems = queryItems
        
        guard let url = urlComponents?.url else { throw APIError.badURL }
        let request = createRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode([Product].self, from: data)
    }

    func triggerInditexMiner() async throws {
        guard let url = URL(string: "\(baseURL)/inditex/mine") else { throw APIError.badURL }
        var request = createRequest(url: url, method: "POST")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
    }
    
    func triggerWatchlistCheck() async throws {
        guard let url = URL(string: "\(baseURL)/watchlist/check") else { throw APIError.badURL }
        var request = createRequest(url: url, method: "POST")
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw APIError.serverError
        }
    }
    
    func resolveURL(url: String) async throws -> String {
        guard let encodedURL = url.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
              let endpoint = URL(string: "\(baseURL)/resolve-url?url=\(encodedURL)") else {
            throw APIError.badURL
        }
        
        let request = createRequest(url: endpoint)
        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode([String: String].self, from: data)
        return response["finalUrl"] ?? url
    }
    
    // MARK: - Ultra Features
    
    struct AnalysisResult: Decodable {
        let recommendation: String // BUY, WAIT, DON'T MISS
        let confidence: Double
        let reason: String
        let badge: String
        let stats: AnalysisStats?
        
        struct AnalysisStats: Decodable {
            let min: Double
            let max: Double
            let avg: Double
        }
    }
    
    func fetchProductAnalysis(productId: Int) async throws -> AnalysisResult {
        guard let url = URL(string: "\(baseURL)/products/\(productId)/analysis") else { throw APIError.badURL }
        let request = createRequest(url: url)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(AnalysisResult.self, from: data)
    }
}


struct GlobalSearchProduct: Codable, Identifiable {
    let id: String // Now strictly expecting a String ID from backend unique generation
    let source: String
    let title: String
    let currentPrice: Double
    let imageUrl: String?
    let url: String
    let badge: String?
    let sellers: [SearchOffer]? // Changed from allOffers to sellers to match backend
    
    // Convert to ProductPreview for reuse in AddProduct flow
    var toPreview: AddProductViewModel.ProductPreview {
        AddProductViewModel.ProductPreview(
            title: title,
            currentPrice: currentPrice,
            imageUrl: imageUrl ?? "",
            source: source,
            url: url
        )
    }
}

struct SearchOffer: Codable, Identifiable {
    var id: String { url }
    let merchant: String? // Backend sends 'merchant'
    let price: Double
    let url: String
    let badge: String?
    
    // Helper for UI compatibility
    var displaySource: String {
        merchant ?? "Mağaza"
    }
}
