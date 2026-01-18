import Foundation

class APIService: ObservableObject {
    static let shared = APIService()
    // Localhost for simulator (might differ if using real device, usually localhost works on simulator)
    private let baseURL = "http://localhost:3000/api"

    func fetchProducts() async throws -> [Product] {
        guard let url = URL(string: "\(baseURL)/products") else { return [] }
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode([Product].self, from: data)
    }
    
    func previewProduct(url: String) async throws -> AddProductViewModel.ProductPreview {
        guard let endpoint = URL(string: "\(baseURL)/products/preview") else { throw URLError(.badURL) }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["url": url]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(AddProductViewModel.ProductPreview.self, from: data)
    }
    
    func addProduct(preview: AddProductViewModel.ProductPreview) async throws {
        guard let endpoint = URL(string: "\(baseURL)/products") else { throw URLError(.badURL) }
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Backend expects: { url, title, price, imageUrl, source }
        // Preview struct matches helpful keys, let's map it.
        let body: [String: Any] = [
            "url": preview.url,
            "title": preview.title,
            "price": preview.currentPrice,
            "imageUrl": preview.imageUrl,
            "source": preview.source
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
    }
}
