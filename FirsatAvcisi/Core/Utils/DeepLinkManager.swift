import SwiftUI
import Combine

enum DeepLinkTarget: Identifiable, Equatable {
    case product(id: Int)
    case collection(id: Int)
    
    var id: String {
        switch self {
        case .product(let id): return "product-\(id)"
        case .collection(let id): return "collection-\(id)"
        }
    }
}

class DeepLinkManager: ObservableObject {
    @Published var currentTarget: DeepLinkTarget?
    
    func handle(url: URL) {
        print("🔗 Deep Link Received: \(url.absoluteString)")
        
        // Scheme: firsatavcisi://product?id=123
        // Universal Link: https://firsatavcisi.com/product/123
        
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            // Handle Custom Scheme
            if url.scheme == "firsatavcisi" {
                if url.host == "product" {
                    if let idItem = components.queryItems?.first(where: { $0.name == "id" }),
                       let idString = idItem.value,
                       let id = Int(idString) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.currentTarget = .product(id: id)
                        }
                    }
                }
            }
            // Handle Universal Link (Path based)
            else if url.pathComponents.contains("product") {
                if let last = url.pathComponents.last, let id = Int(last) {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.currentTarget = .product(id: id)
                    }
                }
            }
        }
    }
}
